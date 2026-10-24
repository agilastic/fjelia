import 'package:fjelia/theme/activity_colors.dart';
import 'package:fjelia/models/calendar_activity.dart';
import 'package:fjelia/providers/activity_calendar_provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/screens/planner/plan_calendar_markers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('month markers include history, planned sessions and Garmin without linked duplicates', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    final month = DateTime(2024, 2);
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'done',
            name: 'Completed run',
            type: 'running',
            startDate: DateTime(2024, 2, 29, 12),
            durationSeconds: 1800,
          ),
        );
    for (final status in ['planned', 'cancelled', 'completed']) {
      await db
          .into(db.trainingSessions)
          .insert(
            TrainingSessionsCompanion.insert(
              id: status,
              planId: 'plan',
              athleteId: 'self',
              sessionDate: DateTime(2024, 2, 29),
              sessionNumber: 1,
              weekNumber: 1,
              sport: 'swimming',
              sessionType: 'base',
              phase: 'base',
              primaryZone: 2,
              title: 'Swim $status',
              plannedDurationMin: 30,
              plannedTrimp: 30,
              sessionLevel: 1,
              status: Value(status),
              garminWorkoutId: Value('linked-$status'),
            ),
          );
    }
    for (final id in ['linked-planned', 'linked-completed', 'unlinked']) {
      await db
          .into(db.scheduledWorkoutRecords)
          .insert(
            ScheduledWorkoutRecordsCompanion.insert(
              workoutId: id,
              scheduleId: id,
              name: 'Garmin $id',
              sportType: 'cycling',
              scheduledDate: DateTime(2024, 2, 29),
            ),
          );
    }
    final entries = await container.read(
      planCalendarActivitiesProvider(month).future,
    );
    expect(entries.length, 3);
    expect(entries.where((e) => e.completed).single.title, 'Completed run');
    expect(
      entries.where((e) => !e.completed).map((e) => e.title),
      containsAll(['Swim planned', 'Garmin unlinked']),
    );
    expect(
      await container.read(
        planCalendarActivitiesProvider(DateTime(2024, 3)).future,
      ),
      isEmpty,
    );
    for (final entry in entries) {
      expect(calendarActivityColor(entry), completedActivityColor(entry.sport));
    }
    final planned = CalendarActivity(
      date: DateTime(2024, 2),
      sport: 'running',
      title: 'Base',
      completed: false,
      phase: 'base',
    );
    expect(calendarActivityColor(planned), completedActivityColor('running'));
    container.dispose();
    await db.close();
  });
}
