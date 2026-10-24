import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import '../models/heart_rate.dart';
import '../utils/log.dart';

const _source = 'health_connect';

/// Sources that already write to Apple Health themselves — never echoed back.
const _nativeHealthSources = {
  'health_connect',
  'garmin_api',
  'coros',
  'suunto',
};

/// Result of [HealthConnectService.probeAccess].
enum HealthAccess { ok, unresponsive, failed }

class HealthWriteBackResult {
  int hrv = 0;
  int rhr = 0;
  int spo2 = 0;
  int respiration = 0;
  int sleep = 0;
  int steps = 0;
  int workouts = 0;
  int bp = 0;
  int weight = 0;
  final List<String> errors = [];
}

/// Outcome of [HealthConnectService.exportBloodPressure].
class BpExportResult {
  int written = 0;
  int skipped = 0;
  final List<String> errors = [];
}

class HealthConnectSyncResult {
  int sleep = 0;
  int hr = 0;
  int steps = 0;
  int spo2 = 0;
  int activities = 0;
  final List<String> errors = [];
}

/// Apple Health (HealthKit) import and write-back. The name is kept from the
/// Android Health Connect origin of this service.
class HealthConnectService {
  HealthConnectService(this.db, {Health? health})
    : _health = health ?? Health();

  final Health _health;
  final AppDatabase db;
  bool _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  List<HealthDataType> get _types => [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.HEART_RATE,
    HealthDataType.STEPS,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  ];

  List<HealthDataType> get _writeTypes => [
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.HEART_RATE,
    HealthDataType.STEPS,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.WORKOUT,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  ];

  bool _isSleepType(HealthDataType t) =>
      t == HealthDataType.SLEEP_SESSION ||
      t == HealthDataType.SLEEP_IN_BED ||
      t == HealthDataType.SLEEP_ASLEEP ||
      t == HealthDataType.SLEEP_AWAKE ||
      t == HealthDataType.SLEEP_DEEP ||
      t == HealthDataType.SLEEP_REM ||
      t == HealthDataType.SLEEP_LIGHT;

  Future<bool> requestPermissions() async {
    await _configure();
    final types = ({..._types, ..._writeTypes}).toList();
    final permissions = types
        .map(
          (t) => _writeTypes.contains(t)
              ? HealthDataAccess.READ_WRITE
              : HealthDataAccess.READ,
        )
        .toList();
    log(
      '[Health] requestPermissions — types=${types.length} '
      'writeTypes=${_writeTypes.length}',
    );
    try {
      final granted = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      log('[Health] requestAuthorization returned $granted');
      return granted;
    } catch (e, st) {
      log('[Health] requestAuthorization ERROR: $e\n$st');
      return false;
    }
  }

