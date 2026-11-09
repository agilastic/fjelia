import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/l10n/l10n_ext.dart';
import 'package:fjelia/l10n/plan_text.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/screens/planner/plan_screen.dart';
import 'package:fjelia/services/race_goal_service.dart';
import 'package:fjelia/services/season/season_report.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:fjelia/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

void main() {
  tearDown(() => setActiveLocale(const Locale('en')));
  testWidgets('the plan speaks German: season, badges, purpose and steps', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.now();
    await tester.runAsync(() async {
      await WorkoutTemplateLibrary(db).seedIfEmpty();
      var n = 0;
      for (var week = 10; week >= 1; week--) {
        for (final (off, sport, min) in const [
          (6, 'running', 50),
          (4, 'running', 60),
          (1, 'running', 100),
          (3, 'cycling_road', 60),
        ]) {
          await db
              .into(db.activityRecords)
              .insert(
                ActivityRecordsCompanion.insert(
                  activityId: 'h${n++}',
                  name: sport,
                  type: sport,
                  startDate: now.subtract(Duration(days: week * 7 - off)),
                  durationSeconds: min * 60,
                  distanceMeters: Value(min * 170.0),
                  source: const Value('garmin'),
                ),
              );
        }
      }
      Future<void> goal(
        String id,
        String name,
        String sport,
        int days,
        double m,
        String prio,
      ) => db
          .into(db.raceGoals)
          .insert(
            RaceGoalsCompanion.insert(
              id: id,
              athleteId: 'self',
              name: name,
              primarySport: sport,
              distanceM: m,
              raceDate: DateTime(now.year, now.month, now.day + days),
              priority: prio,
              source: 'manual',
              createdAt: now,
            ),
          );
      await goal('m', 'Hannover Marathon', 'running', 150, 42195, 'a');
      await goal('h', 'Halbmarathon', 'running', 140, 21097, 'a');
      await goal('s', 'Seeschwimmen', 'swimming', 120, 3000, 'b');
      final goals = await RaceGoalService(db).resolveGoalSet(today: now);
      final g = goals.display!;
      await TrainingPlanService(
        db,
        garminProviders(db, FakeWorkoutGarmin()),
      ).generatePlan(
        athleteId: 'self',
        raceGoalId: g.id,
        raceDate: g.date,
        sport: g.sport,
        raceDistanceM: g.distanceM,
        daysPerWeek: 5,
        hoursPerWeek: 6,
        maxSessionsPerDay: 1,
        gadSports: const ['running', 'swimming'],
        goals: goals,
      );
    });
    setActiveLocale(const Locale('de'));
    tester.view.physicalSize = const Size(393, 9000);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.dark(),
          home: const Scaffold(body: PlanScreen()),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
    final l10n = lookupAppLocalizations(const Locale('de'));
    // The season's verdict is no card on the plan any more (it feeds the
    // FjeliaPro season analysis); its words still read German.
    expect(find.text(l10n.seasonNeedsYourDecision), findsNothing);
    final plan = await tester.runAsync(
      () => db.select(db.trainingPlans).getSingle(),
    );
    final report = SeasonReport.decode(plan!.seasonJson)!;
    expect(report['outcome'], 'requiresDecision');
    final words = [
      ...seasonReportLines(l10n, report),
      ...seasonAlternatives(l10n, report),
    ].join('\n');
    // Conflicts, trade-offs and alternatives in German.
    expect(words, contains('haben beide Priorität A'));
    expect(words, contains('daher ist der Plan für das B-Ziel vorläufig'));
    expect(words, contains('Eines der Events verschieben'));
    expect(words, isNot(contains('priority')));
    expect(words, isNot(contains(' weeks ')));
    expect(find.text('GRUNDLAGE'), findsWidgets);

    // Every purpose the planner wrote is recognised.
    final sessions = await tester.runAsync(
      () => db.select(db.trainingSessions).get(),
    );
    final names = ['Hannover Marathon', 'Halbmarathon', 'Seeschwimmen'];
    final objectives = {
      for (final s in sessions!)
        if (s.goalObjective != null) s.goalObjective!,
    };
    expect(objectives, isNotEmpty);
    for (final o in objectives) {
      expect(
        planObjectiveLabel(l10n, o, goalNames: names),
        isNot(o),
        reason: o,
      );
    }

    // The session sheet: badges, purpose, steps and the move legend. The
    // plan starts today, so the first session shown is a different one each
    // day: take whichever comes first.
    final ordered = [...sessions]
      ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));
    final first = ordered.firstWhere(
      (s) =>
          s.goalObjective != null && find.text(s.title).evaluate().isNotEmpty,
    );
    await tester.tap(find.text(first.title).first);
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(
      find.textContaining(
        '${planPhaseLabel(l10n, first.phase)} · '
        '${sessionTypeLabel(l10n, first.sessionType)}',
      ),
      findsOneWidget,
    );
    expect(find.text('GEPLANT'), findsOneWidget);
    expect(
      find.textContaining(
        planObjectiveLabel(l10n, first.goalObjective!, goalNames: names),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('repeat'), findsNothing);
    expect(find.textContaining('Warm-up'), findsNothing);
    expect(find.text('Ruhetag'), findsOneWidget);
    expect(find.text('rest day'), findsNothing);
    await tester.runAsync(db.close);
  });
}
