import 'season_goal.dart';

/// What a day can take, because of an event close to it.
enum DayLoad { free, easyOnly, blocked }

/// What came of combining the goals into one season.
enum FeasibilityOutcome {
  /// A plan satisfies the settings and every goal's preparation.
  feasible,

  /// A plan exists, with limits to a secondary goal's preparation or ambition.
  feasibleWithTradeoffs,

  /// Demands or capacity cannot be judged; the plan is provisional.
  insufficientData,

  /// Alternatives exist but the planner cannot choose which goal to relax.
  requiresDecision,

  /// The declared goals cannot be combined.
  infeasible;

  /// The more serious of two outcomes.
  FeasibilityOutcome worse(FeasibilityOutcome other) =>
      index >= other.index ? this : other;
}

enum ConflictSeverity { info, warning, decision }

enum ConflictKind {
  sameDay,
  closeHighPriority,
  recoveryMeetsSharpening,
  tightSpacing,
  flexibleOverlap,
}

/// A problem between goals, with what the athlete could do about it.
class GoalConflict {
  const GoalConflict({
    required this.kind,
    required this.severity,
    required this.goalIds,
    required this.message,
    this.gapDays,
    this.slackDays,
    this.alternatives = const [],
  });

  final ConflictKind kind;
  final ConflictSeverity severity;
  final List<String> goalIds;
  final String message;

  /// Calendar days between the two events.
  final int? gapDays;

  /// Days left once recovery after the first and sharpening for the second
  /// are counted; negative when they overlap.
  final int? slackDays;
  final List<String> alternatives;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'severity': severity.name,
    'goals': goalIds,
    'message': message,
    if (gapDays != null) 'gapDays': gapDays,
    if (slackDays != null) 'slackDays': slackDays,
    if (alternatives.isNotEmpty) 'alternatives': alternatives,
  };
}

/// Every goal the season has to carry, read once.
///
/// The order is fixed by date, then priority, then id, so the order the rows
/// came in never changes what the planner decides. A cancelled goal stays in
/// [all] for the record but takes no part in planning.
class GoalSet {
  GoalSet(Iterable<SeasonGoal> goals, {required DateTime today})
    : today = localDay(today),
      all = (goals.toList()
        ..sort((a, b) {
          final byDate = a.date.compareTo(b.date);
          if (byDate != 0) return byDate;
          final byPriority = a.priority.index.compareTo(b.priority.index);
          return byPriority != 0 ? byPriority : a.id.compareTo(b.id);
        }));

  /// A set of one goal, for callers that know only one.
  GoalSet.single(SeasonGoal goal, {required DateTime today})
    : this([goal], today: today);

  final DateTime today;
  final List<SeasonGoal> all;

  /// The longest look-ahead: three years.
  static const _horizonDays = 3 * 365;

  /// Goals still to come, today included: an event today is not lost because
  /// its stored midnight is already behind us.
  late final List<SeasonGoal> active = [
    for (final g in all)
      if (g.isActive &&
          daysBetween(today, g.date) >= 0 &&
          daysBetween(today, g.date) <= _horizonDays)
        g,
  ];

  /// Goals behind us whose recovery still shapes the days ahead.
  late final List<SeasonGoal> recent = [
    for (final g in all)
      if (g.isActive &&
          daysBetween(g.date, today) > 0 &&
          daysBetween(g.date, today) <= g.demand.recoveryDays)
        g,
  ];

  /// Active goals and the recent ones: what the timeline looks at.
  List<SeasonGoal> get relevant => [...recent, ...active];

  bool get isEmpty => active.isEmpty;

  /// The goal shown as the plan's own: the most important, then the nearest.
  /// Display only; planning looks at the whole set.
  SeasonGoal? get display {
    if (active.isEmpty) return null;
    final sorted = [...active]
      ..sort((a, b) {
        final p = a.priority.index.compareTo(b.priority.index);
        return p != 0 ? p : a.date.compareTo(b.date);
      });
    return sorted.first;
  }

  /// The day of the last event: where the plan ends.
  DateTime? get horizonEnd => active.isEmpty
      ? null
      : active.map((g) => g.date).reduce((a, b) => a.isAfter(b) ? a : b);

  /// Changes whenever something that shapes a plan changes.
  late final String revision = stableHash(
    '$seasonPolicyVersion;${[for (final g in all) g.revisionKey].join(';')}',
  );

