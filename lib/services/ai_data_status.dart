/// How fresh and complete the data behind an AI request is, as one compact
/// TOON line. Without it a model reads a missing record as "no training" or
/// "rested"; with it a gap is visible as a gap.
String aiDataStatusLine({
  required DateTime now,
  required List<DateTime> activityDays,
  required List<DateTime> hrvDays,
  required List<DateTime> sleepDays,
  required List<DateTime> dailyDays,
  int window = 28,
}) {
  DateTime day(DateTime t) => DateTime(t.year, t.month, t.day);
  final today = day(now);
  final from = today.subtract(Duration(days: window - 1));
  String date(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  Set<DateTime> inWindow(List<DateTime> days) => {
    for (final d in days.map(day))
      if (!d.isBefore(from) && !d.isAfter(today)) d,
  };
  DateTime? last(List<DateTime> days) {
    DateTime? best;
    for (final d in days.map(day)) {
      if (!d.isAfter(today) && (best == null || d.isAfter(best))) best = d;
    }
    return best;
  }

  int ago(DateTime t) => today.difference(t).inDays;

  final gaps = <String>[];
  String metric(String name, List<DateTime> days) {
    final newest = last(days);
    if (newest == null) {
      gaps.add('$name none');
      return '$name(None)';
    }
    final age = ago(newest);
    // Today's value may simply not be in yet; two days or more is a gap.
    if (age >= 2) gaps.add('$name ${age}d');
    return '$name(Last:${date(newest)},DaysAgo:$age,'
        'Days$window:${inWindow(days).length}/$window)';
  }

  // Longest run of days without a recorded activity inside the window.
  final active = inWindow(activityDays);
  var longest = 0, run = 0;
  for (var i = 0; i < window; i++) {
    if (active.contains(from.add(Duration(days: i)))) {
      run = 0;
    } else {
      run++;
      if (run > longest) longest = run;
    }
  }
  final newestActivity = last(activityDays);
  final activities = newestActivity == null
      ? 'Activities(None)'
      : 'Activities(Last:${date(newestActivity)},DaysAgo:${ago(newestActivity)},'
            'ActiveDays$window:${active.length}/$window,LongestGap:${longest}d)';

  final parts = [
    activities,
    metric('HRV', hrvDays),
    metric('Sleep', sleepDays),
    metric('Daily', dailyDays),
  ];
  return '[DataStatus:${parts.join(',')}'
      '${gaps.isEmpty ? '' : ',Gaps:${gaps.join('/')}'}'
      ',MissingRecord:Unknown]';
}
