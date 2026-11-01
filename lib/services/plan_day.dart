import 'package:drift/drift.dart';

import '../db/database.dart';

/// Whether [day] is a planned rest day: an active training plan covers it and
/// nothing is scheduled on it, neither a plan session in any state nor a
/// workout on the watch calendar. Without a plan there is no planned rest.
///
/// The Plan's upcoming list and the AI coach both ask this, so a completed or
/// cancelled session is never mistaken for a rest day.
Future<bool> isPlannedRestDay(AppDatabase db, DateTime day) async {
  final start = DateTime(day.year, day.month, day.day);
  final end = DateTime(day.year, day.month, day.day + 1);
  final plan =
      await (db.select(db.trainingPlans)
            ..where(
              (t) =>
                  t.athleteId.equals('self') &
                  t.status.equals('active') &
                  t.startDate.isSmallerThanValue(end) &
                  t.endDate.isBiggerOrEqualValue(start),
            )
            ..limit(1))
          .getSingleOrNull();
  if (plan == null) return false;
  final session =
      await (db.select(db.trainingSessions)
            ..where(
              (t) =>
                  t.athleteId.equals('self') &
                  t.sessionDate.isBiggerOrEqualValue(start) &
                  t.sessionDate.isSmallerThanValue(end),
            )
            ..limit(1))
          .getSingleOrNull();
  if (session != null) return false;
  final watch =
      await (db.select(db.scheduledWorkoutRecords)
            ..where(
              (t) =>
                  t.scheduledDate.isBiggerOrEqualValue(start) &
                  t.scheduledDate.isSmallerThanValue(end),
            )
            ..limit(1))
          .getSingleOrNull();
  return watch == null;
}

/// Plan sessions of [day] in any state: planned, adapted, completed, skipped.
Future<List<TrainingSession>> sessionsOn(AppDatabase db, DateTime day) {
  final start = DateTime(day.year, day.month, day.day);
  final end = DateTime(day.year, day.month, day.day + 1);
  return (db.select(db.trainingSessions)..where(
        (t) =>
            t.athleteId.equals('self') &
            t.sessionDate.isBiggerOrEqualValue(start) &
            t.sessionDate.isSmallerThanValue(end),
      ))
      .get();
}
