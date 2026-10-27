import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/api/garmin_client.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/strength_workout.dart';
import 'package:fjelia/services/strength/garmin_strength.dart';
import 'package:fjelia/services/strength/strength_repository.dart';
import 'package:fjelia/services/strength/strength_templates.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_providers/garmin_workout_provider.dart';
import 'package:fjelia/services/workout_providers/workout_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';
import '../support/recording_workout_provider.dart';

/// A sanitised, hand-written `exerciseSets` response in Garmin's shape: no
/// real account, activity or athlete data.
const _fixture = {
  'activityId': 1,
  'exerciseSets': [
    {
      'setType': 'ACTIVE',
      'messageIndex': 0,
      'repetitionCount': 10,
      'weight': 70000.0,
      'duration': 32.5,
      'exercises': [
        {
          'category': 'BENCH_PRESS',
          'name': 'BARBELL_BENCH_PRESS',
          'probability': 98,
        },
      ],
    },
    {'setType': 'REST', 'messageIndex': 1, 'duration': 121.4},
    {
      'setType': 'ACTIVE',
      'messageIndex': 2,
      'repetitionCount': 9,
      'weight': 70000.0,
      'exercises': [
        {'category': 'BENCH_PRESS', 'name': 'BARBELL_BENCH_PRESS'},
      ],
    },
    {'setType': 'REST', 'messageIndex': 3, 'duration': 90.0},
    {
      'setType': 'ACTIVE',
      'messageIndex': 4,
      'repetitionCount': 12,
      'weight': 0.0,
      'exercises': [
        {'category': 'UNKNOWN', 'name': null},
      ],
    },
    {
      'setType': 'ACTIVE',
      'messageIndex': 5,
      'duration': 60.0,
      'weight': 0.0,
      'exercises': [
        {'category': 'PLANK', 'name': 'PLANK'},
      ],
    },
    {'setType': 'REST', 'messageIndex': 6, 'duration': 15.0},
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final full = bundledStrengthTemplates.first.build();
  final core = bundledStrengthTemplates.last.build();

  group('upload payload (STR-A32)', () {
    test('one step per set, rests between, none after the last set', () {
      final p = garminStrengthPayload(full);
      final kinds = p.steps.map((s) => (s['stepType'] as Map)['stepTypeKey']);
      expect(kinds.where((k) => k == 'interval').length, 12);
      expect(kinds.where((k) => k == 'rest').length, 11);
      expect(kinds.last, 'interval');
      expect(p.steps.map((s) => s['stepOrder']), [
        for (var i = 1; i <= 23; i++) i,
      ]);
      final first = p.steps.first;
      expect(first['category'], 'SQUAT');
      expect(first['exerciseName'], 'BARBELL_BACK_SQUAT');
      // A range is not turned into one number: the set ends on the lap button.
      expect((first['endCondition'] as Map)['conditionTypeKey'], 'lap.button');
      expect(first.containsKey('endConditionValue'), isFalse);
      expect(first['description'], contains('8–10 reps'));
      expect(first.containsKey('weightValue'), isFalse, reason: 'no load set');
      expect(
        p.omitted,
        containsAll([
          'effort targets',
          'rep ranges (the set ends on the lap button)',
          'tempo',
        ]),
      );
    });

    test('exact reps and loads go up as such; pyramids stay exact', () {
      final plan = StrengthWorkoutPlan(
        blocks: [
          StrengthBlock(
            id: 'b',
            exercises: [
              StrengthPlannedExercise(
                id: 'e',
                variantId: 'bench_press',
                name: 'Bench press',
                equipment: 'Barbell',
                sets: [
                  for (final (reps, kg) in [(12, 60.0), (10, 70.0), (8, 80.0)])
                    StrengthSetTarget(
                      id: 's$reps',
                      reps: reps,
                      load: StrengthLoad(kg),
                      restSeconds: 120,
                    ),
                ],
              ),
            ],
          ),
        ],
      );
      final p = garminStrengthPayload(plan);
      final sets = p.steps.where((s) => s['exerciseName'] != null).toList();
      expect(sets.map((s) => s['endConditionValue']), [12, 10, 8]);
      expect(sets.map((s) => s['weightValue']), [60.0, 70.0, 80.0]);
      expect((sets.first['weightUnit'] as Map)['unitKey'], 'kilogram');
      expect(p.omitted, isEmpty);
    });

    test('a circuit goes round by round with its own rests', () {
      final p = garminStrengthPayload(core);
      final names = [
        for (final s in p.steps)
          if ((s['stepType'] as Map)['stepTypeKey'] != 'rest')
            (s['description'] as String).split(' · ').first,
      ];
      expect(names.take(5), [
        'Plank',
        'Dead bug',
        'Bird dog',
        'Pallof press',
        'Plank',
      ]);
      expect(names.length, 12);
      final rests = [
        for (final s in p.steps)
          if ((s['stepType'] as Map)['stepTypeKey'] == 'rest')
            s['endConditionValue'],
      ];
      // 3 between exercises per round, 60 s between rounds, none at the end.
      expect(rests, [15, 15, 15, 60, 15, 15, 15, 60, 15, 15, 15]);
      expect(
        (p.steps.first['endCondition'] as Map)['conditionTypeKey'],
        'time',
      );
      expect(p.omitted, contains('exercise names Garmin does not know'));
    });

    test('names can be stripped for a retry', () {
      final steps = withoutGarminExerciseNames(
        garminStrengthPayload(full).steps,
      );
      expect(hasGarminExerciseNames(steps), isFalse);
      expect(steps.first['description'], startsWith('Back squat'));
    });
  });

  group('recorded sets (STR-A23)', () {
    final ex = parseGarminExerciseSets('42', _fixture);

    test('exercises, grams, rests and unknowns', () {
      expect(ex.map((e) => e.name), [
        'Bench press',
        'Unidentified exercise',
        'Plank',
      ]);
      final bench = ex.first;
      expect(bench.variantId, 'bench_press');
      expect(bench.sets.map((s) => s.reps), [10, 9]);
      expect(bench.sets.map((s) => s.load?.kg), [70, 70]);
      expect(bench.sets.first.restSeconds, 121);
      expect(bench.sets.first.restOrigin, StrengthOrigin.imported);
      expect(bench.sets.first.origins['reps'], StrengthOrigin.imported);
      final unknown = ex[1].sets.single;
      expect(unknown.load, isNull, reason: 'weight 0 is unknown, not 0 kg');
      final plank = ex[2].sets.single;
      expect(plank.durationSeconds, 60);
      expect(plank.reps, isNull);
      expect(plank.restSeconds, 15);
    });

    test('ids are stable across imports', () {
      final again = parseGarminExerciseSets('42', _fixture);
      expect(
        again.expand((e) => e.sets).map((s) => s.id),
        ex.expand((e) => e.sets).map((s) => s.id),
      );
    });

    test('dumbbell loads keep their own context, never doubled', () {
      final db = parseGarminExerciseSets('9', {
        'exerciseSets': [
          {
            'setType': 'ACTIVE',
            'repetitionCount': 10,
            'weight': 20000,
            'exercises': [
              {'category': 'BENCH_PRESS', 'name': 'DUMBBELL_BENCH_PRESS'},
            ],
          },
        ],
      }).single;
      expect(db.convention.basis, StrengthLoadBasis.single);
      expect(db.sets.single.load?.kg, 20);
      expect(
        db.contextKey,
        isNot(builtInStrengthVariant('db_bench_press')!.convention.key),
      );
    });

    test('nothing usable yields nothing', () {
      expect(parseGarminExerciseSets('1', null), isEmpty);
      expect(parseGarminExerciseSets('1', {'exerciseSets': []}), isEmpty);
    });

    test('merge is idempotent and keeps the athlete\'s corrections', () {
      final first = mergeGarminImport(null, '42', ex)!;
      expect(mergeGarminImport(first, '42', ex), isNull, reason: 'repeat sync');
      // The athlete corrects reps of set 2 and adds a set of their own.
      final corrected = first.copyWith(
        exercises: [
          first.exercises.first.copyWith(
            sets: [
              first.exercises.first.sets.first,
              first.exercises.first.sets[1].copyWith(
                reps: () => 8,
                origins: {'reps': StrengthOrigin.manual},
              ),
              const StrengthSetResult(
                id: 'mine',
                status: StrengthSetStatus.completed,
                reps: 5,
              ),
            ],
          ),
          ...first.exercises.skip(1),
        ],
      );
      expect(mergeGarminImport(corrected, '42', ex), isNull);
      // Garmin later changes its count for both sets.
      final updated = parseGarminExerciseSets('42', {
        'exerciseSets': [
          for (final row in _fixture['exerciseSets']! as List)
            (row as Map)['messageIndex'] == 0 || row['messageIndex'] == 2
                ? {...row, 'repetitionCount': 11}
                : row,
        ],
      });
      final merged = mergeGarminImport(corrected, '42', updated)!;
      final sets = merged.exercises.first.sets;
      expect(sets[0].reps, 11, reason: 'imported value updated');
      expect(sets[1].reps, 8, reason: 'correction kept');
      expect(sets[2].id, 'mine', reason: 'own set kept');
    });

    test('a log the athlete wrote is left alone', () {
      final own = StrengthActivityLog(
        activityId: '42',
        exercises: [
          StrengthPerformedExercise(
            id: 'pe',
            variantId: 'bench_press',
            name: 'Bench press',
            equipment: 'Barbell',
            sets: const [StrengthSetResult(id: 'x')],
          ),
        ],
      );
      expect(mergeGarminImport(own, '42', ex), isNull);
    });
  });

  group('delivery', () {
    late AppDatabase db;
    late FakeWorkoutGarmin garmin;
    late RecordingProvider other;
    late TrainingPlanService service;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      garmin = FakeWorkoutGarmin();
      other = RecordingProvider(db, 'acme');
      final repo = StrengthRepository(db);
      service = TrainingPlanService(
        db,
        WorkoutProviders([
          GarminWorkoutProvider(
            db,
            garmin,
            strengthRevision: (s) async =>
                (await repo.sessionPlan(s))?.revision,
          ),
          other,
        ]),
      );
      await db
          .into(db.trainingPlans)
          .insert(
            TrainingPlansCompanion.insert(
              id: 'p',
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
              id: 's',
              planId: 'p',
              athleteId: 'self',
              sessionDate: DateTime(2026, 11, 3),
              sessionNumber: 1,
              weekNumber: 1,
              sport: 'strength',
              sessionType: 'key',
              subType: const Value('strengthFull'),
              phase: 'base',
              primaryZone: 3,
              title: 'Full Body Strength — Base',
              sessionNotes: Value(
                bundledStrengthTemplates.first.legacyDescription,
              ),
              stepsJson: const Value('[]'),
              plannedDurationMin: 55,
              plannedTrimp: 50,
              sessionLevel: 2,
            ),
          );
    });
    tearDown(() => db.close());

    test('Garmin gets exercises, not a timed outline', () async {
      await service.pushToGarmin('s');
      expect(garmin.creates, 1);
      expect(garmin.lastSteps.first['exerciseName'], 'BARBELL_BACK_SQUAT');
      expect(garmin.lastSteps.any((s) => s['zoneNumber'] != null), isFalse);
      expect(garmin.lastDescription, contains('1. Back squat (Barbell)'));
      expect(await service.strengthUploadOmissions('s'), contains('tempo'));
    });

    test(
      'editing exercises sends again; no edit only reschedules (#1)',
      () async {
        await service.pushToGarmin('s');
        await service.pushToGarmin('s');
        expect(garmin.creates, 1, reason: 'unchanged: rescheduled');
        final repo = StrengthRepository(db);
        final s = await (db.select(
          db.trainingSessions,
        )..where((t) => t.id.equals('s'))).getSingle();
        final plan = (await repo.sessionPlan(s))!.plan;
        await repo.savePlan(
          StrengthPlanOwner.session('s'),
          plan.copyWith(notes: () => 'Heavier today'),
          expectedRevision: 0,
        );
        await service.pushToGarmin('s');
        expect(garmin.creates, 2, reason: 'new plan revision');
      },
    );

    test('other platforms are not sent strength at all', () async {
      await expectLater(
        service.deliver('s', other),
        throwsA(isA<WorkoutNotSupported>()),
      );
      expect(other.delivered, isEmpty);
      // Plan-wide auto delivery skips it the same way.
      await service.deliverPlan('self', to: [other]);
      expect(other.delivered, isEmpty);
      // Sharing gives the exercise list.
      expect(
        (await service.workoutText('s')).text,
        contains('Set 1: 8–10 reps'),
      );
    });

    test('a refused exercise name is retried without names', () async {
      final strict = _NameRefusingGarmin();
      final svc = TrainingPlanService(
        db,
        WorkoutProviders([GarminWorkoutProvider(db, strict)]),
      );
      await svc.pushToGarmin('s');
      expect(strict.attempts, 2);
      expect(hasGarminExerciseNames(strict.lastSteps), isFalse);
    });
  });
}

class _NameRefusingGarmin extends FakeWorkoutGarmin {
  int attempts = 0;
  @override
  Future<String> createWorkout(
    String name,
    String sport,
    List<Map<String, dynamic>> steps, {
    String? description,
  }) async {
    attempts++;
    if (hasGarminExerciseNames(steps)) {
      throw GarminApiException('createWorkout failed 400: invalid exercise');
    }
    return super.createWorkout(name, sport, steps, description: description);
  }
}
