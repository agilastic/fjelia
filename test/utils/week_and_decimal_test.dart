import 'package:flutter_test/flutter_test.dart';

import 'package:fjelia/utils/decimal.dart';
import 'package:fjelia/utils/week.dart';

void main() {
  group('parseDecimal', () {
    test('accepts decimal comma and point', () {
      expect(parseDecimal('21,1'), 21.1);
      expect(parseDecimal('21.1'), 21.1);
      expect(parseDecimal(' 42,195 '), 42.195);
      expect(parseDecimal('10'), 10);
    });
    test('handles thousands separators', () {
      expect(parseDecimal('1.234,5'), 1234.5);
      expect(parseDecimal('1,234.5'), 1234.5);
    });
    test('rejects empty and garbage', () {
      expect(parseDecimal(null), isNull);
      expect(parseDecimal(''), isNull);
      expect(parseDecimal('abc'), isNull);
    });
  });

  group('week start', () {
    // Wednesday 21 October 2026.
    final wed = DateTime(2026, 10, 21);
    test('Monday-first', () {
      expect(weekStartOf(wed), DateTime(2026, 10, 19));
      expect(weekdayIndex(wed), 2);
      expect(weekdayIndex(DateTime(2026, 10, 25)), 6); // Sunday last
      expect(weekdayInitials().first, 'M');
    });
    test('Sunday-first', () {
      expect(weekStartOf(wed, mondayFirst: false), DateTime(2026, 10, 18));
      expect(weekdayIndex(DateTime(2026, 10, 25), mondayFirst: false), 0);
      expect(weekStartOf(DateTime(2026, 10, 25), mondayFirst: false),
          DateTime(2026, 10, 25));
      expect(weekdayInitials(mondayFirst: false).first, 'S');
    });
    test('week numbers follow ISO for the Monday inside the week', () {
      expect(isoWeekNumber(DateTime(2026, 10, 19)), 43);
      expect(isoWeekNumber(DateTime(2026, 10, 18), mondayFirst: false), 43);
      expect(isoWeekNumber(DateTime(2026, 10, 25), mondayFirst: false), 44);
    });
  });
}
