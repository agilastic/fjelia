class CalendarActivity {
  const CalendarActivity({
    required this.date,
    required this.sport,
    required this.title,
    required this.completed,
    this.phase,
  });
  final DateTime date;
  final String sport, title;
  final bool completed;
  final String? phase;
}
