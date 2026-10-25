import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';
import 'day_data_provider.dart' show scheduledWorkoutsProvider;
import 'planner_providers.dart';

/// Ends the active plan when the last goal is gone (deleted, cancelled or
/// behind us): there is nothing left to prepare for, so its planned sessions
/// and their watch entries go, and the plan stops being the active one.
/// Returns whether a plan was ended. Changed goals, by contrast, rebuild the
/// plan at the next morning check or when the athlete regenerates.
final retirePlanWithoutGoalsProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    final goals = await ref.read(raceGoalServiceProvider).resolveGoalSet();
    if (!goals.isEmpty) return false;
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
