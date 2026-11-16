/// One threshold value from one source, and which of them Fjelia proposes.
///
/// Sources rank by how the value was obtained: the app's own tests first
/// (30-minute time trial, HR drift test, a planned DFA alpha1 ramp test),
/// then what a watch platform detected (Garmin, COROS), then DFA alpha1 over
/// several sessions and the eFTP from
/// rides, then the values in the Polar profile (often age-based defaults),
/// and formulas last. Within a rank the newest wins. A candidate never
/// changes the value in use by itself: it is proposed and the athlete
/// applies or keeps.
library;

import 'dart:math' as math;

enum ThresholdKind {
  /// Aerobic threshold heart rate, running (top of zone 2).
  lt1,

  /// Lactate threshold heart rate (LTHR), running; may carry a pace.
  lt2,

  /// Lactate threshold heart rate, cycling.
  lt2Bike,

  /// Functional threshold power, watts.
  ftp,
}

/// Rank per source (lower is preferred).
const thresholdSourceRank = {
  'tt': 1,
  'drift': 1,
  'dfa_ramp': 1,
  'garmin_api': 2,
  'coros': 2,
  'dfa': 3,
  'eftp': 3,
  'polar_profile': 4,
  'formula': 5,
};

/// Candidates older than this are shown but never proposed.
const thresholdMaxAge = Duration(days: 180);

class ThresholdCandidate {
  const ThresholdCandidate({
    required this.kind,
    required this.source,
    required this.value,
    this.date,
    this.paceSecPerKm,
    this.sessions,
    this.note,
  });

  final ThresholdKind kind;
  final String source;

  /// Heart rate (bpm) or, for [ThresholdKind.ftp], watts.
  final int value;
  final DateTime? date;
  final int? paceSecPerKm;

  /// For DFA alpha1: how many sessions the median is taken from.
  final int? sessions;

  /// Short explanation, e.g. "LT2 − 30 bpm".
  final String? note;

  int get rank => thresholdSourceRank[source] ?? 9;

  /// Identifies this proposal, so "keep" is remembered until the value
  /// changes.
  String get fingerprint => '${kind.name}:$source:$value';

  bool isFresh(DateTime now) =>
      source == 'formula' ||
      (date != null && now.difference(date!) <= thresholdMaxAge);
}

/// The candidate Fjelia would use: the best fresh one by rank, then date.
ThresholdCandidate? bestThreshold(
  Iterable<ThresholdCandidate> candidates,
  DateTime now,
) {
  final fresh = candidates.where((c) => c.isFresh(now)).toList()
    ..sort((a, b) {
      final byRank = a.rank.compareTo(b.rank);
      if (byRank != 0) return byRank;
      return (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0));
    });
  return fresh.firstOrNull;
}

/// The best candidate, when it differs enough from [inUse] (3 bpm, or 3 %
/// for FTP) and the athlete hasn't kept the current value against it. A
/// formula is shown but never proposed: it knows less than any zones in use.
ThresholdCandidate? thresholdProposal({
  required List<ThresholdCandidate> candidates,
  required int? inUse,
  required Set<String> kept,
  required DateTime now,
}) {
  final best = bestThreshold(candidates, now);
  if (best == null || best.source == 'formula') return null;
  if (_wasKept(best, kept)) return null;
  if (inUse == null) return best;
  final diff = (best.value - inUse).abs();
  final enough = best.kind == ThresholdKind.ftp
      ? diff >= inUse * 0.03
      : diff >= 3;
  return enough ? best : null;
}

/// "Keep current" holds while the source reports about the same value: a
/// DFA median moving by a beat or two doesn't bring the proposal back.
bool _wasKept(ThresholdCandidate c, Set<String> kept) {
  final tolerance = c.kind == ThresholdKind.ftp ? (c.value * 0.02).round() : 2;
  for (var v = c.value - tolerance; v <= c.value + tolerance; v++) {
    if (kept.contains('${c.kind.name}:${c.source}:$v')) return true;
  }
  return false;
}

/// Median of [values]; null when fewer than [minimum].
/// A single DFA session further than this from the value in use is taken
/// for a misreading (a steady run, a strap issue), not for a new threshold.
const dfaMaxDeviation = 15;

/// The sessions of [sessions] whose value ([read]) fits [inUse]. Sessions
/// further off count only when at least three of them agree within 8 bpm
/// and outnumber the rest: then the value in use is the one that's off.
List<T> plausibleDfa<T>(
  List<T> sessions, {
  required double Function(T) read,
  required int? inUse,
}) {
  if (inUse == null) return sessions;
  final near = <T>[], far = <T>[];
  for (final s in sessions) {
    ((read(s) - inUse).abs() <= dfaMaxDeviation ? near : far).add(s);
  }
  if (far.length >= 3 && far.length > near.length) {
    final values = far.map(read);
    if (values.reduce(math.max) - values.reduce(math.min) <= 8) return far;
  }
  return near;
}

int? medianOf(List<double> values, {int minimum = 1}) {
  if (values.length < minimum) return null;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  final median = sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
  return median.round();
}
