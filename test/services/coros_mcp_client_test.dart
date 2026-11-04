import 'dart:convert';

import 'package:fjelia/api/coros_mcp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'device login: register, wait for the sign-in, trade for tokens',
    () async {
      var claims = 0;
      late String state;
      final client = CorosMcpClient(
        client: MockClient((req) async {
          final path = req.url.path;
          if (path == '/.well-known/oauth-authorization-server') {
            return http.Response(
              jsonEncode({'issuer': 'https://mcpeu.coros.com'}),
              200,
            );
          }
          if (path == '/connect/register') {
            expect(jsonDecode(req.body)['token_endpoint_auth_method'], 'none');
            return http.Response(jsonEncode({'client_id': 'fj-1'}), 201);
          }
          if (path == '/api/v1/cli/login-sessions') {
            return http.Response(
              jsonEncode({
                'sessionId': 's1',
                'pollToken': 'p1',
                'loginUrl': 'https://mcpeu.coros.com/login/s1',
                'expiresAt': 'x',
                'intervalSeconds': 1,
              }),
              200,
            );
          }
          if (path == '/api/v1/cli/login-sessions/s1/claim') {
            expect(req.headers['X-Poll-Token'], 'p1');
            claims++;
            return http.Response(
              jsonEncode(
                claims < 2
                    ? {'status': 'pending'}
                    : {'status': 'authorized', 'loginTicket': 't1'},
              ),
              200,
            );
          }
          if (path == '/oauth2/authorize') {
            expect(req.url.queryParameters['login_ticket'], 't1');
            expect(req.url.queryParameters['code_challenge_method'], 'S256');
            state = req.url.queryParameters['state']!;
            return http.Response(
              '',
              302,
              headers: {
                'location':
                    'http://127.0.0.1:43123/callback?code=c1&state=$state',
              },
            );
          }
          if (path == '/oauth2/token') {
            expect(req.bodyFields['grant_type'], 'authorization_code');
            expect(req.bodyFields['code'], 'c1');
            expect(req.bodyFields['code_verifier'], isNotEmpty);
            return http.Response(
              jsonEncode({
                'access_token': 'a1',
                'refresh_token': 'r1',
                'expires_in': 2592000,
              }),
              200,
            );
          }
          return http.Response('not found $path', 404);
        }),
      );
      final pending = await client.startLogin();
      expect(pending.loginUrl.toString(), 'https://mcpeu.coros.com/login/s1');
      final auth = (await client.finishLogin(pending))!;
      expect(claims, 2);
      expect(auth.accessToken, 'a1');
      expect(auth.refreshToken, 'r1');
      expect(auth.issuer, 'https://mcpeu.coros.com');
      expect(auth.expired, isFalse);
    },
  );

  test('a tool answer comes as text, also inside an event stream', () async {
    final client = CorosMcpClient(
      client: MockClient((req) async {
        expect(req.headers['Authorization'], 'Bearer a1');
        final answer = {
          'jsonrpc': '2.0',
          'id': 2,
          'result': {
            'content': [
              {
                'type': 'text',
                'text': jsonEncode(
                  'Sleep Overview\n\n2026-11-04\nSleep Score: 91',
                ),
              },
            ],
          },
        };
        return http.Response(
          'event: message\ndata: ${jsonEncode(answer)}\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      }),
    );
    final auth = CorosMcpAuth(
      issuer: 'https://mcpeu.coros.com',
      clientId: 'fj-1',
      accessToken: 'a1',
      refreshToken: 'r1',
      expiresAt: DateTime.now().add(const Duration(days: 1)),
    );
    expect(
      await client.callTool(auth, 'querySleepOverview', {'days': 1}),
      'Sleep Overview\n\n2026-11-04\nSleep Score: 91',
    );
  });
}
