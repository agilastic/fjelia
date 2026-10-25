import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../models/garmin_data.dart';
import '../services/post_workout_scorer.dart' show noActivityReason;
import 'database_provider.dart';
import 'day_data_provider.dart';
import 'planner_providers.dart';
import 'upcoming_plan_provider.dart';

enum PlanWeekState { planned, done, skipped, missed }

/// One line of the week: a planned session, a planned watch workout or an
/// activity that was done without a plan.
class PlanWeekItem {
  const PlanWeekItem({
    required this.sport,
    required this.title,
    required this.state,
    this.minutes,
    this.session,
    this.activity,
    this.skipReason,
    this.workout,
    this.completionMatch,
  });
  final String sport, title;

  /// Why a session was cancelled, when the athlete said.
  final String? skipReason;
  final PlanWeekState state;

  /// Planned minutes, or the real ones once done.
  final int? minutes;
  final TrainingSession? session;
  final ScheduledWorkout? workout;
  final PlanCompletionMatch? completionMatch;
  bool get hasPlan => session != null || workout != null;
  int? get plannedMinutes =>
      session?.plannedDurationMin ?? workout?.estimatedDuration?.inMinutes;

  /// What was really done, for a done line.
  final ActivityRecord? activity;
}

class PlanWeekDay {
  const PlanWeekDay(this.date, this.items);
  final DateTime date;
  final List<PlanWeekItem> items;
  bool get rest => items.isEmpty;
}

class PlanWeek {
  const PlanWeek(this.start, this.days);
  final DateTime start;
  final List<PlanWeekDay> days;

  /// Minutes of everything still meant to happen or already done as planned;
  /// a cancelled session does not count.
  int get plannedMinutes => [
    for (final d in days)
      for (final i in d.items)
        if (i.hasPlan && i.state != PlanWeekState.skipped)
          i.plannedMinutes ?? 0,
  ].fold(0, (a, b) => a + b);

  int get doneMinutes => [
    for (final d in days)
      for (final i in d.items)
        if (i.state == PlanWeekState.done) i.minutes ?? 0,
  ].fold(0, (a, b) => a + b);
}

/// The first day of the week that contains [day].
DateTime weekStartFor(DateTime day, {bool mondayFirst = true}) {
  final d = DateTime(day.year, day.month, day.day);
  return DateTime(
    d.year,
    d.month,
    d.day - (mondayFirst ? d.weekday - 1 : d.weekday % 7),
  );
}

/// Builds the week from sessions, watch workouts and activities. Pure, so it
/// can be tested without a database.
PlanWeek buildPlanWeek({
  required DateTime start,
  required List<TrainingSession> sessions,
  required List<ActivityRecord> activities,
  Map<String, String> skipReasons = const {},
  Map<String, String> linkedActivity = const {},
  Map<String, DateTime> completionStarts = const {},
  List<UpcomingPlanEntry> scheduled = const [],
}) {
  final entries = markDoneEntries(
    mergeUpcomingPlan(sessions, [
      for (final e in scheduled)
        if (e.workout != null) e.workout!,
    ], skipReasons: skipReasons),
    activities,
    linkedActivity: linkedActivity,
    completionStarts: completionStarts,
  );
  final used = <String>{
    for (final e in entries)
      if (e.doneBy != null) e.doneBy!.activityId,
  };
  final days = <PlanWeekDay>[];
  for (var i = 0; i < 7; i++) {
    final day = DateTime(start.year, start.month, start.day + i);
    bool same(DateTime d) {
      final l = d.toLocal();
      return l.year == day.year && l.month == day.month && l.day == day.day;
    }

    final items = <PlanWeekItem>[];
    for (final e in entries.where((e) => same(e.doneBy?.startDate ?? e.date))) {
      final s = e.session;
      final reason = s == null ? null : skipReasons[s.id];
      final actual = e.doneBy;
      final state = e.done || s?.status == 'completed' || actual != null
          ? PlanWeekState.done
          : s?.status == 'skipped'
          ? (reason == null || reason == noActivityReason
                ? PlanWeekState.missed
                : PlanWeekState.skipped)
          : PlanWeekState.planned;
      items.add(
        PlanWeekItem(
          sport: actual?.type ?? e.sport,
          title: actual?.name ?? e.title,
          state: state,
          minutes: actual != null
              ? (actual.durationSeconds / 60).round()
              : state == PlanWeekState.done
              ? s?.actualDurationMin
              : e.plannedMinutes,
          session: s,
          workout: e.workout,
          activity: actual,
          completionMatch: e.completionMatch,
          skipReason: reason == noActivityReason ? null : reason,
        ),
      );
    }
    // Done without a plan: still part of the week.
    for (final a in activities.where(
      (a) => same(a.startDate) && !used.contains(a.activityId),
    )) {
      items.add(
        PlanWeekItem(
          sport: a.type,
          title: a.name,
          state: PlanWeekState.done,
          minutes: (a.durationSeconds / 60).round(),
          activity: a,
        ),
      );
    }
    days.add(PlanWeekDay(day, items));
  }
  return PlanWeek(start, days);
}

