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

MockClient _server({required bool passwordOk, List<String>? log}) {
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
      signedIn = true;
      return http.Response(
        '',
        302,
        headers: {
          'location': '/',
          'set-cookie': 'PLAY_SESSION_FLOW=signed; Path=/',
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
    if (u.path == '/training/analysis/777/export/tcx/false') {
      return http.Response(
        '<TrainingCenterDatabase></TrainingCenterDatabase>',
        200,
      );
    }
    return http.Response('nope', 404);
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
}
