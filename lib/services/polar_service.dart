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
  PolarService(this._db, {http.Client? client})
    : _http = client ?? http.Client();

  final AppDatabase _db;
  final http.Client _http;

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
  // Older history from the Flow website (optional, history import only)
  // -------------------------------------------------------------------------

  /// A Polar Flow login is stored for the one-time history import.
  Future<bool> get hasFlowLogin async =>
      await _storage.read(key: _flowEmailKey) != null &&
      await _storage.read(key: _flowPasswordKey) != null;

  Future<String?> get flowLoginEmail => _storage.read(key: _flowEmailKey);

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
      final existingIds = {
        for (final a in await _db.getActivitiesInRange(days + 7))
          if (a.source == _source) a.activityId,
      };
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
          if (existingIds.contains('polar_flow_${w.id}')) continue;
          if ((w.durationSeconds ?? 120) < 60) continue; // recording noise
          try {
            final xml = await web.exportTcx(w);
            final session = parseTcx(xml, source: _source);
            if (session == null || session.durationSeconds < 60) continue;
            if (await _saveFlowSession(w, session)) saved++;
          } on PolarFlowException catch (e) {
            log('[Polar] Flow session ${w.id} skipped: $e');
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

  Future<bool> _saveFlowSession(PolarFlowWorkout w, TcxSession t) async {
    final id = 'polar_flow_${w.id}';
    final sameDay = await _db.getActivitiesForDate(t.start);
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
    await _db.saveHeartRateSamples(t.heartRates);
    final type = _mapSport(w.sport ?? t.sport);
    final companion = ActivityRecordsCompanion(
      activityId: Value(id),
      name: Value('Polar $type'),
      type: Value(type),
      startDate: Value(t.start),
      durationSeconds: Value(t.durationSeconds),
      distanceMeters: Value(t.distanceMeters ?? w.distanceMeters),
      avgHeartRate: Value(t.avgHeartRate),
      maxHeartRate: Value(t.maxHeartRate),
      gpxJson: t.route.isEmpty
          ? const Value.absent()
          : Value(jsonEncode(t.route)),
      source: const Value(_source),
    );
    if (await _db.getActivityById(id) != null) {
      await (_db.update(
        _db.activityRecords,
      )..where((t) => t.activityId.equals(id))).write(companion);
    } else {
      await _db.into(_db.activityRecords).insert(companion);
    }
    return true;
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
    if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    if (decoded is Map) {
      final v =
          decoded[key] ??
          (decoded.values.isNotEmpty ? decoded.values.first : null);
      if (v is List) return v.cast<Map<String, dynamic>>();
    }
    return const [];
  }

  Future<void> _syncExercises(PolarSyncResult result) async {
    try {
      // samples/zones: HR samples and the user's Polar HR zones per exercise.
      final uri = Uri.parse(
        '$_api/exercises',
      ).replace(queryParameters: {'samples': 'true', 'zones': 'true'});
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
        if (await _saveExercise(e)) result.exercises++;
      }
    } catch (e) {
      result.error = '/exercises: $e';
    }
  }

  Future<bool> _saveExercise(Map<String, dynamic> e) async {
    final id = 'polar_${e['id']}';
    final start = DateTime.tryParse(
      (e['start_time'] ?? e['start-time'] ?? '') as String,
    );
    if (start == null) return false;
    final duration = _parseDuration(e['duration'] as String? ?? '');
    final sport = (e['sport'] ?? 'GENERIC') as String;
    final distance = (e['distance'] as num?)?.toDouble();
    final hr = (e['heart_rate'] ?? e['heart-rate']) as Map<String, dynamic>?;
    final avgHr = (hr?['average'] as num?)?.toDouble();
    final maxHr = (hr?['maximum'] as num?)?.toDouble();

    final existing = await _db.getActivityById(id);
    // Skip if the same workout from a higher-priority source is stored.
    final sameDay = await _db.getActivitiesForDate(start);
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

    await _db.saveHeartRateSamples(
      parseTimedHeartRates(e['samples'] ?? e['heart_rate_samples'], _source),
    );
    final gpx = e['has_route'] == true
        ? await _fetchGpxJson('${e['id']}')
        : null;
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
    final companion = ActivityRecordsCompanion(
      activityId: Value(id),
      name: Value('Polar ${_mapSport(sport)}'),
      type: Value(_mapSport(sport)),
      startDate: Value(start),
      durationSeconds: Value(duration),
      distanceMeters: Value(distance),
      avgHeartRate: Value(avgHr),
      maxHeartRate: Value(maxHr),
      hrZonesJson: zones == null || zones.percent.isEmpty
          ? const Value.absent()
          : Value(jsonEncode(zones.percent)),
      gpxJson: Value(gpx),
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

  static int _parseDuration(String iso) {
    final m = RegExp(
      r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?',
    ).firstMatch(iso);
    if (m == null) return 0;
    final h = int.tryParse(m.group(1) ?? '0') ?? 0;
    final min = int.tryParse(m.group(2) ?? '0') ?? 0;
    final s = double.tryParse(m.group(3) ?? '0') ?? 0.0;
    return h * 3600 + min * 60 + s.round();
  }

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
        final clock = RegExp(
          r'^(\d{2}):(\d{2})(?::(\d{2}))?$',
        ).firstMatch('${e.key}');
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
      final uri = Uri.parse(
        '$_api/users/activities',
      ).replace(queryParameters: {'from': dayKey(from), 'to': dayKey(to)});
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
