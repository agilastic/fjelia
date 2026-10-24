import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_semantics.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:fjelia/utils/week.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late TrainingPlanService service;
  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  DateTime inDays(int n) => DateTime(today.year, today.month, today.day + n);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    service = TrainingPlanService(db, FakeWorkoutGarmin());
  });
  tearDown(() => db.close());

  Future<RaceGoal> goal(
    String id,
    DateTime date, {
    String priority = 'a',
  }) async {
    await db
        .into(db.raceGoals)
        .insert(
          RaceGoalsCompanion.insert(
            id: id,
            athleteId: 'self',
            name: 'Race $id',
            primarySport: 'running',
            distanceM: 42195,
            raceDate: date,
            priority: priority,
            source: 'manual',
            createdAt: today,
          ),
        );
    return (db.select(db.raceGoals)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<String> generate({
    required DateTime raceDate,
    String? raceGoalId,
    String? existingPlanId,
    bool mondayFirst = true,
  }) => service.generatePlan(
    athleteId: 'self',
    raceGoalId: raceGoalId,
    raceDate: raceDate,
    sport: 'running',
    raceDistanceM: 42195,
    daysPerWeek: 6,
    restDays: const [1],
    strengthDays: const [2, 4],
    hoursPerWeek: 10,
    maxSessionsPerDay: 2,
    gadSports: const ['running', 'cycling_road', 'swimming'],
    existingPlanId: existingPlanId,
    weekStartsOnMonday: mondayFirst,
  );

  test('the planned duration is what the steps do, titles included', () async {
    await generate(raceDate: inDays(20 * 7));
    final sessions = await db.select(db.trainingSessions).get();
    expect(sessions, isNotEmpty);
    var withSteps = 0;
    for (final s in sessions) {
      if (s.stepsJson == null) continue;
      withSteps++;
      final steps = WorkoutSemantics.of(s.stepsJson, sport: s.sport);
      expect(
        s.plannedDurationMin,
        steps.totalMinutes,
        reason: '${s.title} (${s.sport}): ${s.plannedDurationMin} min planned',
      );
      final named = RegExp(r'\((\d+) min\)').firstMatch(s.title);
      if (named != null) {
        expect(
          int.parse(named.group(1)!),
          s.plannedDurationMin,
          reason: s.title,
        );
      }
    }
    expect(withSteps, greaterThan(20));
  });

  test('the race day and the day before are free', () async {
    final race = inDays(10 * 7 + 2);
    await generate(raceDate: race);
    final dates = (await db.select(db.trainingSessions).get())
        .map((s) => s.sessionDate)
        .toSet();
    expect(dates, isNot(contains(race)));
    expect(dates, isNot(contains(race.subtract(const Duration(days: 1)))));
    expect(dates.every((d) => d.isBefore(race)), isTrue);
  });

  test('a replan carries on in the same block, not at week one', () async {
    final race = inDays(24 * 7);
    final g = await goal('g', race);
    // A plan that began three weeks ago: this week is its fourth, the
    // recovery week of a four-week cycle.
    await db
        .into(db.trainingPlans)
        .insert(
          TrainingPlansCompanion.insert(
            id: 'p',
            athleteId: 'self',
            raceGoalId: Value(g.id),
            startDate: inDays(-21),
            endDate: race,
            status: 'active',
            generatedAt: inDays(-21),
          ),
        );
    await generate(raceDate: race, raceGoalId: g.id, existingPlanId: 'p');
    final sessions = await (db.select(
      db.trainingSessions,
    )..orderBy([(t) => OrderingTerm.asc(t.sessionDate)])).get();
    expect(sessions.first.weekNumber, 4);
    expect(sessions.first.phase, 'recovery');
    final plan = await (db.select(
      db.trainingPlans,
    )..where((t) => t.id.equals('p'))).getSingle();
    // The anchor stays where the plan began.
    expect(plan.startDate, inDays(-21));
    // The next block starts after it.
    expect(
      sessions
          .where((s) => s.weekNumber == 5)
          .every((s) => s.phase != 'recovery'),
      isTrue,
    );
  });

  test('a different race starts a new season at the first week', () async {
    final race = inDays(24 * 7);
    final g = await goal('g', race);
    await db
        .into(db.trainingPlans)
        .insert(
          TrainingPlansCompanion.insert(
            id: 'p',
            athleteId: 'self',
            raceGoalId: const Value('other'),
            startDate: inDays(-21),
            endDate: race,
            status: 'active',
            generatedAt: inDays(-21),
          ),
        );
    await generate(raceDate: race, raceGoalId: g.id, existingPlanId: 'p');
    final first = (await (db.select(
      db.trainingSessions,
    )..orderBy([(t) => OrderingTerm.asc(t.sessionDate)])).get()).first;
    expect(first.weekNumber, 1);
  });

  test('weeks follow the chosen week start', () async {
    for (final mondayFirst in [true, false]) {
      await db.delete(db.trainingSessions).go();
      await generate(raceDate: inDays(12 * 7), mondayFirst: mondayFirst);
      final first = weekStartOf(today, mondayFirst: mondayFirst);
      for (final s in await db.select(db.trainingSessions).get()) {
        final week = weekStartOf(s.sessionDate, mondayFirst: mondayFirst);
        expect(
          s.weekNumber,
          1 + week.difference(first).inDays ~/ 7,
          reason: '${s.sessionDate} with Monday first: $mondayFirst',
        );
      }
    }
  });

  test('a replan follows the A goal, not the nearest minor race', () async {
    final minor = await goal('b', inDays(6 * 7), priority: 'b');
    final main = await goal('a', inDays(16 * 7));
    await db
        .into(db.trainingPlans)
        .insert(
          TrainingPlansCompanion.insert(
            id: 'p',
            athleteId: 'self',
            raceGoalId: Value(main.id),
            startDate: today,
            endDate: main.raceDate,
            status: 'active',
            generatedAt: today,
          ),
        );
    await service.replan(
      planId: 'p',
      reason: 'test',
      restDays: const [1],
      strengthDays: const [2],
      hoursPerWeek: 8,
      maxSessionsPerDay: 1,
      preferredSports: const ['running'],
    );
    final plan = await (db.select(
      db.trainingPlans,
    )..where((t) => t.id.equals('p'))).getSingle();
    expect(plan.endDate, main.raceDate);
    expect(plan.raceGoalId, main.id);
    expect(minor.raceDate.isBefore(main.raceDate), isTrue);
  });
}
