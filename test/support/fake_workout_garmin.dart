import 'package:fjelia/api/garmin_client.dart';

class FakeWorkoutGarmin extends GarminClient {
  int creates = 0;
  List<Map<String, dynamic>> lastSteps = const [];
  String? lastDescription;
  final dates = <DateTime>[];
  final removedSchedules = <String>[];
  bool failSchedule = false, failUnschedule = false;
  @override
  Future<String> createWorkout(
    String name,
    String sport,
    List<Map<String, dynamic>> steps, {
    String? description,
  }) async {
    lastSteps = steps;
    lastDescription = description;
    return 'workout-${++creates}';
  }
  @override
  Future<String?> scheduleWorkout(String workoutId, DateTime date) async {
    if (failSchedule) throw GarminApiException('Test scheduling failure');
    dates.add(date);
    return 'schedule-${dates.length}';
  }

  @override
  Future<void> unscheduleWorkout(String id) async {
    if (failUnschedule) throw GarminApiException('Test unscheduling failure');
    removedSchedules.add(id);
  }
}
