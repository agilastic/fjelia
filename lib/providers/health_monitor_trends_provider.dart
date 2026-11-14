import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import 'day_data_provider.dart';

/// Each Health Monitor value against its average of the prior two weeks.
/// A change smaller than the metric's day-to-day noise counts as 0 (steady).
typedef HealthTrends = ({
  double? rhr,
  double? hrv,
  double? spo2,
  double? resp,
  double? stress,
  double? skinTemp,
});

final healthMonitorTrendsProvider = Provider.family<HealthTrends, DateTime>((
  ref,
  date,
) {
  final current = ref.watch(hrvForDateProvider(date)).valueOrNull;
  final history = ref.watch(hrvRangeProvider(15)).valueOrNull ?? [];
  final before = DateTime(date.year, date.month, date.day);
  double? delta(double? Function(HrvRecord) read, {double noise = 0}) {
    final value = current == null ? null : read(current);
    if (value == null) return null;
    final values = [
      for (final row in history)
        if (row.date.isBefore(before))
          if (read(row) case final double reading) reading,
    ];
    if (values.isEmpty) return null;
    final change = value - values.reduce((a, b) => a + b) / values.length;
    return change.abs() < noise ? 0 : change;
  }

  return (
    rhr: delta((r) => r.restingHeartRate?.toDouble()),
    hrv: delta((r) => r.hrvLastNight),
    spo2: delta((r) => r.spo2, noise: 1),
    resp: delta((r) => r.respirationRate, noise: .5),
    stress: delta((r) => r.stressLevel, noise: 5),
    skinTemp: delta((r) => r.skinTempDelta, noise: .2),
  );
});
