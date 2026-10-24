import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';

/// The single athlete's (`self`) threshold row: HR, pace, FTP and zones.
class AthleteThresholdsService {
  AthleteThresholdsService(this._db);

  final AppDatabase _db;

  static const _self = 'self';

  Future<AthleteThreshold?> get() {
    return (_db.select(_db.athleteThresholds)
          ..where((t) => t.athleteId.equals(_self)))
        .getSingleOrNull();
  }

  Future<void> save(AthleteThresholdsCompanion entry) async {
    await _db
        .into(_db.athleteThresholds)
        .insertOnConflictUpdate(entry.copyWith(athleteId: const Value(_self)));
  }

  /// HR zone floors (Z1–Z5) for a sport, or null if not configured.
  List<int>? hrZoneFloorsFor(AthleteThreshold t, String sport) {
    final s = sport.toLowerCase();
    final json = s.contains('cycl') || s.contains('bike')
        ? t.bikeHrZonesJson
        : s.contains('swim')
            ? t.swimHrZonesJson
            : t.runHrZonesJson;
    if (json == null) return null;
    return (jsonDecode(json) as List).map((e) => (e as num).toInt()).toList();
  }

  /// Creates the row from the latest detected thresholds when none exists.
  Future<void> seedFromExistingData({int? maxHr, List<int>? runZoneFloors}) async {
    if (await get() != null) return;
    final latest = await (_db.select(_db.thresholdRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .getSingleOrNull();
    final lt2Pace = latest?.lt2PaceSec;
    await _db.into(_db.athleteThresholds).insertOnConflictUpdate(
          AthleteThresholdsCompanion(
            athleteId: const Value(_self),
            thresholdHrBpm: Value(latest?.lt2Bpm),
            maxHrBpm: Value(maxHr),
            thresholdPaceMps: Value(
                lt2Pace != null && lt2Pace > 0 ? 1000.0 / lt2Pace : null),
            ftpWatts: Value(latest?.ftpWatts),
            runHrZonesJson: Value(
                runZoneFloors != null ? jsonEncode(runZoneFloors) : null),
            bikeHrZonesJson: Value(
                runZoneFloors != null ? jsonEncode(runZoneFloors) : null),
            lastUpdatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Records an estimated FTP from recent rides. Only changes of at least
  /// 3 % are proposed, and a coach-locked profile is left alone.
  Future<bool> proposeEftpUpdate(int estimatedFtp) async {
    final current = await get();
    if (current == null || current.coachLocked) return false;
    final ftp = current.ftpWatts?.toDouble() ?? 0.0;
    final estimate = estimatedFtp.toDouble();
    if (ftp > 0) {
      final delta = (estimate - ftp) / ftp;
      if (delta.abs() < 0.03) return false;
    }
    await save(AthleteThresholdsCompanion(
      estimatedFtp: Value(estimate),
      eFtpDelta: Value(ftp > 0 ? estimate - ftp : 0.0),
      lastUpdatedAt: Value(DateTime.now()),
    ));
    return true;
  }
}