  /// Short read that shows whether HealthKit access works. HealthKit does not
  /// say that access was revoked: reads simply stop answering, so a read that
  /// takes longer than [timeout] counts as unresponsive.
  Future<HealthAccess> probeAccess({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    await _configure();
    final now = DateTime.now();
    try {
      await _health
          .getHealthDataFromTypes(
            types: [HealthDataType.STEPS],
            startTime: now.subtract(const Duration(hours: 1)),
            endTime: now,
          )
          .timeout(timeout);
      return HealthAccess.ok;
    } on TimeoutException {
      log('[Health] access probe: no answer within ${timeout.inSeconds}s');
      return HealthAccess.unresponsive;
    } catch (e) {
      log('[Health] access probe failed: $e');
      return HealthAccess.failed;
    }
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  /// How long a single HealthKit read may take before Health counts as stalled.
  static const _queryTimeout = Duration(seconds: 40);
  bool _healthStalled = false;

  /// Reads Health data. HealthKit reads can wait forever (for example while
  /// the device is locked or access is pending), which would block the whole
  /// sync. After the first timeout the remaining reads of this run fail at
  /// once instead of waiting again.
  Future<List<HealthDataPoint>> _query({
    required List<HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (_healthStalled) {
      throw TimeoutException('Apple Health is not responding');
    }
    try {
      return await _health
          .getHealthDataFromTypes(
            types: types,
            startTime: startTime,
            endTime: endTime,
          )
          .timeout(_queryTimeout);
    } on TimeoutException {
      _healthStalled = true;
      log(
        '[HealthConnect] read timed out after ${_queryTimeout.inSeconds}s for '
        '${types.map((t) => t.name).join(',')} — skipping the rest',
      );
      rethrow;
    }
  }

  Future<HealthConnectSyncResult> sync(
    int days,
    List<String> sleepPriority,
  ) async {
    await _configure();
    _healthStalled = false;

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('hc_activity_dedup_v2') ?? false)) {
      final removed = await db.deduplicateActivities();
      log(
        '[HealthConnect] dedup migration: removed $removed duplicate activities',
      );
      await prefs.setBool('hc_activity_dedup_v2', true);
    }

    final result = HealthConnectSyncResult();
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    log('[HealthConnect] HealthKit sync starting — $days days');

    Future<void> fetchAndProcess(
      List<HealthDataType> types,
      Future<void> Function(List<HealthDataPoint>) process,
    ) async {
      try {
        final raw = await _query(types: types, startTime: start, endTime: now);
        final points = _health.removeDuplicates(raw);
        log(
          '[HealthConnect] fetched ${points.length} pts for '
          '${types.map((t) => t.name).join(',')}',
        );
        await process(points);
      } catch (e) {
        log('[HealthConnect] error for $types: $e');
        result.errors.add(_clip(e));
      }
    }

    final sleepTypes = _types.where(_isSleepType).toList();
    final hrTypes = [
      HealthDataType.HEART_RATE,
      HealthDataType.RESTING_HEART_RATE,
    ];
    final hrvTypes = [HealthDataType.HEART_RATE_VARIABILITY_SDNN];

    await fetchAndProcess(
      sleepTypes,
      (pts) => _processSleep(pts, result, sleepPriority),
    );

    // Heart rate is dense — fetch in 7-day chunks.
    for (var offset = 0; offset < days; offset += 7) {
      final chunkStart = start.add(Duration(days: offset));
      final chunkEnd = start.add(Duration(days: math.min(offset + 7, days)));
      try {
        final raw = await _query(
          types: hrTypes,
          startTime: chunkStart,
          endTime: chunkEnd,
        );
        final points = raw.toSet().toList();
        log('[HealthConnect] HR chunk ${offset ~/ 7}: ${points.length} pts');
        await _processHeartRate(points, result, sleepPriority);
      } catch (e) {
        log('[HealthConnect] HR chunk error: $e');
        result.errors.add(_clip(e));
      }
    }

    await fetchAndProcess(
      hrvTypes,
      (pts) => _processAvgHrv(pts, result, sleepPriority),
    );

    final scalarGroups = <List<HealthDataType>>[
      [HealthDataType.STEPS, HealthDataType.ACTIVE_ENERGY_BURNED],
      [HealthDataType.BLOOD_OXYGEN],
      [HealthDataType.RESPIRATORY_RATE],
      [HealthDataType.BODY_TEMPERATURE],
      [
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      ],
    ];

    for (final group in scalarGroups) {
      for (var offset = 0; offset < days; offset += 7) {
        final chunkStart = start.add(Duration(days: offset));
        final chunkEnd = start.add(Duration(days: math.min(offset + 7, days)));
        try {
          final raw = await _query(
            types: group,
            startTime: chunkStart,
            endTime: chunkEnd,
          );
          final points = raw.toSet().toList();
          final first = group.first;
          if (first == HealthDataType.STEPS ||
              first == HealthDataType.ACTIVE_ENERGY_BURNED ||
              first == HealthDataType.TOTAL_CALORIES_BURNED) {
            log(
              '[HealthConnect] scalar chunk ${offset ~/ 7} (steps/cal): '
              '${points.length} pts',
            );
            await _processSteps(points, result, sleepPriority);
            await _processCalories(points, sleepPriority);
          } else if (first == HealthDataType.BLOOD_OXYGEN) {
            await _processAvgHrvField(
              points,
              result,
              const [HealthDataType.BLOOD_OXYGEN],
              'SpO2',
              sleepPriority,
              (e) => e?.spo2,
              (e, v) => HrvRecordsCompanion(spo2: Value(v)),
              onSaved: (r) => r.spo2++,
            );
          } else if (first == HealthDataType.RESPIRATORY_RATE) {
            await _processAvgHrvField(
              points,
              result,
              const [HealthDataType.RESPIRATORY_RATE],
              'respiration',
              sleepPriority,
              (e) => e?.respirationRate,
              (e, v) => HrvRecordsCompanion(respirationRate: Value(v)),
            );
          } else if (first == HealthDataType.BODY_TEMPERATURE) {
            await _processAvgHrvField(
              points,
              result,
              const [HealthDataType.BODY_TEMPERATURE],
              'body temp',
              sleepPriority,
              (e) => e?.skinTempDelta,
              (e, v) => HrvRecordsCompanion(skinTempDelta: Value(v - 37.0)),
            );
          } else if (first == HealthDataType.BLOOD_PRESSURE_SYSTOLIC) {
            // Blood pressure is fetched to surface authorization state only;
            // readings come from the Aktiia/Hilo integrations.
          }
        } catch (e) {
          if (e.toString().contains('Authorization not determined')) {
            log(
              '[HealthConnect] scalar type not authorized: ${group.first} — skipped',
            );
            break;
          }
          log('[HealthConnect] scalar chunk error (${group.first}): $e');
          result.errors.add(_clip(e));
        }
      }
    }

    await fetchAndProcess([
      HealthDataType.WORKOUT,
    ], (pts) => _processWorkouts(pts, result));

    log(
      '[HealthConnect] sync done — sleep=${result.sleep} hr=${result.hr} '
      'steps=${result.steps} spo2=${result.spo2} '
      'activities=${result.activities}',
    );
    return result;
  }

  static String _clip(Object e) {
    final s = e.toString();
    return s.length > 60 ? s.substring(0, 60) : s;
  }

  static DateTime _day(DateTime t) {
    final l = t.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  static double? _numeric(HealthDataPoint p) {
    final v = p.value;
    return v is NumericHealthValue ? v.numericValue.toDouble() : null;
  }

  // ---- sleep ----------------------------------------------------------------

  Future<void> _processSleep(
    List<HealthDataPoint> points,
    HealthConnectSyncResult result,
    List<String> priority,
  ) async {
    final byDay = <DateTime, List<HealthDataPoint>>{};
    for (final p in points) {
      if (!_isSleepType(p.type)) continue;
      byDay.putIfAbsent(_day(p.dateFrom), () => []).add(p);
    }
    for (final entry in byDay.entries) {
      try {
        await _saveSleepForDay(entry.key, entry.value, priority);
        result.sleep++;
      } catch (e) {
        log('[HealthConnect] sleep save error ${entry.key}: $e');
      }
    }
  }

  Future<void> _saveSleepForDay(
    DateTime day,
    List<HealthDataPoint> points,
    List<String> priority,
  ) async {
    final phases = <Map<String, String>>[];
    var asleep = 0, awake = 0, deep = 0, light = 0, rem = 0;
    DateTime? sleepStart, sleepEnd;

    void bounds(HealthDataPoint p) {
      if (sleepStart == null || p.dateFrom.isBefore(sleepStart!)) {
        sleepStart = p.dateFrom;
      }
      if (sleepEnd == null || p.dateTo.isAfter(sleepEnd!)) {
        sleepEnd = p.dateTo;
      }
    }

    void phase(HealthDataPoint p, String name) => phases.add({
      's': p.dateFrom.toUtc().toIso8601String(),
      'e': p.dateTo.toUtc().toIso8601String(),
      'p': name,
    });

    for (final p in points) {
      final secs = p.dateTo.difference(p.dateFrom).inSeconds;
      switch (p.type) {
        case HealthDataType.SLEEP_ASLEEP:
          asleep += secs;
          bounds(p);
        case HealthDataType.SLEEP_AWAKE:
          awake += secs;
          phase(p, 'awake');
        case HealthDataType.SLEEP_DEEP:
          deep += secs;
          bounds(p);
          phase(p, 'deep');
        case HealthDataType.SLEEP_LIGHT:
          light += secs;
          bounds(p);
          phase(p, 'light');
        case HealthDataType.SLEEP_REM:
          rem += secs;
          bounds(p);
          phase(p, 'rem');
        default:
          break;
      }
    }

    final staged = deep + light + rem;
    final total = staged > 0 ? staged : asleep;
    if (total == 0) return;

    phases.sort((a, b) => a['s']!.compareTo(b['s']!));
    final phasesJson = phases.isEmpty ? null : jsonEncode(phases);

    await db.upsertSleep(
      SleepRecordsCompanion(
        date: Value(day),
        totalSleepSeconds: Value(total),
        deepSleepSeconds: Value(deep),
        remSleepSeconds: Value(rem),
        lightSleepSeconds: Value(staged > 0 ? light : asleep),
        awakeSleepSeconds: Value(awake),
        sleepStart: Value(sleepStart?.toLocal()),
        sleepEnd: Value(sleepEnd?.toLocal()),
        phasesJson: Value(phasesJson),
        source: const Value(_source),
      ),
    );
  }

  // ---- HRV-table fields -----------------------------------------------------

  Future<void> _processAvgHrv(
    List<HealthDataPoint> points,
    HealthConnectSyncResult result,
    List<String> priority,
  ) {
    return _processAvgHrvField(
      points,
      result,
      const [
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
      ],
      'HRV',
      priority,
      (e) => e?.hrvLastNight,
      (e, v) => HrvRecordsCompanion(hrvLastNight: Value(v)),
    );
  }

  /// Averages [types] per local day and patches one HRV-table field.
  Future<void> _processAvgHrvField(
    List<HealthDataPoint> points,
    HealthConnectSyncResult result,
    List<HealthDataType> types,
    String label,
    List<String> priority,
    double? Function(HrvRecord?) current,
    HrvRecordsCompanion Function(HrvRecord?, double) build, {
    void Function(HealthConnectSyncResult)? onSaved,
  }) async {
    final byDay = <DateTime, List<double>>{};
    for (final p in points) {
      if (!types.contains(p.type)) continue;
      final v = _numeric(p);
      if (v == null || v <= 0) continue;
      byDay.putIfAbsent(_day(p.dateFrom), () => []).add(v);
    }
    for (final entry in byDay.entries) {
      try {
        final values = entry.value;
        final avg = values.reduce((a, b) => a + b) / values.length;
        final existing = await db.getHrvForDate(entry.key);
        await _patchHrv(entry.key, existing, build(existing, avg));
        onSaved?.call(result);
      } catch (e) {
        log('[HealthConnect] $label save error: $e');
      }
    }
  }

  Future<void> _processHeartRate(
    List<HealthDataPoint> points,
    HealthConnectSyncResult result,
    List<String> priority,
  ) async {
    await db.saveHeartRateSamples([
      for (final p in points)
        if (p.type == HealthDataType.HEART_RATE && (_numeric(p) ?? 0) > 0)
          TimedHeartRate(p.dateFrom, _numeric(p)!, _source),
    ]);
    // Resting HR when HealthKit has it, else the day's lowest HR sample.
    final byDay = <DateTime, int>{};
    for (final p in points) {
      final v = _numeric(p)?.round();
      if (v == null || v <= 0) continue;
      final day = _day(p.dateFrom);
      if (p.type == HealthDataType.RESTING_HEART_RATE) {
        byDay[day] = v;
      } else if (p.type == HealthDataType.HEART_RATE) {
        final cur = byDay[day];
        if (cur == null || v < cur) byDay[day] = v;
      }
    }
    for (final entry in byDay.entries) {
      try {
        final existing = await db.getHrvForDate(entry.key);
        await _patchHrv(
          entry.key,
          existing,
          HrvRecordsCompanion(restingHeartRate: Value(entry.value)),
        );
        result.hr++;
      } catch (e) {
        log('[HealthConnect] HR save error: $e');
      }
    }
  }

  /// Merges [patch] over [existing] so other sources' fields survive.
  Future<void> _patchHrv(
    DateTime day,
    HrvRecord? existing,
    HrvRecordsCompanion patch,
  ) {
    return db.upsertHrv(
      patch.copyWith(date: Value(day), source: const Value(_source)),
    );
  }

  // ---- wellness -------------------------------------------------------------

  Future<void> _processSteps(
    List<HealthDataPoint> points,
    HealthConnectSyncResult result,
    List<String> priority,
  ) async {
    final byDay = <DateTime, int>{};
    for (final p in points) {
      if (p.type != HealthDataType.STEPS) continue;
      final v = _numeric(p)?.round();
      if (v == null) continue;
      final day = _day(p.dateFrom);
      byDay[day] = (byDay[day] ?? 0) + v;
    }
    for (final entry in byDay.entries) {
      try {
        final existing = await db.getWellnessForDate(entry.key);
        await _patchWellness(
          entry.key,
          existing,
          WellnessRecordsCompanion(steps: Value(entry.value)),
        );
        result.steps++;
      } catch (e) {
        log('[HealthConnect] steps save error: $e');
      }
    }
  }

  Future<void> _processCalories(
    List<HealthDataPoint> points,
    List<String> priority,
  ) async {
    final byDay = <DateTime, double>{};
    for (final p in points) {
      if (p.type != HealthDataType.TOTAL_CALORIES_BURNED &&
          p.type != HealthDataType.ACTIVE_ENERGY_BURNED) {
        continue;
      }
      final v = _numeric(p);
      if (v == null) continue;
      final day = _day(p.dateFrom);
      byDay[day] = (byDay[day] ?? 0) + v;
    }
    for (final entry in byDay.entries) {
      try {
        final existing = await db.getWellnessForDate(entry.key);
        await _patchWellness(
          entry.key,
          existing,
          WellnessRecordsCompanion(totalCalories: Value(entry.value.round())),
        );
      } catch (e) {
        log('[HealthConnect] calories save error: $e');
      }
    }
  }

  Future<void> _patchWellness(
    DateTime day,
    WellnessRecord? existing,
    WellnessRecordsCompanion patch,
  ) {
    return db.upsertWellness(
      patch.copyWith(date: Value(day), source: const Value(_source)),
    );
  }

  // ---- workouts -------------------------------------------------------------

  Future<void> _processWorkouts(
    List<HealthDataPoint> points,
    HealthConnectSyncResult result,
  ) async {
    log('[HC:workouts] raw points: ${points.length}');

    // HealthKit can report the same workout more than once; keep the longest.
    final unique = <DateTime, HealthDataPoint>{};
    for (final p in points) {
      if (p.type != HealthDataType.WORKOUT) continue;
      final prev = unique[p.dateFrom];
      if (prev == null ||
          p.dateTo.difference(p.dateFrom) >
              prev.dateTo.difference(prev.dateFrom)) {
        unique[p.dateFrom] = p;
      }
    }
    log('[HC:workouts] unique workouts after dedup: ${unique.length}');

    for (final p in unique.values) {
      log(
        '[HC:workouts] point type=${p.type} valueType=${p.value.runtimeType} '
        'from=${p.dateFrom} to=${p.dateTo}',
      );
      final value = p.value;
      if (value is! WorkoutHealthValue) {
        log(
          '[HC:workouts] skipped — not WorkoutHealthValue (${value.runtimeType})',
        );
        continue;
      }
      log(
        '[HC:workouts] workout activityType=${value.workoutActivityType} '
        'dist=${value.totalDistance}',
      );

      final activityId = 'hc_${p.dateFrom.millisecondsSinceEpoch}';
      final duration = p.dateTo.difference(p.dateFrom).inSeconds;

      final existing =
          await (db.select(db.activityRecords)
                ..where((t) => t.activityId.equals(activityId))
                ..limit(1))
              .getSingleOrNull();

      if (existing == null) {
        final sameDay = await db.getActivitiesForDate(p.dateFrom);
        final dupes = sameDay.where((a) {
          final startDiff = a.startDate.difference(p.dateFrom).inSeconds.abs();
          final durDiff = (a.durationSeconds - duration).abs();
          return startDiff <= 60 && durDiff <= (duration * 0.02).ceil();
        });
        if (dupes.isNotEmpty) {
          log(
            '[HC:workouts] skipped $activityId — duplicate of '
            '${dupes.first.activityId} (cross-source)',
          );
          continue;
        }
      } else {
        final type = _workoutTypeToString(value.workoutActivityType);
        final needsType = existing.type == 'other' && type != 'other';
        final needsHr = existing.avgHeartRate == null;
        if (!needsType && !needsHr) {
          log('[HC:workouts] skipped $activityId — already in DB');
          continue;
        }
        final avgHr = needsHr ? await _avgHr(p) : null;
        await (db.update(
          db.activityRecords,
        )..where((t) => t.activityId.equals(activityId))).write(
          ActivityRecordsCompanion(
            type: needsType ? Value(type) : const Value.absent(),
            name: needsType
                ? Value(_workoutTypeLabel(value.workoutActivityType))
                : const Value.absent(),
            avgHeartRate: avgHr != null
                ? Value(avgHr.toDouble())
                : const Value.absent(),
          ),
        );
        log(
          '[HC:workouts] patched $activityId type=${needsType ? type : '-'} '
          'avgHr=${avgHr ?? '-'}',
        );
        continue;
      }

      if (duration <= 0) {
        log('[HC:workouts] skipped $activityId — zero duration');
        continue;
      }

      final type = _workoutTypeToString(value.workoutActivityType);
      final avgHr = await _avgHr(p);
      log(
        '[HC:workouts] saving $activityId type=$type dur=${duration}s '
        'dist=${value.totalDistance} avgHr=$avgHr',
      );
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: activityId,
              name: _workoutTypeLabel(value.workoutActivityType),
              type: type,
              startDate: p.dateFrom,
              durationSeconds: duration,
              distanceMeters: Value(value.totalDistance?.toDouble()),
              avgHeartRate: Value(avgHr?.toDouble()),
              source: const Value(_source),
            ),
          );
      result.activities++;
    }
    log('[HC:workouts] done — saved ${result.activities}');
  }

