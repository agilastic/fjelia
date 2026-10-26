import 'package:fjelia/api/polar_workout.dart';
import 'package:fjelia/models/prepared_workout.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> polarTestStep({int seconds = 600, int zone = 2}) => {
  'type': 'ExecutableStepDTO',
  'stepType': {'stepTypeKey': 'warmup'},
  'endCondition': {'conditionTypeKey': 'time'},
  'endConditionValue': seconds,
  'targetType': {'workoutTargetTypeKey': 'heart.rate.zone'},
  'zoneNumber': zone,
  'targetValueOne': 110,
  'targetValueTwo': 127,
};

PreparedWorkout polarTestWorkout({
  List<Map<String, dynamic>>? steps,
  String sport = 'running',
  bool indoor = false,
  DateTime? date,
  String title = 'Easy run',
  String description = 'Keep it easy.',
}) => PreparedWorkout(
  sessionId: 's1',
  title: title,
  date: date ?? DateTime(2026, 10, 28),
  sport: sport,
  indoor: indoor,
  steps: steps ?? [polarTestStep()],
  description: description,
);

void main() {
  Map exercise(Map target) => (target['exerciseTargets'] as List).single as Map;

  test('uses local scheduling, a running profile, HR zones and bpm labels', () {
    final target = buildPolarWorkout(polarTestWorkout());
    expect(target['datetime'], '2026-10-28T18:00');
    expect(target['type'], 'PHASED');
    expect(exercise(target)['sportId'], 1);
    final phase = (exercise(target)['phases'] as List).single;
    expect(phase['duration'], '00:10:00');
    expect(phase['distance'], isNull);
    expect(phase['goalType'], 'DURATION');
    expect(phase['intensityType'], 'HEART_RATE_ZONES');
    expect(phase['lowerZone'], 2);
    expect(phase['upperZone'], 2);
    expect(phase['name'], contains('110–127 bpm'));
    expect(phase['phaseChangeType'], 'AUTOMATIC');
    expect(
      buildPolarWorkout(
        polarTestWorkout(date: DateTime(2026, 10, 28, 7, 15)),
      )['datetime'],
      '2026-10-28T07:15',
    );
    expect(
      exercise(buildPolarWorkout(polarTestWorkout(indoor: true)))['sportId'],
      17,
    );
  });

  test('preserves distance in metres and repeated phase structure', () {
    final distance = {
      ...polarTestStep(),
      'endCondition': {'conditionTypeKey': 'distance'},
      'endConditionValue': 400,
      'targetType': {'workoutTargetTypeKey': 'no.target'},
    };
    final target = buildPolarWorkout(
      polarTestWorkout(
        steps: [
          polarTestStep(),
          {
            'type': 'RepeatGroupDTO',
            'numberOfIterations': 6,
            'workoutSteps': [distance, polarTestStep(seconds: 60, zone: 1)],
          },
        ],
      ),
    );
    final phases = exercise(target)['phases'] as List;
    expect(phases, hasLength(2));
    expect(phases[1]['phaseType'], 'REPEAT');
    expect(phases[1]['repeatCount'], 6);
    final interval = (phases[1]['phases'] as List).first;
    expect(interval['duration'], isNull);
    expect(interval['distance'], 400);
    expect(interval['intensityType'], 'NONE');
    expect(interval['lowerZone'], isNull);
  });

  test(
    'rejects open steps, unknown sports, custom targets and invalid zones',
    () {
      for (final step in [
        {
          ...polarTestStep(),
          'endCondition': {'conditionTypeKey': 'lap.button'},
        },
        {...polarTestStep(), 'endConditionValue': 0},
        {...polarTestStep(), 'endConditionValue': double.nan},
        {...polarTestStep(), 'zoneNumber': 6},
        {
          ...polarTestStep(),
          'targetType': {'workoutTargetTypeKey': 'power.zone'},
        },
      ]) {
        expect(
          () => buildPolarWorkout(polarTestWorkout(steps: [step])),
          throwsA(isA<PolarUnsupportedWorkout>()),
        );
      }
      expect(
        () => buildPolarWorkout(polarTestWorkout(sport: 'yoga')),
        throwsA(isA<PolarUnsupportedWorkout>()),
      );
      expect(
        () => buildPolarWorkout(polarTestWorkout(steps: [])),
        throwsA(isA<PolarUnsupportedWorkout>()),
      );
    },
  );

  test('enforces phase and repeat limits before sending anything', () {
    Map<String, dynamic> repeat(
      int count,
      List<Map<String, dynamic>> children,
    ) => {
      'type': 'RepeatGroupDTO',
      'numberOfIterations': count,
      'workoutSteps': children,
    };
    for (final steps in [
      List.generate(21, (_) => polarTestStep()),
      [
        repeat(99, [polarTestStep(), polarTestStep(), polarTestStep()]),
      ],
      [
        repeat(100, [polarTestStep()]),
      ],
      [
        repeat(2, [
          repeat(2, [
            repeat(2, [polarTestStep()]),
          ]),
        ]),
      ],
    ]) {
      expect(
        () => buildPolarWorkout(polarTestWorkout(steps: steps)),
        throwsA(isA<PolarUnsupportedWorkout>()),
      );
    }
  });

  test('fits Flow text limits without breaking Unicode characters', () {
    final target = buildPolarWorkout(
      polarTestWorkout(
        title: List.filled(50, '🏃').join(),
        description: List.filled(600, '🏃').join(),
      ),
    );
    expect((target['name'] as String).runes, hasLength(45));
    expect((target['description'] as String).runes, hasLength(500));
  });
}
