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
      45,
    );
    final index = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE name = 'idx_session_actuals_activity'",
        )
        .get();
    expect(index, hasLength(1));
  });
}
