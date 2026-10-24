import 'dart:convert';

import 'package:fjelia/api/coros_client.dart';
import 'package:fjelia/api/coros_workout.dart';
import 'package:fjelia/models/prepared_workout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> step(
  String type,
  num value,
  int zone,
  int low,
  int high, {
  String condition = 'time',
}) => {
  'type': 'ExecutableStepDTO',
  'stepType': {'stepTypeKey': type},
  'endCondition': {'conditionTypeKey': condition},
  'endConditionValue': value,
  'zoneNumber': zone,
  'targetType': {'workoutTargetTypeKey': 'heart.rate.zone'},
  'targetValueOne': low,
  'targetValueTwo': high,
};

PreparedWorkout workout(
  List<Map<String, dynamic>> steps, {
  String sport = 'running',
  int? thresholdHr = 165,
}) => PreparedWorkout(
  sessionId: 's',
  title: 'Tempo',
  date: DateTime(2026, 10, 28),
  sport: sport,
  steps: steps,
  description: '',
  thresholdHr: thresholdHr,
);

final intervals = [
  step('warmup', 600, 1, 92, 109),
  {
    'type': 'RepeatGroupDTO',
    'stepType': {'stepTypeKey': 'repeat'},
    'numberOfIterations': 5,
    'workoutSteps': [
      step('interval', 240, 4, 146, 164),
      step('recovery', 120, 1, 92, 109),
    ],
  },
  step('cooldown', 300, 1, 92, 109),
];

