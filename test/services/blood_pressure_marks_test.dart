import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/blood_pressure_chart_data.dart';
import 'package:flutter_test/flutter_test.dart';

BpMeasurement reading(DateTime at) => BpMeasurement(
  id: 0,
  measuredAt: at,
  timezone: 'UTC',
  systolic: 125,
  diastolic: 75,
  heartRate: 60,
  measurementType: 'POD',
  dayNightTag: null,
  isBedTime: null,
  isWakeUpTime: null,
);

void main() {
  final day = DateTime(2026, 10, 22);
  DateTime at(int hour, [int minute = 0]) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  List<BpVariationBucket> buckets(Iterable<int> hoursWithReadings) =>
      bpVariationBuckets(
        [for (final h in hoursWithReadings) reading(at(h, 20))],
        day,
        day.add(const Duration(days: 1)),
        BpPeriod.day,
      );

  test('hours without readings are not worn, workouts are training', () {
    final b = buckets([0, 2, 4, 12, 14, 16]);
    markBpDayBuckets(b, [
      (start: at(6), duration: const Duration(hours: 2)),
    ], at(23, 30));
    expect(b[0].mark, BpBucketMark.none);
    expect(b[1].mark, BpBucketMark.notWorn);
    expect(b[6].mark, BpBucketMark.training);
    expect(b[7].mark, BpBucketMark.training);
    expect(b[8].mark, BpBucketMark.notWorn);
    expect(b[9].mark, BpBucketMark.notWorn);
    expect(b[12].mark, BpBucketMark.none);
  });

  test('training wins over not worn and a partly covered hour counts', () {
    final b = buckets([0, 12]);
    markBpDayBuckets(b, [
      (start: at(7, 40), duration: const Duration(minutes: 30)),
    ], at(23, 30));
    expect(b[7].mark, BpBucketMark.training);
    expect(b[8].mark, BpBucketMark.training);
    expect(b[9].mark, BpBucketMark.notWorn);
  });

  test('hours that have not passed yet are not marked', () {
    final b = buckets([0, 8]);
    markBpDayBuckets(b, const [], at(12, 30));
    expect(b[10].mark, BpBucketMark.notWorn);
    expect(b[12].mark, BpBucketMark.none);
    expect(b[20].mark, BpBucketMark.none);
  });

  test('a day without any reading stays unmarked', () {
    final b = buckets([]);
    markBpDayBuckets(b, [
      (start: at(7), duration: const Duration(hours: 1)),
    ], at(23, 30));
    expect(b.every((x) => x.mark == BpBucketMark.none), isTrue);
  });
}
