import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fjelia/api/polar_flow_web_client.dart';

const _loginPage =
    '<form id="loginForm"><input type="hidden" name="csrfToken" value="tok123"/></form>';
const _events =
    '[{"type":"EXERCISE","listItemId":777,"datetime":"2026-08-19T06:30:00",'
    '"duration":3725000,"distance":5000.5,"url":"/training/analysis/777",'
    '"sport":"RUNNING"},{"type":"ACTIVITY","listItemId":1,"datetime":"2026-08-19T00:00:00",'
    '"url":"/x/1"}]';

MockClient _server({
  required bool passwordOk,
  List<String>? log,
  Future<http.Response?> Function(http.Request)? targetRequest,
}) {
  var signedIn = false;
  return MockClient((req) async {
    log?.add('${req.method} ${req.url.host}${req.url.path}');
    final u = req.url;
    if (u.host == 'flow.polar.com' && u.path == '/login') {
      return http.Response(
        _loginPage,
        200,
        headers: {'set-cookie': 'PLAY_SESSION_FLOW=abc; Path=/; HttpOnly'},
      );
    }
    if (u.host == 'flow.polar.com' && u.path == '/flowSso/login') {
      expect(u.queryParameters['csrfToken'], 'tok123');
      expect(req.headers['Cookie'], contains('timezone='));
      return http.Response(
        '',
        302,
        headers: {'location': 'https://auth.polar.com/login?client_id=flow'},
      );
    }
    if (u.host == 'auth.polar.com' &&
        u.path == '/login' &&
        req.method == 'GET') {
      return http.Response(
        '<html/>',
        200,
        headers: {
          'set-cookie':
              'XSRF-TOKEN=xs1; Path=/, JSESSIONID=j; Path=/; HttpOnly',
        },
      );
    }
    if (u.host == 'auth.polar.com' &&
        u.path == '/login' &&
        req.method == 'POST') {
      final body = req.bodyFields;
      expect(body['_csrf'], 'xs1');
      expect(req.headers['Cookie'], contains('XSRF-TOKEN=xs1'));
      if (body['password'] != 'secret' || !passwordOk) {
        return http.Response('', 302, headers: {'location': '/login?error'});
      }
      return http.Response(
        '',
        302,
        headers: {
          'location': 'https://flow.polar.com/flowSso/redirect?code=c&state=s',
        },
      );
    }
    if (u.host == 'flow.polar.com' && u.path == '/flowSso/redirect') {
      // Flow rejects this callback if the POST's form/security headers leak
      // into the redirected navigation.
      if (req.headers.containsKey('Origin') ||
          req.headers.containsKey('Content-Type') ||
          req.headers.containsKey('X-XSRF-TOKEN')) {
        return http.Response('', 403);
      }
      signedIn = true;
      return http.Response(
        '',
        302,
        headers: {
          'location': '/',
          'set-cookie': 'PLAY_SESSION_FLOW=signed; Path=/, XSRF-TOKEN=flow%2Btoken; Path=/',
        },
      );
    }
    if (u.host == 'flow.polar.com' && u.path == '/') {
      return http.Response('<html>diary</html>', 200);
    }
    if (u.path == '/training/getCalendarEvents') {
      return signedIn
          ? http.Response(_events, 200)
          : http.Response('<html>login</html>', 200);
    }
    if (u.path == '/api/export/training/tcx/777') {
      expect(u.queryParameters['compress'], 'false');
      return http.Response(
        '<TrainingCenterDatabase></TrainingCenterDatabase>',
        200,
      );
    }
    if (u.path == '/api/export/training/fit/777') {
      return http.Response.bytes([0, 128, 255, 42], 200);
    }
    if (u.path == '/api/training/analysis/777/summary') {
      return http.Response(
        '{"id":777,"trainingLoadPro":{"cardioLoadValue":84}}',
        200,
      );
    }
    final targetResponse = await targetRequest?.call(req);
    return targetResponse ?? http.Response('nope', 404);
  });
}