  SeasonGoal? byId(String id) {
    for (final g in all) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// The event that makes [day] unavailable: the goal raced that day, or the
  /// next day's, when the day before is kept free. Null for any other day.
  SeasonGoal? eventBlocking(DateTime day) {
    for (final g in relevant) {
      final offset = daysBetween(g.date, day);
      if (offset == 0) return g;
      final restsBefore =
          g.priority != GoalPriority.c || g.demand.planningMinutes >= 240;
      if (offset == -1 && restsBefore) return g;
    }
    return null;
  }

  /// What [day] can take: nothing on an event day, nothing the day before a
  /// goal that matters, easy sessions only in the first days after one.
  DayLoad loadOn(DateTime day) {
    var load = DayLoad.free;
    for (final g in relevant) {
      final offset = daysBetween(g.date, day);
      final demand = g.demand;
      if (offset == 0) return DayLoad.blocked;
      final restsBefore =
          g.priority != GoalPriority.c || demand.planningMinutes >= 240;
      if (offset == -1 && restsBefore) return DayLoad.blocked;
      // Two days before a long event that matters: easy sessions only.
      if (offset == -2 &&
          g.priority != GoalPriority.c &&
          demand.planningMinutes >= 240) {
        load = DayLoad.easyOnly;
      }
      if (offset > 0 && offset <= demand.easyDaysAfter) load = DayLoad.easyOnly;
    }
    return load;
  }

  /// Problems between goals: events on one day, recovery that meets the next
  /// event's sharpening, and spacing with no slack. Found from the goals'
  /// own demands, not from a fixed number of days.
  late final List<GoalConflict> conflicts = _findConflicts();

  List<GoalConflict> _findConflicts() {
    final out = <GoalConflict>[];
    for (var i = 0; i < active.length; i++) {
      for (var j = i + 1; j < active.length; j++) {
        final first = active[i], second = active[j];
        final gap = daysBetween(first.date, second.date);
        if (gap == 0) {
          out.add(
            GoalConflict(
              kind: ConflictKind.sameDay,
              severity: ConflictSeverity.decision,
              goalIds: [first.id, second.id],
              gapDays: 0,
              message:
                  '${first.name} and ${second.name} are on the same day. '
                  'Only one can be raced.',
              alternatives: ['Move one of the events', 'Mark one as cancelled'],
            ),
          );
          continue;
        }
        final needs =
            first.demand.recoveryDays +
            second.demand.sharpenDays(second.priority);
        final slack = gap - needs;
        if (slack >= 7) continue;
        final bothTop =
            first.priority == GoalPriority.a &&
            second.priority == GoalPriority.a;
        final flexible = [
          first,
          second,
        ].where((g) => g.participation == Participation.flexible).toList();
        if (slack < 0 && bothTop) {
          out.add(
            GoalConflict(
              kind: ConflictKind.closeHighPriority,
              severity: ConflictSeverity.decision,
              goalIds: [first.id, second.id],
              gapDays: gap,
              slackDays: slack,
              message:
                  '${first.name} and ${second.name} are both priority A, '
                  '$gap days apart. Recovery after the first and sharpening '
                  'for the second need ${-slack} more days than that.',
              alternatives: [
                'Make ${first.name} priority B',
                'Make ${second.name} priority B',
                'Move one of the events',
              ],
            ),
          );
        } else if (slack < 0 && flexible.isNotEmpty) {
          final skip = flexible.first;
          out.add(
            GoalConflict(
              kind: ConflictKind.flexibleOverlap,
              severity: ConflictSeverity.warning,
              goalIds: [first.id, second.id],
              gapDays: gap,
              slackDays: slack,
              message:
                  '${first.name} and ${second.name} are $gap days apart and '
                  'overlap by ${-slack} days. ${skip.name} is marked flexible: '
                  'dropping it would free the weeks before the other event.',
              alternatives: ['Skip ${skip.name}'],
            ),
          );
        } else if (slack < 0) {
          out.add(
            GoalConflict(
              kind: ConflictKind.recoveryMeetsSharpening,
              severity: ConflictSeverity.warning,
              goalIds: [first.id, second.id],
              gapDays: gap,
              slackDays: slack,
              message:
                  '${first.name} and ${second.name} are $gap days apart: '
                  'recovery after the first overlaps sharpening for the '
                  'second by ${-slack} days. The lower priority preparation '
                  'is limited to protect the other.',
              alternatives: [
                'Treat ${first.name} as a training event',
                'Move one of the events',
              ],
            ),
          );
        } else {
          out.add(
            GoalConflict(
              kind: ConflictKind.tightSpacing,
              severity: ConflictSeverity.warning,
              goalIds: [first.id, second.id],
              gapDays: gap,
              slackDays: slack,
              message:
                  '${first.name} and ${second.name} are $gap days apart. '
                  'Recovery and sharpening fit with $slack days to spare, so '
                  'any setback leaves no room.',
              alternatives: ['Ride ${first.name} as a controlled effort'],
            ),
          );
        }
      }
    }
    return out;
  }

  /// The outcome the goals alone allow; the weekly allocation can only make
  /// it worse.
  FeasibilityOutcome get outcome {
    var result = FeasibilityOutcome.feasible;
    for (final c in conflicts) {
      result = result.worse(switch (c.severity) {
        ConflictSeverity.decision => FeasibilityOutcome.requiresDecision,
        ConflictSeverity.warning => FeasibilityOutcome.feasibleWithTradeoffs,
        ConflictSeverity.info => FeasibilityOutcome.feasible,
      });
    }
    return result;
  }
}
