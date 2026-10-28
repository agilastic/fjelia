import 'package:intl/intl.dart';

/// Number formatting in the app language (decimal comma or point), without
/// thousands grouping so "1500 m" stays "1500 m". `parseDecimal` reads both
/// separators back.
extension LocalizedNumber on num {
  String fixed(int digits) => isFinite
      ? NumberFormat(
          digits == 0 ? '0' : '0.${'0' * digits}',
          Intl.defaultLocale,
        ).format(this)
      : '—';
}