void main() {
  test(
    'signs in through Flow and auth.polar.com and reads the diary',
    () async {
      final log = <String>[];
      final web = PolarFlowWebClient(
        client: _server(passwordOk: true, log: log),
      );
      await web.login('me@example.com', 'secret');
      expect(web.signedIn, isTrue);
      final list = await web.workouts(DateTime(2026, 8), DateTime(2026, 8, 31));
      expect(list, hasLength(1)); // the ACTIVITY entry is not a session
      expect(list.single.id, '777');
      expect(list.single.durationSeconds, 3725);
      expect(list.single.distanceMeters, 5000.5);
      expect(list.single.start, DateTime(2026, 8, 19, 6, 30));
      expect(
        await web.exportTcx(list.single),
        contains('TrainingCenterDatabase'),
      );
      expect(await web.exportFit(list.single), [0, 128, 255, 42]);
      expect((await web.trainingSummary(list.single))['trainingLoadPro'], {
        'cardioLoadValue': 84,
      });
      expect(log.first, 'GET flow.polar.com/login');
    },
  );

  test('a wrong password is reported clearly', () async {
    final web = PolarFlowWebClient(client: _server(passwordOk: false));
    expect(
      () => web.login('me@example.com', 'wrong'),
      throwsA(
        isA<PolarFlowException>().having(
          (e) => e.message,
          'message',
          contains('Incorrect'),
        ),
      ),
    );
  });

  test('diary calls need a login first', () async {
    final web = PolarFlowWebClient(client: _server(passwordOk: true));
    expect(
      () => web.workouts(DateTime(2026, 8), DateTime(2026, 8, 31)),
      throwsA(isA<PolarFlowException>()),
    );
  });

  test('calendar parsing tolerates odd entries', () {
    expect(PolarFlowWebClient.parseCalendarEvents('[]'), isEmpty);
    expect(
      PolarFlowWebClient.parseCalendarEvents('[{"type":"EXERCISE"},5,null]'),
      isEmpty,
    );
  });

  test(
    'creates JSON targets with Flow cookies and records the returned id',
    () async {
      final calls = <http.Request>[];
      final web = PolarFlowWebClient(
        client: _server(
          passwordOk: true,
          targetRequest: (request) async {
            calls.add(request);
            expect(request.method, 'POST');
            expect(request.url.path, '/api/trainingtarget');
            expect(
              request.headers['content-type'],
              contains('application/json'),
            );
            expect(
              request.headers['cookie'],
              contains('PLAY_SESSION_FLOW=signed'),
            );
            expect(request.headers['x-xsrf-token'], 'flow+token');
            expect(request.headers['x-requested-with'], 'XMLHttpRequest');
            expect(jsonDecode(request.body)['type'], 'PHASED');
            return http.Response('123456', 201);
          },
        ),
      );
      addTearDown(web.close);
      await web.login('me@example.com', 'secret');
      expect(
        await web.createTrainingTarget({
          'type': 'PHASED',
          'datetime': '2026-10-28T18:00',
        }),
        '123456',
      );
      expect(calls, hasLength(1));
    },
  );

  test(
    'reads and updates targets; missing targets are safe to delete',
    () async {
      final calls = <String>[];
      final web = PolarFlowWebClient(
        client: _server(
          passwordOk: true,
          targetRequest: (request) async {
            calls.add('${request.method} ${request.url.path}');
            if (request.method == 'GET') {
              return http.Response(
                '{"id":123,"exerciseTargets":[{"id":456}]}',
                200,
              );
            }
            return request.method == 'DELETE'
                ? http.Response('', 404)
                : http.Response('', 204);
          },
        ),
      );
      addTearDown(web.close);
      await web.login('me@example.com', 'secret');
      expect((await web.trainingTarget('123'))!['id'], 123);
      await web.updateTrainingTarget('123', {'datetime': '2026-10-29T18:00'});
      await web.deleteTrainingTarget('123');
      expect(calls, [
        'GET /api/trainingtarget/123',
        'POST /api/trainingtarget/123',
        'DELETE /training/target/123',
      ]);
    },
  );

  test(
    'a missing target returns null and a refusal keeps its HTTP status',
    () async {
      final web = PolarFlowWebClient(
        client: _server(
          passwordOk: true,
          targetRequest: (request) async =>
              http.Response('', request.method == 'GET' ? 404 : 403),
        ),
      );
      addTearDown(web.close);
      await web.login('me@example.com', 'secret');
      expect(await web.trainingTarget('123'), isNull);
      await expectLater(
        web.createTrainingTarget({}),
        throwsA(
          isA<PolarFlowException>().having(
            (e) => e.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
    },
  );

  test(
    'a redirected POST is not followed or counted as a successful write',
    () async {
      var posts = 0;
      final web = PolarFlowWebClient(
        client: _server(
          passwordOk: true,
          targetRequest: (request) async {
            posts++;
            return http.Response(
              '',
              307,
              headers: {'location': 'https://auth.polar.com/login'},
            );
          },
        ),
      );
      addTearDown(web.close);
      await web.login('me@example.com', 'secret');
      await expectLater(
        web.createTrainingTarget({}),
        throwsA(isA<PolarFlowException>()),
      );
      expect(posts, 1);
    },
  );

  test('a login page cannot confirm an update or deletion', () async {
    final web = PolarFlowWebClient(
      client: _server(
        passwordOk: true,
        targetRequest: (_) async => http.Response('<html>Sign in</html>', 200),
      ),
    );
    addTearDown(web.close);
    await web.login('me@example.com', 'secret');
    await expectLater(
      web.trainingTarget('123'),
      throwsA(isA<PolarFlowException>()),
    );
    await expectLater(
      web.updateTrainingTarget('123', {}),
      throwsA(isA<PolarFlowException>()),
    );
    await expectLater(
      web.deleteTrainingTarget('123'),
      throwsA(isA<PolarFlowException>()),
    );
  });
}
