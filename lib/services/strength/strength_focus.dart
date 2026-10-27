import '../../models/strength_workout.dart';

/// Stage C gym mode: the order sets are done in, and the rest planned after
/// each. Pure, so the screen only displays and records.

class StrengthFocusStep {
  const StrengthFocusStep(
    this.exercise,
    this.set, {
    this.target,
    this.restAfter,
  });
  final StrengthPerformedExercise exercise;
  final StrengthSetResult set;
  final StrengthSetTarget? target;

  /// Planned rest after this set, as a target to time against; null when
  /// none is planned (always null after the last set).
  final int? restAfter;
}

/// The log's sets in execution order: straight sets exercise by exercise,
/// supersets and circuits round by round, as the baseline plan says. Sets
/// without a planned counterpart follow their exercise; exercises added in
/// the gym come last.
List<StrengthFocusStep> strengthFocusOrder(StrengthActivityLog log) {
  final plan = log.baseline?.plan;
  final byPlanned = {
    for (final e in log.exercises)
      if (e.plannedExerciseId != null) e.plannedExerciseId!: e,
  };
  final out = <StrengthFocusStep>[];
  final used = <String>{};
  StrengthSetResult? resultFor(StrengthPerformedExercise e, String targetId) =>
      e.sets.where((s) => s.plannedSetId == targetId).firstOrNull;

  void extras(StrengthPerformedExercise e) {
    for (final s in e.sets) {
      if (used.add(s.id)) out.add(StrengthFocusStep(e, s));
    }
  }

  for (final b in plan?.blocks ?? const <StrengthBlock>[]) {
    if (!b.grouped) {
      final p = b.exercises.single;
      final e = byPlanned[p.id];
      if (e == null) continue;
      for (final t in p.sets) {
        final r = resultFor(e, t.id);
        if (r != null && used.add(r.id)) {
          out.add(StrengthFocusStep(e, r, target: t, restAfter: t.restSeconds));
        }
      }
      extras(e);
      continue;
    }
    for (var round = 0; round < b.rounds; round++) {
      final inRound = [
        for (final p in b.exercises)
          if (round < p.sets.length && byPlanned[p.id] != null)
            (byPlanned[p.id]!, p.sets[round]),
      ];
      for (var i = 0; i < inRound.length; i++) {
        final (e, t) = inRound[i];
        final r = resultFor(e, t.id);
        if (r == null || !used.add(r.id)) continue;
        out.add(
          StrengthFocusStep(
            e,
            r,
            target: t,
            restAfter: i < inRound.length - 1
                ? b.restBetweenExercisesSeconds
                : b.restBetweenRoundsSeconds,
          ),
        );
      }
    }
    for (final p in b.exercises) {
      final e = byPlanned[p.id];
      if (e != null) extras(e);
    }
  }
  for (final e in log.exercises) {
    extras(e);
  }
  if (out.isNotEmpty) {
    final last = out.removeLast();
    out.add(StrengthFocusStep(last.exercise, last.set, target: last.target));
  }
  return out;
}

/// The first set still to record, or the last set when all are recorded.
int strengthFocusStart(List<StrengthFocusStep> order) {
  final i = order.indexWhere(
    (s) => s.set.status == StrengthSetStatus.unrecorded,
  );
  return i >= 0 ? i : (order.isEmpty ? 0 : order.length - 1);
}

/// The set recorded in gym mode, with what the athlete confirmed. A skipped
/// set holds no repetitions, time or load.
StrengthSetResult recordFocusSet(
  StrengthSetResult s,
  StrengthSetStatus status, {
  int? reps,
  int? seconds,
  StrengthLoad? load,
}) {
  final skipped = status == StrengthSetStatus.skipped;
  final next = s.copyWith(
    status: status,
    reps: () => skipped || seconds != null ? null : reps,
    durationSeconds: () => skipped ? null : seconds,
    load: () => skipped ? null : load,
    origins: {
      ...s.origins,
      'status': StrengthOrigin.manual,
      if (!skipped && reps != null && seconds == null)
        'reps': StrengthOrigin.manual,
      if (!skipped && seconds != null) 'durationSeconds': StrengthOrigin.manual,
      if (!skipped && load != null) 'load': StrengthOrigin.manual,
    },
  );
  if (status == StrengthSetStatus.completed &&
      next.reps == null &&
      next.durationSeconds == null) {
    throw StrengthValidationException(
      seconds == null && reps == null
          ? 'Enter the repetitions done.'
          : 'Enter how long the set lasted.',
    );
  }
  return next;
}

/// The rest the athlete actually took, measured from the end of one set to
/// the start of the next. Never the planned rest.
StrengthSetResult withTimedRest(StrengthSetResult s, Duration rest) =>
    s.copyWith(
      restSeconds: () => rest.inSeconds,
      restOrigin: () => StrengthOrigin.timer,
      origins: {...s.origins, 'restSeconds': StrengthOrigin.timer},
    );
