import '../services/strength/strength_repository.dart';
import 'strength_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/workout_destination.dart';
import '../services/workout_providers/coros_workout_provider.dart';
import '../services/workout_providers/garmin_workout_provider.dart';
import '../services/workout_providers/polar_workout_provider.dart';
import '../services/workout_providers/share_only_workout_provider.dart';
import '../services/workout_providers/workout_providers.dart';
import 'auth_provider.dart';
import 'coros_provider.dart';
import 'database_provider.dart';
import 'polar_provider.dart';
import 'suunto_provider.dart';

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
      strengthRevision: (s) async {
        try {
          return (await ref.read(strengthRepositoryProvider).sessionPlan(s))
              ?.revision;
        } on StrengthUnreadableException {
          return 'unreadable';
        }
      },
    ),
    CorosWorkoutProvider(
      ref.watch(corosServiceProvider),
      connected: () => ref.read(corosConnectedProvider.future),
    ),
    PolarWorkoutProvider(
      ref.watch(databaseProvider),
      ref.watch(polarServiceProvider),
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
