import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:cupertino_http/cupertino_http.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/device_hr_zones.dart';
import '../models/garmin_data.dart';
import '../models/heart_rate.dart';
import '../utils/log.dart';

class GarminApiException implements Exception {
  GarminApiException(this.message);

  final String message;

  @override
  String toString() => 'GarminApiException: $message';
}

/// Thrown by [GarminClient.login] when the account has two-factor auth;
/// finish with [GarminClient.loginWithMfa].
class GarminMfaRequiredException implements Exception {
  GarminMfaRequiredException(this.message, {this.method, this.email});

  final String message;
  final String? method;
  final String? email;

  @override
  String toString() => 'GarminMfaRequiredException: $message';
}

class GarminAuthException implements Exception {
  GarminAuthException(this.message);

  final String message;

  @override
  String toString() => 'GarminAuthException: $message';
}

/// One day of a Garmin adaptive ("fbt-adaptive") training plan.
class _PlanTask {
  const _PlanTask({
    required this.name,
    this.description,
    this.durationSecs,
    this.phrase,
    this.week,
    this.day,
    this.steps = const [],
  });

  final String name;
  final String? description;
  final int? durationSecs;
  final String? phrase;
  final int? week;
  final int? day;
  final List<WorkoutStep> steps;
}

/// Metadata of the active Garmin Coach plan, cached in secure storage.
class TrainingPlanMeta {
  const TrainingPlanMeta({
    required this.planId,
    required this.planName,
    required this.durationInWeeks,
    required this.avgWeeklyWorkouts,
    required this.startDate,
    this.endDate,
    required this.currentWeek,
  });

  factory TrainingPlanMeta.fromJson(Map<String, dynamic> json) {
    return TrainingPlanMeta(
      planId: json['planId'] as String,
      planName: json['planName'] as String,
      durationInWeeks: json['durationInWeeks'] as int,
      avgWeeklyWorkouts: json['avgWeeklyWorkouts'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      currentWeek: json['currentWeek'] as int,
    );
  }

  final String planId;
  final String planName;
  final int durationInWeeks;
  final int avgWeeklyWorkouts;
  final DateTime startDate;
  final DateTime? endDate;
  final int currentWeek;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['planId'] = planId;
    json['planName'] = planName;
    json['durationInWeeks'] = durationInWeeks;
    json['avgWeeklyWorkouts'] = avgWeeklyWorkouts;
    json['startDate'] = startDate.toIso8601String();
    if (endDate != null) json['endDate'] = endDate!.toIso8601String();
    json['currentWeek'] = currentWeek;
    return json;
  }
}

/// Garmin Connect client speaking the mobile-app protocol: SSO login with
/// optional MFA, DI OAuth2 tokens and the connectapi.garmin.com services.
/// Splits a merged `Set-Cookie` header into single cookies. Dart's client
/// joins repeated headers with ",", Apple's URLSession with ", "; a comma
/// inside an `Expires=` date is followed by a day number, not `name=`.
List<String> splitSetCookieHeader(String raw) =>
    raw.split(RegExp(r',\s*(?=[^;,\s=]+=)'));

class GarminClient {
  GarminClient({this._client});

  http.Client? _client;

  /// On iOS/macOS the requests go through the system's URLSession. Cookies
  /// are managed by hand (SSO flow), so URLSession's cookie handling is
  /// switched off.
  http.Client get _http => _client ??= _createClient();

  static http.Client _createClient() {
    final native =
        (Platform.isIOS || Platform.isMacOS) &&
        !Platform.environment.containsKey('FLUTTER_TEST');
    if (!native) return http.Client();
    final config = URLSessionConfiguration.ephemeralSessionConfiguration()
      ..httpShouldSetCookies = false
      ..httpCookieAcceptPolicy =
          NSHTTPCookieAcceptPolicy.NSHTTPCookieAcceptPolicyNever;
    return CupertinoClient.fromSessionConfiguration(config);
  }

  /// SSO session cookies between the login and MFA steps.
  String _cookies = '';
  String? _mfaEmail;
  String? _mfaMethod;
  final Map<String, List<WorkoutStep>> _stepsCache = {};

  static const _api = 'https://connectapi.garmin.com';
  static const _tokenUrl =
      'https://diauth.garmin.com/di-oauth2-service/oauth/token';
  static const _ssoLoginUrl = 'https://sso.garmin.com/mobile/api/login';
  static const _ssoMfaUrl = 'https://sso.garmin.com/mobile/api/mfa/verifyCode';
  static const _serviceUrl = 'https://mobile.integration.garmin.com/gcm/ios';
  static const _clientIds = [
    'GARMIN_CONNECT_MOBILE_ANDROID_DI_2025Q2',
    'GARMIN_CONNECT_MOBILE_ANDROID_DI_2024Q4',
    'GARMIN_CONNECT_MOBILE_ANDROID_DI',
    'GARMIN_CONNECT_MOBILE_IOS_DI',
  ];

  static const _storage = FlutterSecureStorage();
  static const _kAccessToken = 'garmin_access_token';
  static const _kRefreshToken = 'garmin_refresh_token';
  static const _kClientId = 'garmin_di_client_id';
  static const _kExpiresAt = 'garmin_expires_at';
  static const _kHrZoneBounds = 'garmin_hr_zone_bounds';
  static const _kEmail = 'garmin_email';
  static const _kLoginBlockedUntil = 'garmin_login_blocked_until';
  static const _kPlanMeta = 'garmin_training_plan_meta';

  // ── Auth ────────────────────────────────────────────────────────────────

  Future<bool> get isLoggedIn async {
    final access = await _storage.read(key: _kAccessToken);
    final refresh = await _storage.read(key: _kRefreshToken);
    return access != null && refresh != null;
  }

  Future<void> login(String email, String password) async {
    final ticket = await _startLogin(email, password);
    await _exchangeServiceTicket(ticket, email: email);
  }

  /// Completes a login interrupted by [GarminMfaRequiredException].
  Future<void> loginWithMfa(String code) async {
    final ticket = await _verifyMfa(code);
    await _exchangeServiceTicket(ticket, email: _mfaEmail);
  }

