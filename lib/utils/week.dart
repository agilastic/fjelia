import 'package:intl/intl.dart';

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
List<String> weekdayInitials({bool mondayFirst = true}) {
  // In the app's language (D for Dienstag); 1 January 2024 is a Monday.
  final f = DateFormat('EEEEE');
  final days = [for (var i = 0; i < 7; i++) f.format(DateTime(2024, 1, 1 + i))];
  return mondayFirst ? days : [days[6], ...days.take(6)];
}

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
