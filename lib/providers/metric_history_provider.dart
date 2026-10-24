import '../models/metric_chart_data.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chart_point.dart';
import '../models/health_metric.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';

final metricHistoryProvider =
    FutureProvider.family<List<ChartPoint>, HealthMetric>((ref, metric) async {
      ref.watch(syncStatusListenerProvider);
      final db = ref.watch(databaseProvider);
      if (metric.isBody) {
        final rows = await db.getRenphoRange(3650);
        return [
          for (final r in rows)
            if ((switch (metric) {
                  HealthMetric.weight => r.weight,
                  HealthMetric.bodyFat => r.bodyFat,
                  HealthMetric.muscle => r.muscleMass,
                  HealthMetric.bmi => r.bmi,
                  HealthMetric.water => r.bodyWater,
                  HealthMetric.protein => r.protein,
                  HealthMetric.visceralFat => r.visceralFat,
                  HealthMetric.bmr => r.bmr,
                  HealthMetric.bone => r.boneMass,
                  HealthMetric.waist => r.waistCm,
                  _ => null,
                })
                case final double v)
              ChartPoint(r.measuredAt, v),
        ];
      }
      if (metric == HealthMetric.sleep) {
        final rows = await db.getSleepRange(365);
        return [
          for (final r in rows) ChartPoint(r.date, r.totalSleepSeconds / 3600),
        ];
      }
      if (metric == HealthMetric.steps) {
        final rows = await db.getWellnessRange(365);
        return [
          for (final r in rows)
            if (r.steps != null) ChartPoint(r.date, r.steps!.toDouble()),
        ];
      }
      final rows = await db.getHrvRange(365);
      return [
        for (final r in rows)
          if ((switch (metric) {
                HealthMetric.hrv => r.hrvLastNight,
                HealthMetric.rhr => r.restingHeartRate?.toDouble(),
                HealthMetric.spo2 => r.spo2,
                HealthMetric.respiration => r.respirationRate,
                HealthMetric.stress => r.stressLevel,
                HealthMetric.skinTemperature => r.skinTempDelta,
                _ => null,
              })
              case final double v)
            ChartPoint(r.date, v),
      ];
    });

final metricHistoryWindowProvider =
    FutureProvider.family<
      MetricHistoryWindow,
      ({HealthMetric metric, int days, int offset, DateTime selected})
    >((ref, request) async {
      final history = await ref.watch(
        metricHistoryProvider(request.metric).future,
      );
      return MetricHistoryWindow(
        history,
        request.metric,
        request.days,
        request.offset,
        request.selected,
      );
    });
