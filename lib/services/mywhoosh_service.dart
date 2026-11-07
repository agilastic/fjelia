import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../api/mywhoosh_client.dart';
import '../db/database.dart';
import '../utils/log.dart';
import 'activity_file_import_service.dart';
import 'dfa_alpha1_service.dart';
import 'source_priority_service.dart';

class MyWhooshSyncResult {
  int rides = 0;
  String? error;

  /// The session ended and the stored password no longer signs in.
  bool authError = false;
}

/// MyWhoosh indoor rides: the activity list of the account and each ride's
/// FIT file, with power, cadence and heart rate second by second.
class MyWhooshService {
  MyWhooshService(this._db, {http.Client? client})
    : _client = MyWhooshClient(client: client);

  final AppDatabase _db;
  final MyWhooshClient _client;

  static const source = 'mywhoosh';
  static const _authKey = 'mywhoosh_auth_v1';
  static const _passwordKey = 'mywhoosh_password';
  static const _storage = FlutterSecureStorage();

  Future<({MyWhooshSession session, String email})?> _loadAuth() async {
    final raw = await _storage.read(key: _authKey);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (
      session: MyWhooshSession(
        accessToken: json['accessToken'] as String,
        whooshId: json['whooshId'] as String?,
      ),
      email: json['email'] as String,
    );
  }

  Future<void> _saveAuth(MyWhooshSession s, String email) => _storage.write(
    key: _authKey,
    value: jsonEncode({
      'accessToken': s.accessToken,
      'whooshId': s.whooshId,
      'email': email,
    }),
  );

  Future<bool> get isConnected async => await _loadAuth() != null;

  Future<String?> get connectedEmail async => (await _loadAuth())?.email;

