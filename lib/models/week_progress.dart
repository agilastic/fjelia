/// How far a calendar week has progressed. A week that is still running has a
/// smaller total than a finished one, so it must not be compared with it as if
/// it were complete.
class WeekProgress {
  const WeekProgress({required this.weekStart, required this.now});

  final DateTime weekStart, now;

  DateTime get weekEnd =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + 7);

  bool get inProgress => !now.isBefore(weekStart) && now.isBefore(weekEnd);

  /// Days of the week that have begun, today included (1 to 7).
  int get daysElapsed => inProgress
      ? DateTime(now.year, now.month, now.day)
                .difference(
                  DateTime(weekStart.year, weekStart.month, weekStart.day),
                )
                .inDays +
            1
      : 7;

  /// The moment of the previous week that matches [now] in this one. Totals up
  /// to it are comparable with the week so far; a finished week is compared
  /// with the whole previous week.
  DateTime get previousCutoff => inProgress
      ? DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day - 7,
        ).add(now.difference(weekStart))
      : weekStart;
}

/// One plain sentence about the week for the load chart. [previousComparable]
/// is the previous week up to the same point as [current].
String weeklyLoadHeadline({
  required int weekNumber,
  required double current,
  required double previousComparable,
  required WeekProgress progress,
  String unit = 'pts',
}) {
  String n(double v) => v.round().toString();
  final where = progress.inProgress
      ? 'Week $weekNumber, day ${progress.daysElapsed} of 7'
      : 'Week $weekNumber';
  if (current <= 0 && progress.inProgress) {
    return '$where: no activity on record yet.';
  }
  final amount = progress.inProgress
      ? '${n(current)} $unit so far'
      : '${n(current)} $unit';
  if (previousComparable <= 0) return '$where: $amount.';
  final change = (current - previousComparable) / previousComparable * 100;
  final basis = progress.inProgress
      ? 'the same days last week'
      : 'the week before';
  if (change.abs() < 3) return '$where: $amount, about the same as $basis.';
  final size = '${change.abs().round()}%';
  return '$where: $amount, $size ${change > 0 ? 'above' : 'below'} $basis.';
}
