import 'dart:convert';

import 'goal_set.dart';
import 'season_goal.dart';
import 'week_allocator.dart';

/// One week of the season: what each goal asked and what the week held.
class WeekReport {
  const WeekReport({
    required this.weekStart,
    required this.phase,
    required this.intents,
    required this.allocation,
    this.notes = const [],
  });

  final DateTime weekStart;

  /// The label of the dominant goal's phase, for a summary line.
  final String phase;

  /// Goal id to intent name.
  final Map<String, String> intents;
  final Map<String, dynamic> allocation;

  /// What scheduling could not do: `longAwayFromUsualDay`.
  final List<String> notes;

  Map<String, dynamic> toJson() => {
    'week':
        '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-'
        '${weekStart.day.toString().padLeft(2, '0')}',
    'phase': phase,
    'intents': intents,
    'allocation': allocation,
    if (notes.isNotEmpty) 'notes': notes,
  };
}

/// The season as the planner decided it: outcome, conflicts, what each week
/// was allocated and the trade-offs, so a question like "why only this much
/// cycling?" is answered from recorded decisions.
class SeasonReport {
  SeasonReport({
    required this.outcome,
    required this.goalSetRevision,
    required this.conflicts,
    required this.weeks,
    required this.confidence,
    required this.summary,
    required this.goals,
  });

  final FeasibilityOutcome outcome;
  final String goalSetRevision;
  final List<GoalConflict> conflicts;
  final List<WeekReport> weeks;

  /// Per sport: how well the history lets the planner judge the athlete.
  final Map<String, String> confidence;

  /// Plain sentences about the trade-offs of the whole season.
  final List<String> summary;

  /// Id to name, priority, sport and date of every goal planned.
  final Map<String, Map<String, String>> goals;

  bool get hasTradeoffs => summary.isNotEmpty || conflicts.isNotEmpty;

  /// The season's own words, shortest first: the conflicts, then trade-offs.
  List<String> get lines => [for (final c in conflicts) c.message, ...summary];

  Map<String, dynamic> toJson() => {
    'policy': seasonPolicyVersion,
    'outcome': outcome.name,
    'goalSet': goalSetRevision,
    'goals': goals,
    'conflicts': [for (final c in conflicts) c.toJson()],
    'confidence': confidence,
    'summary': summary,
    'weeks': [for (final w in weeks) w.toJson()],
  };

  String encode() => jsonEncode(toJson());

  /// Reads a stored season; null when it cannot be read.
  static Map<String, dynamic>? decode(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final data = jsonDecode(json);
      return data is Map<String, dynamic> ? data : null;
    } catch (_) {
      return null;
    }
  }

  /// Builds the report from the goal set and the week allocations.
  static SeasonReport build({
    required GoalSet goals,
    required List<WeekReport> weeks,
    required List<WeekAllocation> allocations,
    required Map<String, SportCapacity> capacities,
    int weeksPrepared = 0,
  }) {
    var outcome = goals.outcome;
    final summary = <String>[];

    // Trade-offs of the weeks, told once for the season.
    final shortened = allocations.where(
      (a) => a.tradeoffs.any((t) => t.contains('shortened')),
    );
    if (shortened.isNotEmpty) {
      summary.add(
        'In ${shortened.length} of ${allocations.length} weeks the weekly '
        'time cannot hold the full long sessions of every goal, so they are '
        'shortened together.',
      );
    }
    final alternating = allocations.where(
      (a) => a.tradeoffs.any((t) => t.contains('turn')),
    );
    if (alternating.isNotEmpty) {
      summary.add(
        'In ${alternating.length} weeks the week cannot hold every long '
        'session; the sports take turns.',
      );
    }
    final away = weeks.where((w) => w.notes.contains('longAwayFromUsualDay'));
    if (away.isNotEmpty) {
      summary.add(
        'In ${away.length} weeks a long session of over two and a half '
        'hours sits away from its usual day, because of your rest days and '
        'the other sessions.',
      );
    }
    // Sessions the athlete moved are kept; where they clash with an event,
    // that is said, not changed behind their back.
    int noted(String note) => weeks.fold<int>(
      0,
      (a, w) => a + w.notes.where((n) => n == note).length,
    );
    final onto = noted('movedOntoEvent');
    if (onto > 0) {
      summary.add(
        '$onto ${onto == 1 ? 'session' : 'sessions'} you moved '
        '${onto == 1 ? 'sits' : 'sit'} on an event day or the rest day before '
        'it. The plan keeps ${onto == 1 ? 'it' : 'them'} where you put '
        '${onto == 1 ? 'it' : 'them'}.',
      );
    }
    final dropped = noted('noRoom');
    if (dropped > 0) {
      summary.add(
        '$dropped ${dropped == 1 ? 'session was' : 'sessions were'} left out '
        'because the workouts chosen for them ran longer than the time left '
        'in the week.',
      );
    }
    final hard = noted('movedHardNearEvent');
    if (hard > 0) {
      summary.add(
        '$hard hard ${hard == 1 ? 'session' : 'sessions'} you moved '
        '${hard == 1 ? 'sits' : 'sit'} in the easy days after an event. The '
        'plan keeps ${hard == 1 ? 'it' : 'them'} where you put '
        '${hard == 1 ? 'it' : 'them'}.',
      );
    }
    final events = allocations.where(
      (a) => a.tradeoffs.any((t) => t.contains('count as training')),
    );
    if (events.isNotEmpty) {
      summary.add(
        'Event weeks count the event as training, so the rest of the week '
        'is lighter.',
      );
    }
    final unmet = allocations.where((a) => a.unmet.isNotEmpty).toList();
    if (unmet.isNotEmpty) {
      summary.add(
        'In ${unmet.length} weeks the training days do not hold every '
        'protected session: ${unmet.first.unmet.first}',
      );
      outcome = outcome.worse(
        unmet.length * 2 >
                (weeksPrepared > 0 ? weeksPrepared : allocations.length)
            ? FeasibilityOutcome.infeasible
            : FeasibilityOutcome.requiresDecision,
      );
    }
    if (summary.isNotEmpty) {
      outcome = outcome.worse(FeasibilityOutcome.feasibleWithTradeoffs);
    }

    // A goal in a sport the history says nothing about: the plan is
    // provisional until training shows what the athlete can do.
    final confidence = <String, String>{};
    for (final g in goals.active) {
      final cap = capacities[g.sport];
      final level = cap?.confidence ?? 'none';
      confidence[g.sport] = level;
      if (level == 'none' && g.priority != GoalPriority.c) {
        outcome = outcome.worse(FeasibilityOutcome.insufficientData);
        summary.add(
          'There is no recent ${g.sport.replaceAll('_', ' ')} in your '
          'history, so the plan for the ${g.priority.name.toUpperCase()} goal '
          'is provisional.',
        );
      }
    }
    return SeasonReport(
      outcome: outcome,
      goalSetRevision: goals.revision,
      conflicts: goals.conflicts,
      weeks: weeks,
      confidence: confidence,
      summary: summary,
      goals: {
        for (final g in goals.active)
          g.id: {
            'name': g.name,
            'priority': g.priority.name.toUpperCase(),
            'sport': g.sport,
            'date':
                '${g.date.year}-${g.date.month.toString().padLeft(2, '0')}-'
                '${g.date.day.toString().padLeft(2, '0')}',
          },
      },
    );
  }
}
