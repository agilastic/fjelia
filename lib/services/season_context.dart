import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../db/database.dart';
import '../l10n/app_localizations.dart';
import '../l10n/plan_text.dart';
import '../services/season/season_report.dart';
import '../theme/activity_colors.dart';

/// The season by weeks, for the Pro season analysis and race plan: what was
/// trained in the last [historyWeeks] weeks and what the plan holds until the
/// last race goal. One line per week, so a model sees the build and its
/// jumps rather than single sessions.
///
/// Lines:
/// `[SeasonHistory:Week,…]` one past week: hours by sport, load, the longest
/// session, sessions done and planned ones missed or skipped;
/// `[SeasonPlan:Week,…]` one coming week: phases, planned hours by sport,
/// the longest session, key sessions and the race goals in it.
Future<List<String>> seasonWeekLines(
  AppDatabase db,
  DateTime today, {
  int historyWeeks = 16,
  int maxPlanWeeks = 40,
}) async {
  final monday = DateTime(
    today.year,
    today.month,
    today.day - today.weekday + 1,
  );
  final historyFrom = DateTime(
    monday.year,
    monday.month,
    monday.day - 7 * historyWeeks,
  );
  final goals =
      await (db.select(db.raceGoals)
            ..where(
              (t) =>
                  t.athleteId.equals('self') &
                  t.raceDate.isBiggerOrEqualValue(monday) &
                  t.participation.equals('cancelled').not(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.raceDate)]))
          .get();
  final lastGoal = goals.isEmpty ? null : goals.last.raceDate;
  final planWeeks = lastGoal == null
      ? 4
      : (lastGoal.difference(monday).inDays ~/ 7 + 1).clamp(1, maxPlanWeeks);
  final planTo = DateTime(
    monday.year,
    monday.month,
    monday.day + 7 * planWeeks,
  );

  final activities =
      await (db.select(db.activityRecords)..where(
            (t) =>
                t.startDate.isBiggerOrEqualValue(historyFrom) &
                t.startDate.isSmallerThanValue(monday),
          ))
          .get();
  final sessions =
      await (db.select(db.trainingSessions)..where(
            (t) =>
                t.athleteId.equals('self') &
                t.sessionDate.isBiggerOrEqualValue(historyFrom) &
                t.sessionDate.isSmallerThanValue(planTo),
          ))
          .get();

  /// The week of [d] counted from this week's Monday (negative: before).
  int weekOf(DateTime d) =>
      (DateTime(d.year, d.month, d.day).difference(monday).inDays / 7).floor();
  String start(int w) =>
      DateFormat('yyyy-MM-dd')
          .format(DateTime(monday.year, monday.month, monday.day + 7 * w));
  String sport(String type) => switch (activityKind(type)) {
    ActivityKind.other => type.replaceAll(RegExp(r'[,\[\]]'), ' '),
    final k => k.name,
  };
  String hours(Map<String, double> bySport) {
    final parts = bySport.entries.where((e) => e.value >= .05).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return parts.isEmpty
        ? 'none'
        : parts.map((e) => '${e.key} ${e.value.toStringAsFixed(1)}').join(' ');
  }

  final lines = <String>[];
  for (var w = -historyWeeks; w < 0; w++) {
    final done = [
      for (final a in activities)
        if (weekOf(a.startDate) == w) a,
    ];
    final planned = [
      for (final s in sessions)
        if (weekOf(s.sessionDate) == w) s,
    ];
    final bySport = <String, double>{};
    for (final a in done) {
      bySport.update(
        sport(a.type),
        (h) => h + a.durationSeconds / 3600,
        ifAbsent: () => a.durationSeconds / 3600,
      );
    }
    final longest = done.isEmpty
        ? null
        : done.reduce((a, b) => a.durationSeconds >= b.durationSeconds ? a : b);
    final load = done.fold<double>(0, (s, a) => s + (a.trainingLoad ?? 0));
    final missed = planned
        .where((s) => s.status != 'completed' && s.status != 'done')
        .length;
    lines.add(
      '[SeasonHistory:Week,${['start:${start(w)}', 'hours:${hours(bySport)}', if (load > 0) 'load:${load.round()}', if (longest != null) 'longest:${(longest.durationSeconds / 60).round()}min ${sport(longest.type)}', 'sessions:${done.length}', if (planned.isNotEmpty) 'planned:${planned.length}', if (planned.isNotEmpty) 'notDone:$missed'].join(',')}]',
    );
  }
  for (var w = 0; w < planWeeks; w++) {
    final planned = [
      for (final s in sessions)
        if (weekOf(s.sessionDate) == w && s.status != 'skipped') s,
    ];
    final weekStart = DateTime(monday.year, monday.month, monday.day + 7 * w);
    final weekEnd = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 7,
    );
    final races = [
      for (final g in goals)
        if (!g.raceDate.isBefore(weekStart) && g.raceDate.isBefore(weekEnd))
          '${g.name.replaceAll(RegExp(r'[,\[\]]'), ' ')} (${g.priority})',
    ];
    if (planned.isEmpty && races.isEmpty) {
      lines.add('[SeasonPlan:Week,start:${start(w)},sessions:0]');
      continue;
    }
    final bySport = <String, double>{};
    for (final s in planned) {
      bySport.update(
        sport(s.sport),
        (h) => h + s.plannedDurationMin / 60,
        ifAbsent: () => s.plannedDurationMin / 60,
      );
    }
    final longest = planned.isEmpty
        ? null
        : planned.reduce(
            (a, b) => a.plannedDurationMin >= b.plannedDurationMin ? a : b,
          );
    final phases = {for (final s in planned) s.phase};
    lines.add(
      '[SeasonPlan:Week,${['start:${start(w)}', if (phases.isNotEmpty) 'phase:${phases.join('/')}', 'hours:${hours(bySport)}', if (longest != null) 'longest:${longest.plannedDurationMin}min ${sport(longest.sport)}', 'key:${planned.where((s) => s.sessionType == 'key').length}', 'sessions:${planned.length}', if (races.isNotEmpty) 'race:${races.join(' + ')}'].join(',')}]',
    );
  }
  return lines;
}

