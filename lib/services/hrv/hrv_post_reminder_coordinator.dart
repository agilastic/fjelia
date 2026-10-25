import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../db/database.dart';
import '../../models/hrv_training_episode.dart';
import '../notifications/local_notification_gateway.dart';
import 'hrv_post_reminder_policy.dart';
import 'hrv_timing_policy.dart';
import 'hrv_training_service.dart';

/// Native ids of this feature live in their own range, so a cleanup can never
/// touch a notification that belongs to something else.
const hrvNativeIdBase = 7000000;
const hrvNativeIdLimit = 7100000;

/// Version of the wording and layout, part of the schedule fingerprint.
const hrvReminderContentVersion = 1;

/// The reminder settings of this installation.
class HrvReminderPrefs {
  const HrvReminderPrefs({
    required this.optedIn,
    required this.epoch,
    required this.revision,
    this.enabledSince,
    this.delayMinutes = 30,
    this.quietEnabled = false,
    this.quietStartMinute = 22 * 60,
    this.quietEndMinute = 7 * 60,
    this.postponeInQuiet = false,
  });
  final bool optedIn;
  final String epoch;
  final int revision, delayMinutes, quietStartMinute, quietEndMinute;
  final DateTime? enabledSince;
  final bool quietEnabled, postponeInQuiet;
}

enum ActionKind {
  startMeasurement,
  showEpisode,
  snoozed,
  skipped,
  notAllowed,
  duplicate,
  ignored,
}

/// What the app should do after a notification action was validated.
class ActionResult {
  const ActionResult(this.kind, {this.episodeId, this.reminderId, this.note});
  final ActionKind kind;
  final String? episodeId, reminderId, note;
}

/// Durable execution of the post-training reminder.
///
/// The database says what should be true; the outbox is how the platform gets
/// there. Saving a measurement or importing a workout never waits for, or
/// fails because of, a platform call.
class HrvPostReminderCoordinator {
  HrvPostReminderCoordinator({
    required this.db,
    required this.gateway,
    required this.sensorReady,
    DateTime Function()? clock,
    this.policy = HrvTimingPolicy.standard,
    this.language = 'en',
    HrvTrainingService? training,
  }) : _clock = clock ?? DateTime.now,
       _reducer = HrvPostReminderPolicy(policy: policy),
       training =
           training ?? HrvTrainingService(db, clock: clock, policy: policy);

  final AppDatabase db;
  final LocalNotificationGateway gateway;

  /// True when an RR-capable strap is remembered and its integration is on.
  /// A current connection is not asked for.
  final Future<bool> Function() sensorReady;
  final HrvTimingPolicy policy;
  final String language;
  final HrvTrainingService training;
  final DateTime Function() _clock;
  final HrvPostReminderPolicy _reducer;
  static const _uuid = Uuid();
  static const _athlete = 'self';

  static final _tails = Expando<Future<void>>('hrv reminder writer');
  Future<T> _serialized<T>(Future<T> Function() body) {
    final result = (_tails[db] ?? Future.value()).then((_) => body());
    _tails[db] = result.then((_) {}, onError: (_) {});
    return result;
  }

  DateTime get now => _clock();

  // ── Preferences ──────────────────────────────────────────────────────────

