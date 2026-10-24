import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'day_data_provider.dart';

final healthMonitorTrendsProvider =
    Provider.family<({double? rhr, double? hrv}), DateTime>((ref, date) {
      final current = ref.watch(hrvForDateProvider(date)).valueOrNull;
      final history = ref.watch(hrvRangeProvider(15)).valueOrNull ?? [];
      final before = DateTime(date.year, date.month, date.day);
      double? delta(bool hrv, double? value) {
        if (value == null) return null;
        final values = [
          for (final row in history)
            if (row.date.isBefore(before))
              if ((hrv ? row.hrvLastNight : row.restingHeartRate?.toDouble())
                  case final double reading)
                reading,
        ];
        if (values.isEmpty) return null;
        return value - values.reduce((a, b) => a + b) / values.length;
      }

      return (
        rhr: delta(false, current?.restingHeartRate?.toDouble()),
        hrv: delta(true, current?.hrvLastNight),
      );
    });
