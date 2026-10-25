import 'dart:math' as math;

import '../../utils/week.dart';
import 'goal_set.dart';
import 'season_goal.dart';

/// Periodisation: base, build, peak, taper, with every [cycle]th week of base
/// and build an unloading week. [week] counts from the season anchor and
/// [totalWeeks] runs to the goal's own week.
String seasonPhase(int week, int totalWeeks, {int cycle = 4}) {
  if (totalWeeks <= 2) return week == totalWeeks - 1 ? 'taper' : 'base';
  final taper = totalWeeks >= 8 ? 2 : 1;
  final peak = math.max(1, (totalWeeks * 0.2).round());
  final build = math.max(1, (totalWeeks * 0.35).round());
  final remaining = totalWeeks - week;
  String phase;
  if (remaining <= taper) {
    phase = 'taper';
  } else if (remaining <= taper + peak) {
    phase = 'peak';
  } else if (remaining <= taper + peak + build) {
    phase = 'build';
  } else {
    phase = 'base';
  }
  if ((phase == 'base' || phase == 'build') && week % cycle == cycle - 1) {
    return 'recovery';
  }
  return phase;
}

/// What a goal asks of one week. Several goals can ask different things of
/// the same week: one in its build while another is being recovered from.
enum GoalIntent {
  foundation,
  build,
  specificPreparation,
  sharpen,
  event,
  recover,

  /// The planned easier week inside a block of base or build.
  unload,
  maintain,
  deprioritised;

  /// Share of a full week of preparation this intent gets.
  double get weight => switch (this) {
    GoalIntent.foundation => 0.8,
    GoalIntent.build => 1.0,
    GoalIntent.specificPreparation => 1.0,
    GoalIntent.sharpen => 0.6,
    GoalIntent.event => 0.35,
    GoalIntent.recover => 0.3,
    GoalIntent.unload => 0.7,
    GoalIntent.maintain => 0.45,
    GoalIntent.deprioritised => 0.15,
  };

  /// The phase name templates and week summaries use for it.
  String get phase => switch (this) {
    GoalIntent.foundation => 'base',
    GoalIntent.build => 'build',
    GoalIntent.specificPreparation => 'peak',
    GoalIntent.sharpen => 'taper',
    GoalIntent.event => 'race',
    GoalIntent.recover => 'recovery',
    GoalIntent.unload => 'recovery',
    GoalIntent.maintain => 'base',
    GoalIntent.deprioritised => 'base',
  };

  /// Builds fitness: long and quality work is on the table.
  bool get isPreparation =>
      this == foundation ||
      this == build ||
      this == specificPreparation ||
      this == unload ||
      this == maintain;

  static GoalIntent ofPhase(String phase) => switch (phase) {
    'taper' => GoalIntent.sharpen,
    'peak' => GoalIntent.specificPreparation,
    'build' => GoalIntent.build,
    'recovery' => GoalIntent.unload,
    'race' => GoalIntent.event,
    _ => GoalIntent.foundation,
  };
}

/// One goal's intent for one week.
class GoalWeek {
  const GoalWeek({
    required this.goal,
    required this.intent,
    required this.weeksToEvent,
    required this.progress,
  });

  final SeasonGoal goal;
  final GoalIntent intent;

  /// Whole weeks until the event's week; negative after it.
  final int weeksToEvent;

  /// How far through its preparation the goal is, 0 to 1.
  final double progress;

  double get weight => intent.weight * goal.priority.weight;
}

/// What one sport is asked for in a week. A sport that two goals share is
/// asked once, by the goal that needs it most.
class SportNeed {
  const SportNeed({
    required this.sport,
    required this.weight,
    required this.intent,
    required this.goal,
    required this.weeksToEvent,
    required this.progress,
  });

  final String sport;
  final double weight;
  final GoalIntent intent;
  final SeasonGoal goal;
  final int weeksToEvent;
  final double progress;
}

