import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

/// A night's totals and its stage timeline always come from one source.
void main() {
  final day = DateTime(2026, 11, 5);
  const phases =
      '[{"s":"2026-11-04T22:30:00Z","e":"2026-11-04T23:10:00Z",'
      '"p":"deep"}]';

  AppDatabase open(List<String> order) => AppDatabase(
    NativeDatabase.memory(),
    metricPriorityReader: (_) async => order,
  );

  SleepRecordsCompanion appleHealth() => SleepRecordsCompanion(
    date: Value(day),
    totalSleepSeconds: const Value(435 * 60),
    deepSleepSeconds: const Value(96 * 60),
    lightSleepSeconds: const Value(307 * 60),
    remSleepSeconds: const Value(32 * 60),
    awakeSleepSeconds: const Value(10 * 60),
    phasesJson: const Value(phases),
    source: const Value('health_connect'),
  );

  SleepRecordsCompanion coros() => SleepRecordsCompanion(
    date: Value(day),
    totalSleepSeconds: const Value(429 * 60),
    deepSleepSeconds: const Value(143 * 60),
    lightSleepSeconds: const Value(195 * 60),
    remSleepSeconds: const Value(91 * 60),
    awakeSleepSeconds: const Value(9 * 60),
    sleepScore: const Value(93),
    nightCurvesJson: const Value('{"hrv":[],"stress":[]}'),
    source: const Value('coros'),
  );

  test('COROS first: its totals, and no other watch\'s timeline', () async {
    final db = open(['coros', 'health_connect']);
    addTearDown(db.close);
    await db.upsertSleep(appleHealth());
    await db.upsertSleep(coros());
    final r = (await db.getSleepForDate(day))!;
    expect(r.deepSleepSeconds, 143 * 60);
    expect(r.remSleepSeconds, 91 * 60);
    expect(r.phasesJson, isNull);
    expect(r.nightCurvesJson, isNotNull);
    expect(r.sleepScore, 93);
  });

  test('the same, whichever syncs first', () async {
    final db = open(['coros', 'health_connect']);
    addTearDown(db.close);
    await db.upsertSleep(coros());
    await db.upsertSleep(appleHealth());
    final r = (await db.getSleepForDate(day))!;
    expect(r.deepSleepSeconds, 143 * 60);
    expect(r.phasesJson, isNull);
  });

  test('Apple Health first: its totals with its timeline', () async {
    final db = open(['health_connect', 'coros']);
    addTearDown(db.close);
    await db.upsertSleep(coros());
    await db.upsertSleep(appleHealth());
    final r = (await db.getSleepForDate(day))!;
    expect(r.deepSleepSeconds, 96 * 60);
    expect(r.remSleepSeconds, 32 * 60);
    expect(r.phasesJson, phases);
    // COROS's curves belong to COROS's night.
    expect(r.nightCurvesJson, isNull);
    // A value Apple Health does not have still comes from COROS.
    expect(r.sleepScore, 93);
  });
}
