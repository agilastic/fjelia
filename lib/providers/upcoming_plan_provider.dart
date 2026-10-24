import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../models/garmin_data.dart';
import 'day_data_provider.dart';
import 'planner_providers.dart';

class UpcomingPlanEntry {
  const UpcomingPlanEntry({
    required this.date,
    this.session,
    this.workout,
    this.skipReason,
  });
  final DateTime date;
  final TrainingSession? session;
  final ScheduledWorkout? workout;

  /// Why the session was cancelled, when it was.
  final String? skipReason;

  bool get skipped => session?.status == 'skipped';
}

List<UpcomingPlanEntry> mergeUpcomingPlan(
  List<TrainingSession> sessions,
  List<ScheduledWorkout> workouts, {
  Map<String, String> skipReasons = const {},
}) {
  final linked = {
    for (final s in sessions) ...[s.garminWorkoutId, s.garminAlternativeId],
  }..remove(null);
  return [
    for (final s in sessions)
      UpcomingPlanEntry(
        date: s.sessionDate,
        session: s,
        skipReason: s.status == 'skipped' ? skipReasons[s.id] : null,
      ),
    for (final w in workouts)
      if (!linked.contains(w.workoutId))
        UpcomingPlanEntry(date: w.scheduledDate, workout: w),
  ]..sort((a, b) => a.date.compareTo(b.date));
}

final upcomingPlanProvider = FutureProvider<List<UpcomingPlanEntry>>((
  ref,
) async {
  final sessions = ref.watch(upcomingSessionsProvider.future);
  final workouts = ref.watch(scheduledWorkoutsProvider.future);
  final reasons = ref.watch(sessionSkipReasonsProvider.future);
  return mergeUpcomingPlan(
    await sessions,
    await workouts,
    skipReasons: await reasons,
  );
});
