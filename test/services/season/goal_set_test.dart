import 'package:fjelia/services/season/goal_set.dart';
import 'package:fjelia/services/season/season_goal.dart';
import 'package:flutter_test/flutter_test.dart';

SeasonGoal marathon({
  DateTime? date,
  GoalPriority priority = GoalPriority.a,
  Participation participation = Participation.committed,
  String id = 'marathon',
}) => SeasonGoal(
  id: id,
  name: 'Marathon',
  sport: 'running',
  date: date ?? DateTime(2027, 4, 10),
  distanceM: 42195,
  priority: priority,
  participation: participation,
);

SeasonGoal brevet({
  DateTime? date,
  GoalPriority priority = GoalPriority.b,
  Participation participation = Participation.committed,
  String id = 'brevet',
}) => SeasonGoal(
  id: id,
  name: 'Brevet 200',
  sport: 'cycling_road',
  date: date ?? DateTime(2027, 3, 20),
  distanceM: 200000,
  elevationM: 1500,
  targetSeconds: 7 * 3600 + 1800,
  priority: priority,
  participation: participation,
);

final today = DateTime(2026, 10, 25);

void main() {
  group('goal demand', () {
    test('MG-T14: 200 km in 7.5 h keeps its numbers apart', () {
      final d = brevet().demand;
      expect(d.targetSpeedKmh, closeTo(26.67, 0.01));
      expect(d.climbPerKm, closeTo(7.5, 1e-9));
      expect(d.ascentM, 1500);
      expect(d.planningMinutes, 450);
      expect(d.durationBasis, 'target');
      // The generic terrain label calls it flat; the climbing is still there.
      expect(brevet().profile.terrain.name, 'flat');
    });

    test('MG-T15: without a target the duration is an estimate', () {
      final d = marathon().demand;
      expect(d.targetMinutes, isNull);
      expect(d.durationBasis, 'estimate');
      expect(d.targetSpeedKmh, isNull);
      expect(d.planningMinutes, greaterThan(200));
    });

    test('recovery and sharpening follow the event, not a fixed number', () {
      expect(brevet().demand.recoveryDays, 7);
      expect(marathon().demand.recoveryDays, lessThan(7));
      expect(brevet().demand.sharpenDays(GoalPriority.b), 7);
      expect(marathon().demand.sharpenDays(GoalPriority.a), 14);
      expect(marathon().demand.sharpenDays(GoalPriority.c), 3);
    });
  });

  group('dates', () {
    test('MG-T02: the entered pair is 21 calendar days apart', () {
      expect(daysBetween(DateTime(2027, 3, 20), DateTime(2027, 4, 10)), 21);
    });
    test('MG-T03: a corrected 11 April is 22 days, across the DST change', () {
      expect(daysBetween(DateTime(2027, 3, 20), DateTime(2027, 4, 11)), 22);
      // Clocks go forward on 28 March 2027.
      expect(daysBetween(DateTime(2027, 3, 27), DateTime(2027, 3, 29)), 2);
    });
    test('MG-T27: an event today is still active', () {
      final set = GoalSet([
        marathon(date: DateTime(2026, 10, 25, 0, 0)),
      ], today: DateTime(2026, 10, 25, 18, 30));
      expect(set.active, hasLength(1));
      expect(set.loadOn(today), DayLoad.blocked);
    });
  });

  group('goal set', () {
    test('MG-T17: the order of the rows changes nothing', () {
      final a = GoalSet([marathon(), brevet()], today: today);
      final b = GoalSet([brevet(), marathon()], today: today);
      expect(a.all.map((g) => g.id), b.all.map((g) => g.id));
      expect(a.revision, b.revision);
      expect(a.display!.id, 'marathon');
      expect(a.conflicts.map((c) => c.kind), b.conflicts.map((c) => c.kind));
    });

    test('MG-T01: an earlier B goal does not replace the A goal', () {
      final set = GoalSet([marathon(), brevet()], today: today);
      expect(set.active.map((g) => g.id), ['brevet', 'marathon']);
      expect(set.display!.priority, GoalPriority.a);
      expect(set.horizonEnd, DateTime(2027, 4, 10));
    });

    test('MG-T04: a B goal after the A goal stays in the horizon', () {
      final set = GoalSet([
        marathon(date: DateTime(2027, 3, 1)),
        brevet(date: DateTime(2027, 6, 5)),
      ], today: today);
      expect(set.active, hasLength(2));
      expect(set.horizonEnd, DateTime(2027, 6, 5));
    });

    test('the revision changes with anything that shapes the plan', () {
      final base = GoalSet([marathon(), brevet()], today: today).revision;
      expect(
        GoalSet([
          marathon(),
          brevet(date: DateTime(2027, 3, 21)),
        ], today: today).revision,
        isNot(base),
      );
      expect(
        GoalSet([
          marathon(priority: GoalPriority.b),
          brevet(),
        ], today: today).revision,
        isNot(base),
      );
    });

    test('MG-T18: a cancelled goal takes no part', () {
      final set = GoalSet([
        marathon(),
        brevet(participation: Participation.cancelled),
      ], today: today);
      expect(set.all, hasLength(2));
      expect(set.active.map((g) => g.id), ['marathon']);
      expect(set.conflicts, isEmpty);
      expect(set.loadOn(DateTime(2027, 3, 20)), DayLoad.free);
    });
  });

  group('conflicts', () {
    test('MG-T02: the 21 day spacing is flagged, not refused', () {
      final set = GoalSet([marathon(), brevet()], today: today);
      expect(set.conflicts, hasLength(1));
      final c = set.conflicts.single;
      expect(c.gapDays, 21);
      expect(c.severity, ConflictSeverity.warning);
      expect(set.outcome, FeasibilityOutcome.feasibleWithTradeoffs);
    });

    test('MG-T03: a day more gives some slack', () {
      final set = GoalSet([
        marathon(date: DateTime(2027, 4, 11)),
        brevet(),
      ], today: today);
      expect(set.conflicts.single.gapDays, 22);
      expect(set.conflicts.single.slackDays, greaterThan(0));
    });

    test('far apart events raise nothing', () {
      final set = GoalSet([
        marathon(),
        brevet(date: DateTime(2026, 12, 12)),
      ], today: today);
      expect(set.conflicts, isEmpty);
      expect(set.outcome, FeasibilityOutcome.feasible);
    });

    test('MG-T06: two close A events need a decision, not a pick', () {
      final set = GoalSet([
        marathon(),
        brevet(priority: GoalPriority.a, date: DateTime(2027, 4, 1)),
      ], today: today);
      final c = set.conflicts.single;
      expect(c.kind, ConflictKind.closeHighPriority);
      expect(c.severity, ConflictSeverity.decision);
      expect(c.alternatives, isNotEmpty);
      expect(set.outcome, FeasibilityOutcome.requiresDecision);
      // The same set in another order decides the same.
      final reversed = GoalSet([
        brevet(priority: GoalPriority.a, date: DateTime(2027, 4, 1)),
        marathon(),
      ], today: today);
      expect(reversed.conflicts.single.kind, ConflictKind.closeHighPriority);
    });

    test('MG-T08: a flexible event that overlaps is offered for omission', () {
      final set = GoalSet([
        marathon(),
        brevet(
          priority: GoalPriority.c,
          participation: Participation.flexible,
          date: DateTime(2027, 4, 1),
        ),
      ], today: today);
      final c = set.conflicts.single;
      expect(c.kind, ConflictKind.flexibleOverlap);
      expect(c.alternatives.single, contains('Skip Brevet 200'));
    });

    test('MG-T07: a committed long C event keeps its recovery', () {
      final set = GoalSet([
        marathon(),
        brevet(priority: GoalPriority.c, date: DateTime(2027, 1, 30)),
      ], today: today);
      // No dedicated block, but the day before and after are still reserved.
      expect(set.loadOn(DateTime(2027, 1, 30)), DayLoad.blocked);
      expect(set.loadOn(DateTime(2027, 1, 29)), DayLoad.blocked);
      expect(set.loadOn(DateTime(2027, 1, 31)), DayLoad.easyOnly);
    });

    test('MG-T30: two events on one day cannot both be raced', () {
      final set = GoalSet([
        marathon(),
        brevet(date: DateTime(2027, 4, 10)),
      ], today: today);
      expect(set.conflicts.single.kind, ConflictKind.sameDay);
      expect(set.outcome, FeasibilityOutcome.requiresDecision);
      expect(set.loadOn(DateTime(2027, 4, 10)), DayLoad.blocked);
    });
  });

  group('day load', () {
    test('events block their day and rest the day before', () {
      final set = GoalSet([marathon(), brevet()], today: today);
      expect(set.loadOn(DateTime(2027, 3, 19)), DayLoad.blocked);
      expect(set.loadOn(DateTime(2027, 3, 20)), DayLoad.blocked);
      expect(set.loadOn(DateTime(2027, 3, 21)), DayLoad.easyOnly);
      expect(set.loadOn(DateTime(2027, 3, 25)), DayLoad.free);
      expect(set.loadOn(DateTime(2027, 4, 9)), DayLoad.blocked);
    });
    test('an event just behind us still protects the days after it', () {
      final set = GoalSet([
        brevet(date: DateTime(2026, 10, 24)),
        marathon(),
      ], today: today);
      expect(set.recent.map((g) => g.id), ['brevet']);
      expect(set.loadOn(today), DayLoad.easyOnly);
    });
  });
}
