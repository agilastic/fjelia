import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fjelia_service/fjelia_service.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart'
    show SuuntoRequestSigner;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../db/database.dart';
import '../models/heart_rate.dart';
import '../utils/log.dart';
import 'source_priority_service.dart';

class _DayActivity {
  int steps = 0;
  double energy = 0.0;
  final List<double> hr = [];
  final List<double> hrv = [];
  final List<double> spo2 = [];
}

class SuuntoSyncResult {
  SuuntoSyncResult();

  int sleep = 0;
  int activity = 0;
  int recovery = 0;
  int workouts = 0;
  String? error;
}

class _SuuntoAuth {
  const _SuuntoAuth({
    required this.sessionKey,
    this.email,
    this.phoneNumber,
    required this.timestampMs,
  });

  factory _SuuntoAuth.fromJson(Map<String, dynamic> json) => _SuuntoAuth(
    sessionKey: json['sessionKey'] as String,
    email: json['email'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
    timestampMs: json['timestampMs'] as int,
  );

  final String sessionKey;
  final String? email;
  final String? phoneNumber;
  final int timestampMs;

  /// Sessions are valid for 30 days.
  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch - timestampMs > 2592000000;

  Map<String, dynamic> toJson() => {
    'sessionKey': sessionKey,
    'email': email,
    'phoneNumber': phoneNumber,
    'timestampMs': timestampMs,
  };
}

/// Suunto (Sports Tracker 24/7 API): sleep, daily activity and recovery.
/// Login is by SMS PIN; every request carries a TOTP derived from the app
/// secret salted with the account identifier.
class SuuntoService {
  SuuntoService(this._db, {http.Client? client, SuuntoRequestSigner? signer})
    : _http = client ?? http.Client(),
      _signer = signer ?? createSuuntoSigner();

  final AppDatabase _db;
  final http.Client _http;
  final SuuntoRequestSigner _signer;

  static const _source = 'suunto';
  static const _authKey = 'suunto_auth_v1';
  static const _storage = FlutterSecureStorage();

  Future<bool> get isConnected async {
    final auth = await _loadAuth();
    return auth != null && !auth.isExpired;
  }

  Future<String?> get connectedEmail async {
    final auth = await _loadAuth();
    return auth?.email ?? auth?.phoneNumber;
  }

  Future<void> disconnect() => _storage.delete(key: _authKey);

  /// Suunto cannot be reached without the signer of the service package.
  void _requireSigner() {
    if (!_signer.isAvailable) {
      throw StateError('Suunto is not available in this build.');
    }
  }

  Map<String, String> _preAuthHeaders(String phone) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'x-totp': _signer.totp(phone),
  };

