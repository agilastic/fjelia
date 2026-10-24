import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/training_plan_service.dart';
import 'database_provider.dart';
import 'planner_providers.dart';
import 'user_profile_provider.dart';

/// The profile attributes that shape a plan.
PlanAthleteProfile planAthleteOf(UserProfile? profile) => PlanAthleteProfile(
  experienceLevel: profile?.experienceLevel ?? 'intermediate',
  sex: profile?.sex,
  age: profile?.age?.floor(),
);

/// One generation job at a time; replaces the active plan's future workouts.
final workoutGenerationProvider =
    StateNotifierProvider<WorkoutGenerationNotifier, AsyncValue<int?>>(
      (ref) => WorkoutGenerationNotifier(ref),
    );

class WorkoutGenerationNotifier extends StateNotifier<AsyncValue<int?>> {
  WorkoutGenerationNotifier(this.ref) : super(const AsyncData(null));
  final Ref ref;
  Future<int?> generate() async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final goal = await ref.read(primaryRaceGoalProvider.future);
      if (goal == null) {
        throw StateError('Add a future race goal with priority A first.');
      }
      final profile = await ref.read(userProfileProvider.future);
      final db = ref.read(databaseProvider);
      await ref.read(workoutTemplateLibraryProvider).seedIfEmpty();
      final active =
          await (db.select(db.trainingPlans)
                ..where(
                  (t) => t.athleteId.equals('self') & t.status.equals('active'),
                )
                ..orderBy([(t) => OrderingTerm.desc(t.generatedAt)])
                ..limit(1))
              .getSingleOrNull();
      final id = await ref
          .read(trainingPlanServiceProvider)
          .generatePlan(
            athleteId: 'self',
            raceGoalId: goal.id,
            raceDate: goal.raceDate,
            sport: goal.primarySport,
            raceDistanceM: goal.distanceM,
            daysPerWeek: profile.trainingDaysPerWeek,
            hoursPerWeek: profile.hoursPerWeek,
            restDays: profile.restDays,
            strengthDays: profile.preferredStrengthDays,
            maxSessionsPerDay: profile.maxSessionsPerDay,
            gadSports: profile.preferredSports,
            existingPlanId: active?.id,
            athlete: planAthleteOf(profile),
          );
      final sessions =
          await (db.select(db.trainingSessions)..where(
                (t) =>
                    t.planId.equals(id) &
                    (t.status.equals('planned') | t.status.equals('adapted')),
              ))
              .get();
      ref.invalidate(upcomingSessionsProvider);
      state = AsyncData(sessions.length);
      return sessions.length;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
