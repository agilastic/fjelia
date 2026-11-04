import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  final day = DateTime(2026, 11, 4);
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  SleepRecordsCompanion night(String source, int minutes, {double? score}) =>
      SleepRecordsCompanion(
        date: Value(day),
        totalSleepSeconds: Value(minutes * 60),
        deepSleepSeconds: Value(minutes > 0 ? 114 * 60 : 0),
        lightSleepSeconds: const Value(0),
        remSleepSeconds: const Value(0),
        awakeSleepSeconds: const Value(0),
        sleepScore: Value(score),
        source: Value(source),
      );

  test('an empty Apple Health night does not hide the COROS night', () async {
    await db.upsertSleep(night('health_connect', 0));
    await db.upsertSleep(night('coros', 387, score: 91));
    final r = (await db.getSleepForDate(day))!;
    expect(r.totalSleepSeconds, 387 * 60);
    expect(r.deepSleepSeconds, 114 * 60);
    expect(r.sleepScore, 91);
  });

  test('a real Apple Health night still comes first', () async {
    await db.upsertSleep(night('health_connect', 400));
    await db.upsertSleep(night('coros', 387, score: 91));
    final r = (await db.getSleepForDate(day))!;
    expect(r.totalSleepSeconds, 400 * 60);
    // A value Health did not have is taken from COROS.
    expect(r.sleepScore, 91);
  });
}
