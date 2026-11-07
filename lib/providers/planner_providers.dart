import '../services/plan_session_actions.dart';
import 'day_data_provider.dart'
    show syncStatusListenerProvider, scheduledWorkoutsProvider;
import '../services/plan_day.dart';
import '../services/race_predictor.dart';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import '../services/athlete_thresholds_service.dart';
import '../services/control/plan_reconciler.dart';
import '../services/post_workout_scorer.dart';
import '../services/session_adaptation_service.dart';
import '../services/race_goal_service.dart';
import '../services/season/goal_set.dart';
import '../services/season/season_report.dart';
import '../services/training_plan_service.dart';
import '../services/workout_template_library.dart';
import '../utils/log.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'user_profile_provider.dart';
import 'workout_destination_provider.dart';
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

/// Places workouts done on another day than planned, or in place of a
/// later session (the first step of the closed training loop).
final planReconcilerProvider = Provider<PlanReconciler>(
  (ref) => PlanReconciler(
    ref.watch(databaseProvider),
    ref.watch(postWorkoutScorerProvider),
    ref.watch(planSessionActionsProvider),
    SessionAdaptationService(ref.watch(databaseProvider)),
  ),
);

/// Brings the watch calendar in line with automatic plan changes: sessions
/// done or covered leave it, moved or changed ones go up again. Then the
/// plan screens read the sessions anew.
final applyPlanChangesProvider = Provider<Future<void> Function(PlanChanges)>(
  (ref) => (changes) async {
    if (changes.isEmpty) return;
    final db = ref.read(databaseProvider);
    Future<TrainingSession?> read(String id) => (db.select(
      db.trainingSessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    final actions = ref.read(planSessionActionsProvider);
    for (final id in changes.release) {
      final s = await read(id);
      if (s == null) continue;
      try {
        await actions.releaseDeliveries(s);
      } catch (e) {
        log('[Reconcile] release $id: $e');
      }
    }
    try {
      final pushers = await ref.read(pushProvidersProvider.future);
      final plans = ref.read(trainingPlanServiceProvider);
      for (final id in changes.deliver) {
        for (final p in pushers) {
          try {
            await plans.deliver(id, p);
          } catch (e) {
            log('[Reconcile] ${p.label} push $id: $e');
          }
        }
      }
    } catch (e) {
      log('[Reconcile] push: $e');
    }
    ref.invalidate(upcomingSessionsProvider);
    ref.read(syncStatusListenerProvider.notifier).update((v) => v + 1);
  },
);

/// One automatic decision and the sessions it changed.
class PlanAdjustmentGroup {
  const PlanAdjustmentGroup(this.id, this.items);
  final String id;
  final List<PlanAdjustment> items;
}

const _seenAdjustmentsKey = 'plan_adjustments_seen_v1';

/// Automatic plan changes of the last two days that are not undone or
/// put away, newest first.
final recentPlanAdjustmentsProvider = FutureProvider<List<PlanAdjustmentGroup>>(
  (ref) async {
    ref.watch(syncStatusListenerProvider);
    final db = ref.watch(databaseProvider);
    final since = DateTime.now().subtract(const Duration(days: 2));
    final rows =
        await (db.select(db.planAdjustments)
              ..where(
                (t) =>
                    t.createdAt.isBiggerThanValue(since) &
                    t.undoneAt.isNull() &
                    t.source.equals('controller'),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    var seen = const <String>[];
    try {
      seen =
          (await SharedPreferences.getInstance()).getStringList(
            _seenAdjustmentsKey,
          ) ??
          const [];
    } catch (_) {}
    final groups = <String, List<PlanAdjustment>>{};
    for (final x in rows) {
      if (seen.contains(x.groupId)) continue;
      (groups[x.groupId] ??= []).add(x);
    }
    return [
      for (final e in groups.entries) PlanAdjustmentGroup(e.key, e.value),
    ].reversed.toList();
  },
);

/// Takes back one automatic decision and brings the watch in line.
final undoPlanAdjustmentProvider = Provider<Future<void> Function(String)>(
  (ref) => (groupId) async {
    final changes = await ref.read(planReconcilerProvider).undo(groupId);
    await ref.read(applyPlanChangesProvider)(changes);
    ref.invalidate(recentPlanAdjustmentsProvider);
  },
);

/// Puts a decision's note away; the change itself stays.
final dismissPlanAdjustmentProvider = Provider<Future<void> Function(String)>(
  (ref) => (groupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getStringList(_seenAdjustmentsKey) ?? const [];
      // The last few dozen are enough: older notes are past the window.
      await prefs.setStringList(_seenAdjustmentsKey, [
        ...seen.skip(seen.length > 50 ? seen.length - 50 : 0),
        groupId,
      ]);
    } catch (_) {}
    ref.invalidate(recentPlanAdjustmentsProvider);
  },
);

/// A recent session that was clearly shorter than planned and whose reason
/// is not known yet.
typedef ShortSession = ({TrainingSession session, SessionActual actual});

/// Shorter sessions of the last three days the athlete has not explained.
final shortSessionsProvider = FutureProvider<List<ShortSession>>((ref) async {
  ref.watch(syncStatusListenerProvider);
  final db = ref.watch(databaseProvider);
  final since = DateTime.now().subtract(const Duration(days: 3));
  final rows =
      await (db.select(db.sessionActuals)..where(
            (t) =>
                t.outcome.equals('partial') &
                t.shortReason.isNull() &
                t.startedAt.isBiggerThanValue(since),
          ))
          .get();
  final out = <ShortSession>[];
  for (final a in rows) {
    final s = await (db.select(
      db.trainingSessions,
    )..where((t) => t.id.equals(a.sessionId))).getSingleOrNull();
    if (s != null) out.add((session: s, actual: a));
  }
  return out
    ..sort((a, b) => b.session.sessionDate.compareTo(a.session.sessionDate));
});

/// Records why a session was shorter.
final setShortReasonProvider =
    Provider<Future<void> Function(String sessionId, String reason)>(
      (ref) => (sessionId, reason) async {
        await ref
            .read(postWorkoutScorerProvider)
            .setShortReason(sessionId, reason);
        ref.invalidate(shortSessionsProvider);
      },
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

/// Whether today is a planned rest day: the plan covers it and schedules
/// nothing. Refreshes with the plan.
final plannedRestTodayProvider = FutureProvider<bool>((ref) async {
  ref.watch(upcomingSessionsProvider);
  ref.watch(scheduledWorkoutsProvider);
  return isPlannedRestDay(ref.watch(databaseProvider), DateTime.now());
});
