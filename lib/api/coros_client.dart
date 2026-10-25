import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../utils/log.dart';

import 'coros_workout.dart';

/// Thrown when a COROS request fails.
class CorosException implements Exception {
  CorosException(this.message);

  final String message;

  @override
  String toString() => 'CorosException: $message';
}

/// A COROS token the API no longer accepts (`1010`/`1011`/`1019`). The caller
/// should re-login with the stored credentials and retry.
class CorosAuthException extends CorosException {
  CorosAuthException([super.message = 'COROS token expired']);
}

/// The COROS Training Hub (web) session: the `accessToken` returned by
/// `/account/login` plus the identity it belongs to. Web tokens last about a
/// day, so they are treated as expired after 23 hours and renewed by
/// re-logging in.
///
/// The session is pure in-memory state: [CorosClient] holds one, and
/// [CorosService] (the caller) persists it in the keychain. The JSON keys here
/// are stable across app versions (the `coros_auth_v1` storage blob), so
/// existing installs keep their session.
class CorosAuth {
  const CorosAuth({
    required this.accessToken,
    required this.userId,
    this.region = 'eu',
    required this.timestampMs,
    this.email,
    this.mobileToken,
    this.mobilePayload,
  });

  factory CorosAuth.fromJson(Map<String, dynamic> json) => CorosAuth(
    accessToken: json['accessToken'] as String,
    userId: json['userId'].toString(),
    region: json['region'] as String? ?? 'eu',
    timestampMs: json['timestampMs'] as int,
    email: json['email'] as String?,
    mobileToken: json['mobileToken'] as String?,
    mobilePayload: json['mobilePayload'] as String?,
  );

  final String accessToken;
  final String userId;
  final String region;
  final int timestampMs;
  final String? email;

  /// The mobile-app token, when COROS returns one. Detailed sleep stages are
  /// only reachable with it; the web login currently returns `null`.
  final String? mobileToken;
  final String? mobilePayload;

  /// COROS web tokens last about a day; renew after 23 hours.
  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch - timestampMs > 82800000;

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'userId': userId,
    'region': region,
    'timestampMs': timestampMs,
    'email': email,
    'mobileToken': mobileToken,
    'mobilePayload': mobilePayload,
  };
}

/// Client for the COROS Training Hub (web) API: activities, daily HRV / RHR /
/// steps / VO₂max and (best-effort) detailed sleep.
///
/// This is an unofficial interface — the same one the coros.com web app uses —
/// so it can change without notice. Every failure is reported as a
/// [CorosException] (or a [CorosAuthException] when the token is stale, which
/// signals the caller to re-login). The client is a pure in-memory session: it
/// holds a [CorosAuth] and no persistence, and returns the API's raw JSON, so
/// it can be unit-tested with a mock [http.Client]. Persisting the session and
/// credentials, and mapping the fetched data into the local database, belong
/// to `CorosService`.
class CorosClient {
  CorosClient({http.Client? client, this.trace, this._auth})
    : _http = client ?? http.Client();

  final http.Client _http;

  /// Optional hop-by-hop trace (host, path, status; never tokens or bodies),
  /// for diagnosing a changed API.
  final void Function(String line)? trace;

  CorosAuth? _auth;

  static const _timeout = Duration(seconds: 30);

  bool get signedIn => _auth != null;

  CorosAuth? get auth => _auth;

  bool get tokenExpired => _auth?.isExpired ?? true;

  void close() => _http.close();

  // ── region → base URL ─────────────────────────────────────────────────────
  //
  // The region is normalised (lowercased) so that, e.g. `EU` and `eu` both
  // resolve to the Europe base; `us`/`asia` and anything else resolve to the
  // US base.

  static String _base(String region) => switch (region.toLowerCase()) {
    'eu' => 'https://teameuapi.coros.com',
    'cn' => 'https://teamcnapi.coros.com',
    _ => 'https://teamapi.coros.com',
  };

  /// The mobile-app API base (only the detailed sleep endpoint uses it, with
  /// the mobile token).
  static String _mobileBase(String region) => switch (region.toLowerCase()) {
    'eu' => 'https://apieu.coros.com',
    'cn' => 'https://apicn.coros.com',
    _ => 'https://api.coros.com',
  };

  // ── small parsers (for shaping the raw API answers) ───────────────────────

  static String _md5(String s) => md5.convert(utf8.encode(s)).toString();

  static String _dateStr(DateTime d) {
    final l = d.toLocal();
    return '${l.year}${l.month.toString().padLeft(2, '0')}'
        '${l.day.toString().padLeft(2, '0')}';
  }

