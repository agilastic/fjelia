import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import 'hr_zone_history.dart';
import 'package:fjelia_core/services/hr_zone_model.dart';

/// Recomputes activities' time-in-zone from HR samples with the zones in
/// force on each workout's day (the zone history), so workouts from
/// different platforms are measured alike and a later zone change does not
/// rewrite an earlier workout. Samples come from the activity itself (Garmin) or from the
/// shared HR timeline within the activity's window (Polar, COROS, Apple
/// Health, …). Activities without any samples keep the device's split.
class ZoneRecalculationService {
  ZoneRecalculationService(this._db);

  final AppDatabase _db;

  /// Returns the number of activities updated.
  Future<int> recalculate({
    required HrZoneBook book,
    required DateTime since,
  }) async {
    final rows = await (_db.select(
      _db.activityRecords,
    )..where((t) => t.startDate.isBiggerOrEqualValue(since))).get();
    var updated = 0;
    for (final a in rows) {
      final t = a.type.toLowerCase();
      if (t.contains('swim')) continue; // wrist HR in water is unreliable
      final floors = book.forActivity(a.type, a.startDate);
      if (floors == null) continue;
      final activeSamples = {'ftms', 'manual_recording'}.contains(a.source);
      var zones = activeSamples
          ? zonePercentFromActiveSamples(
              a.metricsJson,
              floors,
              a.durationSeconds.toDouble(),
            )
          : zonePercentFromSamples(a.metricsJson, floors);
      if (zones == null && !activeSamples) {
        final hr = await _db.getHeartRateSamples(
          a.startDate,
          a.startDate.add(Duration(seconds: a.durationSeconds)),
        );
        // Prefer the activity's own platform when several recorded HR.
        final own = hr.where((s) => s.source == a.source).toList();
        final use = own.length >= 10 ? own : hr;
        zones = zonePercentFromSamples(
          jsonEncode([
            for (final s in use)
              {'hr': s.bpm, 't': s.measuredAt.millisecondsSinceEpoch},
          ]),
          floors,
        );
      }
      if (zones == null) continue;
      final json = jsonEncode(zones);
      if (json == a.hrZonesJson) continue;
      await (_db.update(_db.activityRecords)
            ..where((r) => r.activityId.equals(a.activityId)))
          .write(ActivityRecordsCompanion(hrZonesJson: Value(json)));
      updated++;
    }
    return updated;
  }
}
