import 'package:drift/drift.dart';

import '../db/database.dart';
import '../models/gym_workout.dart';

class GymWorkoutImportResult {
  const GymWorkoutImportResult(this.imported, this.duplicates);
  final int imported, duplicates;
}

class GymWorkoutImportService {
  GymWorkoutImportService(this.db);
  final AppDatabase db;

  Future<GymWorkoutImportResult> save(List<GymWorkout> workouts) =>
      db.transaction(() async {
        var imported = 0, duplicates = 0;
        for (final w in workouts) {
          w.validate();
          final existing = await db.getActivityById(w.id);
          final deleted =
              await (db.select(db.deletedActivities)..where(
                    (t) =>
                        t.activityId.equals(w.id) |
                        t.startDate.isBetweenValues(
                          w.startedAt.subtract(sameWorkoutMaxStartGap),
                          w.startedAt.add(sameWorkoutMaxStartGap),
                        ),
                  ))
                  .get();
          final nearby =
              await (db.select(db.activityRecords)..where(
                    (t) => t.startDate.isBetweenValues(
                      w.startedAt.subtract(sameWorkoutMaxStartGap),
                      w.startedAt.add(sameWorkoutMaxStartGap),
                    ),
                  ))
                  .get();
          final matching = nearby.any(
            (a) => isSameWorkout(
              a.startDate,
              a.durationSeconds,
              a.type,
              w.startedAt,
              w.durationSeconds,
              'treadmill_running',
            ),
          );
          final wasDeleted = deleted.any(
            (d) =>
                d.activityId == w.id ||
                isSameWorkout(
                  d.startDate,
                  d.durationSeconds,
                  d.type,
                  w.startedAt,
                  w.durationSeconds,
                  'treadmill_running',
                ),
          );
          if (existing != null || wasDeleted || matching) {
            duplicates++;
            continue;
          }
          await db
              .into(db.activityRecords)
              .insert(
                ActivityRecordsCompanion.insert(
                  activityId: w.id,
                  name: w.name,
                  type: 'treadmill_running',
                  startDate: w.startedAt,
                  durationSeconds: w.durationSeconds,
                  distanceMeters: Value(w.distanceMeters),
                  calories: Value(w.calories),
                  avgHeartRate: Value(w.avgHeartRate),
                  source: Value(w.source),
                ),
              );
          imported++;
        }
        return GymWorkoutImportResult(imported, duplicates);
      });
}
