import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/providers/day_data_provider.dart';

void main() {
  test('starts on the first available record without earlier zero points', () {
    final first = DateTime(2026, 9, 1);
    final points = buildTrainingFormSeries(
      dailyLoads: {first: 100},
      through: DateTime(2026, 9, 3),
    );
    expect(points.map((p) => p.date), [
      first,
      DateTime(2026, 9, 2),
      DateTime(2026, 9, 3),
    ]);
    expect(points.first.ctl, closeTo(100 * 2 / 43, 1e-10));
    expect(points.first.atl, 25);
    expect(points.last.load, 0);
    expect(points.last.ctl, lessThan(points.first.ctl));
    expect(points.last.atl, lessThan(points.first.atl));
    expect(points.last.historyStart, first);
    expect(points.last.historyDays, 3);
  });

  test('older training warms the displayed 60 days without restarting them', () {
    final points = buildTrainingFormSeries(
      dailyLoads: {for (var i = 0; i < 365; i++) DateTime(2026, 1, 1 + i): 100},
      through: DateTime(2026, 12, 31),
    );
    final visible = points.sublist(points.length - 60);
    expect(visible, hasLength(60));
    expect(visible.first.ctl, greaterThan(99.99));
    expect(visible.first.atl, greaterThan(99.99));
    expect(points.last.historyDays, 365);
    // Closed-form response to a constant load, independent of display slicing.
    expect(points.last.ctl, closeTo(100 * (1 - math.pow(41 / 43, 365)), 1e-9));
  });

  test('a long break decays the baseline across every intervening day', () {
    final points = buildTrainingFormSeries(
      dailyLoads: {DateTime(2026, 1, 1): 1000},
      through: DateTime(2026, 8, 1),
    );
    expect(points, hasLength(213));
    expect(points.last.load, 0);
    expect(points.last.ctl, greaterThan(0));
    expect(points.last.ctl, lessThan(1));
    expect(points.last.atl, lessThan(points.last.ctl));
    expect(points.last.historyDays, 213);
  });

  test('preserves a real high-load day rather than hiding the spike', () {
    final points = buildTrainingFormSeries(
      dailyLoads: {DateTime(2026, 9, 1): 100, DateTime(2026, 9, 2): 3000},
      through: DateTime(2026, 9, 2),
    );
    expect(points.last.load, 3000);
    expect(points.last.atl, greaterThan(750));
    expect(points.last.tsb, lessThan(-600));
  });

  test('empty, invalid and future-only records do not invent a history', () {
    for (final loads in <Map<DateTime, double>>[
      {},
      {DateTime(2026, 9, 1): double.nan},
      {DateTime(2026, 9, 1): double.infinity},
      {DateTime(2026, 9, 1): -5},
      {DateTime(2026, 9, 3): 100},
    ]) {
      expect(
        buildTrainingFormSeries(
          dailyLoads: loads,
          through: DateTime(2026, 9, 2),
        ),
        isEmpty,
      );
    }
  });

  test('sorts records and combines multiple loads on one calendar day', () {
    final points = buildTrainingFormSeries(
      dailyLoads: {
        DateTime(2026, 9, 3): 70,
        DateTime(2026, 9, 1, 18): 40,
        DateTime(2026, 9, 1, 7): 60,
        DateTime(2026, 9, 5): 900,
      },
      through: DateTime(2026, 9, 3),
    );
    expect(points.map((p) => p.load), [100, 0, 70]);
    expect(points.first.date, DateTime(2026, 9, 1));
    expect(points.last.date, DateTime(2026, 9, 3));
  });

  test('spring and autumn clock changes keep one point per calendar day', () {
    for (final month in [3, 10]) {
      final points = buildTrainingFormSeries(
        dailyLoads: {DateTime(2026, month, 1): 100},
        through: DateTime(2026, month + 1, 1),
      );
      expect(points.map((p) => p.date).toSet(), hasLength(32));
      expect(points.last.date, DateTime(2026, month + 1, 1));
      expect(points.every((p) => p.date.hour == 0), isTrue);
      expect(points.last.historyDays, 32);
    }
  });
}