/// The season planner's verdict for the Pro season analysis: the outcome,
/// each conflict and trade-off in words and the ways out it offers. This
/// used to be the season card on the plan. Goal names become their priority,
/// sport and date, as everywhere in the context.
///
/// `[SeasonCheck:Outcome,…]` then one `[SeasonCheckNote:…]` per line and one
/// `[SeasonCheckOption:…]` per alternative.
Future<List<String>> seasonCheckLines(AppDatabase db) async {
  final plan =
      await (db.select(db.trainingPlans)
            ..where(
              (t) => t.athleteId.equals('self') & t.status.equals('active'),
            )
            ..limit(1))
          .getSingleOrNull();
  final report = SeasonReport.decode(plan?.seasonJson);
  if (report == null) return const [];
  final en = lookupAppLocalizations(const Locale('en'));
  final goals = report['goals'] is Map ? report['goals'] as Map : const {};
  String anonymous(String line) {
    var out = line;
    for (final g in goals.values) {
      if (g is! Map || g['name'] is! String || (g['name'] as String).isEmpty) {
        continue;
      }
      out = out.replaceAll(
        g['name'] as String,
        '${g['priority']}-goal ${g['sport']} ${g['date']}',
      );
    }
    return out.replaceAll(RegExp(r'[\[\]\n\r]'), ' ').trim();
  }

  return [
    '[SeasonCheck:Outcome,${report['outcome'] ?? 'na'}]',
    for (final line in seasonReportLines(en, report))
      '[SeasonCheckNote:${anonymous(line)}]',
    for (final alt in seasonAlternatives(en, report))
      '[SeasonCheckOption:${anonymous(alt)}]',
  ];
}
