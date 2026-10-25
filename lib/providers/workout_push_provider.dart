import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auto_plan_pause.dart';
import '../services/workout_providers/workout_providers.dart';
import 'database_provider.dart';
import 'planner_providers.dart';
import 'workout_destination_provider.dart';

/// What came of sending a workout to the watch platform.
class WorkoutPushResult {
  const WorkoutPushResult.sent(this.provider) : shareReason = null;

  /// The platform cannot hold this workout: share it as text, for [reason].
  const WorkoutPushResult.share(this.provider, String this.shareReason);

  final WorkoutProvider provider;
  final String? shareReason;

  bool get sent => shareReason == null;
}

/// Sends a planned session to [provider]. Throws with the platform's own
/// message when it refuses; a workout the platform cannot hold comes back as
/// one to share.
final pushWorkoutProvider =
    Provider<
      Future<WorkoutPushResult> Function(
        String sessionId,
        WorkoutProvider provider,
      )
    >(
      (ref) => (sessionId, provider) async {
        try {
          await ref
              .read(trainingPlanServiceProvider)
              .deliver(sessionId, provider);
          return WorkoutPushResult.sent(provider);
        } on WorkoutNotSupported catch (e) {
          return WorkoutPushResult.share(provider, e.reason);
        }
      },
    );

/// What deleting every planned workout did on the connected platforms.
class DeleteAllResult {
  const DeleteAllResult({required this.removed, required this.labels});

  /// Entries taken off each platform, by provider id.
  final Map<String, int> removed;

  /// Provider id to the name the athlete knows it by.
  final Map<String, String> labels;

  /// Platforms that had something removed, as "COROS 3, Garmin 12".
  String get summary => [
    for (final e in removed.entries)
      if (e.value > 0) '${labels[e.key] ?? e.key} ${e.value}',
  ].join(', ');
}

/// Deletes all planned workouts on this phone and on every connected
/// platform, reporting progress. First the phone, which is quick and tells
/// the sync not to build a plan again by itself; then each platform removes
/// what Fjelia put there. Which platforms there are is not known here.
final deleteAllWorkoutsProvider =
    Provider<
      Future<DeleteAllResult> Function(
        void Function(int done, int total, String label) onProgress,
      )
    >(
      (ref) => (onProgress) async {
        final db = ref.read(databaseProvider);
        // The names platforms that can only be searched by name use, taken
        // before the plans go.
        final titles = {
          for (final s in await db.select(db.trainingSessions).get()) s.title,
        };
        onProgress(0, 0, 'Deleting on this phone');
        await AutoPlanPause.pause();
        final plans = ref.read(trainingPlanServiceProvider);
        await plans.deleteLocalPlans();
        onProgress(1, 1, 'On this phone');
        final providers = await connectedProvidersNow(ref);
        final removed = await plans.removeFromPlatforms(
          titles: titles,
          providers: providers,
          onProgress: onProgress,
        );
        return DeleteAllResult(
          removed: removed,
          labels: {for (final p in providers) p.id: p.label},
        );
      },
    );
