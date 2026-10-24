// The evidence that may justify rebuilding the rest of a plan. Kept apart so
// the rules can be tested; the caller supplies completed data only.

/// Relative growth of [current] over [previous], in percent, when it exceeds
/// [threshold] percent, else null. Both are summed zone time (hours times a
/// hundred) of two completed weeks, not a load model, so the message says so.
double? zoneTimeJump(double current, double previous, {double threshold = 15}) {
  if (!current.isFinite || !previous.isFinite || previous <= 0) return null;
  final change = (current - previous) / previous * 100;
  return change > threshold ? change : null;
}

/// Whether HRV was suppressed on each of the given nights: every value is
/// more than [share] below [baseline]. A missing night counts as not
/// suppressed, so one poor reading never qualifies on its own.
bool hrvSuppressed(
  Iterable<double?> nights,
  double? baseline, {
  double share = 0.1,
  int needed = 2,
}) {
  if (baseline == null || baseline <= 0) return false;
  final list = nights.toList();
  if (list.length < needed) return false;
  return list
      .take(needed)
      .every((v) => v != null && v < baseline * (1 - share));
}