  Future<void> logout() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kClientId),
      _storage.delete(key: _kExpiresAt),
      _storage.delete(key: _kHrZoneBounds),
      _storage.delete(key: _kEmail),
    ]);
    _cookies = '';
    log('[Garmin] logout: credentials cleared');
  }

  Map<String, String> get _ssoHeaders => {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
    'Accept': 'application/json, text/plain, */*',
    'Content-Type': 'application/json',
    'Origin': 'https://sso.garmin.com',
    if (_cookies.isNotEmpty) 'Cookie': _cookies,
  };

  static final _ssoQuery = {
    'clientId': 'GCM_IOS_DARK',
    'locale': 'en-US',
    'service': _serviceUrl,
  };

  /// Posts credentials to the mobile SSO API and returns the service ticket.
  Future<String> _startLogin(String email, String password) async {
    // After a 429 Garmin keeps rate-limiting; every further attempt extends
    // the lockout, so don't send any until the cooldown has passed.
    final blocked = int.tryParse(
      await _storage.read(key: _kLoginBlockedUntil) ?? '',
    );
    if (blocked != null) {
      final until = DateTime.fromMillisecondsSinceEpoch(blocked);
      if (DateTime.now().isBefore(until)) {
        final hh = until.hour.toString().padLeft(2, '0');
        final mm = until.minute.toString().padLeft(2, '0');
        throw GarminAuthException(
          'Garmin is rate-limiting logins. Please try again after $hh:$mm.',
        );
      }
      await _storage.delete(key: _kLoginBlockedUntil);
    }
    _cookies = '';
    log('[Garmin] login: POST $_ssoLoginUrl');
    final response = await _http.post(
      Uri.parse(_ssoLoginUrl).replace(queryParameters: _ssoQuery),
      headers: _ssoHeaders,
      body: jsonEncode(<String, Object>{
        'username': email,
        'password': password,
        'rememberMe': true,
        'captchaToken': '',
      }),
    );
    _captureCookies(response);
    log(
      '[Garmin] login: → ${response.statusCode} '
      '(${response.body.length} bytes)',
    );
    if (response.statusCode == 429 || response.statusCode == 403) {
      _logBlockedResponse('login', response);
    }

    switch (response.statusCode) {
      case 429:
        await _blockLogins('login');
        throw GarminAuthException(
          'Too many login attempts. Garmin blocks logins for a while — '
          'please try again in 30 minutes.',
        );
      case 403:
        throw GarminAuthException(
          'Garmin blocked the request. Try again in a few seconds.',
        );
      case 401:
        throw GarminAuthException(
          'Incorrect email or password. Please check your Garmin credentials.',
        );
    }
    if (response.statusCode >= 500) {
      throw GarminAuthException(
        'Could not reach Garmin. Check your internet connection and try again.',
      );
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw GarminAuthException(
        'Garmin returned an unexpected response. Please try again.',
      );
    }
    final status = json['responseStatus'] as Map<String, dynamic>?;
    final type = status?['type'] as String? ?? 'UNKNOWN';
    log('[Garmin] login: responseStatus=$type');

    switch (type) {
      case 'SUCCESSFUL':
        final ticket = json['serviceTicketId'] as String?;
        if (ticket == null) {
          throw GarminAuthException(
            'Login partially failed. Please try again.',
          );
        }
        log('[Garmin] login: got service ticket');
        return ticket;
      case 'MFA_REQUIRED':
        final info = json['customerMfaInfo'] as Map<String, dynamic>?;
        _mfaMethod = info?['mfaLastMethodUsed'] as String? ?? 'email';
        _mfaEmail = email;
        log('[Garmin] login: MFA required, method=$_mfaMethod');
        throw GarminMfaRequiredException(
          'MFA required',
          method: _mfaMethod,
          email: email,
        );
      case 'INVALID_USERNAME_PASSWORD':
        throw GarminAuthException('Invalid username or password.');
      default:
        throw GarminAuthException(
          'Login failed. Please check your credentials and try again.',
        );
    }
  }

  /// After a 429 every further attempt only extends Garmin's lockout, so
  /// logins are refused locally for 30 minutes.
  Future<void> _blockLogins(String step) async {
    final until = DateTime.now().add(const Duration(minutes: 30));
    await _storage.write(
      key: _kLoginBlockedUntil,
      value: '${until.millisecondsSinceEpoch}',
    );
    log('[Garmin] $step: rate-limited (429) — blocking logins for 30 min');
  }

  /// What Garmin/Cloudflare said when blocking a request: the body (no
  /// credentials in it) and the headers that identify who answered.
  void _logBlockedResponse(String what, http.Response response) {
    const interesting = ['server', 'cf-ray', 'cf-mitigated', 'retry-after'];
    final headers = {
      for (final h in interesting)
        if (response.headers[h] != null) h: response.headers[h],
    };
    final body = response.body.replaceAll(RegExp(r'\s+'), ' ');
    log(
      '[Garmin] $what blocked: HTTP ${response.statusCode} '
      'headers=$headers body=${body.length > 300 ? body.substring(0, 300) : body}',
    );
  }

  Future<String> _verifyMfa(String code) async {
    log('[Garmin] mfa: POST $_ssoMfaUrl');
    final response = await _http.post(
      Uri.parse(_ssoMfaUrl).replace(queryParameters: _ssoQuery),
      headers: _ssoHeaders,
      body: jsonEncode(<String, Object>{
        'mfaMethod': _mfaMethod ?? 'email',
        'mfaVerificationCode': code.trim(),
        'rememberMyBrowser': true,
        'reconsentList': <Object>[],
        'mfaSetup': false,
      }),
    );
    _captureCookies(response);
    log(
      '[Garmin] mfa: → ${response.statusCode} '
      '(${response.body.length} bytes)',
    );

    if (response.statusCode == 429) {
      _logBlockedResponse('mfa', response);
      await _blockLogins('mfa');
      throw GarminAuthException(
        'Too many code attempts. Garmin blocks logins for a while — '
        'please try again in 30 minutes.',
      );
    }
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw GarminAuthException(
        'Could not verify your code. Please try again.',
      );
    }
    final status = json['responseStatus'] as Map<String, dynamic>?;
    final type = status?['type'] as String? ?? 'UNKNOWN';
    if (type != 'SUCCESSFUL') {
      // Garmin's reason (e.g. wrong/expired code); the body holds no secrets.
      log(
        '[Garmin] mfa: rejected — HTTP ${response.statusCode} type=$type '
        'message=${status?['message']} error=${json['error']}',
      );
      throw GarminAuthException(
        "That code didn't work. Make sure it is the newest code from "
        'your email and enter it again.',
      );
    }
    final ticket = json['serviceTicketId'] as String?;
    if (ticket == null) {
      throw GarminAuthException(
        'Verification partially failed. Please try again.',
      );
    }
    log('[Garmin] mfa: got service ticket');
    return ticket;
  }

  void _captureCookies(http.Response response) {
    final raw = response.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return;
    final jar = <String, String>{
      for (final c in _cookies.split('; ').where((c) => c.contains('=')))
        c.substring(0, c.indexOf('=')): c.substring(c.indexOf('=') + 1),
    };
    for (final cookie in splitSetCookieHeader(raw)) {
      final pair = cookie.split(';').first.trim();
      final eq = pair.indexOf('=');
      if (eq <= 0) continue;
      jar[pair.substring(0, eq)] = pair.substring(eq + 1);
    }
    _cookies = jar.entries.map((e) => '${e.key}=${e.value}').join('; ');
    log('[Garmin] cookies captured: ${_cookies.length} chars');
  }

  /// Trades the SSO service ticket for DI OAuth2 tokens. Garmin rotates the
  /// accepted client IDs, so each known one is tried in turn.
  Future<void> _exchangeServiceTicket(String ticket, {String? email}) async {
    // ignore: avoid_print
    print(
      '[Garmin] exchange: POST $_tokenUrl '
      '(trying ${_clientIds.length} client IDs)',
    );
    var rateLimited = false;
    for (final clientId in _clientIds) {
      log('[Garmin] exchange: trying client_id=$clientId');
      final response = await _http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Authorization': 'Basic ${base64.encode(utf8.encode('$clientId:'))}',
          'Accept': 'application/json,text/html;q=0.9,*/*;q=0.8',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cache-Control': 'no-cache',
          ..._nativeHeaders(),
        },
        body: {
          'client_id': clientId,
          'service_ticket': ticket,
          'grant_type':
              'https://connectapi.garmin.com/di-oauth2-service/oauth/grant/service_ticket',
          'service_url': _serviceUrl,
        },
      );
      // ignore: avoid_print
      print(
        '[Garmin] exchange: $clientId → ${response.statusCode} '
        '(${response.body.length} bytes)',
      );

      if (response.statusCode == 200) {
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final access = json['access_token'] as String;
          final refresh = json['refresh_token'] as String;
          final actualClientId = _extractClientIdFromJwt(access) ?? clientId;
          // ignore: avoid_print
          print(
            '[Garmin] exchange: success, client_id=$actualClientId '
            'expires_in=${json['expires_in']}s',
          );
          await _storeTokens(
            access,
            refresh,
            actualClientId,
            _expiresAtFromJwt(access),
            email,
          );
          return;
        } catch (e) {
          log('[Garmin] exchange: $clientId JSON parse error: $e');
          continue;
        }
      }
      if (response.statusCode == 429) {
        _logBlockedResponse('exchange', response);
        await _blockLogins('exchange');
        rateLimited = true;
        break;
      }
      final body = response.body;
      log(
        '[Garmin] exchange: $clientId failed — '
        '${body.length > 300 ? body.substring(0, 300) : body}',
      );
    }
    if (rateLimited) {
      throw GarminAuthException(
        'Too many requests. Garmin blocks logins for a while — '
        'please try again in 30 minutes.',
      );
    }
    throw GarminAuthException('Could not complete login. Please try again.');
  }

  Future<void> _storeTokens(
    String accessToken,
    String refreshToken,
    String clientId,
    int expiresAt, [
    String? email,
  ]) async {
    await Future.wait<void>([
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
      _storage.write(key: _kClientId, value: clientId),
      _storage.write(key: _kExpiresAt, value: '$expiresAt'),
      if (email != null) _storage.write(key: _kEmail, value: email),
    ]);
  }

  Map<String, dynamic>? _jwtPayload(String jwt) {
    final parts = jwt.split('.');
    if (parts.length < 2) return null;
    var payload = parts[1];
    payload += '=' * ((4 - payload.length % 4) % 4);
    return jsonDecode(utf8.decode(base64Url.decode(payload)))
        as Map<String, dynamic>;
  }

  /// Token expiry as epoch seconds; one hour from now if unreadable.
  int _expiresAtFromJwt(String jwt) {
    try {
      final exp = _jwtPayload(jwt)?['exp'] as num?;
      if (exp != null) return exp.toInt();
    } catch (_) {}
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
  }

  String? _extractClientIdFromJwt(String jwt) {
    try {
      return _jwtPayload(jwt)?['client_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _basicAuth(String clientId) =>
      'Basic ${base64.encode(utf8.encode('$clientId:'))}';

  Map<String, String> _nativeHeaders([Map<String, String>? extra]) {
    final headers = <String, String>{};
    headers['User-Agent'] = 'GCM-Android-5.23';
    headers['X-Garmin-User-Agent'] =
        'com.garmin.android.apps.connectmobile/5.23; ; Google/sdk_gphone64_arm64/google; Android/33; Dalvik/2.1.0';
    headers['X-Garmin-Paired-App-Version'] = '10861';
    headers['X-Garmin-Client-Platform'] = 'Android';
    headers['X-App-Ver'] = '10861';
    headers['X-Lang'] = 'en';
    headers['X-GCExperience'] = 'GC5';
    headers['Accept-Language'] = 'en-US,en;q=0.9';
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _getValidToken();
    return _nativeHeaders({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
  }

  Future<String> _getValidToken() async {
    await _ensureFreshToken();
    final token = await _storage.read(key: _kAccessToken);
    if (token == null) throw GarminAuthException('Not logged in');
    return token;
  }

  /// Refreshes when the access token expires within five minutes.
  Future<void> _ensureFreshToken() async {
    final raw = await _storage.read(key: _kExpiresAt);
    final expiresAt = int.tryParse(raw ?? '');
    if (expiresAt == null) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = expiresAt - now;
    log('[Garmin] ensureFreshToken: expires in ${remaining}s');
    if (remaining < 300) {
      log('[Garmin] ensureFreshToken: refreshing proactively');
      await _refreshDiToken();
    }
  }

  Future<void> _refreshDiToken() async {
    final refresh = await _storage.read(key: _kRefreshToken);
    final clientId = await _storage.read(key: _kClientId) ?? _clientIds.first;
    if (refresh == null) {
      throw GarminAuthException(
        'No refresh token stored. Please log in again.',
      );
    }
    log('[Garmin] refresh: POST $_tokenUrl client_id=$clientId');
    final http.Response response;
    try {
      response = await _http.post(
        Uri.parse(_tokenUrl),
        headers: _nativeHeaders({
          'Authorization': _basicAuth(clientId),
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cache-Control': 'no-cache',
        }),
        body: {
          'grant_type': 'refresh_token',
          'client_id': clientId,
          'refresh_token': refresh,
        },
      );
    } catch (e) {
      throw GarminAuthException(
        'Something went wrong refreshing your session. Please log in again.',
      );
    }
    log(
      '[Garmin] refresh: → ${response.statusCode} '
      '(${response.body.length} bytes)',
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final access = json['access_token'] as String?;
      final newRefresh = json['refresh_token'] as String? ?? refresh;
      if (access == null) {
        throw GarminAuthException(
          'Could not refresh your session. Please log in again.',
        );
      }
      final newClientId = _extractClientIdFromJwt(access) ?? clientId;
      // ignore: avoid_print
      print(
        '[Garmin] refresh: success, new client_id=$newClientId '
        'expires_in=${json['expires_in']}s',
      );
      await _storeTokens(
        access,
        newRefresh,
        newClientId,
        _expiresAtFromJwt(access),
      );
      return;
    }
    if (response.statusCode == 400 || response.statusCode == 401) {
      await logout();
      throw GarminAuthException('Session expired. Please log in again.');
    }
    final body = response.body;
    // ignore: avoid_print
    print(
      '[Garmin] refresh: failed body: '
      '${body.length > 600 ? body.substring(0, 600) : body}',
    );
    throw GarminAuthException(
      'Could not refresh your session. Please log in again.',
    );
  }

  // ── HTTP helpers ─────────────────────────────────────────────────────────

  Future<http.Response> _getWithRetry(
    String path, {
    Map<String, String>? params,
  }) async {
    final uri = Uri.parse('$_api$path').replace(queryParameters: params);
    log('[Garmin] GET $uri');
    var response = await _http.get(uri, headers: await _authHeaders());
    log('[Garmin] → ${response.statusCode} (${response.body.length} bytes)');
    if (response.statusCode == 401) {
      log('[Garmin] 401 — forcing token refresh and retrying');
      await _refreshDiToken();
      response = await _http.get(uri, headers: await _authHeaders());
      log('[Garmin] retry → ${response.statusCode}');
    }
    return response;
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? params,
  }) async {
    final response = await _getWithRetry(path, params: params);
    if (response.statusCode == 200) {
      if (response.body.isEmpty) return const {};
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return const {};
      log('[Garmin] parsed keys: ${json.keys.toList()}');
      return json;
    }
    if (response.statusCode == 401) {
      throw GarminAuthException('Session expired. Please log in again.');
    }
    _logErrorBody(response);
    throw GarminApiException(
      'API error ${response.statusCode}: ${response.body}',
    );
  }

  Future<List> _getList(String path, Map<String, String> params) async {
    final response = await _getWithRetry(path, params: params);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final list = json is List ? json : const [];
      log('[Garmin] parsed list: ${list.length} items');
      return list;
    }
    if (response.statusCode == 401) {
      throw GarminAuthException('Session expired. Please log in again.');
    }
    _logErrorBody(response);
    throw GarminApiException(
      'API error ${response.statusCode}: ${response.body}',
    );
  }

  void _logErrorBody(http.Response response) {
    final body = response.body;
    // ignore: avoid_print
    print(
      '[Garmin] ERROR body: '
      '${body.length > 1000 ? body.substring(0, 1000) : body}',
    );
  }

  String _dateStr(DateTime d) =>
      '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _decodeBody(http.Response response) =>
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

  // ── Activities ──────────────────────────────────────────────────────────

  Future<List<GarminActivity>> getActivities({
    int limit = 20,
    int start = 0,
  }) async {
    log('[Garmin] getActivities: limit=$limit start=$start');
    try {
      final list = await _getList(
        '/activitylist-service/activities/search/activities',
        {'limit': '$limit', 'start': '$start'},
      );
      final activities = list
          .cast<Map<String, dynamic>>()
          .map(GarminActivity.fromGarminJson)
          .toList();
      log('[Garmin] getActivities: ${activities.length} activities');
      return activities;
    } on GarminAuthException {
      rethrow;
    } catch (e) {
      log('[Garmin] getActivities ERROR: $e');
      return <GarminActivity>[];
    }
  }

  /// GPS track, per-row samples and HR zones of one activity.
  Future<
    ({
      Map<String, double>? hrZones,
      List<ActivitySample>? samples,
      double? totalElevation,
      List<LatLng>? trackPoints,
    })
  >
  getActivityDetails(String activityId) async {
    log('[Garmin] getActivityDetails: activityId=$activityId');
    List<LatLng>? track;
    List<ActivitySample>? samples;
    try {
      final response = await _getWithRetry(
        '/activity-service/activity/$activityId/details',
        params: {'maxChartSize': '2000'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        log('[Garmin] details keys: ${json.keys.toList()}');

        final polyline = (json['geoPolylineDTO'] as Map?)?['polyline'] as List?;
        if (polyline != null) {
          track = polyline
              .cast<Map<String, dynamic>>()
              .map<LatLng?>((p) {
                final lat = (p['lat'] as num?)?.toDouble();
                final lon = (p['lon'] as num?)?.toDouble();
                return lat == null || lon == null ? null : LatLng(lat, lon);
              })
              .whereType<LatLng>()
              .toList();
          log('[Garmin] GPS points: ${track.length}');
        }

        final descriptors =
            (json['metricDescriptors'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            const [];
        final rows = (json['activityDetailMetrics'] as List?) ?? const [];
        // ignore: avoid_print
        print(
          '[Garmin] descriptor count: ${descriptors.length}, '
          'row count: ${rows.length}',
        );

        final index = <String, int>{};
        for (final d in descriptors) {
          final key =
              (d['key'] ?? d['appDescriptorKey'] ?? d['columnHeaderKey'] ?? '')
                  as String;
          final idx =
              (d['metricsIndex'] ?? d['index'] ?? d['columnIndex']) as int?;
          if (idx != null) index[key] = idx;
        }
        int? first(List<String> keys) {
          for (final k in keys) {
            if (index.containsKey(k)) return index[k];
          }
          return null;
        }

        final tsIdx = first(['directTimestamp', 'sumDuration']);
        final distIdx = first(['directDistance', 'sumDistance']);
        final hrIdx = first(['directHeartRate']);
        final speedIdx = first(['directSpeed', 'directGradeAdjustedSpeed']);
        final eleIdx = first([
          'directElevation',
          'directAltitude',
          'directElevationCorrected',
          'sumElevationGain',
        ]);
        final powerIdx = first(['directPower']);
        // ignore: avoid_print
        print(
          '[Garmin] idx: ts=$tsIdx dist=$distIdx hr=$hrIdx '
          'spd=$speedIdx ele=$eleIdx pwr=$powerIdx',
        );
        samples = _parseMetricRows(
          rows,
          distIdx,
          hrIdx,
          speedIdx,
          powerIdx,
          eleIdx: eleIdx,
          timestampIdx: first(['directTimestamp']),
        );
        log('[Garmin] samples parsed: ${samples.length}');
      } else {
        // ignore: avoid_print
        print(
          '[Garmin] details HTTP ${response.statusCode}: '
          '${response.body.length > 300 ? response.body.substring(0, 300) : response.body}',
        );
      }
    } catch (e, st) {
      log('[Garmin] getActivityDetails ERROR: $e\n$st');
    }

    if (track == null || track.isEmpty) {
      track = await _fetchGpxFallback(activityId);
    }
    final hrZones = await _fetchHrZones(activityId);
    return (
      hrZones: hrZones,
      samples: samples,
      totalElevation: samples == null ? null : _calculateElevationGain(samples),
      trackPoints: track,
    );
  }

  /// Positive elevation gain with a 1 m noise floor between samples.
  double? _calculateElevationGain(List<ActivitySample> samples) {
    final elevations = samples
        .map((s) => s.elevation)
        .whereType<double>()
        .where((e) => e > -100 && e < 10000)
        .toList();
    if (elevations.length < 2) return null;
    var gain = 0.0;
    for (var i = 1; i < elevations.length; i++) {
      final delta = elevations[i] - elevations[i - 1];
      if (delta > 0 && delta < 100) gain += delta;
    }
    return gain;
  }

  /// The exercise sets the watch recorded for a strength activity, as
  /// Garmin returns them; null when there are none or the request fails.
  /// Nothing else of the response is kept.
  Future<Object?> getExerciseSets(String activityId) async {
    try {
      final response = await _getWithRetry(
        '/activity-service/activity/$activityId/exerciseSets',
      );
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } catch (e) {
      log('[Garmin] getExerciseSets ERROR: $e');
      return null;
    }
  }

  Future<Map<String, double>?> _fetchHrZones(String activityId) async {
    try {
      final response = await _getWithRetry(
        '/activity-service/activity/$activityId/hrTimeInZones',
      );
      if (response.statusCode != 200) return null;
      final list = jsonDecode(response.body) as List;
      final seconds = <String, double>{};
      for (final z in list.cast<Map<String, dynamic>>()) {
        final zone = z['zoneNumber'] ?? z['zone'];
        final secs = (z['secsInZone'] as num?)?.toDouble() ?? 0.0;
        if (zone != null) seconds['zone$zone'] = secs;
      }
      if (seconds.isEmpty) return null;
      final total = seconds.values.reduce((a, b) => a + b);
      if (total <= 0) return null;
      // Percent of time per zone.
      return seconds.map((k, v) => MapEntry(k, v / total * 100));
    } catch (e) {
      log('[Garmin] fetchHrZones ERROR: $e');
      return null;
    }
  }

  Future<List<LatLng>?> _fetchGpxFallback(String activityId) async {
    try {
      final response = await _getWithRetry(
        '/activity-service/activity/$activityId/gpx/course/$activityId.gpx',
      );
      log('[Garmin] GPX fallback: HTTP ${response.statusCode}');
      if (response.statusCode != 200) return null;
      final points = RegExp(r'<trkpt\s+lat="([^"]+)"\s+lon="([^"]+)"')
          .allMatches(response.body)
          .map<LatLng?>((m) {
            final lat = double.tryParse(m.group(1) ?? '');
            final lon = double.tryParse(m.group(2) ?? '');
            return lat == null || lon == null ? null : LatLng(lat, lon);
          })
          .whereType<LatLng>()
          .toList();
      log('[Garmin] GPX fallback: ${points.length} points');
      return points;
    } catch (e) {
      log('[Garmin] GPX fallback ERROR: $e');
      return null;
    }
  }

  /// One sample per detail row that has a distance.
  List<ActivitySample> _parseMetricRows(
    List rows,
    int? distIdx,
    int? hrIdx,
    int? speedIdx,
    int? powerIdx, {
    int? eleIdx,
    int? timestampIdx,
  }) {
    double? valueAt(List values, int? idx) {
      if (idx == null || idx >= values.length) return null;
      return (values[idx] as num?)?.toDouble();
    }

    final samples = <ActivitySample>[];
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final values = (row['metrics'] ?? row['values']) as List? ?? const [];
      final dist = valueAt(values, distIdx);
      final timestamp = heartRateTimestamp(valueAt(values, timestampIdx));
      if (dist == null && timestamp == null) continue;
      final hr = valueAt(values, hrIdx);
      final power = valueAt(values, powerIdx);
      samples.add(
        ActivitySample(
          distanceMeters: dist ?? 0,
          timestamp: timestamp,
          heartRate: hr != null && hr > 0 ? hr : null,
          speed: valueAt(values, speedIdx),
          elevation: valueAt(values, eleIdx),
          power: power != null && power > 0 ? power : null,
        ),
      );
    }
    return samples;
  }

  // ── Wellness ────────────────────────────────────────────────────────────

  Future<BodyBatteryReport?> getBodyBattery(DateTime date) async {
    log('[Garmin] getBodyBattery: ${_dateStr(date)}');
    try {
      final list = await _getList(
        '/wellness-service/wellness/bodyBattery/reports/daily',
        {'startDate': _dateStr(date), 'endDate': _dateStr(date)},
      );
      if (list.isEmpty) return null;
      final report = BodyBatteryReport.fromGarminJson(
        list.first as Map<String, dynamic>,
      );
      // ignore: avoid_print
      print(
        '[Garmin] getBodyBattery: current=${report.currentValue} '
        'charged=${report.charged} drained=${report.drained}',
      );
      return report;
    } catch (e) {
      log('[Garmin] getBodyBattery ERROR: $e');
      return null;
    }
  }

  Future<double?> getFitnessAge(DateTime date) async {
    try {
      final json = await _get(
        '/fitnessage-service/fitnessage/${_dateStr(date)}',
      );
      final age = (json['fitnessAge'] as num?)?.toDouble();
      log('[Garmin] getFitnessAge: $age');
      return age == null || age <= 0 ? null : age;
    } catch (e) {
      log('[Garmin] getFitnessAge ERROR: $e');
      return null;
    }
  }

  Map<String, dynamic>? _settingsCache;
  DateTime? _settingsFetchedAt;

  /// User settings, cached for ten minutes.
  Future<Map<String, dynamic>?> _getUserSettings() async {
    final fetched = _settingsFetchedAt;
    if (_settingsCache != null &&
        fetched != null &&
        DateTime.now().difference(fetched).inMinutes < 10) {
      return _settingsCache;
    }
    final json = await _get('/userprofile-service/userprofile/user-settings');
    _settingsCache = json['userData'] as Map<String, dynamic>?;
    _settingsFetchedAt = DateTime.now();
    return _settingsCache;
  }

  Future<double?> getVo2MaxRunning() async {
    try {
      final data = await _getUserSettings();
      final v = (data?['vo2MaxRunning'] as num?)?.toDouble();
      log('[Garmin] getVo2MaxRunning: $v');
      return v == null || v <= 0 ? null : v;
    } catch (e) {
      log('[Garmin] getVo2MaxRunning ERROR: $e');
      return null;
    }
  }

  Future<double?> getVo2MaxCycling() async {
    try {
      final data = await _getUserSettings();
      for (final key in const ['vo2MaxCycling', 'vo2MaxCyclingValue']) {
        final v = (data?[key] as num?)?.toDouble();
        if (v != null && v > 0) {
          log('[Garmin] getVo2MaxCycling: $v ($key)');
          return v;
        }
      }
      log('[Garmin] getVo2MaxCycling: null');
      return null;
    } catch (e) {
      log('[Garmin] getVo2MaxCycling ERROR: $e');
      return null;
    }
  }

  Future<double?> getDailySpo2(DateTime date) async {
    log('[Garmin] getDailySpo2: ${_dateStr(date)}');
    try {
      final json = await _get(
        '/wellness-service/wellness/daily/spo2/${_dateStr(date)}',
      );
      final v = (json['avgSpO2'] ?? json['averageSpO2']) as num?;
      return v?.toDouble();
    } catch (e) {
      log('[Garmin] getDailySpo2 ERROR: $e');
      return null;
    }
  }

  Future<List<TimedHeartRate>> getHeartRateSamples(DateTime date) async {
    final json = await _get(
      '/wellness-service/wellness/dailyHeartRate/',
      params: {'date': _dateStr(date)},
    );
    return parseTimedHeartRates(json['heartRateValues'], 'garmin_api');
  }

  Future<WellnessData?> getWellness(DateTime date) async {
    log('[Garmin] getWellness: ${_dateStr(date)}');
    try {
      final json = await _get(
        '/usersummary-service/usersummary/daily/',
        params: {'calendarDate': _dateStr(date)},
      );
      if (json.isEmpty) return null;
      final data = LinkedHashMap<String, dynamic>.of(json);
      data['calendarDate'] ??= _dateStr(date);
      final wellness = WellnessData.fromGarminJson(data);
      // ignore: avoid_print
      print(
        '[Garmin] getWellness: steps=${wellness.steps} '
        'stress=${wellness.averageStress} '
        'bodyBattery=${wellness.bodyBatteryLowest}/${wellness.bodyBatteryHighest}',
      );
      return wellness;
    } catch (e) {
      log('[Garmin] getWellness ERROR: $e');
      return null;
    }
  }

  Future<SleepData?> getSleep(DateTime date) async {
    log('[Garmin] getSleep: ${_dateStr(date)}');
    try {
      final json = await _get(
        '/sleep-service/sleep/dailySleepData',
        params: {'date': _dateStr(date)},
      );
      final dto = json['dailySleepDTO'] as Map<String, dynamic>?;
      if (dto == null) return null;
      log('[Garmin] dailySleepDTO keys: ${dto.keys.toList()}');
      log('[Garmin] sleepNeed raw: ${dto['sleepNeed']}');
      final sleep = SleepData.fromGarminJson(json);
      // ignore: avoid_print
      print(
        '[Garmin] getSleep: total=${sleep.totalSleep.inMinutes}'
        'min deep=${sleep.deepSleep.inMinutes}'
        'min score=${sleep.sleepScore} spo2=${sleep.avgSpo2} '
        'resp=${sleep.avgRespiration?.toStringAsFixed(1)} '
        'skinTemp=${sleep.skinTempDelta} sleepNeed='
        '${sleep.sleepNeedSeconds != null ? '${sleep.sleepNeedSeconds! / 60}min' : 'null'}',
      );
      return sleep;
    } catch (e) {
      log('[Garmin] getSleep ERROR: $e');
      return null;
    }
  }

  Future<HrvData?> getHrv(DateTime date) async {
    log('[Garmin] getHrv: ${_dateStr(date)}');
    try {
      final json = await _get('/hrv-service/hrv/${_dateStr(date)}');
      if (json.isEmpty) return null;
      final data = LinkedHashMap<String, dynamic>.of(json);
      data['calendarDate'] ??= _dateStr(date);
      final hrv = HrvData.fromGarminJson(data);
      // ignore: avoid_print
      print(
        '[Garmin] getHrv: lastNight=${hrv.lastNightAvg} '
        'weeklyAvg=${hrv.weeklyAvg} rhr=${hrv.restingHeartRate}',
      );
      return hrv;
    } catch (e) {
      log('[Garmin] getHrv ERROR: $e');
      return null;
    }
  }

  /// The user's HR zone setup per sport (always fetched fresh, so changes
  /// such as switching to %LTHR zones are picked up).
  Future<List<DeviceHrZones>> getHrZoneSettings() async {
    try {
      final response = await _getWithRetry('/biometric-service/heartRateZones');
      if (response.statusCode != 200) return const [];
      final body = jsonDecode(response.body);
      final rows = body is List ? body : [body];
      final settings = [
        for (final row in rows.whereType<Map>())
          ?DeviceHrZones.fromGarminJson(Map<String, dynamic>.from(row)),
      ];
      log(
        '[Garmin] hrZones: ${settings.map((z) => '${z.sport}/${z.method} '
            'lthr=${z.lthr} max=${z.maxHr} floors=${z.floors}').join('; ')}',
      );
      return settings;
    } catch (e) {
      log('[Garmin] getHrZoneSettings ERROR: $e');
      return const [];
    }
  }

  // ── Workouts & calendar ─────────────────────────────────────────────────

  static String _garminSportTypeKey(String sport) {
    switch (sport.trim().toLowerCase()) {
      case 'running' || 'run':
        return 'running';
      case 'cycling' || 'bike' || 'biking' || 'ride':
        return 'cycling';
      case 'swimming' || 'swim':
        return 'swimming';
      case 'strength' || 'strength_training' || 'gym' || 'weight':
        return 'strength_training';
      case 'cardio' || 'cardio_training' || 'hiit' || 'crossfit':
        return 'cardio_training';
      default:
        return 'running';
    }
  }

  static Map<String, dynamic> _garminSportType(String sport) {
    final key = _garminSportTypeKey(sport);
    final id = switch (key) {
      'running' => 1,
      'cycling' => 2,
      'swimming' => 4,
      'strength_training' => 5,
      'cardio_training' => 6,
      _ => 1,
    };
    return {'sportTypeId': id, 'sportTypeKey': key, 'displayOrder': id};
  }

  /// Creates a structured workout and returns its Garmin workout id.
  Future<String> createWorkout(
    String name,
    String sport,
    List<Map<String, dynamic>> steps, {
    String? description,
  }) async {
    // Repetitions and lap-button steps have no time of their own.
    final estimatedSecs = steps.fold<num>(0, (sum, s) {
      final key = (s['endCondition'] as Map?)?['conditionTypeKey'];
      if (key == 'reps' || key == 'lap.button') return sum;
      return sum + ((s['endConditionValue'] as num?) ?? 0);
    });
    final sportType = _garminSportType(sport);
    final body = jsonEncode({
      'workoutName': name,
      'description': description ?? 'Created by Fjelia',
      'estimatedDurationInSecs': estimatedSecs.round(),
      'sportType': sportType,
      'workoutSegments': [
        <String, Object>{
          'segmentOrder': 1,
          'sportType': sportType,
          'workoutSteps': steps,
        },
      ],
    });
    final uri = Uri.parse('$_api/workout-service/workout');
    log('[Garmin] POST $uri');
    var response = await _http.post(
      uri,
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: body,
    );
    log(
      '[Garmin] createWorkout → ${response.statusCode}: '
      '${response.body.length > 600 ? response.body.substring(0, 600) : response.body}',
    );
    if (response.statusCode == 401) {
      await _refreshDiToken();
      response = await _http.post(
        uri,
        headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
        body: body,
      );
    }
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return (json['workoutId'] ?? json['id']).toString();
    }
    throw GarminApiException(
      'createWorkout failed ${response.statusCode}: ${response.body}',
    );
  }

  /// Puts a workout on the Garmin calendar; returns the schedule id.
  Future<String?> scheduleWorkout(String workoutId, DateTime date) async {
    final dateStr = _dateStr(date);
    final body = jsonEncode(<String, String>{'date': dateStr});
    final uri = Uri.parse('$_api/workout-service/schedule/$workoutId');
    log('[Garmin] POST $uri date=$dateStr');
    var response = await _http.post(
      uri,
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: body,
    );
    log(
      '[Garmin] scheduleWorkout → ${response.statusCode}: '
      '${response.body.length > 600 ? response.body.substring(0, 600) : response.body}',
    );
    if (response.statusCode == 401) {
      await _refreshDiToken();
      response = await _http.post(
        uri,
        headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
        body: body,
      );
    }
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return (json['scheduleId'] ?? json['id'])?.toString();
    }
    throw GarminApiException(
      'scheduleWorkout failed ${response.statusCode}: ${response.body}',
    );
  }

  /// Removes a calendar entry while retaining its workout definition.
  Future<void> unscheduleWorkout(String scheduleId) async {
    final uri = Uri.parse('$_api/workout-service/schedule/$scheduleId');
    log('[Garmin] DELETE $uri');
    var response = await _http.delete(uri, headers: await _authHeaders());
    if (response.statusCode == 401) {
      response = await _http.delete(uri, headers: await _authHeaders());
    }
    if (response.statusCode >= 300 && response.statusCode != 404) {
      throw GarminApiException(
        'unschedule failed ${response.statusCode}: ${response.body}',
      );
    }
  }

  /// Removes a workout, unscheduling it first when [scheduleId] is given.
  Future<void> deleteWorkout(String workoutId, {String? scheduleId}) async {
    if (scheduleId != null) await unscheduleWorkout(scheduleId);
    final uri = Uri.parse('$_api/workout-service/workout/$workoutId');
    log('[Garmin] DELETE $uri');
    var response = await _http.delete(uri, headers: await _authHeaders());
    if (response.statusCode == 401) {
      response = await _http.delete(uri, headers: await _authHeaders());
    }
    if (response.statusCode >= 300 && response.statusCode != 404) {
      throw GarminApiException(
        'deleteWorkout failed ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<List<String>> listWorkoutIds() async {
    final uri = Uri.parse('$_api/workout-service/workout?start=1&limit=999');
    var response = await _http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 401) {
      await _refreshDiToken();
      response = await _http.get(uri, headers: await _authHeaders());
    }
    if (response.statusCode != 200) {
      log(
        '[Garmin] listWorkoutIds → ${response.statusCode}: '
        '${response.body.length > 1000 ? response.body.substring(0, 1000) : response.body}',
      );
      return const [];
    }
    final json = jsonDecode(response.body);
    final list = json is List
        ? json
        : (json is Map ? json['workoutList'] as List? : null) ?? const [];
    return list
        .map(
          (w) => w is Map
              ? (w['workoutId'] ?? w['workout_id'] ?? w['id'] ?? '').toString()
              : '',
        )
        .where((id) => id.isNotEmpty && id != 'null')
        .toList();
  }

  List<({int year, int month0})> _monthsBetween(DateTime from, DateTime to) {
    final months = <({int year, int month0})>[];
    var cursor = DateTime(from.year, from.month);
    final end = DateTime(to.year, to.month);
    while (!cursor.isAfter(end)) {
      months.add((year: cursor.year, month0: cursor.month - 1));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return months;
  }

  Future<List<Map<String, dynamic>>> _calendarItems(
    int year,
    int month0,
  ) async {
    final response = await _getWithRetry(
      '/calendar-service/year/$year/month/$month0',
    );
    if (response.statusCode != 200) return const [];
    final json = _decodeBody(response);
    return (json['calendarItems'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];
  }

  /// `"title|yyyy-MM-dd"` → workout id for workouts already on the calendar,
  /// used to avoid pushing duplicates.
  Future<Map<String, String>> calendarWorkoutsByTitleDate({
    int monthsAhead = 2,
  }) async {
    final now = DateTime.now();
    final result = <String, String>{};
    for (var i = 0; i < monthsAhead; i++) {
      final m = DateTime(now.year, now.month + i);
      try {
        final items = await _calendarItems(m.year, m.month - 1);
        for (final item in items) {
          final type = item['itemType'] as String? ?? '';
          if (!type.contains('orkout')) continue;
          final title = item['title'] as String? ?? '';
          final date = item['date'] as String? ?? '';
          if (date.length < 10) continue;
          final id = (item['workoutId'] ?? item['id'])?.toString() ?? '';
          if (id.isEmpty) continue;
          result['$title|${date.substring(0, 10)}'] = id;
        }
      } catch (e) {
        log('[Garmin] calendarWorkoutsByTitleDate month $m error: $e');
      }
    }
    log('[Garmin] calendarWorkoutsByTitleDate: ${result.length} items');
    return result;
  }

  Future<List<({String scheduleId, String workoutId})>> listCalendarWorkouts({
    int monthsAhead = 3,
  }) async {
    final now = DateTime.now();
    final found = <({String scheduleId, String workoutId})>{};
    final seen = <String>{};
    for (var i = 0; i < monthsAhead; i++) {
      final m = DateTime(now.year, now.month + i);
      try {
        for (final item in await _calendarItems(m.year, m.month - 1)) {
          final type = item['itemType'] as String? ?? '';
          if (!type.contains('orkout')) continue;
          final workoutId = item['workoutId']?.toString() ?? '';
          final scheduleId = item['id']?.toString() ?? '';
          if (workoutId.isEmpty || scheduleId.isEmpty) continue;
          if (seen.add('${scheduleId}_$workoutId')) {
            found.add((scheduleId: scheduleId, workoutId: workoutId));
          }
        }
      } catch (e) {
        log('[Garmin] listCalendarWorkouts month $m error: $e');
      }
    }
    log('[Garmin] listCalendarWorkouts found ${found.length} items');
    return found.toList();
  }

  /// Races and events from the Garmin calendar for the next months.
  Future<List<Map<String, dynamic>>> getRaceEvents({
    int monthsAhead = 12,
  }) async {
    final now = DateTime.now();
    final events = <Map<String, dynamic>>[];
    for (var i = 0; i < monthsAhead; i++) {
      final m = DateTime(now.year, now.month + i);
      try {
        for (final item in await _calendarItems(m.year, m.month - 1)) {
          final type = (item['itemType'] as String? ?? '').toLowerCase();
          if (!(type.contains('race') ||
              type.contains('event') ||
              type.contains('course'))) {
            continue;
          }
          final date = DateTime.tryParse(item['date'] as String? ?? '');
          if (date == null || date.isBefore(now)) continue;
          events.add(item);
        }
      } catch (e) {
        log('[Garmin] getRaceEvents ERROR month $m: $e');
      }
    }
    return events;
  }

  /// Planned workouts for the next 14 days, enriched with their steps.
  Future<List<ScheduledWorkout>> getScheduledWorkouts() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final horizon = today.add(const Duration(days: 14));
    final workouts = <ScheduledWorkout>[];

    for (final m in _monthsBetween(today, horizon)) {
      try {
        final items = await _calendarItems(m.year, m.month0);
        // ignore: avoid_print
        print(
          '[Garmin] calendar itemTypes: '
          '${items.map((i) => i['itemType'] as String? ?? '?').toSet()}',
        );
        for (final item in items) {
          final type = item['itemType'] as String? ?? '';
          if (type != 'workout' && type != 'fbtAdaptiveWorkout') continue;
          final date = DateTime.tryParse(item['date'] as String? ?? '');
          if (date == null) continue;
          final day = DateTime(date.year, date.month, date.day);
          if (day.isBefore(today) || day.isAfter(horizon)) continue;
          workouts.add(ScheduledWorkout.fromCalendarItem(item));
        }
      } catch (e) {
        log('[Garmin] getScheduledWorkouts calendar ERROR: $e');
      }
    }

    // Adaptive (Garmin Coach) workouts carry no steps on the calendar; the
    // plan endpoint has a phrase per day we can turn into steps.
    final planId = workouts
        .map((w) => w.trainingPlanId)
        .firstWhere((id) => id != null, orElse: () => null);
    if (planId != null &&
        workouts.any((w) => w.itemType == 'fbtAdaptiveWorkout')) {
      try {
        final tasks = await _fetchAdaptivePlanSteps(planId);
        for (var i = 0; i < workouts.length; i++) {
          final w = workouts[i];
          final task = tasks[_dateStr(w.scheduledDate)];
          if (task == null) continue;
          workouts[i] = ScheduledWorkout(
            workoutId: w.workoutId,
            scheduleId: w.scheduleId,
            trainingPlanId: w.trainingPlanId,
            name: task.name,
            sportType: w.sportType,
            scheduledDate: w.scheduledDate,
            estimatedDuration: task.durationSecs != null
                ? Duration(seconds: task.durationSecs!)
                : w.estimatedDuration,
            estimatedDistanceMeters: w.estimatedDistanceMeters,
            description: task.description,
            itemType: w.itemType,
            steps: task.steps,
          );
        }
      } catch (e) {
        log('[Garmin] getScheduledWorkouts enrichSteps ERROR: $e');
      }
    }

    // Drop duplicates (same workout listed in two months) and sort.
    final seen = <String>{};
    workouts.retainWhere(
      (w) => seen.add('${w.workoutId}_${_dateStr(w.scheduledDate)}'),
    );
    workouts.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    final needSteps = workouts
        .asMap()
        .entries
        .where(
          (e) =>
              e.value.steps.isEmpty && e.value.itemType != 'fbtAdaptiveWorkout',
        )
        .toList();
    final fetched = await Future.wait(
      needSteps.map((e) async {
        try {
          final steps = await getWorkoutSteps(
            e.value.workoutId,
            scheduleId: e.value.scheduleId,
          );
          return (index: e.key, steps: steps, desc: e.value.description);
        } catch (_) {
          return (
            index: e.key,
            steps: <WorkoutStep>[],
            desc: e.value.description,
          );
        }
      }),
    );
    for (final r in fetched) {
      final w = workouts[r.index];
      workouts[r.index] = ScheduledWorkout(
        workoutId: w.workoutId,
        scheduleId: w.scheduleId,
        trainingPlanId: w.trainingPlanId,
        name: w.name,
        sportType: w.sportType,
        scheduledDate: w.scheduledDate,
        estimatedDuration: w.estimatedDuration,
        estimatedDistanceMeters: w.estimatedDistanceMeters,
        description: r.desc,
        itemType: w.itemType,
        steps: r.steps,
      );
    }
    // ignore: avoid_print
    print(
      '[Garmin] scheduledWorkouts: ${workouts.length} '
      '(${workouts.where((w) => w.steps.isNotEmpty).length} with steps)',
    );
    return workouts;
  }

  /// Day-by-day tasks of a Garmin Coach plan, keyed `yyyy-MM-dd`. Also caches
  /// the plan's metadata for the training-plan screen.
  Future<Map<String, _PlanTask>> _fetchAdaptivePlanSteps(String planId) async {
    log('[Garmin] fetchAdaptivePlanSteps: planId=$planId');
    final response = await _getWithRetry(
      '/trainingplan-service/trainingplan/fbt-adaptive/$planId',
    );
    // ignore: avoid_print
    print(
      '[Garmin] fbt-adaptive → HTTP ${response.statusCode} '
      '(${response.body.length} bytes)',
    );
    final tasks = <String, _PlanTask>{};
    if (response.statusCode != 200) return tasks;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final planName =
        (json['trainingPlanName'] ?? json['planName'] ?? json['name'])
            as String?;
    log('[Garmin] fbt-adaptive keys: ${json.keys.toList()}');
    final durationInWeeks = (json['durationInWeeks'] as num?)?.toInt();
    final avgWeekly = (json['avgWeeklyWorkouts'] as num?)?.toInt();
    final startDate = json['startDate'] as String?;
    final endDate = json['endDate'] as String?;
    log(
      '[Garmin] fbt-adaptive plan meta: durationInWeeks=$durationInWeeks '
      'startDate=$startDate endDate=$endDate avgWeeklyWorkouts=$avgWeekly',
    );

    final taskList =
        (json['taskList'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    log('[Garmin] fbt-adaptive taskList length: ${taskList.length}');
    if (taskList.isNotEmpty) {
      // ignore: avoid_print
      print(
        '[Garmin] fbt-adaptive task[0] keys: ${taskList.first.keys.toList()}',
      );
    }

    for (final task in taskList) {
      final workout = task['taskWorkout'] as Map<String, dynamic>?;
      if (workout == null || task['restDay'] == true) continue;
      final date = (task['calendarDate'] ?? task['scheduledDate']) as String?;
      if (date == null || date.length < 10) continue;
      final name = workout['workoutName'] as String? ?? 'Workout';
      final desc = workout['workoutDescription'] as String?;
      final secs = (workout['estimatedDurationInSecs'] as num?)?.toInt();
      final phrase = workout['workoutPhrase'] as String?;
      tasks[date.substring(0, 10)] = _PlanTask(
        name: name,
        description: desc,
        durationSecs: secs,
        phrase: phrase,
        week: (task['taskWeek'] as num?)?.toInt(),
        day: (task['taskDay'] as num?)?.toInt(),
        steps: _buildAdaptiveSteps(name, desc, secs, phrase),
      );
    }
    // ignore: avoid_print
    print(
      '[Garmin] fbt-adaptive: mapped ${tasks.length} dates: '
      '${tasks.keys.toList()}',
    );

    try {
      final start = startDate != null ? DateTime.parse(startDate) : null;
      if (start != null) {
        final weeks =
            durationInWeeks ??
            tasks.values
                .map((t) => t.week)
                .whereType<int>()
                .fold<int>(0, math.max);
        final currentWeek = (DateTime.now().difference(start).inDays ~/ 7 + 1)
            .clamp(1, math.max(weeks, 1))
            .toInt();
        final meta = TrainingPlanMeta(
          planId: planId,
          planName: planName ?? 'Training Plan',
          durationInWeeks: weeks,
          avgWeeklyWorkouts: avgWeekly ?? 0,
          startDate: start,
          endDate: endDate != null ? DateTime.tryParse(endDate) : null,
          currentWeek: currentWeek,
        );
        await _storage.write(key: _kPlanMeta, value: jsonEncode(meta.toJson()));
        log(
          '[Garmin] plan meta saved: week $currentWeek/$weeks '
          'endDate=${meta.endDate}',
        );
      }
    } catch (e) {
      log('[Garmin] plan meta save error: $e');
    }
    return tasks;
  }

  Future<TrainingPlanMeta?> getTrainingPlanMeta() async {
    final raw = await _storage.read(key: _kPlanMeta);
    if (raw == null) return null;
    return TrainingPlanMeta.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Turns an adaptive-plan description such as `5x3:00@165-172bpm` or
  /// `45:00@140bpm` into executable steps with warm-up and cool-down.
  static List<WorkoutStep> _buildAdaptiveSteps(
    String name,
    String? description,
    int? durationSecs,
    String? phrase,
  ) {
    final text = description ?? '';
    int? hrLow, hrHigh;
    final range = RegExp(r'@(\d+)-(\d+)bpm').firstMatch(text);
    if (range != null) {
      hrLow = int.tryParse(range.group(1)!);
      hrHigh = int.tryParse(range.group(2)!);
    } else {
      final single = RegExp(r'@(\d+)bpm').firstMatch(text);
      if (single != null) {
        hrLow = int.tryParse(single.group(1)!);
        hrHigh = hrLow;
      }
    }

    WorkoutStep timeStep(
      int order,
      String stepName,
      String intensity,
      int secs, {
      bool withHr = false,
    }) => WorkoutStep(
      order: order,
      type: 'ExecutableStepDTO',
      stepName: stepName,
      intensity: intensity,
      durationUnit: 'time',
      durationValue: secs.toDouble(),
      targetType: withHr && hrLow != null ? 'heartRate' : null,
      targetFrom: withHr ? hrLow?.toDouble() : null,
      targetTo: withHr ? hrHigh?.toDouble() : null,
    );

    final isInterval = RegExp(r'\d+x\d+:\d{2}').hasMatch(text);
    if (!isInterval) {
      final intensity = _phraseToIntensity(phrase);
      final total = _parseDescriptionSecs(text) ?? durationSecs;
      if (total == null) return const [];
      if (RegExp(r'^\d+:\d{2}@').hasMatch(text.trim()) && total <= 1200) {
        // Short steady run: a single step.
        return [timeStep(1, 'Run', intensity, total, withHr: true)];
      }
      final warm = total > 1200 ? 600 : 300;
      final cool = total > 1200 ? 600 : 300;
      final main = math.max(total - warm - cool, 60);
      return [
        timeStep(1, 'Warm Up', 'WARMUP', warm),
        timeStep(2, 'Run', intensity, main, withHr: true),
        timeStep(3, 'Cool Down', 'COOLDOWN', cool),
      ];
    }

    // Intervals: `sets x reps x dur` or `reps x dur`.
    int reps;
    int workSecs;
    final nested = RegExp(r'(\d+)x(\d+)x(\d+:\d{2})').firstMatch(text);
    final simple = RegExp(r'(\d+)x(\d+:\d{2})').firstMatch(text);
    if (nested != null) {
      reps = int.parse(nested.group(1)!) * int.parse(nested.group(2)!);
      workSecs = _parseDescriptionSecs(nested.group(3)!) ?? 60;
    } else {
      reps = int.parse(simple!.group(1)!);
      workSecs = _parseDescriptionSecs(simple.group(2)!) ?? 60;
    }
    final restSecs = workSecs >= 300 ? 120 : 60;
    final total = durationSecs ?? reps * (workSecs + restSecs) + 1200;
    final warm = total > 1200 ? 600 : 300;

    return [
      timeStep(1, 'Warm up', 'WARMUP', warm),
      WorkoutStep(
        order: 2,
        type: 'RepeatGroupDTO',
        stepName: 'Repeat',
        repeatCount: reps,
        steps: [
          timeStep(3, 'Laufen', 'ACTIVE', workSecs, withHr: true),
          timeStep(4, 'Pause', 'REST', restSecs),
        ],
      ),
      timeStep(5, 'Cool Down', 'COOLDOWN', warm),
    ];
  }

  /// `mm:ss` or `h:mm:ss` → seconds.
  static int? _parseDescriptionSecs(String text) {
    final m = RegExp(r'(\d+):(\d{2})(?::(\d{2}))?').firstMatch(text);
    if (m == null) return null;
    if (m.group(3) != null) {
      return int.parse(m.group(1)!) * 3600 +
          int.parse(m.group(2)!) * 60 +
          int.parse(m.group(3)!);
    }
    return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
  }

  static String _phraseToIntensity(String? phrase) {
    final p = (phrase ?? '').toUpperCase();
    if (p.contains('SPEED') ||
        p.contains('ANAEROBIC') ||
        p.contains('SPRINT')) {
      return 'INTERVAL';
    }
    if (p.contains('BASE') || p.contains('AEROBIC')) return 'ACTIVE';
    if (p.contains('REST') || p.contains('RECOVERY')) return 'REST';
    if (p.contains('WARM')) return 'WARMUP';
    if (p.contains('COOL')) return 'COOLDOWN';
    return 'ACTIVE';
  }

  /// Steps of one workout. Tries the adaptive plan, the workout and the
  /// schedule endpoints in turn.
  Future<List<WorkoutStep>> getWorkoutSteps(
    String workoutId, {
    String? scheduleId,
    String? trainingPlanId,
    DateTime? date,
  }) async {
    final cacheKey = '$workoutId|$scheduleId';
    final cached = _stepsCache[cacheKey];
    if (cached != null) return cached;

    final paths = <String>[
      if (trainingPlanId != null && int.tryParse(trainingPlanId) != null)
        '/trainingplan-service/trainingplan/fbt-adaptive/$trainingPlanId',
      if (int.tryParse(workoutId) != null)
        '/workout-service/workout/$workoutId',
      if (scheduleId != null) '/workout-service/schedule/$scheduleId',
    ];

    for (final path in paths) {
      try {
        log('[Garmin] getWorkoutSteps: trying $path');
        final response = await _getWithRetry(path);
        final body = utf8.decode(response.bodyBytes);
        log('[Garmin] → HTTP ${response.statusCode} (${body.length} bytes)');
        if (response.statusCode != 200) continue;
        final json = jsonDecode(body) as Map<String, dynamic>;
        // ignore: avoid_print
        print(
          '[Garmin] workout body: '
          '${body.length > 500 ? body.substring(0, 500) : body}',
        );

        List<WorkoutStep> steps;
        if (path.contains('fbt-adaptive')) {
          final day = date != null ? _dateStr(date) : null;
          steps = const [];
          for (final task
              in (json['taskList'] as List? ?? const [])
                  .cast<Map<String, dynamic>>()) {
            final workout = task['taskWorkout'] as Map<String, dynamic>?;
            if (workout == null || task['restDay'] == true) continue;
            final d =
                (task['calendarDate'] ?? task['scheduledDate']) as String?;
            if (day == null || d == null || !d.startsWith(day)) continue;
            steps = _buildAdaptiveSteps(
              workout['workoutName'] as String? ?? 'Workout',
              workout['workoutDescription'] as String?,
              (workout['estimatedDurationInSecs'] as num?)?.toInt(),
              workout['workoutPhrase'] as String?,
            );
            // ignore: avoid_print
            print(
              '[Garmin] fbt-adaptive steps for $workoutId (date=$day): '
              '${steps.length}',
            );
            break;
          }
        } else {
          final workout = json['workout'] as Map<String, dynamic>? ?? json;
          steps = _extractSteps(workout);
        }
        if (_totalStepCount(steps) > 0) {
          _stepsCache[cacheKey] = steps;
          return steps;
        }
      } catch (e) {
        log('[Garmin] getWorkoutSteps ERROR ($path): $e');
      }
    }
    // ignore: avoid_print
    print(
      '[Garmin] getWorkoutSteps: no steps found for id=$workoutId '
      'scheduleId=$scheduleId',
    );
    return const [];
  }

  int _totalStepCount(List<WorkoutStep> steps) => steps.fold(
    0,
    (n, s) => n + (s.steps.isEmpty ? 1 : _totalStepCount(s.steps)),
  );

  List<WorkoutStep> _extractSteps(Map<String, dynamic> workout) {
    final segments = workout['workoutSegments'] as List?;
    if (segments != null) {
      final steps = <WorkoutStep>[];
      for (final segment in segments.cast<Map<String, dynamic>>()) {
        steps.addAll(
          (segment['workoutSteps'] as List? ?? const [])
              .cast<Map<String, dynamic>>()
              .map(WorkoutStep.fromJson),
        );
      }
      steps.sort((a, b) => a.order.compareTo(b.order));
      return steps;
    }
    final steps =
        (workout['workoutSteps'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(WorkoutStep.fromJson)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return steps;
  }
}
