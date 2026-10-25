import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/coros_workout.dart' show CorosUnsupportedWorkout;
import '../services/workout_destination.dart';
import 'workout_destination_provider.dart';
import '../services/auto_plan_pause.dart';
import 'coros_provider.dart';
import 'database_provider.dart';
import 'planner_providers.dart';

/// What came of sending a workout to the watch platform.
class WorkoutPushResult {
  const WorkoutPushResult.sent(this.destination) : shareReason = null;

  /// The platform cannot hold this workout: share it as text, for [reason].
  const WorkoutPushResult.share(this.destination, String this.shareReason);

  final WorkoutDestination destination;
  final String? shareReason;

  bool get sent => shareReason == null;
}

/// Sends a planned session to [destination]: Garmin, or COROS when its
/// experimental route is on. Throws with the platform's own message
/// when it refuses.
final pushWorkoutProvider =
    Provider<
      Future<WorkoutPushResult> Function(
        String sessionId,
        WorkoutDestination destination,
      )
    >(
      (ref) => (sessionId, destination) async {
        final plans = ref.read(trainingPlanServiceProvider);
        if (destination == WorkoutDestination.garmin) {
          await plans.pushToGarmin(sessionId);
          return WorkoutPushResult.sent(destination);
        }
        if (destination != WorkoutDestination.coros) {
          throw StateError('${destination.label} cannot be pushed to.');
        }
        try {
          await ref
              .read(corosServiceProvider)
              .pushWorkout(await plans.prepareWorkout(sessionId));
          return WorkoutPushResult.sent(destination);
        } on CorosUnsupportedWorkout catch (e) {
          return WorkoutPushResult.share(destination, e.reason);
        }
      },
    );

/// What deleting every planned workout did on the connected platforms.
class DeleteAllResult {
  const DeleteAllResult({required this.garmin, required this.corosRemoved});

  final bool garmin;

  /// Workouts taken off the COROS calendar.
  final int corosRemoved;
}

/// Deletes all planned workouts on this phone and on every connected platform
/// that holds them (Garmin, and COROS where Fjelia sent some), reporting
/// progress. Polar and Suunto hold nothing Fjelia sent.
final deleteAllWorkoutsProvider =
    Provider<
      Future<DeleteAllResult> Function(
        void Function(int done, int total, String label) onProgress,
      )
    >(
      (ref) => (onProgress) async {
        final targets = await ref.read(workoutTargetsProvider.future);
        final garmin = targets.any(
          (t) => t.destination == WorkoutDestination.garmin,
        );
        final db = ref.read(databaseProvider);
        // The names COROS entries are matched by, before the plans go.
        final titles = {
          for (final s in await db.select(db.trainingSessions).get()) s.title,
        };
        // First the phone, which is quick, and the sync is told not to build a
        // plan again by itself. Then every platform that holds workouts.
        onProgress(0, 0, 'Deleting on this phone');
        await AutoPlanPause.pause();
        final plans = ref.read(trainingPlanServiceProvider);
        await plans.deleteLocalPlans();
        onProgress(1, 1, 'On this phone');
        var coros = 0;
        try {
          coros = await ref
              .read(corosServiceProvider)
              .removeSentWorkouts(
                titles,
                onProgress: (done, total) =>
                    onProgress(done, total, 'COROS calendar'),
              );
        } catch (_) {
          // COROS being unreachable must not stop the other platforms.
        }
        if (garmin) await plans.deleteGarminWorkouts(onProgress: onProgress);
        return DeleteAllResult(garmin: garmin, corosRemoved: coros);
      },
    );
