import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/models/chart_point.dart';
import 'package:fjelia/models/heart_rate_summary.dart';

void main() {
  test('dense workout sampling does not outweigh an hour of lower HR', () {
    final day = DateTime(2026, 10, 20);
    final points = [
      for (var minute = 0; minute < 60; minute++)
        ChartPoint(day.add(Duration(minutes: minute)), 60),
      for (var second = 0; second <= 600; second++)
        ChartPoint(day.add(Duration(minutes: 60, seconds: second)), 140),
    ];
    final stats = HeartRateStatistics.fromPoints(points);
    expect(
      points.fold(0.0, (sum, p) => sum + p.value) / points.length,
      greaterThan(130),
    );
    // One minute transitions from 60 to 140; the remaining intervals are constant.
    expect(stats.average, closeTo(72, 1e-9));
    expect(stats.coveredDuration, const Duration(minutes: 70));
    final summary = HeartRateDaySummary(points: points, activities: []);
    expect(summary.average, stats.average);
    expect(summary.peak, 140);
  });
  test('long gaps are excluded and isolated readings have no time average', () {
    final day = DateTime(2026, 10, 20);
    final stats = HeartRateStatistics.fromPoints([
      ChartPoint(day, 60),
      ChartPoint(day.add(const Duration(minutes: 2)), 60),
      ChartPoint(day.add(const Duration(hours: 12)), 140),
      ChartPoint(day.add(const Duration(hours: 12, minutes: 2)), 140),
    ]);
    expect(stats.average, 100);
    expect(stats.coveredDuration, const Duration(minutes: 4));
    expect(
      HeartRateStatistics.fromPoints([ChartPoint(day, 60)]).average,
      isNull,
    );
    expect(
      HeartRateStatistics.fromPoints([ChartPoint(day, 60), ChartPoint(day, 60)])
          .average,
      isNull,
    );
    expect(HeartRateStatistics.fromPoints([]).average, isNull);
  });
}
