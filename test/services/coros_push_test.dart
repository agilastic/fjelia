import 'dart:convert';

import 'package:drift/native.dart';
import 'package:fjelia/api/coros_client.dart';
import 'package:fjelia/api/coros_workout.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/prepared_workout.dart';
import 'package:fjelia/services/coros_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> step(int seconds) => {
  'type': 'ExecutableStepDTO',
  'stepType': {'stepTypeKey': 'interval'},
  'endCondition': {'conditionTypeKey': 'time'},
  'endConditionValue': seconds,
  'zoneNumber': 2,
  'targetType': {'workoutTargetTypeKey': 'heart.rate.zone'},
  'targetValueOne': 110,
  'targetValueTwo': 127,
};

PreparedWorkout workout({int seconds = 1800, String sport = 'running'}) =>
    PreparedWorkout(
      sessionId: 's1',
      title: 'Easy run',
      date: DateTime(2026, 10, 28),
      sport: sport,
      steps: [step(seconds)],
      description: '',
      thresholdHr: 165,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late List<http.Request> requests;
  late String answer;

  CorosService service() => CorosService(
    db,
    client: MockClient((req) async {
      requests.add(req);
      return http.Response(answer, 200);
    }),
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    requests = [];
    answer = jsonEncode({'result': '0000'});
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

  test('a workout is sent once, a changed one again', () async {
    final coros = service();
    await coros.pushWorkout(workout());
    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/training/schedule/update');
    // The same workout again is not a second entry on the calendar.
    await expectLater(
      coros.pushWorkout(workout()),
      throwsA(
        isA<CorosException>().having(
          (e) => e.message,
          'message',
          contains('already'),
        ),
      ),
    );
    expect(requests, hasLength(1));
    // A longer one is different: it goes up.
    await coros.pushWorkout(workout(seconds: 2400));
    expect(requests, hasLength(2));
  });

  test('a refusal is not remembered as sent', () async {
    answer = jsonEncode({'result': '2001', 'message': 'invalid'});
    final coros = service();
    await expectLater(
      coros.pushWorkout(workout()),
      throwsA(isA<CorosException>()),
    );
    answer = jsonEncode({'result': '0000'});
    await coros.pushWorkout(workout());
    // Two refused formats, then the accepted one.
    expect(requests, hasLength(3));
  });

  test('a sport COROS has no form for sends nothing', () async {
    await expectLater(
      service().pushWorkout(workout(sport: 'strength')),
      throwsA(isA<CorosUnsupportedWorkout>()),
    );
    expect(requests, isEmpty);
  });

  test('not connected is said plainly', () async {
    FlutterSecureStorage.setMockInitialValues({});
    await expectLater(
      service().pushWorkout(workout()),
      throwsA(
        isA<CorosException>().having(
          (e) => e.message,
          'message',
          contains('not connected'),
        ),
      ),
    );
    expect(requests, isEmpty);
  });
}
