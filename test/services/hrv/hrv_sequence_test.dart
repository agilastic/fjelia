import 'dart:math';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/spot_hrv.dart';
import 'package:fjelia/services/hrv/hrv_post_reminder_coordinator.dart';
import 'package:fjelia/services/hrv/hrv_post_reminder_policy.dart';
import 'package:fjelia/services/notifications/local_notification_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notification_gateway.dart';
import '../../support/hrv_db.dart';

/// Random sequences of everything that can happen to a workout, a reading and
/// the setting, in any order. After every step the invariants hold: the same
/// ones the guide lists as HRV-R01–30, as far as they are about stored state.
void main() {
  for (var seed = 0; seed < 40; seed++) {
    test('invariants hold after every step (seed $seed)', () async {
      final random = Random(seed);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final gateway = FakeNotificationGateway();
      var clock = atMin(-600);
      HrvPostReminderCoordinator build() => HrvPostReminderCoordinator(
        db: db,
        gateway: gateway,
        sensorReady: () async => true,
        clock: () => clock,
      );
      var coordinator = build();
      final terminalSeen = <String, String>{};
      var activities = 0, readings = 0;
      final log = <String>[];

      Future<void> step() async {
        final action = random.nextInt(14);
        switch (action) {
          case 0:
          case 1:
            final start = random.nextInt(400);
            final length = 20 + random.nextInt(120);
            log.add('activity@$start+$length');
            await addActivity(
              db,
              'a${activities++}',
              start,
              length,
              source: random.nextInt(8) == 0 ? 'manual' : 'garmin_api',
            );
          case 2:
          case 3:
            log.add('pre');
            await addReading(
              db,
              random.nextInt(400) - 40,
              SpotHrvContext.beforeTraining,
              rmssd: 30 + random.nextInt(60).toDouble(),
              quality: random.nextInt(10) == 0 ? 'invalid' : 'usable',
              uid: 'm${readings++}',
            );
          case 4:
          case 5:
            log.add('post');
            await addReading(
              db,
              random.nextInt(500),
              SpotHrvContext.afterTraining,
              rmssd: 30 + random.nextInt(60).toDouble(),
              uid: 'm${readings++}',
            );
          case 6:
            log.add('delete reading');
            final rows = await db.select(db.spotHrvMeasurements).get();
            if (rows.isNotEmpty) {
              await (db.delete(db.spotHrvMeasurements)..where(
                    (t) => t.id.equals(rows[random.nextInt(rows.length)].id),
                  ))
                  .go();
            }
          case 7:
            log.add('delete activity');
            final rows = await db.select(db.activityRecords).get();
            if (rows.isNotEmpty) {
              await (db.delete(db.activityRecords)..where(
                    (t) => t.id.equals(rows[random.nextInt(rows.length)].id),
                  ))
                  .go();
            }
          case 8:
            final on = random.nextBool();
            log.add('opt ${on ? 'in' : 'out'}');
            await coordinator.setEnabled(on);
          case 9:
            clock = clock.add(Duration(minutes: random.nextInt(80)));
            log.add('clock ${clock.difference(atMin(0)).inMinutes}');
          case 10:
            log.add('restart');
            coordinator = build();
          case 11:
            final rows = await db.select(db.hrvPostReminders).get();
            if (rows.isNotEmpty) {
              final r = rows[random.nextInt(rows.length)];
              final kind = [
                'snooze',
                'skip',
                'measure',
                'open',
              ][random.nextInt(4)];
              log.add('action $kind');
              final stale = random.nextInt(3) == 0;
              await coordinator.handle(
                NotificationResponse(
                  actionId: kind,
                  payload: HrvNotificationPayload(
                    epoch: r.installationEpoch,
                    reminderId: r.reminderId,
                    generation: stale ? max(1, r.generation - 1) : r.generation,
                    episodeId: r.episodeId,
                  ).encode(),
                ),
              );
            }
          case 12:
            log.add('permission');
            gateway.state = NotificationPermission
                .values[random.nextInt(NotificationPermission.values.length)];
          default:
            log.add('reconcile');
        }
        await coordinator.reconcile();
      }

      Future<void> check() async {
        final reminders = await db.select(db.hrvPostReminders).get();
        final prefs = await coordinator.prefs();
        // R19: one chain per episode, one native id per chain.
        expect(
          reminders.map((r) => r.episodeId).toSet(),
          hasLength(reminders.length),
        );
        expect(
          reminders.map((r) => r.nativeNotificationId).toSet(),
          hasLength(reminders.length),
        );
        for (final r in reminders) {
          // Terminal states are never left again (R19, R16).
          final seen = terminalSeen[r.reminderId];
          if (seen != null) {
            expect(r.desiredState, seen, reason: log.join(', '));
          }
          if (ReminderState.parse(r.desiredState).terminal) {
            terminalSeen[r.reminderId] = r.desiredState;
          }
          // At most one snooze (R18).
          expect(r.snoozeCount, lessThanOrEqualTo(1));
          // Due and expiry stay ordered wherever there is a real due time.
          if (ReminderState.parse(r.desiredState).active) {
            expect(
              r.originalDueAtUtc.isBefore(r.expiresAtUtc),
              isTrue,
              reason: log.join(', '),
            );
          }
        }
        // R20/R22: a platform request exists only for a chain that wants it.
        final wanted = {
          for (final r in reminders)
            if (r.desiredState == 'scheduled' || r.desiredState == 'snoozed')
              r.nativeNotificationId,
        };
        for (final id in gateway.pending.keys) {
          expect(
            wanted.contains(id) ||
                reminders.any(
                  (r) =>
                      r.nativeNotificationId == id &&
                      r.osState == 'cancelPending',
                ),
            isTrue,
            reason: 'stray request $id after ${log.join(', ')}',
          );
        }
        // Nothing for a reminder that is off, and nothing beyond the budget.
        if (!prefs.optedIn) {
          expect(
            reminders.where((r) => r.desiredState == 'scheduled'),
            isEmpty,
            reason: log.join(', '),
          );
        }
        expect(gateway.pending.length, lessThanOrEqualTo(8));

        // R04/R02: a reading belongs to one workout; times are in order.
        final links = await (db.select(
          db.hrvEpisodeMeasurements,
        )..where((t) => t.state.equals('active'))).get();
        expect(
          links.map((l) => l.measurementUid).toSet(),
          hasLength(links.length),
        );
        final episodes = {
          for (final e in await db.select(db.hrvTrainingEpisodes).get())
            e.episodeId: e,
        };
        final byUid = {
          for (final m in await db.select(db.spotHrvMeasurements).get())
            m.measurementUid!: m,
        };
        final primaries = <String>{};
        for (final l in links) {
          final e = episodes[l.episodeId]!;
          final m = byUid[l.measurementUid]!;
          if (l.selection == 'primary') {
            expect(primaries.add('${l.episodeId}/${l.role}'), isTrue);
          }
          if (l.role == 'pre') {
            expect(
              !m.samplingEndedAt!.isAfter(e.actualStartUtc),
              isTrue,
              reason: 'pre overlaps its workout: ${log.join(', ')}',
            );
          } else {
            expect(
              e.actualEndUtc != null && !m.startedAt.isBefore(e.actualEndUtc!),
              isTrue,
              reason: 'post before the end: ${log.join(', ')}',
            );
          }
          // R03: contexts are respected.
          expect(
            m.context,
            l.role == 'pre' ? 'beforeTraining' : 'afterTraining',
          );
          expect(m.qualityState, isNot('invalid'));
        }
        // R23: nothing is scheduled for a workout that ended before enabling.
        final since = prefs.enabledSince;
        for (final r in reminders.where((r) => r.desiredState == 'scheduled')) {
          final e = episodes[r.episodeId];
          if (e?.actualEndUtc != null && since != null) {
            expect(
              e!.actualEndUtc!.isBefore(since),
              isFalse,
              reason: log.join(', '),
            );
          }
        }
      }

      await coordinator.setEnabled(true);
      for (var i = 0; i < 28; i++) {
        await step();
        await check();
      }
    });
  }
}
