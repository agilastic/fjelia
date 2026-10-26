import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../api/polar_flow_web_client.dart';
import '../config/secrets.dart';
import '../db/database.dart';
import '../models/heart_rate.dart';
import '../models/device_hr_zones.dart';
import 'device_zone_store.dart';
import 'source_priority_service.dart';
import 'tcx_parser.dart';
import 'fit_activity_data.dart';
import 'polar_exercise_data.dart';
import '../utils/log.dart';
import 'oauth_token_store.dart';
import 'open_meteo_client.dart' show dayKey;

class PolarSyncResult {
  PolarSyncResult({
    this.exercises = 0,
    this.sleep = 0,
    this.hrv = 0,
    this.daily = 0,
    this.error,
  });

  int exercises;
  int sleep;
  int hrv;
  int daily;
  String? error;
}

class _PolarUser {
  const _PolarUser({required this.userId, this.email});

  factory _PolarUser.fromJson(Map<String, dynamic> json) => _PolarUser(
    userId: json['userId'].toString(),
    email: json['email'] as String?,
  );

  final String userId;
  final String? email;

  Map<String, dynamic> toJson() => {'userId': userId, 'email': email};
}

/// Polar AccessLink v3: exercises, sleep, nightly recharge and daily activity.
class PolarService {
  PolarService(
    this._db, {
    http.Client? client,
    PolarFlowWebClient Function()? flowClientFactory,
  }) : _http = client ?? http.Client(),
       _flowClientFactory = flowClientFactory ?? PolarFlowWebClient.new;

  final AppDatabase _db;
  final http.Client _http;
  final PolarFlowWebClient Function() _flowClientFactory;

  static const _api = 'https://www.polaraccesslink.com/v3';
  static const _tokenUrl = 'https://polarremote.com/v2/oauth2/token';
  static const _clientId = Secrets.polarClientId;
  static const _clientSecret = Secrets.polarClientSecret;
  static const _source = 'polar';
  static const _userKey = 'polar_auth_v1';
  static const _flowEmailKey = 'polar_flow_email';
  static const _flowPasswordKey = 'polar_flow_password';
  static const _timeout = Duration(seconds: 20);
  static const _storage = FlutterSecureStorage();

  static String get _basic {
    if (!Secrets.hasPolar) throw Secrets.missing('Polar');
    return 'Basic ${base64Encode(utf8.encode('$_clientId:$_clientSecret'))}';
  }

  static String buildAuthUrl() {
    if (!Secrets.hasPolar) throw Secrets.missing('Polar');
    return Uri.parse('https://flow.polar.com/oauth2/authorization')
        .replace(
          queryParameters: {'response_type': 'code', 'client_id': _clientId},
        )
        .toString();
  }

  Future<bool> get isConnected async =>
      await oauthTokenStore.load(_source) != null && await _loadUser() != null;

  Future<String?> get connectedEmail async => (await _loadUser())?.email;

  // -------------------------------------------------------------------------
  // Flow website login: older history and planned workout delivery
  // -------------------------------------------------------------------------

  /// A Polar Flow login is stored for history imports and planned workouts.
  Future<bool> get hasFlowLogin async =>
      await _storage.read(key: _flowEmailKey) != null &&
      await _storage.read(key: _flowPasswordKey) != null;

  Future<String?> get flowLoginEmail => _storage.read(key: _flowEmailKey);

  /// Uses the same stored login as the importer, with a separate cookie session
  /// so delivering a workout cannot interfere with an import in progress.
  Future<T> withFlowClient<T>(
    Future<T> Function(PolarFlowWebClient client) action,
  ) async {
    final email = await _storage.read(key: _flowEmailKey);
    final password = await _storage.read(key: _flowPasswordKey);
    if (email == null || password == null) {
      throw PolarFlowException(
        'Save your Polar Flow login in Settings, Connections, Polar to send workouts.',
      );
    }
    final web = _flowClientFactory();
    try {
      await web.login(email, password);
      return await action(web);
    } finally {
      web.close();
    }
  }

  /// Signs in to Polar Flow to check the login, then keeps it in the keychain.
  /// Throws [PolarFlowException] when the sign-in fails.
  Future<void> saveFlowLogin(
    String email,
    String password, {
    PolarFlowWebClient? client,
  }) async {
    final web = client ?? PolarFlowWebClient();
    try {
      await web.login(email.trim(), password);
    } finally {
      if (client == null) web.close();
    }
    await _storage.write(key: _flowEmailKey, value: email.trim());
    await _storage.write(key: _flowPasswordKey, value: password);
  }

  Future<void> clearFlowLogin() async {
    await _storage.delete(key: _flowEmailKey);
    await _storage.delete(key: _flowPasswordKey);
  }

