import 'package:intl/intl.dart';

/// Number formatting in the app language (decimal comma or point), without
/// thousands grouping so "1500 m" stays "1500 m". `parseDecimal` reads both
/// separators back.
/// A planned duration: minutes up to an hour, hours and minutes above it.
/// 45 → "45 min", 60 → "60 min", 75 → "1 h 15 min", 120 → "2 h".
String planDuration(int minutes) {
  if (minutes <= 60) return '$minutes min';
  final h = minutes ~/ 60, m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}

extension LocalizedNumber on num {
  String fixed(int digits) => isFinite
      ? NumberFormat(
          digits == 0 ? '0' : '0.${'0' * digits}',
          Intl.defaultLocale,
        ).format(this)
      : '—';
}
