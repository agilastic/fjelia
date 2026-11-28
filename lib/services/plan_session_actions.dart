import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../l10n/l10n_ext.dart';
import '../l10n/plan_text.dart' show absenceKindLabel;
import 'package:fjelia_views/fjelia_views.dart'
    show
        AbsenceRefused,
        DoneRefused,
        EventDayRefused,
        PlanEdits,
        PlanEditRefused,
        PlanShiftRefused;
import 'workout_providers/workout_providers.dart';
import 'workout_replacement_service.dart';

class PlanSessionActions {
  PlanSessionActions(this.db, this.providers);
  final AppDatabase db;
  final WorkoutProviders providers;

  /// The database part of every edit, shared with the computer.
  late final _edits = PlanEdits(db);

  Future<TrainingSession> moveDay(TrainingSession session, int days) {
    final d = session.sessionDate;
    return moveToDate(session, DateTime(d.year, d.month, d.day + days));
  }

  /// Moves a session to [day] (the date only; the steps stay as they are).
  /// The rules are fjelia_views' [PlanEdits.moveToDate]: never onto an event
  /// day, the rest day before one, or a day away.
  Future<TrainingSession> moveToDate(
    TrainingSession session,
    DateTime day,
  ) async {
    try {
      return await _edits.moveToDate(session, day);
    } on PlanEditRefused catch (e) {
      throw StateError(refusalText(e));
    }
  }

  /// Turns an outdoor session into its indoor form (treadmill, trainer) or
  /// back. The steps stay; the content changed, so a platform that has the
  /// session sends it again at the next push.
  Future<TrainingSession> setIndoor(TrainingSession session, bool indoor) =>
      _edits.setIndoor(session, indoor);

  /// Sets the main target of a ride, `hr` or `power`. The steps keep their
  /// zones and the other value stays in the step note, so the same session
  /// turns into either. The content changed, so a platform that has the
  /// session sends it again at the next push.
  Future<TrainingSession> setTargetMetric(
    TrainingSession session,
    String metric,
  ) => _edits.setTargetMetric(session, metric);

  /// Skips a session. The decision is stored first, so it works without a
  /// connection; the calendar entry is released afterwards, and if that fails
  /// the entry id is kept so it can be cleaned up later.
  Future<TrainingSession> markRest(
    TrainingSession session, {
    String reason = 'Marked as rest',
  }) async {
    await _edits.markRest(session, reason: reason);
    // Releasing it from the watch calendars changes the row again.
    await releaseDeliveries(session);
    return _edits.session(session.id);
  }

  /// Skips the original session and creates a same-day replacement in another
  /// endurance sport. Time blocks and HR-zone distribution carry over, while
  /// pace/power targets are cleared and recalculated for the selected sport.
  /// Replaces the session with [preview]'s. With [remainderLabel] and a
  /// partial replacement the rest of the original is planned too, on the same
  /// day in the original sport ([WorkoutReplacementPreview.remainderSport]);
  /// both are linked to the original, so restoring it removes both.
  Future<TrainingSession> replaceWithSport(
    WorkoutReplacementPreview preview, {
    String reason = replacedWithAnotherSport,
    String? remainderLabel,
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
          // The original's duration in its title would be wrong here.
          title: Value(
            '$sportLabel · '
            '${session.title.replaceFirst(RegExp(r'\s*\(\d+\s*min\)$'), '')}',
          ),
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
      if (remainderLabel != null && preview.isPartial) {
        await db
            .into(db.trainingSessions)
            .insert(
              replacement.copyWith(
                id: Value(const Uuid().v4()),
                sport: Value(preview.remainderSport),
                title: Value(
                  '$remainderLabel · '
                  '${session.title.replaceFirst(RegExp(r'\s*\(\d+\s*min\)$'), '')}',
                ),
                plannedDurationMin: Value(preview.remainderMin),
                plannedTrimp: Value(preview.remainderLoad),
                stepsJson: Value(preview.remainderStepsJson),
                // The rest is easy volume; the hard part went with the
                // replacement.
                primaryZone: Value(session.primaryZone.clamp(1, 2)),
              ),
            );
      }
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
/// Stored when rest is chosen instead of a suggested sport change.
const restInsteadOfReplacement = 'Rest recommended for replacement';

/// Stored on the original when another sport replaces it.
const replacedWithAnotherSport = 'Replaced with another sport';

const skipReasons = [
  'Illness',
  'Injury or pain',
  'Fatigue',
  'No time',
  'Travel',
  'Conditions',
  'My choice',
];

/// A refused plan edit in the app's words.
String refusalText(PlanEditRefused e) => switch (e) {
  EventDayRefused(:final event) =>
    'That day belongs to $event. Pick another day.',
  AbsenceRefused(:final kind) => tr.moveIntoAbsence(absenceKindLabel(tr, kind)),
  DoneRefused() => 'That workout is already done.',
  PlanShiftRefused(:final reason) => refusalText(reason),
};