  /// The AccessLink API only returns the last 30 days. For the history import
  /// the stored Flow login reads the diary and imports each older session from
  /// its TCX export. Returns the number of sessions saved. Does nothing (0)
  /// without a stored login. Best-effort: sessions that fail are skipped.
  Future<int> importFlowHistory({
    required int days,
    PolarFlowWebClient? client,
    void Function(String message)? onProgress,
  }) async {
    final email = await _storage.read(key: _flowEmailKey);
    final password = await _storage.read(key: _flowPasswordKey);
    if (email == null || password == null) return 0;
    final web = client ?? PolarFlowWebClient();
    var saved = 0;
    try {
      await web.login(email, password);
      final today = DateTime.now();
      final end = DateTime(today.year, today.month, today.day);
      final begin = end.subtract(Duration(days: days));
      final existing = {
        for (final a in await _db.getActivitiesInRange(days + 7))
          if (a.source == _source) a.activityId: a,
      };
      final processed = <String>{};
      // One diary request per calendar month keeps the answers small.
      var cursor = DateTime(begin.year, begin.month);
      while (!cursor.isAfter(end)) {
        final next = DateTime(cursor.year, cursor.month + 1);
        final from = cursor.isBefore(begin) ? begin : cursor;
        final to = next.subtract(const Duration(days: 1)).isAfter(end)
            ? end
            : next.subtract(const Duration(days: 1));
        onProgress?.call('Polar Flow: ${from.year}-${from.month}');
        final list = await web.workouts(from, to);
        for (final w in list) {
          final id = 'polar_flow_${w.id}';
          if (!processed.add(id)) continue;
          // Old Flow imports stored neither speed nor altitude samples. Refill
          // those rows once, without requiring the user to delete a workout.
          final stored = existing[id];
          if (stored?.metricsJson != null &&
              _mapSport(stored!.type) != 'other') {
            continue;
          }
          if ((w.durationSeconds ?? 120) < 60) continue; // recording noise
          try {
            final xml = await web.exportTcx(w);
            final session = parseTcx(xml, source: _source);
            if (session == null || session.durationSeconds < 60) continue;
            FitActivityData? fit;
            Map<String, dynamic>? summary;
            try {
              fit = parseFitActivity(await web.exportFit(w));
            } catch (error) {
              log('[Polar] Flow FIT ${w.id} unavailable: ${error.runtimeType}');
            }
            try {
              final response = await web.trainingSummary(w);
              if ('${response['id']}' == w.id) summary = response;
            } catch (error) {
              log(
                '[Polar] Flow summary ${w.id} unavailable: ${error.runtimeType}',
              );
            }
            if (await _saveFlowSession(
              w,
              session,
              fit: fit,
              summary: summary,
            )) {
              saved++;
            }
          } catch (error) {
            log('[Polar] Flow session ${w.id} skipped: ${error.runtimeType}');
          }
        }
        cursor = next;
      }
      log('[Polar] Flow history: $saved sessions imported');
    } finally {
      if (client == null) web.close();
    }
    return saved;
  }

