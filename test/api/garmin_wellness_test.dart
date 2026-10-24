import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fjelia/api/garmin_client.dart';
import 'package:fjelia/models/garmin_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'daily summary passes date as a query, preserving steps and stress',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'garmin_access_token': 'fixture',
      });
      final client = GarminClient(
        client: MockClient((request) async {
          expect(request.url.path, '/usersummary-service/usersummary/daily/');
          expect(request.url.queryParameters['calendarDate'], '2026-10-20');
          return http.Response(
            jsonEncode({
              'calendarDate': '2026-10-20',
              'totalSteps': 683,
              'averageStressLevel': 13,
              'restingHeartRate': 47,
            }),
            200,
          );
        }),
      );
      final wellness = await client.getWellness(DateTime(2026, 10, 20));
      expect(wellness?.steps, 683);
      expect(wellness?.averageStress, 13);
      expect(wellness?.restingHeartRate, 47);
    },
  );

  test('sleep response preserves top-level resting heart rate', () {
    final sleep = SleepData.fromGarminJson({
      'restingHeartRate': 47,
      'dailySleepDTO': {
        'calendarDate': '2026-10-20',
        'sleepTimeSeconds': 28800,
      },
    });
    expect(sleep.restingHeartRate, 47);
  });
}
