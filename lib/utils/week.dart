// Week arithmetic that follows the "calendar week start" setting.

/// The first day (midnight) of the week containing [d].
DateTime weekStartOf(DateTime d, {bool mondayFirst = true}) => DateTime(
  d.year,
  d.month,
  d.day - (mondayFirst ? d.weekday - 1 : d.weekday % 7),
);

/// 0-based position of [d] within its week.
int weekdayIndex(DateTime d, {bool mondayFirst = true}) =>
    mondayFirst ? d.weekday - 1 : d.weekday % 7;

/// Single-letter weekday headings in display order.
List<String> weekdayInitials({bool mondayFirst = true}) => mondayFirst
    ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
    : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

/// ISO-8601 week number of the week that starts on [weekStart]. A Sunday-first
/// week is numbered like the ISO week of the Monday inside it.
int isoWeekNumber(DateTime weekStart, {bool mondayFirst = true}) {
  final monday = mondayFirst
      ? weekStart
      : DateTime.utc(weekStart.year, weekStart.month, weekStart.day + 1);
  final day = DateTime.utc(monday.year, monday.month, monday.day);
  final thursday = day.add(Duration(days: 4 - day.weekday));
  return (thursday.difference(DateTime.utc(thursday.year)).inDays / 7).floor() +
      1;
}
