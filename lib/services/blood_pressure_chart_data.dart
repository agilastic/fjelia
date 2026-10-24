import 'dart:math' as math;

import '../db/database.dart';

enum BpPeriod { day, week, month }

/// What the blood-pressure device could and could not do during an hour.
enum BpBucketMark {
  none,

  /// A workout took place; readings are sparse or off during training.
  training,

  /// No readings although the hour has passed: the pod was not worn.
  notWorn,
}

class BpAxisRange {
  const BpAxisRange(this.minimum, this.maximum);
  final double minimum, maximum;

  factory BpAxisRange.fromValues(Iterable<num> values) {
    final finite = values
        .where((v) => v.isFinite)
        .map((v) => v.toDouble())
        .toList();
    if (finite.isEmpty) return const BpAxisRange(40, 160);
    final low = finite.reduce((a, b) => a < b ? a : b).toDouble();
    final high = finite.reduce((a, b) => a > b ? a : b).toDouble();
    final padding = math.max(5.0, (high - low) * .1);
    return BpAxisRange(
      math.max(0, ((low - padding) / 10).floor() * 10).toDouble(),
      ((high + padding) / 10).ceil() * 10.0,
    );
  }
}

class BpVariationBucket {
  BpVariationBucket(this.date, this.readings);
  final DateTime date;
  final List<BpMeasurement> readings;
  BpBucketMark mark = BpBucketMark.none;
  double average(bool systolic) =>
      readings.fold<double>(
        0,
        (sum, r) => sum + (systolic ? r.systolic : r.diastolic),
      ) /
      readings.length;
  int minimum(bool systolic) =>
      readings.map((r) => systolic ? r.systolic : r.diastolic).reduce(math.min);
  int maximum(bool systolic) =>
      readings.map((r) => systolic ? r.systolic : r.diastolic).reduce(math.max);
}

List<BpVariationBucket> bpVariationBuckets(
  List<BpMeasurement> readings,
  DateTime start,
  DateTime end,
  BpPeriod period,
) {
  final count = period == BpPeriod.day
      ? 24
      : DateTime.utc(
          end.year,
          end.month,
          end.day,
        ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
  final buckets = [
    for (var i = 0; i < count; i++)
      BpVariationBucket(
        period == BpPeriod.day
            ? DateTime(start.year, start.month, start.day, i)
            : DateTime(start.year, start.month, start.day + i),
        [],
      ),
  ];
  for (final r in readings) {
    final local = r.measuredAt.toLocal();
    if (local.isBefore(start) || !local.isBefore(end)) continue;
    final index = period == BpPeriod.day
        ? local.hour
        : DateTime.utc(
            local.year,
            local.month,
            local.day,
          ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
    if (index >= 0 && index < buckets.length) buckets[index].readings.add(r);
  }
  return buckets;
}

/// Marks the hours of a day chart: workouts as training, and hours that have
/// passed without any reading as not worn. A day without any reading is left
/// unmarked, because then nothing can be said about the pod.
void markBpDayBuckets(
  List<BpVariationBucket> buckets,
  List<({DateTime start, Duration duration})> trainings,
  DateTime now,
) {
  if (buckets.every((b) => b.readings.isEmpty)) return;
  for (final bucket in buckets) {
    final from = bucket.date;
    final to = from.add(const Duration(hours: 1));
    final training = trainings.any(
      (t) => t.start.isBefore(to) && t.start.add(t.duration).isAfter(from),
    );
    if (training) {
      bucket.mark = BpBucketMark.training;
    } else if (bucket.readings.isEmpty && !to.isAfter(now)) {
      bucket.mark = BpBucketMark.notWorn;
    }
  }
}
