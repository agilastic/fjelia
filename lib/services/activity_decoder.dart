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
  final samples = samplesJson is! List
      ? <ActivitySample>[]
      : samplesJson
            .cast<Map<String, dynamic>>()
            .map(
              (s) => ActivitySample(
                distanceMeters: (s['d'] as num).toDouble(),
                timestamp: heartRateTimestamp(s['t']),
                heartRate: (s['hr'] as num?)?.toDouble(),
                speed: (s['spd'] as num?)?.toDouble(),
                elevation: (s['ele'] as num?)?.toDouble(),
                power: (s['w'] as num?)?.toDouble(),
              ),
            )
            .toList();

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
        : _movingDurationFromSamples(samples),
  );
}

/// Moving time from distance/speed samples. Time per step is Δd / speed
/// (capped at 60 s); a hysteresis of 3 samples below 0.3 m/s / at or above
/// 0.5 m/s switches between stopped and moving.
Duration? _movingDurationFromSamples(List<ActivitySample> samples) {
  if (samples.length < 2) return null;
  var prevDist = samples.first.distanceMeters;
  var moving = true;
  var slowCount = 0;
  var fastCount = 0;
  var total = 0.0;

  for (var i = 1; i < samples.length; i++) {
    final s = samples[i];
    final delta = s.distanceMeters - prevDist;
    prevDist = s.distanceMeters;
    final speed = s.speed;
    if (speed == null) continue;

    var dt = 0.0;
    if (speed > 0.05 && delta > 0) {
      dt = (delta / speed).clamp(0.0, 60.0);
    }

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
  if (total <= 0) return null;
  return Duration(seconds: total.round());
}

double? _avgFromSamples(List<ActivitySample> samples) {
  final values = samples.map((s) => s.power).whereType<double>().toList();
  if (values.isEmpty) return null;
  return values.reduce((a, b) => a + b) / values.length;
}
