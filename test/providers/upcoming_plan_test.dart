import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/models/garmin_data.dart';
import 'package:fjelia/providers/upcoming_plan_provider.dart';

void main() {
  test('scheduled workouts appear in chronological upcoming groups', () {
    ScheduledWorkout workout(String id, int day) => ScheduledWorkout(
      workoutId: id,
      scheduleId: id,
      name: id,
      sportType: 'running',
      scheduledDate: DateTime(2026, 10, day),
    );
    final rows = mergeUpcomingPlan([], [
      workout('later', 22),
      workout('today', 20),
      workout('tomorrow', 21),
    ]);
    expect(rows.map((e) => e.workout!.name), ['today', 'tomorrow', 'later']);
    expect(rows.map((e) => e.date.day), [20, 21, 22]);
  });
}
