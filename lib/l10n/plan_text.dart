import 'app_localizations.dart';
import '../screens/planner/plan_week_agenda.dart' show sportLabel;

/// The planner writes its words in English: they are stored with the plan and
/// read by the coach. These turn them into the athlete's language for the
/// screen. Anything not recognised is shown as it was written.

bool _english(AppLocalizations l) => l.localeName.startsWith('en');

/// Phase badge, e.g. BASE.
String planPhaseLabel(AppLocalizations l, String phase) => switch (phase) {
  'base' => l.phaseBase,
  'build' => l.phaseBuild,
  'peak' => l.phasePeak,
  'taper' => l.phaseTaper,
  'recovery' => l.phaseRecovery,
  'race' => l.phaseRace,
  _ => phase.toUpperCase(),
};

/// Session type badge, e.g. LONG.
String sessionTypeLabel(AppLocalizations l, String type) => switch (type) {
  'key' => l.sessionTypeKey,
  'long' => l.sessionTypeLong,
  'recovery' => l.sessionTypeRecovery,
  'assessment' => l.sessionTypeAssessment,
  'endurance' => l.sessionTypeEndurance,
  'strength' => l.sessionTypeStrength,
  'yoga' => l.sessionTypeYoga,
  _ => type.toUpperCase(),
};

/// Session status badge, e.g. PLANNED.
String sessionStatusLabel(AppLocalizations l, String status) =>
    switch (status) {
      'planned' => l.planned,
      'completed' => l.sessionStatusCompleted,
      'adapted' => l.sessionStatusAdapted,
      _ => status.toUpperCase(),
    };

/// The role of a workout step (`Warm-up`, `Interval`, …, the English ids
/// the step models use).
String stepRoleLabel(AppLocalizations l, String role) => switch (role) {
  'Warm-up' => l.stepWarmUp,
  'Cool-down' => l.stepCoolDown,
  'Recovery' => l.stepRecovery,
  'Rest' => l.stepRest,
  'Interval' => l.stepInterval,
  'Workout' => l.stepWorkout,
  _ => role,
};

/// The amount of a step: `4× repeat`, `30 sec`, `5 min 30 sec`, `Open-ended`.
String stepAmountLabel(AppLocalizations l, String amount) {
  if (_english(l)) return amount;
  final repeat = RegExp(r'^(\d+)× repeat$').firstMatch(amount);
  if (repeat != null) return l.stepRepeat(int.parse(repeat[1]!));
  if (amount == 'Open-ended') return l.stepOpenEnded;
  return amount.replaceAllMapped(
    RegExp(r'(\d+) sec\b'),
    (m) => l.stepSeconds(int.parse(m[1]!)),
  );
}

String _sport(AppLocalizations l, String noun) => switch (noun) {
  'run' => sportLabel('running'),
  'ride' => sportLabel('cycling'),
  'swim' => sportLabel('swimming'),
  _ => sportLabel(noun.replaceAll(' ', '_')),
};

/// Restores a goal name the planner lowercased, from the names it knows.
String _goal(String text, Iterable<String> goalNames) {
  for (final name in goalNames) {
    if (name.toLowerCase() == text.toLowerCase()) return name;
  }
  return text;
}

/// What a session is for, as the week allocator wrote it ("Long run for
/// Hannover Marathon"). Case-insensitive, because trade-off lines carry it
/// lowercased.
String planObjectiveLabel(
  AppLocalizations l,
  String text, {
  Iterable<String> goalNames = const [],
}) {
  if (_english(l)) return text;
  final t = text.trim().replaceFirst(RegExp(r'\.$'), '');
  RegExpMatch? m(String pattern) =>
      RegExp('^$pattern\$', caseSensitive: false).firstMatch(t);
  String g(RegExpMatch match, int i) => _goal(match[i]!, goalNames);
  if (m('optional variety you chose in the settings') != null) {
    return l.objectiveOptionalVariety;
  }
  if (m('strength to support your training') != null) {
    return l.objectiveStrengthSupport;
  }
  if (m(r'intervals for (.+)') case final x?) {
    return l.objectiveIntervals(g(x, 1));
  }
  if (m(r'steady quality (.+?) for (.+)') case final x?) {
    return l.objectiveSteady(_sport(l, x[1]!), g(x, 2));
  }
  if (m(r'easy (.+?): recovery around (.+)') case final x?) {
    return l.objectiveEasyRecovery(_sport(l, x[1]!), g(x, 2));
  }
  if (m(r'easy endurance (.+?) for (.+)') case final x?) {
    return l.objectiveEasyEndurance(_sport(l, x[1]!), g(x, 2));
  }
  if (m(r'long (.+?) for (.+)') case final x?) {
    return l.objectiveLong(_sport(l, x[1]!), g(x, 2));
  }
  return text;
}

/// A session a week could not hold, as the week allocator wrote it.
String planUnmetLabel(
  AppLocalizations l,
  String text, {
  Iterable<String> goalNames = const [],
}) {
  if (_english(l)) return text;
  String objective(String s) => planObjectiveLabel(l, s, goalNames: goalNames);
  final minutes = RegExp(
    r'^The week holds (\d+) min, too little for a long (.+?) for (.+)\.$',
  ).firstMatch(text);
  if (minutes != null) {
    return l.unmetWeekMinutes(
      int.parse(minutes[1]!),
      _sport(l, minutes[2]!),
      _goal(minutes[3]!, goalNames),
    );
  }
  final hours = RegExp(r'^The week holds ([\d.]+) h, too little for (.+)\.$')
      .firstMatch(text);
  if (hours != null) {
    return l.unmetWeekHours(hours[1]!, objective(hours[2]!));
  }
  final days = RegExp(r'^Not enough training days for (.+)\.$')
      .firstMatch(text);
  if (days != null) return l.unmetTrainingDays(objective(days[1]!));
  return text;
}

