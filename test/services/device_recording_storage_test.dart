import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/ecg.dart';
import 'package:fjelia/models/ftms.dart';
import 'package:fjelia/models/indoor_recording.dart';
import 'package:fjelia/services/ecg_storage_service.dart';
import 'package:fjelia/services/indoor_recording_service.dart';
import 'package:fjelia/services/training_ble.dart';
import 'package:fjelia/services/backup_service.dart';
import 'package:fjelia/providers/training_load_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late Directory dir;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dir = await Directory.systemTemp.createTemp('fjelia-device-recordings-');
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  IndoorCapture indoor({String? sessionId}) {
    final c = IndoorCapture(
      id: 'ftms_original',
      startedAt: DateTime.utc(2026, 11, 5, 12),
      device: const TrainingDevice(id: 'machine', name: 'Indoor bike'),
      machine: FtmsMachine.bike,
      name: 'Indoor intervals',
      sessionId: sessionId,
    );
    for (var second = 0; second <= 40; second++) {
      final at = c.startedAt.add(Duration(seconds: second));
      c.ingest(
        {'machine_distance': 1000 + second * 5, 'spd': 5, 'hr': 140, 'w': 200},
        at,
        recording: true,
      );
      c.snapshot(at, second * 1000);
    }
    return c;
  }

  test(
    'ECG import deduplicates, preserves original, and exports a lossless CSV',
    () async {
      final repo = EcgStorageService(db);
      final bytes = Uint8List.fromList(
        utf8.encode('time_ms,ecg_mv\n0,1.234\n2,-0.567\n4,0\n'),
      );
      final id = await repo.import(
        'garmin-wave.csv',
        bytes,
        at: DateTime.utc(2026),
        source: 'Garmin',
      );
      expect(
        await repo.import(
          'renamed.csv',
          bytes,
          at: DateTime.utc(2025),
          source: 'Other',
        ),
        id,
      );
      final row = await db.select(db.ecgRecordings).getSingle();
      expect(row.kind, 'waveform');
      expect(row.source, 'Garmin');
      expect(row.sampleCount, 3);
      final original = await repo.exportOriginal(row, directory: dir);
      expect(await original.readAsBytes(), bytes);
      final export = await repo.exportCsv(row, directory: dir);
      final decoded = decodeEcgImport(await export.readAsBytes());
      expect(decoded.sampleRateHz, 500);
      expect(decoded.chunks.single.microvolts, [1234, -567, 0]);
      expect(decoded.recordedAt!.isAtSameMomentAs(row.recordedAt), isTrue);
      final metadata = await repo.exportMetadataCsv(directory: dir);
      expect(await metadata.readAsString(), contains('Garmin'));
      await repo.delete(id, cacheDirectory: dir);
      expect(await original.exists(), isFalse);
      expect(await export.exists(), isFalse);
      expect(await db.select(db.ecgRecordings).get(), isEmpty);
      expect(await db.select(db.ecgSampleChunks).get(), isEmpty);
    },
  );

  test(
    'report-only imports keep PDF bytes without manufacturing waveform metrics',
    () async {
      final repo = EcgStorageService(db),
          pdf = Uint8List.fromList(ascii.encode('%PDF-1.7\nECG report\n%%EOF'));
      final id = await repo.import(
        'Garmin ECG.pdf',
        pdf,
        at: DateTime.utc(2026),
        source: 'Garmin',
      );
      final row = await db.select(db.ecgRecordings).getSingle();
      expect(row.kind, 'report');
      expect(row.sampleRateHz, isNull);
      expect(row.sampleCount, 0);
      expect(await repo.chunks(id), isEmpty);
      expect(
        await (await repo.exportOriginal(row, directory: dir)).readAsBytes(),
        pdf,
      );
      await expectLater(repo.exportCsv(row, directory: dir), throwsStateError);
    },
  );

  test(
    'stale ECG capture is retained and marked interrupted after reopening',
    () async {
      final repo = EcgStorageService(db);
      final id = await repo.begin(
        deviceId: 'h10',
        deviceName: 'Polar H10',
        rate: 130,
        resolution: 14,
      );
      await repo.append(
        id,
        [
          const EcgChunk(
            offsetUs: 0,
            microvolts: [-12, 20, 0],
            deviceLastSampleNs: 599616023171427290,
          ),
        ],
        0,
        count: 3,
        durationMs: 23,
        gaps: 0,
      );
      await repo.recoverInterrupted();
      final row = await db.select(db.ecgRecordings).getSingle();
      expect(row.status, 'interrupted');
      expect(row.sampleCount, 3);
      expect(
        (await repo.chunks(id)).single.deviceLastSampleNs,
        599616023171427290,
      );
      expect(await db.select(db.hrvRecords).get(), isEmpty);
      expect(await db.select(db.spotHrvMeasurements).get(), isEmpty);
    },
  );

  test(
    'indoor save is idempotent and contributes existing training load',
    () async {
      final repo = IndoorRecordingService(db), c = indoor();
      await repo.checkpoint(c, 'paused');
      final restored = (await repo.load(c.id))!;
      expect(restored.samples, c.samples);
      expect(restored.elapsedMs, 40000);
      await repo.save(restored, zones: [90, 110, 130, 150, 170]);
      await repo.save(restored, zones: [90, 110, 130, 150, 170]);
      final activity = await db.select(db.activityRecords).getSingle();
      expect(activity.activityId, c.id);
      expect(activity.source, 'ftms');
      expect(activity.distanceMeters, 200);
      expect(activity.avgHeartRate, 140);
      expect(activity.avgWatts, 200);
      expect(effectiveLoad(activity), greaterThan(0));
      expect(
        (await db.select(db.indoorRecordings).getSingle()).status,
        'saved',
      );
    },
  );

  test('indoor workout completes a planned session and keeps original over a cloud copy', () async {
    await db
        .into(db.trainingSessions)
        .insert(
          TrainingSessionsCompanion.insert(
            id: 'plan-session',
            planId: 'plan',
            athleteId: 'self',
            sessionDate: DateTime.utc(2026, 11, 5),
            sessionNumber: 1,
            weekNumber: 1,
            sport: 'cycling_road',
            sessionType: 'endurance',
            phase: 'base',
            primaryZone: 2,
            title: 'Indoor intervals',
            plannedDurationMin: 30,
            plannedTrimp: 20,
            sessionLevel: 1,
          ),
        );
    final c = indoor(sessionId: 'plan-session');
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'cloud-copy',
            name: 'Cloud bike ride',
            type: 'cycling',
            startDate: c.startedAt,
            durationSeconds: 40,
            source: const Value('garmin_api'),
          ),
        );
    final ecg = EcgStorageService(db);
    final ecgId = await ecg.begin(
      deviceId: 'h10',
      deviceName: 'Polar H10',
      rate: 130,
      resolution: 14,
      activityId: 'cloud-copy',
    );
    await IndoorRecordingService(db).save(c, zones: [90, 110, 130, 150, 170]);
    expect(
      (await db.select(db.trainingSessions).getSingle()).status,
      'completed',
    );
    expect((await db.select(db.sessionActuals).getSingle()).activityId, c.id);
    expect((await db.select(db.activityRecords).getSingle()).activityId, c.id);
    expect((await db.select(db.ecgRecordings).getSingle()).activityId, c.id);
    await db.deleteActivityByUser(c.id);
    expect(await db.select(db.indoorRecordings).get(), isEmpty);
    expect((await db.select(db.ecgRecordings).getSingle()).activityId, isNull);
    expect((await db.select(db.ecgRecordings).getSingle()).recordingId, ecgId);
    await expectLater(
      IndoorRecordingService(db).save(c, zones: [90, 110, 130, 150, 170]),
      throwsStateError,
    );
  });

  test('portable backup restores ECG originals, device timestamps and indoor checkpoints', () async {
    final repo = EcgStorageService(db);
    final id = await repo.begin(
      deviceId: 'h10',
      deviceName: 'Polar H10',
      rate: 130,
      resolution: 14,
    );
    await repo.append(
      id,
      [
        const EcgChunk(
          offsetUs: 0,
          microvolts: [-11, 22, 33],
          deviceLastSampleNs: 599616023171427290,
        ),
      ],
      0,
      count: 3,
      durationMs: 23,
      gaps: 0,
    );
    await repo.finish(id, interrupted: true);
    await repo.import(
      'report.pdf',
      Uint8List.fromList(ascii.encode('%PDF-1.7\nreport\n%%EOF')),
      at: DateTime.utc(2026),
      source: 'Garmin',
    );
    await IndoorRecordingService(db).checkpoint(indoor(), 'paused');
    final archive = await BackupService(db).export(directory: dir);
    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);
    await BackupService(other).restore(await archive.readAsBytes());
    expect(await other.select(other.ecgRecordings).get(), hasLength(2));
    expect(
      (await EcgStorageService(other).chunks(id)).single.deviceLastSampleNs,
      599616023171427290,
    );
    expect(
      (await IndoorRecordingService(other).load('ftms_original'))!
          .distanceMeters,
      200,
    );
    expect(
      (await other.select(other.ecgRecordings).get())
          .singleWhere((r) => r.kind == 'report')
          .originalBase64,
      isNotNull,
    );
  });

  test(
    'schema 62 backups without new recording tables still restore',
    () async {
      final backup = await BackupService(db).export(directory: dir);
      final archive = ZipDecoder().decodeBytes(await backup.readAsBytes());
      final payload = jsonDecode(
        utf8.decode(archive.findFile('backup.json')!.content as List<int>),
      ) as Map<String, dynamic>;
      payload['schema'] = 62;
      for (final table in [
        'ecg_recordings',
        'ecg_sample_chunks',
        'indoor_recordings',
      ]) {
        (payload['tables'] as Map).remove(table);
      }
      final raw = utf8.encode(jsonEncode(payload));
      await BackupService(db).restore(
        ZipEncoder().encode(
          Archive()..addFile(ArchiveFile('backup.json', raw.length, raw)),
        ),
      );
      expect(await db.select(db.ecgRecordings).get(), isEmpty);
    },
  );

  test(
    'a restore guard runs before any local recordings are replaced',
    () async {
      await IndoorRecordingService(db).checkpoint(indoor(), 'paused');
      final file = await BackupService(db).export(directory: dir);
      final guarded = BackupService(
        db,
        beforeRestore: () async {
          throw StateError('Recording in progress');
        },
      );
      await expectLater(
        guarded.restore(await file.readAsBytes()),
        throwsStateError,
      );
      expect(
        (await db.select(db.indoorRecordings).getSingle()).recordingId,
        'ftms_original',
      );
    },
  );

  test(
    'schema 62 migrates to 63 without altering existing activities',
    () async {
      final file = File('${dir.path}/migration.sqlite');
      final old = AppDatabase(NativeDatabase(file));
      await old
          .into(old.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'old',
              name: 'Existing run',
              type: 'running',
              startDate: DateTime.utc(2026),
              durationSeconds: 300,
            ),
          );
      for (final table in [
        'ecg_recordings',
        'ecg_sample_chunks',
        'indoor_recordings',
      ]) {
        await old.customStatement('DROP TABLE $table');
      }
      await old.customStatement('PRAGMA user_version = 62');
      await old.close();
      final migrated = AppDatabase(NativeDatabase(file));
      addTearDown(migrated.close);
      expect(
        (await migrated.select(migrated.activityRecords).getSingle())
            .activityId,
        'old',
      );
      expect(await migrated.select(migrated.ecgRecordings).get(), isEmpty);
      expect(await migrated.select(migrated.ecgSampleChunks).get(), isEmpty);
      expect(await migrated.select(migrated.indoorRecordings).get(), isEmpty);
      expect(
        (await migrated.customSelect('PRAGMA user_version').getSingle())
            .data
            .values
            .single,
        migrated.schemaVersion,
      );
    },
  );
}
