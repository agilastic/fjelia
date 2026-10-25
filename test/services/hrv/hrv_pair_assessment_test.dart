import 'dart:math' as math;

import 'package:fjelia/models/hrv_pair_assessment.dart';
import 'package:fjelia/models/hrv_training_episode.dart';
import 'package:fjelia/services/hrv/hrv_comparison_service.dart';
import 'package:fjelia/services/hrv/hrv_pair_assessment_service.dart';
import 'package:fjelia/services/hrv/hrv_pairing_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/hrv_fixtures.dart';

void main() {
  const assessor = HrvPairAssessmentService();
  const pairing = HrvPairingService();

  HrvPairAssessment assess(
    EpisodeFact e,
    List<MeasurementFact> ms, {
    bool intervening = false,
  }) {
    final r = pairing.resolve(episodes: [e], measurements: ms);
    return assessor.assess(e, r.of(e.id)!, interveningWorkout: intervening);
  }

  group('arithmetic', () {
    test('HRV-T031 60 to 45 gives -15 ms, -25 % and the ln difference', () {
      final a = assess(workout('A', 0, 120), [
        pre('p', -20, rmssd: 60),
        post('q', 151, rmssd: 45),
      ]);
      expect(a.comparable, isTrue);
      expect(a.deltaMs, -15);
      expect(a.deltaPercent, -25);
      expect(a.deltaLn, closeTo(-0.287682, 1e-6));
      expect(a.deltaLn, closeTo(math.log(45) - math.log(60), 1e-12));
    });

    test('the difference uses unrounded values', () {
      final a = assess(workout('A', 0, 60), [
        pre('p', -20, rmssd: 41.26),
        post('q', 70, rmssd: 38.74),
      ]);
      expect(a.deltaMs, closeTo(-2.52, 1e-9));
    });

    test('HRV-T032 zero, negative and non-finite values give no delta', () {
      for (final bad in [0.0, -3.0, double.nan, double.infinity]) {
        final a = assess(workout('A', 0, 60), [
          pre('p', -20, rmssd: bad),
          post('q', 70),
        ]);
        expect(a.comparable, isFalse, reason: '$bad');
        expect(a.deltaMs, isNull);
        expect(a.reasons, contains(HrvReason.invalidValue));
      }
    });
  });

  group('timing', () {
    test(
      'HRV-T004 the delay is the real sampling start, not the +30 target',
      () {
        // Opened at +30, one minute of settling: sampling starts at +31.
        final a = assess(workout('A', 0, 120), [
          pre('p', -20),
          post('q', 120 + 31),
        ]);
        expect(a.postDelay, const Duration(minutes: 31));
        expect(a.inTargetBand, isTrue);
      },
    );

    test(
      'HRV-T033 a +46 minute post is outside the band and its own cohort',
      () {
        final a = assess(workout('A', 0, 120), [
          pre('p', -20),
          post('q', 120 + 46),
        ]);
        expect(a.postDelay, const Duration(minutes: 46));
        expect(a.inTargetBand, isFalse);
        expect(a.reasons, contains(HrvReason.postOutsideTargetBand));
        expect(a.comparable, isTrue);
        expect(a.timingCohortMinutes, isNot(30));
      },
    );

    test('HRV-T037 10, 30 and 60 minute posts land in different cohorts', () {
      int cohort(int delay) => assess(workout('A', 0, 120), [
        pre('p', -20),
        post('q', 120 + delay),
      ]).timingCohortMinutes!;
      expect({cohort(10), cohort(30), cohort(60)}, hasLength(3));
    });

    test('HRV-T006 an unknown end gives no delay and no delta', () {
      final a = assess(workout('A', 0, null), [pre('p', -20)]);
      expect(a.postDelay, isNull);
      expect(a.reasons, contains(HrvReason.unknownActualEnd));
      expect(a.reasons, contains(HrvReason.missingPost));
    });

    test('an uncertain clock blocks the comparison', () {
      final a = assess(workout('A', 0, 60, clockUncertain: true), [
        pre('p', -20),
        post('q', 70),
      ]);
      expect(a.comparable, isFalse);
      expect(a.reasons, contains(HrvReason.clockUncertain));
    });
  });

  group('comparability', () {
    test(
      'HRV-T016 seated pre and supine post stay associated, not compared',
      () {
        final a = assess(workout('A', 0, 60), [
          pre('p', -20),
          reading('q', 70, 'afterTraining', posture: 'supine'),
        ]);
        expect(a.hasPair, isTrue);
        expect(a.comparable, isFalse);
        expect(a.deltaMs, isNull);
        expect(a.reasons, contains(HrvReason.postureMismatch));
      },
    );

    test('a different duration is a protocol mismatch', () {
      final a = assess(workout('A', 0, 60), [
        pre('p', -20),
        post('q', 70, seconds: 180),
      ]);
      expect(a.comparable, isFalse);
      expect(a.reasons, contains(HrvReason.durationMismatch));
    });

    test('HRV-T017 another metric is not compared', () {
      final a = assess(workout('A', 0, 60), [
        pre('p', -20),
        reading('q', 70, 'afterTraining', metric: 'sdnn'),
      ]);
      expect(a.comparable, isFalse);
      expect(a.reasons, contains(HrvReason.metricMismatch));
    });

    test('HRV-T029 unknown legacy quality stays flagged, never "passed"', () {
      final a = assess(workout('A', 0, 60), [
        reading('p', -20, 'beforeTraining', legacy: true),
        post('q', 70),
      ]);
      expect(a.reasons, contains(HrvReason.legacyQualityUnknown));
    });

    test('an intervening workout blocks the comparison', () {
      final a = assess(workout('A', 0, 60), [
        pre('p', -20),
        post('q', 70),
      ], intervening: true);
      expect(a.comparable, isFalse);
      expect(a.reasons, contains(HrvReason.interveningWorkout));
    });

    test('pre only: missing post, no delta', () {
      final a = assess(workout('A', 0, 60), [pre('p', -20)]);
      expect(a.hasPre, isTrue);
      expect(a.reasons, contains(HrvReason.missingPost));
      expect(a.deltaMs, isNull);
    });

    test('post only: missing pre, no delta', () {
      final a = assess(workout('A', 0, 60), [post('q', 70)]);
      expect(a.reasons, contains(HrvReason.missingPre));
      expect(a.deltaMs, isNull);
    });
  });

  group('fingerprint', () {
    test('changes when a fact changes, stays when nothing does', () {
      final e = workout('A', 0, 60);
      final one = assess(e, [pre('p', -20), post('q', 70)]).fingerprint;
      final same = assess(e, [pre('p', -20), post('q', 70)]).fingerprint;
      final other = assess(e, [
        pre('p', -20),
        post('q', 70, rmssd: 44),
      ]).fingerprint;
      final moved = assess(workout('A', 0, 61), [
        pre('p', -20),
        post('q', 70),
      ]).fingerprint;
      expect(same, one);
      expect(other, isNot(one));
      expect(moved, isNot(one));
    });
  });

  group('history', () {
    const cohortService = HrvComparisonService();

    AssessedEpisode day(
      int d, {
      double pre = 60,
      double post = 45,
      String sport = 'cycling',
      String posture = 'seated',
      int seconds = 300,
      int delay = 31,
      String device = 'h10',
      int length = 120,
    }) {
      final base = d * 24 * 60;
      final e = workout('E$d', base, base + length, sport: sport);
      final ms = [
        reading(
          'p$d',
          base - 20,
          'beforeTraining',
          rmssd: pre,
          posture: posture,
          seconds: seconds,
          device: device,
        ),
        reading(
          'q$d',
          base + length + delay,
          'afterTraining',
          rmssd: post,
          posture: posture,
          seconds: seconds,
          device: device,
        ),
      ];
      final r = pairing.resolve(episodes: [e], measurements: ms);
      return AssessedEpisode(e, assessor.assess(e, r.of(e.id)!));
    }

    List<AssessedEpisode> series(int n, {int step = 2}) => [
      for (var i = 0; i < n; i++) day(1 + i * step, post: 45.0 + i),
    ];

    test('HRV-T035 below the minimum shows the count, not a range', () {
      final history = series(7);
      final cohort = cohortService.cohortFor(day(60), history);
      expect(cohort.eligible, 7);
      expect(cohort.sufficient, isFalse);
      expect(cohort.medianMs, isNull);
    });

    test('at the minimum with enough span the median and IQR appear', () {
      final history = series(8);
      final cohort = cohortService.cohortFor(day(60), history);
      expect(cohort.eligible, 8);
      expect(cohort.sufficient, isTrue);
      // post 45..52 against pre 60: deltas -15..-8, median -11.5.
      expect(cohort.medianMs, closeTo(-11.5, 1e-9));
      expect(cohort.q1Ms, closeTo(-13.25, 1e-9));
      expect(cohort.q3Ms, closeTo(-9.75, 1e-9));
      expect(cohort.span, const Duration(days: 14));
    });

    test('eight workouts squeezed into under 14 days are not enough', () {
      final history = [for (var i = 0; i < 8; i++) day(1 + i)];
      final cohort = cohortService.cohortFor(day(60), history);
      expect(cohort.eligible, 8);
      expect(cohort.sufficient, isFalse);
    });

    test('HRV-T036 other posture, protocol, sensor and sport are excluded', () {
      final history = [
        ...series(8),
        day(20, posture: 'supine'),
        day(22, seconds: 180),
        day(24, device: 'other'),
        day(26, sport: 'running'),
      ];
      final cohort = cohortService.cohortFor(day(60), history);
      expect(cohort.eligible, 8);
      expect(cohort.excluded[CohortExclusion.posture], 1);
      expect(cohort.excluded[CohortExclusion.protocol], 1);
      expect(cohort.excluded[CohortExclusion.sensor], 1);
      expect(cohort.excluded[CohortExclusion.sport], 1);
    });

    test('a different workout length is excluded', () {
      final cohort = cohortService.cohortFor(day(60), [day(10, length: 30)]);
      expect(cohort.excluded[CohortExclusion.workoutLength], 1);
    });

    test('HRV-T037 another timing cohort is not mixed in', () {
      final cohort = cohortService.cohortFor(day(60), [day(10, delay: 61)]);
      expect(cohort.excluded[CohortExclusion.timing], 1);
      expect(cohort.eligible, 0);
    });

    test('only earlier workouts count, never a later one', () {
      final cohort = cohortService.cohortFor(day(20), [day(30), day(10)]);
      expect(cohort.excluded[CohortExclusion.notEarlier], 1);
      expect(cohort.eligible, 1);
    });

    test('workouts older than the horizon are left out', () {
      final cohort = cohortService.cohortFor(day(200), [day(10)]);
      expect(cohort.excluded[CohortExclusion.tooOld], 1);
    });

    test('HRV-T038 a workout contributes once however many posts it has', () {
      final e = workout('R', 0, 120);
      final r = pairing.resolve(
        episodes: [e],
        measurements: [
          pre('rp', -20),
          for (var i = 0; i < 5; i++) post('rq$i', 151 + i * 6),
        ],
      );
      final one = AssessedEpisode(e, assessor.assess(e, r.of('R')!));
      final cohort = cohortService.cohortFor(day(60), [one]);
      expect(cohort.eligible, 1);
    });

    test('HRV-T034 the quantile is of paired changes, not of two means', () {
      expect(HrvComparisonService.quantile([1, 2, 3, 4], .5), 2.5);
      expect(HrvComparisonService.quantile([5], .25), 5);
    });
  });
}
