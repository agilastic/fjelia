import 'package:fjelia/l10n/app_localizations.dart';

import 'dart:convert';

import 'package:fjelia/models/workout_profile.dart';
import 'package:fjelia/widgets/workout_profile_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> step(
  String type,
  int seconds, {
  int? zone,
  String condition = 'time',
}) => {
  'type': 'ExecutableStepDTO',
  'stepType': {'stepTypeKey': type},
  'endCondition': {'conditionTypeKey': condition},
  'endConditionValue': seconds,
  'zoneNumber': ?zone,
};

Map<String, dynamic> repeat(int times, List<Map<String, dynamic>> steps) => {
  'type': 'RepeatGroupDTO',
  'stepType': {'stepTypeKey': 'repeat'},
  'numberOfIterations': times,
  'workoutSteps': steps,
};

String json(List<Map<String, dynamic>> steps) => jsonEncode(steps);

void main() {
  group('workoutProfile', () {
    test('reads blocks in order with their length and zone', () {
      final blocks = workoutProfile(
        json([
          step('warmup', 480),
          step('interval', 300, zone: 2),
          step('interval', 900, zone: 2),
          step('cooldown', 420),
        ]),
        primaryZone: 2,
      );
      expect(blocks.map((b) => b.seconds), [480, 300, 900, 420]);
      expect(blocks.map((b) => b.zone), [1, 2, 2, 1]);
      expect(blocks.map((b) => b.label), [
        'Warm-up',
        'Interval',
        'Interval',
        'Cool-down',
      ]);
      expect(blocks.any((b) => b.estimated), isFalse);
      expect(blocks.fold<double>(0, (s, b) => s + b.seconds), 2100);
    });

    test('expands repeats, also nested ones', () {
      final blocks = workoutProfile(
        json([
          step('warmup', 600),
          repeat(3, [step('interval', 240, zone: 4), step('recovery', 120)]),
          repeat(2, [
            repeat(2, [step('interval', 30, zone: 5)]),
          ]),
        ]),
        primaryZone: 4,
      );
      expect(blocks, hasLength(1 + 6 + 4));
      expect(blocks[1].zone, 4);
      expect(blocks[2].zone, 1);
      expect(blocks[2].label, 'Recovery');
    });

    test('a step without a zone takes the primary zone of the session', () {
      final blocks = workoutProfile(
        json([step('interval', 600), step('rest', 60)]),
        primaryZone: 3,
      );
      expect(blocks.map((b) => b.zone), [3, 1]);
    });

    test('distance and open-ended steps get an estimated length', () {
      final swim = workoutProfile(
        json([step('interval', 500, condition: 'distance')]),
        primaryZone: 2,
        sport: 'swimming',
      );
      expect(swim.single.estimated, isTrue);
      expect(swim.single.seconds, closeTo(700, 1));

      final run = workoutProfile(
        json([step('interval', 1000, condition: 'distance')]),
        primaryZone: 3,
        sport: 'running',
      );
      expect(run.single.seconds, closeTo(360, 1));

      final open = workoutProfile(
        jsonEncode([
          {
            'stepType': {'stepTypeKey': 'interval'},
            'endCondition': {'conditionTypeKey': 'lap.button'},
          },
        ]),
        primaryZone: 2,
      );
      expect(open.single.estimated, isTrue);
      expect(open.single.seconds, 300);
    });

    test('nothing readable gives no blocks', () {
      expect(workoutProfile(null, primaryZone: 2), isEmpty);
      expect(workoutProfile('', primaryZone: 2), isEmpty);
      expect(workoutProfile('{broken', primaryZone: 2), isEmpty);
      expect(workoutProfile('[]', primaryZone: 2), isEmpty);
    });

    test('a huge repeat is capped', () {
      final blocks = workoutProfile(
        json([
          repeat(100, [step('interval', 30, zone: 4), step('rest', 30)]),
        ]),
        primaryZone: 4,
      );
      expect(blocks.length, lessThanOrEqualTo(200));
    });

    test('durations read like the plan list', () {
      expect(formatBlockDuration(45), '45 sec');
      expect(formatBlockDuration(300), '5 min');
      expect(formatBlockDuration(330), '5 min 30 sec');
    });
  });

  group('WorkoutProfileBar', () {
    final blocks = [
      const WorkoutBlock(seconds: 480, zone: 1, label: 'Warm-up'),
      const WorkoutBlock(seconds: 300, zone: 2, label: 'Interval'),
      const WorkoutBlock(seconds: 900, zone: 2, label: 'Interval'),
      const WorkoutBlock(seconds: 420, zone: 1, label: 'Cool-down'),
    ];

    Future<void> pump(WidgetTester tester, List<WorkoutBlock> b) =>
        tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: WorkoutProfileBar(blocks: b),
              ),
            ),
          ),
        );

    testWidgets('shows a summary and block widths follow the duration', (
      tester,
    ) async {
      await pump(tester, blocks);
      expect(find.text('35 min · Z1–Z2'), findsOneWidget);
      final boxes = tester
          .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .toList();
      expect(boxes, hasLength(4));
      // Higher zone, taller block.
      expect(boxes[1].heightFactor!, greaterThan(boxes[0].heightFactor!));
      final widths = [
        for (final e in find.byType(FractionallySizedBox).evaluate())
          tester.getSize(find.byWidget(e.widget)).width,
      ];
      // The 15 minute block is three times as wide as the 5 minute block
      // (less the 2 px gap).
      expect((widths[2] + 2) / (widths[1] + 2), closeTo(3, .1));
    });

    testWidgets('tapping a block names it and tapping again clears it', (
      tester,
    ) async {
      await pump(tester, blocks);
      await tester.tap(find.byType(FractionallySizedBox).at(1));
      await tester.pump();
      expect(find.text('Interval · 5 min · Z2'), findsOneWidget);
      await tester.tap(find.byType(FractionallySizedBox).at(1));
      await tester.pump();
      expect(find.text('35 min · Z1–Z2'), findsOneWidget);
    });

    testWidgets(
      'estimated lengths are marked and nothing shows without blocks',
      (tester) async {
        await pump(tester, const [
          WorkoutBlock(
            seconds: 700,
            zone: 2,
            label: 'Interval',
            estimated: true,
          ),
        ]);
        expect(find.text('≈ 11 min 40 sec · Z2'), findsOneWidget);
        await tester.tap(find.byType(FractionallySizedBox));
        await tester.pump();
        expect(
          find.text('Interval · ≈ 11 min 40 sec · Z2 · estimated length'),
          findsOneWidget,
        );
        await pump(tester, const []);
        expect(find.byType(FractionallySizedBox), findsNothing);
      },
    );

    testWidgets('the profile is described for screen readers', (tester) async {
      await pump(tester, blocks);
      expect(
        find.bySemanticsLabel(RegExp('Workout profile: Warm-up 8 min zone 1')),
        findsOneWidget,
      );
    });
  });
}
