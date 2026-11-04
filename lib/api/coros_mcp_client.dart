import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../utils/log.dart';

/// Fjelia's sign-in to COROS's official MCP service (`mcp.coros.com`):
/// OAuth with PKCE and a device-style login on COROS's own page, the way
/// COROS's reference client does it. The password is only ever typed on
/// COROS's page. Tokens last 30 days and renew themselves.
class CorosMcpAuth {
  const CorosMcpAuth({
    required this.issuer,
    required this.clientId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory CorosMcpAuth.fromJson(Map<String, dynamic> json) => CorosMcpAuth(
    issuer: json['issuer'] as String,
    clientId: json['clientId'] as String,
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
  );

  final String issuer, clientId, accessToken, refreshToken;
  final DateTime expiresAt;

  bool get expired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 1)));

  Map<String, dynamic> toJson() => {
    'issuer': issuer,
    'clientId': clientId,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.millisecondsSinceEpoch,
  };
}

/// A login waiting for the athlete on COROS's page.
class CorosMcpPendingLogin {
  const CorosMcpPendingLogin({
    required this.issuer,
    required this.clientId,
    required this.verifier,
    required this.state,
    required this.authorizeUrl,
    required this.sessionId,
    required this.pollToken,
    required this.loginUrl,
    required this.interval,
  });

  final String issuer, clientId, verifier, state, authorizeUrl;
  final String sessionId, pollToken;

  /// Where the athlete signs in.
  final Uri loginUrl;
  final Duration interval;
}

class CorosMcpException implements Exception {
  const CorosMcpException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CorosMcpClient {
  CorosMcpClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  /// COROS routes `mcp.coros.com` to the account's region.
  static const issuer = 'https://mcp.coros.com';
  static const _scopes = 'openid offline_access mcp.tools';

  /// Only a name for the authorization code: it is read from the redirect
  /// the server answers with, nothing listens here.
  static const _redirect = 'http://127.0.0.1:43123/callback';
  static const _timeout = Duration(seconds: 20);

  static String _random(int bytes) {
    final r = Random.secure();
    return base64Url
        .encode(List.generate(bytes, (_) => r.nextInt(256)))
        .replaceAll('=', '');
  }

  Future<Map<String, dynamic>> _json(http.BaseResponse response) async {
    // COROS's texts hold characters like "—": always UTF-8, whatever the
    // header says.
    final body = response is http.Response
        ? utf8.decode(response.bodyBytes, allowMalformed: true)
        : utf8.decode(
            await (response as http.StreamedResponse).stream.toBytes(),
            allowMalformed: true,
          );
    if (body.isEmpty) return const {};
    final type = response.headers['content-type'] ?? '';
    if (type.contains('text/event-stream')) {
      // The last data event carries the JSON-RPC answer.
      final events = <String>[];
      final lines = <String>[];
      for (final line in body.split(RegExp(r'\r?\n'))) {
        if (line.isEmpty) {
          if (lines.isNotEmpty) events.add(lines.join('\n'));
          lines.clear();
        } else if (line.startsWith('data:')) {
          lines.add(line.substring(5).trimLeft());
        }
      }
      if (lines.isNotEmpty) events.add(lines.join('\n'));
      return events.isEmpty
          ? const {}
          : jsonDecode(events.last) as Map<String, dynamic>;
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  /// The service's actual issuer (the regional host), from its metadata.
  Future<String> _issuer() async {
    try {
      final r = await _http
          .get(Uri.parse('$issuer/.well-known/oauth-authorization-server'))
          .timeout(_timeout);
      final value = (await _json(r))['issuer'];
      if (value is String && value.startsWith('https://')) return value;
    } catch (e) {
      log('[CorosMcp] metadata: $e');
    }
    return issuer;
  }

  /// Fjelia as a client of the service, with a fresh PKCE pair.
  Future<
    ({
      String issuer,
      String clientId,
      String verifier,
      String state,
      Uri authorize,
    })
  >
  _begin() async {
    final iss = await _issuer();
    final reg = await _http
        .post(
          Uri.parse('$iss/connect/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'client_name': 'Fjelia',
            'redirect_uris': [_redirect],
            'grant_types': ['authorization_code', 'refresh_token'],
            'response_types': ['code'],
            'scope': _scopes,
            'token_endpoint_auth_method': 'none',
          }),
        )
        .timeout(_timeout);
    final clientId = (await _json(reg))['client_id'];
    if ((reg.statusCode != 200 && reg.statusCode != 201) ||
        clientId is! String) {
      throw CorosMcpException('COROS registration failed (${reg.statusCode})');
    }
    final verifier = _random(48);
    final challenge = base64Url
        .encode(sha256.convert(ascii.encode(verifier)).bytes)
        .replaceAll('=', '');
    final state = _random(24);
    final authorize = Uri.parse('$iss/oauth2/authorize').replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': _redirect,
        'scope': _scopes,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'resource': '$iss/mcp',
        'state': state,
      },
    );
    return (
      issuer: iss,
      clientId: clientId,
      verifier: verifier,
      state: state,
      authorize: authorize,
    );
  }

