import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';
import 'day_data_provider.dart' show scheduledWorkoutsProvider;
import 'planner_providers.dart';
import 'user_profile_provider.dart';
import 'workout_generation_provider.dart';

/// After the athlete chose what a plan without a race is for: while there is
/// no race goal, a plan for it is built now, or the plan ends when they
/// chose none.
final applyCasualGoalProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    final goals = await ref.read(raceGoalServiceProvider).resolveGoalSet();
    if (!goals.isEmpty) return;
    await ref.read(retirePlanWithoutGoalsProvider)();
  },
);

/// Ends the active plan when the last goal is gone (deleted, cancelled or
/// behind us): there is nothing left to prepare for, so its planned sessions
/// and their watch entries go, and the plan stops being the active one.
/// Returns whether a plan was ended. Changed goals, by contrast, rebuild the
/// plan at the next morning check or when the athlete regenerates.
final retirePlanWithoutGoalsProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    final goals = await ref.read(raceGoalServiceProvider).resolveGoalSet();
    if (!goals.isEmpty) return false;
    // Without a race the plan follows the athlete's own aim instead.
    String? casual;
    try {
      casual = (await ref.read(userProfileProvider.future)).casualGoal;
    } catch (_) {
      // No profile to read: no plan without a race.
    }
    if (casual != null) {
      await ref.read(workoutGenerationProvider.notifier).generate();
      return false;
    }
    final db = ref.read(databaseProvider);
    final plan =
        await (db.select(db.trainingPlans)
              ..where(
                (t) => t.athleteId.equals('self') & t.status.equals('active'),
              )
              ..limit(1))
            .getSingleOrNull();
    if (plan == null) return false;
    await ref.read(trainingPlanServiceProvider).endPlan(plan.id);
    ref.invalidate(upcomingSessionsProvider);
    ref.invalidate(scheduledWorkoutsProvider);
    ref.invalidate(seasonReportProvider);
    return true;
  },
);
