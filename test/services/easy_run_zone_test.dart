import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
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

  Future<void> seed(String sport) async {
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    await db.delete(db.workoutTemplates).go();
    await db
        .into(db.workoutTemplates)
        .insert(
          WorkoutTemplatesCompanion.insert(
            id: 'easy',
            sport: sport,
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
            runHrZonesJson: const Value('[92,110,128,146,165]'),
            bikeHrZonesJson: const Value('[112,126,139,151,166]'),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<List<TrainingSession>> plan(String sport) async {
    await TrainingPlanService(
      db,
      garminProviders(db, FakeWorkoutGarmin()),
    ).generatePlan(
      athleteId: 'self',
      raceDate: DateTime.now().add(const Duration(days: 8 * 7)),
      sport: sport,
      raceDistanceM: 21097,
      daysPerWeek: 6,
      restDays: const [1],
      strengthDays: const [],
      hoursPerWeek: 8,
      gadSports: [sport],
    );
    return (db.select(
      db.trainingSessions,
    )..where((t) => t.title.equals('Easy Zone One'))).get();
  }

  List<Map<String, dynamic>> steps(TrainingSession s) =>
      (jsonDecode(s.stepsJson!) as List).cast<Map<String, dynamic>>();

  test(
    'an easy run is planned in the lower half of zone 2, not zone 1',
    () async {
      await seed('running');
      final sessions = await plan('running');
      expect(sessions, isNotEmpty);
      final s = sessions.first;
      final list = steps(s);
      // Warm-up and cool-down keep their zone; the main step moves up.
      expect(list.map((e) => e['zoneNumber']), [1, 2, 1]);
      // Zone 2 is 110 to 127 bpm; the lower half is 110 to 119.
      expect(
        [list[1]['targetValueOne'], list[1]['targetValueTwo']],
        [110, 119],
      );
      // Zone 1 is 92 to 109 bpm and stays for the warm-up.
      expect([list[0]['targetValueOne'], list[0]['targetValueTwo']], [92, 109]);
      expect(s.primaryZone, 2);
    },
  );

  test('a recovery ride keeps zone 1: cycling has no such problem', () async {
    await seed('cycling_road');
    final sessions = await plan('cycling_road');
    expect(sessions, isNotEmpty);
    expect(steps(sessions.first).map((e) => e['zoneNumber']), [1, 1, 1]);
    expect(sessions.first.primaryZone, 1);
  });
}
