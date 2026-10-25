import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/activity_export_service.dart';
import '../services/backup_service.dart';
import 'database_provider.dart';
import 'hrv_reminder_provider.dart';

final activityExportProvider = Provider<ActivityExportService>(
  (ref) => ActivityExportService(ref.watch(databaseProvider)),
);
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    ref.watch(databaseProvider),
    // The data was replaced: remove what the old data left on the phone,
    // then work out the new associations without any reminder.
    afterRestore: () async {
      final coordinator = ref.read(hrvReminderCoordinatorProvider);
      await coordinator.runCleanups();
      await coordinator.reconcile(historical: true);
    },
  ),
);
