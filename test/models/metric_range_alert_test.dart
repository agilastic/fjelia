import 'package:fjelia/models/health_metric.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/models/metric_range_alert.dart';

void main() {
  test('directional metrics flag only unfavorable deviations', () {
    for (final metric in [HealthMetric.stress, HealthMetric.rhr]) {
      final direction = metricAlertDirection(metric);
      expect(
        outsideExpandedMetricRange(73.6, [60, 70], direction: direction),
        isTrue,
      );
      expect(
        outsideExpandedMetricRange(56.9, [60, 70], direction: direction),
        isFalse,
      );
    }
    for (final metric in [HealthMetric.spo2, HealthMetric.hrv]) {
      final direction = metricAlertDirection(metric);
      expect(
        outsideExpandedMetricRange(56.9, [60, 70], direction: direction),
        isTrue,
      );
      expect(
        outsideExpandedMetricRange(73.6, [60, 70], direction: direction),
        isFalse,
      );
    }
    for (final metric in [HealthMetric.steps, HealthMetric.sleep]) {
      expect(
        outsideExpandedMetricRange(1000, [
          10,
          20,
        ], direction: metricAlertDirection(metric)),
        isFalse,
      );
      expect(
        outsideExpandedMetricRange(0, [
          10,
          20,
        ], direction: metricAlertDirection(metric)),
        isFalse,
      );
    }
    expect(
      metricAlertDirection(HealthMetric.respiration),
      MetricAlertDirection.either,
    );
    expect(
      metricAlertDirection(HealthMetric.skinTemperature),
      MetricAlertDirection.either,
    );
  });
  test('flags values more than five percent outside historical min/max', () {
    expect(outsideExpandedMetricRange(57, [60, 70]), isFalse);
    expect(outsideExpandedMetricRange(73.5, [60, 70]), isFalse);
    expect(outsideExpandedMetricRange(56.9, [60, 70]), isTrue);
    expect(outsideExpandedMetricRange(73.6, [60, 70]), isTrue);
    expect(outsideExpandedMetricRange(65, [60, 70]), isFalse);
  });
  test('negative ranges expand outward and missing data does not alert', () {
    expect(outsideExpandedMetricRange(-.21, [-.2, -.1]), isFalse);
    expect(outsideExpandedMetricRange(-.22, [-.2, -.1]), isTrue);
    expect(outsideExpandedMetricRange(-.09, [-.2, -.1]), isTrue);
    expect(outsideExpandedMetricRange(null, [60, 70]), isFalse);
    expect(outsideExpandedMetricRange(70, []), isFalse);
    expect(outsideExpandedMetricRange(double.nan, [60]), isFalse);
  });
}
