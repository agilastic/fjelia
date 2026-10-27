import '../../models/strength_workout.dart';
import 'strength_repository.dart';

/// Pure plan edits for the editor. Reordering keeps ids; duplicating makes
/// new ones, so plan-versus-actual mapping never breaks.

StrengthSetTarget defaultSetFor(StrengthExerciseVariant v) => StrengthSetTarget(
  id: newStrengthId('set'),
  reps: v.timed ? null : 10,
  durationSeconds: v.timed ? 30 : null,
  restSeconds: 90,
);

extension StrengthPlanEdits on StrengthWorkoutPlan {
  StrengthWorkoutPlan _mapExercise(
    String id,
    StrengthPlannedExercise Function(StrengthPlannedExercise) f,
  ) => copyWith(
    blocks: [
      for (final b in blocks)
        b.copyWith(
          exercises: [for (final e in b.exercises) e.id == id ? f(e) : e],
        ),
    ],
  );

  /// Groups left with one exercise become straight sets again; empty ones go.
  StrengthWorkoutPlan _tidy(List<StrengthBlock> next) => copyWith(
    blocks: [
      for (final b in next)
        if (b.exercises.length == 1 && b.grouped)
          b.copyWith(kind: StrengthBlockKind.straight)
        else if (b.exercises.isNotEmpty)
          b,
    ],
  );

  StrengthWorkoutPlan addExercise(
    StrengthExerciseVariant v, {
    String? name,
    String? equipment,
  }) => copyWith(
    blocks: [
      ...blocks,
      StrengthBlock(
        id: newStrengthId('blk'),
        exercises: [
          StrengthPlannedExercise(
            id: newStrengthId('ex'),
            variantId: v.id,
            name: name ?? v.name,
            equipment: equipment ?? v.equipment,
            convention: v.convention,
            notes: v.instructions,
            sets: [defaultSetFor(v)],
          ),
        ],
      ),
    ],
  );

  StrengthWorkoutPlan updateExercise(
    String id,
    StrengthPlannedExercise Function(StrengthPlannedExercise) f,
  ) => _mapExercise(id, f);

  StrengthWorkoutPlan removeExercise(String id) => _tidy([
    for (final b in blocks)
      b.copyWith(exercises: [...b.exercises.where((e) => e.id != id)]),
  ]);

  /// A copy with new exercise and set ids, placed right after the original.
  StrengthWorkoutPlan duplicateExercise(String id) {
    final next = <StrengthBlock>[];
    for (final b in blocks) {
      final i = b.exercises.indexWhere((e) => e.id == id);
      if (i < 0) {
        next.add(b);
        continue;
      }
      final e = b.exercises[i];
      final copy = e.copyWith(
        id: newStrengthId('ex'),
        sets: [for (final s in e.sets) s.copyWith(id: newStrengthId('set'))],
      );
      if (b.grouped) {
        next.add(b.copyWith(exercises: [...b.exercises]..insert(i + 1, copy)));
      } else {
        next
          ..add(b)
          ..add(StrengthBlock(id: newStrengthId('blk'), exercises: [copy]));
      }
    }
    return copyWith(blocks: next);
  }

  /// Moves within a group, or moves a straight exercise past the next block.
  StrengthWorkoutPlan moveExercise(String id, int delta) {
    final bi = blocks.indexWhere((b) => b.exercises.any((e) => e.id == id));
    if (bi < 0) return this;
    final b = blocks[bi];
    if (b.grouped) {
      final i = b.exercises.indexWhere((e) => e.id == id);
      final j = i + delta;
      if (j < 0 || j >= b.exercises.length) return this;
      final list = [...b.exercises];
      list.insert(j, list.removeAt(i));
      return copyWith(blocks: [...blocks]..[bi] = b.copyWith(exercises: list));
    }
    final j = bi + delta;
    if (j < 0 || j >= blocks.length) return this;
    final list = [...blocks];
    list.insert(j, list.removeAt(bi));
    return copyWith(blocks: list);
  }

  bool canMove(String id, int delta) => moveExercise(id, delta) != this;

  /// Joins the exercise's block with the next block into a superset or
  /// circuit. Sets and their ids stay.
  StrengthWorkoutPlan groupWithNext(String id, StrengthBlockKind kind) {
    final bi = blocks.indexWhere((b) => b.exercises.any((e) => e.id == id));
    if (bi < 0 || bi + 1 >= blocks.length) return this;
    final a = blocks[bi], b = blocks[bi + 1];
    final merged = StrengthBlock(
      id: a.grouped ? a.id : newStrengthId('blk'),
      kind: kind,
      exercises: [...a.exercises, ...b.exercises],
      restBetweenExercisesSeconds: a.restBetweenExercisesSeconds ?? 0,
      restBetweenRoundsSeconds:
          a.restBetweenRoundsSeconds ??
          a.exercises.last.sets.firstOrNull?.restSeconds ??
          90,
    );
    return copyWith(
      blocks: [...blocks]
        ..removeRange(bi, bi + 2)
        ..insert(bi, merged),
    );
  }

  /// Splits a group into straight sets, keeping every value.
  StrengthWorkoutPlan ungroup(String blockId) => copyWith(
    blocks: [
      for (final b in blocks)
        if (b.id == blockId && b.grouped)
          for (final e in b.exercises)
            StrengthBlock(id: newStrengthId('blk'), exercises: [e])
        else
          b,
    ],
  );

