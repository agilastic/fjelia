import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  // A Wednesday morning.
  final now = DateTime(2026, 11, 18, 9);
  final today = DateTime(2026, 11, 18);
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await WorkoutTemplateLibrary(db).seedIfEmpty();
  });
  tearDown(() => db.close());

  TrainingPlanService service() => TrainingPlanService(
    db,
    garminProviders(db, FakeWorkoutGarmin()),
    clock: () => now,
  );

  /// Eight weeks of three easy 40-minute runs.
  Future<void> history() async {
    for (var w = 1; w <= 8; w++) {
      for (final d in [1, 3, 5]) {
        await db
            .into(db.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: 'run$w$d',
                name: 'Run',
                type: 'running',
                startDate: day(-7 * w + d).add(const Duration(hours: 7)),
                durationSeconds: 2400,
                distanceMeters: const Value(7000),
              ),
            );
      }
    }
  }

  Future<List<TrainingSession>> generate(String casual) async {
    await service().generatePlan(
      athleteId: 'self',
      raceDate: day(casualHorizonDays),
      sport: 'running',
      daysPerWeek: 4,
      restDays: const [1, 5],
      strengthDays: const [],
      hoursPerWeek: 4,
      gadSports: const ['running', 'cycling_road'],
      casualGoal: casual,
    );
    return (db.select(
      db.trainingSessions,
    )..orderBy([(t) => OrderingTerm.asc(t.sessionDate)])).get();
  }

  test('no training yet: one easy 25-minute run to start with', () async {
    final sessions = await generate('fitness');
    expect(sessions, hasLength(1));
    final first = sessions.single;
    expect(first.sport, 'running');
    expect(first.plannedDurationMin, inInclusiveRange(24, 26));
    expect(first.primaryZone, 2);
    expect(first.sessionDate, today);
    final plan = (await db.select(db.trainingPlans).get()).single;
    expect(plan.raceGoalId, isNull);
    expect(plan.seasonJson, isNull);
  });

  test('getting fitter: about four weeks of base, one hard session a week, '
      'no taper', () async {
    await history();
    final sessions = await generate('fitness');
    expect(sessions.length, greaterThan(8));
    expect(sessions.last.sessionDate.isAfter(day(20)), isTrue);
    // Base training with recovery weeks: no build, peak or taper.
    expect(
      sessions.every((s) => s.phase == 'base' || s.phase == 'recovery'),
      isTrue,
    );
    final byWeek = <int, int>{};
    for (final s in sessions.where((s) => s.sessionType == 'key')) {
      byWeek[s.weekNumber] = (byWeek[s.weekNumber] ?? 0) + 1;
    }
    expect(byWeek.values.every((n) => n <= 1), isTrue);
    expect(byWeek, isNotEmpty);
  });

  test('for the fun of it: every session easy', () async {
    await history();
    final sessions = await generate('fun');
    expect(sessions, isNotEmpty);
    expect(sessions.any((s) => s.sessionType == 'key'), isFalse);
    expect(sessions.every((s) => s.primaryZone <= 2), isTrue);
  });

  test('a replan of a plan without a race stays without a race', () async {
    await history();
    await generate('fitness');
    final plan = (await db.select(db.trainingPlans).get()).single;
    await service().replan(
      planId: plan.id,
      reason: 'test',
      daysPerWeek: 4,
      restDays: const [1, 5],
      strengthDays: const [],
      hoursPerWeek: 4,
      preferredSports: const ['running'],
      casualGoal: 'fitness',
    );
    final sessions = await (db.select(
      db.trainingSessions,
    )..where((t) => t.status.equals('planned'))).get();
    expect(sessions, isNotEmpty);
    expect(sessions.any((s) => s.phase == 'taper'), isFalse);
    final after = (await db.select(db.trainingPlans).get()).single;
    expect(after.raceGoalId, isNull);
    expect(after.endDate.isAfter(day(20)), isTrue);
  });
}
