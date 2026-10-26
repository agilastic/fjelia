import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/polar_service.dart';
import 'package:fjelia/services/oauth_token_store.dart';
import 'package:fjelia/services/activity_decoder.dart';
import 'package:fjelia/screens/strain/activity_detail_sheet.dart';

import '../support/polar_fit_fixture.dart';
import 'polar_exercise_data_test.dart' show polarExerciseFixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      'polar_auth_v1': '{"userId":"42"}',
    });
    SharedPreferences.setMockInitialValues({});
    await oauthTokenStore.save(
      'polar',
      OAuthToken(
        accessToken: 'test',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  PolarService service({
    bool fitAvailable = true,
    bool corrupt = false,
    bool moving = true,
    Map<String, dynamic>? json,
    List<Map<String, dynamic>>? exercises,
  }) => PolarService(
    db,
    client: MockClient((request) async {
      if (request.url.path == '/v3/exercises') {
        expect(request.url.queryParameters['samples'], 'true');
        return http.Response(
          jsonEncode(exercises ?? [json ?? polarExerciseFixture()]),
          200,
        );
      }
      if (request.url.path.endsWith('/fit')) {
        if (!fitAvailable) return http.Response('', 404);
        final bytes = polarFitFixture(movingSeconds: moving ? 3600 : null);
        if (corrupt) bytes.last ^= 1;
        return http.Response.bytes(bytes, 200);
      }
      return http.Response('[]', 200);
    }),
  );

  test('sync saves the reported Polar values and timed records', () async {
    final result = await service().sync();
    expect(result.exercises, 1);
    final row = (await db.select(db.activityRecords).get()).single;
    expect(row.activityId, 'polar_ABC123');
    expect(row.totalElevation, 20);
    expect(row.avgWatts, 289);
    expect(row.trainingLoad, 84);
    expect(row.movingDurationSeconds, 3600);
    expect(row.durationSeconds, 3645);
    expect(row.distanceMeters, 9530.4);
    final decoded = decodeActivityRecord(row);
    expect(decoded.samples, hasLength(3));
    expect(decoded.route, hasLength(3));
    expect(decoded.samples[1].elevation, 52);
    expect(decoded.movingDuration, const Duration(hours: 1));
    expect(
      ActivityDetailSheet(activity: row).duration(decoded.duration),
      '1h 0m 45s',
    );
  });

  test(
    'one invalid exercise does not prevent the rest from importing',
    () async {
      final broken = polarExerciseFixture()
        ..['id'] = 'bad'
        ..['heart_rate_zones'] = [
          for (var i = 0; i < 5; i++) {'index': i, 'lower_limit': 'bad'},
        ];
      final result = await service(
        exercises: [broken, polarExerciseFixture()],
      ).sync();
      expect(result.exercises, 1);
      expect(result.error, isNotNull);
      final rows = await db.select(db.activityRecords).get();
      expect(rows, hasLength(1));
      expect(rows.single.activityId, 'polar_ABC123');
    },
  );
  test(
    'an unavailable FIT export still imports the exercise and CSV data',
    () async {
      expect((await service(fitAvailable: false).sync()).exercises, 1);
      final row = (await db.select(db.activityRecords).get()).single;
      expect(row.trainingLoad, 84);
      expect(row.durationSeconds, 3645);
      expect(row.totalElevation, isNull);
      expect(decodeActivityRecord(row).samples, hasLength(3));
      // Ten seconds of samples are not moving time for a one-hour recording.
      expect(decodeActivityRecord(row).movingDuration, isNull);
    },
  );
  test('a corrupt FIT file leaves the valid API summary usable', () async {
    expect((await service(corrupt: true).sync()).exercises, 1);
    expect(
      (await db.select(db.activityRecords).get()).single.totalElevation,
      isNull,
    );
  });
  test(
    'a sparse re-sync preserves enriched values and the existing route',
    () async {
      await service().sync();
      final sparse = polarExerciseFixture()
        ..remove('samples')
        ..remove('training_load_pro')
        ..remove('training_load');
      await service(fitAvailable: false, json: sparse).sync();
      final rows = await db.select(db.activityRecords).get();
      expect(rows, hasLength(1));
      expect(rows.single.totalElevation, 20);
      expect(rows.single.movingDurationSeconds, 3600);
      expect(rows.single.trainingLoad, 84);
      expect(rows.single.avgWatts, 289);
      expect(jsonDecode(rows.single.gpxJson!), hasLength(3));
      expect(decodeActivityRecord(rows.single).samples, hasLength(3));
    },
  );
  test('moving time is not fabricated from timer duration', () async {
    await service(moving: false).sync();
    final row = (await db.select(db.activityRecords).get()).single;
    expect(row.durationSeconds, 3645);
    expect(row.movingDurationSeconds, isNull);
    expect(decodeActivityRecord(row).movingDuration, isNull);
  });

  test(
    'a trimmed recording does not inherit the old duration\'s moving time',
    () async {
      await service().sync();
      final trimmed = polarExerciseFixture()
        ..['duration'] = 'PT30M'
        ..remove('samples')
        ..remove('training_load_pro')
        ..remove('training_load');
      await service(fitAvailable: false, json: trimmed).sync();
      final row = (await db.select(db.activityRecords).get()).single;
      expect(row.durationSeconds, 1800);
      expect(row.movingDurationSeconds, isNull);
      expect(row.totalElevation, isNull);
      expect(row.avgWatts, isNull);
      expect(row.metricsJson, isNull);
      expect(row.trainingLoad, isNull);
    },
  );

  test(
    'a partial HR-only re-sync retains recorded motion and power samples',
    () async {
      await service().sync();
      final partial = polarExerciseFixture()
        ..['samples'] = [
          {'sample-type': '0', 'recording-rate': 5, 'data': '121,133,153'},
        ];
      await service(fitAvailable: false, json: partial).sync();
      final row = (await db.select(db.activityRecords).get()).single;
      final samples = decodeActivityRecord(row).samples;
      expect(samples, hasLength(3));
      expect(samples[1].heartRate, 133);
      expect(samples[1].distanceMeters, 12.5);
      expect(samples[1].speed, 2.5);
      expect(samples[1].elevation, 52);
      expect(samples[1].power, 289);
      expect(row.avgWatts, 289);
      expect(row.totalElevation, 20);
    },
  );
  test(
    'higher-priority recordings are respected before enrichment requests',
    () async {
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'garmin',
              name: 'Run',
              type: 'running',
              startDate: DateTime.utc(2026, 10, 25, 14, 28),
              durationSeconds: 3645,
              source: const Value('garmin_api'),
            ),
          );
      expect((await service().sync()).exercises, 0);
      expect(await db.select(db.activityRecords).get(), hasLength(1));
    },
  );
}
