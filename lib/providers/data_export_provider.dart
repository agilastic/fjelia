import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/activity_export_service.dart';
import '../services/backup_service.dart';
import '../services/data_wipe_service.dart';
import 'connection_actions_provider.dart';
import 'database_provider.dart';
import 'hrv_reminder_provider.dart';
import 'nutrition_provider.dart';
import 'strength_provider.dart';
import 'ecg_provider.dart';
import 'indoor_recording_provider.dart';
import '../l10n/l10n_ext.dart';

final activityExportProvider = Provider<ActivityExportService>(
  (ref) => ActivityExportService(ref.watch(databaseProvider)),
);
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    ref.watch(databaseProvider),
    beforeRestore: () async {
      if (ref.read(deviceRecordingOwnerProvider) != null) {
        throw StateError(tr.recordingBeforeRestore);
      }
    },
    // The data was replaced: remove what the old data left on the phone,
    // then work out the new associations without any reminder.
    afterRestore: () async {
      await ref.read(ecgStorageProvider).recoverInterrupted();
      ref.invalidate(ecgChunksProvider);
      ref.invalidate(recordingActivitiesProvider);
      ref.invalidate(ecgRecorderProvider);
      ref.invalidate(indoorRecorderProvider);
      final coordinator = ref.read(hrvReminderCoordinatorProvider);
      await coordinator.runCleanups();
      await coordinator.reconcile(historical: true);
      ref.invalidate(nutritionPreferencesProvider);
      ref.invalidate(nutritionLogProvider);
      ref.invalidate(nutritionPlanProvider);
      ref.invalidate(nutritionSavedPlanProvider);
      ref.invalidate(nutritionLinkedPlanProvider);
      invalidateStrength(ref.invalidate);
      await ref.read(nutritionReminderProvider).reconcile();
    },
  ),
);

/// Settings → System → Delete all data: signs out of every service, so
/// their push registrations are removed on the servers too (one that cannot
/// be reached does not stop it), then deletes everything on this phone.
final dataWipeProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    final actions = ref.read(connectionActionsProvider);
    for (final type in ConnectionType.values) {
      if (type == ConnectionType.health) continue;
      try {
        await actions.disconnect(type).timeout(const Duration(seconds: 10));
      } catch (e) {
        log('[Wipe] ${type.name} not signed out: $e');
      }
    }
    await DataWipeService(ref.read(databaseProvider)).wipe();
  },
);
