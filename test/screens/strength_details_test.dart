import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/strength_workout.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/screens/strength/strength_sections.dart';
import 'package:fjelia/screens/strength/strength_focus_screen.dart';
import 'package:fjelia/screens/strength/strength_trend_sheet.dart';
import 'package:fjelia/widgets/strength_demo.dart';
import 'package:fjelia/services/strength/strength_repository.dart';
import 'package:fjelia/services/strength/strength_templates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercise demonstrations loop for ever, so the screen never settles:
/// pump a fixed two seconds instead.
Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppDatabase db;
  late ActivityRecord activity;
  final full = bundledStrengthTemplates.first;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'gym',
            name: 'Strength',
            type: 'strength_training',
            startDate: DateTime(2026, 10, 27, 18),
            durationSeconds: 3300,
            avgHeartRate: const Value(112),
          ),
        );
    activity = (await db.select(db.activityRecords).get()).single;
  });
  tearDown(() => db.close());

  Future<void> show(
    WidgetTester tester,
    Widget child, {
    double width = 393,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [child],
            ),
          ),
        ),
      ),
    );
    await frames(tester);
  }

  Future<void> linkSession() async {
    await db
        .into(db.trainingPlans)
        .insert(
          TrainingPlansCompanion.insert(
            id: 'plan',
            athleteId: 'self',
            startDate: DateTime(2026, 10, 1),
            endDate: DateTime(2027, 1, 1),
            status: 'active',
            generatedAt: DateTime(2026, 10, 1),
          ),
        );
    await db
        .into(db.trainingSessions)
        .insert(
          TrainingSessionsCompanion.insert(
            id: 'session',
            planId: 'plan',
            athleteId: 'self',
            sessionDate: DateTime(2026, 10, 27),
            sessionNumber: 1,
            weekNumber: 1,
            sport: 'strength',
            sessionType: 'key',
            subType: const Value('strengthFull'),
            phase: 'base',
            primaryZone: 3,
            title: 'Full Body Strength — Base',
            sessionNotes: Value(full.legacyDescription),
            plannedDurationMin: 55,
            plannedTrimp: 50,
            sessionLevel: 2,
          ),
        );
    await db
        .into(db.sessionActuals)
        .insert(
          const SessionActualsCompanion(
            sessionId: Value('session'),
            activityId: Value('gym'),
          ),
        );
  }

  testWidgets(
    'imported activity without sets says so, invents nothing (STR-A09)',
    (tester) async {
      await show(tester, CompletedStrengthSection(activity: activity));
      expect(
        find.text(
          'Exercise details were not provided by this activity source.',
        ),
        findsOneWidget,
      );
      expect(find.text('Add exercise details'), findsOneWidget);
      expect(find.text('Log from plan'), findsNothing, reason: 'no plan link');
      expect(find.textContaining('0 exercises'), findsNothing);
      expect(find.text('Completed sets'.toUpperCase()), findsNothing);
      expect(await db.select(db.strengthActivityLogs).get(), isEmpty);
    },
  );

  testWidgets(
    'log from the linked plan: targets stay hints until recorded (STR-A19)',
    (tester) async {
      await linkSession();
      await show(tester, CompletedStrengthSection(activity: activity));
      await tester.tap(find.text('Log from plan'));
      await frames(tester);
      expect(find.text('BACK SQUAT'), findsOneWidget);
      expect(find.text('Not recorded'), findsWidgets);
      // Opening the editor saves the plan revision it compares with, not
      // any result.
      expect(await db.select(db.strengthPerformedSets).get(), isEmpty);
      // A range target cannot be completed as planned: the form asks.
      await tester.tap(
        find
            .byTooltip('Enter the repetitions done; the plan has a range.')
            .first,
      );
      await frames(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Reps done'), '10');
      await tester.enterText(find.widgetWithText(TextField, 'Load'), '60');
      await tester.tap(find.text('Apply'));
      await frames(tester);
      expect(find.text('Saved'), findsOneWidget);
      final log = (await StrengthRepository(db).loadLog('gym'))!;
      final sets = log.sets.toList();
      expect(sets.first.status, StrengthSetStatus.completed);
      expect(sets.first.reps, 10);
      expect(sets.first.load?.kg, 60);
      expect(
        sets.first.restSeconds,
        isNull,
        reason: 'planned rest is not actual',
      );
      expect(
        sets.skip(1).every((s) => s.status == StrengthSetStatus.unrecorded),
        isTrue,
      );
      expect(log.baseline?.ownerKey, 'session');
      expect(log.baseline?.retrospective, isFalse);
    },
  );

  testWidgets('recorded sets show status words and known totals (STR-A02)', (
    tester,
  ) async {
    await StrengthRepository(db).saveLog(
      StrengthActivityLog(
        activityId: 'gym',
        exercises: [
          StrengthPerformedExercise(
            id: 'e',
            variantId: 'bench_press',
            name: 'Bench press',
            equipment: 'Barbell',
            sets: const [
              StrengthSetResult(
                id: 'a',
                status: StrengthSetStatus.completed,
                reps: 10,
                load: StrengthLoad(70),
              ),
              StrengthSetResult(
                id: 'b',
                status: StrengthSetStatus.failed,
                reps: 0,
                load: StrengthLoad(70),
              ),
              StrengthSetResult(
                id: 'c',
                status: StrengthSetStatus.completed,
                reps: 8,
              ),
            ],
          ),
        ],
      ),
    );
    await show(tester, CompletedStrengthSection(activity: activity));
    expect(find.text('BENCH PRESS'), findsOneWidget);
    expect(find.text('700 kg·reps'), findsOneWidget);
    expect(find.text('Known for 2 of 3 loaded sets'), findsOneWidget);
    expect(find.text('1 failed'), findsOneWidget);
    await tester.tap(find.byTooltip('Expand Bench press'));
    await frames(tester);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Done'), findsNWidgets(2));
    expect(
      find.text('8 × — kg'),
      findsOneWidget,
      reason: 'unknown load is a dash',
    );
  });

  for (final (width, scale) in [(320.0, 2.0), (393.0, 1.0), (430.0, 1.3)]) {
    testWidgets('planned layout at $width px, text ×$scale (STR-A17)', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await show(
        tester,
        PlannedStrengthSection(
          owner: StrengthPlanOwner.session('s'),
          sessionDate: DateTime(2026, 10, 27),
          fallback: full.build(),
        ),
        width: width,
        textScale: scale,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('BACK SQUAT'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Expand Back squat'));
      await frames(tester);
      await tester.tap(find.byTooltip('Expand Back squat'));
      await frames(tester);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('8–10 reps').first);
      await frames(tester);
      expect(
        find.bySemanticsLabel(RegExp('^Set 1: target 8–10 reps')),
        findsWidgets,
      );
      semantics.dispose();
    });
  }

  testWidgets('history hint is shown and applied only on request (STR-A21)', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repo = StrengthRepository(db);
    await repo.saveLog(
      StrengthActivityLog(
        activityId: 'gym',
        exercises: [
          StrengthPerformedExercise(
            id: 'sq',
            variantId: 'back_squat',
            name: 'Back squat',
            equipment: 'Barbell',
            sets: [
              for (final (i, r) in [10, 9, 8].indexed)
                StrengthSetResult(
                  id: 's$i',
                  status: StrengthSetStatus.completed,
                  reps: r,
                  load: const StrengthLoad(70),
                ),
            ],
          ),
        ],
      ),
    );
    final owner = StrengthPlanOwner.session('next');
    await show(
      tester,
      PlannedStrengthSection(
        owner: owner,
        sessionDate: DateTime(2026, 11, 3),
        fallback: full.build(),
      ),
    );
    expect(find.text('Last time: 70 kg · 10 / 9 / 8'), findsOneWidget);
    expect(await repo.loadPlan(owner), isNull, reason: 'viewing saves nothing');
    await tester.tap(
      find.bySemanticsLabel('Use Last time: 70 kg · 10 / 9 / 8'),
    );
    await frames(tester);
    final saved = (await repo.loadPlan(owner))!;
    final squat = saved.plan.exercises.firstWhere(
      (e) => e.variantId == 'back_squat',
    );
    expect(squat.sets.map((s) => s.load?.kg), [70, 70, 70]);
    expect(squat.sets.map((s) => s.repsText), [
      '8–10',
      '8–10',
      '8–10',
    ], reason: 'history never changes the programme reps');
    final other = saved.plan.exercises.firstWhere(
      (e) => e.variantId == 'deadlift',
    );
    expect(other.sets.every((s) => s.load == null), isTrue);
    semantics.dispose();
  });

  testWidgets(
    'editing adds a set and saves a revision for this workout (STR-A14)',
    (tester) async {
      final owner = StrengthPlanOwner.session('s');
      await show(
        tester,
        PlannedStrengthSection(
          owner: owner,
          sessionDate: DateTime(2026, 10, 27),
          fallback: full.build(),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Edit exercises'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Edit exercises'));
      await frames(tester);
      await tester.tap(find.text('Edit exercises'));
      await frames(tester);
      await tester.tap(find.text('Add set').first);
      await frames(tester);
      expect(find.text('Unsaved changes'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await frames(tester);
      final saved = (await StrengthRepository(db).loadPlan(owner))!;
      expect(saved.revision, 1);
      final squat = saved.plan.exercises.first;
      expect(squat.sets.length, 4);
      expect(
        squat.sets.map((s) => s.id).toSet().length,
        4,
        reason: 'new set id',
      );
      expect(
        squat.sets.take(3).map((s) => s.id),
        full.build().exercises.first.sets.map((s) => s.id),
      );
    },
  );

  group('load proposals (Stage B)', () {
    final owner = StrengthPlanOwner.session('next');
    StrengthWorkoutPlan benchPlan() => StrengthWorkoutPlan(
      blocks: [
        StrengthBlock(
          id: 'blk',
          exercises: [
            StrengthPlannedExercise(
              id: 'bench',
              variantId: 'bench_press',
              name: 'Bench press',
              equipment: 'Barbell',
              sets: [
                for (var i = 0; i < 3; i++)
                  StrengthSetTarget(
                    id: 'b$i',
                    repMin: 8,
                    repMax: 10,
                    effort: const StrengthEffort(StrengthEffortScale.rir, 2),
                  ),
              ],
            ),
          ],
        ),
      ],
    );

    Future<void> history(StrengthRepository repo) async {
      final today = DateUtils.dateOnly(DateTime.now());
      for (final (id, days) in [('h1', 7), ('h2', 3)]) {
        await db
            .into(db.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: id,
                name: 'Gym',
                type: 'strength_training',
                startDate: today.subtract(Duration(days: days, hours: 6)),
                durationSeconds: 3600,
              ),
            );
        await repo.saveLog(
          StrengthActivityLog(
            activityId: id,
            exercises: [
              StrengthPerformedExercise(
                id: '$id-e',
                variantId: 'bench_press',
                name: 'Bench press',
                equipment: 'Barbell',
                sets: [
                  for (var i = 0; i < 3; i++)
                    StrengthSetResult(
                      id: '$id-$i',
                      status: StrengthSetStatus.completed,
                      reps: 10,
                      load: const StrengthLoad(70),
                      effort: const StrengthEffort(StrengthEffortScale.rir, 2),
                    ),
                ],
              ),
            ],
          ),
        );
      }
    }

    Widget section({String? blocked}) => PlannedStrengthSection(
      owner: owner,
      sessionDate: DateTime.now(),
      fallback: benchPlan(),
      progressionBlockedReason: blocked,
    );

    testWidgets('unknown load step asks for one; nothing is proposed', (
      tester,
    ) async {
      final repo = StrengthRepository(db);
      await history(repo);
      await show(tester, section());
      expect(find.text('Set load step'), findsOneWidget);
      expect(find.text('Apply to this workout'), findsNothing);
      expect(await repo.loadPlan(owner), isNull);
    });

    testWidgets('apply saves the increment only on request (STR-A35)', (
      tester,
    ) async {
      final repo = StrengthRepository(db);
      await history(repo);
      await repo.rememberIncrement(
        benchPlan().exercises.single.contextKey,
        const StrengthLoad(2.5),
      );
      await show(tester, section());
      expect(find.text('70 kg → 72.5 kg'), findsOneWidget);
      expect(
        await repo.loadPlan(owner),
        isNull,
        reason: 'viewing saves nothing',
      );
      await tester.tap(find.text('View supporting sets'));
      await frames(tester);
      expect(find.text('Set 1: 10 × 70 kg · RIR 2'), findsNWidgets(2));
      await tester.tap(find.text('Close'));
      await frames(tester);
      await tester.tap(find.text('Apply to this workout'));
      await frames(tester);
      final saved = (await repo.loadPlan(owner))!;
      expect(saved.plan.exercises.single.sets.map((s) => s.load?.kg), [
        72.5,
        72.5,
        72.5,
      ]);
      expect(find.text('Apply to this workout'), findsNothing);
      expect(
        find.textContaining('after your review (rule v1)'),
        findsOneWidget,
      );
    });

    testWidgets('keep current load hides that proposal and saves no plan', (
      tester,
    ) async {
      final repo = StrengthRepository(db);
      await history(repo);
      await repo.rememberIncrement(
        benchPlan().exercises.single.contextKey,
        const StrengthLoad(2.5),
      );
      await show(tester, section());
      await tester.tap(find.text('Keep current load'));
      await frames(tester);
      expect(find.text('Apply to this workout'), findsNothing);
      expect(await repo.loadPlan(owner), isNull);
      expect(
        (await repo.proposalDecisions(owner)).values.single.decision,
        'dismissed',
      );
    });

    testWidgets('taper keeps the load (STR-A36)', (tester) async {
      final repo = StrengthRepository(db);
      await history(repo);
      await repo.rememberIncrement(
        benchPlan().exercises.single.contextKey,
        const StrengthLoad(2.5),
      );
      await show(tester, section(blocked: 'Taper phase'));
      expect(find.text('Apply to this workout'), findsNothing);
      expect(
        find.text('Taper phase: the load stays as programmed.'),
        findsOneWidget,
      );
    });
  });

  group('Stage C', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('gym mode records a set and its measured rest (C1)', (
      tester,
    ) async {
      final owner = StrengthPlanOwner.session('gym-next');
      await show(
        tester,
        PlannedStrengthSection(
          owner: owner,
          sessionDate: DateTime.now(),
          fallback: full.build(),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Start workout'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Start workout'));
      await frames(tester);
      await tester.tap(find.text('Start workout'));
      await settle(tester);
      expect(find.text('EXERCISE 1 · SET 1 OF 3'), findsOneWidget);
      expect(find.text('Back squat'), findsOneWidget);
      // A rep range starts empty: Done asks for the repetitions.
      await tester.tap(find.text('Done'));
      await settle(tester);
      expect(find.text('Enter the repetitions done.'), findsOneWidget);
      await tester.tap(find.byTooltip('More Reps'));
      await settle(tester);
      expect(find.text('8'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await settle(tester);
      expect(find.text('REST'), findsOneWidget);
      expect(find.text('Planned 2:00'), findsOneWidget);
      await tester.tap(find.text('Start set'));
      await settle(tester);
      final repo = StrengthRepository(db);
      final live = (await repo.openLiveSession(owner))!;
      final first = live.sets.first;
      expect(first.status, StrengthSetStatus.completed);
      expect(first.reps, 8);
      expect(first.load, isNull, reason: 'no load entered: unknown');
      expect(first.restOrigin, StrengthOrigin.timer);
      expect(first.restSeconds, isNotNull);
      expect(
        live.sets
            .skip(1)
            .every((s) => s.status == StrengthSetStatus.unrecorded),
        isTrue,
      );
      expect(find.text('EXERCISE 1 · SET 2 OF 3'), findsOneWidget);
      // Leaving keeps the workout open to resume.
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(find.text('Resume workout'), findsOneWidget);
    });

    testWidgets('trend shows load and estimated 1RM with a table (C2, C3)', (
      tester,
    ) async {
      final repo = StrengthRepository(db);
      final today = DateUtils.dateOnly(DateTime.now());
      for (final (id, days, kg) in [('t1', 9, 100.0), ('t2', 2, 102.5)]) {
        await db
            .into(db.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: id,
                name: 'Gym',
                type: 'strength_training',
                startDate: today.subtract(Duration(days: days)),
                durationSeconds: 3600,
              ),
            );
        await repo.saveLog(
          StrengthActivityLog(
            activityId: id,
            exercises: [
              StrengthPerformedExercise(
                id: '$id-e',
                variantId: 'back_squat',
                name: 'Back squat',
                equipment: 'Barbell',
                sets: [
                  StrengthSetResult(
                    id: '$id-s',
                    status: StrengthSetStatus.completed,
                    reps: 5,
                    load: StrengthLoad(kg),
                  ),
                ],
              ),
            ],
          ),
        );
      }
      final squat = full.build().exercises.first;
      await show(
        tester,
        SizedBox(
          height: 900,
          child: StrengthTrendSheet(
            name: 'Back squat',
            contextKey: squat.contextKey,
            equipment: 'Barbell',
            convention: squat.convention,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Top working load (kg)'), findsOneWidget);
      expect(find.text('Estimated 1RM, middle of range'), findsOneWidget);
      expect(
        find.textContaining('top 102.5 kg · 1RM ≈ 115.3–119.6 kg'),
        findsOneWidget,
      );
    });

    testWidgets('entering a load survives the dialog closing (device bug)', (
      tester,
    ) async {
      final repo = StrengthRepository(db);
      final owner = StrengthPlanOwner.session('load-entry');
      final stored = await repo.savePlan(
        owner,
        full.build(),
        expectedRevision: 0,
      );
      final live = await repo.startLiveSession(
        stored: stored,
        title: 'Strength',
      );
      await show(
        tester,
        SizedBox(
          height: 900,
          child: StrengthFocusScreen(initial: live, startedAt: DateTime.now()),
        ),
      );
      // No load planned: "+" asks for one.
      await tester.tap(find.byTooltip('More Load (kg)'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), '60');
      await tester.tap(find.text('OK'));
      // Run the whole closing animation; the field must not outlive its
      // controller.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.takeException(), isNull);
      expect(find.text('60'), findsOneWidget);
      await tester.tap(find.byTooltip('More Load (kg)'));
      await settle(tester);
      expect(find.text('62.5'), findsOneWidget);
      // Cancel keeps the value.
      await tester.tap(find.text('62.5'));
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('62.5'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('gym mode fits 320 px at 200 % text', (tester) async {
      final repo = StrengthRepository(db);
      final owner = StrengthPlanOwner.session('small');
      final stored = await repo.savePlan(
        owner,
        full.build(),
        expectedRevision: 0,
      );
      final live = await repo.startLiveSession(
        stored: stored,
        title: 'Strength',
      );
      await show(
        tester,
        SizedBox(
          height: 900,
          child: StrengthFocusScreen(initial: live, startedAt: DateTime.now()),
        ),
        width: 320,
        textScale: 2,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Finish workout'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('Done'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('demonstrations hold still when motion is reduced', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: StrengthExerciseDemo(
                variantId: 'back_squat',
                name: 'Back squat',
              ),
            ),
          ),
        ),
      );
      // Nothing is scheduled: a reduced-motion screen settles.
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp('^Back squat demonstration')),
        findsOneWidget,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: StrengthExerciseDemo(variantId: 'custom-x', name: 'Mine'),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(StrengthExerciseDemo),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
        reason: 'no demo, no box',
      );
      semantics.dispose();
    });
  });
}
