import 'package:flutter/material.dart';

import '../../services/workout_providers/polar_workout_provider.dart';
import '../../services/workout_providers/workout_provider.dart';
import '../onboarding/connect_polar_screen.dart';

/// Completes any login needed for the workout the athlete chose to send.
/// Returning from sign-in without saving cancels this delivery.
Future<bool> ensureWorkoutDeliveryReady(
  BuildContext context,
  WorkoutProvider provider,
) async {
  if (provider is! PolarWorkoutProvider || !await provider.needsFlowLogin) {
    return true;
  }
  if (!context.mounted) return false;
  return await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const ConnectPolarScreen(forWorkoutUpload: true),
        ),
      ) ??
      false;
}
