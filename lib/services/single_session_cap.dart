import '../db/database.dart';

// The longest single session a sport may get, from the athlete's own recent
// sessions in it. A session much longer than the longest of the last weeks
// raises the risk of overuse injury (Frandsen et al. 2025, BJSM, runners:
// more than 10 % over the longest run of the last 30 days). For other sports
// the same limit is a cautious transfer, not a validated rule; see
// docs/workout-sport-replacement.md and docs/training-plan-rethink.md.

/// Days of history the longest session is read from.
const singleSessionCapDays = 60;

/// How much longer than that longest session a new one may be.
const singleSessionCapGrowth = 1.1;

/// The limit when the sport has no session in those days.
const singleSessionCapWithoutHistoryMin = 60;

/// Minutes of the longest session of at least ten minutes before [day], over
/// [singleSessionCapDays], among [activities] that [sameSport] accepts; null
/// when there is none.
int? longestRecentSessionMin(
  Iterable<ActivityRecord> activities,
  DateTime day, {
  required bool Function(String type) sameSport,
}) {
  final start = DateTime(day.year, day.month, day.day);
  final from = start.subtract(const Duration(days: singleSessionCapDays));
  int? longest;
  for (final activity in activities) {
    if (activity.startDate.isBefore(from) ||
        !activity.startDate.isBefore(start)) {
      continue;
    }
    final minutes = activity.durationSeconds ~/ 60;
    if (minutes < 10 || !sameSport(activity.type)) continue;
    if (longest == null || minutes > longest) longest = minutes;
  }
  return longest;
}

/// The longest session the limit allows after a longest recent session of
/// [longestMin] minutes (null: none).
int singleSessionCapMin(int? longestMin) => longestMin == null
    ? singleSessionCapWithoutHistoryMin
    : (longestMin * singleSessionCapGrowth).floor();