  Future<bool> _saveFlowSession(
    PolarFlowWorkout w,
    TcxSession t, {
    FitActivityData? fit,
    Map<String, dynamic>? summary,
  }) async {
    final id = 'polar_flow_${w.id}';
    final sameDay = await _db.getActivitiesForDate(t.start.toLocal());
    final priority = await priorityForGroup(SourceGroup.activity);
    final duplicate = sameDay.where(
      (a) =>
          a.activityId != id &&
          a.startDate.difference(t.start).inMinutes.abs() <= 2 &&
          (a.durationSeconds - t.durationSeconds).abs() <=
              t.durationSeconds * 0.05,
    );
    if (duplicate.isNotEmpty &&
        !shouldOverwrite(duplicate.first.source, _source, priority)) {
      return false;
    }
    // Reject an export for a different recording instead of combining its
    // totals and samples with this TCX session.
    if (fit != null &&
        ((fit.start != null &&
                fit.start!.difference(t.start).inSeconds.abs() > 120) ||
            (fit.timerSeconds != null &&
                (fit.timerSeconds! - t.durationSeconds).abs() >
                    t.durationSeconds * .05))) {
      fit = null;
    }
    final existing = await _db.getActivityById(id);
    final type = _activityType([w.sport, t.sport, fit?.sport, existing?.type]);
    // A previously imported workout may already have all its metrics but an
    // unresolved sport. Correct only its type and generated name in that case.
    if (existing?.metricsJson != null && _mapSport(existing!.type) == 'other') {
      if (type == 'other') return false;
      await (_db.update(
        _db.activityRecords,
      )..where((row) => row.activityId.equals(id))).write(
        ActivityRecordsCompanion(
          type: Value(type),
          name:
              const {
                'workout',
                'other',
                'polar other',
                'polar generic',
              }.contains(existing.name.trim().toLowerCase())
              ? Value('Polar $type')
              : const Value.absent(),
        ),
      );
      return true;
    }
    final samples = t.samples.any((sample) => sample['spd'] != null)
        ? t.samples
        : fit?.samples.isNotEmpty == true
        ? fit!.samples
        : t.samples;
    await _db.saveHeartRateSamples(
      t.heartRates.isNotEmpty
          ? t.heartRates
          : parseTimedHeartRates(samples, _source),
    );
    final sameRecording =
        existing != null &&
        existing.startDate.isAtSameMomentAs(t.start) &&
        existing.durationSeconds == t.durationSeconds;
    Value<T?> optional<T>(T? value) => value != null
        ? Value<T?>(value)
        : sameRecording
        ? Value<T?>.absent()
        : Value<T?>(null);
    final pro = summary?['trainingLoadPro'];
    final cardioLoad = pro is Map && pro['valid'] != false
        ? _flowNumber(pro['cardioLoadValue'])
        : null;
    final moving = fit?.movingSeconds;
    final route = t.route.isNotEmpty ? t.route : fit?.route;
    final companion = ActivityRecordsCompanion(
      activityId: Value(id),
      name: Value('Polar $type'),
      type: Value(type),
      startDate: Value(t.start),
      durationSeconds: Value(t.durationSeconds),
      distanceMeters: optional(
        t.distanceMeters ?? fit?.distanceMeters ?? w.distanceMeters,
      ),
      avgHeartRate: optional(
        _flowNumber(summary?['hrAverage']) ?? t.avgHeartRate,
      ),
      maxHeartRate: optional(_flowNumber(summary?['hrMax']) ?? t.maxHeartRate),
      trainingLoad: optional(
        cardioLoad ?? _flowNumber(summary?['trainingLoad']),
      ),
      avgWatts: optional(fit?.avgPower ?? _flowWeightedStat(summary, 'POWER')),
      avgRunCadence: optional(
        type == 'running' ? _flowWeightedStat(summary, 'CADENCE') : null,
      ),
      totalElevation: optional(
        fit?.ascentMeters ?? _flowTotal(summary, 'ascent'),
      ),
      movingDurationSeconds: optional(
        moving != null && moving >= 0 && moving <= t.durationSeconds + 1
            ? moving.round()
            : null,
      ),
      metricsJson: optional(samples.isEmpty ? null : jsonEncode(samples)),
      gpxJson: optional(
        route == null || route.isEmpty ? null : jsonEncode(route),
      ),
      source: const Value(_source),
    );
    if (existing != null) {
      await (_db.update(
        _db.activityRecords,
      )..where((t) => t.activityId.equals(id))).write(companion);
    } else {
      await _db.into(_db.activityRecords).insert(companion);
    }
    return true;
  }

  static double? _flowNumber(Object? raw) =>
      raw is num && raw.isFinite && raw >= 0 ? raw.toDouble() : null;

  static List<Map> _flowExercises(Map<String, dynamic>? summary) {
    final exercises = summary?['exercises'];
    return switch (exercises) {
      Map values => values.values.whereType<Map>().toList(),
      List values => values.whereType<Map>().toList(),
      _ => const [],
    };
  }

  static double? _flowTotal(Map<String, dynamic>? summary, String field) {
    final exercises = _flowExercises(summary);
    if (exercises.isEmpty) return null;
    var total = 0.0;
    for (final exercise in exercises) {
      final value = _flowNumber(exercise[field]);
      if (value == null) return null;
      total += value;
    }
    return total;
  }

  static double? _flowWeightedStat(Map<String, dynamic>? summary, String stat) {
    final exercises = _flowExercises(summary);
    if (exercises.isEmpty) return null;
    var weighted = 0.0, seconds = 0.0;
    for (final exercise in exercises) {
      final stats = exercise['trainingStatistic'];
      final values = stats is Map ? stats[stat] : null;
      final avg = values is Map ? _flowNumber(values['avg']) : null;
      final duration = exercise['duration'];
      final time = duration is String ? parsePolarDuration(duration) : 0;
      if (avg == null || time <= 0) return null;
      weighted += avg * time;
      seconds += time;
    }
    return seconds > 0 ? weighted / seconds : null;
  }

