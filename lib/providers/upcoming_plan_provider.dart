import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../models/garmin_data.dart';
import 'day_data_provider.dart';
import '../services/post_workout_scorer.dart'
    show PostWorkoutScorer, noActivityReason;
import 'database_provider.dart';
import 'planner_providers.dart';

enum PlanCompletionMatch {
  activityLink,
  recordedStart,
  workoutName,
  activityName,
  duration,
}

class UpcomingPlanEntry {
  const UpcomingPlanEntry({
    required this.date,
    this.session,
    this.workout,
    this.skipReason,
    this.doneBy,
    this.completionMatch,
  });
  final DateTime date;
  final TrainingSession? session;
  final ScheduledWorkout? workout;

  /// Why the session was cancelled, when it was.
  final String? skipReason;

  /// The recorded activity that did this entry, when there is one.
  final ActivityRecord? doneBy;
  final PlanCompletionMatch? completionMatch;

  bool get skipped => session?.status == 'skipped';

  /// Done: a finished session, or an activity that stands for it.
  bool get done => session?.status == 'completed' || doneBy != null;

  String get title => session?.title ?? workout?.name ?? '';

  /// Planned minutes, when known.
  int? get plannedMinutes => session != null
      ? session!.plannedDurationMin
      : workout?.estimatedDuration?.inMinutes;

  String get sport => session?.sport ?? workout?.sportType ?? '';

  UpcomingPlanEntry withDoneBy(
    ActivityRecord? activity, {
    PlanCompletionMatch? match,
  }) => UpcomingPlanEntry(
    date: date,
    session: session,
    workout: workout,
    skipReason: skipReason,
    doneBy: activity,
    completionMatch: match,
  );
}

String _plain(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9äöüß]'), '');

bool _sameSport(String planned, String recorded) =>
    PostWorkoutScorer.sportFamilyMatches(switch (planned.toLowerCase()) {
      'cycling' ||
      'biking' ||
      'indoor_cycling' ||
      'road_biking' => 'cycling_road',
      'trail_run' || 'treadmill_running' => 'running',
      _ => planned.toLowerCase(),
    }, recorded);

class _CompletionCandidate {
  const _CompletionCandidate(
    this.entry,
    this.activity,
    this.score,
    this.delta,
    this.completed,
    this.match,
  );
  final int entry, score, delta;
  final ActivityRecord activity;
  final bool completed;
  final PlanCompletionMatch match;
}

int _compareCompletion(_CompletionCandidate a, _CompletionCandidate b) {
  final evidence = b.score.compareTo(a.score);
  if (evidence != 0) return evidence;
  if (a.completed != b.completed) return a.completed ? -1 : 1;
  return a.delta.compareTo(b.delta);
}

