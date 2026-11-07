import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../db/database.dart';
import '../../models/strength_workout.dart' show isStrengthSport;
import '../../utils/log.dart';
import '../missed_workout_planner.dart' show SessionWeight, weightOf;
import '../plan_session_actions.dart';
import '../post_workout_scorer.dart';
import '../session_adaptation_service.dart';
import 'stimulus.dart';

/// Sessions whose watch entries must follow a change: [release] were done
/// (or covered) and leave the watch, [deliver] moved or changed.
class PlanChanges {
  const PlanChanges({this.release = const {}, this.deliver = const {}});
  final Set<String> release, deliver;
  bool get isEmpty => release.isEmpty && deliver.isEmpty;

  PlanChanges operator +(PlanChanges o) => PlanChanges(
    release: {...release, ...o.release},
    deliver: {...deliver, ...o.deliver}..removeAll({...release, ...o.release}),
  );
}

/// The first part of the closed loop: a workout that matched no session on
/// its own day is placed where it belongs.
///
/// - Done on another day than planned (a swap): the session moves to the
///   workout's day and is scored there.
/// - More than a later session asks of the same sport (a substitute): that
///   session counts as done, and the day it leaves is free.
/// - A hard climb also covers a planned leg-strength session.
/// - A day left free takes the sessions still open on the workout's day;
///   after a workout that tired the legs, a run or ride there is easy.
///
/// Only one clear candidate is ever used; with several nothing is changed.
/// Every change is written to [PlanAdjustments] with the session as it was,
/// and can be undone. Nothing missed is added on top of a week.
class PlanReconciler {
  PlanReconciler(this.db, this.scorer, this.actions, this.adaptation);
  final AppDatabase db;
  final PostWorkoutScorer scorer;
  final PlanSessionActions actions;
  final SessionAdaptationService adaptation;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Places the workouts of the last [days] days. [maxPerDay] is the most
  /// sessions a freed day takes.
  Future<PlanChanges> reconcile({
    DateTime? now,
    int days = 2,
    int maxPerDay = 1,
  }) async {
    final today = _day(now ?? DateTime.now());
    final activities =
        await (db.select(db.activityRecords)
              ..where(
                (t) => t.startDate.isBetweenValues(
                  today.subtract(Duration(days: days)),
                  today.add(const Duration(days: 1)),
                ),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
            .get();
    var changes = const PlanChanges();
    for (final a in activities) {
      if (a.durationSeconds <= 0) continue;
      try {
        changes += await _place(a, today, maxPerDay);
        changes += await _creditLegStrength(a, today);
      } catch (e) {
        log('[Reconcile] ${a.activityId}: $e');
      }
    }
    return changes;
  }

  Future<Set<String>> _undonePairs() async => {
    for (final x in await (db.select(
      db.planAdjustments,
    )..where((t) => t.undoneAt.isNotNull())).get())
      '${x.activityId}|${x.sessionId}',
  };

  Future<bool> _completes(String activityId) async =>
      (await (db.select(db.sessionActuals)
            ..where((t) => t.activityId.equals(activityId))
            ..limit(1))
          .getSingleOrNull()) !=
      null;

  Future<List<TrainingSession>> _open(DateTime from, DateTime to) async => [
    for (final s
        in await (db.select(db.trainingSessions)
              ..where(
                (t) =>
                    t.athleteId.equals('self') &
                    t.status.isIn(const ['planned', 'adapted']) &
                    t.locked.equals(false) &
                    t.sessionDate.isBetweenValues(from, to),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.sessionDate),
                (t) => OrderingTerm.asc(t.sessionNumber),
              ]))
            .get())
      if (!_day(s.sessionDate).isAfter(_day(to)) &&
          !_day(s.sessionDate).isBefore(_day(from)))
        s,
  ];