  /// Exchanges the OAuth code and registers the user with AccessLink.
  Future<bool> handleAuthCallback(String code) async {
    try {
      final response = await _http
          .post(
            Uri.parse(_tokenUrl),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json;charset=UTF-8',
              'Authorization': _basic,
            },
            body: {'grant_type': 'authorization_code', 'code': code},
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        log(
          '[Polar] token exchange failed: ${response.statusCode} ${response.body}',
        );
        return false;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final access = json['access_token'] as String;
      final userId = (json['x_user_id'] ?? json['user_id']).toString();
      await oauthTokenStore.save(
        _source,
        OAuthToken(
          accessToken: access,
          refreshToken: json['refresh_token'] as String?,
          expiresAt: DateTime.now().add(
            Duration(seconds: (json['expires_in'] as num? ?? 0).toInt()),
          ),
        ),
      );
      await _saveUser(_PolarUser(userId: userId));

      try {
        final reg = await _http
            .post(
              Uri.parse('$_api/users'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $access',
              },
              body: jsonEncode({'member-id': userId}),
            )
            .timeout(_timeout);
        if (reg.statusCode == 200 || reg.statusCode == 201) {
          log('[Polar] user registered with AccessLink');
        } else if (reg.statusCode == 409) {
          log('[Polar] user already registered with AccessLink');
        } else {
          log(
            '[Polar] user registration returned ${reg.statusCode}: ${reg.body}',
          );
        }
      } catch (e) {
        log('[Polar] user registration error: $e');
      }
      log('[Polar] auth OK — userId=$userId');
      return true;
    } catch (e) {
      log('[Polar] token exchange error: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    await Future.wait([
      oauthTokenStore.clear(_source),
      _storage.delete(key: _userKey),
      clearFlowLogin(),
    ]);
  }

  Future<PolarSyncResult> sync({int days = 30}) async {
    final result = PolarSyncResult();
    final user = await _loadUser();
    if (user == null || await oauthTokenStore.load(_source) == null) {
      log('[Polar] not connected — skipping sync');
      return result;
    }
    await _refreshIfNeeded();
    final to = DateTime.now();
    final from = to.subtract(Duration(days: days));
    log('[Polar] sync ${dayKey(from)} → ${dayKey(to)} userId=${user.userId}');
    await Future.wait([
      _syncExercises(result),
      _syncSleep(result, from, to),
      _syncNightlyRecharge(result),
      _syncDailyActivity(result, from, to),
    ]);
    log(
      '[Polar] done — exercises=${result.exercises} sleep=${result.sleep} '
      'hrv=${result.hrv} daily=${result.daily}',
    );
    return result;
  }

  Future<Map<String, String>> _headers() async {
    final token = await oauthTokenStore.load(_source);
    if (token == null) throw Exception('Polar: not authenticated');
    return {
      'Authorization': 'Bearer ${token.accessToken}',
      'Accept': 'application/json',
      'content-type': 'application/json',
    };
  }

