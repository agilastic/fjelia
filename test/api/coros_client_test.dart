import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fjelia/api/coros_client.dart';

const _ok = '0000';

int _now() => DateTime.now().millisecondsSinceEpoch;

/// A client whose in-memory session is preset (no network login needed) and
/// wired to [mock].
CorosClient _signedIn(MockClient mock, {String? mobileToken}) {
  final client = CorosClient(client: mock);
  client.adopt(
    CorosAuth(
      accessToken: 'tok',
      userId: '478387947656200192',
      region: 'eu',
      timestampMs: _now(),
      email: 'me@example.com',
      mobileToken: mobileToken,
    ),
  );
  return client;
}

void main() {
  test('login stores the session on a 0000 answer', () async {
    final client = CorosClient(
      client: MockClient((req) async {
        expect(req.url.host, 'teameuapi.coros.com');
        expect(req.url.path, '/account/login');
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['account'], 'me@example.com');
        expect(body['accountType'], 2);
        expect(body['pwd'], isNotEmpty);
        return http.Response(
          jsonEncode({
            'result': _ok,
            'data': {'accessToken': 'tok', 'userId': 478387947656200192},
          }),
          200,
        );
      }),
    );
    await client.login('me@example.com', 'pw');
    expect(client.signedIn, isTrue);
    expect(client.auth?.userId, '478387947656200192');
    expect(client.tokenExpired, isFalse);
  });

  test('a rejected login throws a CorosException', () async {
    final client = CorosClient(
      client: MockClient(
        (req) async => http.Response(
          jsonEncode({'result': '1001', 'message': 'bad credentials'}),
          200,
        ),
      ),
    );
    expect(
      () => client.login('me@example.com', 'nope'),
      throwsA(
        isA<CorosException>().having(
          (e) => e.message,
          'message',
          contains('1001'),
        ),
      ),
    );
  });

  test('an uppercase region still resolves to the Europe base', () async {
    String? host;
    final client = CorosClient(
      client: MockClient((req) async {
        host = req.url.host;
        return http.Response(
          jsonEncode({'result': _ok, 'data': {'accessToken': 't', 'userId': 1}}),
          200,
        );
      }),
    );
    await client.login('me@example.com', 'pw', region: 'EU');
    expect(host, 'teameuapi.coros.com');
  });

  test('activities streams rows and stops after one page', () async {
    final client = _signedIn(
      MockClient(
        (req) async {
          expect(req.url.host, 'teameuapi.coros.com');
          expect(req.url.path, '/activity/query');
          return http.Response(
            jsonEncode({
              'result': _ok,
              'data': {
                'totalPage': 1,
                'pageNumber': 1,
                'count': 2,
                'dataList': [
                  {'labelId': 'a', 'startTime': 1700000000},
                  {'labelId': 'b', 'startTime': 1700000001},
                ],
              },
            }),
            200,
          );
        },
      ),
    );
    final rows = <Map<String, dynamic>>[];
    await client.activities(
      from: DateTime(2026, 10, 1),
      to: DateTime(2026, 10, 8),
      onRow: (row) async => rows.add(row),
    );
    expect(rows, hasLength(2));
    expect(rows.map((r) => r['labelId']), ['a', 'b']);
  });

  test('a stale token on the activity list is an auth error', () async {
    final client = _signedIn(
      MockClient(
        (req) async => http.Response(
          jsonEncode({'result': '1019', 'message': 'Access token is invalid'}),
          200,
        ),
      ),
    );
    expect(
      () => client.activities(onRow: (_) async {}),
      throwsA(isA<CorosAuthException>()),
    );
  });

  test('daily metrics merges the three web-token endpoints', () async {
    final client = _signedIn(
      MockClient((req) async {
        final u = req.url;
        if (u.path == '/analyse/dayDetail/query') {
          return http.Response(
            jsonEncode({
              'result': _ok,
              'data': {
                'dayList': [
                  {'happenDay': '20261001', 'rhr': 55, 'stepCount': 8000},
                ],
              },
            }),
            200,
          );
        }
        if (u.path == '/dashboard/query') {
          return http.Response(
            jsonEncode({
              'result': _ok,
              'data': {
                'summaryInfo': {
                  'sleepHrvData': {
                    'sleepHrvList': [
                      {'happenDay': '20261001', 'avgSleepHrv': 42},
                    ],
                  },
                },
              },
            }),
            200,
          );
        }
        if (u.path == '/analyse/query') {
          // A non-auth, non-0000 source: merged? No — only 0000 is merged.
          return http.Response(
            jsonEncode({
              'result': '1002',
              'data': {
                't7dayList': [
                  {'happenDay': '20261001', 'SHOULD_NOT_MERGE': true},
                ],
              },
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      }),
    );
    final byDay = await client.dailyMetrics(
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 1),
    );
    expect(byDay.keys, ['20261001']);
    final day = byDay['20261001']!;
    expect(day['rhr'], 55);
    expect(day['stepCount'], 8000);
    expect(day['avgSleepHrv'], 42);
    expect(day.containsKey('SHOULD_NOT_MERGE'), isFalse);
  });

  test('a stale web token on daily metrics is an auth error', () async {
    final client = _signedIn(
      MockClient(
        (req) async => http.Response(
          jsonEncode({'result': '1011', 'message': 'expired'}),
          200,
        ),
      ),
    );
    expect(
      () => client.dailyMetrics(DateTime(2026, 10, 1), DateTime(2026, 10, 8)),
      throwsA(isA<CorosAuthException>()),
    );
  });

  test('sleep returns empty when there is no mobile token', () async {
    var called = false;
    final client = _signedIn(
      MockClient(
        (req) async {
          called = true;
          return http.Response('{}', 200);
        },
      ),
    );
    final days = await client.sleep(
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 8),
    );
    expect(days, isEmpty);
    expect(called, isFalse); // no mobile token → no network call at all
  });

  test('a stale mobile token is skipped, not a web auth error', () async {
    // Carries a mobile token, so the endpoint is hit; a stale mobile token
    // must be skipped quietly (it must not trigger a web re-login).
    final client = _signedIn(
      MockClient(
        (req) async {
          expect(req.url.host, 'apieu.coros.com');
          expect(req.url.path, '/coros/data/statistic/daily');
          return http.Response(
            jsonEncode({'result': '1019', 'message': 'expired'}),
            200,
          );
        },
      ),
      mobileToken: 'mobiletok',
    );
    final days = await client.sleep(
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 8),
    );
    expect(days, isEmpty); // skipped, and no exception thrown
  });
}