  /// Mean of the HR samples recorded during [workout], rounded.
  Future<int?> _avgHr(HealthDataPoint workout) async {
    try {
      final samples = await _query(
        types: const [HealthDataType.HEART_RATE],
        startTime: workout.dateFrom,
        endTime: workout.dateTo,
      );
      final values = samples
          .where((s) => s.type == HealthDataType.HEART_RATE)
          .map((s) => _numeric(s) ?? 0.0)
          .where((v) => v > 0)
          .toList();
      if (values.isEmpty) return null;
      return (values.reduce((a, b) => a + b) / values.length).round();
    } catch (_) {
      return null;
    }
  }

  String _workoutTypeLabel(HealthWorkoutActivityType t) => switch (t) {
    HealthWorkoutActivityType.RUNNING => 'Run',
    HealthWorkoutActivityType.BIKING => 'Ride',
    HealthWorkoutActivityType.SWIMMING => 'Swim',
    HealthWorkoutActivityType.WALKING => 'Walk',
    HealthWorkoutActivityType.HIKING => 'Hike',
    HealthWorkoutActivityType.STRENGTH_TRAINING => 'Strength',
    HealthWorkoutActivityType.YOGA => 'Yoga',
    HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING => 'HIIT',
    HealthWorkoutActivityType.ELLIPTICAL => 'Elliptical',
    HealthWorkoutActivityType.ROWING => 'Row',
    _ => 'Workout',
  };

