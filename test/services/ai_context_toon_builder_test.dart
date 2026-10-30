import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/ai_context_toon_builder.dart';
import 'package:fjelia/services/briefing_brief.dart';
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
    'scheduled Garmin workout remains planned without serializing names',
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
      expect(
        result,
        contains(
          'Status:planned,Source:garmin,SessionCount:1,GarminScheduled:1',
        ),
      );
      expect(result, contains('PlannedSteps:warmup/10m'));
      expect(result, contains('[RaceGoals:10km goal next month]'));
      expect(result, isNot(contains('Secret')));
    },
  );

  test(
    'a recorded activity does not hide two remaining planned sessions',
    () async {
      final today = DateTime(now.year, now.month, now.day);
      await db
          .into(db.trainingPlans)
          .insert(
            TrainingPlansCompanion.insert(
              id: 'p',
              athleteId: 'self',
              startDate: today,
              endDate: today.add(const Duration(days: 30)),
              status: 'active',
              generatedAt: today,
            ),
          );
      Future<void> session(
        String id,
        int number,
        String sport,
        int minutes,
        String status,
      ) => db
          .into(db.trainingSessions)
          .insert(
            TrainingSessionsCompanion.insert(
              id: id,
              planId: 'p',
              athleteId: 'self',
              sessionDate: today,
              sessionNumber: number,
              weekNumber: 1,
              sport: sport,
              sessionType: 'easy',
              phase: 'base',
              primaryZone: 2,
              title: 'Private $id',
              plannedDurationMin: minutes,
              plannedTrimp: 30,
              sessionLevel: 1,
              status: Value(status),
            ),
          )
          .then((_) {});
      await session('morning-done', 1, 'walking', 20, 'completed');
      await session('run', 2, 'running', 45, 'planned');
      await session('strength', 3, 'strength', 30, 'adapted');
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'done',
              name: 'Private activity',
              type: 'walking',
              startDate: today.add(const Duration(hours: 8)),
              durationSeconds: 1200,
            ),
          );
      final text = await builder.build(null, '', null);
      final brief = BriefingBrief.parse(text)!;
      expect(brief.done, ['walking/20']);
      expect(brief.today, ['running/45', 'strength/30']);
      expect(text, contains('Status:planned,Source:plan,SessionCount:2'));
      expect(text, isNot(contains('Status:rest_day')));
      expect(text, isNot(contains('Private')));
    },
  );

  test(
    'Garmin copies do not double count Fjelia sessions in the brief',
    () async {
      final today = DateTime(now.year, now.month, now.day);
      await db
          .into(db.trainingPlans)
          .insert(
            TrainingPlansCompanion.insert(
              id: 'p',
              athleteId: 'self',
              startDate: today,
              endDate: today.add(const Duration(days: 30)),
              status: 'active',
              generatedAt: today,
            ),
          );
      for (final entry in [(1, 'running', 45), (2, 'strength', 30)]) {
        await db
            .into(db.trainingSessions)
            .insert(
              TrainingSessionsCompanion.insert(
                id: 's${entry.$1}',
                planId: 'p',
                athleteId: 'self',
                sessionDate: today,
                sessionNumber: entry.$1,
                weekNumber: 1,
                sport: entry.$2,
                sessionType: 'easy',
                phase: 'base',
                primaryZone: 2,
                title: 'Private plan',
                plannedDurationMin: entry.$3,
                plannedTrimp: 30,
                sessionLevel: 1,
              ),
            );
      }
      await db.upsertScheduledWorkout(
        ScheduledWorkoutRecordsCompanion.insert(
          workoutId: 'mirror',
          scheduleId: 'mirror-today',
          name: 'Private mirror',
          sportType: 'running',
          scheduledDate: today,
          estimatedDurationSeconds: const Value(2700),
        ),
      );
      final first = await builder.build(null, '', null);
      expect(BriefingBrief.parse(first)!.today, ['running/45', 'strength/30']);
      expect(
        first,
        contains('SessionCount:2,GarminScheduled:1,PlanSessions:2'),
      );
      await (db.update(db.trainingSessions)..where((s) => s.id.equals('s1')))
          .write(const TrainingSessionsCompanion(status: Value('completed')));
      final after = await builder.build(null, '', null);
      expect(BriefingBrief.parse(after)!.today, ['strength/30']);
      expect(
        after,
        contains('SessionCount:1,GarminScheduled:1,PlanSessions:1'),
      );
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
