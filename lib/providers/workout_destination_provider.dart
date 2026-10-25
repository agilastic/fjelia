import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/workout_providers/workout_providers.dart';
import 'auth_provider.dart';
import 'coros_provider.dart';
import 'polar_provider.dart';
import 'source_priority_provider.dart';
import 'suunto_provider.dart';
import 'user_profile_provider.dart';
import 'workout_providers_provider.dart';

/// The platforms the athlete has connected, in their order of activity
/// sources (Settings, Connections). With none connected it is Garmin alone,
/// where workouts always went.
final connectedProvidersProvider = FutureProvider<List<WorkoutProvider>>((
  ref,
) async {
  final priority = await ref.watch(sourcePriorityProvider.future);
  // Read again when a connection or the athlete's settings change.
  ref.watch(authProvider);
  ref.watch(corosConnectedProvider);
  ref.watch(polarConnectedProvider);
  ref.watch(suuntoConnectedProvider);
  ref.watch(userProfileProvider);
  final providers = ref.watch(workoutProvidersProvider);
  final connected = await providers.connected(priority['activity'] ?? const []);
  if (connected.isNotEmpty) return connected;
  final garmin = providers.byId('garmin');
  return garmin == null ? const [] : [garmin];
});

/// The connected platforms that take a workout straight onto their calendar:
/// where plans go by themselves, without being asked.
final pushProvidersProvider = FutureProvider<List<WorkoutProvider>>((
  ref,
) async => [
  for (final p in await ref.watch(connectedProvidersProvider.future))
    if (await p.mode() == DeliveryMode.push) p,
]);

/// How a workout reaches the watch platform.
enum WorkoutRoute {
  /// Fjelia sends it to the platform's calendar.
  push,

  /// Fjelia hands over the workout as text to enter by hand.
  share,
}

/// A platform and the way a workout gets to it.
typedef WorkoutTarget = ({WorkoutProvider provider, WorkoutRoute route});

/// One target per connected platform, so with Garmin and COROS both connected
/// both buttons are there. A platform that takes workouts is pushed to; for
/// every other, the workout is shared as text.
final workoutTargetsProvider = FutureProvider<List<WorkoutTarget>>((ref) async {
  final connected = await ref.watch(connectedProvidersProvider.future);
  return [
    for (final p in connected)
      (
        provider: p,
        route: await p.mode() == DeliveryMode.push
            ? WorkoutRoute.push
            : WorkoutRoute.share,
      ),
  ];
});
