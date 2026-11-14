import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/workout_replacement_service.dart';

void main() {
  late AppDatabase db;
  late WorkoutReplacementService service;
  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  var ids = 0;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = WorkoutReplacementService(db);
    await db
        .into(db.trainingPlans)
        .insert(
          TrainingPlansCompanion.insert(
            id: 'plan',
            athleteId: 'self',
            startDate: today.subtract(const Duration(days: 30)),
            endDate: today.add(const Duration(days: 90)),
            status: 'active',
            generatedAt: today,
          ),
        );
  });
  tearDown(() => db.close());

  Future<TrainingSession> session({
    String sport = 'running',
    String title = 'Endurance run',
    String type = 'endurance',
    int zone = 2,
    int minutes = 60,
    int trimp = 60,
    int dayOffset = 0,
    String? steps,
    String? goalRole,
    String phase = 'base',
    int week = 1,
  }) async {
    final id = 's${ids++}';
    await db
        .into(db.trainingSessions)
        .insert(
          TrainingSessionsCompanion.insert(
            id: id,
            planId: 'plan',
            athleteId: 'self',
            sessionDate: today.add(Duration(days: dayOffset, hours: 7)),
            sessionNumber: ids,
            weekNumber: week,
            sport: sport,
            sessionType: type,
            phase: phase,
            primaryZone: zone,
            title: title,
            plannedDurationMin: minutes,
            plannedTrimp: trimp,
            sessionLevel: 1,
            stepsJson: Value(steps),
            goalRole: Value(goalRole),
          ),
        );
    return (db.select(
      db.trainingSessions,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> activity(String type, int minutes, double load, int daysAgo) =>
      db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'a${ids++}',
              name: type,
              type: type,
              startDate: today.subtract(Duration(days: daysAgo, hours: -8)),
              durationSeconds: minutes * 60,
              trainingLoad: Value(load),
            ),
          );

  Future<WorkoutReplacementPreview> replace(TrainingSession s, String target) =>
      service.preview(s, targetSport: target, targetLabel: target);

  test('without history the starter ratio sets the duration', () async {
    final p = await replace(await session(), 'cycling_road');
    // 60 min run × 1.65 → 99 → nearest 5 minutes.
    expect(p.durationMin, 100);
    expect(p.targetLoad, 60);
    expect(p.usedAthleteHistory, isFalse);
    expect(p.warnings, contains('noHistory'));
    expect(p.objective, WorkoutObjective.base);
  });

  test('the athlete\'s own load rates set the duration', () async {
    // Cycling: 1 load per minute; running: 2 per minute.
    await activity('cycling', 60, 60, 10);
    await activity('cycling', 90, 90, 20);
    await activity('running', 30, 60, 12);
    await activity('running', 45, 90, 25);
    // Under 10 minutes: not used.
    await activity('cycling', 5, 50, 3);
    final p = await replace(
      await session(minutes: 50, trimp: 80),
      'cycling_road',
    );
    // 80 / 1 = 80 min, blended with 50 × 2 / 1 = 100 min (65/35) → 87 → 85.
    expect(p.durationMin, 85);
    expect(p.usedAthleteHistory, isTrue);
    expect(p.warnings, isNot(contains('noHistory')));
  });

  test('a run replacement is capped', () async {
    final p = await replace(
      await session(
        sport: 'cycling_road',
        title: 'Endurance ride',
        minutes: 120,
      ),
      'running',
    );
    expect(p.durationMin, 60);
    expect(p.warnings, contains('runningCap'));
  });

  test(
    'a long run cannot be replaced by a long run in another sport',
    () async {
      final p = await replace(
        await session(sport: 'trail_running', title: 'Long run', minutes: 80),
        'running',
      );
      expect(p.objective, WorkoutObjective.longEndurance);
      expect(p.warnings, containsAll(['longRun', 'runningCap']));
    },
  );

  test('race-specific and technique sessions are flagged', () async {
    final race = await replace(
      await session(
        title: 'Threshold intervals',
        zone: 4,
        goalRole: 'primary',
        minutes: 50,
      ),
      'cycling_road',
    );
    expect(race.objective, WorkoutObjective.threshold);
    expect(race.warnings, contains('raceSpecific'));

    final swim = await replace(
      await session(sport: 'swimming', title: 'Technique swim', minutes: 45),
      'cycling_road',
    );
    expect(swim.warnings, contains('swimTechnique'));
  });

  test('hard sessions nearby and low recovery suggest rest', () async {
    await session(title: 'VO2max intervals', zone: 5, dayOffset: 1);
    await db
        .into(db.dayScoreRecords)
        .insert(
          DayScoreRecordsCompanion.insert(
            date: today.subtract(const Duration(days: 1)),
            recoveryScore: const Value(28),
          ),
        );
    final p = await replace(
      await session(title: 'Tempo run', zone: 3, minutes: 50),
      'cycling_road',
    );
    expect(p.objective, WorkoutObjective.tempo);
    expect(p.warnings, containsAll(['nearbyHard', 'lowRecovery']));
    expect(p.suggestRest, isTrue);
  });

  test('a session that is most of the week is flagged', () async {
    await session(
      title: 'Easy run',
      zone: 1,
      minutes: 30,
      trimp: 20,
      dayOffset: 2,
    );
    final p = await replace(
      await session(minutes: 90, trimp: 120),
      'cycling_road',
    );
    expect(p.warnings, contains('largeWeeklyShare'));
  });

  test('steps keep their structure, distances become times', () async {
    Map<String, Object> step(
      String type,
      int id,
      String condition,
      int value, {
      Map<String, Object> extra = const {},
    }) => {
      'type': 'ExecutableStepDTO',
      'stepType': {'stepTypeId': id, 'stepTypeKey': type},
      'endCondition': {'conditionTypeKey': condition},
      'endConditionValue': value,
      'zoneNumber': type == 'interval' ? 4 : 1,
      ...extra,
    };
    final steps = jsonEncode([
      step('warmup', 1, 'time', 600),
      {
        'type': 'RepeatGroupDTO',
        'numberOfIterations': 4,
        'workoutSteps': [
          step(
            'interval',
            3,
            'distance',
            1000,
            extra: {'targetType': 'pace', 'targetValueOne': 4.2},
          ),
        ],
      },
      step('cooldown', 2, 'time', 300),
    ]);
    final p = await replace(
      await session(
        title: 'Threshold 4×1 km',
        zone: 4,
        minutes: 40,
        steps: steps,
      ),
      'cycling_road',
    );
    // 40 min × 1.65 → 66 → 65 min.
    expect(p.durationMin, 65);
    final out = jsonDecode(p.stepsJson) as List;
    final interval = (out[1]['workoutSteps'] as List).single as Map;
    expect(out[1]['numberOfIterations'], 4);
    expect(interval['endCondition']['conditionTypeKey'], 'time');
    expect(interval['zoneNumber'], 4);
    expect(interval.containsKey('targetType'), isFalse);
    expect(interval.containsKey('targetValueOne'), isFalse);
    // 1 km by bike ≈ 120 s; the whole workout is scaled to 65 minutes.
    final total =
        (out[0]['endConditionValue'] as int) +
        4 * (interval['endConditionValue'] as int) +
        (out[2]['endConditionValue'] as int);
    expect(total, closeTo(65 * 60, 5));
    expect(
      (out[0]['endConditionValue'] as int) /
          (out[2]['endConditionValue'] as int),
      closeTo(2, .01),
    );
  });

  test('without steps a simple workout is built', () async {
    final p = await replace(await session(minutes: 50), 'cycling_road');
    final out = jsonDecode(p.stepsJson) as List;
    expect(
      [for (final s in out) s['stepType']['stepTypeKey']],
      ['warmup', 'interval', 'cooldown'],
    );
    expect(
      out.fold<int>(0, (n, s) => n + (s['endConditionValue'] as int)),
      p.durationMin * 60,
    );
    expect(out[1]['zoneNumber'], 2);
  });

  test('unreadable steps fall back to a simple workout', () async {
    final p = await replace(
      await session(minutes: 30, steps: '{broken'),
      'cycling_road',
    );
    final out = jsonDecode(p.stepsJson) as List;
    expect(out.first['stepType']['stepTypeKey'], 'warmup');
    expect(
      out.fold<int>(0, (n, s) => n + (s['endConditionValue'] as int)),
      p.durationMin * 60,
    );
  });
}