void main() {
  group('buildCorosWorkout', () {
    test('steps, a repeat group and their order', () {
      final built = buildCorosWorkout(workout(intervals), firstId: 1000);
      final program = built.program;
      expect(program['sportType'], 1);
      expect(program['name'], 'Tempo');
      final exercises = (program['exercises'] as List).cast<Map>();
      // Warm-up, group header with two children, cool-down.
      expect(exercises, hasLength(5));
      expect(exercises.map((e) => e['exerciseType']), [1, 0, 2, 4, 3]);
      final group = exercises[1];
      expect(group['isGroup'], isTrue);
      expect(group['sets'], 5);
      expect(group['sortNo'], 67108864);
      expect(exercises[2]['groupId'], group['id']);
      expect(exercises[3]['groupId'], group['id']);
      expect(exercises[2]['sortNo'], 1);
      expect(exercises[3]['sortNo'], 2);
      expect(exercises[0]['groupId'], '');
      // Ids are unique and count up from the first.
      final ids = exercises.map((e) => e['id'] as int).toList();
      expect(ids.toSet(), hasLength(5));
      expect(ids.reduce((a, b) => a < b ? a : b), 1000);
    });

    test('time and distance targets', () {
      final built = buildCorosWorkout(
        workout([
          step('warmup', 600, 1, 92, 109),
          step('interval', 1000, 4, 146, 164, condition: 'distance'),
        ]),
        firstId: 1,
      );
      final e = (built.program['exercises'] as List).cast<Map>();
      expect([e[0]['targetType'], e[0]['targetValue']], [2, 600]);
      expect(e[0]['targetDisplayUnit'], 0);
      // A kilometre is 100000 centimetres.
      expect([e[1]['targetType'], e[1]['targetValue']], [5, 100000]);
      expect(e[1]['targetDisplayUnit'], 1);
      expect(built.program['distance'], '1.00');
      expect(built.program['duration'], 600);
    });

    test('heart rate is a range as a share of threshold', () {
      final built = buildCorosWorkout(workout(intervals), firstId: 1);
      final e = (built.program['exercises'] as List).cast<Map>();
      final run = e[2];
      // 146 and 164 bpm of a 165 bpm threshold, in tenths of a percent.
      expect(run['intensityPercent'], (146 / 165 * 100000).round());
      expect(run['intensityPercentExtend'], (164 / 165 * 100000).round());
      expect(run['hrType'], 3);
      expect(run['intensityType'], 2);
      // 6 is COROS's own range; 2 would be the named zone Aerobic Power.
      expect(run['intensityCustom'], 6);
      expect(run['isIntensityPercent'], isTrue);
      expect(run['name'], 'Training 04:00 @ Z4 146-164 bpm');
      // COROS works the beats out from its own profile.
      expect(run['intensityValue'], 0);
    });

    test('without a threshold there is no heart-rate target to send', () {
      final built = buildCorosWorkout(
        workout(intervals, thresholdHr: null),
        firstId: 1,
      );
      for (final e in (built.program['exercises'] as List).cast<Map>().where(
        (e) => e['isGroup'] == false,
      )) {
        expect(e['hrType'], 0);
        expect(e['intensityType'], 0);
        expect(e['isIntensityPercent'], anyOf(isNull, isFalse));
      }
    });

    test('totals and the bar chart count the plain steps', () {
      final built = buildCorosWorkout(workout(intervals), firstId: 1);
      final program = built.program;
      // The steps once, as the Training Hub totals them.
      expect(program['duration'], 600 + 240 + 120 + 300);
      expect(program['sets'], 4);
      expect(program['totalSets'], 4);
      final bars = (program['exerciseBarChart'] as List).cast<Map>();
      expect(bars, hasLength(4));
      expect(bars.map((b) => b['width']), everyElement(25.0));
      expect(bars.map((b) => b['height']), [83, 93, 5, 88]);
      expect(built.entity['exerciseBarChart'], bars);
    });

    test('sports without a structured form are named, not guessed', () {
      expect(
        () => buildCorosWorkout(
          workout(intervals, sport: 'strength'),
          firstId: 1,
        ),
        throwsA(
          isA<CorosUnsupportedWorkout>().having(
            (e) => e.reason,
            'reason',
            contains('strength'),
          ),
        ),
      );
      expect(
        () => buildCorosWorkout(
          workout([
            {
              'type': 'RepeatGroupDTO',
              'numberOfIterations': 2,
              'workoutSteps': [
                {
                  'type': 'RepeatGroupDTO',
                  'numberOfIterations': 2,
                  'workoutSteps': [step('interval', 60, 4, 146, 164)],
                },
              ],
            },
          ]),
          firstId: 1,
        ),
        throwsA(isA<CorosUnsupportedWorkout>()),
      );
      expect(
        () => buildCorosWorkout(workout(const []), firstId: 1),
        throwsA(isA<CorosUnsupportedWorkout>()),
      );
      // Cycling and swimming have codes.
      expect(
        buildCorosWorkout(
          workout(intervals, sport: 'cycling_gravel'),
          firstId: 1,
        ).program['sportType'],
        2,
      );
      expect(
        buildCorosWorkout(
          workout(intervals, sport: 'swimming'),
          firstId: 1,
        ).program['sportType'],
        5,
      );
    });

    test('the request body and the fingerprint', () {
      final built = buildCorosWorkout(workout(intervals), firstId: 1);
      final body = built.payload('20261028');
      expect(body['pbVersion'], 2);
      expect((body['entities'] as List).single['happenDay'], '20261028');
      expect((body['programs'] as List).single, built.program);
      expect(body['versionObjects'], [
        {'id': 1, 'status': 1},
      ]);
      // The day is not part of the workout: the same steps, the same print.
      final again = buildCorosWorkout(workout(intervals), firstId: 500);
      expect(again.fingerprint, built.fingerprint);
      // A different heart-rate encoding is a different workout to resend.
      final other = buildCorosWorkout(workout(intervals), firstId: 1);
      (other.program['exercises'] as List).cast<Map>()[2]['intensityCustom'] =
          2;
      expect(other.fingerprint, isNot(built.fingerprint));
      final changed = buildCorosWorkout(
        workout([step('warmup', 900, 1, 92, 109)]),
        firstId: 1,
      );
      expect(changed.fingerprint, isNot(built.fingerprint));
    });
  });

  group('CorosClient.uploadWorkout', () {
    CorosClient signedIn(MockClient mock) {
      final client = CorosClient(client: mock);
      client.adopt(
        CorosAuth(
          accessToken: 'tok',
          userId: '42',
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return client;
    }

    final built = buildCorosWorkout(workout(intervals), firstId: 1);

    test('posts to the schedule update with the session headers', () async {
      final bodies = <Map<String, dynamic>>[];
      final client = signedIn(
        MockClient((req) async {
          expect(req.url.host, 'teameuapi.coros.com');
          expect(req.url.path, '/training/schedule/update');
          expect(req.headers['accessToken'], 'tok');
          expect(req.headers['yfheader'], contains('42'));
          bodies.add(jsonDecode(req.body) as Map<String, dynamic>);
          return http.Response(jsonEncode({'result': '0000'}), 200);
        }),
      );
      await client.uploadWorkout(built, DateTime(2026, 10, 28));
      expect(bodies, hasLength(1));
      expect(
        (bodies.single['entities'] as List).single['happenDay'],
        '20261028',
      );
    });

    test('a refused day format is tried again with dashes', () async {
      final days = <String>[];
      final client = signedIn(
        MockClient((req) async {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          final day = (body['entities'] as List).single['happenDay'] as String;
          days.add(day);
          return http.Response(
            jsonEncode(
              day.contains('-')
                  ? {'result': '1000'}
                  : {'result': '2001', 'message': 'bad day'},
            ),
            200,
          );
        }),
      );
      await client.uploadWorkout(built, DateTime(2026, 10, 28));
      expect(days, ['20261028', '2026-10-28']);
    });

    test('when both are refused the message of COROS is passed on', () async {
      final client = signedIn(
        MockClient(
          (req) async => http.Response(
            jsonEncode({'result': '2001', 'message': 'invalid program'}),
            200,
          ),
        ),
      );
      await expectLater(
        client.uploadWorkout(built, DateTime(2026, 10, 28)),
        throwsA(
          isA<CorosException>().having(
            (e) => e.message,
            'message',
            allOf(contains('2001'), contains('invalid program')),
          ),
        ),
      );
    });

    test('a lost session is an auth error, not a refusal', () async {
      final client = signedIn(
        MockClient(
          (req) async => http.Response(jsonEncode({'result': '1019'}), 200),
        ),
      );
      await expectLater(
        client.uploadWorkout(built, DateTime(2026, 10, 28)),
        throwsA(isA<CorosAuthException>()),
      );
    });
  });
}
