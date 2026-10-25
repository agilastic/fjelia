import 'package:fjelia/services/replan_triggers.dart';
import 'package:fjelia/services/season/goal_set.dart';
import 'package:fjelia/services/season/season_goal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('zoneTimeJump', () {
    test('reports growth above the threshold', () {
      expect(zoneTimeJump(120, 100), closeTo(20, 1e-9));
      expect(zoneTimeJump(115, 100), isNull);
      expect(zoneTimeJump(80, 100), isNull);
    });

    test('nothing to compare against gives no trigger', () {
      expect(zoneTimeJump(100, 0), isNull);
      expect(zoneTimeJump(double.nan, 100), isNull);
      expect(zoneTimeJump(100, double.infinity), isNull);
    });
  });

  group('hrvSuppressed', () {
    test('needs two low nights, one is not a trend', () {
      expect(hrvSuppressed([50, 52], 60), isTrue);
      expect(hrvSuppressed([50, 58], 60), isFalse);
      expect(hrvSuppressed([50], 60), isFalse);
    });

    test('a missing night or baseline is not suppression', () {
      expect(hrvSuppressed([50, null], 60), isFalse);
      expect(hrvSuppressed([null, null], 60), isFalse);
      expect(hrvSuppressed([50, 52], null), isFalse);
      expect(hrvSuppressed([50, 52], 0), isFalse);
    });
  });

  group('goalSetChanged', () {
    final today = DateTime(2026, 10, 25);
    SeasonGoal goal(String id, DateTime date, {double km = 42.195}) =>
        SeasonGoal(
          id: id,
          name: id,
          sport: 'running',
          date: date,
          distanceM: km * 1000,
        );

    test('the same goals are not a change', () {
      final goals = GoalSet([goal('a', DateTime(2027, 4, 10))], today: today);
      expect(
        goalSetChanged(planRevision: goals.revision, goals: goals),
        isFalse,
      );
    });

    test('a moved date, a new goal or a new priority is', () {
      final before = GoalSet([goal('a', DateTime(2027, 4, 10))], today: today);
      final moved = GoalSet([goal('a', DateTime(2027, 4, 11))], today: today);
      final added = GoalSet([
        goal('a', DateTime(2027, 4, 10)),
        goal('b', DateTime(2027, 3, 20), km: 200),
      ], today: today);
      expect(
        goalSetChanged(planRevision: before.revision, goals: moved),
        isTrue,
      );
      expect(
        goalSetChanged(planRevision: before.revision, goals: added),
        isTrue,
      );
    });

    test('a plan from before goals were linked knows only one goal', () {
      final one = GoalSet([goal('a', DateTime(2027, 4, 10))], today: today);
      final two = GoalSet([
        goal('a', DateTime(2027, 4, 10)),
        goal('b', DateTime(2027, 3, 20), km: 200),
      ], today: today);
      expect(goalSetChanged(planRevision: null, goals: one), isFalse);
      expect(goalSetChanged(planRevision: null, goals: two), isTrue);
    });

    test(
      'the last goal gone is a change: the plan has nothing to prepare for',
      () {
        final none = GoalSet(const [], today: today);
        expect(goalSetChanged(planRevision: 'x', goals: none), isTrue);
        expect(goalSetChanged(planRevision: null, goals: none), isTrue);
        final cancelled = GoalSet([
          SeasonGoal(
            id: 'a',
            name: 'a',
            sport: 'running',
            date: DateTime(2027, 4, 10),
            distanceM: 42195,
            participation: Participation.cancelled,
          ),
        ], today: today);
        expect(goalSetChanged(planRevision: 'x', goals: cancelled), isTrue);
      },
    );
  });
}
