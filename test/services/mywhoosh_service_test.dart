import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fjelia/api/mywhoosh_client.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/mywhoosh_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/coros_fit_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late List<http.Request> requests;
  late bool tokenValid;
  late bool withFile;
  // The FIT fixture starts at this time and lasts 120 s.
  final start = DateTime.utc(2026, 11, 3, 17, 44);

  Map<String, dynamic> ride() => {
    'id': 'R1',
    'title': 'Tempo Ride',
    'date': start.millisecondsSinceEpoch / 1000,
    if (withFile) 'activityFileId': 'F1',
    'distance': 1.2,
    'rideDuration': '00:02:00.000',
    'watt': 180,
    'heartrate': 91,
  };

  MyWhooshService service() => MyWhooshService(
    db,
    client: MockClient((req) async {
      requests.add(req);
      if (req.url.path.endsWith('/api/login')) {
        tokenValid = true;
        return http.Response(
          jsonEncode({
            'Success': true,
            'AccessToken': 'fresh',
            'WhooshId': 'W1',
          }),
          200,
        );
      }
      if (req.url.host == 'files.test') {
        return http.Response.bytes(corosStyleFit(), 200);
      }
      if (!tokenValid) return http.Response('', 401);
      return switch (req.url.path) {
        '/v2/rider/profile/activities' => http.Response(
          jsonEncode({
            'data': {
              'results': [ride()],
              'totalPages': 1,
            },
          }),
          200,
        ),
        '/v2/rider/profile/download-activity-file' => http.Response(
          jsonEncode({'data': 'https://files.test/r1.fit'}),
          200,
        ),
        _ => http.Response('', 404),
      };
    }),
  );

  // Far enough back to reach the fixture's ride.
  int days() => DateTime.now().difference(start).inDays + 2;
  int downloads() => requests.where((r) => r.url.host == 'files.test').length;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    requests = [];
    tokenValid = true;
    withFile = true;
    FlutterSecureStorage.setMockInitialValues({
      'mywhoosh_auth_v1': jsonEncode({
        'accessToken': 'tok',
        'whooshId': 'W1',
        'email': 'me@example.com',
      }),
      'mywhoosh_password': 'secret',
    });
  });
  tearDown(() => db.close());

  test('a ride comes with the curves of its FIT file, once', () async {
    final r = await service().sync(days: days());
    expect(r.rides, 1);
    final a = await db.select(db.activityRecords).getSingle();
    expect(a.activityId, 'mywhoosh_R1');
    expect(a.source, 'mywhoosh');
    expect(a.name, 'Tempo Ride');
    expect(a.maxHeartRate, 99);
    expect(a.metricsJson, contains('"hr"'));
    expect(downloads(), 1);

    await service().sync(days: days());
    expect(downloads(), 1);
  });

  test('without a file the list values are kept and it is a ride', () async {
    withFile = false;
    await service().sync(days: days());
    final a = await db.select(db.activityRecords).getSingle();
    expect(a.type, 'cycling');
    expect(a.durationSeconds, 120);
    expect(a.distanceMeters, closeTo(1200, .01));
    expect(a.avgWatts, 180);
    expect(a.avgHeartRate, 91);
  });

  test('a deleted ride is not stored again', () async {
    await service().sync(days: days());
    await db.deleteActivityByUser('mywhoosh_R1');
    requests.clear();
    await service().sync(days: days());
    expect(downloads(), 0);
    expect(await db.select(db.activityRecords).get(), isEmpty);
  });

  test('an ended session signs in again with the stored password', () async {
    tokenValid = false;
    final r = await service().sync(days: days());
    expect(r.authError, isFalse);
    expect(r.rides, 1);
    final login = requests.firstWhere((q) => q.url.path.endsWith('/login'));
    expect(jsonDecode(login.body)['Password'], 'secret');
  });

  test('the Garmin copy of a ride keeps its place', () async {
    withFile = false;
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'garmin_1',
            name: 'Virtual Ride',
            type: 'cycling',
            startDate: start.toLocal(),
            durationSeconds: 121,
            source: const Value('garmin_api'),
          ),
        );
    await service().sync(days: days());
    final rows = await db.select(db.activityRecords).get();
    expect(rows.map((a) => a.source), ['garmin_api']);
    expect(rows.single.name, 'Tempo Ride');
  });

  test('a ride stored before its Garmin copy came gives way', () async {
    await service().sync(days: days());
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'garmin_1',
            name: 'Virtuelles Radfahren',
            type: 'virtual_ride',
            startDate: start.toLocal(),
            durationSeconds: 120,
            source: const Value('garmin_api'),
          ),
        );
    expect(await db.deduplicateActivities(), 1);
    final kept = await db.select(db.activityRecords).getSingle();
    expect(kept.source, 'garmin_api');
    expect(kept.name, 'Tempo Ride');
    // Back to Garmin's own name, if the athlete wants it.
    await db.resetActivityTitle('garmin_1');
    expect(
      (await db.getActivityById('garmin_1'))!.name,
      'Virtuelles Radfahren',
    );
    // Later syncs see the copy in the list and download nothing.
    requests.clear();
    await service().sync(days: days());
    expect(downloads(), 0);
    expect(await db.select(db.activityRecords).get(), hasLength(1));
  });

  test('a title the athlete gave the Garmin copy stays', () async {
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'garmin_1',
            name: 'Virtual Ride',
            type: 'virtual_ride',
            startDate: start.toLocal(),
            durationSeconds: 120,
            source: const Value('garmin_api'),
          ),
        );
    await db.renameActivity('garmin_1', 'Mein Sprinttraining');
    await service().sync(days: days());
    expect((await db.getActivityById('garmin_1'))!.name, 'Mein Sprinttraining');
  });

  test('an account open on another device is told apart', () async {
    final client = MyWhooshClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'Success': false,
            'LoginType': 4,
            'Message': 'You are already logged in from another device.',
          }),
          200,
        ),
      ),
    );
    expect(
      client.login('me@example.com', 'secret'),
      throwsA(isA<MyWhooshSignedInElsewhere>()),
    );
  });

  test('ride durations read as seconds', () {
    expect(parseRideDuration('01:31:54.000'), 5514);
    expect(parseRideDuration('00:00:00.000'), isNull);
    expect(parseRideDuration('bad'), isNull);
  });
}