/// The week starting on [start]: the plan, what was done, what was dropped.
final planWeekProvider = StreamProvider.family<PlanWeek, DateTime>((
  ref,
  start,
) {
  ref.watch(syncStatusListenerProvider);
  // Plan changes (move, skip, regenerate) refresh these.
  ref.watch(upcomingSessionsProvider);
  ref.watch(scheduledWorkoutsProvider);
  final db = ref.watch(databaseProvider);
  final end = DateTime(start.year, start.month, start.day + 7);
  return db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.trainingPlans,
          db.trainingSessions,
          db.activityRecords,
          db.scheduledWorkoutRecords,
          db.sessionActuals,
        },
      )
      .watch()
      .asyncMap((_) async {
        final plans =
            await (db.select(db.trainingPlans)..where(
                  (t) => t.status.equals('active') & t.athleteId.equals('self'),
                ))
                .get();
        final sessions =
            await (db.select(db.trainingSessions)
                  ..where(
                    (t) =>
                        t.athleteId.equals('self') &
                        (t.planId.isIn(plans.map((p) => p.id)) |
                            t.status.equals('completed')) &
                        t.sessionDate.isBiggerOrEqualValue(start) &
                        t.sessionDate.isSmallerThanValue(end),
                  )
                  ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)]))
                .get();
        final activities =
            await (db.select(db.activityRecords)
                  ..where(
                    (t) =>
                        t.startDate.isBiggerOrEqualValue(start) &
                        t.startDate.isSmallerThanValue(end),
                  )
                  ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
                .get();
        final actuals =
            await (db.select(db.sessionActuals)..where(
                  (t) =>
                      t.sessionId.isIn(sessions.map((s) => s.id)) |
                      t.activityId.isIn(activities.map((a) => a.activityId)) |
                      (t.startedAt.isBiggerOrEqualValue(start) &
                          t.startedAt.isSmallerThanValue(end)),
                ))
                .get();
        final linkedIds = actuals
            .map((a) => a.activityId)
            .whereType<String>()
            .toSet();
        final loadedIds = activities.map((a) => a.activityId).toSet();
        if (linkedIds.difference(loadedIds).isNotEmpty) {
          activities.addAll(
            await (db.select(db.activityRecords)..where(
                  (t) => t.activityId.isIn(linkedIds.difference(loadedIds)),
                ))
                .get(),
          );
        }
        final scheduled =
            await (db.select(db.scheduledWorkoutRecords)..where(
                  (t) =>
                      t.scheduledDate.isBiggerOrEqualValue(start) &
                      t.scheduledDate.isSmallerThanValue(end),
                ))
                .get();
        return buildPlanWeek(
          start: start,
          sessions: sessions,
          activities: activities,
          skipReasons: {
            for (final a in actuals)
              if (a.skipReason != null) a.sessionId: a.skipReason!,
          },
          linkedActivity: {
            for (final a in actuals)
              if (a.activityId != null) a.sessionId: a.activityId!,
          },
          completionStarts: {
            for (final a in actuals)
              if (a.startedAt != null) a.sessionId: a.startedAt!,
          },
          // Watch workouts that are not part of the plan.
          scheduled: [
            for (final row in scheduled)
              UpcomingPlanEntry(
                date: row.scheduledDate,
                workout: scheduledWorkoutFromRecord(row),
              ),
          ],
        );
      });
});
