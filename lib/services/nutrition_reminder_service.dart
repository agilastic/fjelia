import '../l10n/l10n_ext.dart';

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import 'nutrition_service.dart';
import 'notifications/local_notification_gateway.dart';

const nutritionNotificationBase = 7100000;
const nutritionNotificationLimit = 7200000;

/// Of the given activities, those with a pre-workout or resting HRV reading
/// but no post-workout one yet.
typedef PostHrvMissing = Future<Set<String>> Function(List<String> activityIds);

class NutritionReminderService {
  NutritionReminderService(
    this.store,
    this.gateway, {
    DateTime Function()? now,
    this.postHrvMissing,
  }) : now = now ?? DateTime.now;
  final NutritionService store;
  final LocalNotificationGateway gateway;
  final DateTime Function() now;
  final PostHrvMissing? postHrvMissing;
  Future<void> _pending = Future.value();
  AppDatabase get db => store.db;
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  bool _active(NutritionReminderRecord r) =>
      r.state == 'scheduled' || r.state.startsWith('snoozed');
  DateTime quietAdjusted(DateTime at) {
    final local = at.toLocal();
    if (local.hour >= 22) {
      return DateTime(local.year, local.month, local.day + 1, 8);
    }
    if (local.hour < 8) return DateTime(local.year, local.month, local.day, 8);
    return at;
  }

  bool eligible(ActivityRecord a, DateTime at) {
    final end = a.startDate.add(Duration(seconds: nutritionElapsedSeconds(a)));
    final sport = a.type.toLowerCase();
    return a.durationSeconds >= 45 * 60 &&
        !end.isAfter(at) &&
        at.difference(end) < Duration(hours: 24) &&
        [
          'run',
          'trail',
          'cycl',
          'bik',
          'mtb',
          'swim',
          'ski',
          'nordic',
        ].any(sport.contains);
  }

  Future<void> _cancel(NutritionReminderRecord r, String state) async {
    await (db.update(db.nutritionReminderRecords)
          ..where((t) => t.activityId.equals(r.activityId)))
        .write(NutritionReminderRecordsCompanion(state: Value(state)));
    await gateway.cancel(r.notificationId);
  }

  /// The HRV hint is optional: a failing lookup never blocks the reminder.
  Future<Set<String>> _hrvMissing(List<String> ids) async {
    final lookup = postHrvMissing;
    if (lookup == null || ids.isEmpty) return const {};
    try {
      return await lookup(ids);
    } catch (_) {
      return const {};
    }
  }

  ScheduledNotification _notification(
    NutritionReminderRecord r,
    ActivityRecord activity,
    bool hrvMissing,
  ) => ScheduledNotification(
    id: r.notificationId,
    at: r.dueAt,
    feature: NotificationFeature.nutrition,
    payload: NutritionNotificationPayload(r.activityId, r.token).encode(),
    title: tr.nutritionReminderTitle(activity.name),
    body: hrvMissing
        ? '${tr.nutritionReminderBody}\n${tr.nutritionReminderHrvHint}'
        : tr.nutritionReminderBody,
    actionLabels: {
      'log': tr.logIntake,
      'snooze': tr.in30Minutes,
      'skip': tr.dismiss,
    },
  );

  static String _textOf(ScheduledNotification n) => '${n.title}\n${n.body}';

  Future<void> _schedule(
    NutritionReminderRecord r,
    ActivityRecord activity,
    bool hrvMissing,
  ) async {
    final n = _notification(r, activity, hrvMissing);
    await gateway.schedule(n);
    await (db.update(
      db.nutritionReminderRecords,
    )..where((t) => t.activityId.equals(r.activityId))).write(
      NutritionReminderRecordsCompanion(scheduledText: Value(_textOf(n))),
    );
  }

