import 'dart:convert';

import '../db/database.dart';
import '../models/garmin_data.dart';
import '../models/heart_rate.dart';
import '../utils/log.dart';

/// Decodes a stored JSON column. A missing or blank value means there is no
/// data; an unreadable value is logged. Both give null, so one damaged field
/// cannot stop a whole list from loading.
Object? decodeStoredJson(String? json, {String? what}) {
  if (json == null || json.trim().isEmpty) return null;
  try {
    return jsonDecode(json);
  } on FormatException catch (e) {
    log('[Activity] unreadable JSON in ${what ?? 'column'}: ${e.message}');
    return null;
  }
}

/// Rebuilds the in-memory activity (route, samples, zones, planned steps)
/// from its database row.
GarminActivity decodeActivityRecord(ActivityRecord r) {
  final id = r.activityId;
  final routeJson = decodeStoredJson(r.gpxJson, what: 'route of $id');
  final route = routeJson is! List
      ? <LatLng>[]
      : routeJson
            .cast<Map<String, dynamic>>()
            .map(
              (p) => LatLng(
                (p['lat'] as num).toDouble(),
                (p['lng'] as num).toDouble(),
              ),
            )
            .toList();

  final samplesJson = decodeStoredJson(r.metricsJson, what: 'samples of $id');
  var lastDistance = 0.0;
  final samples = samplesJson is! List
      ? <ActivitySample>[]
      : samplesJson.cast<Map<String, dynamic>>().map((s) {
          final distance = s['d'];
          if (distance is num && distance.isFinite && distance >= 0) {
            lastDistance = distance.toDouble();
          }
          return ActivitySample(
            distanceMeters: lastDistance,
            timestamp: heartRateTimestamp(s['t']),
            heartRate: (s['hr'] as num?)?.toDouble(),
            speed: (s['spd'] as num?)?.toDouble(),
            elevation: (s['ele'] as num?)?.toDouble(),
            power: (s['w'] as num?)?.toDouble(),
            cadence: (s['cad'] as num?)?.toDouble(),
          );
        }).toList();

  final zonesJson = decodeStoredJson(r.hrZonesJson, what: 'HR zones of $id');
  final hrZones = zonesJson is! Map
      ? <String, double>{}
      : zonesJson.map((k, v) => MapEntry('$k', (v as num).toDouble()));

  final stepsJson = decodeStoredJson(r.plannedStepsJson, what: 'steps of $id');
  final plannedSteps = stepsJson is! List
      ? <WorkoutStep>[]
      : stepsJson
            .cast<Map<String, dynamic>>()
            .map(WorkoutStep.fromJson)
            .toList();

  return GarminActivity(
    id: r.activityId,
    name: r.name,
    type: r.type,
    startTime: r.startDate,
    duration: Duration(seconds: r.durationSeconds),
    distanceMeters: r.distanceMeters,
    avgHeartRate: r.avgHeartRate,
    maxHeartRate: r.maxHeartRate,
    trainingLoad: r.trainingLoad,
    avgPower: r.avgWatts ?? _avgFromSamples(samples),
    elevationGain: r.totalElevation,
    route: route,
    samples: samples,
    hrZoneSeconds: hrZones,
    source: r.source,
    plannedWorkoutName: r.plannedWorkoutName,
    plannedDuration: r.plannedDurationSeconds != null
        ? Duration(seconds: r.plannedDurationSeconds!)
        : null,
    plannedDistanceMeters: r.plannedDistanceMeters,
    plannedSteps: plannedSteps,
    aerobicTrainingEffect: r.aerobicTrainingEffect,
    anaerobicTrainingEffect: r.anaerobicTrainingEffect,
    recoveryTimeSeconds: r.recoveryTimeSeconds,
    activityFeedbackPhrase: r.activityFeedbackPhrase,
    avgRunCadence: r.avgRunCadence,
    vo2max: r.vo2maxActivity,
    movingDuration: r.movingDurationSeconds != null
        ? Duration(seconds: r.movingDurationSeconds!)
        : _movingDurationFromSamples(samples, r.durationSeconds),
  );
}

/// Estimated moving time from observed speed intervals. A few samples cannot
/// represent a whole workout: require at least 90% recording-time coverage.
/// Untimed legacy summaries use distance/speed only with equivalent coverage.
Duration? _movingDurationFromSamples(
  List<ActivitySample> samples,
  int durationSeconds,
) {
  final speeds = samples
      .where((s) => s.speed != null && s.speed!.isFinite && s.speed! >= 0)
      .toList();
  if (speeds.length < 2 || durationSeconds <= 0) return null;
  final timed = speeds.every((s) => s.timestamp != null);
  if (!timed && speeds.any((s) => s.timestamp != null)) return null;
  var moving = speeds.first.speed! >= 0.5;
  var slowCount = 0;
  var fastCount = 0;
  var total = 0.0, coverage = 0.0;

  for (var i = 1; i < speeds.length; i++) {
    final s = speeds[i], previous = speeds[i - 1];
    final speed = s.speed!;
    final delta = s.distanceMeters - previous.distanceMeters;
    final dt = timed
        ? s.timestamp!.difference(previous.timestamp!).inMilliseconds / 1000
        : speed > 0.05 && delta > 0
        ? delta / speed
        : 0.0;
    if (dt < 0) return null;
    if (!dt.isFinite || dt <= 0 || dt > 60) continue;
    coverage += dt;

    if (moving) {
      if (speed < 0.3) {
        slowCount++;
        if (slowCount >= 3) {
          moving = false;
          slowCount = 0;
        }
      } else {
        slowCount = 0;
      }
    } else {
      if (speed >= 0.5) {
        fastCount++;
        if (fastCount >= 3) {
          moving = true;
          fastCount = 0;
        }
      } else {
        fastCount = 0;
      }
    }
    if (moving) total += dt;
  }
  if (coverage < durationSeconds * .9) return null;
  return Duration(seconds: total.round().clamp(0, durationSeconds));
}

double? _avgFromSamples(List<ActivitySample> samples) {
  final values = samples.map((s) => s.power).whereType<double>().toList();
  if (values.isEmpty) return null;
  return values.reduce((a, b) => a + b) / values.length;
}
