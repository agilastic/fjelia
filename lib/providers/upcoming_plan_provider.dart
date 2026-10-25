import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../models/garmin_data.dart';
import 'day_data_provider.dart';
import '../services/post_workout_scorer.dart' show PostWorkoutScorer;
import 'database_provider.dart';
import 'planner_providers.dart';

class UpcomingPlanEntry {
  const UpcomingPlanEntry({
    required this.date,
    this.session,
    this.workout,
    this.skipReason,
    this.doneBy,
  });
  final DateTime date;
  final TrainingSession? session;
  final ScheduledWorkout? workout;

  /// Why the session was cancelled, when it was.
  final String? skipReason;

  /// The recorded activity that did this entry, when there is one.
  final ActivityRecord? doneBy;

  bool get skipped => session?.status == 'skipped';

  /// Done: a finished session, or an activity that stands for it.
  bool get done => session?.status == 'completed' || doneBy != null;

  String get title => session?.title ?? workout?.name ?? '';

  /// Planned minutes, when known.
  int? get plannedMinutes => session != null
      ? session!.plannedDurationMin
      : workout?.estimatedDuration?.inMinutes;

  String get sport => session?.sport ?? workout?.sportType ?? '';

  UpcomingPlanEntry withDoneBy(ActivityRecord activity) => UpcomingPlanEntry(
    date: date,
    session: session,
    workout: workout,
    skipReason: skipReason,
    doneBy: activity,
  );
}

String _plain(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9äöüß]'), '');

/// Marks the entries that an activity already did. Garmin names the activity
/// after the workout, often with the place in front ("Hemmingen - Run With The
/// Wind Modified"), so the name is the strongest sign; failing that, the same
/// sport and a length within 18 % of the planned one. An activity stands for
/// one entry at most, and a cancelled or finished-and-linked entry is left as
/// it is.
List<UpcomingPlanEntry> markDoneEntries(
  List<UpcomingPlanEntry> entries,
  List<ActivityRecord> activities,
) {
  final taken = <String>{};
  final done = <int, ActivityRecord>{};
  // Score: 2 by name, 1 by length. Best first, so a name beats a guess.
  final candidates = <({int entry, ActivityRecord activity, int score})>[];
  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    if (e.skipped || e.done) continue;
    for (final a in activities) {
      final local = a.startDate.toLocal();
      final sameDay =
          local.year == e.date.year &&
          local.month == e.date.month &&
          local.day == e.date.day;
      if (!sameDay) continue;
      if (!PostWorkoutScorer.sportFamilyMatches(e.sport, a.type)) continue;
      final entryName = _plain(e.title);
      final activityName = _plain(a.name);
      final byName =
          entryName.length >= 4 &&
          (activityName.contains(entryName) ||
              (activityName.length >= 4 && entryName.contains(activityName)));
      final planned = e.plannedMinutes;
      final minutes = a.durationSeconds / 60;
      final byLength =
          planned != null &&
          planned > 0 &&
          minutes / planned >= 0.82 &&
          minutes / planned <= 1.18;
      if (byName) {
        candidates.add((entry: i, activity: a, score: 2));
      } else if (byLength) {
        candidates.add((entry: i, activity: a, score: 1));
      }
    }
  }
  candidates.sort((a, b) => b.score.compareTo(a.score));
  for (final c in candidates) {
    if (done.containsKey(c.entry) || taken.contains(c.activity.activityId)) {
      continue;
    }
    done[c.entry] = c.activity;
    taken.add(c.activity.activityId);
  }
  return [
    for (var i = 0; i < entries.length; i++)
      done.containsKey(i) ? entries[i].withDoneBy(done[i]!) : entries[i],
  ];
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
  final merged = mergeUpcomingPlan(
    await sessions,
    await workouts,
    skipReasons: await reasons,
  );
  // What was done today shows against what was planned for today; read again
  // when a sync brings new activities.
  ref.watch(syncStatusListenerProvider);
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final activities =
      await (db.select(db.activityRecords)..where(
            (t) =>
                t.startDate.isBiggerOrEqualValue(today) &
                t.startDate.isSmallerThanValue(
                  DateTime(today.year, today.month, today.day + 1),
                ),
          ))
          .get();
  return markDoneEntries(merged, activities);
});