  Future<PlanChanges> _place(
    ActivityRecord a,
    DateTime today,
    int maxPerDay,
  ) async {
    if (await _completes(a.activityId)) return const PlanChanges();
    final day = _day(a.startDate);
    final undone = await _undonePairs();
    final near = await _open(
      day.subtract(const Duration(days: 2)),
      day.add(const Duration(days: 2, hours: 23)),
    );
    final fits = <(TrainingSession, String)>[];
    Stimulus? done;
    for (final s in near) {
      if (_day(s.sessionDate) == day) continue;
      if (isStrengthSport(s.sport)) continue;
      if (!PostWorkoutScorer.sportFamilyMatches(s.sport, a.type)) continue;
      if (undone.contains('${a.activityId}|${s.id}')) continue;
      done ??= Stimulus.done(a, await scorer.zoneSeconds(a, s.sport));
      final planned = Stimulus.planned(s);
      if (done.resembles(planned)) {
        fits.add((s, 'swap'));
      } else if (_day(s.sessionDate).isAfter(day) && done.covers(planned)) {
        fits.add((s, 'substitute'));
      }
    }
    if (fits.length != 1) {
      if (fits.length > 1) {
        log(
          '[Reconcile] ${a.activityId}: ${fits.length} sessions fit, none moved',
        );
      }
      return const PlanChanges();
    }
    final (session, kind) = fits.single;
    final from = _day(session.sessionDate);
    final group = const Uuid().v4();
    try {
      await actions.moveToDate(session, day);
    } on StateError catch (e) {
      log('[Reconcile] ${session.id} cannot move: $e');
      return const PlanChanges();
    }
    if (!await scorer.score(a) || !await _completedBy(session.id, a)) {
      // Matched elsewhere after all: put the session back.
      await _restore(session);
      return const PlanChanges();
    }
    await (db.update(db.sessionActuals)
          ..where((t) => t.sessionId.equals(session.id)))
        .write(SessionActualsCompanion(matchKind: Value(kind)));
    await _record(
      group: group,
      kind: kind,
      before: session,
      activity: a,
      reason: kind,
      params: {
        'activity': a.name,
        'session': session.title,
        'from': from.toIso8601String(),
        'to': day.toIso8601String(),
        'minutes': (a.durationSeconds / 60).round(),
        'z4': done!.z4Min.round(),
      },
    );
    var changes = PlanChanges(release: {session.id});
    if (from.isAfter(day) && !from.isBefore(today)) {
      changes += await _fillFreedDay(a, done, day, from, group, maxPerDay);
    }
    return changes;
  }

  Future<bool> _completedBy(String sessionId, ActivityRecord a) async {
    final row = await (db.select(
      db.sessionActuals,
    )..where((t) => t.sessionId.equals(sessionId))).getSingleOrNull();
    return row?.activityId == a.activityId;
  }

  /// The sessions still open on the workout's [day] move to the day the
  /// covered session left, where that day has room. Strength stays: after a
  /// hard day it goes into the week through the missed-session flow.
  Future<PlanChanges> _fillFreedDay(
    ActivityRecord a,
    Stimulus done,
    DateTime day,
    DateTime freed,
    String group,
    int maxPerDay,
  ) async {
    final onFreed =
        await (db.select(db.trainingSessions)..where(
              (t) =>
                  t.athleteId.equals('self') &
                  t.sessionDate.isBetweenValues(
                    freed,
                    freed.add(const Duration(hours: 23, minutes: 59)),
                  ) &
                  t.status.isNotIn(const ['skipped', 'ended']),
            ))
            .get();
    var room = maxPerDay - onFreed.length;
    if (room <= 0) return const PlanChanges();
    final legs = loadsLegs(a, done);
    final deliver = <String>{};
    for (final s in await _open(day, day)) {
      if (room <= 0) break;
      if (isStrengthSport(s.sport)) continue;
      final legSport =
          PostWorkoutScorer.sportFamilyMatches(s.sport, 'running') ||
          PostWorkoutScorer.sportFamilyMatches(s.sport, 'cycling');
      try {
        var moved = await actions.moveToDate(s, freed);
        var reason = 'moved';
        if (legs && legSport) {
          final weight = weightOf(s);
          if (s.sessionType == 'long') {
            moved = await adaptation.adjust(
              moved,
              durationMin: (s.plannedDurationMin * .75).round(),
              trigger: 'controller',
            );
            reason = 'movedEasy';
          } else if (weight == SessionWeight.hard) {
            moved = await adaptation.adjust(
              moved,
              intensity: 'recovery',
              trigger: 'controller',
            );
            reason = 'movedEasy';
          } else if (s.primaryZone > 2) {
            moved = await adaptation.adjust(
              moved,
              intensity: 'easier',
              trigger: 'controller',
            );
            reason = 'movedEasy';
          }
        }
        await _record(
          group: group,
          kind: reason == 'moved' ? 'move' : 'ease',
          before: s,
          activity: a,
          reason: reason,
          params: {
            'activity': a.name,
            'session': s.title,
            'from': day.toIso8601String(),
            'to': freed.toIso8601String(),
            'minutes': moved.plannedDurationMin,
          },
        );
        deliver.add(s.id);
        room--;
      } on StateError catch (e) {
        log('[Reconcile] ${s.id} stays: $e');
      }
    }
    return PlanChanges(deliver: deliver);
  }

