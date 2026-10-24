import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fjelia_service_api/fjelia_service_api.dart';
import '../api/garmin_client.dart';
import '../api/renpho_client.dart';
import '../db/database.dart' hide DailyBpSummary;
import '../models/garmin_data.dart';
import '../models/renpho_data.dart';
import '../models/scores.dart';
import '../utils/log.dart';
import 'activity_decoder.dart';
import 'energie_calculator.dart';
import 'heat_acclimation_service.dart';
import 'score_calculator.dart';

const _zoneKeys = ['zone1', 'zone2', 'zone3', 'zone4', 'zone5'];
const _zoneWeights = [1.0, 1.1, 1.2, 3.1, 8.0];

/// Training load for one activity: zone-weighted minutes when HR zones are
/// known, otherwise Banister TRIMP from average HR (rest 55, max 190).
double? _trimpLoad(GarminActivity a) {
  final minutes = a.duration.inSeconds / 60.0;
  if (minutes <= 0) return null;
  final zones = a.hrZoneSeconds;
  if (zones.isNotEmpty) {
    var load = 0.0;
    for (var i = 0; i < _zoneKeys.length; i++) {
      final pct = zones[_zoneKeys[i]];
      if (pct == null) continue;
      load += minutes * (pct / 100.0) * _zoneWeights[i];
    }
    if (load > 0) return load;
  }
  final hr = a.avgHeartRate;
  if (hr == null || hr <= 0) return null;
  final reserve = ((hr - 55.0) / 135.0).clamp(0.0, 1.0);
  return minutes * reserve * math.exp(1.92 * reserve);
}

class SyncResult {
  int garmin = 0;
  int activities = 0;
  int bp = 0;
  int renpho = 0;
  int workouts = 0;
  final List<String> errors = [];
  bool aktiiaAuthError = false;
  bool garminAuthError = false;
  bool renphoAuthError = false;

  bool get hasErrors => errors.isNotEmpty;
}

class SyncService {
  SyncService(
    this._aktiia,
    this._garmin,
    this._renpho,
    this._db,
    this._heat, [
    this._scores = const ScoreCalculator(),
  ]);

  final AktiiaClient _aktiia;
  final GarminClient _garmin;
  final RenphoClient _renpho;
  final AppDatabase _db;
  final HeatAcclimationService _heat;
  final ScoreCalculator _scores;
  late final EnergieCalculator _energie = EnergieCalculator(_db);

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _clip(Object e) {
    final s = e.toString();
    return s.length > 60 ? s.substring(0, 60) : s;
  }

  // ---------------------------------------------------------------------------
  // Entry points
  // ---------------------------------------------------------------------------

  /// Full sync for one day: cloud sources, activities, plans and scores.
  Future<SyncResult> syncDay(DateTime date) async {
    final result = SyncResult();
    await Future.wait([
      _syncRenpho(result),
      _syncGarmin(date, result),
      _syncScheduledWorkouts(result),
    ]);
    await _syncAllActivities(result);
    await _matchPlannedWorkouts();
    try {
      await _heat.recomputeRange(14);
    } catch (e) {
      log('[Sync] heat recompute skipped: $e');
    }
    await _recalculateScores(date, result);
    await _energie.recalculateForDate(date);
    final today = _day(DateTime.now());
    if (_day(date) != today) await _recalculateScores(today, result);
    return result;
  }

  Future<SyncResult> syncAktiiaDay(DateTime date) async {
    final result = SyncResult();
    await _syncAktiia(date, result);
    await _recalculateScores(date, result);
    return result;
  }

  Future<SyncResult> syncWorkoutsOnly() async {
    final result = SyncResult();
    await _syncScheduledWorkouts(result);
    return result;
  }

  Future<void> recalculateEnergie(DateTime date) =>
      _energie.recalculateForDate(date);

  // ---------------------------------------------------------------------------
  // Garmin scheduled workouts
  // ---------------------------------------------------------------------------

