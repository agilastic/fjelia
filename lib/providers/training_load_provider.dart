import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';

/// Shared visual scale; TRIMP has no fixed 250-point upper limit.
double trainingLoadScale(num? load, [num? optimalHigh]) =>
    (math.max(250, math.max(load ?? 0, optimalHigh ?? 0)) / 50).ceil() * 50.0;

const _zoneKeys = ['zone1', 'zone2', 'zone3', 'zone4', 'zone5'];
const _zoneWeights = [1.0, 1.1, 1.2, 3.1, 8.0];

/// Prefer recorded activity load; otherwise use zone-weighted minutes when HR zones are
/// stored, otherwise Banister TRIMP (rest 55, max 190 bpm); climbing adds
/// one point per 10 m.
double effectiveLoad(ActivityRecord a) => effectiveLoadFromSummary(
  durationSeconds: a.durationSeconds,
  recordedLoad: a.trainingLoad,
  elevationMeters: a.totalElevation,
  hrZonesJson: a.hrZonesJson,
  averageHeartRate: a.avgHeartRate,
);

/// The same calculation using only the scalar activity summary, so historical
/// initialization does not need years of GPS tracks and sample arrays.
double effectiveLoadFromSummary({
  required int durationSeconds,
  double? recordedLoad,
  double? elevationMeters,
  String? hrZonesJson,
  double? averageHeartRate,
}) {
  final recorded = recordedLoad;
  if (recorded != null && recorded.isFinite && recorded >= 0) return recorded;
  final minutes = durationSeconds / 60;
  if (minutes <= 0) return 0.0;
  final elevation = elevationMeters ?? 0.0;
  final climbBonus = elevation > 0 ? elevation / 10 : 0.0;

  final zonesJson = hrZonesJson;
  if (zonesJson != null) {
    final zones = jsonDecode(zonesJson) as Map<String, dynamic>;
    var load = 0.0;
    for (var i = 0; i < 5; i++) {
      final pct = (zones[_zoneKeys[i]] as num?)?.toDouble() ?? 0.0;
      load += minutes * (pct / 100) * _zoneWeights[i];
    }
    if (load > 0) return load + climbBonus;
  }

  final avgHr = averageHeartRate;
  if (avgHr != null && avgHr > 0) {
    final x = ((avgHr - 55) / 135).clamp(0.0, 1.0);
    return minutes * x * math.exp(1.92 * x) + climbBonus;
  }
  return recordedLoad ?? 0.0;
}

/// ISO-8601 (year, week) of [d].
(int, int) _isoYearWeek(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  final thursday = day.add(Duration(days: 4 - day.weekday));
  final jan4 = DateTime(thursday.year, 1, 4);
  final week1Monday = jan4.subtract(Duration(days: jan4.weekday - 1));
  final week = thursday.difference(week1Monday).inDays ~/ 7 + 1;
  return (thursday.year, week);
}

String _weekKey(DateTime d) {
  final (y, w) = _isoYearWeek(d);
  return '$y-W${w.toString().padLeft(2, '0')}';
}

String _weekLabel(DateTime d) => 'W${_isoYearWeek(d).$2}';

/// One sport's load this week vs last week.
class SportWeekLoad {
  SportWeekLoad(this.sport, [this.currentLoad = 0, this.previousLoad = 0]);

  final String sport;
  double currentLoad;
  double previousLoad;
}

typedef WeekLoad = ({
  String label,
  double load,
  double durationHours,
  double distanceKm,
  bool isCurrent,
});

/// The last 12 weeks of load, with this week's budget (previous week + 10 %).
class WeeklyLoadSummary {
  const WeeklyLoadSummary({
    required this.weeks,
    required this.currentLoad,
    required this.previousLoad,
    required this.sports,
  });

  final List<WeekLoad> weeks;
  final double currentLoad;
  final double previousLoad;
  final List<SportWeekLoad> sports;

  /// Share of the 10 %-progression limit used this week.
  double get usedFraction {
    final limit = previousLoad * 1.1;
    return limit <= 0 ? 0.0 : currentLoad / limit;
  }

  double get remaining =>
      (previousLoad * 1.1 - currentLoad).clamp(0.0, double.infinity);

  bool get nearLimit => usedFraction >= 0.9 && usedFraction < 1.0;
  bool get overLimit => usedFraction >= 1.0;
}

