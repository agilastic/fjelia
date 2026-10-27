import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/strength_workout.dart';
import 'package:fjelia/services/strength/strength_progression.dart';
import 'package:fjelia/services/strength/strength_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _rir2 = StrengthEffort(StrengthEffortScale.rir, 2);

StrengthPlannedExercise _bench({double? kg, StrengthEffort? effort = _rir2}) =>
    StrengthPlannedExercise(
      id: 'bench',
      variantId: 'bench_press',
      name: 'Bench press',
      equipment: 'Barbell',
      sets: [
        for (var i = 0; i < 3; i++)
          StrengthSetTarget(
            id: 'b$i',
            repMin: 8,
            repMax: 10,
            load: kg == null ? null : StrengthLoad(kg),
            effort: effort,
          ),
      ],
    );

StrengthBlock _block(StrengthPlannedExercise e) =>
    StrengthBlock(id: 'blk', exercises: [e]);

StrengthHistoryEntry _session(
  String id,
  DateTime date, {
  List<int> reps = const [10, 10, 10],
  double kg = 70,
  StrengthEffort? effort = const StrengthEffort(StrengthEffortScale.rir, 2),
  StrengthSetStatus status = StrengthSetStatus.completed,
  bool stale = false,
  int revision = 1,
}) => StrengthHistoryEntry(
  activityId: id,
  date: date,
  source: null,
  stale: stale,
  logRevision: revision,
  sets: [
    for (var i = 0; i < reps.length; i++)
      StrengthSetResult(
        id: '$id-$i',
        status: i == reps.length - 1 ? status : StrengthSetStatus.completed,
        reps: reps[i],
        load: StrengthLoad(kg),
        effort: i == reps.length - 1 ? effort : null,
      ),
  ],
);

StrengthProgressionEvaluation _eval(
  List<StrengthHistoryEntry> recent, {
  StrengthPlannedExercise? exercise,
  StrengthLoad? step = const StrengthLoad(2.5),
  String? blocked,
}) {
  final e = exercise ?? _bench();
  return evaluateStrengthProgression(
    exercise: e,
    block: _block(e),
    recent: recent,
    increment: step,
    blockedReason: blocked,
  );
}

