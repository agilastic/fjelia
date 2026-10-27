import '../../models/strength_workout.dart';
import 'strength_repository.dart';

/// Stage B: explainable, optional load proposals (section 12).
///
/// Rule v1 is a conservative Fjelia product policy, not a training
/// guideline. A proposal needs, for one straight-set exercise with an
/// external load:
///
/// 1. The [strengthProgressionMinSessions] most recent comparable sessions
///    (same movement, equipment and load convention), none stale.
/// 2. In each, at least the programmed number of working sets, every one
///    completed, all at the same known load.
/// 3. Every programmed set reached its upper repetition target.
/// 4. Effort recorded on the last working set, and no recorded effort harder
///    than intended (the programme's target, else RIR ≥ 1 / RPE ≤ 9).
/// 5. The workout's own load not set above or apart from that load.
/// 6. A programme context that allows progression and a known equipment
///    increment.
///
/// The result is calculated from facts every time; nothing is stored until
/// the athlete decides. Changing the rule means a new version, never a
/// rewrite of recorded history.
const strengthProgressionRuleVersion = 1;
const strengthProgressionMinSessions = 2;

enum StrengthProgressionOutcome {
  /// No proposal: keep the target and show history.
  none,

  /// The rule is met and a load increment can be reviewed.
  propose,

  /// The rule is met but the load step for this equipment is unknown.
  needsIncrement,

  /// The rule is met but the programme does not progress now (taper,
  /// recovery).
  blocked,
}

class StrengthProgressionEvaluation {
  const StrengthProgressionEvaluation(
    this.outcome,
    this.reason, {
    this.currentLoad,
    this.proposedLoad,
    this.supporting = const [],
    this.fingerprint,
  });
  final StrengthProgressionOutcome outcome;

  /// Why, in words fit for the athlete.
  final String reason;
  final StrengthLoad? currentLoad, proposedLoad;

  /// The sessions the evaluation used, newest first.
  final List<StrengthHistoryEntry> supporting;

  /// Identifies this exact proposal: rule version, exercise, loads and the
  /// supporting logs' revisions. A correction or deletion changes it.
  final String? fingerprint;

  bool get qualifies => outcome != StrengthProgressionOutcome.none;
}

StrengthProgressionEvaluation _none(
  String reason, [
  List<StrengthHistoryEntry> supporting = const [],
]) => StrengthProgressionEvaluation(
  StrengthProgressionOutcome.none,
  reason,
  supporting: supporting,
);

/// Whether a recorded effort is not harder than intended.
bool _effortWithin(StrengthEffort actual, StrengthEffort? target) {
  if (target != null && target.scale == actual.scale) {
    return actual.scale == StrengthEffortScale.rir
        ? actual.value >= target.value
        : actual.value <= target.value;
  }
  if (target != null) {
    // Compare across scales with RPE ≈ 10 − RIR.
    final targetRir = target.scale == StrengthEffortScale.rir
        ? target.value
        : 10 - target.value;
    final actualRir = actual.scale == StrengthEffortScale.rir
        ? actual.value
        : 10 - actual.value;
    return actualRir >= targetRir;
  }
  return actual.scale == StrengthEffortScale.rir
      ? actual.value >= 1
      : actual.value <= 9;
}

String _kg(double kg) => formatStrengthLoad(kg, MassUnit.kg);

