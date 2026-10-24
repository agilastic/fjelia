import 'dart:convert';

import 'package:fjelia/services/workout_semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> timed(String type, int seconds, int zone) => {
  'type': 'ExecutableStepDTO',
  'stepType': {'stepTypeKey': type},
  'endCondition': {'conditionTypeKey': 'time'},
  'endConditionValue': seconds,
  'zoneNumber': zone,
};

Map<String, dynamic> distance(String type, int metres, int zone) => {
  'type': 'ExecutableStepDTO',
  'stepType': {'stepTypeKey': type},
  'endCondition': {'conditionTypeKey': 'distance'},
  'endConditionValue': metres,
  'zoneNumber': zone,
};

Map<String, dynamic> repeat(int n, List<Map<String, dynamic>> steps) => {
  'type': 'RepeatGroupDTO',
  'stepType': {'stepTypeKey': 'repeat'},
  'numberOfIterations': n,
  'workoutSteps': steps,
};

String json(List<Map<String, dynamic>> steps) => jsonEncode(steps);

void main() {
  group('WorkoutSemantics', () {
    test('time steps add up exactly, repeats multiply', () {
      final s = WorkoutSemantics.of(
        json([
          timed('warmup', 600, 1),
          repeat(5, [timed('interval', 240, 4), timed('recovery', 120, 1)]),
          timed('cooldown', 300, 1),
        ]),
      );
      expect(s.exactSeconds, 600 + 5 * 360 + 300);
      expect(s.isExact, isTrue);
      expect(s.totalMinutes, 45);
    });

    test('nested repeats multiply each other', () {
      final s = WorkoutSemantics.of(
        json([
          repeat(3, [
            repeat(4, [timed('interval', 60, 4), timed('recovery', 30, 1)]),
            timed('recovery', 120, 1),
          ]),
        ]),
      );
      // 3 × (4 × 90 + 120) = 1440 s
      expect(s.exactSeconds, 1440);
      expect(s.zoneSeconds[4], 3 * 4 * 60);
    });

    test('a distance is not read as seconds and stays an estimate', () {
      final s = WorkoutSemantics.of(
        json([
          repeat(4, [distance('interval', 500, 2)]),
        ]),
        sport: 'swimming',
      );
      expect(s.exactSeconds, 0);
      expect(s.estimatedSeconds, closeTo(4 * 500 * 1.4, 1e-9));
      expect(s.isExact, isFalse);
      // 500 m is not 500 s.
      expect(s.totalSeconds, isNot(4 * 500));
    });

    test('a step without an end counts as an open estimate', () {
      final s = WorkoutSemantics.of(
        json([
          {
            'type': 'ExecutableStepDTO',
            'stepType': {'stepTypeKey': 'interval'},
            'endCondition': {'conditionTypeKey': 'lap.button'},
            'zoneNumber': 2,
          },
        ]),
      );
      expect(s.openSteps, 1);
      expect(s.isExact, isFalse);
    });

    test('the main zone leaves out warm-up and cool-down', () {
      final s = WorkoutSemantics.of(
        json([
          timed('warmup', 900, 1),
          timed('interval', 600, 4),
          timed('cooldown', 900, 1),
        ]),
      );
      expect(s.dominantZone, 4);
      expect(s.zoneSeconds[1], 1800);
    });

    test('load uses the zone weights over nested repeats', () {
      final s = WorkoutSemantics.of(
        json([
          repeat(2, [timed('interval', 600, 4)]),
        ]),
      );
      expect(s.legacyLoad, closeTo(20 * 3.1, 1e-9));
    });

    test('garbage and empty input give an empty result', () {
      expect(WorkoutSemantics.of(null).isEmpty, isTrue);
      expect(WorkoutSemantics.of('').isEmpty, isTrue);
      expect(WorkoutSemantics.of('not json').isEmpty, isTrue);
      expect(WorkoutSemantics.of('{"a":1}').isEmpty, isTrue);
    });
  });

  group('fitSteadyWorkout', () {
    final longRun = json([
      timed('warmup', 600, 1),
      timed('interval', 4200, 2),
      timed('cooldown', 600, 1),
    ]);

    test('the easy main step is stretched to the target', () {
      final fitted = fitSteadyWorkout(longRun, 100 * 60);
      expect(fitted.scaled, isTrue);
      final s = WorkoutSemantics.of(fitted.stepsJson);
      expect(s.totalMinutes, 100);
      // Warm-up and cool-down stay.
      expect(s.zoneSeconds[1], 1200);
    });

    test('the change is bounded to half and one and a half times', () {
      final far = fitSteadyWorkout(longRun, 30 * 60);
      expect(WorkoutSemantics.of(far.stepsJson).totalSeconds, 600 + 2100 + 600);
      final huge = fitSteadyWorkout(longRun, 300 * 60);
      expect(
        WorkoutSemantics.of(huge.stepsJson).totalSeconds,
        600 + 6300 + 600,
      );
    });

    test('intervals and repeat groups are never scaled', () {
      final intervals = json([
        timed('warmup', 600, 1),
        repeat(5, [timed('interval', 240, 4), timed('recovery', 120, 1)]),
        timed('cooldown', 300, 1),
      ]);
      final fitted = fitSteadyWorkout(intervals, 80 * 60);
      expect(fitted.scaled, isFalse);
      expect(fitted.stepsJson, intervals);
    });

    test('a hard main step is protected, a progression keeps its hard end', () {
      final progression = json([
        timed('warmup', 600, 1),
        timed('interval', 3600, 2),
        timed('interval', 1200, 3),
        timed('cooldown', 600, 1),
      ]);
      final fitted = fitSteadyWorkout(progression, 120 * 60);
      expect(fitted.scaled, isTrue);
      final s = WorkoutSemantics.of(fitted.stepsJson);
      expect(s.zoneSeconds[3], 1200);
    });

    test('workouts by distance or without an exact length stay unchanged', () {
      final swim = json([distance('interval', 1000, 2)]);
      expect(fitSteadyWorkout(swim, 3600).scaled, isFalse);
    });
  });

  group('retimeTitle', () {
    test('totals in the title follow the real duration', () {
      expect(retimeTitle('Long Run (115 min)', 126), 'Long Run (126 min)');
      expect(retimeTitle('30m easy return run', 40), '40m easy return run');
    });

    test('schemes and other numbers stay', () {
      expect(
        retimeTitle('Speed Strides 6×1min Z4', 40),
        'Speed Strides 6×1min Z4',
      );
      expect(retimeTitle('Fast Finish 45+12min', 70), 'Fast Finish 45+12min');
    });
  });
}