  static int? _toInt(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  static double? _toDouble(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  static double? _nonZeroDouble(Object? v) {
    final d = _toDouble(v);
    return d == null || d == 0 ? null : d;
  }

  // ── auth ──────────────────────────────────────────────────────────────────

  Map<String, String> _headers() {
    final a = _auth ?? (throw CorosException('Not signed in to COROS.'));
    return {
      'Content-Type': 'application/json',
      'accessToken': a.accessToken,
      'yfheader': jsonEncode({'userId': a.userId}),
    };
  }

  bool _isAuthError(Map<String, dynamic> json) =>
      const {'1010', '1011', '1019'}.contains(json['result']);

  /// Signs in against the COROS Training Hub and stores the session in memory.
  /// Throws [CorosException] when the credentials are rejected or the request
  /// fails.
  Future<void> login(
    String email,
    String password, {
    String region = 'eu',
  }) async {
    final base = _base(region);
    trace?.call('POST ${Uri.parse('$base/account/login').host}/account/login');
    try {
      final response = await _http
          .post(
            Uri.parse('$base/account/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'account': email,
              'accountType': 2,
              'pwd': _md5(password),
            }),
          )
          .timeout(_timeout);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['result'] != '0000') {
        throw CorosException(
          'Login failed: ${json['message']} (${json['result']})',
        );
      }
      final data = json['data'] as Map<String, dynamic>;
      _auth = CorosAuth(
        accessToken: data['accessToken'] as String,
        userId: data['userId'].toString(),
        region: region,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        email: email,
      );
      log('[Coros] login OK — region=${region.toLowerCase()}');
    } on CorosException {
      rethrow;
    } catch (e) {
      throw CorosException('Login error: $e');
    }
  }

  /// Loads a previously persisted session (from `CorosService`) without a new
  /// network round-trip.
  void adopt(CorosAuth auth) => _auth = auth;

  // ── activities ────────────────────────────────────────────────────────────

  /// The workouts on the Training Hub calendar from [from] to [to], one
  /// [CorosCalendarEntry] each. Reads what the calendar page itself loads.
  Future<List<CorosCalendarEntry>> calendarWorkouts(
    DateTime from,
    DateTime to,
  ) async {
    final a = _auth ?? (throw CorosException('Not signed in to COROS.'));
    final uri = Uri.parse('${_base(a.region)}/training/schedule/query').replace(
      queryParameters: {
        'startDate': _dateStr(from),
        'endDate': _dateStr(to),
        'supportRestExercise': '1',
      },
    );
    final response = await _http
        .get(uri, headers: _headers())
        .timeout(_timeout);
    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (_isAuthError(json)) throw CorosAuthException();
    if (json['result'] != '0000') {
      throw CorosException(
        'COROS did not list the calendar (${json['result']}): '
        '${json['message'] ?? 'no message'}',
      );
    }
    return parseCorosCalendar(json['data'] as Map<String, dynamic>? ?? {});
  }

  /// Takes one workout off the Training Hub calendar.
  Future<void> removeCalendarWorkout(CorosCalendarEntry entry) async {
    final a = _auth ?? (throw CorosException('Not signed in to COROS.'));
    final response = await _http
        .post(
          Uri.parse('${_base(a.region)}/training/schedule/update'),
          headers: _headers(),
          body: jsonEncode(entry.removalPayload),
        )
        .timeout(_timeout);
    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (_isAuthError(json)) throw CorosAuthException();
    if (!const {'0000', '1000'}.contains(json['result'])) {
      throw CorosException(
        'COROS did not remove the workout (${json['result']}): '
        '${json['message'] ?? 'no message'}',
      );
    }
  }

  /// Activity rows between [from] and [to] (inclusive local days), or the
  /// latest pages when no range is given. Paginates up to [maxPages] of 50 and
  /// invokes [onRow] for each row as it is fetched, so rows are processed
  /// (and, by the caller, persisted) as they arrive.
  ///
  /// A stale token throws [CorosAuthException]; a non-`0000` (non-auth) answer
  /// stops after the rows fetched so far and returns normally; a network
  /// failure propagates.
  /// Puts [workout] on the Training Hub calendar for [day].
  ///
  /// The Training Hub's interface is not published; this follows what its web
  /// page sends. The day is written compactly (`20261027`) first and, if that
  /// is refused, with dashes (`2026-10-27`). Throws [CorosException] with
  /// COROS's own message when both are refused.
  Future<void> uploadWorkout(CorosWorkout workout, DateTime day) async {
    final a = _auth ?? (throw CorosException('Not signed in to COROS.'));
    final base = _base(a.region);
    final d = day.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final formats = [
      '${d.year}${two(d.month)}${two(d.day)}',
      '${d.year}-${two(d.month)}-${two(d.day)}',
    ];
    CorosException? last;
    for (final happenDay in formats) {
      final response = await _http
          .post(
            Uri.parse('$base/training/schedule/update'),
            headers: _headers(),
            body: jsonEncode(workout.payload(happenDay)),
          )
          .timeout(_timeout);
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (_isAuthError(json)) throw CorosAuthException();
      if (const {'0000', '1000'}.contains(json['result'])) return;
      last = CorosException(
        'COROS did not accept the workout (${json['result']}): '
        '${json['message'] ?? 'no message'}',
      );
      log(
        '[Coros] workout upload refused with day $happenDay: ${json['result']}',
      );
    }
    throw last!;
  }

