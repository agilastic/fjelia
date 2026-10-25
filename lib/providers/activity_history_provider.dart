
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import 'database_provider.dart';
import 'hrv_reminder_provider.dart';
import 'day_data_provider.dart';

final loadActivitiesProvider = FutureProvider<List<ActivityRecord>>((
  ref,
) async {
  ref.watch(syncStatusListenerProvider);
  return (await ref.watch(databaseProvider).getActivitiesInRange(365))
    ..sort((a, b) => b.startDate.compareTo(a.startDate));
});

final deleteActivityProvider = Provider<Future<void> Function(String)>(
  (ref) => (id) async {
    await ref.read(databaseProvider).deleteActivityById(id);
    ref.invalidate(loadActivitiesProvider);
    ref.invalidate(trainingMonitorProvider);
    ref.invalidate(trainingFormSeriesProvider);
    // The workout is gone; its HRV readings stay, its reminder does not.
    await ref.read(hrvReminderActionsProvider).reconcile();
  },
);
