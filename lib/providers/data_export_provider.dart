import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/activity_export_service.dart';
import '../services/backup_service.dart';
import 'database_provider.dart';

final activityExportProvider = Provider<ActivityExportService>(
  (ref) => ActivityExportService(ref.watch(databaseProvider)),
);
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(databaseProvider)),
);
