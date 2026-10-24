import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
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
