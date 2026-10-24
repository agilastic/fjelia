import 'package:fjelia/models/garmin_data.dart';
import 'package:fjelia/models/planned_workout_presentation.dart';
import 'package:fjelia/models/workout_presentation.dart';
import 'package:fjelia/models/workout_profile.dart';
import 'package:fjelia/screens/activities/workout_detail_sheet.dart';
import 'package:fjelia/widgets/workout_profile_bar.dart';
import 'package:fjelia/widgets/workout_structure_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutStep step(
  String intensity,
  double seconds, {
  int? zone,
  String? description,
}) => WorkoutStep(
  order: 1,
  type: 'ExecutableStepDTO',
  intensity: intensity,
  durationUnit: 'time',
  durationValue: seconds,
  targetZone: zone,
  description: description,
);

final steps = [
  step('WARMUP', 600),
  WorkoutStep(
    order: 2,
    type: 'RepeatGroupDTO',
    repeatCount: 3,
    steps: [
      step('ACTIVE', 240, zone: 4, description: 'Hold steady'),
      step('RECOVERY', 120),
    ],
  ),
  step('COOLDOWN', 600),
];

void main() {
  test('a Garmin workout becomes lines with repeat groups and notes', () {
    final lines = workoutStepLines(steps);
    expect(lines.map((l) => '${l.amount} ${l.label}'.trim()), [
      '10 min Warm-up',
      '3× repeat',
      '4 min Interval',
      '2 min Recovery',
      '10 min Cool-down',
    ]);
    expect(lines[1].repeat, isTrue);
    expect(lines[2].depth, 1);
    expect(lines[2].zone, 4);
    expect(lines[2].note, 'Hold steady');
  });

  test('the blocks expand the repeats and colour easy steps as zone 1', () {
    final blocks = workoutStepBlocks(steps);
    expect(blocks, hasLength(1 + 3 * 2 + 1));
    expect(blocks.first.zone, 1);
    expect(blocks[1].zone, 4);
    expect(blocks[2].label, 'Recovery');
    expect(
      blocks.fold<double>(0, (a, b) => a + b.seconds),
      600 + 3 * 360 + 600,
    );
  });

  test('the zone split comes from the time in each block', () {
    final fractions = zoneFractionsOf(workoutStepBlocks(steps))!;
    // 600 + 3 * 120 + 600 = 1560 s in zone 1, 3 * 240 = 720 s in zone 4.
    expect(fractions[0], closeTo(1560 / 2280, 1e-9));
    expect(fractions[3], closeTo(720 / 2280, 1e-9));
    expect(fractions[1] + fractions[2] + fractions[4], 0);
    expect(zoneFractionsOf(const []), isNull);
  });

  test('a planned tempo run has a Z1 warm-up and a Z4 main part', () {
    const json =
        '[{"stepType":"warmup","endCondition":{"conditionTypeKey":"time"},"endConditionValue":600},'
        '{"stepType":"interval","endCondition":{"conditionTypeKey":"time"},"endConditionValue":3200},'
        '{"stepType":"cooldown","endCondition":{"conditionTypeKey":"time"},"endConditionValue":300}]';
    final lines = plannedStepLines(json, primaryZone: 4);
    expect(lines.map((l) => l.colorZone), [1, 4, 1]);
    final fractions = zoneFractionsOf(workoutProfile(json, primaryZone: 4))!;
    expect(fractions[3], closeTo(3200 / 4100, 1e-9));
    expect(fractions[1], 0);
  });

  test('a zone is shown as heart rate and, with FTP, as watts', () {
    const floors = [108, 137, 148, 158, 166];
    expect(zoneTargetText(4, hrFloors: floors), 'Z4 · 158–165 bpm');
    expect(
      zoneTargetText(4, hrFloors: floors, ftp: 250),
      'Z4 · 158–165 bpm · 225–263 W',
    );
    expect(zoneTargetText(5, hrFloors: floors), 'Z5 · 166+ bpm');
    expect(
      zoneTargetText(1, hrFloors: floors, ftp: 200),
      'Z1 · 108–136 bpm · up to 110 W',
    );
  });

  test('every planned step carries the range of its zone as of today', () {
    const json =
        '[{"stepType":"warmup","endCondition":{"conditionTypeKey":"time"},"endConditionValue":600},'
        '{"stepType":"interval","endCondition":{"conditionTypeKey":"time"},"endConditionValue":1200}]';
    List<String?> targets(int ftp) => [
      for (final l in plannedStepLines(
        json,
        primaryZone: 4,
        zoneTarget: (z) => zoneTargetText(
          z,
          hrFloors: const [108, 137, 148, 158, 166],
          ftp: ftp,
        ),
      ))
        l.target,
    ];
    expect(targets(250), [
      'Z1 · 108–136 bpm · up to 138 W',
      'Z4 · 158–165 bpm · 225–263 W',
    ]);
    // A new FTP changes the watts without touching the stored steps.
    expect(targets(300)[1], 'Z4 · 158–165 bpm · 270–315 W');
    expect(plannedStepLines(json, primaryZone: 4).first.target, isNull);
  });

  test('steps by distance get an estimated length', () {
    final blocks = workoutStepBlocks([
      const WorkoutStep(
        order: 1,
        type: 'ExecutableStepDTO',
        intensity: 'ACTIVE',
        durationUnit: 'distance',
        durationValue: 1000,
      ),
    ], sport: 'running');
    expect(blocks.single.estimated, isTrue);
    expect(blocks.single.seconds, closeTo(360, 1));
  });

  testWidgets(
    'the Garmin workout sheet shows tiles, profile and coloured steps',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutDetailSheet(
            workout: ScheduledWorkout(
              workoutId: '1',
              scheduleId: '1',
              name: 'Run With The Wind',
              sportType: 'running',
              scheduledDate: DateTime(2026, 10, 24),
              steps: steps,
            ),
          ),
        ),
      );
      expect(find.text('DURATION'), findsOneWidget);
      expect(find.text('WORKOUT STRUCTURE'), findsOneWidget);
      expect(find.byType(WorkoutProfileBar), findsOneWidget);
      expect(find.byType(WorkoutStructureList), findsOneWidget);
      expect(find.text('3× repeat'), findsOneWidget);
      expect(find.text('Hold steady'), findsOneWidget);
      // The colours of the bars by role.
      final lines = workoutStepLines(steps);
      expect(workoutStepColor(lines[2]), isNot(workoutStepColor(lines[3])));
      // The colour is the zone colour, as in the profile above the list.
      expect(workoutStepColor(lines[0]), workoutZoneColors[0]);
      expect(workoutStepColor(lines[2]), workoutZoneColors[3]);
    },
  );
}
