import '../services/plan_session_actions.dart';
import 'day_data_provider.dart' show syncStatusListenerProvider;
import '../services/race_predictor.dart';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../services/athlete_thresholds_service.dart';
import '../services/post_workout_scorer.dart';
import '../services/race_goal_service.dart';
import '../services/season/goal_set.dart';
import '../services/season/season_report.dart';
import '../services/training_plan_service.dart';
import '../services/workout_template_library.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'user_profile_provider.dart';
import 'workout_providers_provider.dart';

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

/// Every goal the season carries; what planning reads.
final goalSetProvider = FutureProvider<GoalSet>((ref) {
  ref.watch(syncStatusListenerProvider);
  return ref.watch(raceGoalServiceProvider).resolveGoalSet();
});

/// The goal shown as the plan's own; see [goalSetProvider] for all of them.
final primaryRaceGoalProvider = FutureProvider<RaceGoal?>((ref) {
  ref.watch(syncStatusListenerProvider);
  return ref.watch(raceGoalServiceProvider).getPrimaryGoal();
});

/// Rows of every goal still to come, the plan's own first.
final seasonGoalsProvider = FutureProvider<List<RaceGoal>>((ref) async {
  final set = await ref.watch(goalSetProvider.future);
  final rows = {
    for (final g in await ref.watch(raceGoalServiceProvider).getAll()) g.id: g,
  };
  final ordered = [
    if (set.display != null) set.display!,
    ...set.active.where((g) => g.id != set.display?.id),
  ];
  return [
    for (final g in ordered)
      if (rows[g.id] != null) rows[g.id]!,
  ];
});

/// What the season planner decided for the active plan: outcome, conflicts
/// and trade-offs. Null before a plan exists.
final seasonReportProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  // Read again whenever the plan is rebuilt.
  ref.watch(upcomingSessionsProvider);
  final db = ref.watch(databaseProvider);
  final plan =
      await (db.select(db.trainingPlans)
            ..where(
              (t) => t.athleteId.equals('self') & t.status.equals('active'),
            )
            ..limit(1))
          .getSingleOrNull();
  return SeasonReport.decode(plan?.seasonJson);
});

final workoutTemplateLibraryProvider = Provider<WorkoutTemplateLibrary>(
  (ref) => WorkoutTemplateLibrary(ref.watch(databaseProvider)),
);

final trainingPlanServiceProvider = Provider<TrainingPlanService>((ref) {
  // Rides start on the metric chosen last (watts indoors); each ride can be
  // switched in its sheet.
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return TrainingPlanService(
    ref.watch(databaseProvider),
    ref.watch(workoutProvidersProvider),
    usesPower: (sport, indoor) =>
        sport.startsWith('cycl') &&
        (profile?.powerOnBike(indoor: indoor) ?? false),
  );
});

final postWorkoutScorerProvider = Provider<PostWorkoutScorer>(
  (ref) => PostWorkoutScorer(ref.watch(databaseProvider)),
);

/// Future planned, adapted or cancelled sessions in active plans. The plan
/// list uses the same full horizon as the month calendar; a cancelled session
/// stays in the list, marked, so the plan shows what was dropped.
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
  return (db.select(db.trainingSessions)
        ..where(
          (t) =>
              t.planId.isIn(active.map((p) => p.id)) &
              t.sessionDate.isBiggerOrEqualValue(today) &
              (t.status.equals('planned') |
                  t.status.equals('adapted') |
                  t.status.equals('skipped')),
        )
        ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)]))
      .get();
});

/// What the athlete's recent running predicts for the race: an estimate that
/// never replaces the target time they set.
final raceFinishEstimateProvider = FutureProvider.family<int?, RaceGoal>((
  ref,
  goal,
) {
  ref.watch(syncStatusListenerProvider);
  return RacePredictor.estimateFinish(ref.watch(databaseProvider), goal);
});

final planSessionActionsProvider = Provider<PlanSessionActions>(
  (ref) => PlanSessionActions(
    ref.watch(databaseProvider),
    ref.watch(workoutProvidersProvider),
  ),
);
final raceGoalImportProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    await ref
        .read(raceGoalServiceProvider)
        .syncFromGarmin(ref.read(garminClientProvider));
    ref.invalidate(upcomingRaceGoalsProvider);
    ref.invalidate(primaryRaceGoalProvider);
    ref.invalidate(goalSetProvider);
  },
);

/// Why sessions were skipped, by session id: the reason the athlete chose or
/// the readiness check gave.
final sessionSkipReasonsProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  ref.watch(syncStatusListenerProvider);
  final db = ref.watch(databaseProvider);
  return {
    for (final a in await (db.select(
      db.sessionActuals,
    )..where((t) => t.skipReason.isNotNull())).get())
      a.sessionId: a.skipReason!,
  };
});

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
