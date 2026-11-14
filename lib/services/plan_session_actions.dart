import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../utils/week.dart';
import 'workout_providers/workout_providers.dart';
import 'race_goal_service.dart';
import 'workout_replacement_service.dart';

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

  /// Turns an outdoor session into its indoor form (treadmill, trainer) or
  /// back. The steps stay; the content changed, so a platform that has the
  /// session sends it again at the next push.
  Future<TrainingSession> setIndoor(
    TrainingSession session,
    bool indoor,
  ) async {
    if (session.indoor == indoor) return session;
    await (db.update(
      db.trainingSessions,
    )..where((t) => t.id.equals(session.id))).write(
      TrainingSessionsCompanion(
        indoor: Value(indoor),
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

  /// Skips the original session and creates a same-day replacement in another
  /// endurance sport. Time blocks and HR-zone distribution carry over, while
  /// pace/power targets are cleared and recalculated for the selected sport.
  Future<TrainingSession> replaceWithSport(
    WorkoutReplacementPreview preview, {
    String reason = 'Replaced with another sport',
  }) async {
    final session = preview.source;
    final sport = preview.targetSport;
    final sportLabel = preview.targetLabel;
    if (!const {'planned', 'adapted'}.contains(session.status)) {
      throw StateError('Only a planned workout can be replaced.');
    }
    if (sport == session.sport) {
      throw ArgumentError.value(sport, 'sport', 'Choose another sport.');
    }
    final now = DateTime.now();
    final replacementId = const Uuid().v4();
    final replacement = session
        .toCompanion(true)
        .copyWith(
          id: Value(replacementId),
          sport: Value(sport),
          title: Value('$sportLabel · ${session.title}'),
          sessionNotes: const Value(null),
          athleteNotes: const Value(null),
          warmUp: const Value(null),
          mainSet: const Value(null),
          coolDown: const Value(null),
          plannedDurationMin: Value(preview.durationMin),
          plannedTrimp: Value(preview.targetLoad),
          stepsJson: Value(preview.stepsJson),
          hrRangesJson: const Value(null),
          paceRangesJson: const Value(null),
          powerRangesJson: const Value(null),
          targetMetric: const Value(null),
          adaptationTrigger: const Value('athlete_replacement'),
          originalSessionId: Value(session.id),
          garminWorkoutId: const Value(null),
          garminAlternativeId: const Value(null),
          multiSportWorkoutId: const Value(null),
          status: const Value('planned'),
          createdByCoach: const Value(false),
          adjustedByCoach: const Value(false),
          addedByAthlete: const Value(true),
          dateModified: Value(now),
          modifiedBy: const Value('athlete'),
        );
    await db.transaction(() async {
      await (db.update(
        db.trainingSessions,
      )..where((t) => t.id.equals(session.id))).write(
        TrainingSessionsCompanion(
          status: const Value('skipped'),
          dateModified: Value(now),
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
      await db.into(db.trainingSessions).insert(replacement);
    });
    await releaseDeliveries(session);
    return (db.select(
      db.trainingSessions,
    )..where((t) => t.id.equals(replacementId))).getSingle();
  }

  /// Takes the session off every platform's calendar that has it, best
  /// effort: a platform that cannot be reached keeps its entry for a later
  /// attempt. The workout stays on record, so restoring the session puts it
  /// back without creating it twice.
  Future<void> releaseDeliveries(TrainingSession session) =>
      providers.releaseEverywhere(session);

  /// Undoes a skip. Only a skip with a recorded reason and no completed
  /// activity is undone; the session becomes planned again.
  /// A sport replacement made from this session goes with the skip; a
  /// replacement that is already done keeps the original skipped.
  Future<TrainingSession> restore(TrainingSession session) async {
    if (session.status != 'skipped') return session;
    final replacements =
        await (db.select(db.trainingSessions)..where(
              (t) =>
                  t.originalSessionId.equals(session.id) &
                  t.adaptationTrigger.equals('athlete_replacement'),
            ))
            .get();
    for (final r in replacements) {
      final actual = await (db.select(
        db.sessionActuals,
      )..where((t) => t.sessionId.equals(r.id))).getSingleOrNull();
      if (r.status == 'completed' || actual?.completedAt != null) {
        throw StateError('The replacement workout is already done.');
      }
    }
    // Off the watch calendars first, while the delivery records still exist.
    for (final r in replacements) {
      await releaseDeliveries(r);
    }
    await db.transaction(() async {
      for (final r in replacements) {
        await (db.delete(
          db.sessionActuals,
        )..where((t) => t.sessionId.equals(r.id))).go();
        await (db.delete(
          db.trainingSessions,
        )..where((t) => t.id.equals(r.id))).go();
      }
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
