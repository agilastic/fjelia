import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../api/coros_workout.dart';
import '../models/prepared_workout.dart';
import '../api/coros_client.dart';
import '../db/database.dart';
import '../models/heart_rate.dart';
import '../utils/log.dart';
import 'workout_providers/cleanup_queue.dart';
import 'workout_providers/delivery_ledger.dart';

class CorosSyncResult {
  CorosSyncResult();

  int activities = 0;
  int activitiesSeen = 0;
  int skipped = 0;
  int hrv = 0;
  int sleep = 0;
  int daily = 0;
  bool authError = false;
  String? error;
}

class _ActivitySaveResult {
  const _ActivitySaveResult(this.saved, [this.reason = '']);

  static const missingLabelId = _ActivitySaveResult(false, 'missing_label_id');
  static const missingStart = _ActivitySaveResult(false, 'missing_start');
  static const ok = _ActivitySaveResult(true);

  final bool saved;
  final String reason;
}

/// COROS Training Hub: activities, daily HRV / RHR / VO₂max / steps and
/// (best-effort) detailed sleep.
///
/// This is a thin orchestrator over [CorosClient]. It persists the session and
/// the credentials in the keychain, decides when to (re)log in (web tokens last
/// about a day), and maps the raw data the client fetches into the local
/// database. All HTTP lives in [CorosClient].
class CorosService {
  CorosService(
    this._db, {
    http.Client? client,
    void Function(String line)? trace,
  }) : _client = CorosClient(client: client, trace: trace);

  final AppDatabase _db;
  final CorosClient _client;

  static const _source = 'coros';
  static const _storage = FlutterSecureStorage();

  String _dateStr(DateTime d) {
    final l = d.toLocal();
    return '${l.year}${l.month.toString().padLeft(2, '0')}'
        '${l.day.toString().padLeft(2, '0')}';
  }

  /// `yyyyMMdd` → DateTime.
  DateTime? _parseDay(String s) {
    if (s.length < 8) return null;
    return DateTime(
      int.parse(s.substring(0, 4)),
      int.parse(s.substring(4, 6)),
      int.parse(s.substring(6, 8)),
    );
  }

  int? _toInt(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    final s = '$v';
    return int.tryParse(s) ?? _parseHms(s);
  }

