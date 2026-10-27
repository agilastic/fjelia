import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/replan_triggers.dart';
import '../services/strength/strength_templates.dart';
import 'database_provider.dart';
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
    restDays: profile.restDays,
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
  return sessions.any((s) => isLegacyStrengthSession(s.subType, s.phase));
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
        restDays: profile.restDays,
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