void main() {
  final d1 = DateTime(2026, 10, 20), d2 = DateTime(2026, 10, 23);
  final qualifying = [_session('a2', d2), _session('a1', d1)];

  test(
    'two qualifying sessions and a known step propose one increment (STR-A35)',
    () {
      final r = _eval(qualifying);
      expect(r.outcome, StrengthProgressionOutcome.propose);
      expect(r.currentLoad?.kg, 70);
      expect(r.proposedLoad?.kg, 72.5);
      expect(r.supporting.map((s) => s.activityId), ['a2', 'a1']);
      expect(r.fingerprint, contains('a2@1'));
      expect(r.fingerprint, startsWith('v$strengthProgressionRuleVersion|'));
    },
  );

  group('no proposal on insufficient evidence (STR-A34)', () {
    void none(StrengthProgressionEvaluation r, String why) {
      expect(r.outcome, StrengthProgressionOutcome.none, reason: why);
      expect(r.proposedLoad, isNull, reason: why);
    }

    test('one session', () => none(_eval([_session('a', d2)]), 'one session'));
    test('stale history', () {
      none(
        _eval([_session('a2', d2, stale: true), _session('a1', d1)]),
        'stale',
      );
    });
    test('upper reps not met', () {
      none(
        _eval([
          _session('a2', d2, reps: [10, 10, 9]),
          _session('a1', d1),
        ]),
        'reps',
      );
    });
    test('shortened session', () {
      none(
        _eval([
          _session('a2', d2, reps: [10, 10]),
          _session('a1', d1),
        ]),
        'sets',
      );
    });
    test('failed, partial or unrecorded set', () {
      for (final s in [
        StrengthSetStatus.failed,
        StrengthSetStatus.partial,
        StrengthSetStatus.unrecorded,
        StrengthSetStatus.skipped,
      ]) {
        none(_eval([_session('a2', d2, status: s), _session('a1', d1)]), '$s');
      }
    });
    test('no effort recorded', () {
      none(
        _eval([_session('a2', d2, effort: null), _session('a1', d1)]),
        'effort',
      );
    });
    test('harder than intended', () {
      none(
        _eval([
          _session(
            'a2',
            d2,
            effort: const StrengthEffort(StrengthEffortScale.rir, 0),
          ),
          _session('a1', d1),
        ]),
        'RIR 0 vs target 2',
      );
      none(
        _eval([
          _session(
            'a2',
            d2,
            effort: const StrengthEffort(StrengthEffortScale.rpe, 9.5),
          ),
          _session('a1', d1),
        ]),
        'RPE 9.5 is RIR 0.5 vs target 2',
      );
    });
    test('without a target effort, a set to failure does not qualify', () {
      none(
        _eval([
          _session(
            'a2',
            d2,
            effort: const StrengthEffort(StrengthEffortScale.rir, 0),
          ),
          _session('a1', d1),
        ], exercise: _bench(effort: null)),
        'RIR 0 without target',
      );
    });
    test('load changed between sessions', () {
      none(_eval([_session('a2', d2), _session('a1', d1, kg: 67.5)]), 'load');
    });
    test('workout already has a different load', () {
      none(_eval(qualifying, exercise: _bench(kg: 75)), 'own load wins');
    });
    test('unsupported: timed, bodyweight, assisted, grouped', () {
      final plank = StrengthPlannedExercise(
        id: 'p',
        variantId: 'plank',
        name: 'Plank',
        equipment: '',
        convention: const StrengthConvention(
          loadKind: StrengthLoadKind.bodyweight,
        ),
        sets: const [StrengthSetTarget(id: 'p0', durationSeconds: 60)],
      );
      none(_eval(qualifying, exercise: plank), 'timed');
      final assisted = _bench().copyWith(
        convention: const StrengthConvention(
          loadKind: StrengthLoadKind.assisted,
        ),
      );
      none(_eval(qualifying, exercise: assisted), 'assisted');
      final e = _bench();
      none(
        evaluateStrengthProgression(
          exercise: e,
          block: StrengthBlock(
            id: 'g',
            kind: StrengthBlockKind.superset,
            exercises: [e],
          ),
          recent: qualifying,
          increment: const StrengthLoad(2.5),
        ),
        'grouped',
      );
    });
  });

  test('a matching planned load still allows a proposal', () {
    expect(
      _eval(qualifying, exercise: _bench(kg: 70)).outcome,
      StrengthProgressionOutcome.propose,
    );
  });

  test('unknown increment asks for review, never invents one', () {
    final r = _eval(qualifying, step: null);
    expect(r.outcome, StrengthProgressionOutcome.needsIncrement);
    expect(r.proposedLoad, isNull);
    expect(r.fingerprint, isNull);
  });

  test('taper or recovery blocks the increase (STR-A36)', () {
    final r = _eval(qualifying, blocked: 'Taper phase');
    expect(r.outcome, StrengthProgressionOutcome.blocked);
    expect(r.proposedLoad, isNull);
    expect(r.reason, startsWith('Taper phase'));
  });

  test('a corrected log changes the fingerprint (STR-A36)', () {
    final before = _eval(qualifying).fingerprint;
    final after = _eval([_session('a2', d2, revision: 2), _session('a1', d1)])
        .fingerprint;
    expect(after, isNot(before));
  });

  test('apply sets the load on working sets only', () {
    final plan = StrengthWorkoutPlan(
      blocks: [
        _block(
          _bench().copyWith(
            sets: [
              const StrengthSetTarget(
                id: 'w',
                kind: StrengthSetKind.warmup,
                reps: 5,
                load: StrengthLoad(40),
              ),
              ..._bench().sets,
            ],
          ),
        ),
      ],
    );
    final next = applyProgression(plan, 'bench', const StrengthLoad(72.5));
    expect(next.exercises.single.sets.map((s) => s.load?.kg), [
      40,
      72.5,
      72.5,
      72.5,
    ]);
    expect(next.exercises.single.sets.map((s) => s.repsText).skip(1), [
      '8–10',
      '8–10',
      '8–10',
    ]);
  });

  group('repository', () {
    late AppDatabase db;
    late StrengthRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = StrengthRepository(db);
    });
    tearDown(() => db.close());

    Future<void> logged(
      String id,
      DateTime start,
      List<StrengthSetResult> sets,
    ) async {
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: id,
              name: 'Gym',
              type: 'strength_training',
              startDate: start,
              durationSeconds: 3600,
            ),
          );
      await repo.saveLog(
        StrengthActivityLog(
          activityId: id,
          exercises: [
            StrengthPerformedExercise(
              id: '$id-e',
              variantId: 'bench_press',
              name: 'Bench press',
              equipment: 'Barbell',
              sets: sets,
            ),
          ],
        ),
      );
    }

    test('recent sessions keep failed sets visible and newest first', () async {
      await logged('a1', d1, _session('a1', d1).sets);
      await logged(
        'a2',
        d2,
        _session('a2', d2, status: StrengthSetStatus.failed).sets,
      );
      final recent = await repo.recentComparableSessions(
        _bench().contextKey,
        before: DateTime(2026, 10, 27),
        now: DateTime(2026, 10, 27),
      );
      expect(recent.map((s) => s.activityId), ['a2', 'a1']);
      expect(recent.first.sets.last.status, StrengthSetStatus.failed);
      expect(recent.first.logRevision, 1);
      expect(_eval(recent).outcome, StrengthProgressionOutcome.none);
    });

    test(
      'accept saves a revision and the decision atomically; nothing before',
      () async {
        await logged('a1', d1, _session('a1', d1).sets);
        await logged('a2', d2, _session('a2', d2).sets);
        final owner = StrengthPlanOwner.session('next');
        final plan = StrengthWorkoutPlan(blocks: [_block(_bench())]);
        final recent = await repo.recentComparableSessions(
          _bench().contextKey,
          before: DateTime(2026, 10, 27),
          now: DateTime(2026, 10, 27),
        );
        final r = _eval(recent);
        expect(r.outcome, StrengthProgressionOutcome.propose);
        expect(
          await repo.loadPlan(owner),
          isNull,
          reason: 'evaluating saves nothing',
        );
        await repo.acceptProposal(
          owner: owner,
          plan: applyProgression(plan, 'bench', r.proposedLoad!),
          expectedRevision: 0,
          exerciseId: 'bench',
          fingerprint: r.fingerprint!,
          ruleVersion: strengthProgressionRuleVersion,
          fromKg: 70,
          toKg: 72.5,
        );
        final saved = (await repo.loadPlan(owner))!;
        expect(
          saved.plan.exercises.single.sets.every((s) => s.load?.kg == 72.5),
          isTrue,
        );
        expect(
          (await repo.proposalDecisions(owner))[r.fingerprint]!.decision,
          'accepted',
        );
        // The accepted load is now ahead of history: no further proposal.
        expect(
          _eval(recent, exercise: saved.plan.exercises.single).outcome,
          StrengthProgressionOutcome.none,
        );
        // Deleting a supporting activity does not undo the accepted target.
        await db.deleteActivityById('a2');
        expect(
          (await repo.loadPlan(owner))!
              .plan
              .exercises
              .single
              .sets
              .first
              .load
              ?.kg,
          72.5,
        );
      },
    );

    test('a stale editor cannot accept over a newer plan', () async {
      final owner = StrengthPlanOwner.session('next');
      final plan = StrengthWorkoutPlan(blocks: [_block(_bench())]);
      await repo.savePlan(owner, plan, expectedRevision: 0);
      await expectLater(
        repo.acceptProposal(
          owner: owner,
          plan: applyProgression(plan, 'bench', const StrengthLoad(72.5)),
          expectedRevision: 0,
          exerciseId: 'bench',
          fingerprint: 'f',
          ruleVersion: 1,
          fromKg: 70,
          toKg: 72.5,
        ),
        throwsA(isA<StrengthConflictException>()),
      );
      expect(
        await repo.proposalDecisions(owner),
        isEmpty,
        reason: 'rolled back',
      );
    });
  });
}
