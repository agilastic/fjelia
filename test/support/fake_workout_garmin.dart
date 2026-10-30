import 'package:fjelia/api/garmin_client.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/plan_session_actions.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_providers/garmin_workout_provider.dart';
import 'package:fjelia/services/workout_providers/workout_providers.dart';

class FakeWorkoutGarmin extends GarminClient {
  int creates = 0;
  List<Map<String, dynamic>> lastSteps = const [];
  String? lastDescription;
  final dates = <DateTime>[];
  final removedSchedules = <String>[];
  final deletedWorkouts = <String>[];
  bool failSchedule = false, failUnschedule = false, failDelete = false;

  /// What the calendar already holds, as `title|yyyy-MM-dd` to workout id.
  Map<String, String> existingCalendar = {};

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

  @override
  Future<void> deleteWorkout(String workoutId, {String? scheduleId}) async {
    if (failDelete) throw GarminApiException('Test delete failure');
    if (scheduleId != null) removedSchedules.add(scheduleId);
    deletedWorkouts.add(workoutId);
  }

  /// Further calendar entries, for copies of one workout.
  List<GarminCalendarWorkout> calendar = [];

  List<GarminCalendarWorkout> get _entries => [
    for (final e in existingCalendar.entries)
      (
        title: e.key.split('|').first,
        date: e.key.split('|').last,
        workoutId: e.value,
        scheduleId: 'existing-${e.value}',
      ),
    ...calendar,
  ];

  @override
  Future<List<GarminCalendarWorkout>> calendarWorkoutEntries({
    int monthsAhead = 2,
  }) async => _entries;

  @override
  Future<List<GarminCalendarWorkout>> calendarWorkoutsOn(DateTime date) async {
    final day = date.toIso8601String().substring(0, 10);
    return [
      for (final e in _entries)
        if (e.date == day && !removedSchedules.contains(e.scheduleId)) e,
    ];
  }

  @override
  Future<List<({String scheduleId, String workoutId})>> listCalendarWorkouts({
    int monthsAhead = 3,
  }) async => const [];

  @override
  Future<List<String>> listWorkoutIds() async => const [];
}

/// The providers of a test: Garmin, with [garmin] as its connection.
WorkoutProviders garminProviders(
  AppDatabase db,
  GarminClient garmin, {
  List<WorkoutProvider> others = const [],
}) => WorkoutProviders([GarminWorkoutProvider(db, garmin), ...others]);

/// Garmin-only shorthands for tests written when Garmin was the one platform.
extension GarminTestShorthands on TrainingPlanService {
  Future<void> pushToGarmin(String sessionId) =>
      deliver(sessionId, providers.byId('garmin')!);
  Future<void> pushPlanToGarmin(String athleteId) =>
      deliverPlan(athleteId, to: [providers.byId('garmin')!]);
  Future<int> retryGarminCleanup() => retryCleanup();
}

extension GarminActionShorthands on PlanSessionActions {
  Future<void> releaseGarminEntry(TrainingSession s) => releaseDeliveries(s);
}