final weeklyTrainingLoadProvider = FutureProvider<WeeklyLoadSummary>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  ref.watch(syncStatusListenerProvider);
  final activities = await db.getActivitiesInRange(84);

  final load = <String, double>{};
  final hours = <String, double>{};
  final km = <String, double>{};
  final sportCurrent = <String, double>{};
  final sportPrevious = <String, double>{};

  final now = DateTime.now();
  final currentKey = _weekKey(now);
  final monday = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final previousKey = _weekKey(monday.subtract(const Duration(days: 1)));
  final labels = <String, String>{};

  for (final a in activities) {
    final key = _weekKey(a.startDate);
    labels[key] = _weekLabel(a.startDate);
    final l = effectiveLoad(a);
    load[key] = (load[key] ?? 0) + l;
    hours[key] = (hours[key] ?? 0) + a.durationSeconds / 3600;
    km[key] = (km[key] ?? 0) + (a.distanceMeters ?? 0) / 1000;
    if (key == currentKey) {
      sportCurrent[a.type] = (sportCurrent[a.type] ?? 0) + l;
    } else if (key == previousKey) {
      sportPrevious[a.type] = (sportPrevious[a.type] ?? 0) + l;
    }
  }
  load.putIfAbsent(currentKey, () => 0);
  hours.putIfAbsent(currentKey, () => 0);
  km.putIfAbsent(currentKey, () => 0);
  labels.putIfAbsent(currentKey, () => _weekLabel(now));

  final keys = load.keys.toList()..sort();
  final recent = keys.length > 12 ? keys.sublist(keys.length - 12) : keys;
  final weeks = recent
      .map(
        (k) => (
          label: labels[k]!,
          load: load[k] ?? 0.0,
          durationHours: hours[k] ?? 0.0,
          distanceKm: km[k] ?? 0.0,
          isCurrent: k == currentKey,
        ),
      )
      .toList();

  final sports =
      {...sportCurrent.keys, ...sportPrevious.keys}
          .map(
            (s) =>
                SportWeekLoad(s, sportCurrent[s] ?? 0, sportPrevious[s] ?? 0),
          )
          .toList()
        ..sort((a, b) => b.currentLoad.compareTo(a.currentLoad));

  return WeeklyLoadSummary(
    weeks: weeks,
    currentLoad: load[currentKey] ?? 0,
    previousLoad: load[previousKey] ?? 0,
    sports: sports,
  );
});

/// Planned vs actual load per day for the week starting [weekStart].
final plannedVsActualProvider =
    FutureProvider.family<List<({double actual, double planned})>, DateTime>((
      ref,
      weekStart,
    ) async {
      final db = ref.watch(databaseProvider);
      ref.watch(syncStatusListenerProvider);
      final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final end = start.add(const Duration(days: 6));
      final sessions =
          (await (db.select(
            db.trainingSessions,
          )..orderBy([(t) => OrderingTerm.asc(t.sessionDate)])).get()).where((
            s,
          ) {
            final d = DateTime(
              s.sessionDate.year,
              s.sessionDate.month,
              s.sessionDate.day,
            );
            return !d.isBefore(start) && !d.isAfter(end);
          }).toList();
      final activities = await db.getActivitiesInRange(14);

      final planned = List<double>.filled(7, 0);
      final actual = List<double>.filled(7, 0);
      for (final s in sessions) {
        final i = s.sessionDate.weekday - 1;
        planned[i] += s.plannedTrimp.toDouble();
      }
      for (final a in activities) {
        final d = DateTime(
          a.startDate.year,
          a.startDate.month,
          a.startDate.day,
        );
        if (d.isBefore(start) || d.isAfter(end)) continue;
        actual[a.startDate.weekday - 1] += effectiveLoad(a);
      }
      return List.generate(7, (i) => (actual: actual[i], planned: planned[i]));
    });

/// This week (Mon–Sun) and last week per weekday: indices 0–6 are last week,
/// 7–13 this week.
final weekDayLoadProvider =
    FutureProvider<
      ({List<double> distanceKm, List<double> load, List<double> timeHours})
    >((ref) async {
      final db = ref.watch(databaseProvider);
      ref.watch(syncStatusListenerProvider);
      final activities = await db.getActivitiesInRange(14);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastMonday = today.subtract(Duration(days: today.weekday - 1 + 7));

      final load = List<double>.filled(14, 0);
      final hours = List<double>.filled(14, 0);
      final km = List<double>.filled(14, 0);
      for (final a in activities) {
        final d = DateTime(
          a.startDate.year,
          a.startDate.month,
          a.startDate.day,
        );
        final idx = d.difference(lastMonday).inDays;
        if (idx < 0 || idx >= 14) continue;
        load[idx] += effectiveLoad(a);
        hours[idx] += a.durationSeconds / 3600;
        km[idx] += (a.distanceMeters ?? 0) / 1000;
      }
      return (distanceKm: km, load: load, timeHours: hours);
    });
