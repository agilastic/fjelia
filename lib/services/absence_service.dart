import 'package:drift/drift.dart';
import 'package:fjelia_core/services/absence.dart';

import '../db/database.dart';
import 'plan_session_actions.dart';
import 'post_workout_scorer.dart' show noActivityReason;

export 'package:fjelia_core/services/absence.dart';

/// The kinds of absence, in the order they are offered.
const absenceKinds = ['illness', 'injury', 'vacation', 'offseason'];

/// Stored on sessions the off-season cancels.
const offSeasonReason = 'Off-season';

/// The skip reason a session cancelled by an absence of [kind] gets.
String absenceSkipReason(String kind) => switch (kind) {
  'illness' => 'Illness',
  'injury' => 'Injury or pain',
  'vacation' => 'Travel',
  _ => offSeasonReason,
};

/// Enters and removes absences. Sessions on their days are cancelled with
/// the absence's reason; the plan is then built again around them.
class AbsenceService {
  AbsenceService(this.db, this.actions);
  final AppDatabase db;
  final PlanSessionActions actions;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Sessions from [from] to [to] (days, both included).
  Future<List<TrainingSession>> _sessions(DateTime from, DateTime to) =>
      (db.select(db.trainingSessions)..where(
            (t) =>
                t.athleteId.equals('self') &
                t.sessionDate.isBiggerOrEqualValue(_day(from)) &
                t.sessionDate.isSmallerThanValue(
                  _day(to).add(const Duration(days: 1)),
                ),
          ))
          .get();

  /// Enters an absence and cancels what was planned on its days; a session
  /// already done stays. Returns how many were cancelled.
  ///
  /// With [openEnd] the end is not known: the absence covers [start] up to
  /// tomorrow and [extendOpen] carries it on day by day.
  Future<int> add({
    required String kind,
    required DateTime start,
    required DateTime end,
    String? note,
    bool openEnd = false,
    DateTime? now,
  }) async {
    final from = _day(start.isAfter(end) ? end : start);
    var to = _day(start.isAfter(end) ? start : end);
    if (openEnd) {
      final tomorrow = _day(now ?? DateTime.now()).add(const Duration(days: 1));
      if (to.isBefore(tomorrow)) to = tomorrow;
    }
    await db
        .into(db.absences)
        .insert(
          AbsencesCompanion.insert(
            kind: kind,
            startDay: from,
            endDay: to,
            note: Value(note?.trim().isEmpty ?? true ? null : note!.trim()),
            createdAt: DateTime.now(),
            openEnd: Value(openEnd),
          ),
        );
    return _cancel(from, to, absenceSkipReason(kind));
  }

  /// Cancels what is planned from [from] to [to] with [reason]; a session
  /// already done stays, and a day closed as missed takes the reason.
  Future<int> _cancel(DateTime from, DateTime to, String reason) async {
    final reasons = {
      for (final a in await db.select(db.sessionActuals).get())
        a.sessionId: a.skipReason,
    };
    var cancelled = 0;
    for (final s in await _sessions(from, to)) {
      final open = s.status == 'planned' || s.status == 'adapted';
      final missed = s.status == 'skipped' && reasons[s.id] == noActivityReason;
      if (!open && !missed) continue;
      await actions.markRest(s, reason: reason);
      cancelled++;
    }
    return cancelled;
  }

  /// Carries every absence with an open end on to tomorrow and cancels what
  /// the new days held. Returns whether any absence grew.
  Future<bool> extendOpen({DateTime? now}) async {
    final tomorrow = _day(now ?? DateTime.now()).add(const Duration(days: 1));
    var grew = false;
    for (final a in await (db.select(
      db.absences,
    )..where((t) => t.openEnd.equals(true))).get()) {
      if (!a.endDay.isBefore(tomorrow)) continue;
      await (db.update(db.absences)..where((t) => t.id.equals(a.id))).write(
        AbsencesCompanion(endDay: Value(tomorrow)),
      );
      await _cancel(
        a.endDay.add(const Duration(days: 1)),
        tomorrow,
        absenceSkipReason(a.kind),
      );
      grew = true;
    }
    return grew;
  }

  /// Fit again: an open absence ends yesterday, and what it cancelled from
  /// today on is planned again. Begun only today, it goes altogether.
  Future<void> endOpen(Absence absence, {DateTime? now}) async {
    final today = _day(now ?? DateTime.now());
    if (!absence.startDay.isBefore(today)) {
      await remove(absence, now: now);
      return;
    }
    await (db.update(db.absences)..where((t) => t.id.equals(absence.id))).write(
      AbsencesCompanion(
        endDay: Value(today.subtract(const Duration(days: 1))),
        openEnd: const Value(false),
      ),
    );
    await _restore(absence, today, absence.endDay);
  }

  /// Removes an absence. Sessions still ahead that it cancelled are planned
  /// again; past ones stay cancelled.
  Future<void> remove(Absence absence, {DateTime? now}) async {
    await (db.delete(db.absences)..where((t) => t.id.equals(absence.id))).go();
    final today = _day(now ?? DateTime.now());
    await _restore(
      absence,
      absence.startDay.isBefore(today) ? today : absence.startDay,
      absence.endDay,
    );
  }

  /// Plans again what [absence] cancelled from [from] to [to], unless
  /// another absence still covers the day.
  Future<void> _restore(Absence absence, DateTime from, DateTime to) async {
    if (from.isAfter(to)) return;
    final reason = absenceSkipReason(absence.kind);
    final reasons = {
      for (final a in await db.select(db.sessionActuals).get())
        a.sessionId: a.skipReason,
    };
    final others = [
      for (final o in await db.absencesBetween(from, to))
        if (o.id != absence.id) o,
    ];
    for (final s in await _sessions(from, to)) {
      if (s.status != 'skipped' || reasons[s.id] != reason) continue;
      if (absenceOn(others, s.sessionDate) != null) continue;
      try {
        await actions.restore(s);
      } on StateError {
        // Its replacement is already done: it stays cancelled.
      }
    }
  }
}
