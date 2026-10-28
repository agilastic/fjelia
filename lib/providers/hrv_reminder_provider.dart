import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/hrv/hrv_notification_action_router.dart';
import '../services/hrv/hrv_post_reminder_coordinator.dart';
import '../services/hrv/hrv_timing_policy.dart';
import '../services/notifications/local_notification_adapter.dart';
import '../services/notifications/local_notification_gateway.dart';
import '../services/polar_h10_service.dart';
import '../db/database.dart' show HrvPostReminder;
import 'database_provider.dart';
import 'hrv_training_provider.dart';
import 'locale_provider.dart';

/// The platform gateway. Tests override it with a fake.
final localNotificationGatewayProvider = Provider<LocalNotificationGateway>((
  ref,
) {
  if (!(Platform.isIOS || Platform.isAndroid)) {
    return NoopNotificationGateway();
  }
  final language = ref.read(appLocaleProvider).languageCode;
  return FlutterLocalNotificationGateway(language: language);
});

/// True while a strap is remembered, which is all the reminder needs. A
/// current connection is not asked for.
final hrvSensorReadyProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    try {
      return await PolarH10Pairing.read() != null;
    } catch (_) {
      return false;
    }
  },
);

final hrvReminderCoordinatorProvider = Provider<HrvPostReminderCoordinator>((
  ref,
) {
  return HrvPostReminderCoordinator(
    db: ref.watch(databaseProvider),
    gateway: ref.watch(localNotificationGatewayProvider),
    sensorReady: ref.watch(hrvSensorReadyProvider),
    training: ref.watch(hrvTrainingServiceProvider),
    language: ref.read(appLocaleProvider).languageCode,
  );
});

final hrvActionRouterProvider = Provider<HrvNotificationActionRouter>((ref) {
  final router = HrvNotificationActionRouter(
    coordinator: ref.watch(hrvReminderCoordinatorProvider),
    gateway: ref.watch(localNotificationGatewayProvider),
  )..attach();
  ref.onDispose(router.dispose);
  return router;
});

/// The reminder settings and what the platform currently allows.
class HrvReminderStatus {
  const HrvReminderStatus({
    required this.prefs,
    required this.permission,
    required this.sensorReady,
  });
  final HrvReminderPrefs prefs;
  final NotificationPermission permission;
  final bool sensorReady;

  bool get enabled => prefs.optedIn;

  /// The reminder is on but the platform will not show it.
  bool get blocked => prefs.optedIn && !permission.allowed;
}

final hrvReminderStatusProvider = FutureProvider<HrvReminderStatus>((
  ref,
) async {
  final coordinator = ref.watch(hrvReminderCoordinatorProvider);
  return HrvReminderStatus(
    prefs: await coordinator.prefs(),
    permission: await ref.watch(localNotificationGatewayProvider).permission(),
    sensorReady: await ref.watch(hrvSensorReadyProvider)(),
  );
});

/// Changes to the reminder from the settings screen and the capture flow.
final hrvReminderActionsProvider = Provider<HrvReminderActions>(
  HrvReminderActions.new,
);

class HrvReminderActions {
  HrvReminderActions(this.ref);
  final Ref ref;

  HrvPostReminderCoordinator get _coordinator =>
      ref.read(hrvReminderCoordinatorProvider);

  Future<NotificationPermission> setEnabled(bool on) async {
    final permission = await _coordinator.setEnabled(on);
    ref.invalidate(hrvReminderStatusProvider);
    ref.invalidate(hrvSnapshotProvider);
    return permission;
  }

  Future<void> setQuietHours({
    required bool enabled,
    int? startMinute,
    int? endMinute,
    bool? postpone,
  }) async {
    await _coordinator.updateQuietHours(
      enabled: enabled,
      startMinute: startMinute,
      endMinute: endMinute,
      postpone: postpone,
    );
    ref.invalidate(hrvReminderStatusProvider);
  }

  /// After anything that can change a reminder: a saved or deleted reading,
  /// an imported workout, the strap being paired or removed, the app coming
  /// back. Never throws: the data change that caused it must not fail
  /// because a platform call did.
  Future<void> reconcile({bool historical = false}) async {
    try {
      await _coordinator.reconcile(historical: historical);
    } catch (_) {
      // The outbox keeps what is owed; the next call picks it up.
    }
    ref.invalidate(hrvSnapshotProvider);
    ref.invalidate(hrvReminderStatusProvider);
  }

  /// "Workout finished": the athlete says when a workout began and ended, for
  /// a source that cannot tell in time. Kept as the athlete's own report; a
  /// provider record that arrives later replaces it through the same episode.
  Future<void> reportFinish({
    required DateTime start,
    required DateTime end,
  }) async {
    await ref
        .read(hrvTrainingServiceProvider)
        .reportFinish(start: start, end: end);
    await reconcile();
  }

  Future<void> bootstrap() async {
    try {
      await _coordinator.bootstrap();
    } catch (_) {}
    ref.invalidate(hrvSnapshotProvider);
    ref.invalidate(hrvReminderStatusProvider);
  }
}

/// Set while a capture sheet is open, so a notification action cannot open a
/// second Bluetooth capture.
final hrvCaptureActiveProvider = StateProvider<bool>((ref) => false);

/// What a support conversation needs, and nothing about the athlete's health:
/// versions, states, reason codes, counts and the last error class.
class HrvDiagnostics {
  const HrvDiagnostics({required this.lines});
  final List<String> lines;
}

final hrvDiagnosticsProvider = FutureProvider<HrvDiagnostics>((ref) async {
  final db = ref.watch(databaseProvider);
  final gateway = ref.watch(localNotificationGatewayProvider);
  final coordinator = ref.watch(hrvReminderCoordinatorProvider);
  final prefs = await coordinator.prefs();
  final permission = await gateway.permission();
  final reminders = await db.select(db.hrvPostReminders).get();
  final ops = await db.select(db.hrvNotificationOperations).get();
  final episodes = await db.select(db.hrvTrainingEpisodes).get();
  final links = await (db.select(
    db.hrvEpisodeMeasurements,
  )..where((t) => t.state.equals('active'))).get();
  Set<int> pending = const {};
  try {
    pending = await gateway.pendingIds();
  } catch (_) {}
  final owned = pending
      .where((id) => id >= hrvNativeIdBase && id < hrvNativeIdLimit)
      .length;
  String state(HrvPostReminder r) {
    final detected = episodes
        .where((e) => e.episodeId == r.episodeId)
        .map((e) => e.detectedAtUtc)
        .firstOrNull;
    final delay = detected == null
        ? ''
        : ' discoveredAfterEnd=${detected.difference(r.originalDueAtUtc.subtract(Duration(seconds: r.targetOffsetSeconds))).inMinutes}min';
    return '  ${r.desiredState}/${r.reason} os=${r.osState} gen=${r.generation} '
        'snoozes=${r.snoozeCount}$delay'
        '${r.lastError == null ? '' : ' lastError=${r.lastError}'}';
  }

  return HrvDiagnostics(
    lines: [
      'policy ${HrvTimingPolicy.standard.version}, analysis paired-response-v1, '
          'content v$hrvReminderContentVersion',
      'reminder ${prefs.optedIn ? 'on' : 'off'}, permission ${permission.name}, '
          'sensor remembered ${await ref.read(hrvSensorReadyProvider)()}',
      'episodes ${episodes.length}, active links ${links.length}',
      'owned platform requests $owned, pending operations '
          '${ops.where((o) => o.state == 'pending').length}',
      if (reminders.isNotEmpty) 'reminders:',
      for (final r in reminders.take(8)) state(r),
    ],
  );
});
