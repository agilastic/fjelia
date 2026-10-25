import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/spot_hrv.dart';
import 'package:fjelia/services/hrv/hrv_post_reminder_coordinator.dart';
import 'package:fjelia/services/hrv/hrv_post_reminder_policy.dart';
import 'package:fjelia/services/hrv/hrv_timing_policy.dart';
import 'package:fjelia/services/notifications/local_notification_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notification_gateway.dart';
import '../../support/hrv_db.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationGateway gateway;
  late HrvPostReminderCoordinator coordinator;
  var clock = atMin(-600);
  var sensor = true;

  HrvPostReminderCoordinator build() => HrvPostReminderCoordinator(
    db: db,
    gateway: gateway,
    sensorReady: () async => sensor,
    clock: () => clock,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
    clock = atMin(-600);
    sensor = true;
    coordinator = build();
  });
  tearDown(() => db.close());

  const before = SpotHrvContext.beforeTraining;
  const after = SpotHrvContext.afterTraining;

  /// Opted in early, one ride 0–120 min with a pre measurement.
  Future<void> ride({bool enable = true, bool withPre = true}) async {
    if (enable) await coordinator.setEnabled(true);
    await addActivity(db, 'a1', 0, 120);
    if (withPre) await addReading(db, -20, before, uid: 'pre');
  }

  Future<HrvPostReminder> reminder() =>
      db.select(db.hrvPostReminders).getSingle();

  Future<List<HrvNotificationOperation>> ops() =>
      db.select(db.hrvNotificationOperations).get();

  void at_(int minutes) => clock = atMin(minutes);

  group('scheduling', () {
    test('HRV-T051 one request, at the actual end plus 30 minutes', () async {
      await ride();
      at_(121);
      await coordinator.reconcile();
      expect(gateway.scheduled, hasLength(1));
      final n = gateway.scheduled.single;
      expect(n.at.toUtc(), atMin(150));
      expect(n.id, inInclusiveRange(hrvNativeIdBase, hrvNativeIdLimit));
      final p = HrvNotificationPayload.decode(n.payload)!;
      final r = await reminder();
      expect(p.reminderId, r.reminderId);
      expect(p.episodeId, r.episodeId);
      expect(p.generation, r.generation);
      expect(r.osState, 'accepted');
      expect(r.desiredState, 'scheduled');
      // The text is generic and promises no exact time.
      expect(n.body, isNot(contains('30')));
    });

    test(
      'HRV-T094 repeating the reconciliation never adds a request',
      () async {
        await ride();
        at_(121);
        for (var i = 0; i < 100; i++) {
          await coordinator.reconcile();
          coordinator = build(); // a restart in between
        }
        expect(gateway.scheduleCalls, 1);
        expect(await db.select(db.hrvPostReminders).get(), hasLength(1));
        expect(await ops(), hasLength(1));
      },
    );

    test('HRV-T052 nothing without opt-in, a pre or a sensor', () async {
      await ride(enable: false);
      at_(121);
      await coordinator.reconcile();
      expect(gateway.scheduleCalls, 0);

      await coordinator.setEnabled(true);
      sensor = false;
      await coordinator.reconcile();
      expect(gateway.scheduleCalls, 0);
    });

    test('no pre means no reminder row at all', () async {
      await ride(withPre: false);
      at_(121);
      await coordinator.reconcile();
      expect(gateway.scheduleCalls, 0);
      expect(await db.select(db.hrvPostReminders).get(), isEmpty);
    });

    test('HRV-T055 a workout found hours later is only history', () async {
      await ride();
      at_(300);
      await coordinator.reconcile();
      expect(gateway.scheduleCalls, 0);
      // Past the window the workout is history, not a reminder to keep.
      expect(await db.select(db.hrvPostReminders).get(), isEmpty);
    });

    test('a catch-up inside 15 minutes shows once, soon', () async {
      await ride();
      at_(160);
      await coordinator.reconcile();
      expect(gateway.scheduled, hasLength(1));
      expect(
        gateway.scheduled.single.at.difference(clock).inSeconds,
        inInclusiveRange(1, 5),
      );
      expect((await reminder()).originalDueAtUtc.toUtc(), atMin(150));
    });

    test('a historical import associates but never reminds', () async {
      await ride();
      at_(121);
      await coordinator.reconcile(historical: true);
      expect(gateway.scheduleCalls, 0);
    });

    test('a workout that ended before enabling never reminds', () async {
      await addActivity(db, 'a1', 0, 120);
      await addReading(db, -20, before);
      at_(125);
      await coordinator.setEnabled(true);
      await coordinator.reconcile();
      expect(gateway.scheduleCalls, 0);
      expect((await reminder()).reason, 'enabledAfterEnd');
    });

    test('an unknown end waits and plans nothing', () async {
      await addActivity(db, 'a1', 0, 120, source: 'manual');
      await coordinator.setEnabled(true);
      await addReading(db, -20, before);
      at_(130);
      await coordinator.reconcile();
      expect(gateway.scheduleCalls, 0);
      expect((await reminder()).desiredState, 'waitingForWorkout');
    });

    test('the end becoming known later schedules from the end', () async {
      await coordinator.setEnabled(true);
      await addReading(db, -20, before);
      await addActivity(db, 'a1', 0, 120, source: 'manual');
      at_(100);
      await coordinator.reconcile();
      expect(gateway.scheduleCalls, 0);
      await (db.update(
        db.activityRecords,
      )).write(const ActivityRecordsCompanion(source: Value('garmin_api')));
      at_(121);
      await coordinator.reconcile();
      expect(gateway.scheduled.single.at.toUtc(), atMin(150));
    });
  });

  group('completion and cancellation', () {
    test('HRV-T056 a usable post completes and removes the request', () async {
      await ride();
      at_(121);
      await coordinator.reconcile();
      final id = gateway.scheduled.single.id;
      at_(150);
      await addReading(db, 151, after, uid: 'post');
      at_(160);
      await coordinator.reconcile();
      expect((await reminder()).desiredState, 'completed');
      expect(gateway.cancelled, contains(id));
      expect(gateway.pending, isEmpty);
    });

    test('a post saved before the import never causes a reminder', () async {
      await coordinator.setEnabled(true);
      await addReading(db, -20, before);
      await addReading(db, 131, after);
      await addActivity(db, 'a1', 0, 120);
      at_(135);
      await coordinator.reconcile();
      expect(gateway.scheduleCalls, 0);
      expect(await db.select(db.hrvPostReminders).get(), isEmpty);
    });

    test('HRV-T057 an invalid attempt does not complete it', () async {
      await ride();
      at_(121);
      await coordinator.reconcile();
      await addReading(db, 151, after, quality: 'invalid');
      at_(160);
      await coordinator.reconcile();
      expect((await reminder()).desiredState, isNot('completed'));
      expect(gateway.pending, isNotEmpty);
    });

    test(
      'HRV-T060 deleting the post does not bring the reminder back',
      () async {
        await ride();
        at_(121);
        await coordinator.reconcile();
        await addReading(db, 151, after);
        at_(160);
        await coordinator.reconcile();
        final calls = gateway.scheduleCalls;
        await db.delete(db.spotHrvMeasurements).go();
        await addReading(db, -20, before);
        at_(165);
        await coordinator.reconcile();
        expect((await reminder()).desiredState, 'completed');
        expect(gateway.scheduleCalls, calls);
      },
    );

    test('turning it off cancels the owned request only', () async {
      await ride();
      at_(121);
      await coordinator.reconcile();
      gateway.pending[999] = gateway.scheduled.single; // someone else's
      await coordinator.setEnabled(false);
      expect(gateway.pending.keys, [999]);
      expect((await reminder()).desiredState, 'cancelled');
    });

    test('unpairing the strap cancels a running chain', () async {
      await ride();
      at_(121);
      await coordinator.reconcile();
      sensor = false;
      await coordinator.reconcile();
      expect(gateway.pending, isEmpty);
    });

    test('HRV-T025 a second workout retires the first reminder', () async {
      await ride();
      at_(121);
      await coordinator.reconcile();
      await addActivity(db, 'a2', 140, 30, source: 'coros');
      at_(145);
      await coordinator.reconcile();
      final first = (await db.select(db.hrvPostReminders).get()).single;
      expect(first.reason, 'interveningWorkout');
      expect(gateway.pending, isEmpty);
    });

    test('a deleted workout retires its reminder', () async {
      await ride();
      at_(121);
      await coordinator.reconcile();
      await db.delete(db.activityRecords).go();
      await coordinator.reconcile();
      expect((await reminder()).desiredState, 'cancelled');
      expect(gateway.pending, isEmpty);
    });

    test('HRV-T097 at the exact expiry nothing is scheduled or kept', () async {
      await ride();
      at_(121);
      await coordinator.reconcile();
      at_(210);
      await coordinator.reconcile();
      expect((await reminder()).desiredState, 'expired');
      expect(gateway.pending, isEmpty);
    });
  });

  group('permission', () {
    test(
      'HRV-T067 denied: suppressed, data fine, no repeated prompts',
      () async {
        gateway.state = NotificationPermission.denied;
        await ride();
        at_(121);
        await coordinator.reconcile();
        await coordinator.reconcile();
        expect(gateway.scheduleCalls, 0);
        expect(gateway.permissionRequests, isEmpty);
        expect((await reminder()).reason, 'permissionBlocked');
      },
    );

    test('allowing it later, inside the window, schedules', () async {
      gateway.state = NotificationPermission.denied;
      await ride();
      at_(121);
      await coordinator.reconcile();
      gateway.state = NotificationPermission.granted;
      await coordinator.reconcile();
      expect(gateway.scheduleCalls, 1);
    });

    test('enabling asks once, in context', () async {
      gateway.state = NotificationPermission.notDetermined;
      await coordinator.setEnabled(true);
      await coordinator.setEnabled(false);
      await coordinator.setEnabled(true);
      expect(gateway.permissionRequests, hasLength(1));
    });

    test('provisional counts as allowed', () async {
      gateway.state = NotificationPermission.provisional;
      await ride();
      at_(121);
      await coordinator.reconcile();
      expect(gateway.scheduleCalls, 1);
    });
  });

  group('failures and races', () {
    test('HRV-T092 a failing schedule is retried and still wanted', () async {
      await ride();
      gateway.scheduleError = StateError('platform');
      at_(121);
      await coordinator.reconcile();
      expect(await ops(), hasLength(1));
      expect((await ops()).single.state, 'pending');
      expect((await ops()).single.attempts, 1);
      expect((await reminder()).osState, 'failed');
      // The measurement and the workout are untouched.
      expect(await db.select(db.spotHrvMeasurements).get(), hasLength(1));

      gateway.scheduleError = null;
      at_(125);
      await coordinator.drain();
      expect(gateway.scheduled, hasLength(1));
      expect((await reminder()).osState, 'accepted');
    });

    test('a retry is abandoned once the window has closed', () async {
      await ride();
      gateway.scheduleError = StateError('platform');
      at_(121);
      await coordinator.reconcile();
      gateway.scheduleError = null;
      at_(300);
      await coordinator.reconcile();
      expect(gateway.scheduled, isEmpty);
    });

    test('HRV-T098 a failing cancel keeps the id until it works', () async {
      await ride();
      at_(121);
      await coordinator.reconcile();
      final id = gateway.scheduled.single.id;
      gateway.cancelError = StateError('platform');
      await addReading(db, 151, after);
      at_(160);
      await coordinator.reconcile();
      final pendingCancel = (await ops()).where((o) => o.state == 'pending');
      expect(pendingCancel.single.nativeNotificationId, id);
      expect(pendingCancel.single.operation, 'cancel');
      // The saved post is safe.
      expect(await db.select(db.spotHrvMeasurements).get(), hasLength(2));
      gateway.cancelError = null;
      at_(175);
      await coordinator.drain();
      expect(gateway.cancelled, contains(id));
      expect((await ops()).where((o) => o.state == 'pending'), isEmpty);
    });

    test(
      'HRV-T056 a post saved while the schedule call runs ends cancelled',
      () async {
        await ride();
        at_(121);
        gateway.duringSchedule = () async {
          await addReading(db, 151, after, uid: 'raced');
        };
        await coordinator.reconcile();
        gateway.duringSchedule = null;
        expect(gateway.pending, isNotEmpty); // the old call succeeded
        at_(160);
        await coordinator.reconcile();
        expect(gateway.pending, isEmpty);
        expect((await reminder()).desiredState, 'completed');
      },
    );

    test('HRV-T093 after a crash past the due time no second banner', () async {
      await ride();
      at_(121);
      await coordinator.reconcile();
      // The acknowledgement was lost: the operation looks unfinished.
      await (db.update(db.hrvNotificationOperations)).write(
        const HrvNotificationOperationsCompanion(
          state: Value('pending'),
          attempts: Value(1),
          claimedUntilUtc: Value(null),
        ),
      );
      final calls = gateway.scheduleCalls;
      at_(155);
      await coordinator.drain();
      expect(gateway.scheduleCalls, calls);
      expect((await reminder()).osState, 'unknown');
    });

    test('HRV-T088 a stale schedule never runs after a newer cancel', () async {
      await ride();
      at_(121);
      gateway.scheduleError = StateError('platform');
      await coordinator.reconcile();
      gateway.scheduleError = null;
      await coordinator.setEnabled(false);
      at_(130);
      await coordinator.drain();
      expect(gateway.scheduled, isEmpty);
      expect(gateway.pending, isEmpty);
    });

    test(
      'an unfinished operation is claimed by one runner at a time',
      () async {
        await ride();
        at_(121);
        gateway.scheduleError = StateError('platform');
        await coordinator.reconcile();
        gateway.scheduleError = null;
        final op = (await ops()).single;
        await (db.update(db.hrvNotificationOperations)).write(
          HrvNotificationOperationsCompanion(
            nextAttemptAtUtc: const Value(null),
            claimedUntilUtc: Value(clock.add(const Duration(minutes: 1))),
          ),
        );
        await coordinator.drain();
        expect(gateway.scheduled, isEmpty, reason: op.operationId);
      },
    );
  });

  group('actions', () {
    Future<NotificationResponse> response(String action) async {
      final r = await reminder();
      return NotificationResponse(
        actionId: action,
        payload: HrvNotificationPayload(
          epoch: r.installationEpoch,
          reminderId: r.reminderId,
          generation: r.generation,
          episodeId: r.episodeId,
        ).encode(),
      );
    }

    Future<void> due() async {
      await ride();
      at_(121);
      await coordinator.reconcile();
      at_(152);
    }

    test('measure goes to one capture, a repeat is a duplicate', () async {
      await due();
      final r = await response('measure');
      final first = await coordinator.handle(r);
      expect(first.kind, ActionKind.startMeasurement);
      expect(first.episodeId, (await reminder()).episodeId);
      expect((await coordinator.handle(r)).kind, ActionKind.duplicate);
    });

    test('HRV-T058 snooze once: now plus ten minutes, due kept', () async {
      await due();
      final r = await response('snooze');
      final result = await coordinator.handle(r);
      expect(result.kind, ActionKind.snoozed);
      final row = await reminder();
      expect(row.snoozeCount, 1);
      expect(row.nextDueAtUtc.toUtc(), atMin(162));
      expect(row.originalDueAtUtc.toUtc(), atMin(150));
      expect(gateway.scheduled.last.at.toUtc(), atMin(162));
      // The same callback again changes nothing.
      expect((await coordinator.handle(r)).kind, ActionKind.duplicate);
      expect((await reminder()).snoozeCount, 1);
      // A second snooze, even from the new notification, is refused.
      final again = await response('snooze');
      expect((await coordinator.handle(again)).kind, ActionKind.notAllowed);
    });

    test('a snooze that would cross the expiry is refused', () async {
      await due();
      at_(205);
      final r = await response('snooze');
      final result = await coordinator.handle(r);
      expect(result.kind, isNot(ActionKind.snoozed));
    });

    test('HRV-T059 skip is final, across sync and restart', () async {
      await due();
      final id = (await reminder()).nativeNotificationId;
      expect(
        (await coordinator.handle(await response('skip'))).kind,
        ActionKind.skipped,
      );
      expect(gateway.cancelled, contains(id));
      for (var i = 0; i < 3; i++) {
        coordinator = build();
        await coordinator.reconcile();
      }
      expect((await reminder()).desiredState, 'skipped');
      expect(gateway.pending, isEmpty);
    });

    test(
      'HRV-T066 wrong epoch, malformed or unknown payloads do nothing',
      () async {
        await due();
        final r = await reminder();
        Future<ActionKind> run(String? payload) async =>
            (await coordinator.handle(
              NotificationResponse(actionId: 'measure', payload: payload),
            )).kind;
        expect(await run(null), ActionKind.ignored);
        expect(await run('not json'), ActionKind.ignored);
        expect(await run('{"v":2}'), ActionKind.ignored);
        expect(
          await run(
            HrvNotificationPayload(
              epoch: 'other-install',
              reminderId: r.reminderId,
              generation: r.generation,
              episodeId: r.episodeId,
            ).encode(),
          ),
          ActionKind.ignored,
        );
        expect(
          await run(
            HrvNotificationPayload(
              epoch: r.installationEpoch,
              reminderId: 'missing',
              generation: 1,
              episodeId: 'missing',
            ).encode(),
          ),
          ActionKind.ignored,
        );
      },
    );

    test('an old generation opens the current state, not a capture', () async {
      await due();
      final old = await response('measure');
      await coordinator.handle(await response('snooze'));
      final result = await coordinator.handle(old);
      expect(result.kind, ActionKind.showEpisode);
    });

    test(
      'HRV-T021 after the post is saved, measure shows the workout',
      () async {
        await due();
        final r = await response('measure');
        await addReading(db, 151, after);
        final result = await coordinator.handle(r);
        expect(result.kind, ActionKind.showEpisode);
        expect(result.note, 'completed');
      },
    );

    test(
      'an action after the expiry shows the workout and expires it',
      () async {
        await due();
        final r = await response('measure');
        at_(215);
        final result = await coordinator.handle(r);
        expect(result.kind, ActionKind.showEpisode);
        expect((await reminder()).desiredState, 'expired');
      },
    );
  });

  group('lifecycle', () {
    test('bootstrap puts back a request the platform lost', () async {
      await ride();
      at_(121);
      await coordinator.reconcile();
      gateway.pending.clear();
      at_(125);
      await coordinator.bootstrap();
      expect(gateway.scheduled, hasLength(2));
      expect(gateway.pending, hasLength(1));
    });

    test('bootstrap cancels a stale owned request and spares others', () async {
      await ride();
      at_(121);
      await coordinator.reconcile();
      await addReading(db, 151, after);
      at_(160);
      gateway.cancelError = StateError('x');
      await coordinator.reconcile();
      gateway.cancelError = null;
      final foreign = gateway.scheduled.single;
      gateway.pending[42] = foreign;
      await coordinator.bootstrap();
      expect(gateway.pending.keys, [42]);
    });

    test(
      'HRV-T074 a restore invalidates the epoch and clears operations',
      () async {
        await ride();
        at_(121);
        await coordinator.reconcile();
        final old = await reminder();
        final id = old.nativeNotificationId;
        await coordinator.journalAndCancelAll();
        expect(gateway.cancelled, contains(id));
        await coordinator.afterRestore();
        expect(await db.select(db.hrvPostReminders).get(), isEmpty);
        expect(await ops(), isEmpty);
        final p = await coordinator.prefs();
        expect(p.optedIn, isFalse);
        expect(p.epoch, isNot(old.installationEpoch));
        // An old notification is harmless now.
        final result = await coordinator.handle(
          NotificationResponse(
            actionId: 'measure',
            payload: HrvNotificationPayload(
              epoch: old.installationEpoch,
              reminderId: old.reminderId,
              generation: old.generation,
              episodeId: old.episodeId,
            ).encode(),
          ),
        );
        expect(result.kind, ActionKind.ignored);
        // And nothing replays.
        at_(125);
        await coordinator.reconcile();
        expect(gateway.scheduled, hasLength(1));
      },
    );

    test('HRV-T079 a failing cancel keeps the id in the journal', () async {
      await ride();
      at_(121);
      await coordinator.reconcile();
      final id = (await reminder()).nativeNotificationId;
      gateway.cancelError = StateError('x');
      await coordinator.journalAndCancelAll();
      final journal = await db.select(db.hrvNativeCleanups).get();
      expect(journal.single.nativeNotificationId, id);
      gateway.cancelError = null;
      await coordinator.runCleanups();
      expect(await db.select(db.hrvNativeCleanups).get(), isEmpty);
    });

    test(
      'quiet hours suppress an evening reminder, never the next morning',
      () async {
        await coordinator.setEnabled(true);
        await coordinator.updateQuietHours(
          enabled: true,
          startMinute: 0,
          endMinute: 24 * 60 - 1,
        );
        await addActivity(db, 'a1', 0, 120);
        await addReading(db, -20, before);
        at_(121);
        await coordinator.reconcile();
        expect(gateway.scheduleCalls, 0);
        expect((await reminder()).reason, 'quietHours');
      },
    );

    test('HRV-T097 contradictory timing settings are inconsistent', () {
      expect(
        HrvPostReminderPolicy(
          policy: const HrvTimingPolicy(expiry: Duration(minutes: 20)),
        ).policy.consistent,
        isFalse,
      );
    });
  });
}