  /// Signs in and keeps the password for a silent sign-in when the session
  /// ends, as for COROS. Throws [MyWhooshSignedInElsewhere] when the account
  /// is open on another device.
  Future<bool> login(String email, String password) async {
    try {
      final session = await _client.login(email, password);
      await _saveAuth(session, email);
      await _storage.write(key: _passwordKey, value: password);
      log('[MyWhoosh] login OK');
      return true;
    } on MyWhooshSignedInElsewhere {
      log('[MyWhoosh] login refused: signed in on another device');
      rethrow;
    } catch (e) {
      log('[MyWhoosh] login failed: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    await _storage.delete(key: _authKey);
    await _storage.delete(key: _passwordKey);
  }

  Future<MyWhooshSession?> _relogin(String email) async {
    final password = await _storage.read(key: _passwordKey);
    if (password == null) return null;
    try {
      final session = await _client.login(email, password);
      await _saveAuth(session, email);
      log('[MyWhoosh] silent relogin OK');
      return session;
    } catch (e) {
      log('[MyWhoosh] silent relogin failed: $e');
      return null;
    }
  }

  /// Rides from [since] on again, e.g. after one was restored.
  Future<void> refetchSince(DateTime since) async {
    final days = DateTime.now().difference(since).inDays + 1;
    await sync(days: days);
  }

  Future<MyWhooshSyncResult> sync({int days = 30}) async {
    final r = MyWhooshSyncResult();
    final auth = await _loadAuth();
    if (auth == null) return r;
    final since = DateTime.now().subtract(Duration(days: days));
    try {
      try {
        await _syncRides(auth.session, since, r);
      } on MyWhooshAuthException {
        log('[MyWhoosh] session ended — attempting silent relogin');
        final session = await _relogin(auth.email);
        if (session == null) rethrow;
        await _syncRides(session, since, r);
      }
    } catch (e) {
      log('[MyWhoosh] sync error: $e');
      r.error = '$e';
      r.authError = e is MyWhooshAuthException;
    }
    log('[MyWhoosh] done — rides=${r.rides}');
    return r;
  }

  Future<void> _syncRides(
    MyWhooshSession session,
    DateTime since,
    MyWhooshSyncResult r,
  ) async {
    final deleted = await _db.deletedActivityIds();
    final priority = await priorityForGroup(SourceGroup.activity);
    var page = 1;
    while (true) {
      final list = await _client.activities(session, page: page);
      var older = false;
      for (final ride in list.rides) {
        if (ride.start.isBefore(since)) {
          older = true;
          continue;
        }
        final id = '${source}_${ride.id}';
        if (deleted.contains(id)) continue;
        // A ride is stored once with its curves; later syncs leave it.
        if ((await _db.getActivityById(id))?.metricsJson != null) continue;
        if (await _save(session, ride, id, priority)) r.rides++;
      }
      // The list is newest first: once it reaches older rides, stop.
      if (older || page >= list.pages || list.rides.isEmpty) break;
      page++;
    }
    if (r.rides > 0) await _db.deduplicateActivities();
  }

  /// Whether another platform holds this ride and ranks above MyWhoosh.
  /// Apple Health copies and imported files never count: they give way.
  /// That copy then carries MyWhoosh's name for the ride.
  Future<bool> _platformHasIt(
    String id,
    MyWhooshActivity ride,
    DateTime start,
    int seconds,
    List<String> priority,
  ) async {
    final nearby =
        await (_db.select(_db.activityRecords)..where(
              (t) => t.startDate.isBetweenValues(
                start.subtract(const Duration(hours: 1)),
                start.add(const Duration(hours: 1)),
              ),
            ))
            .get();
    final copy = nearby.where(
      (a) =>
          a.activityId != id &&
          !{'health_connect', 'file'}.contains(a.source) &&
          isSameWorkout(
            a.startDate,
            a.durationSeconds,
            a.type,
            start,
            seconds,
            'cycling',
          ) &&
          !shouldOverwrite(a.source, source, priority),
    );
    if (copy.isEmpty) return false;
    if (ride.title case final title?) {
      await _db.adoptActivityName(copy.first.activityId, title);
    }
    return true;
  }

  Future<bool> _save(
    MyWhooshSession session,
    MyWhooshActivity ride,
    String id,
    List<String> priority,
  ) async {
    // A platform copy (Garmin, when MyWhoosh sends rides there) stays; seen
    // from the list already, so its file is not downloaded every sync.
    if (ride.durationSeconds case final seconds?
        when await _platformHasIt(id, ride, ride.start, seconds, priority)) {
      return false;
    }
    ActivityFile? file;
    if (ride.fileId case final fileId?) {
      try {
        file = decodeActivityFile(await _client.fitFile(session, fileId));
      } on MyWhooshAuthException {
        rethrow;
      } catch (e) {
        log('[MyWhoosh] FIT ${ride.id} not read: $e');
      }
    }
    final start = file?.start.toLocal() ?? ride.start;
    final duration = file?.durationSeconds ?? ride.durationSeconds ?? 0;
    if (duration <= 0) return false;
    if (await _platformHasIt(id, ride, start, duration, priority)) {
      return false;
    }
    // MyWhoosh rides are on the bike; the file only says otherwise for a
    // run on the treadmill.
    final type = file == null || file.type == 'other' ? 'cycling' : file.type;

    final km = ride.distanceKm;
    final samples = file?.samples ?? const <Map<String, num>>[];
    final companion = ActivityRecordsCompanion(
      activityId: Value(id),
      name: Value(ride.title ?? ride.routeName ?? 'MyWhoosh ride'),
      type: Value(type),
      startDate: Value(start),
      durationSeconds: Value(duration),
      distanceMeters: Value(
        file?.distanceMeters ?? (km == null ? null : km * 1000),
      ),
      avgHeartRate: Value(file?.avgHeartRate ?? ride.avgHeartRate),
      maxHeartRate: Value(file?.maxHeartRate),
      avgWatts: Value(file?.avgWatts ?? ride.avgWatts),
      totalElevation: Value(file?.ascentMeters ?? ride.elevation),
      metricsJson: Value(samples.isEmpty ? null : jsonEncode(samples)),
      movingDurationSeconds: Value(file?.movingSeconds),
      source: const Value(source),
    );
    if (await _db.getActivityById(id) != null) {
      await (_db.update(
        _db.activityRecords,
      )..where((t) => t.activityId.equals(id))).write(companion);
    } else {
      await _db.into(_db.activityRecords).insert(companion);
    }
    if (file != null && file.rrIntervals.isNotEmpty) {
      await DfaAlpha1Service(_db).save(
        id,
        start: file.start,
        rrIntervals: file.rrIntervals,
        samples: file.samples,
      );
    }
    return true;
  }
}
