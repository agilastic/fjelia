import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../models/health_metric.dart';
import '../models/waist_ratios.dart';
import 'ai_coach_provider.dart';
import 'database_provider.dart';
import 'metric_history_provider.dart';
import 'user_profile_provider.dart';

/// Every waist measurement, oldest first.
final waistMeasurementsProvider = FutureProvider<List<WaistMeasurement>>(
  (ref) => ref.watch(databaseProvider).getWaistMeasurements(),
);

WaistPoint waistPoint(WaistMeasurement m) =>
    (at: m.measuredAt, waistCm: m.waistCm, hipCm: m.hipCm);

final waistActionsProvider = Provider<WaistActions>(WaistActions.new);

/// Keeps the history and the waist in Settings the same: the newest
/// measurement is the profile's waist, and a waist typed into Settings is a
/// measurement of today.
class WaistActions {
  WaistActions(this.ref);
  final Ref ref;

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> add(DateTime at, double waistCm, {double? hipCm}) async {
    if (waistCm < 20 || waistCm > 300) {
      throw StateError('Enter a waist between 20 and 300 cm.');
    }
    if (hipCm != null && (hipCm < 20 || hipCm > 300)) {
      throw StateError('Enter a hip between 20 and 300 cm.');
    }
    await _db.insertWaistMeasurement(
      WaistMeasurementsCompanion.insert(
        measuredAt: at,
        waistCm: waistCm,
        hipCm: Value(hipCm),
      ),
    );
    await _syncProfile();
    _changed();
  }

  Future<void> delete(int id) async {
    await _db.deleteWaistMeasurement(id);
    await _syncProfile();
    _changed();
  }

  /// From the profile editor: the profile is already saved.
  Future<void> fromProfile(double waistCm) async {
    await _db.putWaistFromProfile(DateTime.now(), waistCm);
    _changed();
  }

  /// The newest measurement into the profile. With no measurement left the
  /// profile keeps what it has.
  Future<void> _syncProfile() async {
    final all = await _db.getWaistMeasurements();
    if (all.isEmpty) return;
    final profile = await ref.read(userProfileProvider.future);
    if (profile.waistCm == all.last.waistCm) return;
    await ref
        .read(userProfileProvider.notifier)
        .save(profile.copyWith(waistCm: all.last.waistCm));
  }

  void _changed() {
    ref.invalidate(waistMeasurementsProvider);
    ref.invalidate(metricHistoryProvider(HealthMetric.waist));
    ref.read(toonCacheProvider.notifier).invalidate();
  }
}