  double? _toDouble(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  double? _nonZeroDouble(Object? v) {
    final d = _toDouble(v);
    return d == null || d == 0 ? null : d;
  }

  /// `H:MM:SS` or `MM:SS` → seconds.
  int? _parseHms(String s) {
    final parts = s.split(':').map(int.tryParse).toList();
    if (parts.any((p) => p == null) || parts.isEmpty) return null;
    if (parts.length == 3) return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
    if (parts.length == 2) return parts[0]! * 60 + parts[1]!;
    return parts[0];
  }

  // ── connection ────────────────────────────────────────────────────────────

  Future<bool> get isConnected async => await _loadAuth() != null;

  Future<String?> get connectedEmail async => (await _loadAuth())?.email;

  /// Signs in and, on success, keeps the session and the credentials in the
  /// keychain (so later syncs can renew the token silently). Returns `false`
  /// when the credentials are rejected.
  Future<bool> login(
    String email,
    String password, {
    String region = 'eu',
  }) async {
    try {
      await _client.login(email, password, region: region);
    } on CorosException catch (e) {
      log('[Coros] login failed: $e');
      return false;
    }
    final auth = _client.auth;
    if (auth == null) return false;
    await _saveAuth(auth);
    await _storage.write(key: 'coros_password', value: password);
    await _storage.write(key: 'coros_region', value: region);
    return true;
  }

  /// Re-logs in with the stored credentials to renew an expired token.
  Future<bool> _relogin() async {
    final auth = await _loadAuth();
    final password = await _storage.read(key: 'coros_password');
    final region = await _storage.read(key: 'coros_region') ?? 'eu';
    if (auth?.email == null || password == null) return false;
    final ok = await login(auth!.email!, password, region: region);
    log(ok ? '[Coros] silent relogin OK' : '[Coros] silent relogin failed: ');
    return ok;
  }

  Future<void> disconnect() async {
    await _storage.delete(key: 'coros_auth_v1');
    await _storage.delete(key: 'coros_password');
    await _storage.delete(key: 'coros_region');
  }

  // ── workouts ──────────────────────────────────────────────────────────────

  /// Before the shared ledger, what was sent was kept here, as the
  /// fingerprint per session.
  static const _legacySentKey = 'coros_workouts_sent_v1';

  late final DeliveryLedger _ledger = DeliveryLedger(_db, 'coros');
  late final CleanupQueue _queue = CleanupQueue(_db, 'coros');

  /// Carries what an earlier version kept in secure storage into the ledger,
  /// once: the fingerprints stay, so nothing is sent a second time.
  Future<void> _importLegacySent() async {
    final raw = await _storage.read(key: _legacySentKey);
    if (raw == null) return;
    try {
      for (final e in (jsonDecode(raw) as Map).entries) {
        final v = e.value;
        final map = v is num ? {'fp': v} : Map<String, dynamic>.from(v as Map);
        if (await _ledger.get(e.key as String) != null) continue;
        await _ledger.put(
          e.key as String,
          fingerprint: '${map['fp']}',
          day: map['day'] as String?,
          name: map['name'] as String?,
        );
      }
    } catch (_) {}
    await _storage.delete(key: _legacySentKey);
  }

  /// Whether this session's workout is on the COROS calendar.
  Future<bool> hasDelivered(String sessionId) async {
    await _importLegacySent();
    return await _ledger.get(sessionId) != null;
  }

  static String _dayKey(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';

  /// Puts a planned workout on the COROS calendar through the Training Hub's
  /// unpublished interface. The same workout on the same day is not sent
  /// twice. A changed or moved one is sent again, and the earlier entry is
  /// taken off the calendar first. Throws [CorosUnsupportedWorkout] for a
  /// sport or step COROS has no form for, and [CorosException] when COROS
  /// refuses.
  Future<void> pushWorkout(PreparedWorkout workout) async {
    final built = buildCorosWorkout(
      workout,
      firstId: 1000000 + DateTime.now().millisecondsSinceEpoch % 90000000,
      createdAtSeconds: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    await _importLegacySent();
    final earlier = await _ledger.get(workout.sessionId);
    final day = _dayKey(workout.date);
    if (earlier != null &&
        earlier.fingerprint == '${built.fingerprint}' &&
        earlier.day == day) {
      throw CorosException('This workout is already on your COROS calendar.');
    }
    var auth = await _loadAuth();
    if (auth == null) throw CorosException('COROS is not connected.');
    if (auth.isExpired && await _relogin()) auth = await _loadAuth();
    _client.adopt(auth!);
    Future<void> send() async {
      await _removeEarlier(earlier);
      await _client.uploadWorkout(built, workout.date);
    }

    try {
      await send();
    } on CorosAuthException {
      // The token went stale between the check and the call: renew once.
      if (!await _relogin()) rethrow;
      _client.adopt((await _loadAuth())!);
      await send();
    }
    await _ledger.put(
      workout.sessionId,
      fingerprint: '${built.fingerprint}',
      day: day,
      name: '${built.program['name']}',
    );
    log(
      '[Coros] workout sent for ${workout.date.toIso8601String().substring(0, 10)}',
    );
  }

  /// Takes the earlier send of a session off the calendar, so a changed or
  /// moved workout does not appear twice. Best effort: an entry that cannot be
  /// found or removed is left, and the new one is sent anyway. Sends made by
  /// earlier versions carry no day and are left alone.
  Future<void> _removeEarlier(WorkoutDelivery? earlier) async {
    final day = earlier?.day;
    final name = earlier?.name;
    if (day == null || name == null || day.length != 8) return;
    try {
      await _removeByDayAndName(day, name);
    } on CorosAuthException {
      rethrow;
    } catch (e) {
      log('[Coros] earlier workout not removed: $e');
    }
  }

  Future<void> _signIn() async {
    var auth = await _loadAuth();
    if (auth == null) throw CorosException('COROS is not connected.');
    if (auth.isExpired && await _relogin()) auth = await _loadAuth();
    _client.adopt(auth!);
  }

  /// Takes the entries named [name] off the calendar on [day] (`yyyyMMdd`).
  Future<void> _removeByDayAndName(String day, String name) async {
    final d = DateTime(
      int.parse(day.substring(0, 4)),
      int.parse(day.substring(4, 6)),
      int.parse(day.substring(6, 8)),
    );
    Future<void> run() async {
      for (final e in await _client.calendarWorkouts(d, d)) {
        if (e.name == name) await _client.removeCalendarWorkout(e);
      }
    }

    await _signIn();
    try {
      await run();
    } on CorosAuthException {
      if (!await _relogin()) rethrow;
      _client.adopt((await _loadAuth())!);
      await run();
    }
  }

  /// Takes one session's workout off the COROS calendar and forgets it. A
  /// removal that fails is queued for a later retry and does not throw.
  Future<void> removeDelivered(String sessionId) async {
    await _importLegacySent();
    final record = await _ledger.get(sessionId);
    if (record == null) return;
    final day = record.day, name = record.name;
    if (day != null && name != null && day.length == 8) {
      try {
        await _removeByDayAndName(day, name);
      } catch (e) {
        log('[Coros] removal failed for $name on $day: $e');
        await _queue.add('$day|$name', error: e);
      }
    }
    await _ledger.delete(sessionId);
  }

  /// Tries the removals that failed earlier. Returns how many went.
  Future<int> retryCleanup() => _queue.retry((remoteId, _) async {
    final at = remoteId.indexOf('|');
    await _removeByDayAndName(
      remoteId.substring(0, at),
      remoteId.substring(at + 1),
    );
  });

  /// Takes the workouts Fjelia sent off the COROS calendar: entries from
  /// today on, over the next [months] months, whose name is one of [titles].
  /// Other workouts stay. Returns how many were removed; [onProgress] hears
  /// each one.
  Future<int> removeSentWorkouts(
    Set<String> titles, {
    int months = 6,
    void Function(int done, int total)? onProgress,
  }) async {
    await _importLegacySent();
    if ((await _ledger.all()).isEmpty) return 0;
    if (await _loadAuth() == null) return 0;
    await _signIn();
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final found = <CorosCalendarEntry>[];
    // The calendar answers in ranges; ask a month at a time.
    for (var m = 0; m < months; m++) {
      final from = DateTime(
        start.year,
        start.month + m,
        m == 0 ? start.day : 1,
      );
      final to = DateTime(start.year, start.month + m + 1, 0);
      found.addAll(await _client.calendarWorkouts(from, to));
    }
    final mine = found.where((e) => titles.contains(e.name)).toList();
    var done = 0;
    for (final e in mine) {
      await _client.removeCalendarWorkout(e);
      onProgress?.call(++done, mine.length);
    }
    await _ledger.deleteAll();
    log('[Coros] removed ${mine.length} workouts from the calendar');
    return mine.length;
  }

  // ── sync ──────────────────────────────────────────────────────────────────

  Future<CorosSyncResult> sync({int days = 30}) async {
    var auth = await _loadAuth();
    if (auth == null) {
      log('[Coros] not connected — skipping sync');
      return CorosSyncResult();
    }
    if (auth.isExpired) {
      log('[Coros] token expired — attempting silent relogin');
      if (await _relogin()) auth = await _loadAuth();
    }
    // The (possibly renewed) session now drives every client call. It is
    // non-null here: it was either kept (a failed renew) or reloaded (a
    // successful one).
    _client.adopt(auth!);
    final to = DateTime.now();
    final from = to.subtract(Duration(days: days));
    log('[Coros] sync ${_dateStr(from)} → ${_dateStr(to)}');

    Future<CorosSyncResult> run() async {
      final r = CorosSyncResult();
      await Future.wait([
        _syncActivities(r, from, to),
        _syncDailyMetrics(r, from, to),
        _syncSleep(r, from, to),
      ]);
      return r;
    }

    var result = await run();
    if (result.authError) {
      log('[Coros] mid-sync auth error — attempting silent relogin and retry');
      if (await _relogin()) {
        // _relogin() refreshed the client's token via login().
        result = await run();
      }
    }
    log(
      '[Coros] done — activities=${result.activities}/${result.activitiesSeen} '
      'skipped=${result.skipped} hrv=${result.hrv} sleep=${result.sleep} '
      'daily=${result.daily}',
    );
    return result;
  }

  Future<void> _syncSleep(CorosSyncResult r, DateTime from, DateTime to) async {
    List<Map<String, dynamic>> days;
    try {
      days = await _client.sleep(from, to);
    } catch (e) {
      log('[Coros] sleep sync error: $e');
      r.error = 'sleep: $e';
      return;
    }
    for (final d in days) {
      if (await _saveSleep(d)) r.sleep++;
    }
  }

  Future<bool> _saveSleep(Map<String, dynamic> d) async {
    final day = _parseDay('${d['happenDay'] ?? ''}');
    final sleep = d['sleepData'] as Map<String, dynamic>?;
    if (day == null || sleep == null) return false;
    final total = _toInt(sleep['totalSleepTime']) ?? 0;
    if (total <= 0) return false;
    // COROS reports sleep stages in minutes.
    await _db.upsertSleep(
      SleepRecordsCompanion(
        date: Value(day),
        totalSleepSeconds: Value(total * 60),
        deepSleepSeconds: Value((_toInt(sleep['deepTime']) ?? 0) * 60),
        lightSleepSeconds: Value((_toInt(sleep['lightTime']) ?? 0) * 60),
        remSleepSeconds: Value((_toInt(sleep['eyeTime']) ?? 0) * 60),
        awakeSleepSeconds: Value((_toInt(sleep['wakeTime']) ?? 0) * 60),
        source: const Value(_source),
      ),
    );
    return true;
  }

  Future<void> _syncDailyMetrics(
    CorosSyncResult r,
    DateTime from,
    DateTime to,
  ) async {
    Map<String, Map<String, dynamic>> byDay;
    try {
      byDay = await _client.dailyMetrics(from, to);
    } on CorosAuthException {
      r.authError = true;
      return;
    } catch (e) {
      log('[Coros] daily metrics error: $e');
      r.error = 'daily: $e';
      return;
    }
    for (final entry in byDay.entries) {
      final saved = await _saveDayMetrics(entry.key, entry.value);
      r.daily += saved.$1;
      r.hrv += saved.$2;
    }
  }

  Future<(int, int)> _saveDayMetrics(String key, Map<String, dynamic> m) async {
    final day = _parseDay(key);
    if (day == null) return (0, 0);
    var daily = 0, hrvSaved = 0;

    final hrv = _toDouble(m['avgSleepHrv']);
    final rhr = _toInt(m['rhr']);
    if (hrv != null || rhr != null) {
      {
        await _db.upsertHrv(
          HrvRecordsCompanion(
            date: Value(day),
            hrvLastNight: Value(hrv),
            restingHeartRate: Value(rhr),
            source: const Value(_source),
          ),
        );
        hrvSaved = 1;
      }
    }

    final vo2 = _toDouble(m['vo2max']);
    final steps = _toInt(m['stepCount'] ?? m['steps']);
    if (vo2 != null || steps != null) {
      {
        await _db.upsertWellness(
          WellnessRecordsCompanion(
            date: Value(day),
            steps: Value(steps),
            vo2max: Value(vo2),
            source: const Value(_source),
          ),
        );
        daily = 1;
      }
    }
    return (daily, hrvSaved);
  }

  Future<void> _syncActivities(
    CorosSyncResult r,
    DateTime from,
    DateTime to,
  ) async {
    final seenBefore = r.activitiesSeen;
    Future<void> onRow(Map<String, dynamic> row) async {
      r.activitiesSeen++;
      final saved = await _saveActivity(row);
      if (saved.saved) {
        r.activities++;
      } else {
        r.skipped++;
        log(
          '[Coros] activity skipped labelId=${row['labelId']} '
          'reason=${saved.reason} keys=${row.keys.join(',')}',
        );
      }
    }

    try {
      await _client.activities(from: from, to: to, onRow: onRow);
    } on CorosAuthException {
      r.authError = true;
      return;
    } catch (e) {
      log('[Coros] activity sync error: $e');
      r.error = 'activities: $e';
      return;
    }
    if (r.activitiesSeen == seenBefore && !r.authError) {
      log('[Coros] activities date range empty — retrying latest page');
      try {
        await _client.activities(maxPages: 1, onRow: onRow);
      } on CorosAuthException {
        r.authError = true;
      } catch (e) {
        log('[Coros] activity sync error: $e');
        r.error = 'activities: $e';
      }
    }
  }

  Future<_ActivitySaveResult> _saveActivity(Map<String, dynamic> row) async {
    final labelId = row['labelId']?.toString();
    if (labelId == null || labelId.isEmpty) {
      return _ActivitySaveResult.missingLabelId;
    }
    final start = _parseActivityStart(row);
    if (start == null) return _ActivitySaveResult.missingStart;
    final duration = _parseActivityDuration(row) ?? 0;
    final id = 'coros:$labelId';
    final existing = await (_db.select(
      _db.activityRecords,
    )..where((t) => t.activityId.equals(id))).getSingleOrNull();
    final sportType = _toInt(row['sportType']);

    // Detail call only when training effects are still missing.
    final needDetail = existing?.aerobicTrainingEffect == null;
    log(
      '[Coros] detail needed=$needDetail for $labelId '
      '(existing=${existing != null}, aerobicTE=${existing?.aerobicTrainingEffect})',
    );
    final detail = needDetail
        ? await _client.activityDetail(labelId, sportType)
        : null;
    final merged = {...row, ...?detail};

    final name = (row['name'] as String?)?.trim();
    await _db.saveHeartRateSamples(
      parseTimedHeartRates(
        merged['samples'] ?? merged['heartRateSamples'],
        _source,
      ),
    );
    final companion = ActivityRecordsCompanion(
      activityId: Value(id),
      name: Value(name == null || name.isEmpty ? 'COROS Activity' : name),
      type: Value(_activityType(row)),
      startDate: Value(start),
      durationSeconds: Value(duration),
      distanceMeters: Value(_toDouble(row['distance'] ?? row['total'])),
      avgHeartRate: Value(_nonZeroDouble(row['avgHr'])),
      maxHeartRate: Value(_nonZeroDouble(row['maxHr'])),
      trainingLoad: Value(_corosTrainingLoad(merged, duration)),
      avgWatts: Value(_nonZeroDouble(row['avgPower'] ?? row['np'])),
      totalElevation: Value(_nonZeroDouble(row['ascent'])),
      avgRunCadence: Value(_nonZeroDouble(row['avgCadence'])),
      aerobicTrainingEffect: Value(_toDouble(merged['aerobicTE'])),
      anaerobicTrainingEffect: Value(_toDouble(merged['anaerobicTE'])),
      recoveryTimeSeconds: Value(_toInt(merged['recoveryTimeSeconds'])),
      activityFeedbackPhrase: Value(merged['trainingFocus'] as String?),
      vo2maxActivity: Value(_toDouble(merged['vo2max'])),
      source: const Value(_source),
    );
    if (existing != null) {
      await (_db.update(
        _db.activityRecords,
      )..where((t) => t.activityId.equals(id))).write(companion);
    } else {
      await _db.into(_db.activityRecords).insert(companion);
    }
    return _ActivitySaveResult.ok;
  }

  /// COROS' own load when present, else minutes × aerobic TE factor.
  double? _corosTrainingLoad(Map<String, dynamic> m, int durationSec) {
    final load = _nonZeroDouble(m['trainingLoad']);
    if (load != null) return load;
    final te = _toDouble(m['aerobicTE']);
    if (te == null) return null;
    return durationSec / 60 * (te / 3.0).clamp(0.3, 2.0);
  }

  String _activityType(Map<String, dynamic> row) {
    final sport = (row['sportName'] as String?)?.trim();
    if (sport != null && sport.isNotEmpty) return sport.toLowerCase();
    final mode = (row['modeName'] as String?)?.trim();
    if (mode != null && mode.isNotEmpty) return mode.toLowerCase();
    final type = _toInt(row['sportType']);
    return type != null ? _corosSportTypeName(type) : 'coros';
  }

  String _corosSportTypeName(int type) => switch (type) {
    100 || 101 || 102 || 103 => 'running',
    200 || 201 || 202 || 203 || 204 => 'cycling',
    300 || 301 => 'swimming',
    400 || 401 || 402 => 'strength',
    _ => 'coros_$type',
  };

  int? _parseActivityDuration(Map<String, dynamic> row) {
    for (final key in const [
      'workoutTime',
      'totalTime',
      'duration',
      'activityTime',
    ]) {
      final v = _toInt(row[key]);
      if (v != null && v > 0) return v;
    }
    for (final key in const ['workoutTimeText', 'totalTimeText']) {
      final v = row[key];
      if (v is String) return _parseHms(v);
    }
    return null;
  }

  DateTime? _parseActivityStart(Map<String, dynamic> row) {
    final ts = _toInt(row['startTime'] ?? row['happenTime']);
    if (ts != null && ts > 0) {
      // Seconds or milliseconds depending on the endpoint.
      final ms = ts > 100000000000 ? ts : ts * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    }
    final date = _toInt(row['date']);
    return date != null ? _parseDay('$date') : null;
  }

  /// Track points (`lat`/`lng`) of one activity, via the GPX export.
  Future<List<Map<String, double>>?> fetchGpxTrack(
    String labelId,
    int? sportType,
  ) async {
    final auth = await _loadAuth();
    if (auth == null) return null;
    _client.adopt(auth);
    return await _client.gpxTrack(labelId, sportType);
  }

  Future<CorosAuth?> _loadAuth() async {
    final raw = await _storage.read(key: 'coros_auth_v1');
    if (raw == null) return null;
    return CorosAuth.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _saveAuth(CorosAuth auth) =>
      _storage.write(key: 'coros_auth_v1', value: jsonEncode(auth.toJson()));
}