  Future<void> _syncScheduledWorkouts(SyncResult result) async {
    if (!await _garmin.isLoggedIn) return;
    try {
      final workouts = await _garmin.getScheduledWorkouts();
      final ids = <String>[];
      for (final w in workouts) {
        ids.add(w.scheduleId);
        await _db.upsertScheduledWorkout(
          ScheduledWorkoutRecordsCompanion(
            workoutId: Value(w.workoutId),
            scheduleId: Value(w.scheduleId),
            trainingPlanId: Value(w.trainingPlanId),
            name: Value(w.name),
            sportType: Value(w.sportType),
            scheduledDate: Value(w.scheduledDate),
            estimatedDurationSeconds: Value(w.estimatedDuration?.inSeconds),
            estimatedDistanceMeters: Value(w.estimatedDistanceMeters),
            description: Value(w.description),
            itemType: Value(w.itemType),
            seriesName: Value(w.seriesName),
            stepsJson: Value(
              w.steps.isEmpty
                  ? null
                  : jsonEncode(w.steps.map((s) => s.toJson()).toList()),
            ),
            userNote: Value(w.userNote),
          ),
        );
      }
      await _db.deleteWorkoutsNotIn(ids);
      result.workouts += workouts.length;
      log('[Garmin] scheduled workouts synced: ${workouts.length}');
    } on GarminAuthException {
      result.garminAuthError = true;
      result.errors.add('Garmin auth error: session expired');
    } catch (e) {
      log('[Garmin] scheduled workouts sync error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Scores
  // ---------------------------------------------------------------------------

  Future<void> _recalculateScores(DateTime date, SyncResult result) async {
    final day = _day(date);
    try {
      final hrv = await _db.getHrvForDate(day);
      final sleep =
          await _db.getSleepForDate(day) ??
          await _db.getSleepForDate(day.subtract(const Duration(days: 1)));
      final wellness = await _db.getWellnessForDate(day);
      final activities = await _db.getActivitiesForDate(day);
      final bp = await _loadBpSummary(day);

      final scores = _scores.calculateAll(
        date: day,
        hrv: hrv == null ? null : _hrvFromRecord(hrv),
        sleep: sleep == null ? null : _sleepFromRecord(sleep),
        bp: bp,
        wellness: wellness == null ? null : _wellnessFromRecord(wellness),
        activities: activities.map(decodeActivityRecord).toList(),
      );

      // Strain is the day's summed TRIMP; prefer stored per-activity loads.
      final loads = activities
          .map((a) => a.trainingLoad)
          .whereType<double>()
          .fold<double>(0, (a, b) => a + b);
      final strain = (loads > 0 ? loads : scores.strain.score).clamp(
        0.0,
        2000.0,
      );

      final recovery = scores.recovery?.score;
      final level = recovery == null
          ? null
          : recovery >= 67
          ? RecoveryLevel.green
          : recovery >= 34
          ? RecoveryLevel.yellow
          : RecoveryLevel.red;

      await _db.upsertScore(
        DayScoreRecordsCompanion(
          date: Value(day),
          recoveryScore: Value(recovery),
          sleepScore: Value(scores.sleep?.score),
          strainScore: Value(strain),
          bpScore: Value(scores.bloodPressure?.score),
          recoveryLevel: Value(level?.name),
          recommendation: Value(scores.recovery?.recommendation),
        ),
      );
    } catch (e, st) {
      log('[Sync] _recalculateScores ERROR for $day: $e\n$st');
      result.errors.add('Score calculation error: ${_clip(e)}');
    }
  }

  WellnessData _wellnessFromRecord(WellnessRecord r) => WellnessData(
    date: r.date,
    steps: r.steps,
    activeCalories: r.activeCalories,
    totalCalories: r.totalCalories,
    averageStress: r.averageStress,
    bodyBatteryHighest: r.bodyBatteryHighest,
    bodyBatteryLowest: r.bodyBatteryLowest,
    floorsAscended: r.floorsAscended,
    intensityMinutes: r.intensityMinutes,
    fitnessAge: r.fitnessAge,
  );

  SleepData _sleepFromRecord(SleepRecord r) => SleepData(
    date: r.date,
    totalSleep: Duration(seconds: r.totalSleepSeconds),
    deepSleep: Duration(seconds: r.deepSleepSeconds),
    remSleep: Duration(seconds: r.remSleepSeconds),
    lightSleep: Duration(seconds: r.lightSleepSeconds),
    awakeSleep: Duration(seconds: r.awakeSleepSeconds),
    sleepScore: r.sleepScore,
    sleepStart: r.sleepStart,
    sleepEnd: r.sleepEnd,
    avgOvernightHrv: r.avgOvernightHrv,
    sleepNeedSeconds: r.sleepNeedSeconds,
  );

  HrvData _hrvFromRecord(HrvRecord r) => HrvData(
    date: r.date,
    lastNightAvg: r.hrvLastNight,
    weeklyAvg: r.hrvWeeklyAvg,
    restingHeartRate: r.restingHeartRate,
    spo2: r.spo2,
    respirationRate: r.respirationRate,
    skinTempDelta: r.skinTempDelta,
  );

  Future<DailyBpSummary?> _loadBpSummary(DateTime day) async {
    final readings = await _db.getBpForDate(day);
    if (readings.isEmpty) return null;
    final segments = readings
        .map(
          (m) => BpSegment(
            time: m.measuredAt,
            systolic: m.systolic,
            diastolic: m.diastolic,
            heartRate: m.heartRate,
            maxSystolic: m.systolic,
            minSystolic: m.systolic,
            count: 1,
            dayNightTag: m.dayNightTag,
            isBedTime: m.isBedTime,
            isWakeUpTime: m.isWakeUpTime,
          ),
        )
        .toList();
    int sum(int Function(BpMeasurement) f) =>
        readings.map(f).reduce((a, b) => a + b);
    final n = readings.length;
    final sys = readings.map((m) => m.systolic);
    final dia = readings.map((m) => m.diastolic);
    return DailyBpSummary(
      date: day,
      avgSystolic: sum((m) => m.systolic) / n,
      avgDiastolic: sum((m) => m.diastolic) / n,
      avgHeartRate: sum((m) => m.heartRate) / n,
      maxSystolic: sys.reduce(math.max),
      minSystolic: sys.reduce(math.min),
      maxDiastolic: dia.reduce(math.max),
      minDiastolic: dia.reduce(math.min),
      count: n,
      segments: segments,
    );
  }

  // ---------------------------------------------------------------------------
  // Aktiia
  // ---------------------------------------------------------------------------

  Future<void> _syncAktiia(DateTime date, SyncResult result) async {
    if (!isInAktiiaWindow(date) || !await _aktiia.isLoggedIn) return;
    try {
      final summary = await _aktiia.getDailyBp(date);
      await _db
          .into(_db.dailyBpSummaries)
          .insertOnConflictUpdate(
            DailyBpSummariesCompanion.insert(
              date: _day(date),
              avgSystolic: summary.avgSystolic,
              avgDiastolic: summary.avgDiastolic,
              avgHeartRate: summary.avgHeartRate,
              maxSystolic: summary.maxSystolic,
              minSystolic: summary.minSystolic,
              count: summary.count,
              normalBpPercent: Value(summary.normalBpPercent),
              trend: Value(summary.trend),
              rawJson: jsonEncode({
                'segments': summary.segments.map(_segmentToJson).toList(),
              }),
            ),
          );
      result.bp += await _insertAktiiaReadings(date);
    } on AktiiaAuthException catch (e) {
      result.aktiiaAuthError = true;
      result.errors.add('Aktiia auth error: ${_clip(e)}');
    } catch (e) {
      result.errors.add('Aktiia sync error: ${_clip(e)}');
    }
  }

  Future<int> _insertAktiiaReadings(DateTime date) async {
    if (!isInAktiiaWindow(date)) return 0;
    final from = _day(date);
    final to = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final readings = await _aktiia.getMeasurements(from, to);
    await _db.insertBpMeasurements(readings.map(_bpToCompanion).toList());
    return readings.length;
  }

  static Map<String, Object?> _segmentToJson(BpSegment s) => {
    'sys': s.systolic,
    'dia': s.diastolic,
    'hr': s.heartRate,
    'dayNightTag': s.dayNightTag,
    'timestamp': s.time.millisecondsSinceEpoch,
    'bedTime': s.isBedTime,
    'wakeUpTime': s.isWakeUpTime,
  };

  static BpMeasurementsCompanion _bpToCompanion(BloodPressureMeasurement m) =>
      BpMeasurementsCompanion.insert(
        measuredAt: m.dateTime,
        timezone: Value(m.timezone),
        systolic: m.systolic,
        diastolic: m.diastolic,
        heartRate: m.heartRate,
        measurementType: Value(m.measurementType),
        dayNightTag: Value(m.dayNightTag),
        isBedTime: Value(m.isBedTime),
        isWakeUpTime: Value(m.isWakeUpTime),
      );

  Future<int> _syncAktiiaDay(DateTime date, SyncResult result) async {
    if (!await _aktiia.isLoggedIn) return 0;
    try {
      return await _insertAktiiaReadings(date);
    } on AktiiaAuthException catch (e) {
      result.aktiiaAuthError = true;
      result.errors.add('Aktiia auth error: ${_clip(e)}');
    } catch (e) {
      result.errors.add('Aktiia day sync error: ${_clip(e)}');
    }
    return 0;
  }

  /// Walks back fetching BP readings; stops after 30 empty days. Detailed
  /// readings are only fetched for the last [aktiiaDetailDays] days; older
  /// history comes from imported Hilo reports.
  Future<SyncResult> syncAktiiaHistoric(
    int requestedDays, {
    void Function(int done, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final days = math.min(requestedDays, aktiiaDetailDays);
    final result = SyncResult();
    log('[Aktiia] historic: starting ($days days)');
    final today = _day(DateTime.now());
    var empty = 0;
    for (var i = 0; i < days; i++) {
      onProgress?.call(i, days);
      if (isCancelled?.call() ?? false) break;
      final date = today.subtract(Duration(days: i));
      if ((await _db.getBpForDate(date)).isNotEmpty) {
        empty = 0;
        continue;
      }
      log('[Aktiia] historic: ${date.toIso8601String().substring(0, 10)}');
      final n = await _syncAktiiaDay(date, result);
      result.bp += n;
      empty = n == 0 ? empty + 1 : 0;
      if (empty >= 30) {
        log('[Aktiia] historic: 30 consecutive empty days — stopping early');
        break;
      }
    }
    log('[Aktiia] historic: done — bp=${result.bp}');
    return result;
  }

  // ---------------------------------------------------------------------------
  // Garmin daily data
  // ---------------------------------------------------------------------------

  Future<void> _syncGarmin(DateTime date, SyncResult result) async {
    if (!await _garmin.isLoggedIn) return;
    final day = _day(date);
    try {
      final hrv = await _garmin.getHrv(day);
      final sleep = await _garmin.getSleep(day);
      final wellness = await _garmin.getWellness(day);
      final spo2 = await _garmin.getDailySpo2(day);

      if (hrv != null || sleep?.restingHeartRate != null || wellness != null) {
        await _db.upsertHrv(
          HrvRecordsCompanion(
            date: Value(day),
            hrvLastNight: Value(hrv?.lastNightAvg),
            hrvWeeklyAvg: Value(hrv?.weeklyAvg),
            restingHeartRate: Value(
              sleep?.restingHeartRate ??
                  hrv?.restingHeartRate ??
                  wellness?.restingHeartRate,
            ),
            stressLevel: Value(wellness?.averageStress),
            bodyBattery: Value(wellness?.bodyBatteryHighest),
            spo2: Value(sleep?.avgSpo2 ?? hrv?.spo2 ?? spo2),
            respirationRate: Value(
              sleep?.avgRespiration ??
                  hrv?.respirationRate ??
                  wellness?.respirationRate,
            ),
            skinTempDelta: Value(sleep?.skinTempDelta ?? hrv?.skinTempDelta),
            source: const Value('garmin_api'),
          ),
        );
      }

      if (sleep != null) {
        await _db.upsertSleep(
          SleepRecordsCompanion(
            date: Value(day),
            totalSleepSeconds: Value(sleep.totalSleep.inSeconds),
            deepSleepSeconds: Value(sleep.deepSleep.inSeconds),
            remSleepSeconds: Value(sleep.remSleep.inSeconds),
            lightSleepSeconds: Value(sleep.lightSleep.inSeconds),
            awakeSleepSeconds: Value(sleep.awakeSleep.inSeconds),
            sleepScore: Value(sleep.sleepScore),
            sleepStart: Value(sleep.sleepStart),
            sleepEnd: Value(sleep.sleepEnd),
            phasesJson: Value(
              sleep.phases.isEmpty ? null : sleep.phasesToJson(),
            ),
            avgOvernightHrv: Value(sleep.avgOvernightHrv),
            sleepNeedSeconds: Value(sleep.sleepNeedSeconds),
            source: const Value('garmin_api'),
          ),
        );
      }

      if (wellness != null) {
        await _db.upsertWellness(
          WellnessRecordsCompanion(
            date: Value(day),
            steps: Value(wellness.steps),
            activeCalories: Value(wellness.activeCalories),
            totalCalories: Value(wellness.totalCalories),
            floorsAscended: Value(wellness.floorsAscended),
            intensityMinutes: Value(wellness.intensityMinutes),
            averageStress: Value(wellness.averageStress),
            bodyBatteryHighest: Value(wellness.bodyBatteryHighest),
            bodyBatteryLowest: Value(wellness.bodyBatteryLowest),

            fitnessAge: Value(wellness.fitnessAge),
            avgSpo2: Value(spo2),
            source: const Value('garmin_api'),
          ),
        );
      }

      // VO2max and fitness age only change slowly — fetch for today only.
      if (day == _day(DateTime.now())) {
        final run = await _garmin.getVo2MaxRunning();
        final bike = await _garmin.getVo2MaxCycling();
        final age = await _garmin.getFitnessAge(day);
        log('[Sync] VO2max running=$run cycling=$bike fitnessAge=$age');
        await _db.updateWellnessVo2max(
          day,
          source: 'garmin_api',
          vo2max: run,
          vo2maxCycling: bike,
          fitnessAge: age,
        );
      }

      try {
        final bb = await _garmin.getBodyBattery(day);
        if (bb != null) {
          final json = jsonEncode(
            bb.samples
                .map((s) => [s.timestamp.millisecondsSinceEpoch, s.value])
                .toList(),
          );
          await _db.upsertWellness(
            WellnessRecordsCompanion(
              date: Value(day),
              source: const Value('garmin_api'),
              bodyBatteryJson: Value(json),
              bodyBatteryCharged: Value(bb.charged),
              bodyBatteryDrained: Value(bb.drained),
            ),
          );
        }
      } catch (e) {
        log('[Sync] body battery fetch skipped: $e');
      }
      try {
        await _db.saveHeartRateSamples(await _garmin.getHeartRateSamples(day));
      } catch (e) {
        log('[Sync] timestamped Garmin HR unavailable: $e');
      }
      result.garmin++;
    } on GarminAuthException catch (e) {
      result.garminAuthError = true;
      result.errors.add('Garmin auth error: ${_clip(e)}');
    } catch (e) {
      result.errors.add('Garmin sync error: ${_clip(e)}');
    }
  }

  // ---------------------------------------------------------------------------
  // Activities
  // ---------------------------------------------------------------------------

  static bool _isGpsActivity(String type) => !const {
    'strength_training',
    'gym_and_fitness_equipment',
    'indoor_cycling',
    'treadmill_running',
    'yoga',
    'pilates',
    'breathing',
  }.contains(type);

  static String _encodeTrackPoints(List<LatLng> points) {
    final buf = StringBuffer('[');
    for (var i = 0; i < points.length; i++) {
      if (i > 0) buf.write(',');
      final p = points[i];
      buf.write(
        '{"lat":${p.lat.toStringAsFixed(12)},'
        '"lng":${p.lng.toStringAsFixed(12)}}',
      );
    }
    buf.write(']');
    return buf.toString();
  }

  static String _encodeSamples(List<ActivitySample> samples) => jsonEncode(
    samples
        .map(
          (s) => <String, Object?>{
            'd': s.distanceMeters,
            'hr': s.heartRate,
            if (s.timestamp != null) 't': s.timestamp!.millisecondsSinceEpoch,
            'spd': s.speed,
            if (s.elevation != null) 'ele': s.elevation,
            if (s.power != null) 'w': s.power,
          },
        )
        .toList(),
  );

  /// Imports the latest Garmin activities. New ones get their details
  /// (zones, samples, route) fetched; known ones get missing GPS patched.
  Future<int> _syncAllActivities(
    SyncResult result, {
    int limit = 20,
    int start = 0,
    void Function(List<GarminActivity> page)? onPage,
  }) async {
    if (!await _garmin.isLoggedIn) return 0;
    var gpsPatched = 0;
    try {
      final activities = await _garmin.getActivities(
        limit: limit,
        start: start,
      );
      onPage?.call(activities);
      final cutoff = DateTime.now().subtract(const Duration(days: 1));
      final ids = activities.map((a) => a.id).toSet();
      final existing = {
        for (final r in await (_db.select(
          _db.activityRecords,
        )..where((t) => t.activityId.isIn(ids))).get())
          r.activityId: r,
      };

      final needDetails = activities
          .where(
            (a) =>
                existing[a.id] == null ||
                !(existing[a.id]!.metricsJson?.contains('"t"') ?? false) ||
                (existing[a.id]!.gpxJson == null &&
                    _isGpsActivity(a.type) &&
                    !a.startTime.isBefore(cutoff)),
          )
          .toList();
      final details = Map.fromEntries(
        (await Future.wait(
          needDetails.take(10).map((a) async {
            try {
              return MapEntry(a.id, await _garmin.getActivityDetails(a.id));
            } catch (_) {
              return null;
            }
          }),
        )).whereType<MapEntry<String, dynamic>>(),
      );

      for (final a in activities) {
        final d = details[a.id];
        final zones = (d?.hrZones as Map<String, double>?) ?? a.hrZoneSeconds;
        final samples = d?.samples as List<ActivitySample>?;
        final track = d?.trackPoints as List<LatLng>?;
        final elevation = (d?.totalElevation as double?) ?? a.elevationGain;
        final row = existing[a.id];

        if (row != null) {
          if (samples != null && samples.any((s) => s.timestamp != null)) {
            await (_db.update(
              _db.activityRecords,
            )..where((t) => t.activityId.equals(a.id))).write(
              ActivityRecordsCompanion(
                metricsJson: Value(_encodeSamples(samples)),
              ),
            );
          }
          if (row.gpxJson == null && track != null && track.isNotEmpty) {
            await (_db.update(
              _db.activityRecords,
            )..where((t) => t.activityId.equals(a.id))).write(
              ActivityRecordsCompanion(
                gpxJson: Value(_encodeTrackPoints(track)),
                metricsJson: samples == null || samples.isEmpty
                    ? const Value.absent()
                    : Value(_encodeSamples(samples)),
              ),
            );
            gpsPatched++;
            log('[Garmin] GPS patched: ${a.id} (${a.name})');
          }
          if (row.trainingLoad == null) {
            final load = _trimpLoad(a);
            if (load != null) {
              await (_db.update(_db.activityRecords)
                    ..where((t) => t.activityId.equals(a.id)))
                  .write(ActivityRecordsCompanion(trainingLoad: Value(load)));
            }
          }
          continue;
        }

        final withZones = GarminActivity(
          id: a.id,
          name: a.name,
          type: a.type,
          startTime: a.startTime,
          duration: a.duration,
          avgHeartRate: a.avgHeartRate,
          hrZoneSeconds: zones,
        );
        await _db
            .into(_db.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: a.id,
                name: a.name,
                type: a.type,
                startDate: a.startTime,
                durationSeconds: a.duration.inSeconds,
                distanceMeters: Value(a.distanceMeters),
                avgHeartRate: Value(a.avgHeartRate),
                maxHeartRate: Value(a.maxHeartRate),
                trainingLoad: Value(a.trainingLoad ?? _trimpLoad(withZones)),
                avgWatts: Value(
                  a.avgPower ?? _avgPower(samples ?? const <ActivitySample>[]),
                ),
                totalElevation: Value(elevation),
                hrZonesJson: Value(zones.isEmpty ? null : jsonEncode(zones)),
                gpxJson: Value(
                  track == null || track.isEmpty
                      ? null
                      : _encodeTrackPoints(track),
                ),
                metricsJson: Value(
                  samples == null || samples.isEmpty
                      ? null
                      : _encodeSamples(samples),
                ),
                source: const Value('garmin_api'),
                aerobicTrainingEffect: Value(a.aerobicTrainingEffect),
                anaerobicTrainingEffect: Value(a.anaerobicTrainingEffect),
                recoveryTimeSeconds: Value(a.recoveryTimeSeconds),
                activityFeedbackPhrase: Value(a.activityFeedbackPhrase),
                avgRunCadence: Value(a.avgRunCadence),
                vo2maxActivity: Value(a.vo2max),
                movingDurationSeconds: Value(a.movingDuration?.inSeconds),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        result.activities++;
      }
    } on GarminAuthException catch (e) {
      result.garminAuthError = true;
      result.errors.add('Garmin auth error: ${_clip(e)}');
    } catch (e) {
      result.errors.add('Activity sync error: ${_clip(e)}');
    }
    return gpsPatched;
  }

  static double? _avgPower(List<ActivitySample> samples) {
    final watts = samples.map((s) => s.power).whereType<double>().toList();
    if (watts.isEmpty) return null;
    return watts.reduce((a, b) => a + b) / watts.length;
  }

  Future<void> _matchPlannedWorkouts() async {
    try {
      final now = DateTime.now();
      final from = _day(now).subtract(const Duration(days: 2));
      final to = _day(now).add(const Duration(days: 1));
      final planned = await _db.getScheduledWorkoutsInRange(from, to);
      final unmatched = await _db.getUnmatchedActivitiesInRange(from, to);
      final used = <String>{};

      for (final w in planned) {
        final day = _day(w.scheduledDate);
        final candidates = unmatched
            .where(
              (a) =>
                  !used.contains(a.activityId) &&
                  _day(a.startDate) == day &&
                  _sportMatches(w.sportType, a.type),
            )
            .toList();
        if (candidates.isEmpty) continue;

        ActivityRecord? best;
        var bestScore = double.infinity;
        for (final a in candidates) {
          final planned = w.estimatedDurationSeconds;
          if (planned == null || planned <= 0) {
            best ??= a;
            continue;
          }
          final ratio = a.durationSeconds / planned;
          if (ratio < 0.85 || ratio > 1.15) continue;
          final score = (ratio - 1.0).abs();
          if (score < bestScore) {
            bestScore = score;
            best = a;
          }
        }
        if (best == null) continue;
        used.add(best.activityId);
        await _db.stampPlannedWorkout(
          best.activityId,
          name: w.name,
          durationSeconds: w.estimatedDurationSeconds,
          distanceMeters: w.estimatedDistanceMeters,
          stepsJson: w.stepsJson,
        );
        log(
          '[Sync] planned→actual matched: "${w.name}" → "${best.name}" '
          '(${best.activityId})',
        );
      }
    } catch (e) {
      log('[Sync] _matchPlannedWorkouts error: $e');
    }
  }

  bool _sportMatches(String planned, String actual) {
    final p = planned.toLowerCase(), a = actual.toLowerCase();
    bool both(List<String> keys) =>
        keys.any(p.contains) && keys.any(a.contains);
    return both(['run', 'jogging', 'trail']) ||
        both(['cycl', 'bike', 'ride']) ||
        both(['swim']) ||
        both(['walk', 'hike']) ||
        both(['strength', 'gym', 'weight']);
  }

  // ---------------------------------------------------------------------------
  // Renpho
  // ---------------------------------------------------------------------------

  Future<void> _syncRenpho(SyncResult result) async {
    if (!await _renpho.isLoggedIn) return;
    try {
      final measurements = await _renpho.getAllMeasurements();
      if (measurements.isEmpty) {
        log('[Renpho] sync: no measurements found');
        return;
      }
      final rows = measurements
          .where((m) => m.timestamp.millisecondsSinceEpoch > 0)
          .map(_renphoToCompanion)
          .toList();
      log('[Renpho] sync: writing ${rows.length} rows to DB');
      await _db.upsertRenphoMeasurements(rows);
      log('[Renpho] sync: DB write done');
      result.renpho += rows.length;
      final latest = measurements.first;
      log(
        '[Renpho] sync: measurements=${measurements.length} '
        'latest=${latest.weight?.toStringAsFixed(1) ?? '—'}kg '
        'bmi=${latest.bmi?.toStringAsFixed(1) ?? '—'} '
        'fat=${latest.bodyFat?.toStringAsFixed(1) ?? '—'}%',
      );
    } on RenphoApiException catch (e) {
      result.renphoAuthError = e.code == 401 || e.code == 40001;
      result.errors.add('Renpho sync error: ${_clip(e)}');
      log('[Renpho] sync ERROR — $e');
    } catch (e) {
      result.errors.add('Renpho sync error: ${_clip(e)}');
      log('[Renpho] sync ERROR — $e');
    }
  }

  RenphoRecordsCompanion _renphoToCompanion(RenphoMeasurement m) =>
      RenphoRecordsCompanion.insert(
        measuredAt: m.timestamp,
        scaleName: Value(m.scaleName),
        weight: Value(m.weight),
        bmi: Value(m.bmi),
        bodyFat: Value(m.bodyFat),
        bodyWater: Value(m.bodyWater),
        muscleMass: Value(m.muscleMass),
        boneMass: Value(m.boneMass),
        bmr: Value(m.bmr),
        visceralFat: Value(m.visceralFat),
        subcutaneousFat: Value(m.subcutaneousFat),
        protein: Value(m.protein),
        bodyAge: Value(m.bodyAge),
        leanBodyMass: Value(m.leanBodyMass),
        fatFreeWeight: Value(m.fatFreeWeight),
        waistCm: Value(m.waistCm),
        heartRate: Value(m.heartRate),
        cardiacIndex: Value(m.cardiacIndex),
        bodyShape: Value(m.bodyShape),
        rawJson: jsonEncode(m.raw),
      );

  // ---------------------------------------------------------------------------
  // Migrations & historic backfill
  // ---------------------------------------------------------------------------

  /// One-off: strainScore used to be a 0–21 scale; it is now summed TRIMP.
  Future<void> migrateStrainToTrimp() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('strain_trimp_migration_v1') ?? false) return;
    log('[Migration] recomputing strainScore → Banister TRIMP for all history');
    var patched = 0;
    for (final s in await _db.getAllScores()) {
      final day = DateTime(s.date.year, s.date.month, s.date.day);
      final activities = await _db.getActivitiesForDate(day);
      final load = activities
          .map((a) => a.trainingLoad ?? 0.0)
          .fold<double>(0.0, (a, b) => a + b);
      await _db.upsertScore(
        DayScoreRecordsCompanion(date: Value(s.date), strainScore: Value(load)),
      );
      patched++;
    }
    await prefs.setBool('strain_trimp_migration_v1', true);
    log('[Migration] done — patched $patched days');
  }

  Future<SyncResult> syncGarminHistoric(
    int days, {
    void Function(int done, int total)? onProgress,
    void Function(String status)? onStatus,
    bool Function()? isCancelled,
  }) async {
    final result = SyncResult();
    log('[Garmin] historic: starting ($days days)');
    bool cancelled() => isCancelled?.call() ?? false;

    // Tiers: activity summaries for the whole period (up to a year and
    // more), per-activity details and daily wellness for the last 90 days.
    final detailDays = math.min(days, 90);
    var gpsPatched = 0;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    for (var start = 0; start < 5000; start += 100) {
      if (cancelled()) return result;
      var page = <GarminActivity>[];
      gpsPatched += await _syncAllActivities(
        result,
        limit: 100,
        start: start,
        onPage: (p) => page = p,
      );
      log('[Garmin] historic: activity page start=$start → ${page.length}');
      onStatus?.call('${start + page.length} activities loaded…');
      if (page.length < 100 || page.any((a) => a.startTime.isBefore(cutoff))) {
        break;
      }
    }
    if (cancelled()) return result;
    await _backfillTrainingLoad(days);
    if (cancelled()) return result;
    await _backfillGps(detailDays);
    if (cancelled()) return result;
    onStatus?.call('workout details (last $detailDays days)…');
    await _backfillMetrics(detailDays);
    if (cancelled()) return result;

    final today = _day(DateTime.now());
    for (var i = 0; i < detailDays; i++) {
      onProgress?.call(i + 1, detailDays);
      if (cancelled()) return result;
      final date = today.subtract(Duration(days: i));
      final haveAll =
          await _db.getHrvForDate(date) != null &&
          await _db.getSleepForDate(date) != null &&
          await _db.getWellnessForDate(date) != null;
      if (haveAll && i > 0) continue;
      log('[Garmin] historic: ${date.toIso8601String().substring(0, 10)}');
      await _syncGarmin(date, result);
    }

    try {
      final activities = await _db.getActivitiesInRange(detailDays);
      await _heat.prefetchWeatherForActivities(activities);
    } catch (e) {
      log('[Sync] heat/weather skipped: $e');
    }
    if (cancelled()) return result;

    onStatus?.call('calculating scores…');
    log('[Garmin] historic: recalculating scores for $days days');
    for (var i = 0; i < days; i++) {
      await _recalculateScores(today.subtract(Duration(days: i)), result);
    }
    log('[Garmin] historic: recalculating Energie for $days days');
    await _energie.recalculateRange(days);

    log(
      '[Garmin] historic: recalculating heat acclimation for $detailDays days',
    );
    try {
      await _heat.recomputeRange(detailDays);
      if (gpsPatched > 0) {
        log(
          '[Garmin] historic: $gpsPatched GPS patches — recomputing heat acclimation',
        );
        await _heat.recomputeRange(detailDays);
      }
    } catch (e) {
      log('[Sync] heat/weather skipped: $e');
    }
    log(
      '[Garmin] historic: done — garmin=${result.garmin} '
      'activities=${result.activities}',
    );
    return result;
  }

  Future<void> _backfillMetrics(int days) async {
    try {
      final rows =
          (await _db.getActivitiesInRange(days))
              .where(
                (a) =>
                    a.source == 'garmin_api' &&
                    (a.metricsJson == null || !a.metricsJson!.contains('"t"')),
              )
              .toList()
            ..sort((a, b) => b.startDate.compareTo(a.startDate));
      final todo = rows.take(100).toList();
      log('[Garmin] metrics backfill: ${todo.length} activities need metrics');
      if (todo.isEmpty || !await _garmin.isLoggedIn) return;
      var patched = 0;
      for (final a in todo) {
        try {
          final d = await _garmin.getActivityDetails(a.activityId);
          final samples = d.samples;
          if (samples == null || samples.isEmpty) continue;
          await (_db.update(
            _db.activityRecords,
          )..where((t) => t.activityId.equals(a.activityId))).write(
            ActivityRecordsCompanion(
              metricsJson: Value(_encodeSamples(samples)),
              hrZonesJson: d.hrZones == null || a.hrZonesJson != null
                  ? const Value.absent()
                  : Value(jsonEncode(d.hrZones)),
            ),
          );
          patched++;
        } catch (e) {
          log('[Garmin] metrics backfill error for ${a.activityId}: $e');
        }
      }
      log('[Garmin] metrics backfill: patched $patched activities');
    } catch (e) {
      log('[Garmin] metrics backfill error: $e');
    }
  }

  Future<void> _backfillGps(int days) async {
    try {
      final todo = (await _db.getActivitiesInRange(
        days,
      )).where((a) => a.gpxJson == null && _isGpsActivity(a.type)).toList();
      log('[Garmin] GPS backfill: ${todo.length} activities need GPS');
      if (todo.isEmpty || !await _garmin.isLoggedIn) return;
      var patched = 0;
      for (final a in todo) {
        try {
          final d = await _garmin.getActivityDetails(a.activityId);
          final track = d.trackPoints;
          // An empty string marks "checked, no GPS" so it isn't refetched.
          await (_db.update(
            _db.activityRecords,
          )..where((t) => t.activityId.equals(a.activityId))).write(
            ActivityRecordsCompanion(
              gpxJson: Value(
                track == null || track.isEmpty ? '' : _encodeTrackPoints(track),
              ),
            ),
          );
          if (track != null && track.isNotEmpty) patched++;
        } catch (e) {
          log('[Garmin] GPS backfill error for ${a.activityId}: $e');
        }
      }
      log('[Garmin] GPS backfill: patched $patched activities');
    } catch (e) {
      log('[Garmin] GPS backfill error: $e');
    }
  }

  Future<void> _backfillTrainingLoad(int days) async {
    try {
      final todo = (await _db.getActivitiesInRange(
        days,
      )).where((a) => a.trainingLoad == null).toList();
      log('[Garmin] backfill: ${todo.length} activities need trainingLoad');
      if (todo.isEmpty || !await _garmin.isLoggedIn) return;
      final garmin = {
        for (final a in await _garmin.getActivities(limit: 100)) a.id: a,
      };
      var patched = 0, noLoad = 0;
      for (final r in todo) {
        final a = garmin[r.activityId] ?? decodeActivityRecord(r);
        final load = a.trainingLoad ?? _trimpLoad(a);
        if (load == null) noLoad++;
        await (_db.update(_db.activityRecords)
              ..where((t) => t.activityId.equals(r.activityId)))
            .write(ActivityRecordsCompanion(trainingLoad: Value(load ?? 0.0)));
        patched++;
      }
      log(
        '[Garmin] backfill: patched $patched activities with trainingLoad '
        '($noLoad marked as no-load)',
      );
    } catch (e) {
      log('[Garmin] backfill error: $e');
    }
  }
}