  Map<String, String> _headers(_SuuntoAuth auth) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'STTAuthorization': auth.sessionKey,
    'x-totp': _signer.totp(auth.email ?? auth.phoneNumber ?? ''),
  };

  Future<bool> requestSmsPin(String phone) async {
    _requireSigner();
    try {
      final response = await _http.post(
        Uri.parse('https://api.sports-tracker.com/apiserver/auth/sms'),
        headers: _preAuthHeaders(phone),
        body: jsonEncode({'phonenumber': phone}),
      );
      final json = jsonDecode(response.body);
      final ok =
          json is Map &&
          (json['result'] == 'ok' || (json['status'] as num? ?? 400) < 400);
      if (!ok) {
        log('[Suunto] SMS request failed: ${response.body}');
        return false;
      }
      log('[Suunto] SMS sent to $phone');
      return true;
    } catch (e) {
      log('[Suunto] SMS request exception: $e');
      return false;
    }
  }

  Future<bool> verifyPin(String phone, String pin, {String? email}) async {
    _requireSigner();
    try {
      final response = await _http.post(
        Uri.parse('https://api.sports-tracker.com/apiserver/auth/sms/verify'),
        headers: _preAuthHeaders(phone),
        body: jsonEncode({'phonenumber': phone, 'pin': pin}),
      );
      log('[Suunto] PIN verify HTTP ${response.statusCode}: ${response.body}');
      final body = response.body.trim();
      String? key;
      if (body.startsWith('{')) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        key =
            (json['sessionkey'] ??
                    json['sessionKey'] ??
                    (json['data'] as Map?)?['sessionkey'])
                as String?;
      } else {
        key = body.replaceAll('"', '');
      }
      if (key == null || key.isEmpty) {
        log('[Suunto] empty session key');
        return false;
      }
      await _saveAuth(
        _SuuntoAuth(
          sessionKey: key,
          email: email,
          phoneNumber: phone,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      log('[Suunto] login OK');
      return true;
    } catch (e) {
      log('[Suunto] PIN verify exception: $e');
      return false;
    }
  }

  Future<SuuntoSyncResult> sync({int days = 30}) async {
    final result = SuuntoSyncResult();
    final auth = await _loadAuth();
    if (auth == null) {
      log('[Suunto] not connected — skipping sync');
      return result;
    }
    if (auth.isExpired) {
      log('[Suunto] session expired — please reconnect in Settings');
      return result;
    }
    final since = DateTime.now().subtract(Duration(days: days));
    log('[Suunto] sync last $days days (since $since)');
    await Future.wait([
      _syncSleep(auth, result, since),
      _syncActivity(auth, result, since),
      _syncRecovery(auth, result, since),
      _syncWorkouts(auth, result, since),
    ]);
    log(
      '[Suunto] done — sleep=${result.sleep} activity=${result.activity} '
      'recovery=${result.recovery} workouts=${result.workouts}',
    );
    return result;
  }

  int? _toInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v');
  double? _toDouble(Object? v) =>
      v is num ? v.toDouble() : double.tryParse('$v');

  DateTime? _parseTimestamp(Object? v) {
    if (v is num) {
      return DateTime.fromMillisecondsSinceEpoch(v.toInt()).toLocal();
    }
    return v == null ? null : DateTime.tryParse('$v')?.toLocal();
  }

  Future<List<Map<String, dynamic>>> _export(
    _SuuntoAuth auth,
    String kind,
    DateTime since,
  ) async {
    final uri = Uri.parse(
      'https://247.sports-tracker.com/v1/$kind/export',
    ).replace(queryParameters: {'since': '${since.millisecondsSinceEpoch}'});
    final response = await _http.get(uri, headers: _headers(auth));
    if (response.statusCode != 200) {
      throw Exception('$kind HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded.cast<Map<String, dynamic>>() : const [];
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Workouts from the Sports Tracker backend behind the Suunto app,
  /// mapped to the shared activity fields.
  Future<void> _syncWorkouts(
    _SuuntoAuth auth,
    SuuntoSyncResult r,
    DateTime since,
  ) async {
    try {
      final uri = Uri.parse(
        'https://api.sports-tracker.com/apiserver/v1/workouts',
      ).replace(queryParameters: {'limited': 'true', 'limit': '1000'});
      final response = await _http.get(uri, headers: _headers(auth));
      if (response.statusCode != 200) {
        log('[Suunto] workouts HTTP ${response.statusCode}');
        return;
      }
      final decoded = jsonDecode(response.body);
      final list = decoded is Map ? decoded['payload'] : decoded;
      if (list is! List) return;
      final workouts = list.whereType<Map<String, dynamic>>().toList();
      if (workouts.isNotEmpty) {
        log('[Suunto] workout keys: ${workouts.first.keys.toList()}');
      }
      final priority = await priorityForGroup(SourceGroup.activity);
      for (final w in workouts) {
        final start = _parseTimestamp(w['startTime']);
        if (start == null || start.isBefore(since)) continue;
        if (await _saveWorkout(w, start, priority)) r.workouts++;
      }
    } catch (e) {
      log('[Suunto] workouts error: $e');
      r.error ??= 'workouts: $e';
    }
  }

  Future<bool> _saveWorkout(
    Map<String, dynamic> w,
    DateTime start,
    List<String> priority,
  ) async {
    final key = w['workoutKey'] ?? w['key'] ?? w['id'];
    if (key == null) return false;
    final id = 'suunto_$key';
    final duration = (_toDouble(w['totalTime']) ?? 0).round();
    if (duration <= 0) return false;
    final hr = w['hrdata'] is Map ? w['hrdata'] as Map : const {};
    double? pick(List<Object?> values) {
      for (final v in values) {
        final d = _toDouble(v);
        if (d != null && d > 0) return d;
      }
      return null;
    }

    final sameDay = await _db.getActivitiesForDate(start);
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
    final type = _mapActivity(_toInt(w['activityId']));
    final companion = ActivityRecordsCompanion(
      activityId: Value(id),
      name: Value('Suunto ${type.replaceAll('_', ' ')}'),
      type: Value(type),
      startDate: Value(start),
      durationSeconds: Value(duration),
      distanceMeters: Value(pick([w['totalDistance']])),
      avgHeartRate: Value(
        pick([hr['workoutAvgHR'], hr['avg'], w['avgHr'], w['heartRateAvg']]),
      ),
      maxHeartRate: Value(
        pick([hr['workoutMaxHR'], hr['max'], w['maxHr'], w['heartRateMax']]),
      ),
      totalElevation: Value(pick([w['totalAscent']])),
      source: const Value(_source),
    );
    final existing = await _db.getActivityById(id);
    if (existing != null) {
      await (_db.update(
        _db.activityRecords,
      )..where((t) => t.activityId.equals(id))).write(companion);
    } else {
      await _db.into(_db.activityRecords).insert(companion);
    }
    return true;
  }

  /// Sports Tracker activity ids (common ones).
  static String _mapActivity(int? id) => switch (id) {
    0 => 'walking',
    1 => 'running',
    2 => 'cycling',
    3 => 'cross_country_skiing',
    11 => 'hiking',
    21 => 'swimming',
    22 => 'trail_running',
    23 => 'strength_training',
    _ => 'other',
  };

  Future<void> _syncRecovery(
    _SuuntoAuth auth,
    SuuntoSyncResult r,
    DateTime since,
  ) async {
    try {
      final entries = await _export(auth, 'recovery', since);
      // Keep the latest entry per day.
      final latest = <DateTime, Map<String, dynamic>>{};
      for (final e in entries) {
        final ts = _parseTimestamp(e['timestamp']);
        if (ts == null) continue;
        final data = Map<String, dynamic>.of(
          (e['entryData'] as Map?)?.cast<String, dynamic>() ?? const {},
        )..['_ts'] = ts;
        final day = _day(ts);
        final prev = latest[day];
        if (prev == null || (prev['_ts'] as DateTime).isBefore(ts)) {
          latest[day] = data;
        }
      }
      for (final entry in latest.entries) {
        if (await _saveRecoveryDay(entry.key, entry.value)) r.recovery++;
      }
    } catch (e) {
      log('[Suunto] recovery sync error: $e');
      r.error = 'recovery: $e';
    }
  }

  Future<bool> _saveRecoveryDay(DateTime day, Map<String, dynamic> data) async {
    final balance = _toDouble(data['balance']);
    final stress = _toInt(data['stressState']);
    if (balance == null && stress == null) return false;
    await _db.upsertHrv(
      HrvRecordsCompanion(
        date: Value(day),
        bodyBattery: Value(balance != null ? balance * 100 : null),
        stressLevel: Value(stress?.toDouble()),
        source: const Value(_source),
      ),
    );
    return true;
  }

  Future<void> _syncActivity(
    _SuuntoAuth auth,
    SuuntoSyncResult r,
    DateTime since,
  ) async {
    try {
      final entries = await _export(auth, 'activity', since);
      final days = <DateTime, _DayActivity>{};
      final timedHr = <TimedHeartRate>[];
      for (final e in entries) {
        final ts = _parseTimestamp(e['timestamp']);
        final data = e['entryData'] as Map?;
        if (ts == null || data == null) continue;
        final day = days.putIfAbsent(_day(ts), _DayActivity.new);
        day.steps += _toInt(data['stepCount']) ?? 0;
        day.energy += _toDouble(data['energyConsumption']) ?? 0.0;
        final hr = _toDouble(data['hr']);
        if (hr != null && hr > 0) {
          day.hr.add(hr);
          timedHr.add(TimedHeartRate(ts, hr, _source));
        }
        final hrv = _toDouble(data['hrv']);
        if (hrv != null && hrv > 0) day.hrv.add(hrv);
        final spo2 = _toDouble(data['spo2']);
        if (spo2 != null && spo2 > 0) day.spo2.add(spo2);
      }
      await _db.saveHeartRateSamples(timedHr);
      for (final entry in days.entries) {
        if (await _saveActivityDay(entry.key, entry.value)) r.activity++;
      }
    } catch (e) {
      log('[Suunto] activity sync error: $e');
      r.error = 'activity: $e';
    }
  }

  Future<bool> _saveActivityDay(DateTime day, _DayActivity a) async {
    double? avg(List<double> v) =>
        v.isEmpty ? null : v.reduce((x, y) => x + y) / v.length;
    var saved = false;

    if (a.steps > 0 || a.energy > 0 || a.spo2.isNotEmpty) {
      await _db.upsertWellness(
        WellnessRecordsCompanion(
          date: Value(day),
          steps: Value(a.steps > 0 ? a.steps : null),
          // Energy is reported in joules.
          totalCalories: Value(a.energy > 0 ? (a.energy / 4184).round() : null),
          avgSpo2: Value(avg(a.spo2)),
          source: const Value(_source),
        ),
      );
      saved = true;
    }

    if (a.hr.isNotEmpty || a.hrv.isNotEmpty || a.spo2.isNotEmpty) {
      await _db.upsertHrv(
        HrvRecordsCompanion(
          date: Value(day),
          restingHeartRate: Value(
            a.hr.isEmpty ? null : a.hr.reduce((x, y) => x < y ? x : y).round(),
          ),
          hrvLastNight: Value(avg(a.hrv)),
          spo2: Value(avg(a.spo2)),
          source: const Value(_source),
        ),
      );
      saved = true;
    }
    return saved;
  }

  Future<void> _syncSleep(
    _SuuntoAuth auth,
    SuuntoSyncResult r,
    DateTime since,
  ) async {
    try {
      final entries = await _export(auth, 'sleep', since);
      // Longest sleep per day.
      final best = <DateTime, Map<String, dynamic>>{};
      for (final e in entries) {
        final ts = _parseTimestamp(e['timestamp']);
        final data = (e['entryData'] as Map?)?.cast<String, dynamic>();
        if (ts == null || data == null) continue;
        final duration = _toDouble(data['duration']) ?? 0.0;
        final day = _day(ts);
        final prev = best[day];
        if (prev == null || (_toDouble(prev['duration']) ?? 0.0) < duration) {
          best[day] = {...data, '_ts': ts};
        }
      }
      for (final entry in best.entries) {
        if (await _saveSleepDay(entry.key, entry.value)) r.sleep++;
      }
    } catch (e) {
      log('[Suunto] sleep sync error: $e');
      r.error = 'sleep: $e';
    }
  }

  Future<bool> _saveSleepDay(DateTime day, Map<String, dynamic> d) async {
    final total = (_toDouble(d['duration']) ?? 0).round();
    if (total <= 0) return false;
    final deep = (_toDouble(d['deepSleepDuration']) ?? 0).round();
    final light = (_toDouble(d['lightSleepDuration']) ?? 0).round();
    final rem = (_toDouble(d['remSleepDuration']) ?? 0).round();
    final awake = (total - deep - light - rem).clamp(0, total);
    final start = _parseTimestamp(d['bedtimeStart']);
    final end = _parseTimestamp(d['bedtimeEnd']);
    final avgHrv = _toDouble(d['avgHrv']);

    await _db.upsertSleep(
      SleepRecordsCompanion(
        date: Value(day),
        totalSleepSeconds: Value(total - awake),
        deepSleepSeconds: Value(deep),
        lightSleepSeconds: Value(light),
        remSleepSeconds: Value(rem),
        awakeSleepSeconds: Value(awake),
        sleepStart: Value(start),
        sleepEnd: Value(end),
        avgOvernightHrv: Value(avgHrv),
        source: const Value(_source),
      ),
    );
    if (avgHrv != null) {
      {
        await _db.upsertHrv(
          HrvRecordsCompanion(
            date: Value(day),
            hrvLastNight: Value(avgHrv),
            source: const Value(_source),
          ),
        );
      }
    }
    return true;
  }

  Future<_SuuntoAuth?> _loadAuth() async {
    final raw = await _storage.read(key: _authKey);
    if (raw == null) return null;
    return _SuuntoAuth.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _saveAuth(_SuuntoAuth auth) =>
      _storage.write(key: _authKey, value: jsonEncode(auth.toJson()));
}
