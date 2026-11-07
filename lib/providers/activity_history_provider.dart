import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import 'database_provider.dart';
import 'hrv_reminder_provider.dart';
import 'nutrition_provider.dart';
import 'strength_provider.dart';
import 'day_data_provider.dart';
import 'training_load_provider.dart';
import '../utils/log.dart';
import 'planner_providers.dart';
import 'coros_provider.dart';
import 'health_connect_provider.dart';
import 'polar_provider.dart';
import 'suunto_provider.dart';
import 'mywhoosh_provider.dart';
import 'sync_provider.dart';

final loadActivitiesProvider = FutureProvider<List<ActivityRecord>>((
  ref,
) async {
  ref.watch(syncStatusListenerProvider);
  return (await ref.watch(databaseProvider).getActivitiesInRange(365))
    ..sort((a, b) => b.startDate.compareTo(a.startDate));
});

/// The day's strain from the activities it still has, without replacing
/// unrelated daily scores. With none left the old load is no longer known.
Future<void> _refreshDayStrain(AppDatabase db, DateTime start) async {
  final local = start.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final score = await db.getScoreForDate(day);
  if (score == null) return;
  final remaining =
      await (db.select(db.activityRecords)..where(
            (t) =>
                t.startDate.isBiggerOrEqualValue(day) &
                t.startDate.isSmallerThanValue(
                  DateTime(day.year, day.month, day.day + 1),
                ),
          ))
          .get();
  await (db.update(
    db.dayScoreRecords,
  )..where((t) => t.date.equals(score.date))).write(
    DayScoreRecordsCompanion(
      strainScore: Value(
        remaining.isEmpty
            ? null
            : remaining.fold<double>(0, (sum, a) => sum + effectiveLoad(a)),
      ),
    ),
  );
}

/// How many days the Plan list shows beyond its first weeks; scrolling to
/// the end adds more.
final historyExtraDaysProvider = StateProvider<int>((ref) => 0);

DateTime _lastRequest = DateTime(0);

/// Six more weeks for the Plan list, at most every 600 ms: a scroll that
/// stays at the end does not ask for years at once.
void requestOlderActivities(WidgetRef ref, {bool scrolled = true}) {
  final now = DateTime.now();
  if (scrolled &&
      now.difference(_lastRequest) < const Duration(milliseconds: 600)) {
    return;
  }
  final oldest = ref.read(oldestActivityProvider).valueOrNull;
  final from = ref.read(historyWindowStartProvider);
  // Everything is shown already.
  if (oldest == null || from == null || !oldest.isBefore(from)) return;
  _lastRequest = now;
  ref.read(historyExtraDaysProvider.notifier).state += 42;
}

/// The first day the Plan list shows now, set by the list itself.
final historyWindowStartProvider = StateProvider<DateTime?>((ref) => null);

/// The activities of the last [days] days, newest first, with no limit to
/// the past (a Strava archive reaches back many years).
final historyActivitiesProvider =
    FutureProvider.family<List<ActivityRecord>, int>((ref, days) async {
      ref.watch(syncStatusListenerProvider);
      return (await ref.watch(databaseProvider).getActivitiesInRange(days))
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
    });

/// The start of the oldest activity, so the list knows when it is complete.
final oldestActivityProvider = FutureProvider<DateTime?>((ref) async {
  ref.watch(syncStatusListenerProvider);
  final db = ref.watch(databaseProvider);
  return (await (db.select(db.activityRecords)
            ..orderBy([(t) => OrderingTerm(expression: t.startDate)])
            ..limit(1))
          .getSingleOrNull())
      ?.startDate;
});

void _activitiesChanged(Ref ref) {
  ref.invalidate(loadActivitiesProvider);
  ref.invalidate(historyActivitiesProvider);
  ref.invalidate(oldestActivityProvider);
  ref.invalidate(deletedActivitiesProvider);
  ref.invalidate(trainingLoadProvider);
  ref.invalidate(trainingMonitorProvider);
  ref.invalidate(trainingFormSeriesProvider);
  invalidateStrength(ref.invalidate);
  ref.read(syncStatusListenerProvider.notifier).state++;
}

/// Activities the athlete deleted, newest deletion first.
final deletedActivitiesProvider = FutureProvider<List<DeletedActivity>>(
  (ref) => ref.watch(databaseProvider).getDeletedActivities(),
);

