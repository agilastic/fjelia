import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/models/metric_chart_data.dart';
import 'package:fjelia/models/chart_point.dart';
import 'package:fjelia/models/health_metric.dart';

void main() {
  test(
    'physiological charts fit small changes and preserve negative skin values',
    () {
      final date = DateTime(2026, 10, 20);
      final rhr = MetricChartRange.forPoints(HealthMetric.rhr, [
        ChartPoint(date, 47),
        ChartPoint(date, 49),
      ]);
      expect(rhr.minimum, 46);
      expect(rhr.maximum, 50);
      final skin = MetricChartRange.forPoints(HealthMetric.skinTemperature, [
        ChartPoint(date, -.2),
        ChartPoint(date, .1),
      ]);
      expect(skin.minimum, lessThan(-.2));
      expect(skin.maximum, greaterThan(.1));
      final same = MetricChartRange.forPoints(HealthMetric.spo2, [
        ChartPoint(date, 100),
        ChartPoint(date, 100),
      ]);
      expect(same.maximum, 100);
      expect(same.minimum, lessThan(100));
    },
  );
  test('changing window recalculates values, average and axis range', () {
    final date = DateTime(2026, 10, 30);
    final points = [
      ChartPoint(DateTime(2026, 10, 5), 80),
      ChartPoint(date, 47),
    ];
    final short = MetricHistoryWindow(points, HealthMetric.rhr, 14, 0, date);
    final long = MetricHistoryWindow(points, HealthMetric.rhr, 30, 0, date);
    expect(short.points.length, 1);
    expect(short.average, 47);
    expect(long.points.length, 2);
    expect(long.average, 63.5);
    expect(long.range.maximum, greaterThan(short.range.maximum));
    expect(
      MetricHistoryWindow([], HealthMetric.rhr, 14, 0, date).average,
      isNull,
    );
  });
}