  StrengthWorkoutPlan updateBlock(
    String blockId,
    StrengthBlock Function(StrengthBlock) f,
  ) => copyWith(blocks: [for (final b in blocks) b.id == blockId ? f(b) : b]);

  /// A new set copying the last one, with a new id.
  StrengthWorkoutPlan addSet(String exerciseId) => _mapExercise(
    exerciseId,
    (e) => e.copyWith(
      sets: [
        ...e.sets,
        e.sets.isEmpty
            ? StrengthSetTarget(
                id: newStrengthId('set'),
                reps: 10,
                restSeconds: 90,
              )
            : e.sets.last.copyWith(id: newStrengthId('set')),
      ],
    ),
  );

  StrengthWorkoutPlan duplicateSet(String exerciseId, String setId) =>
      _mapExercise(exerciseId, (e) {
        final i = e.sets.indexWhere((s) => s.id == setId);
        if (i < 0) return e;
        return e.copyWith(
          sets: [...e.sets]
            ..insert(i + 1, e.sets[i].copyWith(id: newStrengthId('set'))),
        );
      });

  StrengthWorkoutPlan removeSet(String exerciseId, String setId) =>
      _mapExercise(
        exerciseId,
        (e) => e.copyWith(sets: [...e.sets.where((s) => s.id != setId)]),
      );

  StrengthWorkoutPlan updateSet(String exerciseId, StrengthSetTarget set) =>
      _mapExercise(
        exerciseId,
        (e) => e.copyWith(
          sets: [for (final s in e.sets) s.id == set.id ? set : s],
        ),
      );

  /// Copies reps/range/time, load and rest of [from] onto every working set
  /// of the exercise. Kind, effort, tempo and ids stay per set.
  StrengthWorkoutPlan applyToWorkingSets(
    String exerciseId,
    StrengthSetTarget from,
  ) => _mapExercise(
    exerciseId,
    (e) => e.copyWith(
      sets: [
        for (final s in e.sets)
          s.kind == StrengthSetKind.warmup
              ? s
              : s.copyWith(
                  reps: () => from.reps,
                  repMin: () => from.repMin,
                  repMax: () => from.repMax,
                  durationSeconds: () => from.durationSeconds,
                  load: () => from.load,
                  resistance: () => from.resistance,
                  restSeconds: () => from.restSeconds,
                ),
      ],
    ),
  );

  /// Applies a history hint's loads to working sets without a load. An
  /// explicit load already set always wins. Returns this plan unchanged when
  /// the history cannot be applied unambiguously.
  StrengthWorkoutPlan applyHistory(
    String exerciseId,
    StrengthHistoryEntry entry,
  ) => _mapExercise(exerciseId, (e) {
    final working = [
      for (final s in e.sets)
        if (s.kind != StrengthSetKind.warmup) s.id,
    ];
    final common = entry.commonLoad;
    final perSet = entry.sets.length == working.length
        ? [for (final s in entry.sets) s.load]
        : null;
    if (common == null && (perSet == null || perSet.any((l) => l == null))) {
      return e;
    }
    return e.copyWith(
      sets: [
        for (final s in e.sets)
          s.kind == StrengthSetKind.warmup || s.load != null
              ? s
              : s.copyWith(
                  load: () => common ?? perSet![working.indexOf(s.id)],
                ),
      ],
    );
  });
}

/// Whether [entry] can be applied to [e] with one action.
bool historyApplies(StrengthPlannedExercise e, StrengthHistoryEntry entry) {
  if (!e.convention.loadKind.hasKg) return false;
  final working = e.sets.where((s) => s.kind != StrengthSetKind.warmup);
  if (working.any((s) => s.load != null)) return false;
  if (entry.commonLoad != null) return true;
  return entry.sets.length == working.length &&
      entry.sets.every((s) => s.load != null);
}

/// A readable exercise list for sharing, from the same domain model.
String strengthPlanText(StrengthWorkoutPlan plan, MassUnit unit) {
  final lines = <String>[];
  var n = 0;
  for (final b in plan.blocks) {
    if (b.grouped) {
      lines.add(
        '${b.kind.label} · ${b.rounds} rounds'
        '${b.restBetweenRoundsSeconds == null ? '' : ' · rest ${formatStrengthSeconds(b.restBetweenRoundsSeconds!)} between rounds'}',
      );
    }
    for (final e in b.exercises) {
      n++;
      lines.add(
        '$n. ${e.name}${e.equipment.isEmpty ? '' : ' (${e.equipment})'}',
      );
      for (var i = 0; i < e.sets.length; i++) {
        final s = e.sets[i];
        final load = s.load == null
            ? s.resistance
            : formatStrengthLoad(s.load!.kg, unit) +
                  (e.convention.basis == StrengthLoadBasis.perImplement
                      ? ' each'
                      : '');
        lines.add(
          '   ${s.kind == StrengthSetKind.warmup ? 'Warm-up' : 'Set ${i + 1}'}: '
          '${s.timed ? formatStrengthSeconds(s.durationSeconds!) : '${s.repsText} reps'}'
          '${load == null ? '' : ' × $load'}'
          '${!b.grouped && s.restSeconds != null ? ' · rest ${formatStrengthSeconds(s.restSeconds!)}' : ''}'
          '${s.effort == null ? '' : ' · ${s.effort!.text}'}',
        );
      }
    }
  }
  return lines.join('\n');
}
