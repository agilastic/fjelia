import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/missed_workout_reminder_service.dart';
import '../services/plan_rebalance_applier.dart';
import '../services/notifications/local_notification_gateway.dart'
    show NotificationPermission;
import 'database_provider.dart';
import 'hrv_reminder_provider.dart';
import 'planner_providers.dart';
import 'readiness_provider.dart';

final missedWorkoutReminderProvider = Provider(
  (ref) => MissedWorkoutReminderService(
    ref.watch(databaseProvider),
    ref.watch(localNotificationGatewayProvider),
  ),
);

/// The evening reminder's switch, time and look-ahead window.
final missedWorkoutSettingsProvider =
    AsyncNotifierProvider<MissedWorkoutSettingsNotifier, MissedWorkoutSettings>(
      MissedWorkoutSettingsNotifier.new,
    );

class MissedWorkoutSettingsNotifier
    extends AsyncNotifier<MissedWorkoutSettings> {
  @override
  Future<MissedWorkoutSettings> build() => MissedWorkoutSettings.load();

  /// Saves and reschedules right away, so a new time applies tonight.
  Future<void> save(MissedWorkoutSettings settings) async {
    await settings.save();
    state = AsyncData(settings);
    unawaited(ref.read(missedWorkoutReminderProvider).reconcile());
  }
}

/// Whether Fjelia may show notifications; refreshed after asking.
final notificationPermissionProvider =
    FutureProvider.autoDispose<NotificationPermission>(
      (ref) => ref.watch(localNotificationGatewayProvider).permission(),
    );

final planRebalanceApplierProvider = Provider(
  (ref) => PlanRebalanceApplier(
    ref.watch(databaseProvider),
    ref.watch(planSessionActionsProvider),
    ref.watch(sessionAdaptationServiceProvider),
  ),
);