  /// A hard climb covers the open leg-strength session of its day, or of the
  /// next day when that is still to come.
  Future<PlanChanges> _creditLegStrength(
    ActivityRecord a,
    DateTime today,
  ) async {
    if (!isRideType(a.type) && !isRunType(a.type)) return const PlanChanges();
    final credited =
        await (db.select(db.sessionActuals)
              ..where((t) => t.creditedByActivityId.equals(a.activityId))
              ..limit(1))
            .getSingleOrNull();
    if (credited != null) return const PlanChanges();
    final day = _day(a.startDate);
    final undone = await _undonePairs();
    final last = day.add(const Duration(days: 1));
    final candidates = [
      for (final s in await _open(day, last.add(const Duration(hours: 23))))
        if (s.sport == 'strength' &&
            s.subType == 'strengthLower' &&
            (_day(s.sessionDate) == day ||
                !_day(s.sessionDate).isBefore(today)) &&
            !undone.contains('${a.activityId}|${s.id}'))
          s,
    ];
    if (candidates.isEmpty) return const PlanChanges();
    final done = Stimulus.done(
      a,
      await scorer.zoneSeconds(
        a,
        isRideType(a.type) ? 'cycling_road' : 'running',
      ),
    );
    if (!worksLegStrength(a, done)) return const PlanChanges();
    final session = candidates.first;
    final from = _day(session.sessionDate);
    if (from != day) {
      try {
        await actions.moveToDate(session, day);
      } on StateError {
        return const PlanChanges();
      }
    }
    await db.transaction(() async {
      await db
          .into(db.sessionActuals)
          .insertOnConflictUpdate(
            SessionActualsCompanion.insert(
              sessionId: session.id,
              matchKind: const Value('credit'),
              outcome: const Value('completed'),
              creditedByActivityId: Value(a.activityId),
              startedAt: Value(a.startDate),
              completedAt: Value(
                a.startDate.add(Duration(seconds: a.durationSeconds)),
              ),
            ),
          );
      await (db.update(
        db.trainingSessions,
      )..where((t) => t.id.equals(session.id))).write(
        TrainingSessionsCompanion(
          status: const Value('completed'),
          dateModified: Value(DateTime.now()),
          modifiedBy: const Value('controller'),
        ),
      );
    });
    await scorer.refreshWeek(day);
    await _record(
      group: const Uuid().v4(),
      kind: 'credit',
      before: session,
      activity: a,
      reason: 'strengthCredit',
      params: {
        'activity': a.name,
        'session': session.title,
        'from': from.toIso8601String(),
        'to': day.toIso8601String(),
        'minutes': done.minutes.round(),
        'z4': done.z4Min.round(),
      },
    );
    return PlanChanges(release: {session.id});
  }

