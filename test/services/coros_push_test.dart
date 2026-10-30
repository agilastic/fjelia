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
  // What the calendar lists on the day asked for.
  late List<Map<String, dynamic>> onCalendar;

  CorosService service() => CorosService(
    db,
    client: MockClient((req) async {
      requests.add(req);
      if (req.url.path == '/training/schedule/query') {
        return http.Response(
          jsonEncode({
            'result': '0000',
            'data': {
              'id': 'plan1',
              'entities': [
                for (final e in onCalendar)
                  {
                    'idInPlan': e['id'],
                    'planId': 'plan1',
                    'happenDay': 20261028,
                  },
              ],
              'programs': [
                for (final e in onCalendar)
                  {'idInPlan': e['id'], 'name': e['name']},
              ],
            },
          }),
          200,
        );
      }
      return http.Response(answer, 200);
    }),
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    requests = [];
    onCalendar = [];
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
    // The day is checked for copies left by earlier sends, then it goes up.
    expect(requests.map((r) => r.url.path), [
      '/training/schedule/query',
      '/training/schedule/update',
    ]);
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
    expect(requests, hasLength(2));
    // A longer one is different: it goes up.
    await coros.pushWorkout(workout(seconds: 2400));
    // The calendar is looked at first, then the new one goes up.
    expect(requests.map((r) => r.url.path), [
      '/training/schedule/query',
      '/training/schedule/update',
      '/training/schedule/query',
      '/training/schedule/update',
    ]);
  });

  test(
    'a changed workout replaces the earlier entry, not its neighbours',
    () async {
      final coros = service();
      await coros.pushWorkout(workout());
      onCalendar = [
        {'id': '5', 'name': 'Easy run'},
        {'id': '6', 'name': 'Something I added myself'},
      ];
      requests.clear();
      await coros.pushWorkout(workout(seconds: 2400));
      final bodies = [
        for (final r in requests.where((r) => r.url.path.endsWith('/update')))
          jsonDecode(r.body) as Map<String, dynamic>,
      ];
      final removal = bodies.first['versionObjects'] as List;
      expect(removal.single, {
        'id': '5',
        'planProgramId': '5',
        'planId': 'plan1',
        'status': 3,
      });
      expect(bodies, hasLength(2));
      expect(bodies.last.containsKey('programs'), isTrue);
    },
  );

  test('a copy Fjelia no longer knows of comes off before sending', () async {
    final coros = service();
    onCalendar = [
      {'id': '7', 'name': 'Easy run'},
      {'id': '8', 'name': 'Something I added myself'},
    ];
    await coros.pushWorkout(workout());
    final bodies = [
      for (final r in requests.where((r) => r.url.path.endsWith('/update')))
        jsonDecode(r.body) as Map<String, dynamic>,
    ];
    expect(bodies, hasLength(2));
    expect((bodies.first['versionObjects'] as List).single['id'], '7');
    expect(bodies.last.containsKey('programs'), isTrue);
  });

  test('moving a workout to another day sends it again', () async {
    final coros = service();
    await coros.pushWorkout(workout());
    final moved = PreparedWorkout(
      sessionId: 's1',
      title: 'Easy run',
      date: DateTime(2026, 10, 29),
      sport: 'running',
      steps: [step(1800)],
      description: '',
      thresholdHr: 165,
    );
    await coros.pushWorkout(moved);
    expect(requests.where((r) => r.url.path.endsWith('/update')), hasLength(2));
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
    // Two refused formats, then the accepted one, each after a look at the day.
    expect(requests.where((r) => r.url.path.endsWith('/update')), hasLength(3));
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

  group('as a platform among others', () {
    test(
      'what was sent is on record in the shared ledger, per session',
      () async {
        final coros = service();
        await coros.pushWorkout(workout());
        expect(await coros.hasDelivered('s1'), isTrue);
        expect(await coros.hasDelivered('other'), isFalse);
        final row = (await db.select(db.workoutDeliveries).get()).single;
        expect(row.providerId, 'coros');
        expect(row.sessionId, 's1');
        expect(row.day, '20261028');
        expect(row.name, 'Easy run');
        expect(row.fingerprint, isNotNull);
      },
    );

    test(
      'one session\'s workout is taken off the calendar and forgotten',
      () async {
        final coros = service();
        await coros.pushWorkout(workout());
        onCalendar = [
          {'id': '5', 'name': 'Easy run'},
          {'id': '6', 'name': 'Mine'},
        ];
        requests.clear();
        await coros.removeDelivered('s1');
        final removals = [
          for (final r in requests.where((r) => r.url.path.endsWith('/update')))
            jsonDecode(r.body) as Map<String, dynamic>,
        ];
        expect(removals, hasLength(1));
        expect((removals.single['versionObjects'] as List).single['id'], '5');
        expect(await coros.hasDelivered('s1'), isFalse);
        expect(await db.select(db.providerCleanups).get(), isEmpty);
      },
    );

    test(
      'a removal that fails is queued, the record goes, a retry finishes it',
      () async {
        final coros = service();
        await coros.pushWorkout(workout());
        onCalendar = [
          {'id': '5', 'name': 'Easy run'},
        ];
        answer = jsonEncode({'result': '9999', 'message': 'down'});
        await coros.removeDelivered('s1');
        final queued = (await db.select(db.providerCleanups).get()).single;
        expect(queued.providerId, 'coros');
        expect(queued.remoteId, '20261028|Easy run');
        expect(await coros.hasDelivered('s1'), isFalse);
        // Still down: tried again, still queued.
        expect(await coros.retryCleanup(), 0);
        expect((await db.select(db.providerCleanups).get()).single.attempts, 2);
        // Up again: gone from the calendar and from the queue.
        answer = jsonEncode({'result': '0000'});
        requests.clear();
        expect(await coros.retryCleanup(), 1);
        expect(await db.select(db.providerCleanups).get(), isEmpty);
        expect(requests.any((r) => r.url.path.endsWith('/update')), isTrue);
      },
    );

    test(
      'what an earlier version kept in secure storage is carried over',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'coros_auth_v1': jsonEncode({
            'accessToken': 'tok',
            'userId': '42',
            'region': 'eu',
            'timestampMs': DateTime.now().millisecondsSinceEpoch,
            'email': 'me@example.com',
          }),
          'coros_workouts_sent_v1': jsonEncode({'s1': 1234}),
        });
        final coros = service();
        expect(await coros.hasDelivered('s1'), isTrue);
        final row = (await db.select(db.workoutDeliveries).get()).single;
        expect(row.fingerprint, '1234');
        // The old key is gone: it is read once.
        expect(
          await const FlutterSecureStorage().read(
            key: 'coros_workouts_sent_v1',
          ),
          isNull,
        );
      },
    );
  });
}
