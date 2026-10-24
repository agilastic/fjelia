import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../models/garmin_data.dart' show LatLng;
import '../models/heat_acclimation.dart';
import '../utils/log.dart';
import 'global_weather_client.dart';
import 'heat_acclimation_settings.dart';
import 'location_service.dart';
import 'open_meteo_client.dart';
import 'activity_decoder.dart';

/// Heat acclimation score (0–100). Decays 6 % per day; outdoor workouts of
/// at least 30 minutes at ≥ 22 °C add 8–15 points depending on heat,
/// humidity (wet bulb) and duration.
class HeatAcclimationService {
  HeatAcclimationService(
    this._db, {
    GlobalWeatherClient? weather,
    HeatAcclimationSettingsStore settings =
        const HeatAcclimationSettingsStore(),
    LocationService? location,
  }) : _weather = weather ?? WeatherRouter(),
       // ignore: prefer_initializing_formals
       _settings = settings,
       _location = location ?? LocationService();

  final AppDatabase _db;
  final GlobalWeatherClient _weather;
  final HeatAcclimationSettingsStore _settings;
  final LocationService _location;

  static const _dailyDecay = 0.06;

  Future<bool> get isEnabled => _settings.isEnabled();

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Recomputes the last [days] days in order, carrying the score forward.
  Future<List<HeatDailyStateData>> recomputeRange(int days) async {
    if (!await isEnabled) return const [];
    final today = _day(DateTime.now());
    final start = today.subtract(Duration(days: days));
    final before = await _getState(start.subtract(const Duration(days: 1)));
    var score = before?.score ?? 0.0;
    final states = <HeatDailyStateData>[];
    for (
      var d = start;
      !d.isAfter(today);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      final state = await _recomputeDay(d, score);
      score = state.score;
      states.add(state);
      await _upsertState(state);
    }
    return states;
  }

  Future<void> _upsertState(HeatDailyStateData s) async {
    await _db.upsertHeatDailyState(
      HeatDailyStateRecordsCompanion(
        date: Value(s.date),
        score: Value(s.score),
        status: Value(s.status.name),
        decayApplied: Value(s.decayApplied),
        workoutGain: Value(s.workoutGain),
        lastActivityId: Value(s.lastActivityId),
        recommendation: Value(s.recommendation),
        updatedAt: Value(s.updatedAt),
      ),
    );
  }

