import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/daily_readiness_service.dart';
import 'package:fjelia/services/session_adaptation_service.dart';
import 'package:fjelia/services/workout_semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> step(String type, int seconds, int zone) => {
  'type': 'ExecutableStepDTO',
  'stepType': {'stepTypeKey': type},
  'endCondition': {'conditionTypeKey': 'time'},
  'endConditionValue': seconds,
  'zoneNumber': zone,
};

Map<String, dynamic> repeat(int n, List<Map<String, dynamic>> steps) => {
  'type': 'RepeatGroupDTO',
  'stepType': {'stepTypeKey': 'repeat'},
  'numberOfIterations': n,
  'endConditionValue': n,
  'workoutSteps': steps,
};

const yellow = ReadinessResult(
  level: ReadinessLevel.yellow,
  flagCount: 2,
  hrvLow: true,
);
const red = ReadinessResult(
  level: ReadinessLevel.red,
  flagCount: 3,
  hrvLow: true,
);
const rest = ReadinessResult(
  level: ReadinessLevel.red,
  flagCount: 3,
  hrvLow: true,
  severity: TrainingSeverity.rest,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late SessionAdaptationService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = SessionAdaptationService(db);
    await db
        .into(db.trainingPlans)
        .insert(
          TrainingPlansCompanion.insert(
            id: 'p',
            athleteId: 'self',
            startDate: DateTime(2026, 10, 1),
            endDate: DateTime(2027, 4, 1),
            status: 'active',
            generatedAt: DateTime(2026, 10, 1),
          ),
        );
  });
  tearDown(() => db.close());

  Future<TrainingSession> plan(
    List<Map<String, dynamic>> steps, {
    String title = 'Long Run (115 min)',
    int minutes = 115,
  }) async {
    await db
        .into(db.trainingSessions)
        .insert(
          TrainingSessionsCompanion.insert(
            id: 's',
            planId: 'p',
            athleteId: 'self',
            sessionDate: DateTime(2026, 10, 25),
            sessionNumber: 1,
            weekNumber: 1,
            sport: 'running',
            sessionType: 'long',
            phase: 'base',
            primaryZone: 2,
            title: title,
            stepsJson: Value(jsonEncode(steps)),
            plannedDurationMin: minutes,
            plannedTrimp: 100,
            sessionLevel: 5,
          ),
        );
    return (db.select(
      db.trainingSessions,
    )..where((t) => t.id.equals('s'))).getSingle();
  }

  Future<TrainingSession> reload() => (db.select(
    db.trainingSessions,
  )..where((t) => t.id.equals('s'))).getSingle();

  final steady = [
    step('warmup', 900, 1),
    step('interval', 5400, 2),
    step('cooldown', 600, 1),
  ];

  test(
    'yellow shortens the steps, so the duration shown is the real one',
    () async {
      final s = await plan(steady);
      final result = await service.adapt(s, yellow);
      expect(result.adapted, isTrue);
      final after = await reload();
      expect(after.status, 'adapted');
      final semantics = WorkoutSemantics.of(after.stepsJson);
      expect(after.plannedDurationMin, semantics.totalMinutes);
      expect(after.plannedDurationMin, lessThan(115));
      expect(after.plannedDurationMin, closeTo(115 * 0.85, 2));
      expect(after.title, contains('(${after.plannedDurationMin} min)'));
      // The main step went from zone 2 to zone 1.
      expect(after.primaryZone, 1);
    },
  );

  test('the same evidence twice does not cut a second time', () async {
    final s = await plan(steady);
    await service.adapt(s, yellow);
    final once = await reload();
    final again = await service.adapt(once, yellow);
    expect(again.adapted, isFalse);
    final twice = await reload();
    expect(twice.plannedDurationMin, once.plannedDurationMin);
    expect(twice.stepsJson, once.stepsJson);
  });

  test('a stronger finding supersedes an earlier yellow one', () async {
    final s = await plan(steady);
    await service.adapt(s, yellow);
    final result = await service.adapt(await reload(), red);
    expect(result.adapted, isTrue);
    final after = await reload();
    expect(after.title, 'Easy Recovery Run');
    expect(after.plannedDurationMin, 30);
  });

  test('intervals lose one repetition instead of a number', () async {
    final s = await plan(
      [
        step('warmup', 600, 1),
        repeat(5, [step('interval', 240, 4), step('recovery', 120, 1)]),
        step('cooldown', 300, 1),
      ],
      title: 'VO2max 5×4min',
      minutes: 45,
    );
    await service.adapt(s, yellow);
    final after = await reload();
    final steps = jsonDecode(after.stepsJson!) as List;
    expect((steps[1] as Map)['numberOfIterations'], 4);
    expect(after.plannedDurationMin, 600 ~/ 60 + 4 * 6 + 5);
    // Zones came down by one.
    expect(
      (((steps[1] as Map)['workoutSteps'] as List).first as Map)['zoneNumber'],
      3,
    );
  });

  test(
    'rest advised adds no session: the session is released and says why',
    () async {
      final s = await plan(steady);
      final result = await service.adapt(s, rest);
      expect(result.adapted, isTrue);
      final after = await reload();
      expect(after.status, 'skipped');
      // Nothing was replaced by an easy session.
      expect(after.title, 'Long Run (115 min)');
      final actual = await (db.select(
        db.sessionActuals,
      )..where((t) => t.sessionId.equals('s'))).getSingle();
      expect(actual.skipReason, 'Rest advised by readiness');
      expect(await db.select(db.sessionAdaptations).get(), hasLength(1));
    },
  );

  test('green changes nothing', () async {
    final s = await plan(steady);
    final result = await service.adapt(
      s,
      const ReadinessResult(level: ReadinessLevel.green, flagCount: 0),
    );
    expect(result.adapted, isFalse);
    expect((await reload()).status, 'planned');
  });
}
