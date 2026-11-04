import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/providers/day_data_provider.dart' show sleepFromRecord;
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/coros_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _answers = {
  'querySleepOverview':
      'Sleep Overview\n\n2026-11-04\nSleep Score: 91\nMain Sleep (asleep): 6h 27min\n'
      'Main Sleep Period (incl. awake): 6h 37min\nAwake Time: 10 min\n'
      'Main Sleep Window: 2026-11-04 00:08 - 2026-11-04 06:45',
  'queryDailyHealthData':
      'Daily Health Data\n\n--- 20261104 ---\nSteps: 192\nStress: Avg 9\nSleep Summary:\n'
      '  Total: 6h 37min | Deep: 1h 54min | Light: 3h 0min | REM: 1h 33min | Awake: 10 min\n'
      '  Sleep HR: Avg 49 bpm | Min 40 bpm | Max 77 bpm',
  'querySleepHrv':
      'HRV Assessment\n\n2026-11-04:\n  HRV Avg: 34 ms\n\n'
      'Sleep HRV Time Series — Last 1 days\n\n2026-11-04:\n'
      '  timestamp=1793747690, timezone=4, hrv=25 ms, status=4\n'
      '  timestamp=1793748290, timezone=4, hrv=37 ms, status=4',
  'queryStressTimeSeries':
      '2026-11-04:\n  timestamp=1793747690, timezone=4, stress=12, score=1\n'
      '  timestamp=1793747990, timezone=4, stress=9, score=1\n'
      '  timestamp=1793800000, timezone=4, stress=40, score=2',
  'queryRestingHeartRate': '2026-11-04: 48 bpm',
  'queryStressLevel': '2026-11-04:\nAverage Stress: 9',
  'queryHealthCheckTimeSeries':
      'Health Check Time Series — Latest in last 7 days\n'
      '========================\n\nDate: 2026-11-04\n'
      'timestamp=1793781086, timezone=4, source=dailyRhmList, '
      'device=COROS PACE 4, dataSource=COROS PACE 4\n'
      'Heart Rate List: [1793781086=63 bpm]\nHRV List: [1793781086=56 ms]\n'
      'Stress List: [1793781086=28]\n'
      'Respiration Rate List: [1793781086=16/min]\n'
      'SpO2 List: [1793781086=98%]\nStress Level: 2\n'
      'Resting Heart Rate: 48 bpm',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the official access alone brings the night and the day', () async {
    FlutterSecureStorage.setMockInitialValues({
      'coros_mcp_auth_v1': jsonEncode({
        'issuer': 'https://mcpeu.coros.com',
        'clientId': 'fj-1',
        'accessToken': 'a1',
        'refreshToken': 'r1',
        'expiresAt': DateTime.now()
            .add(const Duration(days: 20))
            .millisecondsSinceEpoch,
      }),
    });
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final coros = CorosService(
      db,
      client: MockClient((req) async {
        final rpc = jsonDecode(req.body) as Map<String, dynamic>;
        if (rpc['method'] == 'initialize') {
          return http.Response(
            jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': {}}),
            200,
          );
        }
        final name = (rpc['params'] as Map)['name'] as String;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 2,
              'result': {
                'content': [
                  {'type': 'text', 'text': jsonEncode(_answers[name] ?? '')},
                ],
              },
            }),
          ),
          200,
        );
      }),
    );
    expect(await coros.isConnected, isFalse);
    expect(await coros.healthConnected, isTrue);
    final r = await coros.sync(days: 7);
    expect(r.sleep, 1);

    final night = (await db.getSleepForDate(DateTime(2026, 11, 4)))!;
    expect(night.totalSleepSeconds, 387 * 60);
    expect(night.deepSleepSeconds, 114 * 60);
    expect(night.lightSleepSeconds, 180 * 60);
    expect(night.remSleepSeconds, 93 * 60);
    expect(night.awakeSleepSeconds, 10 * 60);
    expect(night.sleepScore, 91);
    expect(night.sleepStart, DateTime(2026, 11, 4, 0, 8));
    expect(night.sleepEnd, DateTime(2026, 11, 4, 6, 45));

    // The curves of the night; the stress point long after waking is not.
    final curves = jsonDecode(night.nightCurvesJson!) as Map<String, dynamic>;
    expect((curves['hrv'] as List).length, 2);
    expect([for (final p in curves['stress'] as List) p[1]], [12, 9]);

    final day = (await db.getHrvForDate(DateTime(2026, 11, 4)))!;
    expect(day.hrvLastNight, 34);
    expect(day.restingHeartRate, 48);
    expect(day.stressLevel, 9);
    // From the wellness check; its HRV and stress do not replace the
    // night's and the day's.
    expect(day.spo2, 98);
    expect(day.respirationRate, 16);
    expect(day.hrvLastNight, 34);
    // Its HRV is a resting HRV reading, saved once however often it syncs.
    await coros.sync(days: 7);
    final resting = await db.select(db.spotHrvMeasurements).get();
    expect(resting, hasLength(1));
    expect(resting.single.context, 'resting');
    expect(resting.single.rmssdMs, 56);
    expect(resting.single.meanHr, 63);
    expect(resting.single.deviceName, 'COROS PACE 4');
    expect(
      resting.single.startedAt,
      DateTime.fromMillisecondsSinceEpoch(1793781086 * 1000),
    );
  });

  test(
    'one COROS sign-in: the stored account connects the access by itself',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'coros_auth_v1': jsonEncode({
          'accessToken': 'web',
          'userId': '42',
          'region': 'eu',
          'timestampMs': DateTime.now().millisecondsSinceEpoch,
          'email': 'me@example.com',
        }),
        'coros_password': 'secret',
        'coros_region': 'eu',
      });
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      late String state;
      var cookieSeen = false;
      const iss = 'https://mcpeu.coros.com';
      final coros = CorosService(
        db,
        client: MockClient((req) async {
          final u = req.url;
          if (u.host == 'mcpeu.coros.com' || u.host == 'mcp.coros.com') {
            switch (u.path) {
              case '/.well-known/oauth-authorization-server':
                return http.Response(jsonEncode({'issuer': iss}), 200);
              case '/connect/register':
                return http.Response(jsonEncode({'client_id': 'fj'}), 201);
              case '/oauth2/authorize' when u.queryParameters['resume'] == null:
                state = u.queryParameters['state']!;
                return http.Response(
                  '',
                  302,
                  headers: {
                    'location': 'https://openeu.coros.com/login?client_id=c&redirect_uri=r&state=x&scope=s',
                    'set-cookie': 'SESSION=abc; Path=/; HttpOnly',
                  },
                );
              case '/callback':
                cookieSeen = req.headers['Cookie'] == 'SESSION=abc';
                return http.Response(
                  '',
                  302,
                  headers: {'location': '/oauth2/authorize?resume=1'},
                );
              case '/oauth2/authorize':
                return http.Response(
                  '',
                  302,
                  headers: {
                    'location':
                        'http://127.0.0.1:43123/callback?code=c9&state=$state',
                  },
                );
              case '/oauth2/token':
                expect(req.bodyFields['code'], 'c9');
                return http.Response(
                  jsonEncode({
                    'access_token': 'a',
                    'refresh_token': 'r',
                    'expires_in': 3600,
                  }),
                  200,
                );
              case '/mcp':
                final rpc = jsonDecode(req.body) as Map<String, dynamic>;
                final name = (rpc['params'] as Map)['name'];
                return http.Response(
                  jsonEncode({
                    'jsonrpc': '2.0',
                    'id': rpc['id'],
                    'result': {
                      'content': [
                        {
                          'type': 'text',
                          'text': jsonEncode(_answers[name] ?? ''),
                        },
                      ],
                    },
                  }),
                  200,
                );
            }
          }
          if (u.host == 'openeu.coros.com' && req.method == 'POST') {
            expect(req.bodyFields['userName'], 'me@example.com');
            expect(req.bodyFields['password'], 'secret');
            return http.Response(
              '',
              302,
              headers: {'location': '$iss/callback?ticket=t'},
            );
          }
          // Training Hub: nothing new today.
          return http.Response(jsonEncode({'result': '0000', 'data': {}}), 200);
        }),
      );
      expect(await coros.healthConnected, isFalse);
      final r = await coros.sync(days: 7);
      expect(cookieSeen, isTrue);
      expect(await coros.healthConnected, isTrue);
      expect(r.sleep, 1);
      expect((await db.getSleepForDate(DateTime(2026, 11, 4)))!.sleepScore, 91);
    },
  );

  test('a Garmin night keeps its phase timeline when COROS writes the same night', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    const phases =
        '[{"s":"2026-11-04T00:14:00Z","e":"2026-11-04T00:23:00Z","p":"light"}]';
    await db.upsertSleep(
      SleepRecordsCompanion(
        date: Value(DateTime(2026, 11, 4)),
        totalSleepSeconds: const Value(386 * 60),
        deepSleepSeconds: const Value(130 * 60),
        lightSleepSeconds: const Value(192 * 60),
        remSleepSeconds: const Value(64 * 60),
        awakeSleepSeconds: const Value(14 * 60),
        phasesJson: const Value(phases),
        source: const Value('garmin_api'),
      ),
    );
    await db.upsertSleep(
      SleepRecordsCompanion(
        date: Value(DateTime(2026, 11, 4)),
        totalSleepSeconds: const Value(387 * 60),
        deepSleepSeconds: const Value(114 * 60),
        lightSleepSeconds: const Value(180 * 60),
        remSleepSeconds: const Value(93 * 60),
        awakeSleepSeconds: const Value(10 * 60),
        nightCurvesJson: const Value('{"hrv":[[1,25],[2,37]],"stress":[]}'),
        source: const Value('coros'),
      ),
    );
    final r = (await db.getSleepForDate(DateTime(2026, 11, 4)))!;
    // Garmin ranks before COROS: its night and timeline stay as they were.
    expect(r.phasesJson, phases);
    expect(r.totalSleepSeconds, 386 * 60);
    expect(r.deepSleepSeconds, 130 * 60);
    expect(r.remSleepSeconds, 64 * 60);
    // And the sleep sheet shows the timeline, not the COROS curves.
    final sleep = sleepFromRecord(r);
    expect(sleep.phases, isNotEmpty);
    expect(sleep.phasesEstimated, isFalse);
  });
}
