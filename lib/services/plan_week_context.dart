import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../db/database.dart';

/// The plan of the last days as it went, for the Pro analyses: every planned
/// session with its status (done, missed, skipped with its reason, moved),
/// planned against done, the plan's own changes and the training nobody
/// planned. The general coach context lists the coming sessions only.
///
/// Lines:
/// `[PlanWeek:Session,…]` one planned session;
/// `[PlanWeek:Change,…]` one change the plan made, with its reason;
/// `[PlanWeek:Extra,…]` an activity no session accounts for.
Future<List<String>> planWeekLines(
  AppDatabase db,
  DateTime today, {
  int days = 7,
}) async {
  final from = DateTime(today.year, today.month, today.day - days + 1);
  final to = DateTime(today.year, today.month, today.day + 1);
  final sessions =
      await (db.select(db.trainingSessions)
            ..where(
              (t) =>
                  t.athleteId.equals('self') &
                  t.sessionDate.isBiggerOrEqualValue(from) &
                  t.sessionDate.isSmallerThanValue(to),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)]))
          .get();
  final actuals = {
    for (final a in await (db.select(
      db.sessionActuals,
    )..where((t) => t.sessionId.isIn(sessions.map((s) => s.id)))).get())
      a.sessionId: a,
  };
  final activities =
      await (db.select(db.activityRecords)
            ..where(
              (t) =>
                  t.startDate.isBiggerOrEqualValue(from) &
                  t.startDate.isSmallerThanValue(to),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
          .get();
  final byId = {for (final a in activities) a.activityId: a};
  final changes =
      await (db.select(db.planAdjustments)
            ..where(
              (t) =>
                  t.createdAt.isBiggerOrEqualValue(from) &
                  t.createdAt.isSmallerThanValue(to) &
                  t.undoneAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  String day(DateTime d) => DateFormat('yyyy-MM-dd EEE', 'en').format(d);
  String clean(String s) => s.replaceAll(RegExp(r'[,\[\]\n]'), ' ').trim();
  final title = {for (final s in sessions) s.id: s.title};
  final used = <String>{};
  final lines = <String>[];
  for (final s in sessions) {
    final a = actuals[s.id];
    final done = a?.activityId ?? a?.creditedByActivityId;
    if (done != null) used.add(done);
    final activity = done == null ? null : byId[done];
    final status = switch (s.status) {
      'completed' || 'done' => 'done',
      'skipped' => 'skipped',
      'planned'
          when s.sessionDate.isBefore(from.add(Duration(days: days - 1))) =>
        done == null ? 'missed' : 'done',
      final other => other,
    };
    lines.add(
      '[PlanWeek:Session,${['date:${day(s.sessionDate)}', 'title:${clean(s.title)}', 'sport:${s.sport}', 'type:${s.sessionType}${s.subType == null ? '' : '/${s.subType}'}', 'zone:Z${s.primaryZone}', 'planned:${s.plannedDurationMin}min', 'status:$status', if (activity != null) 'actual:${(activity.durationSeconds / 60).round()}min ${clean(activity.name)}', if (a?.durationRatio != null) 'durationRatio:${a!.durationRatio!.toStringAsFixed(2)}', if (a?.executionScore != null) 'execution:${a!.executionScore}/100', if (a?.intensityVerdict != null) 'intensity:${clean(a!.intensityVerdict!)}', if (a?.outcome != null) 'outcome:${clean(a!.outcome!)}', if (a?.skipReason != null) 'reason:${clean(a!.skipReason!)}', if (a?.shortReason != null) 'shortReason:${clean(a!.shortReason!)}', if (activity?.athleteNote?.trim().isNotEmpty ?? false) 'note:${clean(activity!.athleteNote!.trim())}', if (s.sessionDateOriginal != null || s.priorSessionDate != null) 'movedFrom:${s.sessionDateOriginal ?? s.priorSessionDate}', if (a?.rpe != null) 'rpe:${a!.rpe}'].join(',')}]',
    );
  }
  for (final c in changes) {
    lines.add(
      '[PlanWeek:Change,${['date:${day(c.createdAt)}', 'kind:${c.kind}', 'session:${clean(title[c.sessionId] ?? c.sessionId)}', 'reason:${c.reasonCode}', 'by:${c.source}'].join(',')}]',
    );
  }
  for (final a in activities) {
    if (used.contains(a.activityId)) continue;
    lines.add(
      '[PlanWeek:Extra,${['date:${day(a.startDate)}', 'name:${clean(a.name)}', 'type:${a.type}', 'duration:${(a.durationSeconds / 60).round()}min', if (a.trainingLoad != null) 'load:${a.trainingLoad!.round()}', if (a.athleteNote?.trim().isNotEmpty ?? false) 'note:${clean(a.athleteNote!.trim())}'].join(',')}]',
    );
  }
  return lines;
}
