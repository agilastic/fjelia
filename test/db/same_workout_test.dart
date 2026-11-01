import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 10, 31, 14, 45, 20);
  const garminRide = 3 * 3600 + 47 * 60;
  const healthRide = 14857;

  group('isSameWorkout', () {
    test('a ride with pauses matches its Apple Health copy', () {
      expect(
        isSameWorkout(
          start,
          garminRide,
          'road_biking',
          start,
          healthRide,
          'cycling',
        ),
        isTrue,
      );
    });

    test('nearly identical recordings match whatever the sport', () {
      expect(
        isSameWorkout(start, 3600, 'treadmill_running', start, 3610, 'other'),
        isTrue,
      );
    });

    test('a different sport at the same time does not match', () {
      expect(
        isSameWorkout(
          start,
          garminRide,
          'cycling',
          start,
          healthRide,
          'running',
        ),
        isFalse,
      );
    });

    test('a much shorter workout at the same start does not match', () {
      expect(
        isSameWorkout(start, 3600, 'cycling', start, 7200, 'cycling'),
        isFalse,
      );
    });

    test('starts more than five minutes apart do not match', () {
      expect(
        isSameWorkout(
          start,
          garminRide,
          'cycling',
          start.add(const Duration(minutes: 6)),
          healthRide,
          'cycling',
        ),
        isFalse,
      );
    });
  });

  test('de-duplication drops the Apple Health copy of a paused ride', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: '24900000000',
            name: 'Hemmingen Radfahren',
            type: 'road_biking',
            startDate: start,
            durationSeconds: garminRide,
            source: const Value('garmin'),
          ),
        );
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'hc_${start.millisecondsSinceEpoch}',
            name: 'Ride',
            type: 'cycling',
            startDate: start,
            durationSeconds: healthRide,
            source: const Value('health_connect'),
          ),
        );
    expect(await db.deduplicateActivities(), 1);
    final left = await db.select(db.activityRecords).get();
    expect(left.single.name, 'Hemmingen Radfahren');
  });
}
