import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/workout_destination.dart';
import 'auth_provider.dart';
import 'coros_provider.dart';
import 'polar_provider.dart';
import 'source_priority_provider.dart';
import 'suunto_provider.dart';
import 'user_profile_provider.dart';

/// Where planned workouts go: the first connected watch platform in the
/// athlete's activity-source order (Settings, Connections).
/// The watch platforms the athlete has connected, in their order of activity
/// sources (Settings, Connections).
final connectedDestinationsProvider = FutureProvider<List<WorkoutDestination>>((
  ref,
) async {
  final priority = await ref.watch(sourcePriorityProvider.future);
  final connected = <String>{
    if (ref.watch(authProvider).garminConnected)
      WorkoutDestination.garmin.sourceKey,
    if (await ref.watch(corosConnectedProvider.future))
      WorkoutDestination.coros.sourceKey,
    if (await ref.watch(polarConnectedProvider.future))
      WorkoutDestination.polar.sourceKey,
    if (await ref.watch(suuntoConnectedProvider.future))
      WorkoutDestination.suunto.sourceKey,
  };
  return connectedWorkoutDestinations(
    priority['activity'] ?? const [],
    connected,
  );
});

/// The first of them: where plans go by themselves, without being asked.
final workoutDestinationProvider = FutureProvider<WorkoutDestination>(
  (ref) async => (await ref.watch(connectedDestinationsProvider.future)).first,
);

/// How a workout reaches the watch platform.
enum WorkoutRoute {
  /// Fjelia sends it to the platform's calendar.
  push,

  /// Fjelia hands over the workout as text to enter by hand.
  share,
}

/// A platform and the way a workout gets to it.
typedef WorkoutTarget = ({WorkoutDestination destination, WorkoutRoute route});

/// One target per connected platform, so with Garmin and COROS both connected
/// both buttons are there. Garmin is pushed to. COROS is pushed to only when
/// the athlete turned on the unofficial Training Hub route; for every other
/// platform, and for COROS without it, the workout is shared.
final workoutTargetsProvider = FutureProvider<List<WorkoutTarget>>((ref) async {
  final destinations = await ref.watch(connectedDestinationsProvider.future);
  final corosOn =
      ref.watch(userProfileProvider).valueOrNull?.corosWorkoutPush ?? false;
  return [
    for (final d in destinations)
      (
        destination: d,
        route:
            d == WorkoutDestination.garmin ||
                (d == WorkoutDestination.coros && corosOn)
            ? WorkoutRoute.push
            : WorkoutRoute.share,
      ),
  ];
});
