import 'package:fjelia/models/hrv_training_episode.dart';
import 'package:fjelia/services/hrv/activity_interval_resolver.dart';
import 'package:fjelia/services/hrv/hrv_pairing_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/hrv_fixtures.dart';

void main() {
  const service = HrvPairingService();

  HrvPairingResult run(
    List<EpisodeFact> episodes,
    List<MeasurementFact> measurements, {
    List<HrvPin> pins = const [],
  }) => service.resolve(
    episodes: episodes,
    measurements: measurements,
    pins: pins,
  );

  group('ordinary sequence', () {
    test('HRV-T001 pre, workout, post pair without a dialog', () {
      final r = run([workout('A', 0, 120)], [pre('p', -20), post('q', 150)]);
      final a = r.of('A')!;
      expect(a.pre!.uid, 'p');
      expect(a.post!.uid, 'q');
      expect(a.association, Association.unambiguous);
      expect(r.links, hasLength(2));
    });

    test('HRV-T002 a pre ending exactly at the start is valid', () {
      final r = run([workout('A', 0, 60)], [pre('p', -5)]);
      expect(r.of('A')!.pre!.uid, 'p');
    });

    test('HRV-T003 a post starting one minute before the end is refused', () {
      final r = run([workout('A', 0, 60)], [post('q', 59)]);
      expect(r.of('A')!.post, isNull);
    });

    test('a post starting exactly at the end is valid', () {
      final r = run([workout('A', 0, 60)], [post('q', 60)]);
      expect(r.of('A')!.post!.uid, 'q');
    });

    test('a pre overlapping the exercise is not eligible', () {
      final r = run([workout('A', 0, 60)], [pre('p', -2)]);
      expect(r.of('A')!.pre, isNull);
    });

    test('HRV-T018 a pre outside the 3 hour window is not broadened', () {
      final r = run([workout('A', 0, 60)], [pre('p', -190)]);
      expect(r.of('A')!.pre, isNull);
    });

    test('a post outside the 120 minute window is not automatic', () {
      final r = run([workout('A', 0, 60)], [post('q', 60 + 121)]);
      expect(r.of('A')!.post, isNull);
    });
  });

  group('selection never follows the value', () {
    test('HRV-T013 the latest eligible pre wins whatever its RMSSD', () {
      final r = run(
        [workout('A', 0, 60)],
        [pre('early', -60, rmssd: 99), pre('late', -20, rmssd: 10)],
      );
      expect(r.of('A')!.pre!.uid, 'late');
    });

    test('HRV-T014 the earliest eligible post stays primary', () {
      final r = run(
        [workout('A', 0, 60)],
        [post('first', 70, rmssd: 20), post('second', 100, rmssd: 90)],
      );
      expect(r.of('A')!.post!.uid, 'first');
      expect(r.of('A')!.additionalPosts.single.uid, 'second');
      final selections = {
        for (final l in r.links) l.measurementUid: l.selection,
      };
      expect(selections['second'], LinkSelection.additional);
    });

    test('ties break by the measurement id, not by the value', () {
      final r = run(
        [workout('A', 0, 60)],
        [pre('b', -20, rmssd: 90), pre('a', -20, rmssd: 10)],
      );
      expect(r.of('A')!.pre!.uid, 'a');
    });
  });

  group('contexts and quality', () {
    test('HRV-T012 a resting reading is never a post', () {
      final r = run([workout('A', 0, 60)], [reading('r', 90, 'resting')]);
      expect(r.of('A')!.post, isNull);
      expect(r.links, isEmpty);
    });

    test('HRV-T015 an unusable measurement is never linked', () {
      final r = run(
        [workout('A', 0, 60)],
        [
          reading('p', -20, 'beforeTraining', usable: false),
          reading('q', 70, 'afterTraining', usable: false),
        ],
      );
      expect(r.of('A')!.association, Association.none);
    });

    test('HRV-T011 a pre without any workout stays unlinked', () {
      final r = run([], [pre('p', -20)]);
      expect(r.links, isEmpty);
    });
  });

  group('several workouts', () {
    test('HRV-T025 a post after a second workout is not the response to A', () {
      final r = run(
        [workout('A', 0, 60), workout('B', 90, 150)],
        [pre('pa', -20), pre('pb', 70), post('q', 160)],
      );
      expect(r.of('A')!.post, isNull);
      expect(r.of('B')!.post!.uid, 'q');
      expect(r.of('B')!.pre!.uid, 'pb');
      expect(r.of('A')!.pre!.uid, 'pa');
    });

    test('a second pre must not skip over the workout in between', () {
      final r = run(
        [workout('A', 0, 60), workout('B', 90, 150)],
        [pre('pa', -20)],
      );
      expect(r.of('B')!.pre, isNull);
    });

    test('HRV-T026 a later workout leaves A\'s valid pair alone', () {
      final r = run(
        [workout('A', 0, 60), workout('B', 200, 260)],
        [pre('p', -20), post('q', 70)],
      );
      expect(r.of('A')!.association, Association.unambiguous);
      expect(r.of('B')!.association, Association.none);
    });

    test('HRV-T027 a reading is used once, in its declared role', () {
      final r = run(
        [workout('A', 0, 60), workout('B', 120, 180)],
        [post('x', 70)],
      );
      expect(r.of('A')!.post!.uid, 'x');
      expect(r.of('B')!.pre, isNull);
      expect(r.links.where((l) => l.measurementUid == 'x'), hasLength(1));
    });

    test('HRV-T010 overlapping distinct workouts are ambiguous', () {
      final r = run(
        [workout('A', 0, 60), workout('B', 30, 90)],
        [pre('p', -20), post('q', 100)],
      );
      expect(r.of('A')!.association, Association.ambiguous);
      expect(r.of('B')!.association, Association.ambiguous);
      expect(r.links, isEmpty);
    });

    test('a child of a reliable parent is not an episode of its own', () {
      final r = run(
        [
          workout('parent', 0, 120),
          workout('swim', 0, 30, parentId: 'parent'),
          workout('bike', 30, 120, parentId: 'parent'),
        ],
        [pre('p', -20), post('q', 130)],
      );
      expect(r.of('parent')!.association, Association.unambiguous);
      expect(r.pairings.keys, ['parent']);
    });

    test('HRV-T030 an episode with an unknown end gets no post', () {
      final r = run([workout('A', 0, null)], [pre('p', -20), post('q', 70)]);
      expect(r.of('A')!.pre!.uid, 'p');
      expect(r.of('A')!.post, isNull);
    });
  });

  group('corrections', () {
    test('HRV-T020 a pin overrides the automatic choice', () {
      final r = run(
        [workout('A', 0, 60)],
        [post('first', 70), post('second', 100)],
        pins: [const HrvPin('second', 'A', HrvRole.post)],
      );
      expect(r.of('A')!.post!.uid, 'second');
      expect(r.of('A')!.association, Association.corrected);
      expect(
        r.links.firstWhere((l) => l.measurementUid == 'second').method,
        AssociationMethod.userCorrection,
      );
    });

    test('a pin that contradicts the timing is reported, not applied', () {
      final r = run(
        [workout('A', 0, 60)],
        [post('q', 30)],
        pins: [const HrvPin('q', 'A', HrvRole.post)],
      );
      expect(r.of('A')!.post, isNull);
      expect(r.of('A')!.contradictions, ['q']);
    });

    test('a pinned reading is not taken by another workout', () {
      final r = run(
        [workout('A', 0, 60), workout('B', 200, 260)],
        [pre('x', 150)],
        pins: [const HrvPin('x', 'A', HrvRole.pre)],
      );
      // x ends after A starts, so the pin is a contradiction and B takes it.
      expect(r.of('A')!.pre, isNull);
    });
  });

  group('order independence', () {
    test('HRV-T076 any arrival order resolves the same links', () {
      final episodes = [workout('A', 0, 60), workout('B', 120, 180)];
      final measurements = [
        pre('pa', -20),
        post('qa', 70),
        pre('pb', 100),
        post('qb', 190),
        post('qb2', 230, rmssd: 10),
      ];
      final expected = run(episodes, measurements).links.toSet();
      for (var shift = 1; shift < measurements.length; shift++) {
        final rotated = [
          ...measurements.sublist(shift),
          ...measurements.sublist(0, shift),
        ];
        expect(
          run(episodes.reversed.toList(), rotated).links.toSet(),
          expected,
        );
      }
    });
  });

  group('actual interval', () {
    const resolver = ActivityIntervalResolver();
    final start = DateTime.utc(2026, 11, 2, 8);

    test('HRV-T005 elapsed time, not moving time, ends the workout', () {
      final i = resolver.resolve(
        start: start,
        durationSeconds: 120 * 60,
        movingDurationSeconds: 90 * 60,
        source: 'garmin_api',
      );
      expect(i.end, start.add(const Duration(minutes: 120)));
      expect(i.basis, IntervalBasis.providerElapsed);
    });

    test('HRV-T006 an unknown source has no trusted end', () {
      final i = resolver.resolve(
        start: start,
        durationSeconds: 3600,
        source: 'manual',
      );
      expect(i.endKnown, isFalse);
    });

    test('a duration shorter than the moving time is not elapsed time', () {
      final i = resolver.resolve(
        start: start,
        durationSeconds: 3000,
        movingDurationSeconds: 3600,
        source: 'garmin_api',
      );
      expect(i.endKnown, isFalse);
    });

    test('a finish reported by the athlete is kept as such', () {
      final i = resolver.resolve(
        start: start,
        durationSeconds: 0,
        source: 'manual',
        userReportedEnd: start.add(const Duration(hours: 1)),
      );
      expect(i.basis, IntervalBasis.userReported);
    });

    test('a finish in the future is a clock uncertainty', () {
      final i = resolver.resolve(
        start: start,
        durationSeconds: 7200,
        source: 'garmin_api',
        now: start.add(const Duration(hours: 1)),
      );
      expect(i.clockUncertain, isTrue);
      expect(i.endKnown, isFalse);
    });

    test('HRV-T007 a workout over midnight keeps its instants', () {
      final late = DateTime.utc(2026, 11, 2, 23, 30);
      final i = resolver.resolve(
        start: late,
        durationSeconds: 3600,
        source: 'garmin_api',
      );
      expect(i.end, DateTime.utc(2026, 11, 3, 0, 30));
    });
  });
}