StrengthProgressionEvaluation evaluateStrengthProgression({
  required StrengthPlannedExercise exercise,
  required StrengthBlock block,
  required List<StrengthHistoryEntry> recent,
  StrengthLoad? increment,
  String? blockedReason,
}) {
  final c = exercise.convention;
  final working = [
    for (final s in exercise.sets)
      if (s.kind != StrengthSetKind.warmup) s,
  ];
  if (block.grouped ||
      !c.loadKind.countsVolume ||
      working.isEmpty ||
      working.any((s) => s.timed || s.repBounds == null)) {
    return _none('Load suggestions cover straight sets with repetitions only.');
  }
  final sessions = recent.take(strengthProgressionMinSessions).toList();
  if (sessions.length < strengthProgressionMinSessions) {
    return _none(
      'Needs $strengthProgressionMinSessions recorded sessions of this exercise.',
      sessions,
    );
  }
  if (sessions.any((s) => s.stale)) {
    return _none('Recent history is too old for a suggestion.', sessions);
  }
  final load = sessions.first.commonLoad;
  if (load == null) {
    return _none('The last session did not use one known load.', sessions);
  }
  final targetEffort = working.last.effort;
  for (final s in sessions) {
    if (s.sets.length < working.length) {
      return _none(
        'A recent session had fewer sets than programmed.',
        sessions,
      );
    }
    if (s.sets.any((r) => r.status != StrengthSetStatus.completed)) {
      return _none(
        'A recent session has partial, failed, skipped or unrecorded sets.',
        sessions,
      );
    }
    final l = s.commonLoad;
    if (l == null || (l.kg - load.kg).abs() > 1e-6) {
      return _none('The load changed between the recent sessions.', sessions);
    }
    for (var i = 0; i < working.length; i++) {
      final reps = s.sets[i].reps;
      if (reps == null || reps < working[i].repBounds!.$2) {
        return _none(
          'Not every set reached the top of its repetition target.',
          sessions,
        );
      }
    }
    final last = s.sets[working.length - 1].effort;
    if (last == null) {
      return _none(
        'Record effort (RIR or RPE) on the last set to get suggestions.',
        sessions,
      );
    }
    if (s.sets.any(
      (r) => r.effort != null && !_effortWithin(r.effort!, targetEffort),
    )) {
      return _none('Recent sets were harder than intended.', sessions);
    }
  }
  final planned = working.map((s) => s.load?.kg).toSet();
  if (planned.length > 1 ||
      (planned.single != null && (planned.single! - load.kg).abs() > 1e-6)) {
    return _none(
      'This workout already has its own load; it stays as set.',
      sessions,
    );
  }
  if (blockedReason != null) {
    return StrengthProgressionEvaluation(
      StrengthProgressionOutcome.blocked,
      '$blockedReason: the load stays as programmed.',
      currentLoad: load,
      supporting: sessions,
    );
  }
  if (increment == null || increment.kg <= 0) {
    return StrengthProgressionEvaluation(
      StrengthProgressionOutcome.needsIncrement,
      'Your recent sets met the progression rule. Set the smallest load '
      'step for this equipment to review a load.',
      currentLoad: load,
      supporting: sessions,
    );
  }
  final next = StrengthLoad(load.kg + increment.kg, unit: load.unit);
  return StrengthProgressionEvaluation(
    StrengthProgressionOutcome.propose,
    "Your recent comparable sets met this programme's progression rule. "
    'Review the next available load increment.',
    currentLoad: load,
    proposedLoad: next,
    supporting: sessions,
    fingerprint: [
      'v$strengthProgressionRuleVersion',
      exercise.id,
      exercise.contextKey,
      _kg(load.kg),
      _kg(next.kg),
      for (final s in sessions) '${s.activityId}@${s.logRevision}',
    ].join('|'),
  );
}

/// The plan with [proposal]'s load on every working set of the exercise.
StrengthWorkoutPlan applyProgression(
  StrengthWorkoutPlan plan,
  String exerciseId,
  StrengthLoad load,
) => plan.copyWith(
  blocks: [
    for (final b in plan.blocks)
      b.copyWith(
        exercises: [
          for (final e in b.exercises)
            e.id != exerciseId
                ? e
                : e.copyWith(
                    sets: [
                      for (final s in e.sets)
                        s.kind == StrengthSetKind.warmup
                            ? s
                            : s.copyWith(load: () => load),
                    ],
                  ),
        ],
      ),
  ],
);
