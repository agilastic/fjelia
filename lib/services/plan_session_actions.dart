import 'package:drift/drift.dart';
import '../db/database.dart';
import '../utils/week.dart';
import 'workout_providers/workout_providers.dart';
import 'race_goal_service.dart';

class PlanSessionActions {
  PlanSessionActions(this.db, this.providers);
  final AppDatabase db;
  final WorkoutProviders providers;
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
    // An event day, or the rest day before it, belongs to the event: no
    // session is moved onto it, whichever goal the plan shows.
    final event = (await RaceGoalService(
      db,
    ).resolveGoalSet()).eventBlocking(target);
    if (event != null) {
      throw StateError('That day belongs to ${event.name}. Pick another day.');
    }
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

  /// Sets the main target of a ride, `hr` or `power`. The steps keep their
  /// zones and the other value stays in the step note, so the same session
  /// turns into either. The content changed, so a platform that has the
  /// session sends it again at the next push.
  Future<TrainingSession> setTargetMetric(
    TrainingSession session,
    String metric,
  ) async {
    if (session.targetMetric == metric) return session;
    await (db.update(
      db.trainingSessions,
    )..where((t) => t.id.equals(session.id))).write(
      TrainingSessionsCompanion(
        targetMetric: Value(metric),
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
    await releaseDeliveries(session);
    return (db.select(
      db.trainingSessions,
    )..where((t) => t.id.equals(session.id))).getSingle();
  }

  /// Takes the session off every platform's calendar that has it, best
  /// effort: a platform that cannot be reached keeps its entry for a later
  /// attempt. The workout stays on record, so restoring the session puts it
  /// back without creating it twice.
  Future<void> releaseDeliveries(TrainingSession session) =>
      providers.releaseEverywhere(session);

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
