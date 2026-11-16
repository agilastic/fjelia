import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import '../db/database.dart';
import '../services/absence_service.dart';
import '../services/replan_triggers.dart';
import '../services/strength/strength_templates.dart';
import 'database_provider.dart';
import 'day_data_provider.dart' show scheduledWorkoutsProvider;
import 'missed_workout_provider.dart' show missedWorkoutReminderProvider;
import 'planner_providers.dart';
import 'user_profile_provider.dart';
import 'workout_generation_provider.dart' show planAthleteOf;

/// True when the active plan was built for other rest or strength days than
/// the ones now set.
final planScheduleOutdatedProvider = FutureProvider<bool>((ref) async {
  ref.watch(upcomingSessionsProvider);
  final profile = await ref.watch(userProfileProvider.future);
  final db = ref.watch(databaseProvider);
  final plan =
      await (db.select(db.trainingPlans)
            ..where(
              (t) => t.athleteId.equals('self') & t.status.equals('active'),
            )
            ..limit(1))
          .getSingleOrNull();
  if (plan == null) return false;
  return scheduleChanged(
    planRestDaysJson: plan.restDaysJson,
    planStrengthDaysJson: plan.strengthDaysJson,
    restDays: profile.planRestDays,
    strengthDays: profile.preferredStrengthDays,
  );
});

/// True when the active plan still has upcoming strength sessions from
/// before the goal-driven programme; a replan gives them the race focus and
/// every strength day. Read afresh whenever a screen shows it, and dropped
/// by every replan; it does not follow the upcoming list, which refreshes
/// faster than a large plan can be checked.
final strengthProgrammeOutdatedProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  final plan =
      await (db.select(db.trainingPlans)
            ..where(
              (t) => t.athleteId.equals('self') & t.status.equals('active'),
            )
            ..limit(1))
          .getSingleOrNull();
  if (plan == null) return false;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sessions =
      await (db.select(db.trainingSessions)..where(
            (t) =>
                t.planId.equals(plan.id) &
                t.sport.equals('strength') &
                t.status.isIn(const ['planned', 'adapted']) &
                t.sessionDate.isBiggerOrEqualValue(today),
          ))
          .get();
  return sessions.any(
    (s) => isLegacyStrengthSession(
      s.subType,
      s.phase,
      sessionNotes: s.sessionNotes,
    ),
  );
});

/// Rebuilds the future of the active plan with the strength programme.
final updateStrengthProgrammeProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    await _replanActive(ref, 'Strength sessions follow your race goals');
    ref.invalidate(strengthProgrammeOutdatedProvider);
  },
);

/// Rebuilds the future of the active plan for the schedule now set. What was
/// done, skipped or moved by the athlete stays.
final applyScheduleProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => _replanActive(ref, 'Your weekly schedule changed'),
);

/// Absences, the latest first.
final absencesProvider = FutureProvider<List<Absence>>(
  (ref) => ref.watch(databaseProvider).absenceList(),
);

final absenceServiceProvider = Provider(
  (ref) => AbsenceService(
    ref.watch(databaseProvider),
    ref.watch(planSessionActionsProvider),
  ),
);

/// Enters an absence, cancels its sessions and builds the plan around it.
final addAbsenceProvider =
    Provider<
      Future<void> Function({
        required String kind,
        required DateTime start,
        required DateTime end,
        String? note,
        bool openEnd,
      })
    >(
      (ref) =>
          ({
            required String kind,
            required DateTime start,
            required DateTime end,
            String? note,
            bool openEnd = false,
          }) async {
            await ref
                .read(absenceServiceProvider)
                .add(
                  kind: kind,
                  start: start,
                  end: end,
                  note: note,
                  openEnd: openEnd,
                );
            await _afterAbsenceChange(ref, 'Absence entered: $kind');
          },
    );

/// Carries open absences on to tomorrow; when one grew, the plan follows.
/// Run at start and whenever the app comes back.
final extendOpenAbsencesProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    if (await ref.read(absenceServiceProvider).extendOpen()) {
      await _afterAbsenceChange(ref, 'Absence goes on');
    }
  },
);

/// Fit again: the open absence ends yesterday and the plan starts easy.
final endOpenAbsenceProvider = Provider<Future<void> Function(Absence)>(
  (ref) => (absence) async {
    await ref.read(absenceServiceProvider).endOpen(absence);
    await _afterAbsenceChange(ref, 'Fit again after ${absence.kind}');
  },
);

/// Removes an absence; what it cancelled ahead is planned again.
final removeAbsenceProvider = Provider<Future<void> Function(Absence)>(
  (ref) => (absence) async {
    await ref.read(absenceServiceProvider).remove(absence);
    await _afterAbsenceChange(ref, 'Absence removed: ${absence.kind}');
  },
);

Future<void> _afterAbsenceChange(Ref ref, String reason) async {
  ref.invalidate(absencesProvider);
  await _replanActive(ref, reason);
  ref.invalidate(sessionSkipReasonsProvider);
  ref.invalidate(scheduledWorkoutsProvider);
  unawaited(ref.read(missedWorkoutReminderProvider).reconcile());
}

Future<void> _replanActive(Ref ref, String reason) async {
  final db = ref.read(databaseProvider);
  final plan =
      await (db.select(db.trainingPlans)
            ..where(
              (t) => t.athleteId.equals('self') & t.status.equals('active'),
            )
            ..limit(1))
          .getSingleOrNull();
  if (plan == null) return;
  final profile = await ref.read(userProfileProvider.future);
  await ref
      .read(trainingPlanServiceProvider)
      .replan(
        planId: plan.id,
        reason: reason,
        daysPerWeek: profile.trainingDaysPerWeek,
        restDays: profile.planRestDays,
        dayCapMinutes: profile.trainingWindows.dayCapMinutes(),
        rampTests: profile.rampTests,
        casualGoal: profile.casualGoal,
        strengthDays: profile.preferredStrengthDays,
        hoursPerWeek: profile.hoursPerWeek,
        maxSessionsPerDay: profile.maxSessionsPerDay,
        preferredSports: profile.preferredSports,
        weekStartsOnMonday: profile.weekStartsOnMonday,
        athlete: planAthleteOf(profile),
      );
  ref.invalidate(upcomingSessionsProvider);
  ref.invalidate(planScheduleOutdatedProvider);
  ref.invalidate(strengthProgrammeOutdatedProvider);
}
