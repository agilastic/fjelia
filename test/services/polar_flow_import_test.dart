import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fjelia/api/polar_flow_web_client.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/polar_service.dart';

const _tcx = '''<TrainingCenterDatabase><Activities><Activity Sport="Running">
<Id>2026-08-19T06:30:00.000Z</Id><Lap StartTime="2026-08-19T06:30:00.000Z">
<TotalTimeSeconds>3725</TotalTimeSeconds><DistanceMeters>10200</DistanceMeters>
<AverageHeartRateBpm><Value>150</Value></AverageHeartRateBpm>
<MaximumHeartRateBpm><Value>171</Value></MaximumHeartRateBpm>
<Track><Trackpoint><Time>2026-08-19T06:30:01.000Z</Time>
<HeartRateBpm><Value>140</Value></HeartRateBpm></Trackpoint></Track>
</Lap></Activity></Activities></TrainingCenterDatabase>''';

const _events =
    '[{"type":"EXERCISE","listItemId":777,"datetime":"2026-08-19T06:30:00",'
    '"duration":3725000,"url":"/training/analysis/777","sport":"RUNNING"},'
    '{"type":"EXERCISE","listItemId":778,"datetime":"2026-08-17T07:00:00",'
    '"duration":6000,"url":"/training/analysis/778"}]';

MockClient _flow() => MockClient((req) async {
  final u = req.url;
  if (u.path == '/login' && u.host == 'flow.polar.com') {
    return http.Response(
      '<input name="csrfToken" value="t"/>',
      200,
      headers: {'set-cookie': 'PLAY_SESSION_FLOW=a; Path=/'},
    );
  }
  if (u.path == '/flowSso/login') {
    return http.Response('', 302, headers: {
      'location': 'https://auth.polar.com/login?x=1',
    });
  }
  if (u.host == 'auth.polar.com' && req.method == 'GET') {
    return http.Response('', 200, headers: {'set-cookie': 'XSRF-TOKEN=x; Path=/'});
  }
  if (u.host == 'auth.polar.com' && req.method == 'POST') {
    return http.Response('', 302, headers: {
      'location': 'https://flow.polar.com/flowSso/redirect?code=c',
    });
  }
  if (u.path == '/flowSso/redirect') {
    return http.Response('', 302, headers: {'location': '/'});
  }
  if (u.path == '/') return http.Response('ok', 200);
  if (u.path == '/training/getCalendarEvents') {
    return http.Response(
      u.queryParameters['start']!.endsWith('.08.2026') ||
              u.queryParameters['start']!.startsWith('01.08')
          ? _events
          : '[]',
      200,
    );
  }
  if (u.path.endsWith('/export/tcx/false')) return http.Response(_tcx, 200);
  return http.Response('', 404);
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('imports sessions older than the API window once', () async {
    final service = PolarService(db);
    expect(await service.hasFlowLogin, isFalse);
    expect(await service.importFlowHistory(days: 3000, client: PolarFlowWebClient(client: _flow())), 0);

    await service.saveFlowLogin('me@example.com', 'pw', client: PolarFlowWebClient(client: _flow()));
    expect(await service.hasFlowLogin, isTrue);
    expect(await service.flowLoginEmail, 'me@example.com');

    final saved = await service.importFlowHistory(days: 3000, client: PolarFlowWebClient(client: _flow()));
    expect(saved, greaterThanOrEqualTo(1));
    final rows = await db.getActivitiesInRange(3100);
    final run = rows.singleWhere((a) => a.activityId == 'polar_flow_777');
    expect(run.type, 'running');
    expect(run.source, 'polar');
    expect(run.durationSeconds, 3725);
    expect(run.distanceMeters, 10200);
    expect(run.avgHeartRate, 150);
    // The 6-second recording is noise and is skipped.
    expect(rows.where((a) => a.activityId == 'polar_flow_778'), isEmpty);

    // A second run does not duplicate anything.
    await service.importFlowHistory(days: 3000, client: PolarFlowWebClient(client: _flow()));
    expect(
      (await db.getActivitiesInRange(3100)).where(
        (a) => a.activityId == 'polar_flow_777',
      ),
      hasLength(1),
    );

    await service.clearFlowLogin();
    expect(await service.hasFlowLogin, isFalse);
  });

  test('a rejected login is not stored', () async {
    final service = PolarService(db);
    final failing = MockClient((req) async => http.Response('', 500));
    expect(
      () => service.saveFlowLogin('a@b.c', 'x', client: PolarFlowWebClient(client: failing)),
      throwsA(isA<PolarFlowException>()),
    );
    expect(await service.hasFlowLogin, isFalse);
  });
}
