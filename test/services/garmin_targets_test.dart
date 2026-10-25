import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:fjelia/services/plan_session_actions.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_semantics.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

/// A step written as a share of FTP with no zone, as the imported Zwift
/// templates are.
Map<String, dynamic> powerStep(String type, int seconds, double fraction) => {
  'type': 'ExecutableStepDTO',
  'stepType': {'stepTypeKey': type},
  'endCondition': {'conditionTypeKey': 'time'},
  'endConditionValue': seconds,
  'ftpFraction': fraction,
  'zoneNumber': null,
  'targetType': {'workoutTargetTypeKey': 'power.zone'},
  'targetValueOne': fraction - 0.02,
  'targetValueTwo': fraction + 0.02,
};

class _ListingGarmin extends FakeWorkoutGarmin {
  final deleted = <String>[];
  @override
  Future<List<({String scheduleId, String workoutId})>> listCalendarWorkouts({
    int monthsAhead = 3,
  }) async => [(scheduleId: 's1', workoutId: 'w1')];
  @override
  Future<List<String>> listWorkoutIds() async => ['w1', 'w2'];
  @override
  Future<void> deleteWorkout(String workoutId, {String? scheduleId}) async =>
      deleted.add(workoutId);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    // One imported running template, power-based, no zones.
    await db.delete(db.workoutTemplates).go();
    await db
        .into(db.workoutTemplates)
        .insert(
          WorkoutTemplatesCompanion.insert(
            id: 't',
            sport: 'running',
            sessionType: 'long',
            subType: const Value('endurance'),
            targetPhase: 'base,build,peak,taper,recovery',
            name: 'Hill Racer Training',
            description: 'Hill training with gradual inclines.',
            stepsJson: jsonEncode([
              powerStep('warmup', 600, 0.5),
              powerStep('interval', 600, 0.7),
              {
                'type': 'RepeatGroupDTO',
                'stepType': {'stepTypeKey': 'repeat'},
                'numberOfIterations': 3,
                'workoutSteps': [
                  powerStep('interval', 600, 0.95),
                  powerStep('recovery', 300, 0.5),
                ],
              },
              powerStep('cooldown', 300, 0.5),
            ]),
            parameterizedFor: 'power',
            estimatedDurationMin: 80,
            estimatedTss: 60,
            source: 'zwo_fyi',
            createdAt: DateTime(2026, 7, 1),
          ),
        );
    await db
        .into(db.athleteThresholds)
        .insert(
          AthleteThresholdsCompanion.insert(
            athleteId: 'self',
            lastUpdatedAt: Value(DateTime(2026, 10, 1)),
            ftpWatts: const Value(264),
            maxHrBpm: const Value(183),
            runHrZonesJson: const Value('[92,110,128,146,165]'),
            bikeHrZonesJson: const Value('[112,126,139,151,166]'),
          ),
          mode: InsertMode.insertOrReplace,
        );
  });
  tearDown(() => db.close());

  Future<TrainingSession> generate(
    TrainingPlanService service, {
    String sport = 'running',
  }) async {
    await service.generatePlan(
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
    return (await (db.select(db.trainingSessions)
              ..where((t) => t.title.equals('Hill Racer Training'))
              ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)])
              ..limit(1))
            .get())
        .first;
  }

  List<Map<String, dynamic>> flat(List steps) => [
    for (final s in steps.cast<Map<String, dynamic>>())
      if (s['workoutSteps'] is List) ...flat(s['workoutSteps'] as List) else s,
  ];

  test('a power-based running template becomes heart-rate zones', () async {
    final s = await generate(TrainingPlanService(db, FakeWorkoutGarmin()));
    final steps = flat(jsonDecode(s.stepsJson!) as List);
    // Every step has its zone, worked out from its share of FTP.
    expect(steps.map((e) => e['zoneNumber']), [1, 2, 4, 1, 1]);
    for (final step in steps) {
      expect(step['targetType']['workoutTargetTypeKey'], 'heart.rate.zone');
      expect(step.containsKey('ftpFraction'), isFalse);
    }
    // Zone 2 runs from its floor to the next floor minus one.
    expect(
      [steps[1]['targetValueOne'], steps[1]['targetValueTwo']],
      [110, 127],
    );
    expect(
      [steps[2]['targetValueOne'], steps[2]['targetValueTwo']],
      [146, 164],
    );
    // The main zone is no longer zone 1 for everything.
    expect(WorkoutSemantics.of(s.stepsJson).dominantZone, 4);
    expect(s.primaryZone, 4);
  });

  test('power stays off the bike unless the athlete has a meter', () async {
    await db.delete(db.workoutTemplates).go();
    await db
        .into(db.workoutTemplates)
        .insert(
          WorkoutTemplatesCompanion.insert(
            id: 'c',
            sport: 'cycling_road',
            sessionType: 'long',
            subType: const Value('endurance'),
            targetPhase: 'base,build,peak,taper,recovery',
            name: 'Hill Racer Training',
            description: 'x',
            stepsJson: jsonEncode([
              powerStep('warmup', 600, 0.5),
              powerStep('interval', 1800, 0.7),
              powerStep('cooldown', 300, 0.5),
            ]),
            parameterizedFor: 'power',
            estimatedDurationMin: 45,
            estimatedTss: 40,
            source: 'domestique',
            createdAt: DateTime(2026, 7, 1),
          ),
        );
    final without = await generate(
      TrainingPlanService(db, FakeWorkoutGarmin()),
      sport: 'cycling_road',
    );
    expect(
      flat(
        jsonDecode(without.stepsJson!) as List,
      ).map((e) => e['targetType']['workoutTargetTypeKey']),
      everyElement('heart.rate.zone'),
    );
    await db.delete(db.trainingSessions).go();
    final withMeter = await generate(
      TrainingPlanService(
        db,
        FakeWorkoutGarmin(),
        usesPower: (sport, indoor) => sport.startsWith('cycl'),
      ),
      sport: 'cycling_road',
    );
    final steps = flat(jsonDecode(withMeter.stepsJson!) as List);
    expect(
      steps.map((e) => e['targetType']['workoutTargetTypeKey']),
      everyElement('power.zone'),
    );
    // 70 % of 264 W, in a band of five percent either side.
    expect(
      [steps[1]['targetValueOne'], steps[1]['targetValueTwo']],
      [176, 194],
    );
    // The zone is set either way.
    expect(steps.map((e) => e['zoneNumber']), [1, 2, 1]);
  });

  test(
    'a smart-trainer ride gets watts, the same ride outdoors heart rate',
    () async {
      final service = TrainingPlanService(
        db,
        FakeWorkoutGarmin(),
        usesPower: (sport, indoor) => false,
      );
      await db.delete(db.workoutTemplates).go();
      await db
          .into(db.workoutTemplates)
          .insert(
            WorkoutTemplatesCompanion.insert(
              id: 'c',
              sport: 'cycling_road',
              sessionType: 'long',
              subType: const Value('endurance'),
              targetPhase: 'base,build,peak,taper,recovery',
              name: 'Hill Racer Training',
              description: 'x',
              stepsJson: jsonEncode([
                powerStep('warmup', 600, 0.5),
                powerStep('interval', 1800, 0.7),
                powerStep('cooldown', 300, 0.5),
              ]),
              parameterizedFor: 'power',
              estimatedDurationMin: 45,
              estimatedTss: 40,
              source: 'domestique',
              createdAt: DateTime(2026, 7, 1),
            ),
          );
      final s = await generate(service, sport: 'cycling_road');
      final outdoor = await service.prepareWorkout(s.id);
      expect(
        flat(outdoor.steps).map((e) => e['targetType']['workoutTargetTypeKey']),
        everyElement('heart.rate.zone'),
      );
      final actions = PlanSessionActions(db, FakeWorkoutGarmin());
      await actions.setTargetMetric(s, 'power');
      final indoor = await service.prepareWorkout(s.id);
      final steps = flat(indoor.steps);
      expect(
        steps.map((e) => e['targetType']['workoutTargetTypeKey']),
        everyElement('power.zone'),
      );
      expect(steps[1]['description'], contains('bpm'));
      expect(steps[1]['targetValueOne'], lessThan(steps[1]['targetValueTwo']));
      final stored = await (db.select(
        db.trainingSessions,
      )..where((t) => t.id.equals(s.id))).getSingle();
      expect((await actions.setTargetMetric(stored, 'hr')).targetMetric, 'hr');
    },
  );

  test(
    'the last chosen bike metric is remembered, indoors starts on watts',
    () {
      const p = UserProfile();
      expect(p.bikeMetric, 'hr');
      expect(p.powerOnBike(indoor: false), isFalse);
      expect(p.powerOnBike(indoor: true), isTrue);
      expect(
        p.copyWith(bikeMetric: 'power').powerOnBike(indoor: false),
        isTrue,
      );
      expect(
        UserProfile.fromJson({'bikePowerTargets': true}).bikeMetric,
        'power',
      );
      expect(UserProfile.fromJson({}).bikeMetric, 'hr');
    },
  );

  test(
    'deleting everything: the phone first, then Garmin with progress',
    () async {
      final garmin = _ListingGarmin();
      final service = TrainingPlanService(db, garmin);
      await generate(service);
      await service.deleteLocalPlans();
      expect(await db.select(db.trainingSessions).get(), isEmpty);
      expect(await db.select(db.trainingPlans).get(), isEmpty);
      expect(garmin.deleted, isEmpty);
      final seen = <(int, int)>[];
      await service.deleteGarminWorkouts(
        onProgress: (done, total, _) => seen.add((done, total)),
      );
      expect(garmin.deleted, ['w1', 'w1', 'w2']);
      expect(seen.last, (3, 3));
    },
  );

  test('the workout on the watch carries its targets as comments', () async {
    final garmin = FakeWorkoutGarmin();
    final service = TrainingPlanService(db, garmin);
    final s = await generate(service);
    await service.pushToGarmin(s.id);
    // Floors are floors: zone 2 is 110 to 127, not 92 to 110.
    final steps = flat(garmin.lastSteps);
    expect(steps[1]['description'], 'Z2 · 110–127 bpm');
    expect(
      steps.map((e) => e['targetType']['workoutTargetTypeKey']),
      everyElement('heart.rate.zone'),
    );
    final text = garmin.lastDescription!;
    expect(text, contains('Hill training with gradual inclines.'));
    expect(text, contains('TARGETS: heart rate in your zones'));
    expect(text, contains('10 min Warm-up · Z1 · 92–109 bpm'));
    expect(text, contains('3× repeat'));
    expect(text, contains('  10 min Interval · Z4 · 146–164 bpm'));
    expect(text, contains('5 min Recovery · Z1 · 92–109 bpm'));
    expect(text, matches(RegExp(r'Total \d+ min\.')));
    expect(text.length, lessThan(1500));
  });

  test('goal and pace guide reach the workout text, for any watch', () async {
    await db
        .into(db.raceGoals)
        .insert(
          RaceGoalsCompanion.insert(
            id: 'goal',
            athleteId: 'self',
            name: 'Hannover',
            primarySport: 'running',
            distanceM: 42195,
            elevationM: const Value(100),
            targetFinishSeconds: const Value(12600),
            raceDate: DateTime.now().add(const Duration(days: 10 * 7)),
            priority: 'a',
            source: 'manual',
            createdAt: DateTime.now(),
          ),
        );
    final garmin = FakeWorkoutGarmin();
    final service = TrainingPlanService(db, garmin);
    await service.generatePlan(
      athleteId: 'self',
      raceGoalId: 'goal',
      raceDate: DateTime.now().add(const Duration(days: 10 * 7)),
      sport: 'running',
      raceDistanceM: 42195,
      raceElevationM: 100,
      targetFinishSeconds: 12600,
      daysPerWeek: 6,
      restDays: const [1],
      strengthDays: const [],
      hoursPerWeek: 8,
      gadSports: const ['running'],
    );
    final s =
        (await (db.select(db.trainingSessions)
                  ..where((t) => t.title.equals('Hill Racer Training'))
                  ..limit(1))
                .get())
            .first;
    final text = (await service.workoutText(s.id)).text;
    expect(
      text,
      contains(
        'Race goal: 3:30:00 for 42.2 km (4:59/km, 4:56/km on the flat).',
      ),
    );
    expect(text, contains('Pace guide: '));
    expect(text, contains('estimated from your goal'));
    expect(text, contains('Heart rate decides.'));
    expect(text, contains('Z2 · 110–127 bpm'));
    // The same text goes to Garmin as the workout comment.
    await service.pushToGarmin(s.id);
    expect(garmin.lastDescription, text);
    final shared = await service.workoutText(s.id);
    expect(shared.title, 'Hill Racer Training');
    expect(shared.date, s.sessionDate);
  });

  test('a session planned with watts before goes up as heart rate', () async {
    // Steps already resolved to watts (as an earlier plan stored them).
    final garmin = FakeWorkoutGarmin();
    final service = TrainingPlanService(db, garmin);
    final s = await generate(service);
    final old = jsonEncode([
      {
        ...powerStep('interval', 900, 0.7)..remove('ftpFraction'),
        'targetValueOne': 176,
        'targetValueTwo': 194,
      },
    ]);
    await (db.update(db.trainingSessions)..where((t) => t.id.equals(s.id)))
        .write(TrainingSessionsCompanion(stepsJson: Value(old)));
    await service.pushToGarmin(s.id);
    final step = flat(garmin.lastSteps).single;
    // 185 W of 264 W is 70 %: zone 2.
    expect(step['zoneNumber'], 2);
    expect(step['targetType']['workoutTargetTypeKey'], 'heart.rate.zone');
    expect([step['targetValueOne'], step['targetValueTwo']], [110, 127]);
  });

  test('a share of FTP maps to the usual zones', () {
    expect(zoneForFtpFraction(0.5), 1);
    expect(zoneForFtpFraction(0.55), 1);
    expect(zoneForFtpFraction(0.7), 2);
    expect(zoneForFtpFraction(0.85), 3);
    expect(zoneForFtpFraction(0.95), 4);
    expect(zoneForFtpFraction(1.1), 5);
  });
}
