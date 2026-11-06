import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/gym_workout.dart';
import 'package:fjelia/models/running_speed.dart';
import 'package:fjelia/models/training_ble_profile.dart';
import 'package:fjelia/models/training_device.dart';
import 'package:fjelia/services/gym_workout_import_service.dart';
import 'package:fjelia/services/matrix_xid_client.dart';
import 'package:fjelia/services/workout_photo_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const treadmill = TrainingDevice(id: 'matrix', name: 'Matrix T7Xi');
final session = MatrixXidSession(
  origin: Uri.parse('https://gym.netpulse.com'),
  userId: 'user-1',
  cookie: 'JSESSIONID=test-cookie',
);
final started = DateTime.utc(2026, 11, 1, 12);
Map<String, dynamic> row({
  int id = 17,
  Map<String, dynamic> extra = const {},
}) => {
  'id': id,
  'startDateUtc': started.millisecondsSinceEpoch,
  'totalDuration': 1800,
  'totalDistance': 5.2,
  'totalCalories': 320,
  'totalWorkout': 1,
  'avgHeartRate': 145.0,
  'equipmentType': 'Treadmill',
  ...extra,
};
Map<String, dynamic> response({
  String unit = 'kilometer',
  List<Object?>? rows,
}) => {
  'distanceUnit': unit,
  'intervals': rows ?? [row()],
};
GymWorkout workout({
  String id = 'summary-1',
  DateTime? at,
  String source = 'gym_summary',
}) => GymWorkout(
  id: id,
  startedAt: at ?? started,
  durationSeconds: 1800,
  source: source,
  distanceMeters: 5200,
  calories: 320,
  avgHeartRate: 145,
);

