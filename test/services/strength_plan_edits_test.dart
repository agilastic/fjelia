import 'package:fjelia/models/strength_workout.dart';
import 'package:fjelia/services/strength/strength_plan_edits.dart';
import 'package:fjelia/services/strength/strength_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final plan = bundledStrengthTemplates.first.build();
  final squat = plan.exercises.first.id;
  Set<String> ids(StrengthWorkoutPlan p) => {
    for (final b in p.blocks) b.id,
    for (final e in p.exercises) e.id,
    for (final e in p.exercises)
      for (final s in e.sets) s.id,
  };

  test('reordering keeps ids; duplicating makes new ones (STR-A14)', () {
    final moved = plan.moveExercise(squat, 1);
    expect(moved.exercises.elementAt(1).id, squat);
    expect(ids(moved), ids(plan));
    expect(plan.moveExercise(squat, -1), same(plan), reason: 'already first');

    final dup = plan.duplicateExercise(squat);
    expect(dup.exercises.length, plan.exercises.length + 1);
    final copy = dup.exercises.elementAt(1);
    expect(copy.variantId, 'back_squat');
    expect(ids(dup).length, ids(plan).length + 2 + copy.sets.length);
    expect(dup.validate(), isEmpty);
  });

  test('grouping and ungrouping keep every value (STR-A07)', () {
    final grouped = plan.groupWithNext(squat, StrengthBlockKind.superset);
    expect(grouped.blocks.length, plan.blocks.length - 1);
    final g = grouped.blocks.first;
    expect(g.kind, StrengthBlockKind.superset);
    expect(g.rounds, 3);
    expect(grouped.validate(), isEmpty);
    final back = grouped.ungroup(g.id);
    expect(back.blocks.length, plan.blocks.length);
    expect(
      back.exercises.map((e) => e.toJson()).toList(),
      plan.exercises.map((e) => e.toJson()).toList(),
    );
  });

  test('removing the last but one exercise of a group makes it straight', () {
    final grouped = plan.groupWithNext(squat, StrengthBlockKind.circuit);
    final other = grouped.blocks.first.exercises.last.id;
    final left = grouped.removeExercise(other);
    expect(left.blocks.first.kind, StrengthBlockKind.straight);
    expect(left.validate(), isEmpty);
  });

  test('apply to working sets leaves warm-ups and ids alone', () {
    final withWarmup = plan.updateExercise(
      squat,
      (e) => e.copyWith(
        sets: [
          const StrengthSetTarget(
            id: 'w',
            kind: StrengthSetKind.warmup,
            reps: 5,
            load: StrengthLoad(40),
          ),
          ...e.sets,
        ],
      ),
    );
    final applied = withWarmup.applyToWorkingSets(
      squat,
      const StrengthSetTarget(
        id: 'x',
        reps: 6,
        load: StrengthLoad(90),
        restSeconds: 180,
      ),
    );
    final sets = applied.exercises.first.sets;
    expect(sets.first.load?.kg, 40);
    expect(sets.skip(1).every((s) => s.reps == 6 && s.load?.kg == 90), isTrue);
    expect(sets.skip(1).every((s) => s.repMin == null), isTrue);
    expect(
      sets.map((s) => s.id).skip(1),
      plan.exercises.first.sets.map((s) => s.id),
    );
  });

  test('shared text lists exercises, sets and loads', () {
    final text = strengthPlanText(plan, MassUnit.kg);
    expect(text, contains('1. Back squat (Barbell)'));
    expect(text, contains('Set 1: 8–10 reps · rest 2:00 · RIR 2'));
  });
}