  String _workoutTypeToString(HealthWorkoutActivityType t) => switch (t) {
    HealthWorkoutActivityType.RUNNING => 'running',
    HealthWorkoutActivityType.BIKING => 'cycling',
    HealthWorkoutActivityType.SWIMMING => 'swimming',
    HealthWorkoutActivityType.WALKING => 'walking',
    HealthWorkoutActivityType.HIKING => 'hiking',
    HealthWorkoutActivityType.STRENGTH_TRAINING => 'strength_training',
    HealthWorkoutActivityType.YOGA => 'yoga',
    HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING => 'hiit',
    HealthWorkoutActivityType.ELLIPTICAL => 'elliptical',
    HealthWorkoutActivityType.ROWING => 'rowing',
    _ => 'other',
  };

  HealthWorkoutActivityType _toWorkoutType(String type) {
    final t = type.toLowerCase();
    if (t.contains('run') || t == 'trail_run') {
      return HealthWorkoutActivityType.RUNNING;
    }
    if (t.contains('trail')) return HealthWorkoutActivityType.HIKING;
    if (t == 'hike' || t == 'hiking') return HealthWorkoutActivityType.HIKING;
    if (t == 'walk' || t == 'walking') return HealthWorkoutActivityType.WALKING;
    if (t.contains('cycl') || t.contains('bik') || t.contains('mtb')) {
      return HealthWorkoutActivityType.BIKING;
    }
    if (t.contains('swim')) return HealthWorkoutActivityType.SWIMMING;
    if (t.contains('strength') || t.contains('gym')) {
      return HealthWorkoutActivityType.STRENGTH_TRAINING;
    }
    if (t.contains('yoga')) return HealthWorkoutActivityType.YOGA;
    return HealthWorkoutActivityType.OTHER;
  }

