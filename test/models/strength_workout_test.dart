import 'package:fjelia/models/strength_workout.dart';
import 'package:fjelia/services/strength/strength_statistics.dart';
import 'package:flutter_test/flutter_test.dart';

StrengthPlannedExercise _ex(
  String id,
  List<StrengthSetTarget> sets, {
  StrengthConvention convention = const StrengthConvention(),
}) => StrengthPlannedExercise(
  id: id,
  variantId: id,
  name: id,
  equipment: 'Barbell',
  convention: convention,
  sets: sets,
);

List<StrengthSetTarget> _sets(
  String id,
  int n, {
  int? reps,
  double? kg,
  int? seconds,
}) => [
  for (var i = 0; i < n; i++)
    StrengthSetTarget(
      id: '$id-$i',
      reps: reps,
      durationSeconds: seconds,
      load: kg == null ? null : StrengthLoad(kg),
    ),
];

StrengthWorkoutPlan _plan(List<StrengthPlannedExercise> e) =>
    StrengthWorkoutPlan(
      blocks: [
        for (final x in e) StrengthBlock(id: '${x.id}-b', exercises: [x]),
      ],
    );

const _bw = StrengthConvention(loadKind: StrengthLoadKind.bodyweight);

void main() {
  group('sport routing (STR-F01)', () {
    test('canonical and verified aliases are strength', () {
      for (final s in [
        'strength',
        'strength_training',
        'STRENGTH_TRAINING',
        'Strength Training',
        'Krafttraining',
        'traditional_strength_training',
      ]) {
        expect(isStrengthSport(s), isTrue, reason: s);
      }
    });
    test('broad matches are not', () {
      for (final s in [
        'strength_endurance',
        'cycling_road',
        'yoga',
        'hiit',
        'functional_fitness',
        'crossfit',
        'gym',
        null,
      ]) {
        expect(isStrengthSport(s), isFalse, reason: s);
      }
    });
  });

  group('arithmetic fixtures (STR-A26)', () {
    test('section 7.4 workout', () {
      final plan = _plan([
        _ex('bench', _sets('bench', 3, reps: 10, kg: 80)),
        _ex('squat', _sets('squat', 4, reps: 8, kg: 100)),
        _ex('curl', _sets('curl', 3, reps: 12, kg: 15)),
        _ex('plank', _sets('plank', 3, seconds: 60), convention: _bw),
      ]);
      final s = summarisePlan(plan);
      expect(s.exercises, 4);
      expect(s.workingSets, 13);
      expect(s.repsMin, 98);
      expect(s.repsMax, 98);
      expect(s.holdSeconds, 180);
      expect(s.volume.min, 6140);
      expect(s.volume.complete, isTrue);
    });

    test('pyramid stays individual sets', () {
      final plan = _plan([
        _ex('p', [
          const StrengthSetTarget(id: 'a', reps: 12, load: StrengthLoad(60)),
          const StrengthSetTarget(id: 'b', reps: 10, load: StrengthLoad(70)),
          const StrengthSetTarget(id: 'c', reps: 8, load: StrengthLoad(80)),
        ]),
      ]);
      final s = summarisePlan(plan);
      expect(s.repsMin, 30);
      expect(s.volume.min, 2060);
      expect(s.maxLoadKg['p'], 80);
      expect(
        loadPatternText(
          plan.exercises.single.sets.map((s) => s.load),
          MassUnit.kg,
        ),
        '60 → 70 → 80 kg',
      );
    });
  });

  test('plank 3 × 60 s is 180 s of holds, not 180 reps (STR-A06)', () {
    final log = StrengthActivityLog(
      activityId: 'a',
      exercises: [
        StrengthPerformedExercise(
          id: 'p',
          variantId: 'plank',
          name: 'Plank',
          equipment: 'Bodyweight',
          convention: _bw,
          sets: [
            for (var i = 0; i < 3; i++)
              StrengthSetResult(
                id: 's$i',
                status: StrengthSetStatus.completed,
                durationSeconds: 60,
              ),
          ],
        ),
      ],
    );
    final s = summariseLog(log);
    expect(s.holdSeconds, 180);
    expect(s.reps, 0);
    expect(s.completedSets, 3);
    expect(s.volume.any, isFalse);
  });

  test('warm-ups are excluded from primary totals (STR-A04)', () {
    final plan = _plan([
      _ex('sq', [
        const StrengthSetTarget(
          id: 'w',
          kind: StrengthSetKind.warmup,
          reps: 5,
          load: StrengthLoad(40),
        ),
        const StrengthSetTarget(id: 'a', reps: 5, load: StrengthLoad(100)),
        const StrengthSetTarget(
          id: 'b',
          kind: StrengthSetKind.backoff,
          reps: 8,
          load: StrengthLoad(80),
        ),
      ]),
    ]);
    final s = summarisePlan(plan);
    expect(s.workingSets, 2);
    expect(s.warmupSets, 1);
    expect(s.volume.min, 500 + 640);
    expect(summarisePlan(plan, includeWarmups: true).volume.min, 200 + 1140);
  });

  test('bodyweight, assisted and band create no tonnage (STR-A05)', () {
    StrengthPerformedExercise e(
      String id,
      StrengthConvention c, {
      double? kg,
      String? band,
    }) => StrengthPerformedExercise(
      id: id,
      variantId: id,
      name: id,
      equipment: '',
      convention: c,
      sets: [
        StrengthSetResult(
          id: '$id-s',
          status: StrengthSetStatus.completed,
          reps: 10,
          load: kg == null ? null : StrengthLoad(kg),
          resistance: band,
        ),
      ],
    );
    final log = StrengthActivityLog(
      activityId: 'a',
      exercises: [
        e('pushup', _bw),
        e(
          'assisted',
          const StrengthConvention(loadKind: StrengthLoadKind.assisted),
          kg: 20,
        ),
        e(
          'band',
          const StrengthConvention(loadKind: StrengthLoadKind.band),
          band: 'Red',
        ),
        e(
          'weighted',
          const StrengthConvention(loadKind: StrengthLoadKind.added),
          kg: 10,
        ),
      ],
    );
    final s = summariseLog(log);
    expect(s.volume.min, 100, reason: 'only added external load counts');
    expect(s.reps, 40);
    expect(
      StrengthSetTarget(
        id: 'x',
        reps: 5,
        load: const StrengthLoad(5),
      ).validate(_bw),
      contains('Bodyweight has no kg load.'),
    );
  });

  test('partial and unknown values stay partial (STR-A11, STR-A28)', () {
    final log = StrengthActivityLog(
      activityId: 'a',
      exercises: [
        StrengthPerformedExercise(
          id: 'b',
          variantId: 'bench',
          name: 'Bench',
          equipment: 'Barbell',
          sets: const [
            StrengthSetResult(
              id: '1',
              status: StrengthSetStatus.completed,
              reps: 10,
              load: StrengthLoad(80),
            ),
            StrengthSetResult(
              id: '2',
              status: StrengthSetStatus.completed,
              reps: 10,
            ),
            StrengthSetResult(
              id: '3',
              status: StrengthSetStatus.failed,
              reps: 0,
              load: StrengthLoad(80),
            ),
            StrengthSetResult(
              id: '4',
              status: StrengthSetStatus.partial,
              reps: 6,
              load: StrengthLoad(80),
            ),
            StrengthSetResult(id: '5'),
          ],
        ),
      ],
    );
    final s = summariseLog(log);
    expect(s.completedSets, 2);
    expect(s.failedSets, 1);
    expect(s.partialSets, 1);
    expect(s.unrecordedSets, 1);
    expect(s.reps, 26);
    expect(s.volume.min, 800 + 0 + 480);
    expect(s.volume.known, 3);
    expect(s.volume.of, 4);
    expect(s.volume.complete, isFalse);
    expect(
      summariseLog(const StrengthActivityLog(activityId: 'x')).exercises,
      isNull,
    );
  });

  test(
    'paired dumbbells and per-side reps use the explicit basis (STR-A13)',
    () {
      final plan = _plan([
        _ex(
          'db',
          _sets('db', 1, reps: 10, kg: 20),
          convention: const StrengthConvention(
            basis: StrengthLoadBasis.perImplement,
            implements: 2,
          ),
        ),
        _ex(
          'row',
          _sets('row', 1, reps: 10, kg: 30),
          convention: const StrengthConvention(
            basis: StrengthLoadBasis.single,
            side: StrengthSide.unilateral,
          ),
        ),
      ]);
      expect(summarisePlan(plan).volume.min, 400 + 600);
      expect(
        plan.exercises.first.contextKey == plan.exercises.last.contextKey,
        isFalse,
      );
    },
  );

  test('kg ↔ lb round trips keep the physical load (STR-A12)', () {
    final load = StrengthLoad.entered(225, MassUnit.lb);
    expect(load.kg, closeTo(102.0582, 1e-4));
    expect(load.unit, MassUnit.lb);
    var kg = load.kg;
    for (var i = 0; i < 50; i++) {
      kg = lbToKg(kgToLb(kg));
    }
    expect(kg, closeTo(load.kg, 1e-9));
    expect(formatStrengthLoad(load.kg, MassUnit.lb), '225 lb');
    expect(formatStrengthLoad(load.kg, MassUnit.kg), '102.1 kg');
    final back = StrengthLoad.fromJson(load.toJson())!;
    expect(back, load);
  });

  group('validation', () {
    const c = StrengthConvention();
    test('rejects inverted ranges, negatives, mixed modes and NaN', () {
      expect(
        const StrengthSetTarget(id: 'a', repMin: 10, repMax: 8).validate(c),
        contains('The rep range is inverted.'),
      );
      expect(
        const StrengthSetTarget(id: 'a', reps: -1).validate(c),
        isNotEmpty,
      );
      expect(
        const StrengthSetTarget(
          id: 'a',
          reps: 5,
          durationSeconds: 30,
        ).validate(c),
        contains('Choose repetitions or timed work, not both.'),
      );
      expect(
        const StrengthSetTarget(
          id: 'a',
          reps: 5,
          load: StrengthLoad(double.nan),
        ).validate(c),
        isNotEmpty,
      );
      expect(const StrengthSetTarget(id: 'a').validate(c), isNotEmpty);
      expect(
        const StrengthSetTarget(id: 'a', reps: 5, tempo: '3-0-1').validate(c),
        isNotEmpty,
      );
      expect(
        const StrengthSetTarget(
          id: 'a',
          reps: 5,
          effort: StrengthEffort(StrengthEffortScale.rpe, 11),
        ).validate(c),
        isNotEmpty,
      );
    });

    test('duplicate ids and future schemas are rejected', () {
      final plan = _plan([
        _ex('a', _sets('x', 1, reps: 5)),
        _ex('b', _sets('x', 1, reps: 5)),
      ]);
      expect(plan.validate(), contains('Duplicate id x-0.'));
      expect(
        () => StrengthWorkoutPlan.fromJson({'schemaVersion': 99, 'blocks': []}),
        throwsFormatException,
      );
      expect(
        () => StrengthWorkoutPlan.fromJson({
          'blocks': [
            {'id': 'b', 'exercises': 'nope'},
          ],
        }),
        throwsFormatException,
      );
    });

    test('finishing with unrecorded sets needs acknowledgement', () {
      final log = StrengthActivityLog(
        activityId: 'a',
        status: StrengthLogStatus.finished,
        exercises: [
          StrengthPerformedExercise(
            id: 'e',
            variantId: 'v',
            name: 'Squat',
            equipment: '',
            sets: const [StrengthSetResult(id: 's')],
          ),
        ],
      );
      expect(log.validate(), isNotEmpty);
      expect(log.copyWith(incompleteAcknowledged: true).validate(), isEmpty);
      expect(
        log.copyWith(incompleteAcknowledged: true).sets.single.status,
        StrengthSetStatus.unrecorded,
        reason: 'finishing never completes remaining sets',
      );
    });
  });

  test('plan JSON round trip keeps ids, groups and values (STR-A03, A07)', () {
    final plan = StrengthWorkoutPlan(
      title: 'Upper',
      blocks: [
        StrengthBlock(
          id: 'g',
          kind: StrengthBlockKind.superset,
          restBetweenExercisesSeconds: 0,
          restBetweenRoundsSeconds: 90,
          exercises: [
            _ex('a', [
              const StrengthSetTarget(
                id: 'a1',
                repMin: 8,
                repMax: 10,
                load: StrengthLoad(70, unit: MassUnit.lb),
                restSeconds: 60,
                tempo: '3-0-1-0',
                effort: StrengthEffort(StrengthEffortScale.rir, 2),
              ),
            ]),
            _ex('b', _sets('b', 1, seconds: 45), convention: _bw),
          ],
        ),
      ],
    );
    final back = StrengthWorkoutPlan.fromJson(plan.toJson());
    expect(back.toJson(), plan.toJson());
    expect(back.blocks.single.rounds, 1);
    expect(back.exercises.first.sets.single.isRange, isTrue);
  });

  test('superset rests are not double counted; no trailing rest', () {
    final plan = StrengthWorkoutPlan(
      blocks: [
        StrengthBlock(
          id: 'g',
          kind: StrengthBlockKind.superset,
          restBetweenExercisesSeconds: 10,
          restBetweenRoundsSeconds: 60,
          exercises: [
            _ex('a', [
              for (var i = 0; i < 2; i++)
                StrengthSetTarget(
                  id: 'a$i',
                  durationSeconds: 30,
                  restSeconds: 999,
                ),
            ], convention: _bw),
            _ex('b', [
              for (var i = 0; i < 2; i++)
                StrengthSetTarget(
                  id: 'b$i',
                  durationSeconds: 30,
                  restSeconds: 999,
                ),
            ], convention: _bw),
          ],
        ),
      ],
    );
    final d = estimatePlanDuration(plan)!;
    // 4 × 30 s work, 2 × 10 s between exercises, one 60 s round rest.
    expect(d.minSeconds, 120 + 20 + 60);
    expect(d.maxSeconds, d.minSeconds);
  });

  group('logging from a plan (STR-A19)', () {
    const c = StrengthConvention();
    test('layout carries no actual values', () {
      final plan = _plan([_ex('a', _sets('a', 3, reps: 10, kg: 80))]);
      final layout = logLayoutFromPlan(plan);
      expect(layout.single.plannedExerciseId, 'a');
      expect(layout.single.sets.map((s) => s.status).toSet(), {
        StrengthSetStatus.unrecorded,
      });
      expect(
        layout.single.sets.every((s) => s.reps == null && s.load == null),
        isTrue,
      );
    });

    test('ranges and unknown loads need actual values', () {
      expect(
        completeAsPlannedBlocker(
          const StrengthSetTarget(
            id: 'a',
            repMin: 8,
            repMax: 10,
            load: StrengthLoad(70),
          ),
          c,
        ),
        isNotNull,
      );
      expect(
        completeAsPlannedBlocker(const StrengthSetTarget(id: 'a', reps: 8), c),
        isNotNull,
      );
    });

    test('exact targets copy without rest', () {
      const target = StrengthSetTarget(
        id: 't',
        reps: 10,
        load: StrengthLoad(80),
        restSeconds: 120,
      );
      final done = completedAsPlanned(
        const StrengthSetResult(id: 'r', plannedSetId: 't'),
        target,
        c,
      );
      expect(done.status, StrengthSetStatus.completed);
      expect(done.reps, 10);
      expect(done.load?.kg, 80);
      expect(done.restSeconds, isNull);
      expect(done.origins['reps'], StrengthOrigin.plan);
    });
  });

  test('comparison maps by planned ids, never by position (STR-A08, A27)', () {
    final plan = _plan([
      _ex('a', _sets('a', 2, reps: 10, kg: 80)),
      _ex('b', _sets('b', 1, reps: 5, kg: 100)),
    ]);
    final log = StrengthActivityLog(
      activityId: 'x',
      baseline: StrengthPlanBaseline(
        ownerKind: 'session',
        ownerKey: 's',
        revisionId: 'r',
        plan: plan,
      ),
      exercises: [
        // Done in a different order, with an extra set and an extra exercise.
        StrengthPerformedExercise(
          id: 'pb',
          variantId: 'b',
          name: 'b',
          equipment: '',
          plannedExerciseId: 'b',
          sets: const [
            StrengthSetResult(
              id: 'r1',
              plannedSetId: 'b-0',
              status: StrengthSetStatus.completed,
              reps: 4,
              load: StrengthLoad(100),
            ),
            StrengthSetResult(
              id: 'r2',
              status: StrengthSetStatus.completed,
              reps: 5,
              load: StrengthLoad(90),
            ),
          ],
        ),
        StrengthPerformedExercise(
          id: 'pa',
          variantId: 'a',
          name: 'a',
          equipment: '',
          plannedExerciseId: 'a',
          sets: const [
            StrengthSetResult(
              id: 'r3',
              plannedSetId: 'a-1',
              status: StrengthSetStatus.skipped,
            ),
          ],
        ),
        StrengthPerformedExercise(
          id: 'pc',
          variantId: 'c',
          name: 'c',
          equipment: '',
        ),
      ],
    );
    final cmp = compareWithBaseline(log);
    expect(cmp.length, 3);
    final a = cmp[0], b = cmp[1];
    expect(a.sets.map((s) => s.match), [
      StrengthMatch.missing,
      StrengthMatch.linked,
    ]);
    expect(a.sets[1].result!.status, StrengthSetStatus.skipped);
    expect(b.sets.map((s) => s.match), [
      StrengthMatch.linked,
      StrengthMatch.added,
    ]);
    expect(b.sets.first.repDelta, -1);
    expect(cmp[2].added, isTrue);
  });
}
