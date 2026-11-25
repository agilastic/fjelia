import 'package:drift/drift.dart';
import 'package:fjelia_service/fjelia_service.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../services/hr_zone_summary_service.dart';
import 'package:fjelia_core/services/workout_semantics.dart';
import 'database_provider.dart';

/// FjeliaPro heart-rate zone trends; unavailable in builds without Pro.
final hrZoneTrends = createHrZoneTrends();

/// How far back the trends read: twelve months and the window before the
/// first of them.
const _trendDays = 400;

/// Every workout's kept time in zones, after computing the missing ones.
final hrZoneWorkoutsProvider = FutureProvider.autoDispose<List<HrZoneWorkout>>((
  ref,
) async {
  final service = HrZoneSummaryService(ref.watch(databaseProvider));
  final since = DateTime.now().subtract(const Duration(days: _trendDays));
  await service.update(since: since);
  return service.workouts(since: since);
});

/// The athlete's zone definitions per sport, oldest first: the bpm limits
/// each workout was computed with.
final hrZoneDefinitionsProvider =
    FutureProvider.autoDispose<List<HrZoneDefinition>>((ref) async {
      ref.watch(hrZoneWorkoutsProvider);
      final db = ref.watch(databaseProvider);
      return (db.select(db.hrZoneDefinitions)..orderBy([
            (t) => OrderingTerm.asc(t.effectiveFrom),
            (t) => OrderingTerm.asc(t.id),
          ]))
          .get();
    });

/// The plan's sessions as the planned-against-recorded comparison sees them.
final hrZonePlannedProvider =
    FutureProvider.autoDispose<List<PlannedZoneSession>>((ref) async {
      final db = ref.watch(databaseProvider);
      final now = DateTime.now();
      final rows =
          await (db.select(db.trainingSessions)..where(
                (t) => t.sessionDate.isBetweenValues(
                  now.subtract(const Duration(days: _trendDays)),
                  now.add(const Duration(days: 14)),
                ),
              ))
              .get();
      final today = DateTime(now.year, now.month, now.day);
      return [for (final s in rows) plannedZoneSession(s, today: today)];
    });

/// One planned session: its zone time from the steps' heart-rate zones, or
/// why it cannot be compared with heart rate. Missed: past and not done, or
/// skipped; it is not zero intensity, it is not there.
PlannedZoneSession plannedZoneSession(
  TrainingSession s, {
  required DateTime today,
}) {
  final family = HrZoneSummaryService.sportFamily(s.sport);
  final day = DateTime(
    s.sessionDate.year,
    s.sessionDate.month,
    s.sessionDate.day,
  );
  final done = s.status == 'completed';
  final missed =
      s.status == 'skipped' ||
      (!done && day.isBefore(today) && s.status != 'cancelled');
  PlanZoneGap? gap;
  List<double>? zones;
  if (family == null) {
    gap = PlanZoneGap.notEndurance;
  } else if (family == 'swimming') {
    gap = PlanZoneGap.pace;
  } else if (s.targetMetric == 'power') {
    // No documented conversion from power targets to heart-rate zones.
    gap = PlanZoneGap.power;
  } else {
    final seconds = WorkoutSemantics.of(
      s.stepsJson,
      sport: s.sport,
    ).zoneSeconds;
    if (seconds.isEmpty) {
      gap = PlanZoneGap.noHrTargets;
    } else {
      zones = [
        for (var z = 1; z <= hrZoneCount; z++)
          (seconds[z] ?? 0) + (z == hrZoneCount ? seconds[6] ?? 0 : 0),
      ];
    }
  }
  return PlannedZoneSession(
    sessionId: s.id,
    sport: family ?? s.sport,
    date: day,
    plannedSeconds: s.plannedDurationMin * 60.0,
    zoneSeconds: zones,
    gap: gap,
    done: done,
    missed: missed,
    phase: s.phase,
  );
}