/// Deletes an activity for good: it is remembered as deleted, so no sync
/// brings it back, and it can be restored from Recently deleted. The
/// athlete's photos and videos of it are kept for that.
final deleteActivityProvider = Provider<Future<void> Function(String)>(
  (ref) => (id) async {
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      final activity = await db.getActivityById(id);
      await db.deleteActivityByUser(id);
      await (db.delete(
        db.nutritionRecords,
      )..where((t) => t.recordKey.equals('intake:$id'))).go();
      if (activity != null) await _refreshDayStrain(db, activity.startDate);
    });
    // The session it completed is open again, and what it moved goes back.
    try {
      final changes = await ref.read(planReconcilerProvider).forgetActivity(id);
      await ref.read(applyPlanChangesProvider)(changes);
    } catch (e) {
      log('[Delete] plan for $id: $e');
    }
    _activitiesChanged(ref);
    // The workout is gone; its HRV readings stay, its reminder does not.
    await ref.read(hrvReminderActionsProvider).reconcile();
    await ref.read(nutritionReminderProvider).reconcile();
  },
);

/// What a restore did: the activity is back; [refetched] when its source
/// was asked for route and curves again.
typedef ActivityRestore = ({ActivityRecord? activity, bool refetched});

/// Brings a deleted activity back: at once from its summary, then from its
/// source, which fills in route, curves and details where it still has them.
final restoreActivityProvider =
    Provider<Future<ActivityRestore> Function(String)>(
      (ref) => (id) async {
        final db = ref.read(databaseProvider);
        final activity = await db.restoreDeletedActivity(id);
        if (activity == null) return (activity: null, refetched: false);
        await _refreshDayStrain(db, activity.startDate);
        // It completes its session again, or is placed as before.
        try {
          await ref.read(postWorkoutScorerProvider).scoreIfUnscored(activity);
          final changes = await ref.read(planReconcilerProvider).reconcile();
          await ref.read(applyPlanChangesProvider)(changes);
        } catch (e) {
          log('[Restore] plan for $id: $e');
        }
        _activitiesChanged(ref);
        var refetched = false;
        try {
          refetched = await _refetch(ref, activity);
        } catch (e) {
          log('[Restore] $id from ${activity.source}: $e');
        }
        if (refetched) {
          await _refreshDayStrain(db, activity.startDate);
          _activitiesChanged(ref);
        }
        return (
          activity: await db.getActivityById(id) ?? activity,
          refetched: refetched,
        );
      },
    );

/// Asks the activity's own source for it again, for its date only.
Future<bool> _refetch(Ref ref, ActivityRecord a) async {
  final day = a.startDate;
  final days = DateTime.now().difference(day).inDays + 2;
  // Polar Flow history sessions are stored as 'polar' too.
  if (a.activityId.startsWith('polar_flow_')) {
    return await ref.read(polarServiceProvider).importFlowHistory(days: days) >
        0;
  }
  switch (a.source) {
    case 'garmin_api':
      return ref
          .read(syncServiceProvider)
          .refetchGarminActivity(a.activityId, day);
    case 'coros':
      final coros = ref.read(corosServiceProvider);
      if (!await coros.isConnected) return false;
      await coros.refetchActivitiesAround(day);
      return true;
    case 'suunto':
      final suunto = ref.read(suuntoServiceProvider);
      if (!await suunto.isConnected) return false;
      await suunto.refetchWorkoutsSince(day.subtract(const Duration(days: 1)));
      return true;
    case 'mywhoosh':
      final myWhoosh = ref.read(myWhooshServiceProvider);
      if (!await myWhoosh.isConnected) return false;
      await myWhoosh.refetchSince(day.subtract(const Duration(days: 1)));
      return true;
    case 'polar':
      final polar = ref.read(polarServiceProvider);
      // Polar's interface only lists the last 30 days.
      if (!await polar.isConnected || days > 30) return false;
      await polar.sync(days: days);
      return true;
    case 'health_connect':
      await ref
          .read(healthConnectServiceProvider)
          .syncWorkoutsBetween(
            day.subtract(const Duration(hours: 1)),
            day.add(Duration(seconds: a.durationSeconds + 3600)),
          );
      return true;
    default:
      // A file, a manual entry or a live workout has no source to ask.
      return false;
  }
}

/// The name an activity shows now, and whether the athlete gave it.
typedef ActivityName = ({String name, bool edited, String? original});

final activityNameProvider = FutureProvider.autoDispose
    .family<ActivityName, String>((ref, id) async {
      ref.watch(syncStatusListenerProvider);
      final db = ref.watch(databaseProvider);
      final a = await db.getActivityById(id);
      final title = await db.activityTitle(id);
      return (
        name: a?.name ?? '',
        edited: title != null,
        original: title?.originalName,
      );
    });

/// Renames an activity in Fjelia only; null or blank goes back to the
/// provider's name. Nothing is sent to the provider.
final renameActivityProvider =
    Provider<Future<void> Function(String id, String? title)>(
      (ref) => (id, title) async {
        final db = ref.read(databaseProvider);
        final clean = title?.trim() ?? '';
        clean.isEmpty
            ? await db.resetActivityTitle(id)
            : await db.renameActivity(id, clean);
        ref.invalidate(activityNameProvider(id));
        _activitiesChanged(ref);
      },
    );
