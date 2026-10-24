import 'dart:math' as math;

import 'chart_point.dart';
import 'health_metric.dart';

class MetricChartRange {
  const MetricChartRange(this.minimum, this.maximum);
  final double minimum, maximum;
  factory MetricChartRange.forPoints(
    HealthMetric metric,
    List<ChartPoint> points,
  ) {
    final values = points.map((p) => p.value).where((v) => v.isFinite).toList();
    if (values.isEmpty) return const MetricChartRange(0, 1);
    final low = values.reduce(math.min), high = values.reduce(math.max);
    final floorPadding = switch (metric) {
      HealthMetric.skinTemperature => .1,
      HealthMetric.respiration => .5,
      HealthMetric.spo2 => .5,
      HealthMetric.steps => 100.0,
      HealthMetric.sleep => .25,
      _ => 1.0,
    };
    final padding = math.max(floorPadding, (high - low) * .15);
    var minimum = low - padding, maximum = high + padding;
    if (metric != HealthMetric.skinTemperature && low >= 0) {
      minimum = math.max(0, minimum);
    }
    if ([
          HealthMetric.spo2,
          HealthMetric.stress,
          HealthMetric.bodyFat,
          HealthMetric.water,
          HealthMetric.protein,
        ].contains(metric) &&
        high <= 100) {
      maximum = math.min(100, maximum);
    }
    return MetricChartRange(minimum, maximum);
  }
}

class MetricHistoryWindow {
  MetricHistoryWindow(
    List<ChartPoint> history,
    HealthMetric metric,
    int days,
    int offset,
    DateTime selected,
  ) {
    end = DateTime(selected.year, selected.month, selected.day + 1 - offset);
    start = DateTime(end.year, end.month, end.day - days);
    final sorted = history.where((p) => p.value.isFinite).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    points = sorted
        .where((p) => !p.at.isBefore(start) && p.at.isBefore(end))
        .toList();
    latest = sorted.where((p) => p.at.isBefore(end)).lastOrNull;
    average = mean(points);
    final baselineDays = metric == HealthMetric.hrv
        ? 7
        : metric == HealthMetric.rhr
        ? 30
        : null;
    baseline = mean(
      baselineDays == null
          ? sorted.where((p) => p.at.isBefore(end)).toList()
          : sorted
                .where(
                  (p) =>
                      !p.at.isBefore(
                        DateTime(end.year, end.month, end.day - baselineDays),
                      ) &&
                      p.at.isBefore(end),
                )
                .toList(),
    );
    range = MetricChartRange.forPoints(metric, points);
  }
  static double? mean(List<ChartPoint> points) => points.isEmpty
      ? null
      : points.fold(0.0, (sum, p) => sum + p.value) / points.length;
  late final DateTime start, end;
  late final List<ChartPoint> points;
  late final ChartPoint? latest;
  late final double? average, baseline;
  late final MetricChartRange range;
}
