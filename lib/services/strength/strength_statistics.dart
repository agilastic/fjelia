import 'dart:math' as math;

import '../../models/strength_workout.dart';

/// Pure arithmetic over strength plans and logs (section 7). Unknown values
/// make totals partial; they never become zero.

/// A total over the sets whose values are known, and how many sets it is
/// missing. `known == of` means complete.
class PartialTotal {
  const PartialTotal(this.min, this.max, this.known, this.of);
  final double min, max;
  final int known, of;
  bool get complete => known == of;
  bool get isRange => min != max;
  bool get any => of > 0;
}

class StrengthPlanSummary {
  const StrengthPlanSummary({
    required this.exercises,
    required this.workingSets,
    required this.warmupSets,
    required this.repsMin,
    required this.repsMax,
    required this.holdSeconds,
    required this.volume,
    required this.maxLoadKg,
    required this.duration,
  });
  final int exercises, workingSets, warmupSets, repsMin, repsMax, holdSeconds;

  /// Known external load × target reps, in kg·reps.
  final PartialTotal volume;

  /// Highest planned load per exercise occurrence id.
  final Map<String, double> maxLoadKg;

  /// Estimated duration in seconds; null when no estimate is justified.
  final StrengthDurationEstimate? duration;
}

class StrengthDurationEstimate {
  const StrengthDurationEstimate(
    this.minSeconds,
    this.maxSeconds,
    this.explicit,
  );
  final int minSeconds, maxSeconds;

  /// Entered by the athlete or the template rather than calculated.
  final bool explicit;
}

class StrengthLogSummary {
  const StrengthLogSummary({
    required this.exercises,
    required this.completedSets,
    required this.partialSets,
    required this.failedSets,
    required this.skippedSets,
    required this.unrecordedSets,
    required this.reps,
    required this.repsUnknownSets,
    required this.holdSeconds,
    required this.volume,
    required this.maxLoadKg,
    required this.restSeconds,
    required this.restIntervals,
  });

  /// Null when no exercise data exists: unknown, not zero.
  final int? exercises;
  final int completedSets, partialSets, failedSets, skippedSets, unrecordedSets;

  /// Achieved repetitions recorded in attempted sets.
  final int reps;

  /// Attempted repetition sets whose count is unknown.
  final int repsUnknownSets;
  final int holdSeconds;
  final PartialTotal volume;

  /// Highest load on a completed set per performed exercise id.
  final Map<String, double> maxLoadKg;

  /// Mean recorded rest, null without recorded intervals.
  final double? restSeconds;
  final int restIntervals;
}

bool _counts(StrengthSetKind kind, bool includeWarmups) =>
    includeWarmups || kind != StrengthSetKind.warmup;

StrengthPlanSummary summarisePlan(
  StrengthWorkoutPlan plan, {
  bool includeWarmups = false,
}) {
  var working = 0, warmup = 0, repsMin = 0, repsMax = 0, hold = 0;
  var vMin = 0.0, vMax = 0.0, known = 0, loaded = 0;
  final maxLoad = <String, double>{};
  for (final e in plan.exercises) {
    final c = e.convention;
    for (final s in e.sets) {
      if (s.kind == StrengthSetKind.warmup) {
        warmup++;
      } else {
        working++;
      }
      if (!_counts(s.kind, includeWarmups)) continue;
      if (s.durationSeconds != null) hold += s.durationSeconds!;
      final bounds = s.repBounds;
      if (bounds != null) {
        repsMin += bounds.$1;
        repsMax += bounds.$2;
      }
      if (c.loadKind.countsVolume && !s.timed) {
        loaded++;
        if (s.load != null && bounds != null) {
          known++;
          final per = s.load!.kg * c.loadFactor * c.repFactor;
          vMin += per * bounds.$1;
          vMax += per * bounds.$2;
        }
      }
      if (s.load != null && c.loadKind.countsVolume) {
        maxLoad[e.id] = math.max(maxLoad[e.id] ?? 0, s.load!.kg);
      }
    }
  }
  return StrengthPlanSummary(
    exercises: plan.exercises.length,
    workingSets: working,
    warmupSets: warmup,
    repsMin: repsMin,
    repsMax: repsMax,
    holdSeconds: hold,
    volume: PartialTotal(vMin, vMax, known, loaded),
    maxLoadKg: maxLoad,
    duration: estimatePlanDuration(plan),
  );
}

/// Seconds per repetition without a tempo; a range, because lifting speed
/// is not known.
const _repSecondsMin = 2, _repSecondsMax = 5;

/// Allowance between exercises (setting up, changing plates).
const _transitionMin = 30, _transitionMax = 90;

