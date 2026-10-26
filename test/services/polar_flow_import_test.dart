import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fjelia/api/polar_flow_web_client.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/polar_service.dart';

import '../support/polar_fit_fixture.dart';

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

MockClient _flow({
  String tcx = _tcx,
  Uint8List? fit,
  Map<String, dynamic>? summary,
  List<String>? exports,
}) => MockClient((req) async {
  final u = req.url;
  if (u.path == '/login' && u.host == 'flow.polar.com') {
    return http.Response(
      '<input name="csrfToken" value="t"/>',
      200,
      headers: {'set-cookie': 'PLAY_SESSION_FLOW=a; Path=/'},
    );
  }
  if (u.path == '/flowSso/login') {
    return http.Response(
      '',
      302,
      headers: {'location': 'https://auth.polar.com/login?x=1'},
    );
  }
  if (u.host == 'auth.polar.com' && req.method == 'GET') {
    return http.Response(
      '',
      200,
      headers: {'set-cookie': 'XSRF-TOKEN=x; Path=/'},
    );
  }
  if (u.host == 'auth.polar.com' && req.method == 'POST') {
    return http.Response(
      '',
      302,
      headers: {'location': 'https://flow.polar.com/flowSso/redirect?code=c'},
    );
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
  if (u.path.startsWith('/api/export/training/tcx/')) {
    exports?.add(u.path);
    return http.Response(tcx, 200);
  }
  if (u.path.startsWith('/api/export/training/fit/') && fit != null) {
    return http.Response.bytes(fit, 200);
  }
  if (u.path.endsWith('/summary') && summary != null) {
    return http.Response(jsonEncode(summary), 200);
  }
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
    expect(
      await service.importFlowHistory(
        days: 3000,
        client: PolarFlowWebClient(client: _flow()),
      ),
      0,
    );

    await service.saveFlowLogin(
      'me@example.com',
      'pw',
      client: PolarFlowWebClient(client: _flow()),
    );
    expect(await service.hasFlowLogin, isTrue);
    expect(await service.flowLoginEmail, 'me@example.com');

    final saved = await service.importFlowHistory(
      days: 3000,
      client: PolarFlowWebClient(client: _flow()),
    );
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
    await service.importFlowHistory(
      days: 3000,
      client: PolarFlowWebClient(client: _flow()),
    );
    expect(
      (await db.getActivitiesInRange(3100))
          .where((a) => a.activityId == 'polar_flow_777'),
      hasLength(1),
    );

    await service.clearFlowLogin();
    expect(await service.hasFlowLogin, isFalse);
  });

  test('a rejected login is not stored', () async {
    final service = PolarService(db);
    final failing = MockClient((req) async => http.Response('', 500));
    expect(
      () => service.saveFlowLogin(
        'a@b.c',
        'x',
        client: PolarFlowWebClient(client: failing),
      ),
      throwsA(isA<PolarFlowException>()),
    );
    expect(await service.hasFlowLogin, isFalse);
  });

  test('fills old Flow rows and retains their workout associations', () async {
    final service = PolarService(db);
    await service.saveFlowLogin(
      'me@example.com',
      'pw',
      client: PolarFlowWebClient(client: _flow()),
    );
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'polar_flow_777',
            name: 'Polar running',
            type: 'running',
            startDate: DateTime.utc(2026, 8, 19, 6, 30),
            durationSeconds: 3725,
            source: const Value('polar'),
            plannedWorkoutName: const Value('My planned run'),
          ),
        );
    final exports = <String>[];
    final summary = <String, dynamic>{
      'id': 777,
      'trainingLoadPro': {
        'valid': true,
        'cardioLoadValue': 84.3,
        'muscleLoadValue': 1051,
      },
      'exercises': {
        '1': {
          'duration': 'PT1H2M5S',
          'ascent': 21.5,
          'trainingStatistic': {
            'POWER': {'avg': 250},
            'CADENCE': {'avg': 79},
          },
        },
      },
    };
    final count = await service.importFlowHistory(
      days: 3000,
      client: PolarFlowWebClient(
        client: _flow(summary: summary, exports: exports),
      ),
    );
    expect(count, 1);
    final row = (await db.getActivityById('polar_flow_777'))!;
    expect(row.totalElevation, 21.5);
    expect(row.avgWatts, 250);
    expect(row.avgRunCadence, 79);
    expect(row.trainingLoad, 84.3);
    expect(row.plannedWorkoutName, 'My planned run');
    expect(jsonDecode(row.metricsJson!) as List, isNotEmpty);
    expect(row.movingDurationSeconds, isNull); // timer time is not moving time
    expect(exports, hasLength(1));

    await service.importFlowHistory(
      days: 3000,
      client: PolarFlowWebClient(
        client: _flow(summary: summary, exports: exports),
      ),
    );
    expect(exports, hasLength(1)); // complete history is not downloaded again
  });

  test(
    'Flow FIT supplies ascent, watts and independently reported moving time',
    () async {
      final service = PolarService(db);
      await service.saveFlowLogin(
        'me@example.com',
        'pw',
        client: PolarFlowWebClient(client: _flow()),
      );
      final tcx = _tcx
          .replaceAll('2026-08-19T06:30:', '2026-10-25T14:28:')
          .replaceFirst('3725', '3645');
      await service.importFlowHistory(
        days: 3000,
        client: PolarFlowWebClient(
          client: _flow(tcx: tcx, fit: polarFitFixture()),
        ),
      );
      final row = (await db.getActivityById('polar_flow_777'))!;
      expect(row.durationSeconds, 3645);
      expect(row.totalElevation, 20);
      expect(row.avgWatts, 289);
      expect(row.movingDurationSeconds, 3600);
      expect((jsonDecode(row.metricsJson!) as List).first['spd'], 2.5);
    },
  );

  test('a corrupt optional FIT does not discard the TCX session', () async {
    final service = PolarService(db);
    await service.saveFlowLogin(
      'me@example.com',
      'pw',
      client: PolarFlowWebClient(client: _flow()),
    );
    final count = await service.importFlowHistory(
      days: 3000,
      client: PolarFlowWebClient(
        client: _flow(fit: Uint8List.fromList([1, 2, 3])),
      ),
    );
    expect(count, 1);
    final row = (await db.getActivityById('polar_flow_777'))!;
    expect(row.avgHeartRate, 150);
    expect(row.totalElevation, isNull);
    expect(row.movingDurationSeconds, isNull);
  });

  test('FIT from another recording cannot enrich a Flow session', () async {
    final service = PolarService(db);
    await service.saveFlowLogin(
      'me@example.com',
      'pw',
      client: PolarFlowWebClient(client: _flow()),
    );
    await service.importFlowHistory(
      days: 3000,
      client: PolarFlowWebClient(client: _flow(fit: polarFitFixture())),
    );
    final row = (await db.getActivityById('polar_flow_777'))!;
    expect(row.totalElevation, isNull);
    expect(row.avgWatts, isNull);
    expect(row.movingDurationSeconds, isNull);
  });
}
