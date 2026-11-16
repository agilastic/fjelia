import 'package:fjelia_service/fjelia_service.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:intl/intl.dart';

import '../db/database.dart';
import '../utils/week.dart';
import 'coach_language.dart';

export 'package:fjelia_service_api/fjelia_service_api.dart'
    show ProAnalysisKind;

/// Which analysis a report is: the kind and what it is about (the day, the
/// ISO week, the race goal, the season's year), so a day's plan check or a
/// race's plan is kept and read again rather than written anew.
class ProAnalysisRef {
  const ProAnalysisRef(this.kind, this.key, {this.goal, this.until});
  final ProAnalysisKind kind;
  final String key;
  final RaceGoal? goal;

  /// The last day a week review covers, for a finished week; null for the
  /// seven days up to now.
  final DateTime? until;

  String get id => '${kind.name}:$key';

  static ProAnalysisRef planCheck(DateTime day) => ProAnalysisRef(
    ProAnalysisKind.planCheck,
    DateFormat('yyyy-MM-dd').format(day),
  );

  /// The seven days up to [day], named after the ISO week of the athlete's
  /// week that holds it. A week that starts on Sunday is named after its
  /// Monday, so every week of either kind has one name.
  static ProAnalysisRef weekReview(DateTime day, {bool mondayFirst = true}) =>
      ProAnalysisRef(
        ProAnalysisKind.weekReview,
        weekReviewKey(day, mondayFirst: mondayFirst),
      );

  /// The finished week before the one [day] is in: the review written when
  /// a new week begins.
  static ProAnalysisRef lastWeekReview(
    DateTime day, {
    bool mondayFirst = true,
  }) {
    final start = weekStartOf(day, mondayFirst: mondayFirst);
    final last = DateTime(start.year, start.month, start.day - 1);
    return ProAnalysisRef(
      ProAnalysisKind.weekReview,
      weekReviewKey(last, mondayFirst: mondayFirst),
      until: last,
    );
  }

  static String weekReviewKey(DateTime day, {bool mondayFirst = true}) {
    final start = weekStartOf(day, mondayFirst: mondayFirst);
    final monday = DateTime(start.year, start.month, start.day + 1);
    final thursday = monday.add(
      Duration(days: DateTime.thursday - monday.weekday),
    );
    final week =
        ((thursday.difference(DateTime(thursday.year)).inDays) ~/ 7) + 1;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  /// The Monday of the ISO week [key] names ("2026-W46"), or null.
  static DateTime? weekReviewMonday(String key) {
    final m = RegExp(r'^(\d{4})-W(\d{2})$').firstMatch(key);
    if (m == null) return null;
    final year = int.parse(m[1]!), week = int.parse(m[2]!);
    // ISO week 1 holds January 4th.
    final jan4 = DateTime(year, 1, 4);
    final firstMonday = DateTime(year, 1, 4 - (jan4.weekday - 1));
    return DateTime(
      firstMonday.year,
      firstMonday.month,
      firstMonday.day + 7 * (week - 1),
    );
  }

  static ProAnalysisRef racePlan(RaceGoal goal) =>
      ProAnalysisRef(ProAnalysisKind.racePlan, goal.id, goal: goal);

  static ProAnalysisRef season(DateTime day) =>
      ProAnalysisRef(ProAnalysisKind.season, '${day.year}');
}

/// The coach's instructions live in the private package; builds without it
/// never offer FjeliaPro.
final proAnalysisPrompts = createProAnalysisPrompts();

/// The instructions for [ref], in the app language.
String proAnalysisInstructions(ProAnalysisRef ref) =>
    '${proAnalysisPrompts.instructions(ref.kind)}\n${coachLanguageDirective()}';

/// The athlete's message for [ref]: what the analysis is about.
String proAnalysisRequest(ProAnalysisRef ref, DateTime now) {
  final today = DateFormat('yyyy-MM-dd (EEEE)', 'en').format(now);
  switch (ref.kind) {
    case ProAnalysisKind.planCheck:
      return 'Plan check for today, $today.';
    case ProAnalysisKind.weekReview:
      final until = ref.until;
      return until == null
          ? 'Review of my last 7 days up to today, $today.'
          : 'Review of my finished training week, the 7 days up to '
                '${DateFormat('yyyy-MM-dd (EEEE)', 'en').format(until)}.';
    case ProAnalysisKind.season:
      return 'Season analysis, today is $today.';
    case ProAnalysisKind.racePlan:
      final g = ref.goal!;
      final days = DateTime(
        g.raceDate.year,
        g.raceDate.month,
        g.raceDate.day,
      ).difference(DateTime(now.year, now.month, now.day)).inDays;
      final target = g.targetFinishSeconds;
      return [
        'Race plan for my goal "${g.name}":',
        'sport ${g.primarySport}, ${(g.distanceM / 1000).toStringAsFixed(1)} km',
        if (g.elevationM != null) '${g.elevationM!.round()} m elevation',
        'on ${DateFormat('yyyy-MM-dd').format(g.raceDate)} ($days days from today, $today)',
        if (target != null)
          'target time ${target ~/ 3600}:${(target ~/ 60 % 60).toString().padLeft(2, '0')}:${(target % 60).toString().padLeft(2, '0')}',
        'priority ${g.priority}',
        if (g.ambition != null) 'ambition ${g.ambition}',
      ].join(', ');
  }
}