  Future<void> activities({
    DateTime? from,
    DateTime? to,
    int maxPages = 10,
    required Future<void> Function(Map<String, dynamic> row) onRow,
  }) async {
    final a = _auth ?? (throw CorosException('Not signed in to COROS.'));
    final base = _base(a.region);
    final headers = _headers();
    var page = 1;
    var totalPages = 1;
    do {
      final params = <String, String>{
        'size': '50',
        'pageNumber': '$page',
        'orderKey': 'startTime',
        'orderType': '2',
        'modeList': '0',
        if (from != null) 'startDay': _dateStr(from),
        if (to != null) 'endDay': _dateStr(to),
      };
      final response = await _http
          .get(
            Uri.parse('$base/activity/query').replace(queryParameters: params),
            headers: headers,
          )
          .timeout(_timeout);
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (_isAuthError(json)) throw CorosAuthException();
      if (json['result'] != '0000') {
        log('[Coros] activity error: ${json['message']}');
        break;
      }
      final data = json['data'] as Map<String, dynamic>? ?? const {};
      final rows =
          (data['dataList'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      log(
        '[Coros] activities range=${from == null ? 'latest' : _dateStr(from)}-'
        '${to == null ? '' : _dateStr(to)} page=$page rows=${rows.length} '
        'total=${data['count'] ?? '-'} pages=${data['totalPage'] ?? '-'}',
      );
      for (final row in rows) {
        await onRow(row);
      }
      totalPages = _toInt(data['totalPage']) ?? 1;
      page = (_toInt(data['pageNumber']) ?? page) + 1;
    } while (page <= totalPages && page <= maxPages);
  }

  /// Extra training-effect fields for one activity. Returns `null` when the
  /// detail is unavailable (a transient failure, not an auth error).
  Future<Map<String, dynamic>?> activityDetail(
    String labelId,
    int? sportType,
  ) async {
    final a = _auth ?? (throw CorosException('Not signed in to COROS.'));
    try {
      final uri = Uri.parse('${_base(a.region)}/activity/detail/query');
      log('[Coros] detail fetch: $labelId');
      final response = await _http
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode({'labelId': labelId, 'sportType': sportType}),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        log('[Coros] detail HTTP ${response.statusCode} body=${response.body}');
        return null;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['result'] != '0000') return null;
      final data = json['data'] as Map<String, dynamic>? ?? const {};
      final summary = data['summary'] as Map<String, dynamic>? ?? data;
      log('[Coros] detail keys for $labelId: ${summary.keys.toList()}');
      final recoveryHours = _toDouble(summary['recoveryTime']);
      return {
        'aerobicTE': _nonZeroDouble(
          summary['aerobicTE'] ??
              summary['aerobicTrainingEffect'] ??
              summary['aerobic'],
        ),
        'anaerobicTE': _nonZeroDouble(
          summary['anaerobicTE'] ??
              summary['anaerobicTrainingEffect'] ??
              summary['anaerobic'],
        ),
        'recoveryTimeSeconds': recoveryHours != null
            ? (recoveryHours * 3600).round()
            : null,
        'trainingFocus': summary['trainingFocus'] ?? summary['workoutFocus'],
        'vo2max': _nonZeroDouble(summary['vo2max'] ?? summary['vO2Max']),
      };
    } catch (e) {
      log('[Coros] detail fetch error for $labelId: $e');
      return null;
    }
  }

  // ── daily metrics (HRV / RHR / steps / VO₂max) ────────────────────────────

  /// Merged per-day wellness/HRV data keyed by `yyyyMMdd`, from the three
  /// web-token endpoints (`dayDetail`, the dashboard `sleepHrvData` and the
  /// 7/28-day `analyse` summary). Only `0000` answers are merged. A stale token
  /// throws [CorosAuthException]; a network failure propagates.
  Future<Map<String, Map<String, dynamic>>> dailyMetrics(
    DateTime from,
    DateTime to,
  ) async {
    final a = _auth ?? (throw CorosException('Not signed in to COROS.'));
    final base = _base(a.region);
    final headers = _headers();
    final range = {'startDay': _dateStr(from), 'endDay': _dateStr(to)};
    final responses = await Future.wait([
      _http
          .get(
            Uri.parse(
              '$base/analyse/dayDetail/query',
            ).replace(queryParameters: range),
            headers: headers,
          )
          .timeout(_timeout),
      _http
          .get(Uri.parse('$base/dashboard/query'), headers: headers)
          .timeout(_timeout),
      _http
          .get(
            Uri.parse('$base/analyse/query').replace(queryParameters: range),
            headers: headers,
          )
          .timeout(_timeout),
    ]);
    final detail = jsonDecode(responses[0].body) as Map<String, dynamic>;
    final dashboard = jsonDecode(responses[1].body) as Map<String, dynamic>;
    final analyse = jsonDecode(responses[2].body) as Map<String, dynamic>;
    if (_isAuthError(detail) || _isAuthError(dashboard)) {
      throw CorosAuthException();
    }

    final byDay = <String, Map<String, dynamic>>{};
    void merge(List? list) {
      for (final e in (list ?? const []).cast<Map<String, dynamic>>()) {
        final key = '${e['happenDay'] ?? ''}';
        if (key.isEmpty) continue;
        (byDay[key] ??= <String, dynamic>{}).addAll(e);
      }
    }

    if (detail['result'] == '0000') {
      merge((detail['data'] as Map?)?['dayList'] as List?);
    }
    if (analyse['result'] == '0000') {
      merge((analyse['data'] as Map?)?['t7dayList'] as List?);
    }
    if (dashboard['result'] == '0000') {
      final summary = (dashboard['data'] as Map?)?['summaryInfo'] as Map?;
      merge((summary?['sleepHrvData'] as Map?)?['sleepHrvList'] as List?);
    }
    return byDay;
  }

  // ── sleep (mobile token, best-effort) ─────────────────────────────────────

  /// Detailed sleep stages, from the *mobile* statistic API. This endpoint
  /// needs the mobile-app token, which the web login does not issue — so with a
  /// web-token session it returns an empty list (sleep stages are simply not
  /// available) rather than failing the sync. A stale *mobile* token does not
  /// trigger a web re-login. A network failure propagates.
  Future<List<Map<String, dynamic>>> sleep(DateTime from, DateTime to) async {
    final a = _auth;
    final token = a?.mobileToken;
    if (a == null || token == null) {
      log('[Coros] no mobile token — sleep sync skipped');
      return const [];
    }
    final response = await _http
        .post(
          Uri.parse('${_mobileBase(a.region)}/coros/data/statistic/daily'),
          headers: {'Content-Type': 'application/json', 'accesstoken': token},
          body: jsonEncode({
            'allDeviceSleep': 1,
            'dataType': 5,
            'dataVersion': 0,
            'startTime': int.parse(_dateStr(from)),
            'endTime': int.parse(_dateStr(to)),
            'statisticType': 1,
          }),
        )
        .timeout(_timeout);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (_isAuthError(json)) {
      log('[Coros] mobile token expired — sleep sync skipped');
      return const [];
    }
    if (json['result'] != '0000') {
      log('[Coros] sleep error: ${json['message']}');
      return const [];
    }
    final days =
        (((json['data'] as Map?)?['statisticData'] as Map?)?['dayDataList']
                as List?)
            ?.cast<Map<String, dynamic>>() ??
        const [];
    return days;
  }

  // ── GPX track export ──────────────────────────────────────────────────────

  /// Track points (`lat`/`lng`) of one activity, via the GPX export. Returns
  /// `null` on any failure (this is an optional, on-demand route fetch).
  Future<List<Map<String, double>>?> gpxTrack(
    String labelId,
    int? sportType,
  ) async {
    final a = _auth;
    if (a == null) return null;
    try {
      final uri = Uri.parse('${_base(a.region)}/activity/detail/download')
          .replace(
            queryParameters: {
              'labelId': labelId,
              'sportType': '$sportType',
              'fileType': '1',
              'accessToken': a.accessToken,
            },
          );
      final response = await _http
          .post(uri, headers: _headers())
          .timeout(_timeout);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['result'] != '0000') {
        log('[Coros] GPX download URL error: ${json['message']}');
        return null;
      }
      final url = (json['data'] as Map?)?['fileUrl'] as String?;
      if (url == null) return null;
      final gpx = await _http.get(Uri.parse(url)).timeout(_timeout);
      if (gpx.statusCode != 200) {
        log('[Coros] GPX fetch HTTP ${gpx.statusCode}');
        return null;
      }
      final points = RegExp(r'<trkpt\s+lat="([^"]+)"\s+lon="([^"]+)"')
          .allMatches(gpx.body)
          .map(
            (m) => {
              'lat': double.parse(m.group(1)!),
              'lng': double.parse(m.group(2)!),
            },
          )
          .toList();
      log('[Coros] GPX parsed ${points.length} points for labelId=$labelId');
      return points;
    } catch (e) {
      log('[Coros] fetchGpxTrack error: $e');
      return null;
    }
  }
}