/// Presentation-only reconciliation: recorded links/start times first, then
/// uniquely matching names or sport/date/duration. Each activity is used once.
/// Equally plausible candidates stay separate instead of guessing.
List<UpcomingPlanEntry> markDoneEntries(
  List<UpcomingPlanEntry> entries,
  List<ActivityRecord> activities, {
  Map<String, String> linkedActivity = const {},
  Map<String, DateTime> completionStarts = const {},
}) {
  final byId = {for (final a in activities) a.activityId: a};
  final taken = <String>{...linkedActivity.values};
  final done = <int, ActivityRecord>{};
  final matches = <int, PlanCompletionMatch>{};
  final assigned = <String>{};
  void assign(int index, ActivityRecord activity, PlanCompletionMatch match) {
    done[index] = activity;
    matches[index] = match;
    assigned.add(activity.activityId);
    taken.add(activity.activityId);
  }

  for (var i = 0; i < entries.length; i++) {
    final activity = byId[linkedActivity[entries[i].session?.id]];
    if (activity != null && !assigned.contains(activity.activityId)) {
      assign(i, activity, PlanCompletionMatch.activityLink);
    }
  }
  final presentSessions = {for (final e in entries) e.session?.id};
  // Completed sessions outside this list still own their recorded activity.
  for (final entry in completionStarts.entries) {
    if (presentSessions.contains(entry.key)) continue;
    for (final a in activities) {
      if (a.startDate.isAtSameMomentAs(entry.value)) taken.add(a.activityId);
    }
  }
  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    if (done.containsKey(i)) continue;
    final existing = e.doneBy;
    if (existing != null && !taken.contains(existing.activityId)) {
      assign(
        i,
        existing,
        e.completionMatch ?? PlanCompletionMatch.activityLink,
      );
      continue;
    }
    if (e.skipped && e.skipReason != noActivityReason) continue;
    final start = completionStarts[e.session?.id];
    if (start == null) continue;
    final exact = activities
        .where(
          (a) =>
              !taken.contains(a.activityId) &&
              a.startDate.isAtSameMomentAs(start) &&
              _sameSport(e.sport, a.type),
        )
        .toList();
    if (exact.length == 1) {
      assign(i, exact.single, PlanCompletionMatch.recordedStart);
    }
  }
  final candidates = <_CompletionCandidate>[];
  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    final hasLink = linkedActivity.containsKey(e.session?.id);
    final orphanedCompletion =
        hasLink &&
        e.session?.status == 'completed' &&
        !byId.containsKey(linkedActivity[e.session?.id]);
    if (done.containsKey(i) ||
        (hasLink && !orphanedCompletion) ||
        (e.skipped && e.skipReason != noActivityReason)) {
      continue;
    }
    for (final a in activities) {
      if (taken.contains(a.activityId)) continue;
      final local = a.startDate.toLocal();
      final sameDay =
          local.year == e.date.year &&
          local.month == e.date.month &&
          local.day == e.date.day;
      if (!sameDay) continue;
      if (!_sameSport(e.sport, a.type)) continue;
      final entryName = _plain(e.title);
      final activityName = _plain(a.name);
      final byName =
          !const {
            'running',
            'cycling',
            'swimming',
            'strength',
            'workout',
            'activity',
            'training',
            'walking',
            'hiking',
            'yoga',
          }.contains(entryName) &&
          entryName.length >= 4 &&
          (activityName.contains(entryName) ||
              (activityName.length >= 4 && entryName.contains(activityName)));
      final stampedName = _plain(a.plannedWorkoutName ?? '');
      final byWorkout = entryName.length >= 4 && stampedName == entryName;
      final planned = e.session?.status == 'completed'
          ? e.session!.actualDurationMin ?? e.plannedMinutes
          : e.plannedMinutes;
      final minutes = a.durationSeconds / 60;
      final byLength =
          planned != null &&
          planned > 0 &&
          minutes / planned >= 0.82 &&
          minutes / planned <= 1.18;
      // A provider duplicate can replace the original recording ID. Recover
      // only a completed entry with both specific name and duration evidence.
      if (orphanedCompletion && (!(byWorkout || byName) || !byLength)) continue;
      if (!byWorkout && !byName && (!byLength || stampedName.isNotEmpty)) {
        continue;
      }
      final score = byWorkout
          ? 30
          : byName
          ? (activityName == entryName ? 20 : 18)
          : 10;
      candidates.add(
        _CompletionCandidate(
          i,
          a,
          score,
          planned == null ? 0 : (a.durationSeconds - planned * 60).abs(),
          e.session?.status == 'completed',
          byWorkout
              ? PlanCompletionMatch.workoutName
              : byName
              ? PlanCompletionMatch.activityName
              : PlanCompletionMatch.duration,
        ),
      );
    }
  }
  while (true) {
    final byEntry = <int, List<_CompletionCandidate>>{};
    final byActivity = <String, List<_CompletionCandidate>>{};
    for (final c in candidates) {
      if (done.containsKey(c.entry) || taken.contains(c.activity.activityId)) {
        continue;
      }
      (byEntry[c.entry] ??= []).add(c);
      (byActivity[c.activity.activityId] ??= []).add(c);
    }
    _CompletionCandidate? uniqueBest(List<_CompletionCandidate> list) {
      list.sort(_compareCompletion);
      return list.length == 1 || _compareCompletion(list[0], list[1]) != 0
          ? list.first
          : null;
    }

    final bestActivities = {
      for (final entry in byActivity.entries)
        entry.key: uniqueBest(entry.value),
    };
    var changed = false;
    for (final list in byEntry.values) {
      final best = uniqueBest(list);
      if (best == null || bestActivities[best.activity.activityId] != best) {
        continue;
      }
      assign(best.entry, best.activity, best.match);
      changed = true;
    }
    if (!changed) break;
  }
  // A pushed Garmin workout and the plan session it was made from are one
  // training: when the recording already completed the session, the workout
  // that carries its name is done by the same recording. Only a clear name
  // match counts, and the recording is not "used up" by it.
  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    if (done.containsKey(i) || e.workout == null || e.session != null) continue;
    final entryName = _plain(e.title);
    if (entryName.length < 4) continue;
    final same = [
      for (final a in activities)
        if (_sameSport(e.sport, a.type) &&
            DateUtils.isSameDay(a.startDate.toLocal(), e.date) &&
            (_plain(a.plannedWorkoutName ?? '') == entryName ||
                _plain(a.name).contains(entryName) ||
                (_plain(a.name).length >= 4 &&
                    entryName.contains(_plain(a.name)))))
          a,
    ];
    if (same.length == 1) {
      done[i] = same.single;
      matches[i] = _plain(same.single.plannedWorkoutName ?? '') == entryName
          ? PlanCompletionMatch.workoutName
          : PlanCompletionMatch.activityName;
    }
  }
  return [
    for (var i = 0; i < entries.length; i++)
      entries[i].withDoneBy(done[i], match: matches[i]),
  ];
}

List<UpcomingPlanEntry> mergeUpcomingPlan(
  List<TrainingSession> sessions,
  List<ScheduledWorkout> workouts, {
  Map<String, String> skipReasons = const {},
}) {
  String key(DateTime date, String id) =>
      '${date.year}-${date.month}-${date.day}:$id';
  final linked = {
    for (final s in sessions)
      for (final id in [s.garminWorkoutId, s.garminAlternativeId])
        if (id != null) key(s.sessionDate, id),
  };
  return [
    for (final s in sessions)
      UpcomingPlanEntry(
        date: s.sessionDate,
        session: s,
        skipReason: s.status == 'skipped' ? skipReasons[s.id] : null,
      ),
    for (final w in workouts)
      if (!linked.contains(key(w.scheduledDate, w.workoutId)))
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
  final actuals =
      await (db.select(db.sessionActuals)..where(
            (t) =>
                t.sessionId.isIn(
                  merged.map((e) => e.session?.id).whereType<String>(),
                ) |
                t.activityId.isIn(activities.map((a) => a.activityId)) |
                (t.startedAt.isBiggerOrEqualValue(today) &
                    t.startedAt.isSmallerThanValue(
                      DateTime(today.year, today.month, today.day + 1),
                    )),
          ))
          .get();
  return markDoneEntries(
    merged,
    activities,
    linkedActivity: {
      for (final a in actuals)
        if (a.activityId != null) a.sessionId: a.activityId!,
    },
    completionStarts: {
      for (final a in actuals)
        if (a.startedAt != null) a.sessionId: a.startedAt!,
    },
  );
});
