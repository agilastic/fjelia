import 'dart:math' as math;

import '../../models/strength_workout.dart';
import 'strength_repository.dart';

/// Stage C: estimated one-repetition maximum and per-exercise trends.
///
/// An estimate, never a measurement. It uses two named formulas and shows
/// both as a range:
///
/// * Epley: load × (1 + reps / 30)
/// * Brzycki: load × 36 / (37 − reps)
///
/// Only completed working or back-off sets with a known external load and
/// 1–10 repetitions qualify; both formulas lose accuracy beyond ten. Timed,
/// bodyweight, added-load, assisted and band sets are never estimated. The
/// load is the entered value in the exercise's own convention (per dumbbell
/// stays per dumbbell), so estimates compare only within one context.
const strengthOneRmMaxReps = 10;

class StrengthOneRm {
  const StrengthOneRm(this.lowKg, this.highKg, this.reps, this.loadKg);
  final double lowKg, highKg;

  /// The set it was estimated from.
  final int reps;
  final double loadKg;

  /// One repetition: the lift itself, not an estimate.
  bool get measured => reps == 1;
}

StrengthOneRm? estimateOneRm(StrengthSetResult s, StrengthConvention c) {
  final reps = s.reps, load = s.load?.kg;
  if (s.status != StrengthSetStatus.completed ||
      s.kind == StrengthSetKind.warmup ||
      s.kind == StrengthSetKind.technique ||
      c.loadKind != StrengthLoadKind.external ||
      s.durationSeconds != null ||
      reps == null ||
      reps < 1 ||
      reps > strengthOneRmMaxReps ||
      load == null ||
      !load.isFinite ||
      load <= 0) {
    return null;
  }
  if (reps == 1) return StrengthOneRm(load, load, 1, load);
  final epley = load * (1 + reps / 30);
  final brzycki = load * 36 / (37 - reps);
  return StrengthOneRm(
    math.min(epley, brzycki),
    math.max(epley, brzycki),
    reps,
    load,
  );
}

/// The highest estimate among [sets], or null when none qualifies.
StrengthOneRm? bestOneRm(
  Iterable<StrengthSetResult> sets,
  StrengthConvention c,
) {
  StrengthOneRm? best;
  for (final s in sets) {
    final e = estimateOneRm(s, c);
    if (e != null && (best == null || e.highKg > best.highKg)) best = e;
  }
  return best;
}

/// "≈ 92–94 kg (Epley–Brzycki, from 10 × 70 kg)".
String oneRmText(StrengthOneRm e, MassUnit unit) {
  if (e.measured) return '${formatStrengthLoad(e.loadKg, unit)} (lifted once)';
  final lo = formatStrengthLoad(e.lowKg, unit);
  final hi = formatStrengthLoad(e.highKg, unit);
  final range = lo == hi ? lo : '${lo.split(' ').first}–$hi';
  return '≈ $range (Epley–Brzycki, from ${e.reps} × '
      '${formatStrengthLoad(e.loadKg, unit)})';
}

/// One session of an exercise context in a trend.
class StrengthTrendPoint {
  const StrengthTrendPoint({
    required this.date,
    required this.activityId,
    this.topLoadKg,
    this.oneRm,
    required this.completedSets,
  });
  final DateTime date;
  final String activityId;

  /// Highest load on a completed working set.
  final double? topLoadKg;
  final StrengthOneRm? oneRm;
  final int completedSets;
}

/// Trend points, oldest first, from comparable sessions.
List<StrengthTrendPoint> strengthTrend(
  List<StrengthHistoryEntry> sessions,
  StrengthConvention c,
) {
  final out = <StrengthTrendPoint>[];
  for (final s in sessions) {
    final done = s.sets.where(
      (r) =>
          r.status == StrengthSetStatus.completed &&
          r.kind != StrengthSetKind.warmup,
    );
    double? top;
    for (final r in done) {
      final kg = r.load?.kg;
      if (kg != null && c.loadKind.countsVolume) top = math.max(top ?? kg, kg);
    }
    out.add(
      StrengthTrendPoint(
        date: s.date,
        activityId: s.activityId,
        topLoadKg: top,
        oneRm: bestOneRm(done, c),
        completedSets: done.length,
      ),
    );
  }
  return out..sort((a, b) => a.date.compareTo(b.date));
}
