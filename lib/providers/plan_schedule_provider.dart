import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/replan_triggers.dart';
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

/// Rebuilds the future of the active plan for the schedule now set. What was
/// done, skipped or moved by the athlete stays.
final applyScheduleProvider = Provider<Future<void> Function()>(
  (ref) => () async {
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
          reason: 'Your weekly schedule changed',
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
  },
);