void main() {
  group('direct Bluetooth capability and RSC data', () {
    test('full standard UUIDs normalize; proprietary UUIDs stay distinct', () {
      expect(trainingUuid('00001826-0000-1000-8000-00805F9B34FB'), '1826');
      expect(trainingUuid('00002A53-0000-1000-8000-00805f9b34fb'), '2a53');
      expect(
        trainingUuid('12341826-0000-1000-8000-00805f9b34fb'),
        isNot('1826'),
      );
    });
    test('an indication-only FTMS characteristic supports recording', () {
      const report = TrainingBleReport(
        device: treadmill,
        services: [
          TrainingGattService('00001826-0000-1000-8000-00805f9b34fb', [
            TrainingGattCharacteristic(uuid: '2acd', indicate: true),
          ]),
        ],
      );
      expect(report.canRecord, isTrue);
      expect(report.machines.single.name, 'treadmill');
    });
    test(
      'a readable characteristic alone cannot promise a live connection',
      () {
        const report = TrainingBleReport(
          device: treadmill,
          services: [
            TrainingGattService('1826', [
              TrainingGattCharacteristic(uuid: '2acd', read: true),
            ]),
            TrainingGattService('180a', [
              TrainingGattCharacteristic(uuid: '2a29', read: true),
            ]),
          ],
        );
        expect(report.canRecord, isFalse);
        expect(report.toJson()['services'], hasLength(2));
        expect(
          jsonEncode(report.toJson()),
          isNot(contains('characteristic_values')),
        );
      },
    );
    test('RSC fallback supports recording without FTMS', () {
      const report = TrainingBleReport(
        device: treadmill,
        services: [
          TrainingGattService('1814', [
            TrainingGattCharacteristic(uuid: '2a53', notify: true),
          ]),
        ],
      );
      expect(report.runningSpeed, isTrue);
      expect(report.canRecord, isTrue);
      expect(report.machines, isEmpty);
    });
    test('RSC units are m/s, steps/min, meters and tenths of meters', () {
      final data = decodeRunningSpeed([7, 0, 3, 172, 125, 0, 0x39, 0x30, 0, 0]);
      expect(data, {
        'spd': 3.0,
        'cad': 172,
        'running': 1,
        'stride_length': 1.25,
        'machine_distance': 1234.5,
      });
      expect(data.containsKey('incline'), isFalse);
      expect(data.containsKey('hr'), isFalse);
    });
    test(
      'zero RSC speed/cadence is valid; optional counters remain absent',
      () {
        expect(decodeRunningSpeed([0, 0, 0, 0]), {
          'spd': 0.0,
          'cad': 0,
          'running': 0,
        });
      },
    );
    test('truncated RSC and invalid bytes cannot become measurements', () {
      for (final bytes in <List<int>>[
        [],
        [0, 0, 0],
        [1, 0, 0, 0, 1],
        [2, 0, 0, 0, 1, 2, 3],
        [0, 0, 256, 1],
      ]) {
        expect(() => decodeRunningSpeed(bytes), throwsFormatException);
      }
    });
  });

  group('console photo extraction', () {
    WorkoutTextLine line(String text, double x, double y) =>
        WorkoutTextLine(text, x, y, .2, .03);
    test('labels above values use the matching column and explicit units', () {
      final draft = parseWorkoutPhoto([
        line('TOTAL TIME', .1, .2),
        line('DISTANCE (mi)', .5, .2),
        line('CALORIES', .1, .5),
        line('AVG HR', .5, .5),
        line('32:15', .1, .25),
        line('3.10', .5, .25),
        line('320', .1, .55),
        line('145 bpm', .5, .55),
      ]);
      expect(draft.seconds, 1935);
      expect(draft.distance, 3.1);
      expect(draft.unit, GymDistanceUnit.miles);
      expect(draft.calories, 320);
      expect(draft.heartRate, 145);
    });
    test(
      'German decimal values and long durations are read without guessing',
      () {
        final draft = parseWorkoutPhoto([
          line('DAUER 1:02:03', .1, .1),
          line('DISTANZ 10,25 km', .1, .3),
          line('KALORIEN 650', .1, .5),
        ]);
        expect(draft.seconds, 3723);
        expect(draft.distance, 10.25);
        expect(draft.unit, GymDistanceUnit.kilometers);
        expect(draft.heartRate, isNull);
      },
    );
    test('remaining time, pace, and calorie rate do not become totals', () {
      final draft = parseWorkoutPhoto([
        line('TIME REMAINING 10:00', .1, .1),
        line('PACE 5:45', .1, .3),
        line('CALORIES PER HOUR 900', .1, .5),
      ]);
      expect(draft.seconds, isNull);
      expect(draft.distance, isNull);
      expect(draft.calories, isNull);
    });
    test('conflicting duration labels are left for manual review', () {
      final draft = parseWorkoutPhoto([
        line('TIME 30:00', .1, .1),
        line('DURATION 20:00', .1, .5),
        line('DISTANCE 5.0', .5, .1),
      ]);
      expect(draft.seconds, isNull);
      expect(draft.unit, isNull);
    });
    test('duration validation rejects malformed minutes, seconds and zero', () {
      expect(gymDuration('45:30'), 2730);
      expect(gymDuration('1:02:03'), 3723);
      for (final value in [
        '30',
        '00:00',
        '-1:30',
        '1:70:00',
        '30:65',
        '25:00:00',
      ]) {
        expect(gymDuration(value), isNull);
      }
    });
  });

  group('xID wire format and account transport', () {
    test('milliseconds, seconds and kilometers are mapped to SI values', () {
      final decoded = decodeMatrixWorkouts(response(), session);
      expect(decoded.skipped, 0);
      final w = decoded.workouts.single;
      expect(w.startedAt, started);
      expect(w.durationSeconds, 1800);
      expect(w.distanceMeters, 5200);
      expect(w.calories, 320);
      expect(w.avgHeartRate, 145);
      expect(w.source, 'matrix_xid');
    });
    test('mile, meter and foot units remain distinct', () {
      for (final e in {'mile': 1609.344, 'meter': 1.0, 'foot': .3048}.entries) {
        final w = decodeMatrixWorkouts(
          response(
            unit: e.key,
            rows: [
              row(extra: {'totalDistance': 1}),
            ],
          ),
          session,
        ).workouts.single;
        expect(w.distanceMeters, closeTo(e.value, 1e-9));
      }
    });
    test(
      'unknown units and aggregated/invalid records are reported as skipped',
      () {
        expect(
          decodeMatrixWorkouts(response(unit: 'unknown'), session).skipped,
          1,
        );
        final batch = decodeMatrixWorkouts(
          response(
            rows: [
              row(),
              row(id: 18, extra: {'totalWorkout': 2}),
              row(id: 19, extra: {'startDateUtc': 1793534400}),
              row(id: 20, extra: {'totalDuration': -1}),
              row(id: 21, extra: {'totalDistance': 'unknown'}),
              row(id: 22, extra: {'avgHeartRate': 500}),
            ],
          ),
          session,
        );
        expect(batch.workouts, hasLength(1));
        expect(batch.skipped, 5);
      },
    );
    test('missing HR and distance stay missing', () {
      final w = decodeMatrixWorkouts(
        response(
          rows: [
            row(extra: {'totalDistance': null, 'avgHeartRate': 0}),
          ],
        ),
        session,
      ).workouts.single;
      expect(w.distanceMeters, isNull);
      expect(w.avgHeartRate, isNull);
    });
    test('remote identities are scoped to account and host', () {
      final id = decodeMatrixWorkouts(response(), session).workouts.single.id;
      final other = MatrixXidSession(
        origin: session.origin,
        userId: 'another',
        cookie: session.cookie,
      );
      expect(
        decodeMatrixWorkouts(response(), other).workouts.single.id,
        isNot(id),
      );
      expect(decodeMatrixWorkouts(response(), session).workouts.single.id, id);
    });
    test(
      'login uses form POST and stores a narrowly scoped session cookie',
      () async {
        final client = MatrixXidClient(
          client: MockClient((request) async {
            expect(request.method, 'POST');
            expect(request.url.toString(), 'https://gym.netpulse.com/np/login');
            expect(Uri.splitQueryString(request.body), {
              'username': '1234567890',
              'password': '4321',
            });
            expect(request.headers['X-NP-API-Version'], '1.5');
            return http.Response(
              '{"uuid":"user-1"}',
              200,
              headers: {
                'set-cookie': 'other=value; Path=/, JSESSIONID=abc123; Path=/; Secure; HttpOnly',
              },
            );
          }),
        );
        addTearDown(client.close);
        final result = await client.login(
          'gym.netpulse.com',
          '1234567890',
          '4321',
        );
        expect(result.cookie, 'JSESSIONID=abc123');
        expect(jsonEncode(result.toJson()), isNot(contains('4321')));
      },
    );
    test(
      'insecure/arbitrary hosts are rejected before sending credentials',
      () async {
        var requests = 0;
        final client = MatrixXidClient(
          client: MockClient((request) async {
            requests++;
            return http.Response('{}', 200);
          }),
        );
        addTearDown(client.close);
        for (final url in [
          'http://gym.netpulse.com',
          'https://netpulse.com.evil.test',
          'https://evil.test',
          'https://user:pin@gym.netpulse.com',
          'https://gym.netpulse.com:8443',
          'https://gym.netpulse.com/path',
        ]) {
          await expectLater(
            client.login(url, 'xid', 'pin'),
            throwsFormatException,
          );
        }
        expect(requests, 0);
      },
    );
    test(
      'history requests use single treadmill workouts and bounded date windows',
      () async {
        final requests = <http.Request>[];
        final client = MatrixXidClient(
          client: MockClient((r) async {
            requests.add(r);
            expect(r.method, 'GET');
            expect(r.headers['Cookie'], 'JSESSIONID=test-cookie');
            expect(r.url.path, '/np/exerciser/user-1/workouts');
            expect(r.url.queryParameters['interval'], 'single');
            expect(r.url.queryParameters['filter'], 'treadmill');
            expect(r.followRedirects, isFalse);
            return http.Response(jsonEncode(response()), 200);
          }),
        );
        addTearDown(client.close);
        final result = await client.workouts(
          session,
          from: DateTime.utc(2026, 11, 1),
          through: DateTime.utc(2026, 11, 15),
        );
        expect(requests, hasLength(3));
        expect(requests.first.url.queryParameters['endDate'], '20261107');
        expect(requests.last.url.queryParameters['startDate'], '20261115');
        expect(result.workouts, hasLength(1));
      },
    );
    test(
      'expired sessions and redirects never follow a login destination',
      () async {
        final client = MatrixXidClient(
          client: MockClient(
            (r) async => http.Response(
              'private-session-cookie',
              302,
              headers: {'location': 'https://another.test'},
            ),
          ),
        );
        addTearDown(client.close);
        await expectLater(
          client.workouts(session, from: started, through: started),
          throwsA(
            isA<MatrixXidException>()
                .having((e) => e.expired, 'expired', true)
                .having(
                  (e) => e.toString(),
                  'redaction',
                  isNot(contains('private-session')),
                ),
          ),
        );
      },
    );
    test(
      'network errors do not expose URLs, cookies, or credentials',
      () async {
        final client = MatrixXidClient(
          client: MockClient(
            (r) async =>
                throw http.ClientException('private-passcode-cookie', r.url),
          ),
        );
        addTearDown(client.close);
        await expectLater(
          client.login('gym.netpulse.com', 'xid', 'pin'),
          throwsA(
            isA<MatrixXidException>().having(
              (e) => e.toString(),
              'redaction',
              isNot(contains('private')),
            ),
          ),
        );
      },
    );
  });

  group('summary storage and duplicates', () {
    late AppDatabase db;
    late GymWorkoutImportService service;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      service = GymWorkoutImportService(db);
    });
    tearDown(() => db.close());
    test(
      'summary fields are saved without fabricating samples or HR zones',
      () async {
        expect((await service.save([workout()])).imported, 1);
        final saved = (await db.select(db.activityRecords).get()).single;
        expect(saved.distanceMeters, 5200);
        expect(saved.avgHeartRate, 145);
        expect(saved.metricsJson, isNull);
        expect(saved.hrZonesJson, isNull);
        expect(saved.source, 'gym_summary');
        expect((await service.save([workout()])).duplicates, 1);
      },
    );
    test(
      'existing recorded workouts are retained instead of a second summary',
      () async {
        await db
            .into(db.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: 'live',
                name: 'Live run',
                type: 'treadmill_running',
                startDate: started,
                durationSeconds: 1800,
                source: const Value('ftms'),
                metricsJson: const Value('[{"t":1,"spd":3}]'),
              ),
            );
        expect((await service.save([workout()])).duplicates, 1);
        expect(
          (await db.select(db.activityRecords).get()).single.activityId,
          'live',
        );
      },
    );
    test('matching summaries across midnight are duplicates', () async {
      final before = DateTime.utc(2026, 11, 1, 23, 59);
      await service.save([workout(at: before)]);
      expect(
        (await service.save([
          workout(id: 'later', at: before.add(const Duration(minutes: 2))),
        ])).duplicates,
        1,
      );
    });
    test(
      'deleted workouts are not brought back by another import source',
      () async {
        await service.save([workout()]);
        await db.deleteActivityByUser('summary-1');
        expect(
          (await service.save([workout(id: 'different', source: 'matrix_xid')]))
              .duplicates,
          1,
        );
        expect(await db.select(db.activityRecords).get(), isEmpty);
      },
    );
    test('a later complete recording replaces the imported summary', () async {
      await service.save([workout()]);
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'watch',
              name: 'Recorded run',
              type: 'running',
              startDate: started,
              durationSeconds: 1800,
              source: const Value('garmin_api'),
            ),
          );
      expect(await db.deduplicateActivities(), 1);
      expect(
        (await db.select(db.activityRecords).get()).single.activityId,
        'watch',
      );
    });
    test('invalid data rolls back the entire batch', () async {
      await expectLater(
        service.save([
          workout(),
          GymWorkout(
            id: 'bad',
            startedAt: started,
            durationSeconds: 0,
            source: 'gym_summary',
          ),
        ]),
        throwsFormatException,
      );
      expect(await db.select(db.activityRecords).get(), isEmpty);
    });
  });
}
