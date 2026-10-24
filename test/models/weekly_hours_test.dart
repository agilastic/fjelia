import 'package:fjelia/models/weekly_hours.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Saturday 24 October 2026; the week began on Monday 19 October.
  final now = DateTime(2026, 10, 24);

  test('averages the full weeks and leaves the current one out', () {
    final hours = WeeklyHours.of(
      [
        // Current week: ignored.
        (DateTime(2026, 10, 20), 5 * 3600),
        // Two full weeks before it: 6 h and 12 h.
        (DateTime(2026, 10, 14), 6 * 3600),
        (DateTime(2026, 10, 7), 4 * 3600),
        (DateTime(2026, 10, 8), 8 * 3600),
      ],
      now: now,
      mondayFirst: true,
    )!;
    expect(hours.peak, 12);
    expect(hours.average, closeTo(18 / 12, 1e-9));
  });

  test('older than the window does not count, nothing gives null', () {
    expect(
      WeeklyHours.of(
        [(DateTime(2026, 1, 5), 3600)],
        now: now,
        mondayFirst: true,
      ),
      isNull,
    );
    expect(WeeklyHours.of(const [], now: now, mondayFirst: true), isNull);
  });

  test('a target well above the busiest week is flagged', () {
    const hours = WeeklyHours(average: 9, peak: 15);
    expect(hours.isFarAbove(25), isTrue);
    expect(hours.isFarAbove(20), isFalse);
    expect(hours.isFarAbove(10), isFalse);
  });
}
