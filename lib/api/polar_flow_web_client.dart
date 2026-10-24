import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown for a failed Polar Flow web login or request.
class PolarFlowException implements Exception {
  PolarFlowException(this.message);
  final String message;
  @override
  String toString() => 'PolarFlowException: $message';
}

/// One diary entry from the Flow web calendar.
class PolarFlowWorkout {
  const PolarFlowWorkout({
    required this.id,
    required this.url,
    required this.start,
    this.durationSeconds,
    this.distanceMeters,
    this.sport,
  });

  /// Polar's training-session id.
  final String id;

  /// Relative analysis URL, e.g. `/training/analysis/123`.
  final String url;
  final DateTime start;
  final int? durationSeconds;
  final double? distanceMeters;
  final String? sport;
}

/// Reads the user's own training diary from the Polar Flow website.
///
/// The official AccessLink API only returns the last 30 days, so for the
/// one-time history import this signs in like the browser does (Flow →
/// `auth.polar.com` form login) and exports each session as TCX. It is an
/// unofficial interface: it can change without notice, so every failure is
/// reported as a [PolarFlowException] and the caller treats it as optional.
class PolarFlowWebClient {
  PolarFlowWebClient({http.Client? client, this.trace})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Optional hop-by-hop trace (method, host, path, status; never cookies or
  /// bodies), for diagnosing a changed login flow.
  final void Function(String line)? trace;

  static const _flow = 'https://flow.polar.com';
  static const _userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 '
      'Safari/604.1';

  /// host → cookie name → value.
  final Map<String, Map<String, String>> _jar = {};
  bool _signedIn = false;

  /// Polar's numeric user id, resolved from the signed-in session. It is
  /// needed for the v2 API's `/v2/users/{userId}/…` paths; null when it could
  /// not be determined, in which case the v2 path is skipped and the web
  /// calendar is used instead.
  String? _userId;

  bool get signedIn => _signedIn;

  String? get userId => _userId;

  void close() => _client.close();

  // -------------------------------------------------------------------------
  // Login
  // -------------------------------------------------------------------------

  Future<void> login(String email, String password) async {
    _jar.clear();
    _signedIn = false;

    final page = await _get(Uri.parse('$_flow/login'));
    final csrf = RegExp(
      r'name="csrfToken"\s+value="([^"]+)"',
    ).firstMatch(page.body)?.group(1);
    if (csrf == null) {
      throw PolarFlowException('Polar Flow login page not recognised.');
    }

    // Flow's login page sets this cookie from JavaScript (minutes east of
    // UTC); the sign-in hand-over is refused without it.
    _jar.putIfAbsent('flow.polar.com', () => {})['timezone'] =
        '${DateTime.now().timeZoneOffset.inMinutes}';

    // Flow hands over to the Polar account service; this lands on its login
    // page and sets the XSRF cookie.
    final sso = await _get(
      Uri.parse(
        '$_flow/flowSso/login',
      ).replace(queryParameters: {'csrfToken': csrf, 'returnUrl': '/'}),
    );
    final loginUri = sso.finalUri;
    if (loginUri.host != 'auth.polar.com') {
      // Already signed in or an unexpected redirect.
      if (await _hasDiary()) {
        _signedIn = true;
        return;
      }
      throw PolarFlowException('Unexpected Polar login redirect: $loginUri');
    }
    final xsrf = _cookie('auth.polar.com', 'XSRF-TOKEN');
    if (xsrf == null) {
      throw PolarFlowException('Polar login: security token missing.');
    }

    final post = await _send(
      'POST',
      Uri.parse('https://auth.polar.com/login'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Origin': 'https://auth.polar.com',
        'Referer': loginUri.toString(),
        'X-XSRF-TOKEN': xsrf,
      },
      body: {
        'username': email,
        'password': password,
        '_csrf': xsrf,
        'remember-me': 'false',
      },
    );
    final landed = post.finalUri;
    if (landed.host == 'auth.polar.com') {
      final p = landed.path;
      if (p.contains('login') || landed.queryParameters.containsKey('error')) {
        throw PolarFlowException('Incorrect Polar e-mail or password.');
      }
      throw PolarFlowException('Polar sign-in needs another step ($p).');
    }
    if (!await _hasDiary()) {
      throw PolarFlowException('Polar Flow sign-in did not complete.');
    }
    // The hand-over lands on the home page; its embedded state carries the
    // numeric user id the v2 API paths need.
    if (landed.host == 'flow.polar.com') {
      _userId = _extractUserId(post.body);
    }
    _signedIn = true;
  }

  Future<bool> _hasDiary() async {
    try {
      final now = DateTime.now();
      await _calendar(now, now);
      return true;
    } on PolarFlowException {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Diary and export
  // -------------------------------------------------------------------------

  /// Training sessions between [from] and [to] (inclusive, local days).
  ///
  /// Tries the official v2 `training-sessions` list API first — the same one
  /// the Flow app uses. If the session is not authorized for it (a 401/403 or a
  /// login-page answer) or the user id could not be resolved, it falls back to
  /// the web calendar, which the form-login session always answers.
  Future<List<PolarFlowWorkout>> workouts(DateTime from, DateTime to) async {
    if (!_signedIn) throw PolarFlowException('Not signed in to Polar Flow.');
    await _ensureUserId();
    if (_userId != null) {
      try {
        final viaV2 = parseV2Activities(await _v2Activities(from, to));
        if (viaV2.isNotEmpty) return viaV2;
        trace?.call(
          'v2 training-sessions returned nothing — using the web calendar',
        );
      } on PolarFlowException catch (e) {
        trace?.call(
          'v2 training-sessions failed ($e) — using the web calendar',
        );
      }
    }
    return parseCalendarEvents(await _calendar(from, to));
  }

  Future<String> _calendar(DateTime from, DateTime to) async {
    String d(DateTime t) =>
        '${t.day.toString().padLeft(2, '0')}.'
        '${t.month.toString().padLeft(2, '0')}.${t.year}';
    final res = await _get(
      Uri.parse(
        '$_flow/training/getCalendarEvents?start=${d(from)}&end=${d(to)}',
      ),
      headers: {
        'Accept': 'application/json, text/plain, */*',
        'X-Requested-With': 'XMLHttpRequest',
      },
    );
    final body = res.body.trimLeft();
    if (!body.startsWith('[') && !body.startsWith('{')) {
      throw PolarFlowException(
        'Polar Flow diary not available (not signed in).',
      );
    }
    return body;
  }

  // -------------------------------------------------------------------------
  // v2 training-sessions API (the one the official Flow app uses)
  // -------------------------------------------------------------------------

  /// The official list endpoint, `GET /v2/users/{userId}/training-sessions`.
  /// Returns the JSON body, or throws [PolarFlowException] when the session is
  /// not authorized for the API or the answer is not JSON (e.g. a login page).
  Future<String> _v2Activities(DateTime from, DateTime to) async {
    final res = await _get(
      Uri.parse('$_flow/v2/users/$_userId/training-sessions').replace(
        queryParameters: {
          'fromDate': _ymd(from),
          'toDate': _ymd(to),
          'filter': 'false',
        },
      ),
      headers: {
        'Accept': 'application/json, text/plain, */*',
        'X-Requested-With': 'XMLHttpRequest',
      },
    );
    final body = res.body.trimLeft();
    if (!body.startsWith('[') && !body.startsWith('{')) {
      throw PolarFlowException(
        'Polar v2 training-sessions not available (not signed in).',
      );
    }
    return body;
  }

  /// Resolves the numeric user id from the signed-in session, for the v2 API's
  /// `/v2/users/{userId}/…` paths. Best-effort: the home page is parsed.
  /// Leaves [_userId] null on failure so the v2 path is skipped.
  Future<void> _ensureUserId() async {
    if (_userId != null) return;
    try {
      final res = await _get(Uri.parse('$_flow/'));
      final id = _extractUserId(res.body);
      if (id != null) _userId = id;
    } on PolarFlowException {
      // No user id → the v2 path is skipped and the web calendar is used.
    }
  }

  /// Pulls the numeric user id out of a Flow page's embedded state. The home
  /// page embeds the session as a JavaScript object (unquoted keys), so the
  /// patterns accept the key with or without quotes.
  static String? _extractUserId(String html) {
    const patterns = [
      r'"?userId"?\s*:\s*"?(\d+)"?',
      r'"?user"?\s*:\s*"?(\d+)"?',
      r'"?user_id"?\s*:\s*"?(\d+)"?',
      r'"?user"?\s*:\s*\{[^{}]*"?id"?\s*:\s*"?(\d+)"?',
      r'data-user-id="(\d+)"',
    ];
    for (final raw in patterns) {
      final m = RegExp(raw).firstMatch(html);
      if (m != null) return m.group(1);
    }
    return null;
  }

  static String _ymd(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  /// Parses a v2 training-sessions list into [PolarFlowWorkout]s. Tolerant:
  /// unknown fields are ignored and entries that lack an id or start time are
  /// skipped. The session URL is taken from the item when present, otherwise
  /// derived from the id so [exportTcx] still works.
  static List<PolarFlowWorkout> parseV2Activities(String json) {
    final decoded = jsonDecode(json);
    final list = decoded is List
        ? decoded
        : decoded is Map
        ? _firstList(decoded, const [
            'trainingSessions',
            'training-sessions',
            'sessions',
            'items',
            'results',
            'data',
          ])
        : const [];
    final out = <PolarFlowWorkout>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final id =
          '${raw['id'] ?? raw['trainingSessionId'] ?? raw['training-session-id'] ?? ''}';
      if (id.isEmpty) continue;
      final start = _parseTimestamp(
        raw['start_time'] ?? raw['start-time'] ?? raw['startTime'] ??
            raw['start'] ?? raw['datetime'],
      );
      if (start == null) continue;
      out.add(
        PolarFlowWorkout(
          id: id,
          url: (raw['url'] as String?) ?? '/training/analysis/$id',
          start: start,
          durationSeconds: _parseDurationField(
            raw['duration'] ?? raw['duration_seconds'] ?? raw['total_time'],
          ),
          distanceMeters: (raw['distance'] as num?)?.toDouble(),
          sport: _v2Sport(raw),
        ),
      );
    }
    return out;
  }

  /// The sport of a v2 session: `sport` / `sport_id` (or its camelCase and
  /// `type` spellings) as a string; numeric ids are stringified.
  static String? _v2Sport(Map raw) {
    for (final k in const ['sport', 'sport_name', 'sportName', 'sport_id', 'type']) {
      final v = raw[k];
      if (v is String && v.isNotEmpty) return v;
      if (v is num) return v.toString();
    }
    return null;
  }

  static List<Object?> _firstList(Map decoded, List<String> keys) {
    for (final k in keys) {
      final v = decoded[k];
      if (v is List) return v;
    }
    if (decoded.values.isNotEmpty) {
      final v = decoded.values.first;
      if (v is List) return v;
    }
    return const [];
  }

  static DateTime? _parseTimestamp(Object? v) {
    if (v is DateTime) return v;
    if (v is num) {
      // epoch milliseconds or seconds
      if (v > 1e12) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      if (v > 1e9) return DateTime.fromMillisecondsSinceEpoch((v * 1000).round());
      return null;
    }
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  /// A duration field in seconds: accepts ISO-8601 (`PT1H2M3.5S`), a number of
  /// seconds or — for values larger than a day — milliseconds, or a numeric
  /// string.
  static int? _parseDurationField(Object? v) {
    int? fromNum(num n) {
      if (n <= 0) return null;
      // Larger than a day in seconds ⇒ it is milliseconds.
      return n > 86400 ? (n / 1000).round() : n.round();
    }

    if (v is num) return fromNum(v);
    if (v is String) {
      final iso = _parseIsoDuration(v);
      if (iso != null) return iso;
      final n = double.tryParse(v);
      if (n != null) return fromNum(n);
    }
    return null;
  }

  /// ISO-8601 duration (`PT1H2M3.5S`) → seconds.
  static int? _parseIsoDuration(String s) {
    final m = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?')
        .firstMatch(s);
    if (m == null) return null;
    final h = int.tryParse(m.group(1) ?? '0') ?? 0;
    final min = int.tryParse(m.group(2) ?? '0') ?? 0;
    final sec = double.tryParse(m.group(3) ?? '0') ?? 0;
    return h * 3600 + min * 60 + sec.round();
  }

  /// The session as TCX (heart rate, laps and, if recorded, the route).
  Future<String> exportTcx(PolarFlowWorkout w) async {
    if (!_signedIn) throw PolarFlowException('Not signed in to Polar Flow.');
    final res = await _get(Uri.parse('$_flow${w.url}/export/tcx/false'));
    if (!res.body.contains('<TrainingCenterDatabase')) {
      throw PolarFlowException('Polar export for ${w.id} was not TCX.');
    }
    return res.body;
  }

  /// Parses the diary JSON. Tolerant: unknown fields are ignored, entries that
  /// are not training sessions are skipped.
  static List<PolarFlowWorkout> parseCalendarEvents(String json) {
    final decoded = jsonDecode(json);
    final list = decoded is List
        ? decoded
        : decoded is Map && decoded['events'] is List
        ? decoded['events'] as List
        : const [];
    final out = <PolarFlowWorkout>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final type = '${raw['type'] ?? ''}'.toUpperCase();
      if (type.isNotEmpty && !type.contains('EXERCISE')) continue;
      final url = raw['url'] as String?;
      final id = '${raw['listItemId'] ?? raw['id'] ?? _idFromUrl(url) ?? ''}';
      final start = DateTime.tryParse('${raw['datetime'] ?? ''}');
      if (id.isEmpty || url == null || start == null) continue;
      final duration = raw['duration'];
      out.add(
        PolarFlowWorkout(
          id: id,
          url: url,
          start: start,
          // Flow reports the duration in milliseconds.
          durationSeconds: duration is num ? (duration / 1000).round() : null,
          distanceMeters: (raw['distance'] as num?)?.toDouble(),
          sport: raw['sport']?.toString(),
        ),
      );
    }
    return out;
  }

  static String? _idFromUrl(String? url) =>
      url == null ? null : RegExp(r'(\d+)$').firstMatch(url)?.group(1);

  // -------------------------------------------------------------------------
  // HTTP with a cookie jar and manual redirects
  // -------------------------------------------------------------------------

  String? _cookie(String host, String name) => _jar[host]?[name];

  Future<_Response> _get(Uri uri, {Map<String, String>? headers}) =>
      _send('GET', uri, headers: headers);

  Future<_Response> _send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Map<String, String>? body,
  }) async {
    var currentMethod = method;
    var current = uri;
    var currentBody = body;
    for (var hop = 0; hop < 12; hop++) {
      final request = http.Request(currentMethod, current)
        ..followRedirects = false
        ..headers.addAll({
          'User-Agent': _userAgent,
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          ...?headers,
        });
      // Like a browser: a redirect keeps the original referrer, reduced to the
      // origin when it crosses to another site.
      final referer = headers?['Referer'];
      if (referer != null) {
        final ref = Uri.parse(referer);
        request.headers['Referer'] = ref.origin == current.origin
            ? referer
            : '${ref.origin}/';
      }
      final cookies = _jar[current.host];
      if (cookies != null && cookies.isNotEmpty) {
        request.headers['Cookie'] = cookies.entries
            .map((e) => '${e.key}=${e.value}')
            .join('; ');
      }
      if (currentBody != null) request.bodyFields = currentBody;
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      trace?.call(
        '${request.method} ${current.host}${current.path}'
        ' [cookies sent: ${(_jar[current.host]?.keys.toList() ?? const <String>[]).join(',')}]'
        ' session#${(_jar[current.host]?['PLAY_SESSION_FLOW'] ?? '').hashCode.toRadixString(16)}'
        ' state=${(current.queryParameters['state'] ?? '').padRight(6).substring(0, 6)}'
        ' → ${res.statusCode}'
        '${res.headers['location'] != null ? ' → ${Uri.parse(res.headers['location']!).replace(query: '').toString()}'
                  ' (state=${(Uri.parse(res.headers['location']!).queryParameters['state'] ?? '').padRight(6).substring(0, 6)}'
                  ' code=${Uri.parse(res.headers['location']!).queryParameters.containsKey('code')})' : ''}',
      );
      _storeCookies(current.host, res.headers['set-cookie']);
      final location = res.headers['location'];
      if (res.statusCode >= 300 && res.statusCode < 400 && location != null) {
        current = current.resolve(location);
        // 301/302/303 turn a POST into a GET.
        if (res.statusCode != 307 && res.statusCode != 308) {
          currentMethod = 'GET';
          currentBody = null;
        }
        continue;
      }
      if (res.statusCode >= 400) {
        final snippet = res.body.replaceAll(RegExp(r'<[^>]*>|\s+'), ' ').trim();
        trace?.call(
          '  body: ${snippet.length > 240 ? snippet.substring(0, 240) : snippet}'
          ' | set-cookie names: ${_cookieNames(res.headers['set-cookie'])}',
        );
        throw PolarFlowException('HTTP ${res.statusCode} from ${current.host}');
      }
      return _Response(res.body, current);
    }
    throw PolarFlowException('Too many redirects from ${uri.host}.');
  }

  String _cookieNames(String? setCookie) => setCookie == null
      ? '-'
      : setCookie
            .split(RegExp(r',\s*(?=[^;,\s=]+=)'))
            .map((c) => c.split('=').first.trim())
            .join(',');

  void _storeCookies(String host, String? setCookie) {
    if (setCookie == null || setCookie.isEmpty) return;
    // Several cookies arrive joined with ", "; split on the comma that begins a
    // new `name=` pair, not on the ones inside an Expires date.
    final parts = setCookie.split(RegExp(r',\s*(?=[^;,\s=]+=)'));
    final jar = _jar.putIfAbsent(host, () => {});
    for (final part in parts) {
      final pair = part.split(';').first;
      final eq = pair.indexOf('=');
      if (eq <= 0) continue;
      final name = pair.substring(0, eq).trim();
      final value = pair.substring(eq + 1).trim();
      if (value.isEmpty || value.toLowerCase() == 'deleted') {
        jar.remove(name);
      } else {
        jar[name] = value;
      }
    }
  }
}

class _Response {
  _Response(this.body, this.finalUri);
  final String body;
  final Uri finalUri;
}
