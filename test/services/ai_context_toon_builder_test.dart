import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/ai_context_toon_builder.dart';
import 'package:fjelia/services/open_meteo_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AiContextToonBuilder builder;
  final now = DateTime.now();
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    builder = AiContextToonBuilder(db, now: () => now);
  });
  tearDown(() => db.close());

  test('empty database produces calendar and rest day context', () async {
    final result = await builder.build(null, '', null);
    expect(result, startsWith('[Context:V4]'));
    expect(result, contains('[Range:60d,Grip:90d]'));
    expect(
      result,
      contains(
        '[TodayWorkout:Status:rest_day,GarminScheduled:0,PlanSessions:0]',
      ),
    );
    expect(RegExp('Status:rest]').allMatches(result), hasLength(14));
    expect(result, isNot(contains('NaN')));
  });

  test(
    'latest measurements win and activity private fields stay excluded',
    () async {
      await db.upsertHrv(
        HrvRecordsCompanion.insert(
          date: now.subtract(const Duration(days: 2)),
          hrvLastNight: const Value(20),
        ),
      );
      await db.upsertHrv(
        HrvRecordsCompanion.insert(date: now, hrvLastNight: const Value(60)),
      );
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'secret-id',
              name: 'Private route name',
              type: 'running',
              startDate: now,
              durationSeconds: 3600,
              distanceMeters: const Value(10000),
              gpxJson: const Value('secret-coordinates'),
              metricsJson: const Value('secret-raw-data'),
              plannedWorkoutName: const Value('Private plan name'),
              hrZonesJson: const Value('{broken'),
              trainingLoad: const Value(42),
            ),
          );
      final result = await builder.build(null, '', null);
      expect(result, contains('Night:60ms'));
      expect(result, contains('Dur:60m,DistKm:10'));
      expect(result, contains('Load:42'));
      for (final private in [
        'secret-id',
        'Private route name',
        'secret-coordinates',
        'secret-raw-data',
        'Private plan name',
      ]) {
        expect(result, isNot(contains(private)));
      }
    },
  );

  test(
    'schedule keeps both workout options without serializing names',
    () async {
      await db.upsertScheduledWorkout(
        ScheduledWorkoutRecordsCompanion.insert(
          workoutId: 'workout-id',
          scheduleId: 'schedule-id',
          name: 'Secret workout',
          sportType: 'running',
          scheduledDate: now,
          stepsJson: const Value(
            '[{"intensity":"warmup","durationValue":600,"name":"Secret step"}]',
          ),
          estimatedDurationSeconds: const Value(1800),
        ),
      );
      final result = await builder.build(null, '10km[goal]\nnext:month', null);
      expect(result, contains('Status:options_available,GarminScheduled:1'));
      expect(result, contains('PlannedSteps:warmup/10m'));
      expect(result, contains('[RaceGoals:10km goal next month]'));
      expect(result, isNot(contains('Secret')));
    },
  );

  test('weather summary contains only current day weather fields', () {
    final point = OpenMeteoPoint(
      time: now,
      temperatureC: 5,
      humidityPct: 70,
      pressureHpa: 1010,
      precipitationMm: 1,
      precipitationProbability: 80,
      windSpeedKmh: 20,
      windDirection: 180,
    );
    final result = AiContextToonBuilder.buildWeatherSummary(
      OpenMeteoResult(
        points: [point],
        sunrise: {},
        sunset: {},
        fetchedAt: now,
        rawJson: 'secret-weather-json',
        source: 'test',
      ),
      now: now,
    );
    expect(result, contains('TempNow:5°C'));
    expect(result, contains('RainChance:80%'));
    expect(result, isNot(contains('secret')));
    expect(AiContextToonBuilder.buildWeatherSummary(null), isNull);
  });
}
