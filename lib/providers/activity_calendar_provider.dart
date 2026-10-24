import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../models/calendar_activity.dart';
import 'database_provider.dart';

/// Load the displayed month, including historic and far-future planned entries.
final planCalendarActivitiesProvider =
    StreamProvider.family<List<CalendarActivity>, DateTime>((ref, month) {
      final db = ref.watch(databaseProvider);
      return db
          .customSelect(
            'SELECT 1',
            readsFrom: {
              db.activityRecords,
              db.trainingSessions,
              db.scheduledWorkoutRecords,
            },
          )
          .watch()
          .asyncMap((_) async {
            final start = DateTime(month.year, month.month);
            final end = DateTime(month.year, month.month + 1);
            final sessions =
                await (db.select(db.trainingSessions)..where(
                      (t) =>
                          t.athleteId.equals('self') &
                          t.sessionDate.isBiggerOrEqualValue(start) &
                          t.sessionDate.isSmallerThanValue(end),
                    ))
                    .get();
            final scheduled =
                await (db.select(db.scheduledWorkoutRecords)..where(
                      (t) =>
                          t.scheduledDate.isBiggerOrEqualValue(start) &
                          t.scheduledDate.isSmallerThanValue(end),
                    ))
                    .get();
            final actual = await db.getActivitiesForMonth(
              month.year,
              month.month,
            );
            final linked = {
              for (final s in sessions) ...[
                s.garminWorkoutId,
                s.garminAlternativeId,
              ],
            }..remove(null);
            final result = <CalendarActivity>[
              for (final s in sessions)
                if (s.status == 'planned' || s.status == 'adapted')
                  CalendarActivity(
                    date: s.sessionDate,
                    sport: s.sport,
                    phase: s.phase,
                    title: s.title,
                    completed: false,
                  ),
              for (final w in scheduled)
                if (!linked.contains(w.workoutId))
                  CalendarActivity(
                    date: w.scheduledDate,
                    sport: w.sportType,
                    title: w.name,
                    completed: false,
                  ),
              for (final a in actual)
                CalendarActivity(
                  date: a.startDate.toLocal(),
                  sport: a.type,
                  title: a.name,
                  completed: true,
                ),
            ];
            result.sort((a, b) => a.date.compareTo(b.date));
            return result;
          });
    });
