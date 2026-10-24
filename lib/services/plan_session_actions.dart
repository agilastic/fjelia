import 'package:drift/drift.dart';
import '../api/garmin_client.dart';
import '../db/database.dart';
import '../utils/log.dart';
import '../utils/week.dart';

class PlanSessionActions {
  PlanSessionActions(this.db, this.garmin);
  final AppDatabase db;
  final GarminClient garmin;
  Future<TrainingSession> moveDay(TrainingSession session, int days) {
    final d = session.sessionDate;
    return moveToDate(session, DateTime(d.year, d.month, d.day + days));
  }

  /// Moves a session to [day] (the date only; the steps stay as they are).
  /// The first date it was planned for is kept, and the week number follows
  /// the plan's calendar weeks.
  Future<TrainingSession> moveToDate(
    TrainingSession session,
    DateTime day,
  ) async {
    final d = session.sessionDate;
    final target = DateTime(day.year, day.month, day.day);
    final plan = await (db.select(
      db.trainingPlans,
    )..where((t) => t.id.equals(session.planId))).getSingleOrNull();
    // Counted like the generator does: calendar weeks from the plan's anchor.
    final week = plan == null
        ? session.weekNumber
        : (DateTime.utc(target.year, target.month, target.day)
                          .difference(
                            DateTime.utc(
                              weekStartOf(plan.startDate).year,
                              weekStartOf(plan.startDate).month,
                              weekStartOf(plan.startDate).day,
                            ),
                          )
                          .inDays ~/
                      7 +
                  1)
              .clamp(1, 156);
    await (db.update(
      db.trainingSessions,
    )..where((t) => t.id.equals(session.id))).write(
      TrainingSessionsCompanion(
        sessionDate: Value(target),
        sessionDateOriginal: Value(
          session.sessionDateOriginal ?? d.toIso8601String(),
        ),
        priorSessionDate: Value(d.toIso8601String()),
        weekNumber: Value(week),
        isMovedFromDifferentWeek: Value(week != session.weekNumber),
        dateModified: Value(DateTime.now()),
        modifiedBy: const Value('athlete'),
      ),
    );
    return (db.select(
      db.trainingSessions,
    )..where((t) => t.id.equals(session.id))).getSingle();
  }

  /// Skips a session. The decision is stored first, so it works without a
  /// connection; the calendar entry is released afterwards, and if that fails
  /// the entry id is kept so it can be cleaned up later.
  Future<TrainingSession> markRest(
    TrainingSession session, {
    String reason = 'Marked as rest',
  }) async {
    await db.transaction(() async {
      await (db.update(
        db.trainingSessions,
      )..where((t) => t.id.equals(session.id))).write(
        TrainingSessionsCompanion(
          status: const Value('skipped'),
          dateModified: Value(DateTime.now()),
          modifiedBy: const Value('athlete'),
        ),
      );
      await db
          .into(db.sessionActuals)
          .insertOnConflictUpdate(
            SessionActualsCompanion.insert(
              sessionId: session.id,
              skipReason: Value(reason),
            ),
          );
    });
    await releaseGarminEntry(session);
    return (db.select(
      db.trainingSessions,
    )..where((t) => t.id.equals(session.id))).getSingle();
  }

  /// Takes the session off the Garmin calendar, if it is on it. A failure is
  /// logged and leaves the entry id in place for a later attempt.
  Future<void> releaseGarminEntry(TrainingSession session) async {
    final id = session.garminAlternativeId;
    if (id == null) return;
    try {
      await garmin.unscheduleWorkout(id);
      await (db.update(
        db.trainingSessions,
      )..where((t) => t.id.equals(session.id))).write(
        const TrainingSessionsCompanion(garminAlternativeId: Value(null)),
      );
    } catch (e) {
      log('[Planner] could not release Garmin entry $id: $e');
    }
  }

  /// Undoes a skip. Only a skip with a recorded reason and no completed
  /// activity is undone; the session becomes planned again.
  Future<TrainingSession> restore(TrainingSession session) async {
    if (session.status != 'skipped') return session;
    await db.transaction(() async {
      final actual = await (db.select(
        db.sessionActuals,
      )..where((t) => t.sessionId.equals(session.id))).getSingleOrNull();
      if (actual != null && actual.completedAt == null) {
        await (db.delete(
          db.sessionActuals,
        )..where((t) => t.sessionId.equals(session.id))).go();
      }
      await (db.update(
        db.trainingSessions,
      )..where((t) => t.id.equals(session.id))).write(
        TrainingSessionsCompanion(
          status: const Value('planned'),
          dateModified: Value(DateTime.now()),
          modifiedBy: const Value('athlete'),
        ),
      );
    });
    return (db.select(
      db.trainingSessions,
    )..where((t) => t.id.equals(session.id))).getSingle();
  }
}

/// Reasons offered when a session is skipped.
const skipReasons = [
  'Illness',
  'Injury or pain',
  'Fatigue',
  'No time',
  'Travel',
  'Conditions',
  'My choice',
];
