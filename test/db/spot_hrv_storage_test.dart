import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/spot_hrv.dart';
import 'package:fjelia/providers/spot_hrv_provider.dart';
import 'package:fjelia/services/spot_hrv_export.dart';

SpotHrvCapture capture() {
  final c = SpotHrvCapture(
    startedAt: DateTime(2026, 10, 23, 12),
    durationSeconds: 120,
  );
  var end = 60000;
  for (var i = 0; i < 119; i++) {
    final rr = 1000.0 + (i % 2) * 10;
    end += rr.toInt();
    c.add(H10HeartRatePacket(60, [rr], true), Duration(milliseconds: end));
  }
  return c;
}

void main() {
  test(
    'spot sessions preserve raw RR and never overwrite overnight HRV',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.upsertHrv(
        HrvRecordsCompanion.insert(
          date: DateTime(2026, 10, 23),
          hrvLastNight: const Value(42),
        ),
      );
      final c = capture();
      expect(c.analysis.reliable, true);
      await saveSpotHrv(
        db,
        capture: c,
        context: SpotHrvContext.afterTraining,
        posture: SpotHrvPosture.seated,
        deviceId: 'h10',
        deviceName: 'Polar H10',
        elapsed: const Duration(seconds: 180),
        notes: 'Ride, "easy"\nTest',
        minutesAfterTraining: 10,
      );
      final row = await db.select(db.spotHrvMeasurements).getSingle();
      expect(row.rmssdMs, closeTo(10, 1e-9));
      expect(row.totalIntervals, 119);
      expect(row.minutesAfterTraining, 10);
      expect(row.context, 'afterTraining');
      expect(row.rrJson, contains('rr_ms'));
      expect(
        (await db.getHrvForDate(DateTime(2026, 10, 23)))!.hrvLastNight,
        42,
      );
      final csv = spotHrvCsv(row);
      expect(csv, contains('polar_h10_rr'));
      expect(csv, contains('"Ride, ""easy""\nTest"'));
      expect(csv, contains('excluded_reason'));
    },
  );
  test('incomplete recordings cannot be saved', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await expectLater(
      saveSpotHrv(
        db,
        capture: capture(),
        context: SpotHrvContext.beforeTraining,
        posture: SpotHrvPosture.seated,
        deviceId: 'h10',
        deviceName: 'H10',
        elapsed: const Duration(seconds: 179),
      ),
      throwsStateError,
    );
    expect(await db.select(db.spotHrvMeasurements).get(), isEmpty);
  });
  test('v43 upgrade creates the independent spot-HRV table', () async {
    final folder = await Directory.systemTemp.createTemp(
      'fjelia-hrv-migration-',
    );
    addTearDown(() => folder.delete(recursive: true));
    final path = File('${folder.path}/db.sqlite');
    final old = AppDatabase(NativeDatabase(path));
    await old.upsertHrv(
      HrvRecordsCompanion.insert(
        date: DateTime(2026, 10, 23),
        hrvLastNight: const Value(48),
      ),
    );
    await old.customStatement('DROP TABLE spot_hrv_measurements');
    await old.customStatement('PRAGMA user_version = 43');
    await old.close();
    final db = AppDatabase(NativeDatabase(path));
    addTearDown(db.close);
    expect(await db.select(db.spotHrvMeasurements).get(), isEmpty);
    expect((await db.getHrvForDate(DateTime(2026, 10, 23)))!.hrvLastNight, 48);
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      db.schemaVersion,
    );
  });

  test('v45 upgrade adds the activity link and keeps completions', () async {
    final folder = await Directory.systemTemp.createTemp('fjelia-link-');
    addTearDown(() => folder.delete(recursive: true));
    final path = File('${folder.path}/db.sqlite');
    final old = AppDatabase(NativeDatabase(path));
    await old
        .into(old.sessionActuals)
        .insert(
          SessionActualsCompanion.insert(
            sessionId: 'done',
            executionScore: const Value(80),
          ),
        );
    await old.customStatement(
      'DROP INDEX IF EXISTS idx_session_actuals_activity',
    );
    await old.customStatement(
      'ALTER TABLE session_actuals DROP COLUMN activity_id',
    );
    await old.customStatement('PRAGMA user_version = 44');
    await old.close();
    final db = AppDatabase(NativeDatabase(path));
    addTearDown(db.close);
    final row = (await db.select(db.sessionActuals).get()).single;
    expect(row.executionScore, 80);
    expect(row.activityId, isNull);
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      db.schemaVersion,
    );
    final index = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE name = 'idx_session_actuals_activity'",
        )
        .get();
    expect(index, hasLength(1));
  });

  test(
    'v47 upgrade adds goal links and gives old plans their one goal',
    () async {
      final folder = await Directory.systemTemp.createTemp('fjelia-goals-');
      addTearDown(() => folder.delete(recursive: true));
      final path = File('${folder.path}/db.sqlite');
      final old = AppDatabase(NativeDatabase(path));
      await old
          .into(old.raceGoals)
          .insert(
            RaceGoalsCompanion.insert(
              id: 'goal',
              athleteId: 'self',
              name: 'Marathon',
              primarySport: 'running',
              distanceM: 42195,
              raceDate: DateTime(2027, 4, 10),
              priority: 'a',
              source: 'manual',
              createdAt: DateTime(2026, 10, 25),
            ),
          );
      await old
          .into(old.trainingPlans)
          .insert(
            TrainingPlansCompanion.insert(
              id: 'plan',
              athleteId: 'self',
              raceGoalId: const Value('goal'),
              startDate: DateTime(2026, 10, 25),
              endDate: DateTime(2027, 4, 10),
              status: 'active',
              generatedAt: DateTime(2026, 10, 25),
            ),
          );
      await old.customStatement('DROP TABLE plan_goals');
      for (final column in const ['participation', 'ambition']) {
        await old.customStatement('ALTER TABLE race_goals DROP COLUMN $column');
      }
      for (final column in const ['goal_set_revision', 'season_json']) {
        await old.customStatement(
          'ALTER TABLE training_plans DROP COLUMN $column',
        );
      }
      for (final column in const ['goal_id', 'goal_role', 'goal_objective']) {
        await old.customStatement(
          'ALTER TABLE training_sessions DROP COLUMN $column',
        );
      }
      await old.customStatement('PRAGMA user_version = 46');
      await old.close();

      final db = AppDatabase(NativeDatabase(path));
      addTearDown(db.close);
      final goal = (await db.select(db.raceGoals).get()).single;
      expect(goal.participation, 'committed');
      expect(goal.ambition, isNull);
      final plan = (await db.select(db.trainingPlans).get()).single;
      expect(plan.seasonJson, isNull);
      final links = await db.select(db.planGoals).get();
      expect(links.single.planId, 'plan');
      expect(links.single.goalId, 'goal');
      expect(links.single.priority, 'a');
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        db.schemaVersion,
      );
      // The shared cleanup queue and delivery record of schema 48 are there.
      expect(await db.select(db.providerCleanups).get(), isEmpty);
      expect(await db.select(db.workoutDeliveries).get(), isEmpty);
    },
  );
}
