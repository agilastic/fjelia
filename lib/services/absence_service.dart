import 'package:drift/drift.dart';

import '../db/database.dart';
import 'plan_session_actions.dart';
import 'post_workout_scorer.dart' show noActivityReason;

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
  Future<int> add({
    required String kind,
    required DateTime start,
    required DateTime end,
    String? note,
  }) async {
    final from = _day(start.isAfter(end) ? end : start);
    final to = _day(start.isAfter(end) ? start : end);
    await db
        .into(db.absences)
        .insert(
          AbsencesCompanion.insert(
            kind: kind,
            startDay: from,
            endDay: to,
            note: Value(note?.trim().isEmpty ?? true ? null : note!.trim()),
            createdAt: DateTime.now(),
          ),
        );
    final reasons = {
      for (final a in await db.select(db.sessionActuals).get())
        a.sessionId: a.skipReason,
    };
    var cancelled = 0;
    for (final s in await _sessions(from, to)) {
      final open = s.status == 'planned' || s.status == 'adapted';
      // A day closed as missed was this absence: it says so now.
      final missed = s.status == 'skipped' && reasons[s.id] == noActivityReason;
      if (!open && !missed) continue;
      await actions.markRest(s, reason: absenceSkipReason(kind));
      cancelled++;
    }
    return cancelled;
  }

  /// Removes an absence. Sessions still ahead that it cancelled are planned
  /// again; past ones stay cancelled.
  Future<void> remove(Absence absence) async {
    await (db.delete(db.absences)..where((t) => t.id.equals(absence.id))).go();
    final today = _day(DateTime.now());
    final from = absence.startDay.isBefore(today) ? today : absence.startDay;
    if (from.isAfter(absence.endDay)) return;
    final reason = absenceSkipReason(absence.kind);
    final reasons = {
      for (final a in await db.select(db.sessionActuals).get())
        a.sessionId: a.skipReason,
    };
    // Days another absence still covers stay cancelled.
    final others = await db.absencesBetween(from, absence.endDay);
    for (final s in await _sessions(from, absence.endDay)) {
      if (s.status != 'skipped' || reasons[s.id] != reason) continue;
      final covered = others.any(
        (o) =>
            !s.sessionDate.isBefore(o.startDay) &&
            !_day(s.sessionDate).isAfter(o.endDay),
      );
      if (covered) continue;
      try {
        await actions.restore(s);
      } on StateError {
        // Its replacement is already done: it stays cancelled.
      }
    }
  }
}
