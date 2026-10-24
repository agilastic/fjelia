import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());
  test('backfilling previous day does not overwrite next midnight', () async {
    final today = DateTime(2026, 10, 19), yesterday = DateTime(2026, 10, 18);
    await db.upsertHrv(
      HrvRecordsCompanion.insert(date: today, hrvLastNight: const Value(38)),
    );
    await db.upsertHrv(
      HrvRecordsCompanion.insert(
        date: yesterday,
        hrvLastNight: const Value(50),
      ),
    );
    expect((await db.getHrvForDate(today))!.hrvLastNight, 38);
    expect((await db.getHrvForDate(yesterday))!.hrvLastNight, 50);
    expect(await db.select(db.hrvRecords).get(), hasLength(2));
    Future<void> sleep(DateTime d, int seconds) => db.upsertSleep(
      SleepRecordsCompanion.insert(
        date: d,
        totalSleepSeconds: seconds,
        deepSleepSeconds: 0,
        remSleepSeconds: 0,
        lightSleepSeconds: seconds,
        awakeSleepSeconds: 0,
      ),
    );
    await sleep(today, 20000);
    await sleep(yesterday, 24000);
    expect((await db.getSleepForDate(today))!.totalSleepSeconds, 20000);
    expect((await db.getSleepForDate(yesterday))!.totalSleepSeconds, 24000);
  });
  test('blood-pressure day excludes next midnight', () async {
    final d = DateTime(2026, 10, 19);
    await db.insertBpMeasurements([
      BpMeasurementsCompanion.insert(
        measuredAt: d,
        systolic: 120,
        diastolic: 80,
        heartRate: 60,
      ),
      BpMeasurementsCompanion.insert(
        measuredAt: DateTime(2026, 10, 20),
        systolic: 130,
        diastolic: 85,
        heartRate: 65,
      ),
    ]);
    expect(await db.getBpForDate(d), hasLength(1));
  });
}
