import 'package:fjelia/models/hrv_training_episode.dart';
import 'package:fjelia/services/hrv/hrv_post_reminder_policy.dart';
import 'package:fjelia/services/hrv/hrv_timing_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/hrv_fixtures.dart';

void main() {
  const policy = HrvPostReminderPolicy();
  final end = at(120);
  final due = end.add(const Duration(minutes: 30));
  final interval = ActualInterval(
    start: at(0),
    end: end,
    basis: IntervalBasis.providerElapsed,
  );

  ReminderInputs inputs(
    DateTime now, {
    bool optedIn = true,
    bool sensor = true,
    bool permission = true,
    bool pre = true,
    bool post = false,
    ActualInterval? iv,
    DateTime? since,
    ReminderRecord? previous,
    bool ambiguous = false,
    bool intervening = false,
    bool historical = false,
    bool capacity = true,
    QuietHours? quiet,
    bool postpone = false,
    bool skip = false,
    bool deleted = false,
  }) => ReminderInputs(
    now: now,
    optedIn: optedIn,
    sensorReady: sensor,
    permissionGranted: permission,
    enabledSince: since ?? at(-600),
    interval: iv ?? interval,
    hasUsablePre: pre,
    hasUsablePost: post,
    ambiguous: ambiguous,
    intervening: intervening,
    historicalImport: historical,
    capacityFree: capacity,
    quietHours: quiet,
    postponeInQuietHours: postpone,
    previous: previous,
    skipRequested: skip,
    deleted: deleted,
  );

  ReminderRecord record(
    ReminderState state, {
    int snoozes = 0,
    DateTime? next,
    ReminderReason reason = ReminderReason.none,
  }) => ReminderRecord(
    state: state,
    originalDue: due,
    nextDue: next ?? due,
    expires: end.add(const Duration(minutes: 90)),
    snoozeCount: snoozes,
    reason: reason,
  );

  group('eligibility', () {
    test('HRV-T051 one due time from the actual end plus 30 minutes', () {
      final d = policy.decide(inputs(end.add(const Duration(minutes: 1))));
      expect(d.state, ReminderState.scheduled);
      expect(d.action, ReminderAction.schedule);
      expect(d.nextDue, due);
      expect(d.originalDue, due);
      expect(d.expires, end.add(const Duration(minutes: 90)));
    });

    test(
      'HRV-T052 each missing prerequisite blocks the automatic reminder',
      () {
        final now = end.add(const Duration(minutes: 1));
        expect(
          policy.decide(inputs(now, optedIn: false)).action,
          ReminderAction.none,
        );
        expect(
          policy.decide(inputs(now, optedIn: false)).state,
          isNot(ReminderState.scheduled),
        );
        expect(
          policy.decide(inputs(now, sensor: false)).state,
          isNot(ReminderState.scheduled),
        );
        final noPre = policy.decide(inputs(now, pre: false));
        expect(noPre.state, ReminderState.suppressed);
        expect(noPre.reason, ReminderReason.noPre);
      },
    );

    test('HRV-T053 a disconnected strap does not matter, only the pairing', () {
      // The policy only knows "remembered and enabled"; no connection input.
      final d = policy.decide(inputs(end.add(const Duration(minutes: 1))));
      expect(d.state, ReminderState.scheduled);
    });

    test('no actual end waits for the workout and plans nothing', () {
      final d = policy.decide(
        inputs(at(130), iv: ActualInterval(start: at(0))),
      );
      expect(d.state, ReminderState.waitingForWorkout);
      expect(d.reason, ReminderReason.endUnknown);
      expect(d.action, ReminderAction.none);
    });

    test('a workout ended before the feature was enabled never notifies', () {
      final d = policy.decide(inputs(end, since: at(125)));
      expect(d.state, ReminderState.suppressed);
      expect(d.reason, ReminderReason.enabledAfterEnd);
    });

    test('a blocked permission suppresses and can recover', () {
      final blocked = policy.decide(inputs(end, permission: false));
      expect(blocked.reason, ReminderReason.permissionBlocked);
      expect(blocked.state, ReminderState.suppressed);
      final granted = policy.decide(
        inputs(
          end.add(const Duration(minutes: 5)),
          previous: record(ReminderState.suppressed),
        ),
      );
      expect(granted.state, ReminderState.scheduled);
    });

    test(
      'ambiguity, an intervening workout and an uncertain clock suppress',
      () {
        expect(
          policy.decide(inputs(end, ambiguous: true)).reason,
          ReminderReason.ambiguous,
        );
        expect(
          policy.decide(inputs(end, intervening: true)).reason,
          ReminderReason.interveningWorkout,
        );
        expect(
          policy
              .decide(
                inputs(
                  end,
                  iv: ActualInterval(
                    start: at(0),
                    end: end,
                    basis: IntervalBasis.providerElapsed,
                    clockUncertain: true,
                  ),
                ),
              )
              .reason,
          ReminderReason.clockUncertain,
        );
      },
    );

    test('capacity full holds the reminder back', () {
      expect(
        policy.decide(inputs(end, capacity: false)).reason,
        ReminderReason.capacity,
      );
    });
  });

  group('discovery timing', () {
    test('HRV-T054 before due, at due and at the catch-up edge', () {
      final before = policy.decide(
        inputs(due.subtract(const Duration(seconds: 1))),
      );
      expect(before.nextDue, due);
      final exact = policy.decide(inputs(due));
      expect(exact.state, ReminderState.scheduled);
      final edge = policy.decide(inputs(due.add(const Duration(minutes: 15))));
      expect(edge.state, ReminderState.scheduled);
      // A catch-up is shown now, not at the missed time.
      expect(edge.nextDue, due.add(const Duration(minutes: 15)));
      expect(edge.originalDue, due);
    });

    test(
      'HRV-T055 one second past the catch-up window is a late discovery',
      () {
        final d = policy.decide(
          inputs(due.add(const Duration(minutes: 15, seconds: 1))),
        );
        expect(d.state, ReminderState.suppressed);
        expect(d.reason, ReminderReason.lateDiscovery);
        expect(d.action, ReminderAction.none);
      },
    );

    test('a historical import never notifies', () {
      final d = policy.decide(inputs(end, historical: true));
      expect(d.reason, ReminderReason.historicalImport);
    });

    test('HRV-T097 at the exact expiry nothing is scheduled', () {
      final expiry = end.add(const Duration(minutes: 90));
      final d = policy.decide(inputs(expiry));
      expect(d.state, ReminderState.expired);
      expect(d.action, ReminderAction.none);
      final before = policy.decide(
        inputs(expiry.subtract(const Duration(seconds: 1))),
      );
      expect(before.state, ReminderState.suppressed); // past catch-up
    });

    test('an expired active chain cancels its request', () {
      final d = policy.decide(
        inputs(
          end.add(const Duration(minutes: 91)),
          previous: record(ReminderState.scheduled),
        ),
      );
      expect(d.state, ReminderState.expired);
      expect(d.action, ReminderAction.cancel);
    });
  });

  group('known chain', () {
    test('repeated sync with an unchanged chain changes nothing', () {
      final prev = record(ReminderState.scheduled);
      for (var i = 0; i < 100; i++) {
        final d = policy.decide(
          inputs(due.subtract(const Duration(minutes: 5)), previous: prev),
        );
        expect(d.state, ReminderState.scheduled);
        expect(d.action, ReminderAction.none);
        expect(d.nextDue, due);
      }
    });

    test('a due chain waits for the athlete and is not shown again', () {
      final d = policy.decide(
        inputs(
          due.add(const Duration(minutes: 5)),
          previous: record(ReminderState.scheduled),
        ),
      );
      expect(d.state, ReminderState.awaitingAction);
      expect(d.action, ReminderAction.none);
    });

    test('HRV-T056 a usable post completes and cancels the request', () {
      final d = policy.decide(
        inputs(due, post: true, previous: record(ReminderState.scheduled)),
      );
      expect(d.state, ReminderState.completed);
      expect(d.action, ReminderAction.cancel);
    });

    test('a post with another protocol still completes the reminder', () {
      // The policy only sees "usable post exists"; protocol is no gate.
      expect(
        policy.decide(inputs(due, post: true)).state,
        ReminderState.completed,
      );
    });

    test('HRV-T057 no usable post means the chain stays open', () {
      final d = policy.decide(
        inputs(due, post: false, previous: record(ReminderState.scheduled)),
      );
      expect(d.state, isNot(ReminderState.completed));
    });

    test('HRV-T060 completed stays completed after the post is deleted', () {
      final d = policy.decide(
        inputs(due, post: false, previous: record(ReminderState.completed)),
      );
      expect(d.state, ReminderState.completed);
      expect(d.action, ReminderAction.none);
    });

    test('HRV-T059 skipped is final across sync and restart', () {
      final skipped = policy.decide(
        inputs(due, skip: true, previous: record(ReminderState.awaitingAction)),
      );
      expect(skipped.state, ReminderState.skipped);
      expect(skipped.action, ReminderAction.cancel);
      for (var i = 0; i < 5; i++) {
        final again = policy.decide(
          inputs(due, previous: record(ReminderState.skipped)),
        );
        expect(again.state, ReminderState.skipped);
        expect(again.action, ReminderAction.none);
      }
    });

    test('a deleted workout cancels the chain', () {
      final d = policy.decide(
        inputs(due, deleted: true, previous: record(ReminderState.scheduled)),
      );
      expect(d.state, ReminderState.cancelled);
      expect(d.action, ReminderAction.cancel);
    });

    test('switching the feature off cancels a running chain only', () {
      final running = policy.decide(
        inputs(due, optedIn: false, previous: record(ReminderState.scheduled)),
      );
      expect(running.state, ReminderState.cancelled);
      expect(running.action, ReminderAction.cancel);
      final none = policy.decide(inputs(due, optedIn: false));
      expect(none.state, ReminderState.suppressed);
    });
  });

  group('snooze', () {
    final prev = record(ReminderState.awaitingAction);

    test('HRV-T058 the first snooze is now plus ten minutes, due kept', () {
      final now = due.add(const Duration(minutes: 2));
      final d = policy.snooze(prev, now)!;
      expect(d.nextDue, now.add(const Duration(minutes: 10)));
      expect(d.originalDue, due);
      expect(d.snoozeCount, 1);
      expect(d.state, ReminderState.snoozed);
      expect(d.action, ReminderAction.schedule);
    });

    test('a second snooze is refused', () {
      final once = record(ReminderState.snoozed, snoozes: 1);
      expect(policy.snooze(once, due.add(const Duration(minutes: 20))), isNull);
    });

    test('a snooze crossing the expiry is refused', () {
      final late = end.add(const Duration(minutes: 85));
      expect(policy.snooze(prev, late), isNull);
      expect(
        policy.snooze(prev, end.add(const Duration(minutes: 79))),
        isNotNull,
      );
    });

    test('a terminal chain cannot be snoozed', () {
      expect(policy.snooze(record(ReminderState.completed), due), isNull);
    });
  });

  group('quiet hours', () {
    // 22:00–07:00 local, a fixed +1 h offset.
    QuietHours quiet() =>
        QuietHours(22 * 60, 7 * 60, offsetAt: (_) => const Duration(hours: 1));

    test('HRV-T087 a due time inside quiet hours is suppressed by default', () {
      final lateEnd = DateTime.utc(2026, 11, 2, 21, 0); // 22:00 local
      final iv = ActualInterval(
        start: lateEnd.subtract(const Duration(hours: 1)),
        end: lateEnd,
        basis: IntervalBasis.providerElapsed,
      );
      final d = policy.decide(
        inputs(
          lateEnd,
          iv: iv,
          quiet: quiet(),
          since: lateEnd.subtract(const Duration(days: 1)),
        ),
      );
      expect(d.reason, ReminderReason.quietHours);
    });

    test(
      'postponing beyond the expiry is not done, the morning is too late',
      () {
        final lateEnd = DateTime.utc(2026, 11, 2, 21, 0);
        final iv = ActualInterval(
          start: lateEnd.subtract(const Duration(hours: 1)),
          end: lateEnd,
          basis: IntervalBasis.providerElapsed,
        );
        final d = policy.decide(
          inputs(
            lateEnd,
            iv: iv,
            quiet: quiet(),
            postpone: true,
            since: lateEnd.subtract(const Duration(days: 1)),
          ),
        );
        expect(d.state, ReminderState.suppressed);
      },
    );

    test('nextAllowed returns the end of the window, DST-aware via offset', () {
      final q = quiet();
      expect(
        q.nextAllowed(DateTime.utc(2026, 11, 2, 12, 0)),
        DateTime.utc(2026, 11, 2, 12, 0),
      );
      expect(
        q.nextAllowed(DateTime.utc(2026, 11, 2, 22, 30)), // 23:30 local
        DateTime.utc(2026, 11, 3, 6, 0), // 07:00 local
      );
      // The same local time with an offset one hour smaller.
      final summer = QuietHours(
        22 * 60,
        7 * 60,
        offsetAt: (_) => const Duration(hours: 2),
      );
      expect(
        summer.nextAllowed(DateTime.utc(2026, 7, 1, 21, 0)), // 23:00 local
        DateTime.utc(2026, 7, 2, 5, 0), // 07:00 local
      );
    });
  });

  test('the default policy has ordered due, catch-up and expiry', () {
    expect(const HrvTimingPolicy().consistent, isTrue);
    expect(
      const HrvTimingPolicy(expiry: Duration(minutes: 40)).consistent,
      isFalse,
    );
  });
}
