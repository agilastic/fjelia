import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_metric.dart';
import '../models/metric_range_alert.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';

final healthMonitorAlertsProvider =
    FutureProvider.family<Set<HealthMetric>, DateTime>((ref, date) async {
      ref.watch(syncStatusListenerProvider);
      final current = ref.watch(hrvForDateProvider(date)).valueOrNull;
      final db = ref.watch(databaseProvider);
      final end = DateTime(date.year, date.month, date.day);
      final start = DateTime(end.year, end.month, end.day - 14);
      final history =
          await (db.select(db.hrvRecords)..where(
                (t) =>
                    t.date.isBiggerOrEqualValue(start) &
                    t.date.isSmallerThanValue(end),
              ))
              .get();
      final alerts = <HealthMetric>{};
      void check(HealthMetric metric, num? value, Iterable<num?> readings) {
        if (outsideExpandedMetricRange(
          value,
          readings.whereType<num>(),
          direction: metricAlertDirection(metric),
        )) {
          alerts.add(metric);
        }
      }

      check(
        HealthMetric.rhr,
        current?.restingHeartRate,
        history.map((r) => r.restingHeartRate),
      );
      check(
        HealthMetric.hrv,
        current?.hrvLastNight,
        history.map((r) => r.hrvLastNight),
      );
      check(HealthMetric.spo2, current?.spo2, history.map((r) => r.spo2));
      check(
        HealthMetric.respiration,
        current?.respirationRate,
        history.map((r) => r.respirationRate),
      );
      check(
        HealthMetric.stress,
        current?.stressLevel,
        history.map((r) => r.stressLevel),
      );
      check(
        HealthMetric.skinTemperature,
        current?.skinTempDelta,
        history.map((r) => r.skinTempDelta),
      );
      return alerts;
    });
