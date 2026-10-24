import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../services/lt2_tt_service.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';
import 'hr_zones_provider.dart';
import 'lt1_provider.dart';
import 'planner_providers.dart';

final lt2TtProvider =
    StateNotifierProvider<Lt2TtNotifier, AsyncValue<Lt2TtResult?>>(
      (ref) => Lt2TtNotifier(ref),
    );

class Lt2TtNotifier extends StateNotifier<AsyncValue<Lt2TtResult?>> {
  Lt2TtNotifier(this._ref) : super(const AsyncLoading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    state = AsyncData(await Lt2TtService.load());
  }

  Future<void> clear() async {
    await Lt2TtService.clear();
    state = const AsyncData(null);
  }

  /// 30-min time-trial test; returns an error message or null.
  Future<String?> calculate(
    ActivityRecord activity, {
    int? warmupMinutes,
  }) async {
    final metrics = activity.metricsJson;
    final result = metrics == null
        ? null
        : Lt2TtService.calculate(
            metrics,
            activity.activityId,
            warmupMinutes: warmupMinutes,
          );
    if (result == null) {
      return 'Could not find HR at 10 min and 30 min — make sure the '
          'activity is at least 30 min after warm-up';
    }
    await Lt2TtService.save(result);
    state = AsyncData(result);
    await _ref
        .read(databaseProvider)
        .upsertThresholdRecord(
          date: activity.startDate,
          activityId: activity.activityId,
          source: 'tt',
          lt2Bpm: result.lt2,
          lt2PaceSec: result.paceSec,
        );
    final zones = _ref.read(hrZonesProvider.notifier);
    await zones.applyFromLt2Hr(result.lt2);
    final lt1 = _ref.read(lt1Provider);
    if (lt1 != null) await zones.applyLt1Ceiling(lt1.bpm);
    // The app-detected threshold now takes precedence over Garmin's LTHR.
    final thresholds = _ref.read(athleteThresholdsServiceProvider);
    if (!((await thresholds.get())?.coachLocked ?? false)) {
      await thresholds.save(
        AthleteThresholdsCompanion(
          thresholdHrBpm: Value(result.lt2),
          runHrZonesJson: Value(
            jsonEncode(_ref.read(hrZonesProvider).running.bounds),
          ),
          lastUpdatedAt: Value(DateTime.now()),
        ),
      );
    }
    _ref.invalidate(thresholdHistoryProvider);
    return null;
  }
}
