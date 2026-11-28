import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/hr_zone_history.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

Map<String, dynamic> hrStep(String type, int seconds, int zone) => {
  'type': 'ExecutableStepDTO',
  'stepType': {'stepTypeKey': type},
  'endCondition': {'conditionTypeKey': 'time'},
  'endConditionValue': seconds,
  'zoneNumber': zone,
  'targetType': {'workoutTargetTypeKey': 'heart.rate.zone'},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late FakeWorkoutGarmin garmin;
  late TrainingPlanService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    garmin = FakeWorkoutGarmin();
    service = TrainingPlanService(db, garminProviders(db, garmin));
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    await db.delete(db.workoutTemplates).go();
    await db
        .into(db.workoutTemplates)
        .insert(
          WorkoutTemplatesCompanion.insert(
            id: 'easy',
            sport: 'running',
            sessionType: 'recovery',
            targetPhase: 'base,build,peak,taper,recovery',
            name: 'Easy Zone One',
            description: 'Easy.',
            stepsJson: jsonEncode([
              hrStep('warmup', 300, 1),
              hrStep('interval', 1800, 1),
              hrStep('cooldown', 300, 1),
            ]),
            parameterizedFor: 'hr',
            estimatedDurationMin: 40,
            estimatedTss: 20,
            source: 'test',
            createdAt: DateTime(2026, 7, 1),
          ),
        );
    await db
        .into(db.athleteThresholds)
        .insert(
          AthleteThresholdsCompanion.insert(
            athleteId: 'self',
            lastUpdatedAt: Value(DateTime(2026, 10, 1)),
            maxHrBpm: const Value(183),
          ),
          mode: InsertMode.insertOrReplace,
        );
    await HrZoneHistory(db).record(
      'running',
      const [92, 110, 128, 146, 165],
      method: ZoneMethod.manual,
      from: DateTime(2026, 1, 1),
    );
  });
  tearDown(() => db.close());

  Future<TrainingSession> easyRun() async {
    await service.generatePlan(
      athleteId: 'self',
      raceDate: DateTime.now().add(const Duration(days: 8 * 7)),
      sport: 'running',
      raceDistanceM: 21097,
      daysPerWeek: 6,
      restDays: const [1],
      strengthDays: const [],
      hoursPerWeek: 8,
      gadSports: const ['running'],
    );
    return (await (db.select(db.trainingSessions)
              ..where((t) => t.title.equals('Easy Zone One'))
              ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)])
              ..limit(1))
            .get())
        .first;
  }

  List<Object?> targets(List<Map<String, dynamic>> steps, int i) => [
    steps[i]['targetValueOne'],
    steps[i]['targetValueTwo'],
  ];

  test('new zones send the workout on the watch again, in them', () async {
    final s = await easyRun();
    await service.pushToGarmin(s.id);
    final first = garmin.creates;
    // Zone 2 is 110 to 127 bpm; the easy run is its lower half.
    expect(targets(garmin.lastSteps, 1), [110, 119]);
    expect(garmin.lastSteps.any((st) => st.containsKey('easyRun')), isFalse);

    // Sent again unchanged: nothing new goes up.
    await service.pushToGarmin(s.id);
    expect(garmin.creates, first);

    await HrZoneHistory(
      db,
    ).record('running', const [100, 120, 135, 150, 168], method: 'manual');
    // Zones of another sport leave the run alone.
    expect(await service.redeliverForZones({'cycling'}), 0);
    expect(garmin.creates, first);

    expect(await service.redeliverForZones({'running'}), greaterThan(0));
    expect(garmin.creates, greaterThan(first));
    // Zone 2 is now 120 to 134 bpm, its lower half 120 to 127; zone 1 runs
    // from 100 to 119.
    expect(targets(garmin.lastSteps, 1), [120, 127]);
    expect(targets(garmin.lastSteps, 0), [100, 119]);
  });

  test('a workout that is not on a watch is not sent by new zones', () async {
    await easyRun();
    final before = garmin.creates;
    await HrZoneHistory(
      db,
    ).record('running', const [100, 120, 135, 150, 168], method: 'manual');
    final delivered = await (db.select(
      db.trainingSessions,
    )..where((t) => t.garminWorkoutId.isNotNull())).get();
    final sent = await service.redeliverForZones({'running'});
    expect(sent, delivered.length);
    expect(garmin.creates, before + delivered.length);
  });
}
