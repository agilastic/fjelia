import 'health_metric.dart';

import 'dart:math' as math;

enum MetricAlertDirection { higher, lower, either, none }

MetricAlertDirection metricAlertDirection(HealthMetric metric) =>
    switch (metric) {
      HealthMetric.stress || HealthMetric.rhr => MetricAlertDirection.higher,
      HealthMetric.spo2 || HealthMetric.hrv => MetricAlertDirection.lower,
      HealthMetric.respiration ||
      HealthMetric.skinTemperature => MetricAlertDirection.either,
      _ => MetricAlertDirection.none,
    };

/// Five percent beyond the previous range, including negative-valued metrics.
bool outsideExpandedMetricRange(
  num? current,
  Iterable<num> history, {
  MetricAlertDirection direction = MetricAlertDirection.either,
}) {
  if (direction == MetricAlertDirection.none) return false;
  if (current == null || !current.isFinite) return false;
  final values = history
      .where((v) => v.isFinite)
      .map((v) => v.toDouble())
      .toList();
  if (values.isEmpty) return false;
  final low = values.reduce(math.min), high = values.reduce(math.max);
  final lower = low - low.abs() * .05;
  final upper = high + high.abs() * .05;
  const epsilon = 1e-9;
  return switch (direction) {
    MetricAlertDirection.higher => current > upper + epsilon,
    MetricAlertDirection.lower => current < lower - epsilon,
    MetricAlertDirection.either =>
      current < lower - epsilon || current > upper + epsilon,
    MetricAlertDirection.none => false,
  };
}
