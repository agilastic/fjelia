import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/workout_destination.dart';
import '../services/workout_providers/coros_workout_provider.dart';
import '../services/workout_providers/garmin_workout_provider.dart';
import '../services/workout_providers/share_only_workout_provider.dart';
import '../services/workout_providers/workout_providers.dart';
import 'auth_provider.dart';
import 'coros_provider.dart';
import 'database_provider.dart';
import 'polar_provider.dart';
import 'suunto_provider.dart';
import 'user_profile_provider.dart';

/// Every watch platform workouts can go to, and the one place that lists
/// them. A new platform is one more entry here: its connection, how it takes
/// a workout, and how it removes one. Sending, replacing, removing, "delete
/// all" and the retry of failed removals then work for it without a change
/// anywhere else.
final workoutProvidersProvider = Provider<WorkoutProviders>((ref) {
  return WorkoutProviders([
    GarminWorkoutProvider(
      ref.watch(databaseProvider),
      ref.watch(garminClientProvider),
      connected: () async => ref.read(authProvider).garminConnected,
    ),
    CorosWorkoutProvider(
      ref.watch(corosServiceProvider),
      connected: () => ref.read(corosConnectedProvider.future),
      pushEnabled: () async =>
          (await ref.read(userProfileProvider.future)).corosWorkoutPush,
      enablePush: () async {
        final profile = await ref.read(userProfileProvider.future);
        await ref
            .read(userProfileProvider.notifier)
            .save(profile.copyWith(corosWorkoutPush: true));
      },
    ),
    ShareOnlyWorkoutProvider(
      id: 'polar',
      label: WorkoutDestination.polar.label,
      sourceKey: WorkoutDestination.polar.sourceKey,
      connected: () => ref.read(polarConnectedProvider.future),
    ),
    ShareOnlyWorkoutProvider(
      id: 'suunto',
      label: WorkoutDestination.suunto.label,
      sourceKey: WorkoutDestination.suunto.sourceKey,
      connected: () => ref.read(suuntoConnectedProvider.future),
    ),
  ]);
});
