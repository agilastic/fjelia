import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import 'database_provider.dart';

final ftpProvider = StateNotifierProvider<FtpNotifier, AsyncValue<FtpResult?>>(
  (ref) => FtpNotifier(ref),
);

class FtpResult {
  const FtpResult({
    required this.ftpWatts,
    required this.source,
    this.weightKg,
    this.estimatedFtp,
    required this.updatedAt,
  });

  final int ftpWatts;

  /// 'manual' or 'estimated'.
  final String source;
  final double? weightKg;
  final double? estimatedFtp;
  final DateTime updatedAt;

  double? get wattsPerKg =>
      weightKg == null || weightKg! <= 0 ? null : ftpWatts / weightKg!;

  /// Coggan zone floors (55/75/90/105/120 % FTP).
  List<int> get powerZoneFloors => _zoneFloors(ftpWatts);
}

List<int> _zoneFloors(int ftp) => [
  (ftp * 0.55).round(),
  (ftp * 0.75).round(),
  (ftp * 0.90).round(),
  (ftp * 1.05).round(),
  (ftp * 1.20).round(),
];

class FtpNotifier extends StateNotifier<AsyncValue<FtpResult?>> {
  FtpNotifier(this._ref) : super(const AsyncLoading()) {
    _load();
  }

  final Ref _ref;

  AppDatabase get _db => _ref.read(databaseProvider);

  Future<void> _load() async {
    try {
      final t = await (_db.select(
        _db.athleteThresholds,
      )..where((t) => t.athleteId.equals('self'))).getSingleOrNull();
      final manual = t?.ftpWatts;
      final estimated = t?.estimatedFtp;
      if (manual == null && estimated == null) {
        state = const AsyncData(null);
        return;
      }
      final watts = manual ?? estimated!.round();
      state = AsyncData(
        FtpResult(
          ftpWatts: watts,
          source: manual != null ? 'manual' : 'estimated',
          weightKg: await _latestWeight(),
          estimatedFtp: estimated,
          updatedAt: t?.lastUpdatedAt ?? DateTime.now(),
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<double?> _latestWeight() async {
    final rows = await _db.getRenphoRange(90);
    for (final r in rows.reversed) {
      if (r.weight != null) return r.weight;
    }
    return null;
  }

  Future<void> saveManual(int ftpWatts) async {
    await _db
        .into(_db.athleteThresholds)
        .insertOnConflictUpdate(
          AthleteThresholdsCompanion(
            athleteId: const Value('self'),
            ftpWatts: Value(ftpWatts),
            bikePowerZonesJson: Value(jsonEncode(_zoneFloors(ftpWatts))),
            lastUpdatedAt: Value(DateTime.now()),
          ),
        );
    await _db.insertFtpSnapshot(ftpWatts, 'ftp_manual');
    await _load();
  }

  /// FTP = 95 % of the best 20-min power from [activity].
  Future<void> saveFromActivity(
    double best20MinWatts,
    String source,
    DateTime date,
  ) async {
    final ftp = (best20MinWatts * 0.95).round();
    await _db
        .into(_db.athleteThresholds)
        .insertOnConflictUpdate(
          AthleteThresholdsCompanion(
            athleteId: const Value('self'),
            ftpWatts: Value(ftp),
            bikePowerZonesJson: Value(jsonEncode(_zoneFloors(ftp))),
            lastUpdatedAt: Value(DateTime.now()),
          ),
        );
    await _db.insertFtpSnapshot(ftp, source, date: date);
    await _load();
  }

  Future<void> clear() async {
    await _db
        .into(_db.athleteThresholds)
        .insertOnConflictUpdate(
          const AthleteThresholdsCompanion(
            athleteId: Value('self'),
            ftpWatts: Value(null),
            bikePowerZonesJson: Value(null),
          ),
        );
    state = const AsyncData(null);
  }
}