  Future<HrvReminderPrefs> prefs() async {
    final row = await (db.select(
      db.hrvReminderPreferences,
    )..where((t) => t.athleteId.equals(_athlete))).getSingleOrNull();
    if (row != null) return _prefsOf(row);
    // The first read creates the row with the feature off.
    final epoch = _uuid.v4();
    await db
        .into(db.hrvReminderPreferences)
        .insert(
          HrvReminderPreferencesCompanion.insert(
            installationEpoch: epoch,
            updatedAtUtc: now.toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final created = await (db.select(
      db.hrvReminderPreferences,
    )..where((t) => t.athleteId.equals(_athlete))).getSingle();
    return _prefsOf(created);
  }

  HrvReminderPrefs _prefsOf(HrvReminderPreference r) => HrvReminderPrefs(
    optedIn: r.optedIn,
    epoch: r.installationEpoch,
    revision: r.revision,
    enabledSince: r.enabledSinceUtc,
    delayMinutes: r.delayMinutes,
    quietEnabled: r.quietEnabled,
    quietStartMinute: r.quietStartMinute,
    quietEndMinute: r.quietEndMinute,
    postponeInQuiet: r.postponeInQuiet,
  );

  /// Turns the reminder on or off. Turning it on asks the platform for
  /// permission once, in context; being refused leaves the feature on, with a
  /// reminder state that says why nothing is shown.
  Future<NotificationPermission> setEnabled(bool on) => _serialized(() async {
    final current = await prefs();
    var permission = await gateway.permission();
    if (on && permission == NotificationPermission.notDetermined) {
      permission = await gateway.requestPermission();
    }
    if (on == current.optedIn) return permission;
    await (db.update(
      db.hrvReminderPreferences,
    )..where((t) => t.athleteId.equals(_athlete))).write(
      HrvReminderPreferencesCompanion(
        optedIn: Value(on),
        // Enabling is not a request to notify about earlier workouts.
        enabledSinceUtc: Value(on ? now.toUtc() : current.enabledSince),
        revision: Value(current.revision + 1),
        updatedAtUtc: Value(now.toUtc()),
      ),
    );
    await _reconcile(historical: false);
    return permission;
  });

  Future<void> updateQuietHours({
    required bool enabled,
    int? startMinute,
    int? endMinute,
    bool? postpone,
  }) => _serialized(() async {
    final current = await prefs();
    await (db.update(
      db.hrvReminderPreferences,
    )..where((t) => t.athleteId.equals(_athlete))).write(
      HrvReminderPreferencesCompanion(
        quietEnabled: Value(enabled),
        quietStartMinute: Value(startMinute ?? current.quietStartMinute),
        quietEndMinute: Value(endMinute ?? current.quietEndMinute),
        postponeInQuiet: Value(postpone ?? current.postponeInQuiet),
        revision: Value(current.revision + 1),
        updatedAtUtc: Value(now.toUtc()),
      ),
    );
    await _reconcile(historical: false);
  });

  // ── Reconciliation ───────────────────────────────────────────────────────

  /// Brings facts, links and reminders in line, then runs the outbox. A
  /// historical import associates data but never raises a reminder.
  Future<void> reconcile({bool historical = false}) =>
      _serialized(() => _reconcile(historical: historical));

  Future<void> _reconcile({required bool historical}) async {
    final snapshot = await training.reconcile();
    await _applyReminders(snapshot, historical);
    await _drain();
  }

  Future<void> _applyReminders(HrvSnapshot snapshot, bool historical) async {
    final p = await prefs();
    final permission = await gateway.permission();
    final sensor = await sensorReady();
    final stamp = now;
    final quiet = p.quietEnabled
        ? QuietHours(p.quietStartMinute, p.quietEndMinute)
        : null;

    await db.transaction(() async {
      final rows = {
        for (final r in await db.select(db.hrvPostReminders).get())
          r.episodeId: r,
      };
      var inFlight = rows.values
          .where(
            (r) =>
                (r.desiredState == ReminderState.scheduled.name ||
                    r.desiredState == ReminderState.snoozed.name) &&
                r.nextDueAtUtc.isAfter(stamp),
          )
          .length;
      final ids = <String>{
        ...rows.keys,
        for (final e in snapshot.episodes)
          if (_candidate(snapshot, e.id, stamp)) e.id,
      };
      for (final id in ids) {
        final episode = snapshot.episode(id);
        final pairing = snapshot.pairings[id];
        final row = rows[id];
        final pre = pairing?.pre;
        final prev = row == null
            ? null
            : ReminderRecord(
                state: ReminderState.parse(row.desiredState),
                originalDue: row.originalDueAtUtc,
                nextDue: row.nextDueAtUtc,
                expires: row.expiresAtUtc,
                snoozeCount: row.snoozeCount,
                accepted: row.osState == 'accepted',
              );
        final gone = episode == null;
        final decision = _reducer.decide(
          ReminderInputs(
            now: stamp,
            optedIn: p.optedIn,
            sensorReady: sensor,
            permissionGranted: permission.allowed,
            enabledSince: p.enabledSince,
            interval: episode?.interval,
            hasUsablePre: pre != null && pre.usable && !pre.clockUncertain,
            hasUsablePost: pairing?.post?.usable ?? false,
            ambiguous:
                snapshot.assessments[id]?.association == Association.ambiguous,
            intervening: snapshot.intervening.contains(id),
            deleted: gone,
            historicalImport: historical,
            capacityFree: inFlight < policy.maxPlatformRequests,
            quietHours: quiet,
            postponeInQuietHours: p.postponeInQuiet,
            previous: prev,
          ),
        );
        if (row == null && pre == null) continue; // nothing to remind about
        final changed =
            row == null ||
            row.desiredState != decision.state.name ||
            row.reason != decision.reason.name ||
            decision.nextDue != null &&
                row.nextDueAtUtc.toUtc() != decision.nextDue!.toUtc() ||
            row.snoozeCount != decision.snoozeCount;
        if (!changed && decision.action == ReminderAction.none) continue;
        if (decision.action == ReminderAction.schedule && row == null) {
          inFlight++;
        }
        await _persist(
          row: row,
          episodeId: id,
          preUid: pre?.uid ?? row?.preMeasurementUid ?? '',
          decision: decision,
          prefs: p,
          permission: permission,
          stamp: stamp,
        );
      }
    });
  }

  /// An episode worth evaluating: a pre exists, no post, and the window is
  /// still open (or the end is not known yet).
  bool _candidate(HrvSnapshot s, String id, DateTime stamp) {
    final pairing = s.pairings[id];
    if (pairing?.pre == null || pairing?.post != null) return false;
    final end = s.episode(id)?.end;
    return end == null || stamp.isBefore(end.add(policy.expiry));
  }

  Future<void> _persist({
    required HrvPostReminder? row,
    required String episodeId,
    required String preUid,
    required ReminderDecision decision,
    required HrvReminderPrefs prefs,
    required NotificationPermission permission,
    required DateTime stamp,
  }) async {
    final due = decision.nextDue ?? row?.nextDueAtUtc ?? stamp;
    final original = decision.originalDue ?? row?.originalDueAtUtc ?? due;
    final expires = decision.expires ?? row?.expiresAtUtc ?? due;
    final wantsSchedule = decision.action == ReminderAction.schedule;
    final wantsCancel = decision.action == ReminderAction.cancel;
    final fingerprint = wantsSchedule
        ? _fingerprint(
            row?.reminderId ?? episodeId,
            due,
            expires,
            decision.snoozeCount,
            prefs,
          )
        : row?.scheduleFingerprint ?? '';
    final reminderId = row?.reminderId ?? _uuid.v4();
    var generation = row?.generation ?? 1;
    final materially =
        wantsCancel ||
        (wantsSchedule && fingerprint != row?.scheduleFingerprint);
    if (row != null && materially) generation++;
    final nativeId = row?.nativeNotificationId ?? await _allocateNativeId();

    if (row == null) {
      await db
          .into(db.hrvPostReminders)
          .insert(
            HrvPostRemindersCompanion.insert(
              reminderId: reminderId,
              episodeId: episodeId,
              preMeasurementUid: preUid,
              installationEpoch: prefs.epoch,
              nativeNotificationId: nativeId,
              generation: Value(generation),
              originalDueAtUtc: original.toUtc(),
              nextDueAtUtc: due.toUtc(),
              expiresAtUtc: expires.toUtc(),
              targetOffsetSeconds: policy.reminderOffset.inSeconds,
              snoozeCount: Value(decision.snoozeCount),
              desiredState: decision.state.name,
              reason: Value(decision.reason.name),
              osState: Value(wantsSchedule ? 'schedulePending' : 'none'),
              scheduleFingerprint: Value(fingerprint),
              permissionSnapshot: Value(permission.name),
              createdAtUtc: stamp.toUtc(),
              updatedAtUtc: stamp.toUtc(),
            ),
          );
    } else {
      await (db.update(
        db.hrvPostReminders,
      )..where((t) => t.reminderId.equals(reminderId))).write(
        HrvPostRemindersCompanion(
          preMeasurementUid: Value(
            preUid.isEmpty ? row.preMeasurementUid : preUid,
          ),
          generation: Value(generation),
          originalDueAtUtc: Value(original.toUtc()),
          nextDueAtUtc: Value(due.toUtc()),
          expiresAtUtc: Value(expires.toUtc()),
          snoozeCount: Value(decision.snoozeCount),
          desiredState: Value(decision.state.name),
          reason: Value(decision.reason.name),
          osState: Value(
            wantsSchedule
                ? 'schedulePending'
                : wantsCancel
                ? 'cancelPending'
                : row.osState,
          ),
          scheduleFingerprint: Value(fingerprint),
          permissionSnapshot: Value(permission.name),
          updatedAtUtc: Value(stamp.toUtc()),
        ),
      );
    }
    if (wantsSchedule || wantsCancel) {
      await _enqueue(
        reminderId: reminderId,
        generation: generation,
        operation: wantsSchedule ? 'schedule' : 'cancel',
        fingerprint: fingerprint,
        nativeId: nativeId,
        due: due,
        expires: expires,
        stamp: stamp,
      );
    }
  }

  String _fingerprint(
    String id,
    DateTime due,
    DateTime expires,
    int snoozes,
    HrvReminderPrefs p,
  ) => sha1
      .convert(
        utf8.encode(
          [
            id,
            due.toUtc().millisecondsSinceEpoch,
            expires.toUtc().millisecondsSinceEpoch,
            snoozes,
            p.revision,
            p.epoch,
            hrvReminderContentVersion,
          ].join('|'),
        ),
      )
      .toString()
      .substring(0, 16);

  Future<int> _allocateNativeId() async {
    final used = <int>{
      for (final r in await db.select(db.hrvPostReminders).get())
        r.nativeNotificationId,
      for (final c in await db.select(db.hrvNativeCleanups).get())
        c.nativeNotificationId,
    };
    for (var id = hrvNativeIdBase + 1; id < hrvNativeIdLimit; id++) {
      if (!used.contains(id)) return id;
    }
    throw StateError('No free notification id.');
  }

  /// One operation per reminder, generation and kind. A newer operation
  /// supersedes older pending ones of the same reminder.
  Future<void> _enqueue({
    required String reminderId,
    required int generation,
    required String operation,
    required String fingerprint,
    required int nativeId,
    required DateTime due,
    required DateTime expires,
    required DateTime stamp,
  }) async {
    final duplicate =
        await (db.select(db.hrvNotificationOperations)..where(
              (t) =>
                  t.reminderId.equals(reminderId) &
                  t.generation.equals(generation) &
                  t.operation.equals(operation),
            ))
            .getSingleOrNull();
    if (duplicate != null) return;
    await (db.update(db.hrvNotificationOperations)..where(
          (t) => t.reminderId.equals(reminderId) & t.state.equals('pending'),
        ))
        .write(
          const HrvNotificationOperationsCompanion(state: Value('superseded')),
        );
    await db
        .into(db.hrvNotificationOperations)
        .insert(
          HrvNotificationOperationsCompanion.insert(
            operationId: _uuid.v4(),
            reminderId: reminderId,
            generation: generation,
            operation: operation,
            fingerprint: Value(fingerprint),
            nativeNotificationId: nativeId,
            dueAtUtc: Value(due.toUtc()),
            expiresAtUtc: Value(expires.toUtc()),
            createdAtUtc: stamp.toUtc(),
          ),
        );
  }

  // ── Outbox ───────────────────────────────────────────────────────────────

  /// Runs pending operations. Failures are kept and retried with a bounded
  /// backoff while the operation is still wanted.
  Future<void> drain() => _serialized(_drain);

  Future<void> _drain() async {
    for (var round = 0; round < 25; round++) {
      final stamp = now.toUtc();
      final ready =
          await (db.select(db.hrvNotificationOperations)
                ..where(
                  (t) =>
                      t.state.equals('pending') &
                      (t.nextAttemptAtUtc.isNull() |
                          t.nextAttemptAtUtc.isSmallerOrEqualValue(stamp)) &
                      (t.claimedUntilUtc.isNull() |
                          t.claimedUntilUtc.isSmallerThanValue(stamp)),
                )
                ..orderBy([
                  (t) => OrderingTerm(expression: t.createdAtUtc),
                  (t) => OrderingTerm(expression: t.generation),
                ])
                ..limit(1))
              .get();
      if (ready.isEmpty) return;
      final op = ready.single;
      // A lease another isolate cannot also take.
      final claimed =
          await (db.update(db.hrvNotificationOperations)..where(
                (t) =>
                    t.operationId.equals(op.operationId) &
                    t.state.equals('pending') &
                    (t.claimedUntilUtc.isNull() |
                        t.claimedUntilUtc.isSmallerThanValue(stamp)),
              ))
              .write(
                HrvNotificationOperationsCompanion(
                  claimedUntilUtc: Value(stamp.add(const Duration(minutes: 1))),
                ),
              );
      if (claimed == 0) continue;
      await _execute(op);
    }
  }

  Future<void> _execute(HrvNotificationOperation op) async {
    final reminder = await (db.select(
      db.hrvPostReminders,
    )..where((t) => t.reminderId.equals(op.reminderId))).getSingleOrNull();
    final stamp = now;
    Future<void> finish(String state, {String? error, bool failed = false}) =>
        (db.update(
          db.hrvNotificationOperations,
        )..where((t) => t.operationId.equals(op.operationId))).write(
          HrvNotificationOperationsCompanion(
            state: Value(state),
            claimedUntilUtc: const Value(null),
            lastError: Value(error),
            attempts: Value(op.attempts + (failed ? 1 : 0)),
          ),
        );
    Future<void> retry(Object e, {required bool stillWanted}) async {
      if (!stillWanted) {
        return finish('superseded', error: e.runtimeType.toString());
      }
      final backoff = Duration(
        seconds: (30 * (1 << op.attempts.clamp(0, 5))).clamp(30, 900),
      );
      await (db.update(
        db.hrvNotificationOperations,
      )..where((t) => t.operationId.equals(op.operationId))).write(
        HrvNotificationOperationsCompanion(
          attempts: Value(op.attempts + 1),
          claimedUntilUtc: const Value(null),
          nextAttemptAtUtc: Value(stamp.toUtc().add(backoff)),
          lastError: Value(e.runtimeType.toString()),
        ),
      );
      if (reminder != null) {
        await (db.update(
          db.hrvPostReminders,
        )..where((t) => t.reminderId.equals(reminder.reminderId))).write(
          HrvPostRemindersCompanion(
            osState: const Value('failed'),
            lastAttemptAt: Value(stamp.toUtc()),
            lastError: Value(e.runtimeType.toString()),
          ),
        );
      }
    }

    if (op.operation == 'cancel') {
      try {
        await gateway.cancel(op.nativeNotificationId);
      } catch (e) {
        // Keep the id: it is what is needed to remove the stale request.
        return retry(e, stillWanted: true);
      }
      await finish('done');
      await _setOs(op, 'none');
      return;
    }

    // A schedule only runs for the reminder's current generation and while
    // it is still wanted.
    final wanted =
        reminder != null &&
        reminder.generation == op.generation &&
        (reminder.desiredState == ReminderState.scheduled.name ||
            reminder.desiredState == ReminderState.snoozed.name) &&
        stamp.isBefore(reminder.expiresAtUtc);
    if (!wanted) return finish('superseded');
    final permission = await gateway.permission();
    if (!permission.allowed) {
      await finish('superseded', error: 'permission');
      await _setOs(op, 'failed', error: 'permission');
      return;
    }
    // After a crash the call may or may not have happened. Past its due
    // time, do not risk a second banner.
    if (op.attempts > 0 && !reminder.nextDueAtUtc.isAfter(stamp)) {
      await finish('done');
      await _setOs(op, 'unknown');
      return;
    }
    final texts = HrvReminderTexts.forLanguage(language);
    final at = reminder.nextDueAtUtc.isAfter(stamp)
        ? reminder.nextDueAtUtc
        : stamp.add(const Duration(seconds: 2));
    try {
      await gateway.schedule(
        ScheduledNotification(
          id: reminder.nativeNotificationId,
          at: at,
          title: texts.title,
          body: texts.body,
          actionLabels: texts.actionLabels,
          payload: HrvNotificationPayload(
            epoch: reminder.installationEpoch,
            reminderId: reminder.reminderId,
            generation: reminder.generation,
            episodeId: reminder.episodeId,
          ).encode(),
        ),
      );
    } catch (e) {
      return retry(
        e,
        stillWanted:
            stamp.isBefore(reminder.expiresAtUtc) &&
            (reminder.nextDueAtUtc.isAfter(stamp) || op.attempts < 3),
      );
    }
    await finish('done');
    await _setOs(op, 'accepted');
  }

  /// Records the platform outcome only if the operation is still the current
  /// one, so an old completion never overwrites a newer cancellation.
  Future<void> _setOs(
    HrvNotificationOperation op,
    String state, {
    String? error,
  }) =>
      (db.update(db.hrvPostReminders)..where(
            (t) =>
                t.reminderId.equals(op.reminderId) &
                t.generation.equals(op.generation),
          ))
          .write(
            HrvPostRemindersCompanion(
              osState: Value(state),
              lastAttemptAt: Value(now.toUtc()),
              lastError: Value(error),
            ),
          );

  // ── Notification actions ─────────────────────────────────────────────────

  /// Validates a notification response against the current data and applies
  /// snooze or skip. Measure and open only return where to go: nothing here
  /// starts Bluetooth.
  ///
  /// [at] is when the athlete acted, if that was earlier than now (an action
  /// taken while the app was closed). A snooze counts from that moment.
  Future<ActionResult> handle(NotificationResponse response, {DateTime? at}) =>
      _serialized(() => _handle(response, at));

  Future<ActionResult> _handle(
    NotificationResponse response,
    DateTime? at,
  ) async {
    final payload = HrvNotificationPayload.decode(response.payload);
    if (payload == null) return const ActionResult(ActionKind.ignored);
    final p = await prefs();
    if (payload.epoch != p.epoch) {
      return const ActionResult(ActionKind.ignored, note: 'epoch');
    }
    final reminder = await (db.select(
      db.hrvPostReminders,
    )..where((t) => t.reminderId.equals(payload.reminderId))).getSingleOrNull();
    if (reminder == null || reminder.episodeId != payload.episodeId) {
      // Follow a merged copy before giving up.
      final episode = await (db.select(
        db.hrvTrainingEpisodes,
      )..where((t) => t.episodeId.equals(payload.episodeId))).getSingleOrNull();
      return ActionResult(
        episode == null ? ActionKind.ignored : ActionKind.showEpisode,
        episodeId: episode?.episodeId,
      );
    }
    final kind = response.actionId;
    final state = ReminderState.parse(reminder.desiredState);
    final expired = !now.isBefore(reminder.expiresAtUtc);

    if (kind == 'snooze' || kind == 'skip') {
      final dup = await _receipt(p.epoch, reminder, payload.generation, kind);
      if (!dup) {
        return const ActionResult(ActionKind.duplicate);
      }
      if (payload.generation != reminder.generation || state.terminal) {
        return ActionResult(
          ActionKind.showEpisode,
          episodeId: reminder.episodeId,
          reminderId: reminder.reminderId,
        );
      }
      if (expired) {
        await _reconcile(historical: false);
        return ActionResult(
          ActionKind.showEpisode,
          episodeId: reminder.episodeId,
          note: 'expired',
        );
      }
      return kind == 'snooze'
          ? _snooze(reminder, p, at ?? now)
          : _skip(reminder, p);
    }

    // measure or open: always lands somewhere safe.
    await _reconcile(historical: false);
    final current = await (db.select(
      db.hrvPostReminders,
    )..where((t) => t.reminderId.equals(reminder.reminderId))).getSingle();
    final now0 = ReminderState.parse(current.desiredState);
    final usable =
        !now0.terminal &&
        payload.generation == current.generation &&
        now.isBefore(current.expiresAtUtc);
    if (kind == 'measure' && usable) {
      final dup = await _receipt(p.epoch, current, payload.generation, kind);
      if (!dup) return const ActionResult(ActionKind.duplicate);
      return ActionResult(
        ActionKind.startMeasurement,
        episodeId: current.episodeId,
        reminderId: current.reminderId,
      );
    }
    return ActionResult(
      ActionKind.showEpisode,
      episodeId: current.episodeId,
      reminderId: current.reminderId,
      note: now0.terminal ? now0.name : 'stale',
    );
  }

  /// True the first time an action is seen.
  Future<bool> _receipt(
    String epoch,
    HrvPostReminder reminder,
    int generation,
    String kind,
  ) async {
    final seen =
        await (db.select(db.hrvNotificationActionReceipts)..where(
              (t) =>
                  t.installationEpoch.equals(epoch) &
                  t.reminderId.equals(reminder.reminderId) &
                  t.generation.equals(generation) &
                  t.actionKind.equals(kind),
            ))
            .getSingleOrNull();
    if (seen != null) return false;
    await db
        .into(db.hrvNotificationActionReceipts)
        .insert(
          HrvNotificationActionReceiptsCompanion.insert(
            installationEpoch: epoch,
            reminderId: reminder.reminderId,
            generation: generation,
            actionKind: kind,
            handledAtUtc: now.toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return true;
  }

  Future<ActionResult> _snooze(
    HrvPostReminder row,
    HrvReminderPrefs p,
    DateTime acted,
  ) async {
    final prev = ReminderRecord(
      state: ReminderState.parse(row.desiredState),
      originalDue: row.originalDueAtUtc,
      nextDue: row.nextDueAtUtc,
      expires: row.expiresAtUtc,
      snoozeCount: row.snoozeCount,
    );
    final snapshot = await training.reconcile();
    final pairing = snapshot.pairings[row.episodeId];
    // Revalidate before putting a new request on the clock.
    if (pairing?.post != null || snapshot.intervening.contains(row.episodeId)) {
      await _applyReminders(snapshot, false);
      await _drain();
      return ActionResult(ActionKind.showEpisode, episodeId: row.episodeId);
    }
    final decision = _reducer.snooze(prev, acted);
    if (decision == null) {
      return ActionResult(ActionKind.notAllowed, episodeId: row.episodeId);
    }
    await db.transaction(
      () => _persist(
        row: row,
        episodeId: row.episodeId,
        preUid: row.preMeasurementUid,
        decision: decision,
        prefs: p,
        permission: NotificationPermission.granted,
        stamp: now,
      ),
    );
    await _drain();
    return ActionResult(
      ActionKind.snoozed,
      episodeId: row.episodeId,
      reminderId: row.reminderId,
    );
  }

  Future<ActionResult> _skip(HrvPostReminder row, HrvReminderPrefs p) async {
    final prev = ReminderRecord(
      state: ReminderState.parse(row.desiredState),
      originalDue: row.originalDueAtUtc,
      nextDue: row.nextDueAtUtc,
      expires: row.expiresAtUtc,
      snoozeCount: row.snoozeCount,
    );
    final decision = _reducer.decide(
      ReminderInputs(
        now: now,
        optedIn: true,
        sensorReady: true,
        permissionGranted: true,
        previous: prev,
        skipRequested: true,
      ),
    );
    await db.transaction(
      () => _persist(
        row: row,
        episodeId: row.episodeId,
        preUid: row.preMeasurementUid,
        decision: decision,
        prefs: p,
        permission: NotificationPermission.granted,
        stamp: now,
      ),
    );
    await _drain();
    return ActionResult(
      ActionKind.skipped,
      episodeId: row.episodeId,
      reminderId: row.reminderId,
    );
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// After start or resume: reconcile, remove stale requests of this feature,
  /// and put back a request the platform lost before it was due.
  Future<void> bootstrap() => _serialized(() async {
    await _reconcile(historical: false);
    await _settleNative();
  });

  Future<void> _settleNative() async {
    if (!gateway.capabilities.pendingQuery) return;
    final pending = await gateway.pendingIds();
    final reminders = await db.select(db.hrvPostReminders).get();
    final wanted = {
      for (final r in reminders)
        if (r.desiredState == ReminderState.scheduled.name ||
            r.desiredState == ReminderState.snoozed.name)
          r.nativeNotificationId,
    };
    final owned = {
      for (final r in reminders) r.nativeNotificationId,
      for (final c in await db.select(db.hrvNativeCleanups).get())
        c.nativeNotificationId,
    };
    for (final id in pending) {
      final ours = id >= hrvNativeIdBase && id < hrvNativeIdLimit;
      // Only ids of this feature; anything else belongs to someone else.
      if (ours && !wanted.contains(id) && owned.contains(id)) {
        try {
          await gateway.cancel(id);
        } catch (_) {}
      }
    }
    final stamp = now;
    final p = await prefs();
    for (final r in reminders) {
      final lost =
          wanted.contains(r.nativeNotificationId) &&
          r.osState == 'accepted' &&
          r.nextDueAtUtc.isAfter(stamp.add(const Duration(seconds: 30))) &&
          !pending.contains(r.nativeNotificationId);
      if (!lost) continue;
      await db.transaction(() async {
        final generation = r.generation + 1;
        await (db.update(
          db.hrvPostReminders,
        )..where((t) => t.reminderId.equals(r.reminderId))).write(
          HrvPostRemindersCompanion(
            generation: Value(generation),
            osState: const Value('schedulePending'),
            updatedAtUtc: Value(stamp.toUtc()),
          ),
        );
        await _enqueue(
          reminderId: r.reminderId,
          generation: generation,
          operation: 'schedule',
          fingerprint: r.scheduleFingerprint,
          nativeId: r.nativeNotificationId,
          due: r.nextDueAtUtc,
          expires: r.expiresAtUtc,
          stamp: stamp,
        );
      });
    }
    if (p.optedIn) await _drain();
  }

  // ── Restore and erasure ──────────────────────────────────────────────────

  /// Before the tables are replaced or erased: remember every native id so
  /// the stale requests can still be removed, then try to remove them.
  Future<void> journalAndCancelAll() => _serialized(() async {
    final p = await prefs();
    final stamp = now.toUtc();
    final ids = <int>{
      for (final r in await db.select(db.hrvPostReminders).get())
        r.nativeNotificationId,
      for (final o in await db.select(db.hrvNotificationOperations).get())
        o.nativeNotificationId,
    };
    for (final id in ids) {
      await db
          .into(db.hrvNativeCleanups)
          .insert(
            HrvNativeCleanupsCompanion.insert(
              nativeNotificationId: Value(id),
              installationEpoch: p.epoch,
              createdAtUtc: stamp,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    await _runCleanups();
  });

  /// Tries every journalled removal; an id leaves the journal only once the
  /// platform confirmed it.
  Future<void> runCleanups() => _serialized(_runCleanups);

  Future<void> _runCleanups() async {
    for (final c in await db.select(db.hrvNativeCleanups).get()) {
      try {
        await gateway.cancel(c.nativeNotificationId);
        await (db.delete(db.hrvNativeCleanups)..where(
              (t) => t.nativeNotificationId.equals(c.nativeNotificationId),
            ))
            .go();
      } catch (e) {
        await (db.update(db.hrvNativeCleanups)..where(
              (t) => t.nativeNotificationId.equals(c.nativeNotificationId),
            ))
            .write(
              HrvNativeCleanupsCompanion(
                lastError: Value(e.runtimeType.toString()),
              ),
            );
      }
    }
  }

  /// After a restore: a new installation epoch, the reminder off, and no
  /// operational state carried over. Associations are rebuilt from facts.
  Future<void> afterRestore() => _serialized(() async {
    await db.transaction(() async {
      await db.delete(db.hrvNotificationOperations).go();
      await db.delete(db.hrvNotificationActionReceipts).go();
      await db.delete(db.hrvPostReminders).go();
      final row = await (db.select(
        db.hrvReminderPreferences,
      )..where((t) => t.athleteId.equals(_athlete))).getSingleOrNull();
      final epoch = _uuid.v4();
      if (row == null) {
        await db
            .into(db.hrvReminderPreferences)
            .insert(
              HrvReminderPreferencesCompanion.insert(
                installationEpoch: epoch,
                updatedAtUtc: now.toUtc(),
              ),
            );
      } else {
        await (db.update(
          db.hrvReminderPreferences,
        )..where((t) => t.athleteId.equals(_athlete))).write(
          HrvReminderPreferencesCompanion(
            optedIn: const Value(false),
            enabledSinceUtc: const Value(null),
            installationEpoch: Value(epoch),
            revision: Value(row.revision + 1),
            updatedAtUtc: Value(now.toUtc()),
          ),
        );
      }
    });
    await db.ensureHrvIdentity();
    await training.reconcile();
    await _runCleanups();
  });
}
