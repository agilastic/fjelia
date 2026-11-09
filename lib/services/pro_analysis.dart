import 'package:fjelia_service/fjelia_service.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:intl/intl.dart';

import '../db/database.dart';
import 'coach_language.dart';

export 'package:fjelia_service_api/fjelia_service_api.dart'
    show ProAnalysisKind;

/// Which analysis a report is: the kind and what it is about (the day, the
/// ISO week, the race goal, the season's year), so a day's plan check or a
/// race's plan is kept and read again rather than written anew.
class ProAnalysisRef {
  const ProAnalysisRef(this.kind, this.key, {this.goal});
  final ProAnalysisKind kind;
  final String key;
  final RaceGoal? goal;

  String get id => '${kind.name}:$key';

  static ProAnalysisRef planCheck(DateTime day) => ProAnalysisRef(
    ProAnalysisKind.planCheck,
    DateFormat('yyyy-MM-dd').format(day),
  );

  /// The seven days up to [day], named after its ISO week.
  static ProAnalysisRef weekReview(DateTime day) {
    final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
    final week =
        ((thursday.difference(DateTime(thursday.year)).inDays) ~/ 7) + 1;
    return ProAnalysisRef(
      ProAnalysisKind.weekReview,
      '${thursday.year}-W${week.toString().padLeft(2, '0')}',
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
      return 'Review of my last 7 days up to today, $today.';
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
