import '../models/heart_rate_summary.dart';

import 'package:health/health.dart';

import 'health_connect_provider.dart';

import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../models/heart_rate.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';
import '../models/chart_point.dart';

final hrActivitiesProvider =
    FutureProvider.family<List<ActivityRecord>, DateTime>((ref, date) {
      ref.watch(syncStatusListenerProvider);
      return ref.watch(databaseProvider).getActivitiesForDate(date);
    });

/// Preserve actual timestamps; do not infer timing from distance or duration.
List<ChartPoint> activityHeartPoints(ActivityRecord activity) {
  if (activity.metricsJson == null) return [];
  try {
    return [
      for (final s in parseTimedHeartRates(
        jsonDecode(activity.metricsJson!),
        activity.source ?? 'activity',
      ))
        ChartPoint(s.timestamp.toLocal(), s.bpm),
    ];
  } on FormatException {
    return [];
  }
}

List<ChartPoint> mergeHeartTimeline(
  List<ChartPoint> points,
  DateTime start,
  DateTime end,
) {
  final byTime = <int, ChartPoint>{};
  for (final p in points) {
    if (p.value.isFinite &&
        p.value > 0 &&
        !p.at.isBefore(start) &&
        p.at.isBefore(end)) {
      byTime.putIfAbsent(
        p.at.millisecondsSinceEpoch,
        () => ChartPoint(p.at.toLocal(), p.value),
      );
    }
  }
  return byTime.values.toList()..sort((a, b) => a.at.compareTo(b.at));
}

final timedHeartRateProvider =
    FutureProvider.family<List<ChartPoint>, ({DateTime start, DateTime end})>((
      ref,
      range,
    ) async {
      ref.watch(syncStatusListenerProvider);
      final rows = await ref
          .watch(databaseProvider)
          .getHeartRateSamples(range.start, range.end);
      return mergeHeartTimeline(
        [for (final r in rows) ChartPoint(r.measuredAt.toLocal(), r.bpm)],
        range.start,
        range.end,
      );
    });

final hrAverageHistoryProvider =
    FutureProvider.family<List<ChartPoint>, ({DateTime start, DateTime end})>((
      ref,
      range,
    ) async {
      final rows = await ref.watch(bpPeriodReadingsProvider(range).future);
      final timed = await ref.watch(timedHeartRateProvider(range).future);
      final db = ref.watch(databaseProvider);
      final activities =
          await (db.select(db.activityRecords)..where(
                (t) =>
                    t.startDate.isBiggerOrEqualValue(range.start) &
                    t.startDate.isSmallerThanValue(range.end),
              ))
              .get();
      final points = mergeHeartTimeline(
        [
          for (final r in rows)
            if (r.heartRate > 0)
              ChartPoint(r.measuredAt.toLocal(), r.heartRate.toDouble()),
          ...timed,
          for (final activity in activities) ...activityHeartPoints(activity),
        ],
        range.start,
        range.end,
      );
      final groups = <DateTime, List<ChartPoint>>{};
      for (final p in points) {
        final d = p.at.toLocal();
        groups.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(p);
      }
      return [
        for (final e in groups.entries)
          if (HeartRateStatistics.fromPoints(e.value).average
              case final double average)
            ChartPoint(e.key, average),
      ]..sort((a, b) => a.at.compareTo(b.at));
    });

final hrRestingHistoryProvider =
    FutureProvider.family<List<ChartPoint>, ({DateTime start, DateTime end})>((
      ref,
      range,
    ) async {
      ref.watch(syncStatusListenerProvider);
      final db = ref.watch(databaseProvider);
      final rows =
          await (db.select(db.hrvRecords)..where(
                (t) =>
                    t.date.isBiggerOrEqualValue(range.start) &
                    t.date.isSmallerThanValue(range.end),
              ))
              .get();
      return [
        for (final r in rows)
          if (r.restingHeartRate != null)
            ChartPoint(r.date, r.restingHeartRate!.toDouble()),
      ]..sort((a, b) => a.at.compareTo(b.at));
    });
final heartTimelineProvider = FutureProvider.family<List<ChartPoint>, DateTime>(
  (ref, date) async {
    ref.watch(syncStatusListenerProvider);
    final bp = await ref.watch(bpForDateProvider(date).future);
    final activities = await ref.watch(hrActivitiesProvider(date).future);
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day + 1);
    final stored = await ref.watch(
      timedHeartRateProvider((start: start, end: end)).future,
    );
    final recovered = <ChartPoint>[
      for (final r in bp)
        if (r.heartRate > 0)
          ChartPoint(r.measuredAt.toLocal(), r.heartRate.toDouble()),
      ...stored,
      for (final a in activities) ...activityHeartPoints(a),
    ];
    if (!(ref.watch(healthConnectPermissionProvider).valueOrNull ?? false)) {
      return mergeHeartTimeline(recovered, start, end);
    }
    try {
      final h = Health();
      await h.configure();
      final points = await h.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: start.add(const Duration(days: 1)),
      );
      return mergeHeartTimeline(
        [
          ...recovered,
          for (final p in points)
            if (p.value is NumericHealthValue)
              ChartPoint(
                p.dateFrom,
                (p.value as NumericHealthValue).numericValue.toDouble(),
              ),
        ],
        start,
        end,
      );
    } catch (_) {
      return mergeHeartTimeline(recovered, start, end);
    }
  },
);

final heartRateDaySummaryProvider =
    FutureProvider.family<HeartRateDaySummary, DateTime>((ref, date) async {
      final points = await ref.watch(heartTimelineProvider(date).future);
      final activities = await ref.watch(hrActivitiesProvider(date).future);
      final hrv = await ref.watch(hrvForDateProvider(date).future);
      return HeartRateDaySummary(
        points: points,
        resting: hrv?.restingHeartRate,
        activities: [
          for (final a in activities)
            ActivityTimelineSpan(
              id: a.activityId,
              name: a.name,
              startDate: a.startDate,
              durationSeconds: a.durationSeconds,
              avgHeartRate: a.avgHeartRate,
            ),
        ],
      );
    });
