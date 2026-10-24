/// What the athlete really trains per week, to set the hours slider against.
class WeeklyHours {
  const WeeklyHours({required this.average, required this.peak});

  /// Mean hours per week over the weeks looked at, the current week excluded.
  final double average;

  /// The busiest of those weeks, in hours.
  final double peak;

  /// Whether [target] hours a week is far beyond what was done in any of the
  /// weeks: more than a third above the busiest one.
  bool isFarAbove(double target) => peak > 0 && target > peak * 1.35;

  /// The hours of the last [weeks] full weeks, from the durations of the
  /// activities (start, seconds). Null without any activity in them.
  static WeeklyHours? of(
    Iterable<(DateTime, int)> activities, {
    required DateTime now,
    required bool mondayFirst,
    int weeks = 12,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final offset = mondayFirst ? today.weekday - 1 : today.weekday % 7;
    final thisWeek = DateTime(today.year, today.month, today.day - offset);
    final first = DateTime(
      thisWeek.year,
      thisWeek.month,
      thisWeek.day - 7 * weeks,
    );
    final hours = List<double>.filled(weeks, 0);
    var any = false;
    for (final (start, seconds) in activities) {
      if (start.isBefore(first) || !start.isBefore(thisWeek)) continue;
      final week = start.difference(first).inDays ~/ 7;
      if (week < 0 || week >= weeks) continue;
      hours[week] += seconds / 3600;
      any = true;
    }
    if (!any) return null;
    return WeeklyHours(
      average: hours.reduce((a, b) => a + b) / weeks,
      peak: hours.reduce((a, b) => a > b ? a : b),
    );
  }
}
