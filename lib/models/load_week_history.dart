import 'dart:convert';

import 'package:fjelia_service_api/fjelia_service_api.dart';

import '../db/database.dart';
import '../utils/week.dart';
import '../services/hr_zone_model.dart';

/// Recorded activity totals for one calendar week. Missing zones are not zero
/// intensity: keep their activity count so the UI can show missing coverage.
class LoadWeekHistory {
  LoadWeekHistory(this.start);
  final DateTime start;
  final zoneMinutes = List<double>.filled(3, 0);
  double elevation = 0;
  int activities = 0;
  int activitiesWithZones = 0;
  int activitiesFromSamples = 0;
  double get classifiedMinutes => zoneMinutes.fold(0, (a, b) => a + b);
  double? get easyPercent =>
      classifiedMinutes > 0 ? 100 * zoneMinutes[0] / classifiedMinutes : null;
}

/// Twelve consecutive weeks, oldest first, using the athlete's calendar-week
/// setting and local activity dates. Stored zone1…zone5 values are percentages.
List<LoadWeekHistory> buildLoadWeekHistory({
  required DateTime through,
  required Iterable<ActivityRecord> activities,
  bool mondayFirst = true,
  List<int>? runningZones,
  List<int>? cyclingZones,
}) {
  final last = weekStartOf(through, mondayFirst: mondayFirst);
  final weeks = {
    for (var i = 11; i >= 0; i--)
      DateTime(last.year, last.month, last.day - i * 7): LoadWeekHistory(
        DateTime(last.year, last.month, last.day - i * 7),
      ),
  };
  for (final activity in activities) {
    final week =
        weeks[weekStartOf(
          activity.startDate.toLocal(),
          mondayFirst: mondayFirst,
        )];
    if (week == null) continue;
    week.activities++;
    final elevation = activity.totalElevation;
    if (elevation != null && elevation.isFinite && elevation > 0) {
      week.elevation += elevation;
    }
    if (activity.durationSeconds <= 0) continue;
    final zones = _percentages(activity.hrZonesJson);
    if (zones == null) {
      final type = activity.type.toLowerCase();
      final cycling =
          type.contains('cycl') ||
          type.contains('bik') ||
          type.contains('ride');
      final running =
          type.contains('run') ||
          type.contains('trail') ||
          type.contains('treadmill');
      final floors = cycling
          ? cyclingZones
          : running
          ? runningZones
          : null;
      if (floors == null) continue;
      final seconds = zoneSecondsFromSamples(activity.metricsJson, floors);
      if (seconds == null) continue;
      final total = seconds.fold<double>(0, (a, b) => a + b);
      final scale = total > activity.durationSeconds
          ? activity.durationSeconds / total
          : 1.0;
      for (var i = 0; i < 5; i++) {
        week.zoneMinutes[i < 2
                ? 0
                : i == 2
                ? 1
                : 2] +=
            seconds[i] * scale / 60;
      }
      week.activitiesWithZones++;
      week.activitiesFromSamples++;
      continue;
    }
    for (var i = 0; i < zones.length; i++) {
      week.zoneMinutes[i < 2
              ? 0
              : i == 2
              ? 1
              : 2] +=
          activity.durationSeconds / 60 * zones[i] / 100;
    }
    week.activitiesWithZones++;
  }
  return weeks.values.toList();
}

/// The last [count] weeks, oldest first, from the kept zone summaries: each
/// workout with the zones in force when it was done, never today's. A
/// workout without heart rate counts as recorded, not as easy.
List<LoadWeekHistory> buildZoneWeekHistory({
  required DateTime through,
  required Iterable<HrZoneWorkout> workouts,
  bool mondayFirst = true,
  int count = 5,
}) {
  final last = weekStartOf(through, mondayFirst: mondayFirst);
  final weeks = {
    for (var i = count - 1; i >= 0; i--)
      DateTime(last.year, last.month, last.day - i * 7): LoadWeekHistory(
        DateTime(last.year, last.month, last.day - i * 7),
      ),
  };
  for (final w in workouts) {
    final week = weeks[weekStartOf(w.start, mondayFirst: mondayFirst)];
    if (week == null) continue;
    week.activities++;
    if (w.coveredSeconds <= 0) continue;
    week.activitiesWithZones++;
    for (var i = 0; i < w.zoneSeconds.length; i++) {
      week.zoneMinutes[i < 2
              ? 0
              : i == 2
              ? 1
              : 2] +=
          w.zoneSeconds[i] / 60;
    }
  }
  return weeks.values.toList();
}

List<double>? _percentages(String? raw) {
  if (raw == null) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final zones = <double>[];
    for (var i = 1; i <= 5; i++) {
      final value = decoded['zone$i'] ?? 0;
      if (value is! num || !value.isFinite || value < 0 || value > 100) {
        return null;
      }
      zones.add(value.toDouble());
    }
    final total = zones.fold<double>(0, (a, b) => a + b);
    // Allow rounding of per-zone percentages, but not seconds mistaken for %.
    return total > 0 && total <= 102.5 ? zones : null;
  } on FormatException {
    return null;
  }
}
