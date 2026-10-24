import 'package:drift/drift.dart';
import '../api/garmin_client.dart';
import '../db/database.dart';

class PlanSessionActions {
  PlanSessionActions(this.db, this.garmin);
  final AppDatabase db;
  final GarminClient garmin;
  Future<TrainingSession> moveDay(TrainingSession session, int days) async {
    final d = session.sessionDate;
    final target = DateTime(d.year, d.month, d.day + days);
    final plan = await (db.select(
      db.trainingPlans,
    )..where((t) => t.id.equals(session.planId))).getSingleOrNull();
    final week = plan == null
        ? session.weekNumber
        : (DateTime.utc(target.year, target.month, target.day)
                          .difference(
                            DateTime.utc(
                              plan.startDate.year,
                              plan.startDate.month,
                              plan.startDate.day,
                            ),
                          )
                          .inDays ~/
                      7 +
                  1)
              .clamp(1, 104);
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

  Future<TrainingSession> markRest(TrainingSession session) async {
    if (session.garminAlternativeId != null) {
      await garmin.unscheduleWorkout(session.garminAlternativeId!);
    }
    await db.transaction(() async {
      await (db.update(
        db.trainingSessions,
      )..where((t) => t.id.equals(session.id))).write(
        TrainingSessionsCompanion(
          status: const Value('skipped'),
          garminAlternativeId: const Value(null),
          dateModified: Value(DateTime.now()),
          modifiedBy: const Value('athlete'),
        ),
      );
      await db
          .into(db.sessionActuals)
          .insertOnConflictUpdate(
            SessionActualsCompanion.insert(
              sessionId: session.id,
              skipReason: const Value('Marked as rest'),
            ),
          );
    });
    return (db.select(
      db.trainingSessions,
    )..where((t) => t.id.equals(session.id))).getSingle();
  }
}
