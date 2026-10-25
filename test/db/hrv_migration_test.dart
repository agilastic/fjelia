import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a schema-48 database: the current one with the HRV additions taken
/// away again, holding one spot reading as an older install would.
Future<File> schema48() async {
  final file = File('${Directory.systemTemp.createTempSync().path}/db.sqlite');
  final db = AppDatabase(NativeDatabase(file));
  await db.customSelect('SELECT 1').get();
  for (final index in const [
    'idx_spot_hrv_uid',
    'idx_hrv_link_measurement',
    'idx_hrv_link_primary',
    'idx_hrv_ops_pending',
  ]) {
    await db.customStatement('DROP INDEX IF EXISTS $index');
  }
  for (final table in const [
    'hrv_training_episodes',
    'hrv_episode_aliases',
    'hrv_episode_measurements',
    'hrv_episode_feedback',
    'hrv_reminder_preferences',
    'hrv_post_reminders',
    'hrv_notification_operations',
    'hrv_notification_action_receipts',
    'hrv_native_cleanups',
  ]) {
    await db.customStatement('DROP TABLE $table');
  }
  for (final column in const [
    'measurement_uid',
    'sampling_ended_at',
    'capture_started_at',
    'timezone_offset_minutes',
    'metric_kind',
    'protocol_version',
    'analysis_version',
    'quality_state',
    'quality_reasons',
    'created_at',
    'modified_at',
    'revision',
  ]) {
    await db.customStatement(
      'ALTER TABLE spot_hrv_measurements DROP COLUMN $column',
    );
  }
  await db.customStatement(
    'INSERT INTO spot_hrv_measurements (started_at, context, posture, '
    'duration_seconds, settle_seconds, device_id, device_name, rmssd_ms, '
    "sdnn_ms, mean_hr, accepted_intervals, total_intervals, coverage, rr_json) "
    "VALUES (1793000000, 'beforeTraining', 'seated', 300, 60, 'h10', "
    "'Polar H10', 52.5, 60, 61, 290, 295, .97, '[]'), "
    "(1793003600, 'afterTraining', 'seated', 300, 60, 'h10', 'Polar H10', "
    "41.0, 50, 70, 290, 295, .97, '[]')",
  );
  await db.customStatement('PRAGMA user_version = 48');
  await db.close();
  return file;
}

void main() {
  test(
    'HRV-T071 a schema-48 database keeps its readings and gains ids',
    () async {
      final file = await schema48();
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      final rows = await (db.select(
        db.spotHrvMeasurements,
      )..orderBy([(t) => OrderingTerm(expression: t.startedAt)])).get();
      expect(rows, hasLength(2));
      expect(rows[0].rmssdMs, 52.5);
      expect(rows[1].rmssdMs, 41.0);
      expect(rows.map((r) => r.measurementUid).toSet(), hasLength(2));
      for (final r in rows) {
        expect(r.measurementUid, matches(RegExp(r'^[0-9a-f-]{36}$')));
        // The end is derived and says so; the quality is never invented.
        expect(
          r.samplingEndedAt,
          r.startedAt.add(const Duration(seconds: 300)),
        );
        expect(r.qualityReasons, 'endDerivedFromDuration');
        expect(r.qualityState, 'legacyUnverified');
        expect(r.metricKind, 'rmssd');
      }
      // No episode, reminder or preference appears by itself.
      expect(await db.select(db.hrvTrainingEpisodes).get(), isEmpty);
      expect(await db.select(db.hrvPostReminders).get(), isEmpty);
      expect(await db.select(db.hrvReminderPreferences).get(), isEmpty);
      expect(
        await db
            .customSelect('PRAGMA user_version')
            .getSingle()
            .then((r) => r.read<int>('user_version')),
        49,
      );
    },
  );

  test('the uids survive another open', () async {
    final file = await schema48();
    var db = AppDatabase(NativeDatabase(file));
    final first = (await db.select(db.spotHrvMeasurements).get())
        .map((r) => r.measurementUid)
        .toSet();
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final second = (await db.select(db.spotHrvMeasurements).get())
        .map((r) => r.measurementUid)
        .toSet();
    expect(second, first);
  });

  test('the current schema matches what the migration builds', () async {
    final file = await schema48();
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();
    final tables =
        (await db
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type='table'",
                )
                .get())
            .map((r) => r.read<String>('name'))
            .toSet();
    expect(
      tables,
      containsAll([
        'hrv_training_episodes',
        'hrv_episode_aliases',
        'hrv_episode_measurements',
        'hrv_episode_feedback',
        'hrv_reminder_preferences',
        'hrv_post_reminders',
        'hrv_notification_operations',
        'hrv_notification_action_receipts',
        'hrv_native_cleanups',
      ]),
    );
  });

  test(
    'a reading belongs to one workout and has one primary per role',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final now = DateTime.utc(2026, 11, 2);
      Future<void> link(String episode, String uid, String role, String sel) =>
          db
              .into(db.hrvEpisodeMeasurements)
              .insert(
                HrvEpisodeMeasurementsCompanion.insert(
                  episodeId: episode,
                  measurementUid: uid,
                  role: role,
                  selection: sel,
                  associationMethod: 'automaticTimeline',
                  policyVersion: 'hrv-v1',
                  createdAtUtc: now,
                ),
              );
      await link('A', 'm1', 'pre', 'primary');
      await expectLater(link('B', 'm1', 'pre', 'primary'), throwsA(anything));
      await expectLater(link('A', 'm2', 'pre', 'primary'), throwsA(anything));
      await link('A', 'm3', 'post', 'primary');
      await link('A', 'm4', 'post', 'additional');
    },
  );
}
