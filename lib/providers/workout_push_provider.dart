import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/coros_workout.dart' show CorosUnsupportedWorkout;
import '../services/workout_destination.dart';
import 'coros_provider.dart';
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