  Future<void> reconcile() => _serial(() async {
    final at = now();
    final prefs = await store.preferences();
    final permission = await gateway.permission();
    final rows = await db.select(db.nutritionReminderRecords).get();
    final native = gateway.capabilities.pendingQuery
        ? await gateway.pendingIds()
        : <int>{};
    final delivered = gateway.capabilities.deliveredQuery
        ? await gateway.deliveredIds()
        : <int>{};
    // A reset/deletion must not leave notifications which no longer have a row.
    final owned = rows.map((r) => r.notificationId).toSet();
    for (final id in {...native, ...delivered}) {
      if (id >= nutritionNotificationBase &&
          id < nutritionNotificationLimit &&
          !owned.contains(id)) {
        await gateway.cancel(id);
      }
    }
    // Pending reminders whose text may need refreshing, and new ones.
    final due = <(NutritionReminderRecord, ActivityRecord, bool)>[];
    for (final row in rows) {
      final activity = await (db.select(
        db.activityRecords,
      )..where((t) => t.activityId.equals(row.activityId))).getSingleOrNull();
      final finished = (await store.log(row.activityId)).finished;
      if (!_active(row) &&
          !native.contains(row.notificationId) &&
          !delivered.contains(row.notificationId)) {
        continue;
      }
      if (activity == null ||
          finished ||
          !eligible(activity, at) ||
          !prefs.reminders ||
          !permission.allowed ||
          !_active(row)) {
        await _cancel(
          row,
          activity == null || finished
              ? 'done'
              : !_active(row)
              ? row.state
              : !prefs.reminders || !permission.allowed
              ? 'disabled'
              : 'expired',
        );
      } else if (row.dueAt.isAfter(at)) {
        final lost =
            gateway.capabilities.pendingQuery &&
            !native.contains(row.notificationId);
        due.add((row, activity, lost));
      }
    }
    if (prefs.reminders && permission.allowed) {
      await _addNew(at, rows, due);
    }
    final missing = await _hrvMissing([
      for (final (_, a, _) in due) a.activityId,
    ]);
    for (final (row, activity, lost) in due) {
      final hint = missing.contains(activity.activityId);
      final text = _textOf(_notification(row, activity, hint));
      if (lost || row.scheduledText != text) {
        await _schedule(row, activity, hint);
      }
    }
  });

  Future<void> _addNew(
    DateTime at,
    List<NutritionReminderRecord> rows,
    List<(NutritionReminderRecord, ActivityRecord, bool)> out,
  ) async {
    final activities =
        await (db.select(db.activityRecords)..where(
              (t) => t.startDate.isBiggerOrEqualValue(
                at.subtract(const Duration(days: 3)),
              ),
            ))
            .get();
    var nextId =
        rows.fold<int>(
          nutritionNotificationBase - 1,
          (value, r) => r.notificationId > value ? r.notificationId : value,
        ) +
        1;
    for (final a in activities) {
      if (!eligible(a, at) || (await store.log(a.activityId)).finished) {
        continue;
      }
      final old = rows.where((r) => r.activityId == a.activityId).firstOrNull;
      if (old != null && old.state != 'disabled') continue;
      final end = a.startDate.add(
        Duration(seconds: nutritionElapsedSeconds(a)),
      );
      final ideal = end.add(const Duration(minutes: 30));
      final due = quietAdjusted(
        ideal.isAfter(at) ? ideal : at.add(const Duration(minutes: 1)),
      );
      if (due.difference(end) >= const Duration(hours: 24)) continue;
      final id = old?.notificationId ?? nextId++;
      if (id >= nutritionNotificationLimit) {
        throw StateError('Nutrition notification id range exhausted.');
      }
      final row = NutritionReminderRecord(
        activityId: a.activityId,
        token: const Uuid().v4(),
        notificationId: id,
        dueAt: due,
        state: 'scheduled',
      );
      await db.into(db.nutritionReminderRecords).insertOnConflictUpdate(row);
      out.add((row, a, true));
    }
  }

  /// Returns the exact activity to open, after validating current local state.
  Future<String?> handle(NotificationResponse response) => _serial(() async {
    final p = NutritionNotificationPayload.decode(response.payload);
    if (p == null) return null;
    final row = await (db.select(
      db.nutritionReminderRecords,
    )..where((t) => t.activityId.equals(p.activityId))).getSingleOrNull();
    final activity = await (db.select(
      db.activityRecords,
    )..where((t) => t.activityId.equals(p.activityId))).getSingleOrNull();
    if (row == null ||
        row.token != p.token ||
        !_active(row) ||
        activity == null ||
        !eligible(activity, now()) ||
        (await store.log(p.activityId)).finished ||
        !(await store.preferences()).reminders) {
      return null;
    }
    if (response.actionId == 'snooze') {
      final count = row.state == 'snoozed1'
          ? 2
          : row.state == 'snoozed2'
          ? 3
          : 1;
      final due = quietAdjusted(now().add(const Duration(minutes: 30)));
      final end = activity.startDate.add(
        Duration(seconds: nutritionElapsedSeconds(activity)),
      );
      if (count > 2 || due.difference(end) >= const Duration(hours: 24)) {
        await _cancel(row, 'dismissed');
      } else {
        final next = row.copyWith(
          token: const Uuid().v4(),
          dueAt: due,
          state: 'snoozed$count',
        );
        await db.into(db.nutritionReminderRecords).insertOnConflictUpdate(next);
        final missing = await _hrvMissing([activity.activityId]);
        await _schedule(next, activity, missing.contains(activity.activityId));
      }
      return null;
    }
    if (response.actionId == 'skip') {
      await _cancel(row, 'dismissed');
      return null;
    }
    if (!['open', 'log'].contains(response.actionId)) return null;
    await _cancel(row, 'opened');
    return row.activityId;
  });
}
