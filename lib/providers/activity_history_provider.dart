import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import 'database_provider.dart';
import 'hrv_reminder_provider.dart';
import 'nutrition_provider.dart';
import 'day_data_provider.dart';
import 'training_load_provider.dart';

final loadActivitiesProvider = FutureProvider<List<ActivityRecord>>((
  ref,
) async {
  ref.watch(syncStatusListenerProvider);
  return (await ref.watch(databaseProvider).getActivitiesInRange(365))
    ..sort((a, b) => b.startDate.compareTo(a.startDate));
});

final deleteActivityProvider = Provider<Future<void> Function(String)>(
  (ref) => (id) async {
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      final activity = await (db.select(
        db.activityRecords,
      )..where((t) => t.activityId.equals(id))).getSingleOrNull();
      await db.deleteActivityById(id);
      await (db.delete(
        db.nutritionRecords,
      )..where((t) => t.recordKey.equals('intake:$id'))).go();
      if (activity == null) return;
      final local = activity.startDate.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final score = await db.getScoreForDate(day);
      if (score == null) return;
      final remaining =
          await (db.select(db.activityRecords)..where(
                (t) =>
                    t.startDate.isBiggerOrEqualValue(day) &
                    t.startDate.isSmallerThanValue(
                      DateTime(day.year, day.month, day.day + 1),
                    ),
              ))
              .get();
      // Refresh the aggregate without replacing unrelated daily scores.
      // If no activities remain, the old cached load is no longer known.
      await (db.update(
        db.dayScoreRecords,
      )..where((t) => t.date.equals(score.date))).write(
        DayScoreRecordsCompanion(
          strainScore: Value(
            remaining.isEmpty
                ? null
                : remaining.fold<double>(0, (sum, a) => sum + effectiveLoad(a)),
          ),
        ),
      );
    });
    ref.invalidate(loadActivitiesProvider);
    ref.invalidate(trainingLoadProvider);
    ref.invalidate(trainingMonitorProvider);
    ref.invalidate(trainingFormSeriesProvider);
    // The workout is gone; its HRV readings stay, its reminder does not.
    await ref.read(hrvReminderActionsProvider).reconcile();
    await ref.read(nutritionReminderProvider).reconcile();
  },
);