  Future<bool> _refreshIfNeeded() async {
    if (!await oauthTokenStore.isExpired(_source)) return true;
    final token = await oauthTokenStore.load(_source);
    final refresh = token?.refreshToken;
    if (refresh == null) return false;
    try {
      final response = await _http
          .post(
            Uri.parse(_tokenUrl),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
              'Authorization': _basic,
            },
            body: {'grant_type': 'refresh_token', 'refresh_token': refresh},
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        log('[Polar] token refresh failed: ${response.statusCode}');
        return false;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      await oauthTokenStore.save(
        _source,
        OAuthToken(
          accessToken: json['access_token'] as String,
          refreshToken: json['refresh_token'] as String? ?? refresh,
          expiresAt: DateTime.now().add(
            Duration(seconds: (json['expires_in'] as num? ?? 0).toInt()),
          ),
        ),
      );
      log('[Polar] token refreshed');
      return true;
    } catch (e) {
      log('[Polar] token refresh error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _get(
    String path, {
    Map<String, String>? params,
  }) async {
    final uri = Uri.parse('$_api$path').replace(queryParameters: params);
    log('[Polar] GET $uri');
    final response = await _http
        .get(uri, headers: await _headers())
        .timeout(_timeout);
    if (response.statusCode == 401 || response.statusCode == 403) {
      log('[Polar] $path auth error ${response.statusCode}: ${response.body}');
      return null;
    }
    if (response.statusCode != 200) {
      log('[Polar] $path HTTP ${response.statusCode}: ${response.body}');
      return null;
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {'items': decoded};
  }

  /// AccessLink returns lists wrapped under varying keys.
  static List<Map<String, dynamic>> _listFrom(Object? decoded, String key) {
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    if (decoded is Map) {
      final v =
          decoded[key] ??
          (decoded.values.isNotEmpty ? decoded.values.first : null);
      if (v is List) return v.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  Future<void> _syncExercises(PolarSyncResult result) async {
    try {
      // samples/zones: HR samples and the user's Polar HR zones per exercise.
      final uri = Uri.parse('$_api/exercises')
          .replace(queryParameters: {'samples': 'true', 'zones': 'true'});
      log('[Polar] GET $uri');
      final response = await _http
          .get(uri, headers: await _headers())
          .timeout(_timeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        log(
          '[Polar] /exercises auth error ${response.statusCode}: ${response.body}',
        );
        return;
      }
      if (response.statusCode == 404) {
        log('[Polar] /exercises 404 — no data');
        return;
      }
      if (response.statusCode != 200) {
        result.error =
            '/exercises HTTP ${response.statusCode}: ${response.body}';
        return;
      }
      final body = response.body;
      log(
        '[Polar] /exercises raw: ${body.length > 1000 ? body.substring(0, 1000) : body}',
      );
      final items = _listFrom(jsonDecode(body), 'exercises');
      log('[Polar] /exercises parsed: ${items.length} items');
      for (final e in items) {
        try {
          if (await _saveExercise(e)) result.exercises++;
        } catch (error) {
          result.error ??= 'Some Polar exercises could not be imported.';
          log('[Polar] exercise ${e['id']} skipped: ${error.runtimeType}');
        }
      }
    } catch (e) {
      result.error = '/exercises: $e';
    }
  }

  Future<bool> _saveExercise(Map<String, dynamic> e) async {
    final exerciseId = '${e['id'] ?? ''}';
    final summary = PolarExerciseData.parse(e);
    if (exerciseId.isEmpty || summary == null) return false;
    final id = 'polar_$exerciseId';
    final start = summary.start;
    final duration = summary.durationSeconds;

    final existing = await _db.getActivityById(id);
    // Skip if the same workout from a higher-priority source is stored.
    final sameDay = await _db.getActivitiesForDate(start.toLocal());
    final priority = await priorityForGroup(SourceGroup.activity);
    final duplicate = sameDay.where(
      (a) =>
          a.activityId != id &&
          a.startDate.difference(start).inMinutes.abs() <= 2 &&
          (a.durationSeconds - duration).abs() <= duration * 0.02,
    );
    if (duplicate.isNotEmpty &&
        !shouldOverwrite(duplicate.first.source, _source, priority)) {
      return false;
    }

    final fit = await _fetchExerciseFit(exerciseId);
    final sport = _activityType([
      e['detailed_sport_info'],
      e['detailed-sport-info'],
      e['sport'],
      fit?.sport,
      existing?.type,
    ]);
    final sameRecording =
        existing != null &&
        existing.startDate.isAtSameMomentAs(start) &&
        existing.durationSeconds == duration;
    Object? previousSamples;
    if (sameRecording && existing.metricsJson != null) {
      try {
        previousSamples = jsonDecode(existing.metricsJson!);
      } on FormatException {
        // Fresh valid samples can repair an old unreadable column.
      }
    }
    final data =
        PolarExerciseData.parse(
          e,
          fit: fit,
          previousSamples: previousSamples,
        ) ??
        summary;
    final heartRates = parseTimedHeartRates(data.samples, _source);
    await _db.saveHeartRateSamples(
      heartRates.isNotEmpty
          ? heartRates
          : parseTimedHeartRates(
              e['samples'] ?? e['heart_rate_samples'],
              _source,
            ),
    );
    String? gpx;
    if (fit != null && fit.route.isNotEmpty) {
      gpx = jsonEncode(fit.route);
    } else if ((e['has_route'] ?? e['has-route']) == true &&
        (!sameRecording ||
            existing.gpxJson == null ||
            existing.gpxJson!.trim().isEmpty)) {
      gpx = await _fetchGpxJson(exerciseId);
    }
    final zones = parseHeartRateZones(
      e['heart_rate_zones'] ?? e['heart-rate-zones'],
    );
    if (zones != null) {
      await const DeviceZoneStore().save(_source, [
        DeviceHrZones(
          source: _source,
          sport: DeviceHrZones.sportKey(_mapSport(sport)),
          // Polar zones default to % of max HR.
          method: 'POLAR',
          floors: zones.floors,
          maxHr: zones.upper,
        ),
      ], merge: true);
    }
    // Missing enrichment can be kept for an unchanged recording. A trimmed or
    // moved recording must not inherit the old duration's moving time/metrics.
    Value<T?> optional<T>(T? value) => value != null
        ? Value<T?>(value)
        : sameRecording
        ? Value<T?>.absent()
        : Value<T?>(null);
    final companion = ActivityRecordsCompanion(
      activityId: Value(id),
      name: Value('Polar ${_mapSport(sport)}'),
      type: Value(_mapSport(sport)),
      startDate: Value(data.start),
      durationSeconds: Value(data.durationSeconds),
      distanceMeters: optional(data.distanceMeters),
      avgHeartRate: optional(data.avgHeartRate),
      maxHeartRate: optional(data.maxHeartRate),
      trainingLoad: optional(data.trainingLoad),
      avgWatts: optional(data.avgPower),
      totalElevation: optional(data.ascentMeters),
      movingDurationSeconds: optional(data.movingSeconds),
      metricsJson: optional(
        data.samples.isEmpty ? null : jsonEncode(data.samples),
      ),
      hrZonesJson: optional(
        zones == null || zones.percent.isEmpty
            ? null
            : jsonEncode(zones.percent),
      ),
      gpxJson: optional(gpx),
      source: const Value(_source),
    );
    if (existing != null) {
      await (_db.update(
        _db.activityRecords,
      )..where((t) => t.activityId.equals(id))).write(companion);
    } else {
      await _db.into(_db.activityRecords).insert(companion);
    }
    return true;
  }

  /// Calendar entries may omit the sport or supply a numeric id/generic
  /// label. Try the export and existing type before settling for "other".
  static String _activityType(Iterable<Object?> candidates) {
    for (final candidate in candidates) {
      if (candidate is! String) continue;
      final type = _mapSport(candidate);
      if (type != 'other') return type;
    }
    return 'other';
  }

  static String _mapSport(String sport) {
    final s = sport.toUpperCase();
    if (s.contains('RUNNING') || s.contains('RUN')) return 'running';
    if (s.contains('CYCLING') || s.contains('BIK')) return 'cycling';
    if (s.contains('SWIMMING') || s.contains('SWIM')) return 'swimming';
    if (s.contains('STRENGTH') || s.contains('GYM') || s.contains('WEIGHT')) {
      return 'strength';
    }
    if (s.contains('HIKING') || s.contains('HIKE')) return 'hiking';
    if (s.contains('WALKING') || s.contains('WALK')) return 'walking';
    if (s.contains('YOGA')) return 'yoga';
    if (s.contains('ROWING')) return 'rowing';
    if (s.contains('SKI')) return 'skiing';
    return 'other';
  }

  Future<FitActivityData?> _fetchExerciseFit(String exerciseId) async {
    try {
      final uri = Uri.parse(
        '$_api/exercises/${Uri.encodeComponent(exerciseId)}/fit',
      );
      final headers = Map<String, String>.of(await _headers())
        ..['Accept'] = '*/*';
      final response = await _http.get(uri, headers: headers).timeout(_timeout);
      if (response.statusCode != 200) {
        log('[Polar] FIT $exerciseId unavailable: HTTP ${response.statusCode}');
        return null;
      }
      final data = parseFitActivity(response.bodyBytes);
      if (data == null) log('[Polar] FIT $exerciseId could not be decoded');
      return data;
    } catch (e) {
      log(
        '[Polar] FIT enrichment unavailable for $exerciseId: ${e.runtimeType}',
      );
      return null;
    }
  }

  Future<String?> _fetchGpxJson(String exerciseId) async {
    try {
      final uri = Uri.parse('$_api/exercises/$exerciseId/gpx');
      log('[Polar] GET $uri');
      final headers = Map<String, String>.of(await _headers())
        ..['Accept'] = 'application/gpx+xml';
      final response = await _http.get(uri, headers: headers).timeout(_timeout);
      if (response.statusCode != 200) return null;
      final points = RegExp(r'<trkpt\s+lat="([^"]+)"\s+lon="([^"]+)"')
          .allMatches(response.body)
          .map(
            (m) => {
              'lat': double.parse(m.group(1)!),
              'lng': double.parse(m.group(2)!),
            },
          )
          .toList();
      log('[Polar] GPX $exerciseId: ${points.length} points');
      return points.isEmpty ? null : jsonEncode(points);
    } catch (e) {
      log('[Polar] GPX fetch error for $exerciseId: $e');
      return null;
    }
  }

  /// ISO-8601 duration (`PT1H2M3.5S`) → seconds.
  /// Polar `heart_rate_zones`: `[{index, lower_limit, upper_limit,
  /// in_zone: "PT2M30S"}, …]` → zone floors and time-in-zone percentages.
  static ({List<int> floors, int? upper, Map<String, double> percent})?
  parseHeartRateZones(Object? raw) {
    if (raw is! List || raw.length < 5) return null;
    final zones = raw.whereType<Map>().toList()
      ..sort(
        (a, b) =>
            ((a['index'] as num?) ?? 0).compareTo((b['index'] as num?) ?? 0),
      );
    if (zones.length < 5) return null;
    num? limit(Map z, String key) =>
        (z[key] ?? z[key.replaceAll('_', '-')]) as num?;
    final floors = <int>[];
    final seconds = <double>[];
    for (final z in zones.take(5)) {
      final lower = limit(z, 'lower_limit');
      if (lower == null) return null;
      floors.add(lower.round());
      final inZone = (z['in_zone'] ?? z['in-zone']) as String?;
      seconds.add(inZone == null ? 0 : _parseDuration(inZone).toDouble());
    }
    final total = seconds.fold<double>(0, (a, b) => a + b);
    return (
      floors: floors,
      upper: limit(zones[4], 'upper_limit')?.round(),
      percent: {
        if (total > 0)
          for (var i = 0; i < 5; i++) 'zone${i + 1}': seconds[i] / total * 100,
      },
    );
  }

  static int _parseDuration(String iso) => parsePolarDuration(iso);

  Future<void> _syncSleep(
    PolarSyncResult result,
    DateTime from,
    DateTime to,
  ) async {
    try {
      final json = await _get(
        '/users/sleep',
        params: {'from': dayKey(from), 'to': dayKey(to)},
      );
      log(
        '[Polar] /users/sleep keys: ${json?.keys.toList()} '
        'nights=${(json?['nights'] as List?)?.length ?? 'null'}',
      );
      for (final night in _listFrom(json, 'nights')) {
        if (await _saveSleepNight(night)) result.sleep++;
      }
    } catch (e) {
      result.error = '/users/sleep: $e';
    }
  }

  Future<bool> _saveSleepNight(Map<String, dynamic> n) async {
    final date = DateTime.tryParse(n['date'] as String? ?? '');
    if (date == null) return false;
    final light = (n['light_sleep'] as num?)?.toInt() ?? 0;
    final deep = (n['deep_sleep'] as num?)?.toInt() ?? 0;
    final rem = (n['rem_sleep'] as num?)?.toInt() ?? 0;
    final awake = (n['total_interruption_duration'] as num?)?.toInt() ?? 0;
    final score = (n['sleep_score'] as num?)?.toDouble();
    final start = DateTime.tryParse(n['sleep_start_time'] as String? ?? '');
    final end = DateTime.tryParse(n['sleep_end_time'] as String? ?? '');

    // Hypnogram: {"HH:MM": stage} → phases.
    String? phasesJson;
    final hyp = n['hypnogram'];
    if (hyp is Map && start != null) {
      final entries = hyp.entries.toList()
        ..sort((a, b) => '${a.key}'.compareTo('${b.key}'));
      final phases = <Map<String, String>>[];
      DateTime? at(String hm) {
        final p = hm.split(':');
        if (p.length != 2) return null;
        var t = DateTime(
          start.year,
          start.month,
          start.day,
          int.tryParse(p[0]) ?? 0,
          int.tryParse(p[1]) ?? 0,
        );
        if (t.isBefore(start.subtract(const Duration(hours: 1)))) {
          t = t.add(const Duration(days: 1));
        }
        return t;
      }

      for (var i = 0; i < entries.length; i++) {
        final s = at('${entries[i].key}');
        final e = i + 1 < entries.length ? at('${entries[i + 1].key}') : end;
        if (s == null || e == null) continue;
        final stage = switch ((entries[i].value as num?)?.toInt()) {
          1 || 2 => 'light',
          3 => 'deep',
          4 => 'rem',
          _ => 'awake',
        };
        phases.add({
          's': s.toUtc().toIso8601String(),
          'e': e.toUtc().toIso8601String(),
          'p': stage,
        });
      }
      phasesJson = jsonEncode(phases);
    }

    final hrSamples = n['heart_rate_samples'];
    if (hrSamples is Map && start != null) {
      final timed = <TimedHeartRate>[];
      for (final e in hrSamples.entries) {
        final clock = RegExp(r'^(\d{2}):(\d{2})(?::(\d{2}))?$')
            .firstMatch('${e.key}');
        var timestamp = heartRateTimestamp(e.key);
        if (timestamp == null && clock != null) {
          timestamp = DateTime(
            start.year,
            start.month,
            start.day,
            int.parse(clock[1]!),
            int.parse(clock[2]!),
            int.parse(clock[3] ?? '0'),
          );
          if (timestamp.isBefore(start)) {
            timestamp = DateTime(
              timestamp.year,
              timestamp.month,
              timestamp.day + 1,
              timestamp.hour,
              timestamp.minute,
              timestamp.second,
            );
          }
        }
        final bpm = e.value;
        if (timestamp != null && bpm is num && bpm.isFinite && bpm > 0) {
          timed.add(TimedHeartRate(timestamp, bpm.toDouble(), _source));
        }
      }
      await _db.saveHeartRateSamples(timed);
    }
    double? avgHr;
    if (hrSamples is Map && hrSamples.isNotEmpty) {
      final values = hrSamples.values
          .map((v) => (v as num).toDouble())
          .toList();
      avgHr = values.reduce((a, b) => a + b) / values.length;
    }

    final day = DateTime(date.year, date.month, date.day);
    {
      await _db.upsertSleep(
        SleepRecordsCompanion(
          date: Value(day),
          totalSleepSeconds: Value(light + deep + rem),
          deepSleepSeconds: Value(deep),
          remSleepSeconds: Value(rem),
          lightSleepSeconds: Value(light),
          awakeSleepSeconds: Value(awake),
          sleepScore: Value(score),
          sleepStart: Value(start),
          sleepEnd: Value(end),
          phasesJson: Value(phasesJson),
          source: const Value(_source),
        ),
      );
    }

    if (avgHr != null) {
      {
        await _db.upsertHrv(
          HrvRecordsCompanion(
            date: Value(day),
            restingHeartRate: Value(avgHr.round()),
            source: const Value(_source),
          ),
        );
      }
    }
    return true;
  }

  Future<void> _syncNightlyRecharge(PolarSyncResult result) async {
    try {
      final json = await _get('/users/nightly-recharge');
      final list = _listFrom(json, 'recharges');
      log(
        '[Polar] /users/nightly-recharge keys: ${json?.keys.toList()} '
        'recharges=${list.length}',
      );
      for (final r in list) {
        final date = DateTime.tryParse(r['date'] as String? ?? '');
        if (date == null) continue;
        if (await _saveNightlyRecharge(date, r)) result.hrv++;
      }
    } catch (e) {
      result.error = '/users/nightly-recharge: $e';
    }
  }

  Future<bool> _saveNightlyRecharge(
    DateTime date,
    Map<String, dynamic> r,
  ) async {
    final hrv =
        ((r['heart_rate_variability_avg'] ?? r['heart-rate-variability-avg'])
                as num?)
            ?.toDouble();
    final hr = ((r['heart_rate_avg'] ?? r['heart-rate-avg']) as num?)?.toInt();
    final breathing =
        ((r['breathing_rate_avg'] ?? r['breathing-rate-avg']) as num?)
            ?.toDouble();
    final samples = r['hrv_samples'] ?? r['hrv-samples'];
    String? intraday;
    if (samples is Map) {
      final day = DateTime(date.year, date.month, date.day);
      final points = samples.entries
          .map<List<int>?>((e) {
            final p = '${e.key}'.split(':');
            final v = (e.value as num?)?.toInt();
            if (p.length != 2 || v == null) return null;
            final t = day
                .subtract(const Duration(days: 1))
                .add(
                  Duration(
                    hours: int.tryParse(p[0]) ?? 0,
                    minutes: int.tryParse(p[1]) ?? 0,
                  ),
                );
            return [t.millisecondsSinceEpoch, v];
          })
          .whereType<List<int>>()
          .toList();
      if (points.isNotEmpty) intraday = jsonEncode(points);
    }

    final day = DateTime(date.year, date.month, date.day);
    await _db.upsertHrv(
      HrvRecordsCompanion(
        date: Value(day),
        hrvLastNight: Value(hrv),
        restingHeartRate: Value(hr),
        respirationRate: Value(breathing),
        hrvIntradayJson: Value(intraday),
        source: const Value(_source),
      ),
    );
    return true;
  }

  Future<void> _syncDailyActivity(
    PolarSyncResult result,
    DateTime from,
    DateTime to,
  ) async {
    try {
      final uri = Uri.parse('$_api/users/activities')
          .replace(queryParameters: {'from': dayKey(from), 'to': dayKey(to)});
      log('[Polar] GET $uri');
      final response = await _http
          .get(uri, headers: await _headers())
          .timeout(_timeout);
      if (response.statusCode != 200) {
        result.error = '/users/activities HTTP ${response.statusCode}';
        return;
      }
      final body = response.body;
      log(
        '[Polar] /users/activities raw: '
        '${body.length > 600 ? body.substring(0, 600) : body}',
      );
      final items = _listFrom(jsonDecode(body), 'activities');
      log('[Polar] /users/activities parsed: ${items.length} items');
      for (final a in items) {
        if (await _saveDailyActivity(a)) result.daily++;
      }
    } catch (e) {
      result.error = '/users/activities: $e';
    }
  }

  Future<bool> _saveDailyActivity(Map<String, dynamic> a) async {
    final start = DateTime.tryParse(
      (a['start_time'] ?? a['start-time'] ?? '') as String,
    );
    if (start == null) return false;
    final steps = (a['steps'] as num?)?.toInt();
    final calories = (a['calories'] as num?)?.toInt();
    final active = ((a['active_calories'] ?? a['active-calories']) as num?)
        ?.toInt();
    final day = DateTime(start.year, start.month, start.day);
    if (steps == null && calories == null) {
      log('[Polar] activity ${dayKey(day)}: no steps/cal — skipping');
      return false;
    }
    await _db.upsertWellness(
      WellnessRecordsCompanion(
        date: Value(day),
        steps: Value(steps),
        totalCalories: Value(calories),
        activeCalories: Value(active),
        source: const Value(_source),
      ),
    );
    return true;
  }

  Future<_PolarUser?> _loadUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    return _PolarUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _saveUser(_PolarUser user) =>
      _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
}
