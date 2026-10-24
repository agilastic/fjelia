import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../services/lt1_drift_service.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';
import 'hr_zones_provider.dart';

final lt1DriftProvider =
    StateNotifierProvider<Lt1DriftNotifier, AsyncValue<Lt1DriftResult?>>(
      (ref) => Lt1DriftNotifier(ref),
    );

class Lt1DriftNotifier extends StateNotifier<AsyncValue<Lt1DriftResult?>> {
  Lt1DriftNotifier(this._ref) : super(const AsyncLoading()) {
    _load();
  }

  final Ref _ref;

  /// Minimum steady-state duration for a drift test.
  static const minDurationSec = 40 * 60;

  Future<void> _load() async {
    state = AsyncData(await Lt1DriftService.load());
  }

  Future<void> clear() async {
    await Lt1DriftService.clear();
    state = const AsyncData(null);
  }

  /// Runs the HR-drift test on [activity]; returns an error message or null.
  Future<String?> calculate(ActivityRecord activity) async {
    final metrics = activity.metricsJson;
    final result = metrics == null
        ? null
        : Lt1DriftService.calculate(metrics, activity.activityId);
    if (result == null) {
      return 'Not enough HR data — activity must be ≥ '
          '${minDurationSec ~/ 60} min with HR signal';
    }
    await Lt1DriftService.save(result);
    state = AsyncData(result);
    await _ref
        .read(databaseProvider)
        .upsertThresholdRecord(
          date: activity.startDate,
          activityId: activity.activityId,
          source: 'drift',
          lt1Bpm: result.lt1,
        );
    await _ref.read(hrZonesProvider.notifier).applyLt1Ceiling(result.lt1);
    _ref.invalidate(thresholdHistoryProvider);
    return null;
  }
}
