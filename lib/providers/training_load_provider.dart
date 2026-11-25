import 'package:drift/drift.dart';
import 'package:fjelia_core/services/training_load.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';
import 'day_data_provider.dart';

export 'package:fjelia_core/services/training_load.dart';

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
