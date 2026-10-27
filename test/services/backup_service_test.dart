import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/backup_service.dart';
import 'package:fjelia/services/renpho_ble_scale_service.dart';
import 'package:fjelia/models/calendar_activity.dart';
import 'package:fjelia/providers/activity_calendar_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/providers/planner_providers.dart';
import 'package:fjelia/models/backup_restore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late Directory dir;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dir = await Directory.systemTemp.createTemp('fjelia-backup-test');
    FlutterSecureStorage.setMockInitialValues({
      'user_profile_v1': '{"birthYear":1980}',
      'aktiia_password': 'private-password',
      'ai_coach_api_key_openai': 'private-key',
    });
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  test(
    'backup round trip preserves records and excludes credentials',
    () async {
      await db.upsertHrv(
        HrvRecordsCompanion.insert(date: DateTime(2026, 10, 19)),
      );
      final file = await BackupService(db).export(directory: dir);
      final bytes = await file.readAsBytes();
      final content =
          ZipDecoder().decodeBytes(bytes).findFile('backup.json')!.content
              as List<int>;
      final text = utf8.decode(content);
      expect(text, isNot(contains('private-password')));
      expect(text, isNot(contains('private-key')));
      await db.customStatement('DELETE FROM hrv_records');
      await BackupService(db).restore(bytes);
      expect(await db.select(db.hrvRecords).get(), hasLength(1));
      expect(
        await const FlutterSecureStorage().read(key: 'aktiia_password'),
        'private-password',
      );
    },
  );
  test(
    'nutrition intake is portable but native reminder requests are not',
    () async {
      await db
          .into(db.nutritionRecords)
          .insert(
            NutritionRecordsCompanion.insert(
              recordKey: 'intake:activity',
              kind: 'intake',
              dataJson: '{"status":"complete","noIntake":true,"entries":[]}',
              updatedAt: DateTime.now(),
            ),
          );
      await db
          .into(db.nutritionReminderRecords)
          .insert(
            NutritionReminderRecordsCompanion.insert(
              activityId: 'activity',
              token: 'old-phone',
              notificationId: 7100001,
              dueAt: DateTime.now(),
              state: 'scheduled',
            ),
          );
      final file = await BackupService(db).export(directory: dir);
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await BackupService(other).restore(await file.readAsBytes());
      expect(
        (await other.select(other.nutritionRecords).getSingle()).recordKey,
        'intake:activity',
      );
      expect(await other.select(other.nutritionReminderRecords).get(), isEmpty);
    },
  );
  test('a schema 50 JSON backup can omit the new nutrition tables', () async {
    final file = await BackupService(db).export(directory: dir);
    final backup = jsonDecode(
      utf8.decode(
        ZipDecoder()
                .decodeBytes(await file.readAsBytes())
                .findFile('backup.json')!
                .content
            as List<int>,
      ),
    ) as Map<String, dynamic>;
    backup['schema'] = 50;
    final tables = backup['tables'] as Map;
    tables.remove('nutrition_records');
    tables.remove('nutrition_reminder_records');
    final bytes = utf8.encode(jsonEncode(backup));
    final zip = ZipEncoder().encode(
      Archive()..addFile(ArchiveFile('backup.json', bytes.length, bytes)),
    );
    await BackupService(db).restore(zip);
    expect(await db.select(db.nutritionRecords).get(), isEmpty);
  });
  test(
    'a backup of the previous schema restores, newer or older ones do not',
    () async {
      await db
          .into(db.sessionActuals)
          .insert(
            SessionActualsCompanion.insert(
              sessionId: 'session',
              skipReason: const Value('Travel'),
            ),
          );
      final file = await BackupService(db).export(directory: dir);
      final original = jsonDecode(
        utf8.decode(
          ZipDecoder()
                  .decodeBytes(await file.readAsBytes())
                  .findFile('backup.json')!
                  .content
              as List<int>,
        ),
      ) as Map<String, dynamic>;

      List<int> zipOf(int schema, {bool dropNewColumn = false}) {
        final copy = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
        copy['schema'] = schema;
        if (dropNewColumn) {
          for (final row in (copy['tables']['session_actuals'] as List)) {
            (row as Map).remove('activity_id');
          }
        }
        final bytes = utf8.encode(jsonEncode(copy));
        return ZipEncoder().encode(
          Archive()..addFile(ArchiveFile('backup.json', bytes.length, bytes)),
        );
      }

      // A schema-44 backup has no activity link in its rows.
      await db.customStatement('DELETE FROM session_actuals');
      await BackupService(db).restore(zipOf(44, dropNewColumn: true));
      final restored = (await db.select(db.sessionActuals).get()).single;
      expect(restored.skipReason, 'Travel');
      expect(restored.activityId, isNull);

      await expectLater(
        BackupService(db).restore(zipOf(43)),
        throwsFormatException,
      );
      await expectLater(
        BackupService(db).restore(zipOf(db.schemaVersion + 1)),
        throwsFormatException,
      );
      // Refused backups leave the data alone.
      expect(await db.select(db.sessionActuals).get(), hasLength(1));
    },
  );
  test(
    'a schema 46 backup, without the goal table and goal columns, restores',
    () async {
      await db
          .into(db.raceGoals)
          .insert(
            RaceGoalsCompanion.insert(
              id: 'g',
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
      final file = await BackupService(db).export(directory: dir);
      final backup = jsonDecode(
        utf8.decode(
          ZipDecoder()
                  .decodeBytes(await file.readAsBytes())
                  .findFile('backup.json')!
                  .content
              as List<int>,
        ),
      ) as Map<String, dynamic>;
      backup['schema'] = 46;
      (backup['tables'] as Map).remove('plan_goals');
      for (final row in backup['tables']['race_goals'] as List) {
        (row as Map)
          ..remove('participation')
          ..remove('ambition');
      }
      final bytes = utf8.encode(jsonEncode(backup));
      final zip = ZipEncoder().encode(
        Archive()..addFile(ArchiveFile('backup.json', bytes.length, bytes)),
      );
      await db.customStatement('DELETE FROM race_goals');
      await BackupService(db).restore(zip);
      final goal = (await db.select(db.raceGoals).get()).single;
      // The old row takes the defaults: committed, ambition not said.
      expect(goal.participation, 'committed');
      expect(goal.ambition, isNull);
      expect(await db.select(db.planGoals).get(), isEmpty);
    },
  );
  group('HRV around workouts', () {
    Future<void> seedHrv() async {
      final now = DateTime.utc(2026, 11, 2, 12);
      await db
          .into(db.spotHrvMeasurements)
          .insert(
            SpotHrvMeasurementsCompanion.insert(
              startedAt: now,
              context: 'beforeTraining',
              posture: 'seated',
              durationSeconds: 300,
              settleSeconds: 60,
              deviceId: 'h10',
              deviceName: 'Polar H10',
              rmssdMs: 55,
              sdnnMs: 60,
              meanHr: 60,
              acceptedIntervals: 290,
              totalIntervals: 295,
              coverage: .97,
              rrJson: '[]',
              measurementUid: const Value('uid-1'),
              qualityState: const Value('usable'),
            ),
          );
      await db
          .into(db.hrvTrainingEpisodes)
          .insert(
            HrvTrainingEpisodesCompanion.insert(
              episodeId: 'ep-1',
              actualStartUtc: now,
              detectedAtUtc: now,
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );
      await db
          .into(db.hrvEpisodeMeasurements)
          .insert(
            HrvEpisodeMeasurementsCompanion.insert(
              episodeId: 'ep-1',
              measurementUid: 'uid-1',
              role: 'pre',
              selection: 'primary',
              associationMethod: 'userCorrection',
              policyVersion: 'hrv-v1',
              createdAtUtc: now,
            ),
          );
      await db
          .into(db.hrvReminderPreferences)
          .insert(
            HrvReminderPreferencesCompanion.insert(
              installationEpoch: 'old-epoch',
              optedIn: const Value(true),
              enabledSinceUtc: Value(now),
              updatedAtUtc: now,
            ),
          );
      await db
          .into(db.hrvPostReminders)
          .insert(
            HrvPostRemindersCompanion.insert(
              reminderId: 'r1',
              episodeId: 'ep-1',
              preMeasurementUid: 'uid-1',
              installationEpoch: 'old-epoch',
              nativeNotificationId: 7000042,
              originalDueAtUtc: now,
              nextDueAtUtc: now,
              expiresAtUtc: now,
              targetOffsetSeconds: 1800,
              desiredState: 'scheduled',
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );
    }

    Map<String, dynamic> readBackup(List<int> bytes) => jsonDecode(
      utf8.decode(
        ZipDecoder().decodeBytes(bytes).findFile('backup.json')!.content
            as List<int>,
      ),
    ) as Map<String, dynamic>;

    test('HRV-T073 facts travel, installation state does not', () async {
      await seedHrv();
      final file = await BackupService(db).export(directory: dir);
      final backup = readBackup(await file.readAsBytes());
      final tables = backup['tables'] as Map;
      expect(tables['spot_hrv_measurements'], hasLength(1));
      expect(tables['hrv_training_episodes'], hasLength(1));
      expect(tables['hrv_episode_measurements'], hasLength(1));
      // Native ids, outbox rows and receipts stay home; the keys remain.
      for (final name in [
        'hrv_post_reminders',
        'hrv_notification_operations',
        'hrv_notification_action_receipts',
        'hrv_native_cleanups',
      ]) {
        expect(tables[name], isEmpty, reason: name);
      }
      final prefs = (tables['hrv_reminder_preferences'] as List).single as Map;
      expect(prefs['opted_in'], 0);
      expect(prefs['installation_epoch'], '');
      expect(jsonEncode(backup), isNot(contains('7000042')));
    });

    test('HRV-T074 a restore keeps the facts, switches the reminder off, '
        'and journals the old native ids', () async {
      await seedHrv();
      final file = await BackupService(db).export(directory: dir);
      final bytes = await file.readAsBytes();
      var cleaned = 0;
      await BackupService(
        db,
        afterRestore: () async => cleaned++,
      ).restore(bytes);
      expect(cleaned, 1);
      expect(await db.select(db.hrvPostReminders).get(), isEmpty);
      final prefs = await db.select(db.hrvReminderPreferences).getSingle();
      expect(prefs.optedIn, isFalse);
      expect(prefs.enabledSinceUtc, isNull);
      expect(prefs.installationEpoch, isNot('old-epoch'));
      expect(prefs.installationEpoch, isNotEmpty);
      final links = await db.select(db.hrvEpisodeMeasurements).get();
      expect(links.single.measurementUid, 'uid-1');
      // The request that may still be pending on this phone is owed removal.
      final owed = await db.select(db.hrvNativeCleanups).get();
      expect(owed.map((c) => c.nativeNotificationId), [7000042]);
    });

    test(
      'HRV-T075 the same backup elsewhere keeps the ids, not the switch',
      () async {
        await seedHrv();
        final file = await BackupService(db).export(directory: dir);
        final bytes = await file.readAsBytes();
        final other = AppDatabase(NativeDatabase.memory());
        addTearDown(other.close);
        await BackupService(other).restore(bytes);
        final row = await other.select(other.spotHrvMeasurements).getSingle();
        expect(row.measurementUid, 'uid-1');
        final prefs = await other
            .select(other.hrvReminderPreferences)
            .getSingle();
        expect(prefs.optedIn, isFalse);
        expect(await other.select(other.hrvNativeCleanups).get(), isEmpty);
      },
    );

    test('HRV-T072 a schema 48 backup restores and gets ids', () async {
      await seedHrv();
      final file = await BackupService(db).export(directory: dir);
      final backup = readBackup(await file.readAsBytes());
      backup['schema'] = 48;
      final tables = backup['tables'] as Map;
      for (final name in [
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
        tables.remove(name);
      }
      for (final row in tables['spot_hrv_measurements'] as List) {
        (row as Map)
          ..remove('measurement_uid')
          ..remove('sampling_ended_at')
          ..remove('capture_started_at')
          ..remove('timezone_offset_minutes')
          ..remove('metric_kind')
          ..remove('protocol_version')
          ..remove('analysis_version')
          ..remove('quality_state')
          ..remove('quality_reasons')
          ..remove('created_at')
          ..remove('modified_at')
          ..remove('revision');
      }
      final bytes = utf8.encode(jsonEncode(backup));
      final zip = ZipEncoder().encode(
        Archive()..addFile(ArchiveFile('backup.json', bytes.length, bytes)),
      );
      await BackupService(db).restore(zip);
      final row = await db.select(db.spotHrvMeasurements).getSingle();
      expect(row.rmssdMs, 55);
      expect(row.measurementUid, matches(RegExp(r'^[0-9a-f-]{36}$')));
      // The quality of an older reading is never turned into a pass.
      expect(row.qualityState, 'legacyUnverified');
      expect(
        row.samplingEndedAt,
        row.startedAt.add(const Duration(seconds: 300)),
      );
      expect(await db.select(db.hrvPostReminders).get(), isEmpty);
    });
  });
  test('invalid backup fails before removing data', () async {
    await db.upsertHrv(
      HrvRecordsCompanion.insert(date: DateTime(2026, 10, 19)),
    );
    final payload = utf8.encode(
      jsonEncode({
        'format': 'fjelia-backup',
        'version': 1,
        'schema': db.schemaVersion,
        'tables': {},
        'settings': {},
      }),
    );
    final zip = ZipEncoder().encode(
      Archive()..addFile(ArchiveFile('backup.json', payload.length, payload)),
    );
    await expectLater(BackupService(db).restore(zip), throwsFormatException);
    expect(await db.select(db.hrvRecords).get(), hasLength(1));
  });
  test(
    'original SQLite ZIP migrates schema 40 and reports import progress',
    () async {
      final sqlite = File('${dir.path}/old.sqlite');
      final original = AppDatabase(NativeDatabase(sqlite));
      try {
        await original
            .into(original.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: 'original-activity',
                name: 'Original ride',
                type: 'cycling',
                startDate: DateTime.now(),
                durationSeconds: 1200,
              ),
            );
        await original.customStatement('DROP TABLE heart_rate_samples');
        await original.customStatement('DROP TABLE summary_metric_origins');
        await original.customStatement('PRAGMA user_version = 40');
      } finally {
        await original.close();
      }
      final settings = utf8.encode(
        jsonEncode({'user_profile_v1': '{"birthYear":1981}'}),
      );
      final data = await sqlite.readAsBytes();
      final zip = ZipEncoder().encode(
        Archive()
          ..addFile(ArchiveFile('alzora_db.sqlite', data.length, data))
          ..addFile(
            ArchiveFile('fjelia_settings.json', settings.length, settings),
          ),
      );
      final progress = <BackupRestoreProgress>[];
      final result = await BackupService(db)
          .restore(zip, onProgress: progress.add);
      expect(result.activities, 1);
      expect(
        (await db.select(db.activityRecords).get()).single.name,
        'Original ride',
      );
      expect(progress.first.fraction, lessThan(1));
      expect(progress.last.fraction, 1);
      expect(progress.last.completed, progress.last.total);
      for (var i = 1; i < progress.length; i++) {
        expect(
          progress[i].fraction,
          greaterThanOrEqualTo(progress[i - 1].fraction),
        );
      }
      expect(
        await const FlutterSecureStorage().read(key: 'user_profile_v1'),
        '{"birthYear":1981}',
      );
    },
  );
  final fixture = Platform.environment['FJELIA_BACKUP_FIXTURE'];
  if (fixture != null) {
    test(
      'import provided original app backup including PLAN records',
      () async {
        final result = await BackupService(db)
            .restore(await File(fixture).readAsBytes());
        expect(result.activities, 1372);
        expect(result.plannedSessions, 194);
        expect(result.scheduledWorkouts, 2);
        expect(await db.select(db.activityRecords).get(), hasLength(1372));
        expect(await db.select(db.trainingSessions).get(), hasLength(194));
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)],
        );
        try {
          final entries = await container.read(
            planCalendarActivitiesProvider(DateTime(2026, 10)).future,
          );
          expect(entries.where((e) => e.completed), isNotEmpty);
          expect(entries.where((e) => !e.completed), isNotEmpty);
        } finally {
          container.dispose();
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }
  test(
    'restoring ZIP refreshes an already open calendar and upcoming list',
    () async {
      final source = AppDatabase(NativeDatabase.memory());
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      late List<int> bytes;
      try {
        await source
            .into(source.trainingPlans)
            .insert(
              TrainingPlansCompanion.insert(
                id: 'restored-plan',
                athleteId: 'self',
                startDate: day,
                endDate: day.add(const Duration(days: 30)),
                status: 'active',
                generatedAt: now,
              ),
            );
        await source
            .into(source.trainingSessions)
            .insert(
              TrainingSessionsCompanion.insert(
                id: 'restored-session',
                planId: 'restored-plan',
                athleteId: 'self',
                sessionDate: day,
                sessionNumber: 1,
                weekNumber: 1,
                sport: 'running',
                sessionType: 'base',
                phase: 'base',
                primaryZone: 2,
                title: 'Restored run',
                plannedDurationMin: 30,
                plannedTrimp: 40,
                sessionLevel: 1,
              ),
            );
        await source
            .into(source.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: 'history',
                name: 'Restored ride',
                type: 'cycling',
                startDate: day,
                durationSeconds: 1800,
              ),
            );
        final zip = await BackupService(source).export(directory: dir);
        bytes = await zip.readAsBytes();
      } finally {
        await source.close();
      }
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      final month = DateTime(day.year, day.month);
      final refreshed = Completer<List<CalendarActivity>>();
      final calendar = container.listen(planCalendarActivitiesProvider(month), (
        _,
        next,
      ) {
        final rows = next.valueOrNull;
        if (rows != null && rows.length == 2 && !refreshed.isCompleted) {
          refreshed.complete(rows);
        }
      });
      final upcoming = container.listen(upcomingSessionsProvider, (_, next) {});
      try {
        expect(
          await container.read(planCalendarActivitiesProvider(month).future),
          isEmpty,
        );
        expect(await container.read(upcomingSessionsProvider.future), isEmpty);
        await BackupService(db).restore(bytes);
        container.read(syncStatusListenerProvider.notifier).state++;
        final entries = await refreshed.future.timeout(
          const Duration(seconds: 3),
        );
        expect(
          entries.map((e) => e.title),
          containsAll(['Restored run', 'Restored ride']),
        );
        expect(
          (await container.read(upcomingSessionsProvider.future)).single.title,
          'Restored run',
        );
      } finally {
        calendar.close();
        upcoming.close();
        container.dispose();
      }
    },
  );
  test('Bluetooth SIG scale decoding honors units and optional fields', () {
    final metric = RenphoBleScaleService.parseWeight([
      8,
      0x20,
      0x4e,
      0xfa,
      0,
      0xd0,
      7,
    ]);
    expect(metric!.weightKg, 100);
    expect(metric.bmi, 25);
    expect(metric.heightM, 2);
    final pounds = RenphoBleScaleService.parseWeight([1, 0x20, 0x4e]);
    expect(pounds!.weightKg, closeTo(90.718474, .000001));
    expect(RenphoBleScaleService.parseWeight([0]), isNull);
  });
}