int? _tempoSeconds(String? tempo) {
  if (tempo == null || !validTempo(tempo)) return null;
  return tempo
      .toUpperCase()
      .split('-')
      .map((p) => p == 'X' ? 1 : int.parse(p))
      .fold<int>(0, (a, b) => a + b);
}

/// A range from timed work, repetitions and rests, or the explicit estimate.
/// Group rests replace set rests inside a superset or circuit; no rest is
/// added after the final set.
StrengthDurationEstimate? estimatePlanDuration(StrengthWorkoutPlan plan) {
  if (plan.estimatedMinutes != null) {
    final s = plan.estimatedMinutes! * 60;
    return StrengthDurationEstimate(s, s, true);
  }
  if (plan.isEmpty) return null;
  var lo = 0, hi = 0;
  void work(StrengthSetTarget s, StrengthConvention c) {
    if (s.durationSeconds != null) {
      final t = s.durationSeconds! * c.repFactor;
      lo += t;
      hi += t;
      return;
    }
    final bounds = s.repBounds;
    if (bounds == null) return;
    final tempo = _tempoSeconds(s.tempo);
    final reps = c.repFactor;
    lo += bounds.$1 * reps * (tempo ?? _repSecondsMin);
    hi += bounds.$2 * reps * (tempo ?? _repSecondsMax);
  }

  void rest(int? seconds) {
    lo += seconds ?? 0;
    hi += seconds ?? 0;
  }

  final blocks = plan.blocks.where((b) => b.exercises.isNotEmpty).toList();
  for (var bi = 0; bi < blocks.length; bi++) {
    final b = blocks[bi];
    final last = bi == blocks.length - 1;
    if (bi > 0) {
      lo += _transitionMin;
      hi += _transitionMax;
    }
    if (!b.grouped) {
      final e = b.exercises.single;
      for (var i = 0; i < e.sets.length; i++) {
        work(e.sets[i], e.convention);
        if (i < e.sets.length - 1 || !last) rest(e.sets[i].restSeconds);
      }
      continue;
    }
    for (var r = 0; r < b.rounds; r++) {
      final inRound = [
        for (final e in b.exercises)
          if (r < e.sets.length) (e, e.sets[r]),
      ];
      for (var i = 0; i < inRound.length; i++) {
        work(inRound[i].$2, inRound[i].$1.convention);
        if (i < inRound.length - 1) rest(b.restBetweenExercisesSeconds);
      }
      if (r < b.rounds - 1 || !last) rest(b.restBetweenRoundsSeconds);
    }
  }
  return StrengthDurationEstimate(lo, hi, false);
}

StrengthLogSummary summariseLog(
  StrengthActivityLog log, {
  bool includeWarmups = false,
}) {
  var done = 0, partial = 0, failed = 0, skipped = 0, unrecorded = 0;
  var reps = 0, repsUnknown = 0, hold = 0, known = 0, loaded = 0;
  var volume = 0.0, rest = 0, restCount = 0;
  final maxLoad = <String, double>{};
  for (final e in log.exercises) {
    final c = e.convention;
    for (final s in e.sets) {
      if (s.restSeconds != null && s.restOrigin != StrengthOrigin.plan) {
        rest += s.restSeconds!;
        restCount++;
      }
      if (!_counts(s.kind, includeWarmups)) continue;
      switch (s.status) {
        case StrengthSetStatus.completed:
          done++;
        case StrengthSetStatus.partial:
          partial++;
        case StrengthSetStatus.failed:
          failed++;
        case StrengthSetStatus.skipped:
          skipped++;
        case StrengthSetStatus.unrecorded:
          unrecorded++;
      }
      if (!s.status.attempted) continue;
      if (s.durationSeconds != null) {
        hold += s.durationSeconds!;
        continue;
      }
      if (s.reps == null) {
        repsUnknown++;
      } else {
        reps += s.reps!;
      }
      if (c.loadKind.countsVolume) {
        loaded++;
        if (s.load != null && s.reps != null) {
          known++;
          volume += s.load!.kg * c.loadFactor * c.repFactor * s.reps!;
        }
      }
      if (s.status == StrengthSetStatus.completed &&
          s.load != null &&
          c.loadKind.countsVolume) {
        maxLoad[e.id] = math.max(maxLoad[e.id] ?? 0, s.load!.kg);
      }
    }
  }
  return StrengthLogSummary(
    exercises: log.isEmpty ? null : log.exercises.length,
    completedSets: done,
    partialSets: partial,
    failedSets: failed,
    skippedSets: skipped,
    unrecordedSets: unrecorded,
    reps: reps,
    repsUnknownSets: repsUnknown,
    holdSeconds: hold,
    volume: PartialTotal(volume, volume, known, loaded),
    maxLoadKg: maxLoad,
    restSeconds: restCount == 0 ? null : rest / restCount,
    restIntervals: restCount,
  );
}

