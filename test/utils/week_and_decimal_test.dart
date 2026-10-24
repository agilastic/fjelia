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
    test('copes with the spaces and separators other keyboards bring', () {
      expect(parseDecimal('42\u066B2'), 42.2); // Arabic decimal separator
      expect(parseDecimal('42\uFF0C2'), 42.2); // full-width comma
      expect(parseDecimal('42\uFF0E2'), 42.2); // full-width point
      expect(parseDecimal('1\u202F234,5'), 1234.5); // narrow no-break space
      expect(parseDecimal('42\u00A0'), 42);
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
      expect(
        weekStartOf(DateTime(2026, 10, 25), mondayFirst: false),
        DateTime(2026, 10, 25),
      );
      expect(weekdayInitials(mondayFirst: false).first, 'S');
    });
    test('week numbers follow ISO for the Monday inside the week', () {
      expect(isoWeekNumber(DateTime(2026, 10, 19)), 43);
      expect(isoWeekNumber(DateTime(2026, 10, 18), mondayFirst: false), 43);
      expect(isoWeekNumber(DateTime(2026, 10, 25), mondayFirst: false), 44);
    });
  });
}