  Future<void> _record({
    required String group,
    required String kind,
    required TrainingSession before,
    required ActivityRecord activity,
    required String reason,
    required Map<String, Object?> params,
  }) => db
      .into(db.planAdjustments)
      .insert(
        PlanAdjustmentsCompanion.insert(
          id: const Uuid().v4(),
          groupId: group,
          createdAt: DateTime.now(),
          kind: kind,
          sessionId: before.id,
          activityId: Value(activity.activityId),
          beforeJson: jsonEncode(before.toJson()),
          reasonCode: reason,
          paramsJson: Value(jsonEncode(params)),
        ),
      );

  /// Writes [old] back and removes what its completion added.
  Future<void> _restore(TrainingSession old) async {
    await db.transaction(() async {
      if (!const {'completed'}.contains(old.status)) {
        for (final delete in [
          db.delete(db.sessionActuals)
            ..where((t) => t.sessionId.equals(old.id)),
          db.delete(db.sessionNts)..where((t) => t.sessionId.equals(old.id)),
          db.delete(db.sessionXp)..where((t) => t.sessionId.equals(old.id)),
        ]) {
          await delete.go();
        }
      }
      await db
          .into(db.trainingSessions)
          .insertOnConflictUpdate(
            old.toCompanion(true).copyWith(dateModified: Value(DateTime.now())),
          );
    });
  }

  /// Takes back one decision: every session of [groupId] as it was. The
  /// workout is not placed the same way again.
  Future<PlanChanges> undo(String groupId) async {
    final rows = await (db.select(
      db.planAdjustments,
    )..where((t) => t.groupId.equals(groupId) & t.undoneAt.isNull())).get();
    final deliver = <String>{};
    final weeks = <DateTime>{};
    for (final x in rows.reversed) {
      final old = TrainingSession.fromJson(
        jsonDecode(x.beforeJson) as Map<String, dynamic>,
      );
      final now = await (db.select(
        db.trainingSessions,
      )..where((t) => t.id.equals(old.id))).getSingleOrNull();
      await _restore(old);
      weeks
        ..add(_day(old.sessionDate))
        ..addAll([if (now != null) _day(now.sessionDate)]);
      deliver.add(old.id);
    }
    await (db.update(db.planAdjustments)
          ..where((t) => t.groupId.equals(groupId) & t.undoneAt.isNull()))
        .write(PlanAdjustmentsCompanion(undoneAt: Value(DateTime.now())));
    for (final d in weeks) {
      await scorer.refreshWeek(d);
    }
    return PlanChanges(deliver: deliver);
  }

  /// A workout was deleted: every decision about it is undone, and the
  /// session it completed is open again.
  Future<PlanChanges> forgetActivity(String activityId) async {
    var changes = const PlanChanges();
    final groups = {
      for (final x
          in await (db.select(db.planAdjustments)..where(
                (t) => t.activityId.equals(activityId) & t.undoneAt.isNull(),
              ))
              .get())
        x.groupId,
    };
    for (final g in groups) {
      changes += await undo(g);
    }
    final linked = await (db.select(
      db.sessionActuals,
    )..where((t) => t.activityId.equals(activityId))).get();
    for (final actual in linked) {
      final s = await (db.select(
        db.trainingSessions,
      )..where((t) => t.id.equals(actual.sessionId))).getSingleOrNull();
      await db.transaction(() async {
        for (final delete in [
          db.delete(db.sessionActuals)
            ..where((t) => t.sessionId.equals(actual.sessionId)),
          db.delete(db.sessionNts)
            ..where((t) => t.sessionId.equals(actual.sessionId)),
          db.delete(db.sessionXp)
            ..where((t) => t.sessionId.equals(actual.sessionId)),
        ]) {
          await delete.go();
        }
        await (db.update(
          db.trainingSessions,
        )..where((t) => t.id.equals(actual.sessionId))).write(
          TrainingSessionsCompanion(
            status: Value(actual.scoredVsAdapted ? 'adapted' : 'planned'),
            actualDurationMin: const Value(null),
            dateModified: Value(DateTime.now()),
          ),
        );
      });
      if (s != null) {
        await scorer.refreshWeek(s.sessionDate);
        changes += PlanChanges(deliver: {s.id});
      }
    }
    return changes;
  }
}
