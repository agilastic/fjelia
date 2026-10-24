import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';

void main() {
  final day = DateTime(2026, 10, 20);
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('partial device writes retain origins of untouched metrics', () async {
    await db.upsertHrv(
      HrvRecordsCompanion(
        date: Value(day),
        hrvLastNight: const Value(38),
        spo2: const Value(98),
        source: const Value('garmin_api'),
      ),
    );
    await db.upsertHrv(
      HrvRecordsCompanion(
        date: Value(day),
        hrvLastNight: const Value(42),
        source: const Value('hilo_ble'),
      ),
    );
    final row = (await db.getHrvForDate(day))!;
    expect(row.hrvLastNight, 42);
    expect(row.spo2, 98);
    expect(row.source, 'mixed');
    final origins = await db.getMetricOrigins('hrv_records', day);
    expect(origins['hrv_last_night']!.source, 'hilo_ble');
    expect(origins['spo2']!.source, 'garmin_api');
    expect(origins['spo2']!.quality, 'observed');
  });

  test(
    'lower priority may fill a missing field but cannot overwrite a higher one',
    () async {
      await db.upsertHrv(
        HrvRecordsCompanion(
          date: Value(day),
          hrvLastNight: const Value(42),
          source: const Value('hilo_ble'),
        ),
      );
      await db.upsertHrv(
        HrvRecordsCompanion(
          date: Value(day),
          hrvLastNight: const Value(30),
          restingHeartRate: const Value(47),
          source: const Value('garmin_api'),
        ),
      );
      final row = (await db.getHrvForDate(day))!;
      expect(row.hrvLastNight, 42);
      expect(row.restingHeartRate, 47);
      final origins = await db.getMetricOrigins('hrv_records', day);
      expect(origins['hrv_last_night']!.source, 'hilo_ble');
      expect(origins['resting_heart_rate']!.source, 'garmin_api');
    },
  );

  test('configured priority is applied per metric', () async {
    final custom = AppDatabase(
      NativeDatabase.memory(),
      metricPriorityReader: (_) async => ['polar', 'garmin_api'],
    );
    await custom.upsertHrv(
      HrvRecordsCompanion(
        date: Value(day),
        hrvLastNight: const Value(40),
        source: const Value('garmin_api'),
      ),
    );
    await custom.upsertHrv(
      HrvRecordsCompanion(
        date: Value(day),
        hrvLastNight: const Value(44),
        source: const Value('polar'),
      ),
    );
    expect((await custom.getHrvForDate(day))!.hrvLastNight, 44);
    expect(
      (await custom.getMetricOrigins(
        'hrv_records',
        day,
      ))['hrv_last_night']!.source,
      'polar',
    );
    await custom.close();
  });

  test('null candidates do not erase values or provenance and derived values are explicit', () async {
    await db.upsertHrv(
      HrvRecordsCompanion(
        date: Value(day),
        spo2: const Value(98),
        source: const Value('garmin_api'),
      ),
    );
    await db.upsertHrv(
      HrvRecordsCompanion(
        date: Value(day),
        spo2: const Value(null),
        stressLevel: const Value(0),
        source: const Value('polar'),
      ),
    );
    await db.updateHrvEnergie(day, 75);
    final row = (await db.getHrvForDate(day))!;
    expect(row.spo2, 98);
    expect(row.stressLevel, 0);
    expect(row.computedEnergie, 75);
    final origins = await db.getMetricOrigins('hrv_records', day);
    expect(origins['spo2']!.source, 'garmin_api');
    expect(origins['stress_level']!.source, 'polar');
    expect(origins['computed_energie']!.source, 'computed');
    expect(origins['computed_energie']!.quality, 'derived');
  });

  test(
    'sleep merges optional fields without deleting stages from another source',
    () async {
      await db.upsertSleep(
        SleepRecordsCompanion.insert(
          date: day,
          totalSleepSeconds: 28800,
          deepSleepSeconds: 3600,
          remSleepSeconds: 7200,
          lightSleepSeconds: 18000,
          awakeSleepSeconds: 0,
          source: const Value('garmin_api'),
        ),
      );
      await db.upsertSleep(
        SleepRecordsCompanion(
          date: Value(day),
          sleepScore: const Value(88),
          source: const Value('hilo_ble'),
        ),
      );
      expect((await db.getSleepForDate(day))!.totalSleepSeconds, 28800);
      final origins = await db.getMetricOrigins('sleep_records', day);
      expect(origins['total_sleep_seconds']!.source, 'garmin_api');
      expect(origins['sleep_score']!.source, 'hilo_ble');
    },
  );

  test('metric data and its provenance commit atomically', () async {
    await db.customStatement(
      "CREATE TRIGGER reject_origin BEFORE INSERT ON summary_metric_origins BEGIN SELECT RAISE(ABORT,'test rejection'); END",
    );
    await expectLater(
      db.upsertHrv(
        HrvRecordsCompanion(
          date: Value(day),
          spo2: const Value(98),
          source: const Value('garmin_api'),
        ),
      ),
      throwsA(anything),
    );
    expect(await db.getHrvForDate(day), isNull);
  });

  test('v41 migration preserves values and marks unrecoverable legacy origins unknown', () async {
    final dir = await Directory.systemTemp.createTemp(
      'fjelia-origin-migration',
    );
    final file = File('${dir.path}/legacy.sqlite');
    final old = AppDatabase(NativeDatabase(file));
    await old.upsertHrv(
      HrvRecordsCompanion(
        date: Value(day),
        spo2: const Value(98),
        source: const Value('garmin_api'),
      ),
    );
    await old.customStatement('DROP TABLE summary_metric_origins');
    await old.customStatement('PRAGMA user_version = 41');
    await old.close();
    final migrated = AppDatabase(NativeDatabase(file));
    expect((await migrated.getHrvForDate(day))!.spo2, 98);
    final origin = (await migrated.getMetricOrigins(
      'hrv_records',
      day,
    ))['spo2']!;
    expect(origin.source, 'unknown');
    expect(origin.quality, 'legacy_unknown');
    await migrated.close();
    await dir.delete(recursive: true);
  });
}