/// Turns a goal set into per-week intents, counted from the season anchor so
/// a later replan carries on in the same block.
class SeasonTimeline {
  SeasonTimeline({
    required this.goals,
    required this.anchorWeek,
    required this.mondayFirst,
    required this.cycle,
  });

  final GoalSet goals;
  final DateTime anchorWeek;
  final bool mondayFirst;
  final int cycle;

  int _weeksBetween(DateTime a, DateTime b) => daysBetween(a, b) ~/ 7;

  /// Every goal that still matters in the week that starts on [weekStart].
  List<GoalWeek> intentsFor(DateTime weekStart) {
    final weekEnd = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 6,
    );
    final g = _weeksBetween(anchorWeek, weekStart);
    final out = <GoalWeek>[];
    for (final goal in goals.relevant) {
      final demand = goal.demand;
      final goalWeek = weekStartOf(goal.date, mondayFirst: mondayFirst);
      final weeksToEvent = _weeksBetween(weekStart, goalWeek);
      if (!goal.date.isBefore(weekStart) && !goal.date.isAfter(weekEnd)) {
        out.add(
          GoalWeek(
            goal: goal,
            intent: GoalIntent.event,
            weeksToEvent: 0,
            progress: 1,
          ),
        );
        continue;
      }
      if (goal.date.isBefore(weekStart)) {
        final since = daysBetween(goal.date, weekStart);
        if (since < demand.recoveryDays) {
          out.add(
            GoalWeek(
              goal: goal,
              intent: GoalIntent.recover,
              weeksToEvent: weeksToEvent,
              progress: 1,
            ),
          );
        }
        continue;
      }
      final totalWeeks = _weeksBetween(anchorWeek, goalWeek) + 1;
      final progress = totalWeeks <= 1
          ? 1.0
          : (g / (totalWeeks - 1)).clamp(0.0, 1.0);
      var intent = GoalIntent.ofPhase(seasonPhase(g, totalWeeks, cycle: cycle));
      if (goal.priority == GoalPriority.c) {
        // No block of its own: ordinary training carries it, with a light
        // sharpening in the last days when the event is long.
        intent =
            intent == GoalIntent.sharpen &&
                demand.sharpenDays(goal.priority) > 0
            ? GoalIntent.sharpen
            : GoalIntent.maintain;
      }
      if (goal.participation == Participation.flexible &&
          goals.conflicts.any(
            (c) =>
                c.kind == ConflictKind.flexibleOverlap &&
                c.goalIds.contains(goal.id),
          ) &&
          (intent == GoalIntent.specificPreparation ||
              intent == GoalIntent.sharpen)) {
        intent = GoalIntent.deprioritised;
      }
      out.add(
        GoalWeek(
          goal: goal,
          intent: intent,
          weeksToEvent: weeksToEvent,
          progress: progress,
        ),
      );
    }
    return out;
  }

  /// Sports a goal prepares: a triathlon prepares all three.
  static Map<String, double> sportsOf(SeasonGoal goal) =>
      goal.sport == 'triathlon'
      ? const {'running': 1.0, 'cycling_road': 1.0, 'swimming': 0.8}
      : {goal.sport: 1.0};

  /// The week's needs by sport, the most important first.
  static List<SportNeed> needsOf(List<GoalWeek> weeks) {
    final best = <String, SportNeed>{};
    for (final w in weeks) {
      for (final entry in sportsOf(w.goal).entries) {
        final weight = w.weight * entry.value;
        final current = best[entry.key];
        if (current == null || weight > current.weight) {
          best[entry.key] = SportNeed(
            sport: entry.key,
            weight: weight,
            intent: w.intent,
            goal: w.goal,
            weeksToEvent: w.weeksToEvent,
            progress: w.progress,
          );
        }
      }
    }
    return best.values.toList()..sort((a, b) {
      final byWeight = b.weight.compareTo(a.weight);
      return byWeight != 0 ? byWeight : a.sport.compareTo(b.sport);
    });
  }
}