/// The season card's lines in the athlete's language: the conflicts from
/// their kind and numbers, then the trade-offs from their codes. A season
/// stored before the codes existed shows its English summary.
List<String> seasonReportLines(
  AppLocalizations l,
  Map<String, dynamic> report,
) {
  final goals = report['goals'] is Map ? report['goals'] as Map : const {};
  final names = [
    for (final g in goals.values)
      if (g is Map && g['name'] is String) g['name'] as String,
  ];
  String name(Object? id) {
    final g = goals[id];
    return g is Map && g['name'] is String ? g['name'] as String : '$id';
  }

  final out = <String>[];
  for (final c in (report['conflicts'] as List? ?? const [])) {
    if (c is! Map) continue;
    out.add(_conflictLine(l, c, name) ?? '${c['message']}');
  }
  final summary = [
    for (final t in (report['summary'] as List? ?? const [])) '$t',
  ];
  final codes = report['summaryCodes'];
  if (codes is! List || codes.length != summary.length || _english(l)) {
    return [...out, ...summary];
  }
  for (final (i, c) in codes.indexed) {
    out.add((c is Map ? _summaryLine(l, c, names) : null) ?? summary[i]);
  }
  return out;
}

/// The alternatives of the season's conflicts, in the athlete's language.
List<String> seasonAlternatives(
  AppLocalizations l,
  Map<String, dynamic> report,
) {
  final goals = report['goals'] is Map ? report['goals'] as Map : const {};
  String name(Object? id) {
    final g = goals[id];
    return g is Map && g['name'] is String ? g['name'] as String : '$id';
  }

  final out = <String>[];
  for (final c in (report['conflicts'] as List? ?? const [])) {
    if (c is! Map) continue;
    final ids = c['goals'] is List ? c['goals'] as List : const [];
    final stored = [
      for (final a in (c['alternatives'] as List? ?? const [])) '$a',
    ];
    if (_english(l) || ids.length != 2) {
      out.addAll(stored);
      continue;
    }
    final first = name(ids[0]), second = name(ids[1]);
    out.addAll([
      for (final a in stored)
        switch (a) {
          'Move one of the events' => l.altMoveOneEvent,
          'Mark one as cancelled' => l.altMarkOneCancelled,
          _ when a == 'Make $first priority B' => l.altMakePriorityB(first),
          _ when a == 'Make $second priority B' => l.altMakePriorityB(second),
          _ when a == 'Skip $first' => l.altSkipGoal(first),
          _ when a == 'Skip $second' => l.altSkipGoal(second),
          _ when a == 'Treat $first as a training event' =>
            l.altTreatAsTraining(first),
          _ when a == 'Ride $first as a controlled effort' =>
            l.altControlledEffort(first),
          _ => a,
        },
    ]);
  }
  return out;
}

String? _conflictLine(
  AppLocalizations l,
  Map c,
  String Function(Object?) name,
) {
  if (_english(l)) return null;
  final ids = c['goals'] is List ? c['goals'] as List : const [];
  if (ids.length != 2) return null;
  final a = name(ids[0]), b = name(ids[1]);
  final gap = (c['gapDays'] as num?)?.toInt() ?? 0;
  final slack = (c['slackDays'] as num?)?.toInt() ?? 0;
  // The flexible goal is the one the alternative offers to skip.
  final skip = [
    for (final alt in (c['alternatives'] as List? ?? const []))
      if ('$alt'.startsWith('Skip ')) '$alt'.substring(5),
  ].firstOrNull;
  return switch (c['kind']) {
    'sameDay' => l.conflictSameDay(a, b),
    'closeHighPriority' => l.conflictBothPriorityA(a, b, gap, -slack),
    'flexibleOverlap' => l.conflictFlexibleOverlap(
      a,
      b,
      gap,
      -slack,
      skip ?? b,
    ),
    'recoveryMeetsSharpening' => l.conflictRecoveryOverlap(a, b, gap, -slack),
    'tightSpacing' => l.conflictTightSpacing(a, b, gap, slack),
    _ => null,
  };
}

String? _summaryLine(AppLocalizations l, Map c, List<String> names) {
  int n(String key) => (c[key] as num?)?.toInt() ?? 0;
  return switch (c['code']) {
    'shortened' => l.seasonShortened(n('n'), n('of')),
    'alternating' => l.seasonAlternating(n('n')),
    'longAway' => l.seasonLongAway(n('n')),
    'movedOntoEvent' => l.seasonMovedOntoEvent(n('n')),
    'noRoom' => l.seasonNoRoom(n('n')),
    'movedHardNearEvent' => l.seasonMovedHardNearEvent(n('n')),
    'eventWeeks' => l.seasonEventWeeks,
    'unmet' => l.seasonUnmet(
      n('n'),
      planUnmetLabel(l, '${c['detail']}', goalNames: names),
    ),
    'noHistory' => l.seasonNoHistory(
      sportLabel('${c['sport']}'),
      '${c['priority']}',
    ),
    _ => null,
  };
}
