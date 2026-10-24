import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../db/database.dart';

/// Exports every activity with its heat and weather context as CSV.
class ActivityExportService {
  ActivityExportService(this._db);

  final AppDatabase _db;

  Future<File> exportActivitiesCsv() async {
    final activities = await _db.select(_db.activityRecords).get();
    final heat = await _db.select(_db.heatWorkoutContexts).get();
    final weather = await _db.select(_db.weatherSnapshotRecords).get();
    final heatById = {for (final h in heat) h.activityId: h};
    final weatherByKey = {for (final w in weather) w.cacheKey: w};

    String s(Object? v) => v == null ? '' : v.toString();
    String b(bool? v) => v == null ? '' : (v ? 'true' : 'false');

    final rows = <List<String>>[
      const [
        'activity_id', 'name', 'type', 'start_date_iso', 'duration_seconds',
        'distance_meters', 'avg_heart_rate', 'max_heart_rate', 'training_load',
        'avg_watts', 'total_elevation_m', 'hr_zones_json', 'gpx_json',
        'metrics_json', 'source', 'planned_workout_name',
        'planned_duration_seconds', 'planned_distance_meters',
        'planned_steps_json', 'heat_is_outdoor', 'heat_qualifies',
        'heat_duration_minutes', 'heat_temperature_c', 'heat_humidity_pct',
        'heat_pressure_hpa', 'heat_wet_bulb_c', 'heat_score_before',
        'heat_score_after', 'heat_weather_cache_key', 'heat_raw_json',
        'weather_source', 'weather_observed_at_iso', 'weather_latitude',
        'weather_longitude', 'weather_temperature_c', 'weather_humidity_pct',
        'weather_pressure_hpa', 'weather_wet_bulb_c', 'weather_raw_json',
      ],
    ];

    for (final a in activities) {
      final h = heatById[a.activityId];
      final w = h?.weatherCacheKey != null ? weatherByKey[h!.weatherCacheKey] : null;
      rows.add([
        a.activityId,
        a.name,
        a.type,
        a.startDate.toIso8601String(),
        s(a.durationSeconds),
        s(a.distanceMeters),
        s(a.avgHeartRate),
        s(a.maxHeartRate),
        s(a.trainingLoad),
        s(a.avgWatts),
        s(a.totalElevation),
        s(a.hrZonesJson),
        s(a.gpxJson),
        s(a.metricsJson),
        s(a.source),
        s(a.plannedWorkoutName),
        s(a.plannedDurationSeconds),
        s(a.plannedDistanceMeters),
        s(a.plannedStepsJson),
        b(h?.isOutdoor),
        b(h?.qualifies),
        s(h?.durationMinutes),
        s(h?.temperatureC),
        s(h?.humidityPct),
        s(h?.pressureHpa),
        s(h?.wetBulbC),
        s(h?.scoreBefore),
        s(h?.scoreAfter),
        s(h?.weatherCacheKey),
        s(h?.rawJson),
        s(w?.source),
        w?.observedAt.toIso8601String() ?? '',
        s(w?.latitude),
        s(w?.longitude),
        s(w?.temperatureC),
        s(w?.humidityPct),
        s(w?.pressureHpa),
        s(w?.wetBulbC),
        s(w?.rawJson),
      ]);
    }

    final csv = rows.map((r) => r.map(_escapeCsv).join(',')).join('\n');
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/fjelia_activities_$stamp.csv');
    return file.writeAsBytes(utf8.encode(csv));
  }

  String _escapeCsv(String value) =>
      '"${value.replaceAll('"', '""')}"';
}
