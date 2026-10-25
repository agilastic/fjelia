// The evidence that may justify rebuilding the rest of a plan. Kept apart so
// the rules can be tested; the caller supplies completed data only.

import 'season/goal_set.dart';

/// Whether the goals changed since the plan was built, so its future no
/// longer prepares for what the athlete now has on the calendar. A plan built
/// before goals were linked has no revision: it counts as changed only when
/// there is more than one goal, which it never knew about. Called for a plan
/// that is active.
bool goalSetChanged({required String? planRevision, required GoalSet goals}) {
  // The last goal gone is the biggest change there is: the plan has nothing
  // left to prepare for.
  if (goals.isEmpty) return true;
  if (planRevision == null) return goals.active.length > 1;
  return planRevision != goals.revision;
}

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