  /// Starts a login: Fjelia registers itself as a client and COROS hands
  /// out a page to sign in on.
  Future<CorosMcpPendingLogin> startLogin() async {
    final (
      issuer: iss,
      clientId: clientId,
      verifier: verifier,
      state: state,
      authorize: authorize,
    ) = await _begin();
    final session = await _http
        .post(
          Uri.parse('$iss/api/v1/cli/login-sessions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'clientId': clientId}),
        )
        .timeout(_timeout);
    final s = await _json(session);
    if (s['sessionId'] is! String ||
        s['pollToken'] is! String ||
        s['loginUrl'] is! String) {
      throw CorosMcpException('COROS login failed (${session.statusCode})');
    }
    return CorosMcpPendingLogin(
      issuer: iss,
      clientId: clientId,
      verifier: verifier,
      state: state,
      authorizeUrl: authorize.toString(),
      sessionId: s['sessionId'] as String,
      pollToken: s['pollToken'] as String,
      loginUrl: Uri.parse(s['loginUrl'] as String),
      interval: Duration(
        seconds: ((s['intervalSeconds'] as num?)?.toInt() ?? 3).clamp(1, 30),
      ),
    );
  }

  /// Waits until the athlete signed in on COROS's page, then trades the
  /// login for tokens. Null when [cancelled] stopped it.
  Future<CorosMcpAuth?> finishLogin(
    CorosMcpPendingLogin p, {
    Duration timeout = const Duration(minutes: 5),
    bool Function()? cancelled,
  }) async {
    final deadline = DateTime.now().add(timeout);
    String? ticket;
    while (ticket == null) {
      if (cancelled?.call() ?? false) return null;
      final r = await _http
          .post(
            Uri.parse(
              '${p.issuer}/api/v1/cli/login-sessions/${p.sessionId}/claim',
            ),
            headers: {'X-Poll-Token': p.pollToken},
          )
          .timeout(_timeout);
      final body = await _json(r);
      final status = '${body['status'] ?? ''}'.toLowerCase();
      if (status == 'authorized' && body['loginTicket'] is String) {
        ticket = body['loginTicket'] as String;
      } else if (status == 'pending') {
        if (DateTime.now().isAfter(deadline)) {
          throw const CorosMcpException('COROS login timed out');
        }
        await Future<void>.delayed(p.interval);
      } else {
        throw CorosMcpException('COROS login $status');
      }
    }
    final url = Uri.parse(p.authorizeUrl);
    final withTicket = url.replace(
      queryParameters: {...url.queryParameters, 'login_ticket': ticket},
    );
    final request = http.Request('GET', withTicket)..followRedirects = false;
    final answer = await _http.send(request).timeout(_timeout);
    await answer.stream.drain<void>();
    final location = answer.headers['location'];
    final callback = location == null ? null : Uri.tryParse(location);
    final code = callback?.queryParameters['code'];
    if (code == null || callback?.queryParameters['state'] != p.state) {
      throw const CorosMcpException('COROS did not authorize Fjelia');
    }
    return _token(p.issuer, p.clientId, {
      'grant_type': 'authorization_code',
      'client_id': p.clientId,
      'code': code,
      'redirect_uri': _redirect,
      'code_verifier': p.verifier,
    });
  }

  /// Signs in with the COROS account the athlete already gave Fjelia, the
  /// way COROS's own client does without a browser: the same COROS login
  /// form, followed redirect by redirect with its cookies.
  Future<CorosMcpAuth> passwordLogin(String email, String password) async {
    final b = await _begin();
    final cookies = <String, Map<String, String>>{};
    Future<Uri> hop(String method, Uri url, {Map<String, String>? form}) async {
      final request = http.Request(method, url)..followRedirects = false;
      final jar = cookies[url.host];
      if (jar != null && jar.isNotEmpty) {
        request.headers['Cookie'] = [
          for (final e in jar.entries) '${e.key}=${e.value}',
        ].join('; ');
      }
      if (form != null) request.bodyFields = form;
      final response = await _http.send(request).timeout(_timeout);
      await response.stream.drain<void>();
      final setCookie = response.headers['set-cookie'];
      if (setCookie != null) {
        // Several cookies arrive joined by commas; dates hold commas too.
        for (final c in setCookie.split(RegExp(r',(?=\s*[^;=\s]+=)'))) {
          final pair = c.split(';').first.trim();
          final eq = pair.indexOf('=');
          if (eq > 0) {
            (cookies[url.host] ??= {})[pair.substring(0, eq)] = pair.substring(
              eq + 1,
            );
          }
        }
      }
      final location = response.headers['location'];
      if ((response.statusCode != 302 && response.statusCode != 303) ||
          location == null) {
        throw CorosMcpException(
          'COROS sign-in stopped at ${url.path} (${response.statusCode})',
        );
      }
      return url.resolve(location);
    }

    final corosLogin = await hop('GET', b.authorize);
    final q = corosLogin.queryParameters;
    final callback = await hop(
      'POST',
      corosLogin,
      form: {
        'client_id': q['client_id'] ?? '',
        'redirect_uri': q['redirect_uri'] ?? '',
        'state': q['state'] ?? '',
        'scope': q['scope'] ?? '',
        'response_type': q['response_type'] ?? 'code',
        'activityType': '',
        'language': 'zh',
        'country': 'CN',
        'userName': email,
        'password': password,
        'checkStatus': '1',
        'getAllHistoryIn24Hours': '0',
      },
    );
    final resume = await hop('GET', callback);
    final done = await hop('GET', resume);
    final code = done.queryParameters['code'];
    if (code == null || done.queryParameters['state'] != b.state) {
      throw const CorosMcpException('COROS did not authorize Fjelia');
    }
    return _token(b.issuer, b.clientId, {
      'grant_type': 'authorization_code',
      'client_id': b.clientId,
      'code': code,
      'redirect_uri': _redirect,
      'code_verifier': b.verifier,
    });
  }

  Future<CorosMcpAuth> _token(
    String iss,
    String clientId,
    Map<String, String> form, {
    String? previousRefresh,
  }) async {
    final r = await _http
        .post(Uri.parse('$iss/oauth2/token'), body: form)
        .timeout(_timeout);
    final t = await _json(r);
    if (r.statusCode != 200 || t['access_token'] is! String) {
      throw CorosMcpException('COROS token refused (${r.statusCode})');
    }
    return CorosMcpAuth(
      issuer: iss,
      clientId: clientId,
      accessToken: t['access_token'] as String,
      refreshToken: (t['refresh_token'] as String?) ?? previousRefresh ?? '',
      expiresAt: DateTime.now().add(
        Duration(seconds: (t['expires_in'] as num?)?.toInt() ?? 3600),
      ),
    );
  }

  /// A fresh token for [auth]; COROS issues a new refresh token each time.
  Future<CorosMcpAuth> refresh(CorosMcpAuth auth) =>
      _token(auth.issuer, auth.clientId, {
        'grant_type': 'refresh_token',
        'client_id': auth.clientId,
        'refresh_token': auth.refreshToken,
      }, previousRefresh: auth.refreshToken);

  Future<Map<String, dynamic>> _rpc(
    CorosMcpAuth auth,
    int id,
    String method,
    Map<String, dynamic> params,
  ) async {
    final r = await _http
        .post(
          Uri.parse('${auth.issuer}/mcp'),
          headers: {
            'Authorization': 'Bearer ${auth.accessToken}',
            'Accept': 'application/json, text/event-stream',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': id,
            'method': method,
            'params': params,
          }),
        )
        .timeout(const Duration(seconds: 45));
    if (r.statusCode == 401) {
      throw const CorosMcpException('COROS access expired');
    }
    final body = await _json(r);
    if (r.statusCode != 200 || body['error'] != null) {
      throw CorosMcpException('COROS $method failed (${r.statusCode})');
    }
    return body;
  }

  /// Calls one tool; its answer is text, as COROS writes it.
  Future<String> callTool(
    CorosMcpAuth auth,
    String tool,
    Map<String, Object> arguments,
  ) async {
    final body = await _rpc(auth, 2, 'tools/call', {
      'name': tool,
      'arguments': arguments,
    });
    final content = (body['result'] as Map?)?['content'];
    return [
      for (final c in (content as List? ?? const []))
        if (c is Map && c['text'] is String) _unquote(c['text'] as String),
    ].join('\n');
  }

  /// COROS sends the text as a JSON string inside the text field.
  static String _unquote(String text) {
    final t = text.trim();
    if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) {
      try {
        final decoded = jsonDecode(t);
        if (decoded is String) return decoded;
      } catch (_) {}
    }
    return text;
  }

  /// Opens the MCP session; COROS works stateless, once per sync is enough.
  Future<void> initialize(CorosMcpAuth auth) => _rpc(auth, 1, 'initialize', {
    'protocolVersion': '2025-06-18',
    'capabilities': const <String, Object>{},
    'clientInfo': {'name': 'Fjelia', 'version': '1.0'},
  });

  void close() => _http.close();
}