  Future<HeatDailyStateData> _recomputeDay(
    DateTime day,
    double previousScore,
  ) async {
    final activities = (await _db.getActivitiesForDate(day)).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final decay = previousScore * _dailyDecay;
    var score = math.max(0.0, previousScore - decay);
    var gain = 0.0;
    String? lastActivityId;
    for (final a in activities) {
      final ctx = await _buildContextForActivity(a, scoreBeforeOverride: score);
      if (ctx == null) continue;
      await _upsertWorkoutContext(ctx);
      if (!ctx.qualifies) continue;
      final added = ctx.scoreAfter - ctx.scoreBefore;
      gain += added;
      score = ctx.scoreAfter;
      lastActivityId = a.activityId;
    }

    final status = score < 30
        ? HeatStatus.none
        : score < 70
        ? HeatStatus.partial
        : HeatStatus.full;
    final recommendation = score < 30
        ? 'Low acclimation. Reduce pace and plan more hydration breaks.'
        : score < 70
        ? 'Partially acclimated. Manage intensity and hydration actively.'
        : 'Well acclimated. Keep an eye on electrolytes and heat stress.';
    return HeatDailyStateData(
      date: day,
      score: score,
      status: status,
      decayApplied: decay,
      workoutGain: gain,
      lastActivityId: lastActivityId,
      recommendation: recommendation,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _upsertWorkoutContext(HeatWorkoutContextData c) async {
    await _db.upsertHeatWorkoutContext(
      HeatWorkoutContextsCompanion(
        activityId: Value(c.activityId),
        activityStart: Value(c.activityStart),
        source: Value(c.source),
        isOutdoor: Value(c.isOutdoor),
        qualifies: Value(c.qualifies),
        durationMinutes: Value(c.durationMinutes),
        temperatureC: Value(c.temperatureC),
        humidityPct: Value(c.humidityPct),
        pressureHpa: Value(c.pressureHpa),
        wetBulbC: Value(c.wetBulbC),
        scoreBefore: Value(c.scoreBefore),
        scoreAfter: Value(c.scoreAfter),
        weatherCacheKey: Value(c.weatherCacheKey),
        rawJson: Value(c.rawJson),
      ),
    );
  }

  Future<HeatWorkoutContextData?> _buildContextForActivity(
    ActivityRecord a, {
    double? scoreBeforeOverride,
  }) async {
    final start = _extractStartLocation(a);
    final outdoor = start != null && _isOutdoorActivity(a);
    final minutes = a.durationSeconds / 60;

    if (!outdoor) {
      final before =
          scoreBeforeOverride ??
          (await _getStateForActivityDate(a.startDate))?.score ??
          0.0;
      return HeatWorkoutContextData(
        activityId: a.activityId,
        activityStart: a.startDate,
        source: a.source ?? 'unknown',
        isOutdoor: false,
        qualifies: false,
        durationMinutes: minutes,
        scoreBefore: before,
        scoreAfter: before,
      );
    }

    // Weather at the start point.
    final snapshot = await _snapshotForPoint(a.startDate, start.lat, start.lng);
    final temp = snapshot?.temperatureC;
    final wetBulb = snapshot?.wetBulbC;
    final qualifies = temp != null && temp >= 22.0 && minutes >= 30.0;

    var before = scoreBeforeOverride;
    if (before == null) {
      final prev = await _getStateForActivityDate(a.startDate);
      before = prev?.score ?? 0.0;
    }
    final after = qualifies
        ? math.min(
            100.0,
            before + _activityHeatGain(minutes, temp, wetBulb ?? temp),
          )
        : before;

    return HeatWorkoutContextData(
      activityId: a.activityId,
      activityStart: a.startDate,
      source: a.source ?? 'unknown',
      isOutdoor: true,
      qualifies: qualifies,
      durationMinutes: minutes,
      temperatureC: temp,
      humidityPct: snapshot?.humidityPct,
      pressureHpa: snapshot?.pressureHpa,
      wetBulbC: wetBulb,
      scoreBefore: before,
      scoreAfter: after,
      weatherCacheKey: snapshot?.cacheKey,
      rawJson: snapshot != null ? jsonEncode(snapshot.toJson()) : null,
    );
  }

  /// Previous day's score with one day of decay applied.
  Future<HeatDailyStateData?> _getStateForActivityDate(DateTime date) async {
    final prev = await _getState(_day(date).subtract(const Duration(days: 1)));
    if (prev == null) return null;
    return HeatDailyStateData(
      date: prev.date,
      score: math.max(0.0, prev.score - prev.score * _dailyDecay),
      status: prev.status,
      decayApplied: prev.decayApplied,
      workoutGain: prev.workoutGain,
      lastActivityId: prev.lastActivityId,
      recommendation: prev.recommendation,
      updatedAt: prev.updatedAt,
    );
  }

  static double _activityHeatGain(
    double minutes,
    double tempC,
    double wetBulbC,
  ) {
    final base = tempC >= 30
        ? 15.0
        : tempC >= 26
        ? 12.0
        : 10.0;
    final humidity = wetBulbC >= 28
        ? 2.0
        : wetBulbC >= 24
        ? 1.0
        : 0.0;
    final durationBonus = ((minutes - 30) / 30).clamp(0.0, 1.0) * 2;
    return (base + humidity + durationBonus).clamp(8.0, 15.0);
  }

  Future<WeatherSnapshotData?> _snapshotForPoint(
    DateTime at,
    double lat,
    double lng,
  ) async {
    final cached = await _db.getWeatherSnapshotNear(lat, lng, at);
    if (cached != null) {
      return WeatherSnapshotData(
        cacheKey: cached.cacheKey,
        source: cached.source,
        observedAt: cached.observedAt,
        latitude: cached.latitude,
        longitude: cached.longitude,
        temperatureC: cached.temperatureC,
        humidityPct: cached.humidityPct,
        pressureHpa: cached.pressureHpa,
        wetBulbC: cached.wetBulbC,
        rawJson: cached.rawJson,
      );
    }
    if (at.isAfter(DateTime.now())) return null;
    try {
      final snap = await _weather.fetchSnapshot(
        latitude: lat,
        longitude: lng,
        at: at,
      );
      if (snap.observedAt.difference(at).abs() > const Duration(hours: 2)) {
        return null;
      }
      await _upsertWeatherSnapshot(snap);
      return snap;
    } catch (e) {
      log('[Heat] weather fetch error: $e');
      return null;
    }
  }

  Future<void> _upsertWeatherSnapshot(WeatherSnapshotData s) async {
    await _db.upsertWeatherSnapshot(
      WeatherSnapshotRecordsCompanion(
        cacheKey: Value(s.cacheKey),
        source: Value(s.source),
        observedAt: Value(s.observedAt),
        latitude: Value(s.latitude),
        longitude: Value(s.longitude),
        temperatureC: Value(s.temperatureC),
        humidityPct: Value(s.humidityPct),
        pressureHpa: Value(s.pressureHpa),
        wetBulbC: Value(s.wetBulbC),
        rawJson: Value(s.rawJson),
      ),
    );
  }

  static bool _isOutdoorActivity(ActivityRecord a) {
    final type = a.type.toLowerCase();
    const indoor = [
      'indoor',
      'treadmill',
      'virtual',
      'strength',
      'yoga',
      'swim',
    ];
    return !indoor.any(type.contains);
  }

  LatLng? _extractStartLocation(ActivityRecord a) {
    final points = decodeStoredJson(
      a.gpxJson,
      what: 'route of ${a.activityId}',
    );
    if (points is! List || points.isEmpty) return null;
    final first = points.first as Map<String, dynamic>;
    final lat = (first['lat'] as num?)?.toDouble();
    final lng = (first['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Future<HeatDailyStateData?> _getState(DateTime day) async {
    final r = await _db.getHeatStateForDate(day);
    if (r == null) return null;
    return HeatDailyStateData(
      date: r.date,
      score: r.score,
      status: HeatStatus.values.byName(r.status),
      decayApplied: r.decayApplied,
      workoutGain: r.workoutGain,
      lastActivityId: r.lastActivityId,
      recommendation: r.recommendation,
      updatedAt: r.updatedAt,
    );
  }

  /// Fixed location from settings, otherwise the device location.
  Future<CurrentLocationData?> getPreferredLocation() async {
    final settings = await _settings.load();
    if (settings.locationMode == HeatLocationMode.none) return null;
    if (settings.locationMode == HeatLocationMode.fixed &&
        settings.fixedLatitude != null &&
        settings.fixedLongitude != null) {
      return CurrentLocationData(
        latitude: settings.fixedLatitude!,
        longitude: settings.fixedLongitude!,
        timestamp: DateTime.now(),
      );
    }
    return _location.getCurrentLocation();
  }

  Future<HeatPlanForecast?> forecastForCurrentLocation(DateTime at) async {
    if (!await isEnabled) return null;
    final loc = await getPreferredLocation();
    if (loc == null) return null;
    return forecastForLocation(at, loc.latitude, loc.longitude);
  }

  Future<HeatPlanForecast?> forecastForLocation(
    DateTime at,
    double lat,
    double lng,
  ) async {
    if (!await isEnabled) return null;
    final snap = await _snapshotForPoint(at, lat, lng);
    if (snap == null) return null;
    return const HeatPlanForecast();
  }

  Future<HeatDailyStateData?> getTodayState() async {
    if (!await isEnabled) return null;
    return _getState(_day(DateTime.now()));
  }

  /// Fetches hourly weather along recent outdoor activities in bulk so the
  /// heat module and activity screens have it offline.
  Future<void> prefetchWeatherForActivities(
    List<ActivityRecord> activities,
  ) async {
    if (!await isEnabled) return;
    final cutoff = DateTime.now().subtract(const Duration(days: 1));
    final outdoor = activities
        .where(
          (a) =>
              a.startDate.isBefore(cutoff) &&
              _isOutdoorActivity(a) &&
              _extractStartLocation(a) != null,
        )
        .toList();

    // Bucket by ~1 km start location so one hourly request covers several.
    final buckets = <String, List<ActivityRecord>>{};
    for (final a in outdoor) {
      final p = _extractStartLocation(a)!;
      final key = '${p.lat.toStringAsFixed(2)}_${p.lng.toStringAsFixed(2)}';
      buckets.putIfAbsent(key, () => []).add(a);
    }

    var saved = 0;
    for (final entry in buckets.entries) {
      final acts = entry.value;
      final start = acts
          .map((a) => a.startDate)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final end = acts
          .map((a) => a.startDate.add(Duration(seconds: a.durationSeconds)))
          .reduce((a, b) => a.isAfter(b) ? a : b);
      if (end.difference(start).inHours > 24 * 31) continue;
      final p = _extractStartLocation(acts.first)!;
      if (await _db.getWeatherSnapshotNear(p.lat, p.lng, start) != null)
        continue;
      log(
        '[Heat] bulk weather fetch: bucket ${entry.key} '
        '${start.toIso8601String().substring(0, 10)} → '
        '${end.toIso8601String().substring(0, 10)} (${acts.length} activities)',
      );
      try {
        final result = await _weather.fetchHourlyWeather(
          latitude: p.lat,
          longitude: p.lng,
          start: start,
          end: end,
        );
        for (final h in result.points) {
          final key =
              '${result.source}:${p.lat.toStringAsFixed(6)}:'
              '${p.lng.toStringAsFixed(6)}:${h.time.toIso8601String()}';
          await _upsertWeatherSnapshot(
            WeatherSnapshotData(
              cacheKey: key,
              source: result.source,
              observedAt: h.time,
              latitude: p.lat,
              longitude: p.lng,
              temperatureC: h.temperatureC,
              humidityPct: h.humidityPct,
              pressureHpa: h.pressureHpa,
              wetBulbC: OpenMeteoClient.wetBulbC(h.temperatureC, h.humidityPct),
              rawJson: '',
            ),
          );
          saved++;
        }
      } catch (e) {
        log('[Heat] bulk weather fetch error for ${entry.key}: $e');
      }
    }
    log('[Heat] bulk weather: saved $saved hourly snapshots');
  }

  Future<HeatWorkoutContextData?> processActivity(ActivityRecord a) async {
    if (!await isEnabled) return null;
    final ctx = await _buildContextForActivity(a);
    if (ctx != null) await _upsertWorkoutContext(ctx);
    return ctx;
  }
}
