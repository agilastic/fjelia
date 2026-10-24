import '../services/plan_session_actions.dart';
import 'day_data_provider.dart' show syncStatusListenerProvider;
import '../services/race_predictor.dart';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../services/athlete_thresholds_service.dart';
import '../services/post_workout_scorer.dart';
import '../services/race_goal_service.dart';
import '../services/training_plan_service.dart';
import '../services/workout_template_library.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

final athleteThresholdsServiceProvider = Provider<AthleteThresholdsService>(
  (ref) => AthleteThresholdsService(ref.watch(databaseProvider)),
);

final raceGoalServiceProvider = Provider<RaceGoalService>(
  (ref) => RaceGoalService(ref.watch(databaseProvider)),
);

final upcomingRaceGoalsProvider = FutureProvider<List<RaceGoal>>((ref) {
  ref.watch(syncStatusListenerProvider);
  return ref.watch(raceGoalServiceProvider).getUpcoming();
});

final primaryRaceGoalProvider = FutureProvider<RaceGoal?>((ref) {
  ref.watch(syncStatusListenerProvider);
  return ref.watch(raceGoalServiceProvider).getPrimaryGoal();
});

final workoutTemplateLibraryProvider = Provider<WorkoutTemplateLibrary>(
  (ref) => WorkoutTemplateLibrary(ref.watch(databaseProvider)),
);

final trainingPlanServiceProvider = Provider<TrainingPlanService>(
  (ref) => TrainingPlanService(
    ref.watch(databaseProvider),
    ref.watch(garminClientProvider),
  ),
);

final postWorkoutScorerProvider = Provider<PostWorkoutScorer>(
  (ref) => PostWorkoutScorer(ref.watch(databaseProvider)),
);

/// Planned or adapted sessions for the next 60 days.
final upcomingSessionsProvider = FutureProvider<List<TrainingSession>>((
  ref,
) async {
  ref.watch(syncStatusListenerProvider);
  final db = ref.watch(databaseProvider);
  final active =
      await (db.select(db.trainingPlans)..where(
            (t) => t.status.equals('active') & t.athleteId.equals('self'),
          ))
          .get();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final until = DateTime(today.year, today.month, today.day + 60);
  return (db.select(db.trainingSessions)
        ..where(
          (t) =>
              t.planId.isIn(active.map((p) => p.id)) &
              t.sessionDate.isBiggerOrEqualValue(today) &
              t.sessionDate.isSmallerOrEqualValue(until) &
              (t.status.equals('planned') | t.status.equals('adapted')),
        )
        ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)]))
      .get();
});

final raceFinishEstimateProvider = FutureProvider.family<int?, RaceGoal>((
  ref,
  goal,
) async {
  ref.watch(syncStatusListenerProvider);
  if (goal.targetFinishSeconds != null) return goal.targetFinishSeconds;
  if (!{'running', 'trail_running'}.contains(goal.primarySport) ||
      goal.distanceM <= 0) {
    return null;
  }
  final anchor = await RacePredictor.bestRunAnchor(ref.watch(databaseProvider));
  if (anchor == null || anchor.distM <= 0) return null;
  return RacePredictor.predict(
    anchor.timeSec,
    anchor.distM,
    goal.distanceM,
    elevationGainM: goal.elevationM,
  );
});

final planSessionActionsProvider = Provider<PlanSessionActions>(
  (ref) => PlanSessionActions(
    ref.watch(databaseProvider),
    ref.watch(garminClientProvider),
  ),
);
final raceGoalImportProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    await ref
        .read(raceGoalServiceProvider)
        .syncFromGarmin(ref.read(garminClientProvider));
    ref.invalidate(upcomingRaceGoalsProvider);
    ref.invalidate(primaryRaceGoalProvider);
  },
);

final plannedSessionProvider = FutureProvider.family<TrainingSession?, String>((
  ref,
  id,
) {
  ref.watch(syncStatusListenerProvider);
  return (ref
          .watch(databaseProvider)
          .select(ref.watch(databaseProvider).trainingSessions)
        ..where((t) => t.id.equals(id)))
      .getSingleOrNull();
});
