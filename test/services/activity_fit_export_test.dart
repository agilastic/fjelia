import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:fjelia/api/garmin_client.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/activity_file_import_service.dart';
import 'package:fjelia/services/activity_fit_export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final start = DateTime.utc(2026, 11, 2, 16);

  /// A 10-minute ride from another platform, one sample a minute.
  ActivityRecord ride() => ActivityRecord(
    id: 1,
    activityId: 'coros:L1',
    name: 'Evening ride',
    type: 'cycling',
    startDate: start,
    durationSeconds: 600,
    distanceMeters: 5000,
    avgHeartRate: 130,
    maxHeartRate: 150,
    avgWatts: 200,
    totalElevation: 40,
    source: 'coros',
    metricsJson: jsonEncode([
      for (var i = 0; i <= 10; i++)
        {
          't': start.add(Duration(minutes: i)).millisecondsSinceEpoch,
          'hr': 120 + i * 3,
          'w': 200,
          'd': i * 500,
          'cad': 85,
        },
    ]),
    gpxJson: jsonEncode([
      {'lat': 52.30, 'lng': 9.80},
      {'lat': 52.31, 'lng': 9.81},
    ]),
  );

  test('a stored workout reads back from its FIT file', () {
    final file = decodeActivityFile(activityRecordFit(ride()))!;
    expect(file.type, 'cycling');
    expect(file.start, start);
    expect(file.durationSeconds, 600);
    expect(file.distanceMeters, closeTo(5000, 1));
    expect(file.avgHeartRate, closeTo(130, 1));
    expect(file.maxHeartRate, 150);
    expect(file.avgWatts, closeTo(200, 1));
    expect(file.samples, hasLength(11));
    expect(file.samples.last['hr'], 150);
    expect(file.route.first['lat'], closeTo(52.30, 1e-5));
    expect(file.route.last['lng'], closeTo(9.81, 1e-5));
  });

  test('a summary without samples still makes a file', () {
    final row = ride().copyWith(
      metricsJson: const Value(null),
      gpxJson: const Value(null),
    );
    final file = decodeActivityFile(activityRecordFit(row))!;
    expect(file.durationSeconds, 600);
    expect(file.distanceMeters, closeTo(5000, 1));
  });

  group('Garmin upload', () {
    setUp(
      () => FlutterSecureStorage.setMockInitialValues({
        'garmin_access_token': 'fixture',
      }),
    );

    GarminClient client(int status, List<http.BaseRequest> seen) =>
        GarminClient(
          client: MockClient.streaming((request, body) async {
            seen.add(request);
            await body.toBytes();
            return http.StreamedResponse(
              Stream.value(utf8.encode('{}')),
              status,
            );
          }),
        );

    test('the file goes to the upload service', () async {
      final seen = <http.BaseRequest>[];
      final sent = await client(
        201,
        seen,
      ).uploadActivityFit(activityRecordFit(ride()), 'fjelia_coros_L1.fit');
      expect(sent, isTrue);
      expect(seen.single.url.path, '/upload-service/upload');
      expect(seen.single.headers['Authorization'], 'Bearer fixture');
      expect(seen.single.headers['content-type'], startsWith('multipart/'));
    });

    test('a workout Garmin already has is told apart', () async {
      final sent = await client(
        409,
        [],
      ).uploadActivityFit(activityRecordFit(ride()), 'a.fit');
      expect(sent, isFalse);
    });
  });
}