/// "60 → 70 → 80 kg", "70 kg" or null when no set has a load.
String? loadPatternText(Iterable<StrengthLoad?> loads, MassUnit unit) {
  final known = loads.whereType<StrengthLoad>().map((l) => l.kg).toList();
  if (known.isEmpty) return null;
  final distinct = <double>[];
  for (final kg in known) {
    if (distinct.isEmpty || (distinct.last - kg).abs() > 1e-9) distinct.add(kg);
  }
  if (distinct.length == 1) return formatStrengthLoad(distinct.single, unit);
  if (distinct.length > 4) return 'Variable loads';
  return '${distinct.map((kg) => _trimUnit(formatStrengthLoad(kg, unit))).join(' → ')} ${unit.name}';
}

String _trimUnit(String s) => s.substring(0, s.lastIndexOf(' '));

/// "3 sets · 8–10 reps · Rest 2:00" for a planned exercise.
String plannedExerciseLine(StrengthPlannedExercise e) {
  final work = e.sets.where((s) => s.kind != StrengthSetKind.warmup).toList();
  final warm = e.sets.length - work.length;
  final reps = {for (final s in work) s.repsText};
  final rests = {for (final s in work) s.restSeconds}..remove(null);
  return [
    '${work.length} ${work.length == 1 ? 'set' : 'sets'}',
    if (warm > 0) '+ $warm warm-up',
    if (reps.length == 1)
      work.first.timed ? reps.single : '${reps.single} reps'
    else if (reps.isNotEmpty)
      'Variable sets',
    if (rests.length == 1) 'Rest ${formatStrengthSeconds(rests.single!)}',
  ].join(' · ');
}

// ── Plan versus actual ────────────────────────────────────────────────────

enum StrengthMatch {
  /// A planned set with a performed set mapped to it.
  linked,

  /// A planned set that nothing was recorded against.
  missing,

  /// A performed set without a planned counterpart.
  added,
}

class StrengthSetComparison {
  const StrengthSetComparison(this.match, {this.target, this.result});
  final StrengthMatch match;
  final StrengthSetTarget? target;
  final StrengthSetResult? result;

  /// Achieved minus target reps; for a range, the distance outside it.
  int? get repDelta {
    final r = result?.reps, b = target?.repBounds;
    if (r == null || b == null) return null;
    if (r < b.$1) return r - b.$1;
    if (r > b.$2) return r - b.$2;
    return 0;
  }

  double? get loadDeltaKg {
    final a = result?.load?.kg, t = target?.load?.kg;
    return a == null || t == null ? null : a - t;
  }
}

class StrengthExerciseComparison {
  const StrengthExerciseComparison({
    this.planned,
    this.performed,
    required this.sets,
  });
  final StrengthPlannedExercise? planned;
  final StrengthPerformedExercise? performed;
  final List<StrengthSetComparison> sets;
  bool get added => planned == null;
  bool get missing => performed == null;
}

/// Maps by stable planned ids only; never by row index or exercise name.
List<StrengthExerciseComparison> compareWithBaseline(StrengthActivityLog log) {
  final plan = log.baseline?.plan;
  if (plan == null) return const [];
  final out = <StrengthExerciseComparison>[];
  final used = <String>{};
  for (final p in plan.exercises) {
    final performed = log.exercises
        .where((e) => e.plannedExerciseId == p.id)
        .firstOrNull;
    if (performed != null) used.add(performed.id);
    final results = {
      for (final s in performed?.sets ?? const <StrengthSetResult>[])
        if (s.plannedSetId != null) s.plannedSetId!: s,
    };
    final targetIds = {for (final t in p.sets) t.id};
    out.add(
      StrengthExerciseComparison(
        planned: p,
        performed: performed,
        sets: [
          for (final t in p.sets)
            results[t.id] != null
                ? StrengthSetComparison(
                    StrengthMatch.linked,
                    target: t,
                    result: results[t.id],
                  )
                : StrengthSetComparison(StrengthMatch.missing, target: t),
          for (final s in performed?.sets ?? const <StrengthSetResult>[])
            if (s.plannedSetId == null || !targetIds.contains(s.plannedSetId))
              StrengthSetComparison(StrengthMatch.added, result: s),
        ],
      ),
    );
  }
  for (final e in log.exercises.where((e) => !used.contains(e.id))) {
    out.add(
      StrengthExerciseComparison(
        performed: e,
        sets: [
          for (final s in e.sets)
            StrengthSetComparison(StrengthMatch.added, result: s),
        ],
      ),
    );
  }
  return out;
}
