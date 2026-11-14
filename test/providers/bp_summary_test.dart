import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/day_data_provider.dart';

BpMeasurement bp(int hour, int sys, int dia, {int hr = 60, int minute = 0}) =>
    BpMeasurement(
      id: hour * 100 + minute,
      measuredAt: DateTime(2026, 11, 12, hour, minute),
      timezone: 'Europe/Berlin',
      systolic: sys,
      diastolic: dia,
      heartRate: hr,
      measurementType: 'CUFF',
    );

void main() {
  final day = DateTime(2026, 11, 12);

  test('readings without a pulse do not pull the heart rate to zero', () {
    final s = buildBpSummaryFromRecords(day, [
      bp(7, 120, 80, hr: 56, minute: 1),
      bp(7, 124, 82, hr: 0, minute: 5),
      bp(19, 132, 86, hr: 64),
    ])!;
    expect(s.avgHeartRate, 60);
    expect(s.count, 3);
    expect(s.avgSystolic, closeTo(125.33, .01));
    // The 07:00 hour has one reading with and one without a pulse.
    expect(s.segments.first.heartRate, 56);
    expect(s.segments.first.count, 2);
  });

  test('only pulse-less readings give heart rate 0, not NaN', () {
    final s = buildBpSummaryFromRecords(day, [bp(7, 120, 80, hr: 0)])!;
    expect(s.avgHeartRate, 0);
    expect(s.segments.single.heartRate, 0);
  });

  test('impossible readings are left out of the day', () {
    final s = buildBpSummaryFromRecords(day, [
      bp(7, 80, 80),
      bp(8, 70, 90),
      bp(9, 118, 76),
    ])!;
    expect(s.count, 1);
    expect((s.maxSystolic, s.minDiastolic), (118, 76));
    expect(buildBpSummaryFromRecords(day, [bp(7, 80, 80)]), isNull);
  });

  group('stored readings', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('impossible readings are neither stored nor read back', () async {
      await db.insertBpMeasurements([
        BpMeasurementsCompanion.insert(
          measuredAt: DateTime(2026, 11, 12, 7),
          systolic: 120,
          diastolic: 80,
          heartRate: 60,
        ),
        BpMeasurementsCompanion.insert(
          measuredAt: DateTime(2026, 11, 12, 8),
          systolic: 80,
          diastolic: 120,
          heartRate: 60,
        ),
      ]);
      // One written before the validation existed.
      await db
          .into(db.bpMeasurements)
          .insert(
            BpMeasurementsCompanion.insert(
              measuredAt: DateTime(2026, 11, 12, 9),
              systolic: 90,
              diastolic: 90,
              heartRate: 60,
            ),
          );
      expect((await db.getBpForDate(day)).map((r) => r.systolic), [120]);
      expect(
        (await db.getBpInRange(day, day.add(const Duration(days: 1)))).length,
        1,
      );
    });
  });
}