  // ---------------------------------------------------------------------------
  // Write-back
  // ---------------------------------------------------------------------------

  Future<bool> _tryWrite(
    double value,
    HealthDataType type,
    HealthDataUnit unit,
    DateTime start, [
    DateTime? end,
  ]) async {
    try {
      return await _health.writeHealthData(
        value: value,
        type: type,
        unit: unit,
        startTime: start,
        endTime: end ?? start,
      );
    } catch (_) {
      return false;
    }
  }

  static const _bpSentKey = 'hc_wb_bp_sent_v1';

  /// Writes blood-pressure readings to Apple Health, skipping those it already
  /// holds. A reading is a duplicate when Health has a systolic/diastolic pair
  /// in the same minute within 2 mmHg (from any app, including Hilo), or when
  /// Fjelia wrote it before. The second check keeps working when Health hides
  /// other apps' samples because read access was not granted.
  Future<BpExportResult> exportBloodPressure(List<BpMeasurement> rows) async {
    final out = BpExportResult();
    if (rows.isEmpty) return out;
    await _configure();
    if (_healthStalled) {
      out.errors.add(
        'Blood pressure export skipped: Apple Health is not responding.',
      );
      return out;
    }
    final types = [
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    ];
    // HealthKit's authorization dialog completing successfully does not mean
    // individual write permissions were granted. WRITE-only checks report
    // sharing authorization on iOS; READ_WRITE checks return null.
    final allowed = await _health.hasPermissions(
      types,
      permissions: [HealthDataAccess.WRITE, HealthDataAccess.WRITE],
    );
    if (allowed != true) {
      const message =
          'Blood pressure export skipped: Apple Health write '
          'permission is not granted. Enable it in Health app access settings.';
      log('[Health] $message');
      out.errors.add(message);
      return out;
    }
    int minute(DateTime t) => t.millisecondsSinceEpoch ~/ 60000;
    String key(DateTime t, int sys, int dia) => '${minute(t)}/$sys/$dia';

    final sorted = [...rows]
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    final inHealth = <int, (int, int)>{};
    try {
      final points = await _query(
        types: types,
        startTime: sorted.first.measuredAt.subtract(const Duration(minutes: 2)),
        endTime: sorted.last.measuredAt.add(const Duration(minutes: 2)),
      );
      final sys = <int, int>{};
      final dia = <int, int>{};
      for (final p in points) {
        final v = p.value;
        if (v is! NumericHealthValue) continue;
        (p.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC ? sys : dia)[minute(
          p.dateFrom,
        )] = v.numericValue
            .round();
      }
      for (final e in sys.entries) {
        final d = dia[e.key];
        if (d != null) inHealth[e.key] = (e.value, d);
      }
    } catch (e) {
      log('[Health] blood pressure duplicate check unavailable: $e');
    }
    bool inHealthAlready(DateTime t, int sys, int dia) {
      final m = minute(t);
      for (final at in [m - 1, m, m + 1]) {
        final v = inHealth[at];
        if (v != null && (v.$1 - sys).abs() <= 2 && (v.$2 - dia).abs() <= 2) {
          return true;
        }
      }
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final sent = (prefs.getStringList(_bpSentKey) ?? const <String>[]).toSet();
    for (final bp in sorted) {
      final k = key(bp.measuredAt, bp.systolic, bp.diastolic);
      if (sent.contains(k) ||
          inHealthAlready(bp.measuredAt, bp.systolic, bp.diastolic)) {
        out.skipped++;
        continue;
      }
      try {
        final saved = await _health.writeBloodPressure(
          systolic: bp.systolic,
          diastolic: bp.diastolic,
          startTime: bp.measuredAt,
        );
        if (!saved) {
          out.errors.add('Blood pressure export stopped after a failed save.');
          break;
        }
        sent.add(k);
        out.written++;
      } catch (e) {
        out.errors.add('Blood pressure export stopped: ${_clip(e)}');
        break;
      }
    }
    // Only recent readings are exported again, so older keys can go.
    final keep =
        DateTime.now()
            .subtract(const Duration(days: 14))
            .millisecondsSinceEpoch ~/
        60000;
    await prefs.setStringList(_bpSentKey, [
      for (final k in sent)
        if ((int.tryParse(k.split('/').first) ?? 0) >= keep) k,
    ]);
    return out;
  }

  /// Writes the last 7 days of locally sourced data to Apple Health.
  /// Each data kind keeps its own watermark so nothing is written twice.
  Future<HealthWriteBackResult> writeBack(
    bool hiloWrite,
    bool renphoWrite,
  ) async {
    await _configure();
    final result = HealthWriteBackResult();
    if (_healthStalled) {
      log('[Health] writeBack skipped — Apple Health is not responding');
      result.errors.add('Apple Health is not responding; nothing was written.');
      return result;
    }
    log('[Health] writeBack starting — 7d');
    final since = DateTime.now().subtract(const Duration(days: 7));
    final prefs = await SharedPreferences.getInstance();

    DateTime wm(String key) =>
        DateTime.fromMillisecondsSinceEpoch(prefs.getInt(key) ?? 0);
    Future<void> saveWm(String key, DateTime t) =>
        prefs.setInt(key, t.millisecondsSinceEpoch);

    if (!hiloWrite) {
      log('[Health] writeBack: Hilo write disabled — skipping HRV/sleep/BP');
    }

    try {
      if (hiloWrite) {
        // HRV / RHR / SpO2 / respiration
        var mark = wm('hc_wb_hrv_ms');
        final start = mark;
        for (final r in await db.getHrvRange(7)) {
          if (_nativeHealthSources.contains(r.source)) continue;
          final d = r.date.toLocal();
          final at = DateTime(d.year, d.month, d.day, 12);
          if (!at.isAfter(start) || at.isBefore(since)) continue;
          if (r.hrvLastNight != null &&
              await _tryWrite(
                r.hrvLastNight!,
                HealthDataType.HEART_RATE_VARIABILITY_SDNN,
                HealthDataUnit.MILLISECOND,
                at,
              )) {
            result.hrv++;
          }
          if (r.restingHeartRate != null &&
              await _tryWrite(
                r.restingHeartRate!.toDouble(),
                HealthDataType.RESTING_HEART_RATE,
                HealthDataUnit.BEATS_PER_MINUTE,
                at,
              )) {
            result.rhr++;
          }
          if (r.spo2 != null &&
              await _tryWrite(
                r.spo2!,
                HealthDataType.BLOOD_OXYGEN,
                HealthDataUnit.PERCENT,
                at,
              )) {
            result.spo2++;
          }
          if (r.respirationRate != null &&
              await _tryWrite(
                r.respirationRate!,
                HealthDataType.RESPIRATORY_RATE,
                HealthDataUnit.RESPIRATIONS_PER_MINUTE,
                at,
              )) {
            result.respiration++;
          }
          if (at.isAfter(mark)) mark = at;
        }
        await saveWm('hc_wb_hrv_ms', mark);

        // Sleep
        mark = wm('hc_wb_sleep_ms');
        final sleepStart = mark;
        for (final s in await db.getSleepRange(7)) {
          if (_nativeHealthSources.contains(s.source)) continue;
          final from = s.sleepStart, to = s.sleepEnd;
          if (from == null || to == null) continue;
          if (!to.isAfter(sleepStart)) continue;
          final secs = to.difference(from).inSeconds;
          if (secs <= 0 || secs > 86400) continue;
          if (await _tryWrite(
            1.0,
            HealthDataType.SLEEP_ASLEEP,
            HealthDataUnit.COUNT,
            from,
            to,
          )) {
            result.sleep++;
          }
          if (to.isAfter(mark)) mark = to;
        }
        await saveWm('hc_wb_sleep_ms', mark);

        // Blood pressure
        final bp = await exportBloodPressure(await db.getRecentBp(7));
        result.bp += bp.written;
        result.errors.addAll(bp.errors);
      }

      if (renphoWrite) {
        var mark = wm('hc_wb_weight_ms');
        final start = mark;
        for (final r in await db.getRenphoRange(7)) {
          if (r.weight == null || !r.measuredAt.isAfter(start)) continue;
          if (await _tryWrite(
            r.weight!,
            HealthDataType.WEIGHT,
            HealthDataUnit.KILOGRAM,
            r.measuredAt,
          )) {
            result.weight++;
          }
          if (r.measuredAt.isAfter(mark)) mark = r.measuredAt;
        }
        await saveWm('hc_wb_weight_ms', mark);
      }

      // Workouts
      var mark = wm('hc_wb_act_ms');
      final actStart = mark;
      for (final a in await db.getRecentActivities(7)) {
        if (_nativeHealthSources.contains(a.source)) continue;
        if (!a.startDate.isAfter(actStart)) continue;
        final end = a.startDate.add(Duration(seconds: a.durationSeconds));
        try {
          if (await _health.writeWorkoutData(
            activityType: _toWorkoutType(a.type),
            start: a.startDate,
            end: end,
            totalDistance: a.distanceMeters?.round(),
          )) {
            result.workouts++;
          }
        } catch (_) {}
        if (a.startDate.isAfter(mark)) mark = a.startDate;
      }
      await saveWm('hc_wb_act_ms', mark);
    } catch (e) {
      log('[HealthConnect] writeBack error: $e');
      result.errors.add(_clip(e));
    }

    log(
      '[HealthConnect] writeBack done — hrv=${result.hrv} rhr=${result.rhr} '
      'sleep=${result.sleep} steps=${result.steps} '
      'workouts=${result.workouts} bp=${result.bp} weight=${result.weight}',
    );
    return result;
  }
}
