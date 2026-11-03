import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/coros_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/coros_fit_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late List<http.Request> requests;
  late bool fileAvailable;
  late bool zipped;
  final start = DateTime.now().subtract(const Duration(days: 1));

  /// A walk COROS lists as a run, with an average but no maximum heart rate
  /// and no moving time, as in the activity list of the web API.
  Map<String, dynamic> row() => {
    'labelId': 'L1',
    'sportType': 100,
    'name': 'Hemmingen Wandern',
    'startTime': start.millisecondsSinceEpoch ~/ 1000,
    'workoutTime': 120,
    'distance': 9530,
    'avgHr': 92,
  };

  CorosService service() => CorosService(
    db,
    client: MockClient((req) async {
      requests.add(req);
      String ok(Object data) => jsonEncode({'result': '0000', 'data': data});
      return switch (req.url.path) {
        '/activity/query' => http.Response(
          ok({
            'dataList': [row()],
            'totalPage': 1,
            'pageNumber': 1,
          }),
          200,
        ),
        '/activity/detail/download' =>
          fileAvailable && req.url.queryParameters['fileType'] == '4'
              ? http.Response(ok({'fileUrl': 'https://files.test/a.fit'}), 200)
              : http.Response(
                  jsonEncode({'result': '1001', 'message': 'no file'}),
                  200,
                ),
        '/a.fit' => http.Response.bytes(
          zipped
              ? ZipEncoder().encode(
                  Archive()
                    ..addFile(ArchiveFile.bytes('L1.fit', corosStyleFit())),
                )
              : corosStyleFit(),
          200,
        ),
        _ => http.Response(ok(const {}), 200),
      };
    }),
  );

  Future<ActivityRecord> stored() =>
      (db.select(db.activityRecords)).getSingle();
  int downloads() =>
      requests.where((r) => r.url.path == '/activity/detail/download').length;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    requests = [];
    fileAvailable = true;
    zipped = false;
    FlutterSecureStorage.setMockInitialValues({
      'coros_auth_v1': jsonEncode({
        'accessToken': 'tok',
        'userId': '42',
        'region': 'eu',
        'timestampMs': DateTime.now().millisecondsSinceEpoch,
        'email': 'me@example.com',
      }),
    });
  });
  tearDown(() => db.close());

  test(
    'max heart rate, moving time and curves come from the FIT file',
    () async {
      await service().sync(days: 7);
      final a = await stored();
      expect(a.avgHeartRate, 92); // the summary's own value stays
      expect(a.maxHeartRate, 99);
      expect(a.movingDurationSeconds, 110);
      expect(a.metricsJson, contains('"hr"'));
      expect(a.gpxJson, isNotNull);
      // The watch file says walk; COROS listed a run.
      expect(a.type, 'walking');
      expect(downloads(), 1);

      // Once the curves are stored, the next sync does not download again.
      await service().sync(days: 7);
      expect(downloads(), 1);
      expect((await stored()).maxHeartRate, 99);
    },
  );

  test('a deleted activity is neither downloaded nor stored again', () async {
    await service().sync(days: 7);
    await db.deleteActivityByUser('coros:L1');
    requests.clear();
    await service().sync(days: 7);
    expect(downloads(), 0);
    expect(await db.select(db.activityRecords).get(), isEmpty);
  });

  test('a FIT file inside a ZIP is unpacked', () async {
    zipped = true;
    await service().sync(days: 7);
    final a = await stored();
    expect(a.maxHeartRate, 99);
    expect(a.movingDurationSeconds, 110);
  });

  test('a curve cut short by the old decoder is downloaded again', () async {
    await service().sync(days: 7);
    await db
        .update(db.activityRecords)
        .write(
          ActivityRecordsCompanion(
            metricsJson: Value(
              jsonEncode([
                {'t': 0, 'hr': 95},
                {'t': 20000, 'hr': 97},
              ]),
            ),
          ),
        );
    await service().sync(days: 7);
    expect(downloads(), 2);
    expect((await stored()).metricsJson, isNot(contains('"t":20000')));
  });

  test(
    'without an export the summary is still saved, FIT then TCX tried',
    () async {
      fileAvailable = false;
      await service().sync(days: 7);
      final a = await stored();
      expect(a.durationSeconds, 120);
      expect(a.avgHeartRate, 92);
      expect(a.maxHeartRate, isNull);
      expect(a.movingDurationSeconds, isNull);
      expect(a.type, 'running');
      expect(
        requests
            .where((r) => r.url.path == '/activity/detail/download')
            .map((r) => r.url.queryParameters['fileType']),
        ['4', '3'],
      );
    },
  );
}
