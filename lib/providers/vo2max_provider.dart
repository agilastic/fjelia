import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../services/vo2max_service.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';

final vo2MaxProvider =
    StateNotifierProvider<Vo2MaxNotifier, AsyncValue<Vo2MaxResult?>>(
      (ref) => Vo2MaxNotifier(ref),
    );

class Vo2MaxNotifier extends StateNotifier<AsyncValue<Vo2MaxResult?>> {
  Vo2MaxNotifier(this._ref) : super(const AsyncLoading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    state = AsyncData(await Vo2MaxService.load());
  }

  Future<void> clear() async {
    await Vo2MaxService.clear();
    state = const AsyncData(null);
  }

  /// 5-min max test; returns an error message or null.
  Future<String?> calculate(ActivityRecord activity) async {
    final metrics = activity.metricsJson;
    final result = metrics == null
        ? null
        : Vo2MaxService.calculate(metrics, activity.activityId);
    if (result == null) {
      return 'Could not extract pace — check activity has speed data';
    }
    await Vo2MaxService.save(result);
    state = AsyncData(result);
    await _ref
        .read(databaseProvider)
        .upsertThresholdRecord(
          date: activity.startDate,
          activityId: activity.activityId,
          source: 'max5',
          vo2PaceSec: result.paceSec,
        );
    _ref.invalidate(thresholdHistoryProvider);
    return null;
  }
}
