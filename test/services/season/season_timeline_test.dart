import 'package:fjelia/services/season/goal_set.dart';
import 'package:fjelia/services/season/season_goal.dart';
import 'package:fjelia/services/season/season_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

SeasonGoal goal(
  String id, {
  required String sport,
  required DateTime date,
  GoalPriority priority = GoalPriority.a,
  double distanceM = 42195,
  Participation participation = Participation.committed,
}) => SeasonGoal(
  id: id,
  name: id,
  sport: sport,
  date: date,
  distanceM: distanceM,
  priority: priority,
  participation: participation,
);

final today = DateTime(2026, 10, 25);
final anchor = DateTime(2026, 10, 19);
DateTime week(int n) => DateTime(2026, 10, 19 + n * 7);

SeasonTimeline timelineOf(List<SeasonGoal> goals) => SeasonTimeline(
  goals: GoalSet(goals, today: today),
  anchorWeek: anchor,
  mondayFirst: true,
  cycle: 4,
);

void main() {
  group('phases', () {
    test('the legacy periodisation is kept', () {
      expect(seasonPhase(0, 20), 'base');
      expect(seasonPhase(19, 20), 'taper');
      expect(seasonPhase(18, 20), 'taper');
      expect(seasonPhase(17, 20), 'peak');
      // Every fourth week of base and build is an unloading week.
      expect(seasonPhase(3, 20), 'recovery');
      expect(seasonPhase(7, 20), 'recovery');
      expect(seasonPhase(0, 2), 'base');
      expect(seasonPhase(1, 2), 'taper');
    });
    test('intents have a phase name and a weight', () {
      expect(GoalIntent.ofPhase('peak'), GoalIntent.specificPreparation);
      expect(GoalIntent.ofPhase('recovery'), GoalIntent.unload);
      expect(GoalIntent.sharpen.phase, 'taper');
      expect(GoalIntent.build.weight, greaterThan(GoalIntent.maintain.weight));
      expect(GoalIntent.recover.isPreparation, isFalse);
      expect(GoalIntent.unload.isPreparation, isTrue);
    });
  });

  group('two goals', () {
    final marathon = goal(
      'marathon',
      sport: 'running',
      date: DateTime(2027, 4, 10),
    );
    final brevet = goal(
      'brevet',
      sport: 'cycling_road',
      date: DateTime(2027, 3, 20),
      priority: GoalPriority.b,
      distanceM: 200000,
    );

    test(
      'MG-T02: A prepares while B prepares, peaks, is raced and recovered',
      () {
        final timeline = timelineOf([marathon, brevet]);
        Map<String, GoalIntent> at(int n) => {
          for (final w in timeline.intentsFor(week(n))) w.goal.id: w.intent,
        };
        // Early: both prepared at once.
        expect(at(1)['marathon'], GoalIntent.foundation);
        expect(at(1)['brevet'], GoalIntent.foundation);
        // The brevet week is the event; the marathon goes on.
        expect(at(21)['brevet'], GoalIntent.event);
        expect(at(21)['marathon'], isNot(GoalIntent.event));
        // The week after: B recovers while A is still prepared.
        expect(at(22)['brevet'], GoalIntent.recover);
        expect(at(22)['marathon'], isNotNull);
        // After the recovery B has no more say.
        expect(at(24)['brevet'], isNull);
        // The marathon's own sharpening, event and recovery.
        expect(at(23)['marathon'], GoalIntent.sharpen);
        expect(at(24)['marathon'], GoalIntent.event);
      },
    );

    test('a goal sees only its own countdown', () {
      final timeline = timelineOf([marathon, brevet]);
      final w = timeline.intentsFor(week(10));
      final b = w.firstWhere((x) => x.goal.id == 'brevet');
      final a = w.firstWhere((x) => x.goal.id == 'marathon');
      expect(b.weeksToEvent, lessThan(a.weeksToEvent));
      expect(b.progress, greaterThan(a.progress));
    });

    test('MG-T05: a sport two goals share is asked once', () {
      final early = goal(
        'half',
        sport: 'running',
        date: DateTime(2027, 2, 6),
        priority: GoalPriority.b,
        distanceM: 21097,
      );
      final timeline = timelineOf([marathon, early]);
      final needs = SeasonTimeline.needsOf(timeline.intentsFor(week(8)));
      expect(needs.where((n) => n.sport == 'running'), hasLength(1));
      // Its weight is the larger of the two, not the sum.
      final running = needs.single;
      expect(running.weight, lessThanOrEqualTo(1.0));
    });

    test('a later A goal keeps its taper when an earlier B is raced', () {
      final early = goal(
        'half',
        sport: 'running',
        date: DateTime(2027, 2, 6),
        priority: GoalPriority.b,
        distanceM: 21097,
      );
      final timeline = timelineOf([marathon, early]);
      final last = timeline.intentsFor(week(23));
      expect(
        last.firstWhere((w) => w.goal.id == 'marathon').intent,
        GoalIntent.sharpen,
      );
      expect(last.where((w) => w.goal.id == 'half'), isEmpty);
    });
  });

  group('lower priorities', () {
    test('MG-T07/T08: a C goal has no block of its own', () {
      final c = goal(
        'fun',
        sport: 'running',
        date: DateTime(2027, 1, 30),
        priority: GoalPriority.c,
        distanceM: 10000,
      );
      final a = goal('a', sport: 'running', date: DateTime(2027, 4, 10));
      final timeline = timelineOf([a, c]);
      for (final n in [5, 10, 12]) {
        final intent = timeline
            .intentsFor(week(n))
            .firstWhere((w) => w.goal.id == 'fun')
            .intent;
        expect(
          intent,
          anyOf(GoalIntent.maintain, GoalIntent.sharpen, GoalIntent.unload),
        );
        expect(intent, isNot(GoalIntent.build));
        expect(intent, isNot(GoalIntent.specificPreparation));
      }
    });

    test('a flexible goal that clashes is deprioritised in its last weeks', () {
      final a = goal('a', sport: 'running', date: DateTime(2027, 4, 10));
      final flexible = goal(
        'b',
        sport: 'cycling_road',
        date: DateTime(2027, 4, 1),
        priority: GoalPriority.b,
        distanceM: 200000,
        participation: Participation.flexible,
      );
      final timeline = timelineOf([a, flexible]);
      final intents = [
        for (var n = 18; n < 23; n++)
          timeline
              .intentsFor(week(n))
              .where((w) => w.goal.id == 'b')
              .map((w) => w.intent)
              .firstOrNull,
      ];
      expect(intents, contains(GoalIntent.deprioritised));
      expect(intents, isNot(contains(GoalIntent.specificPreparation)));
    });
  });

  test('a triathlon prepares all three sports', () {
    final tri = goal('tri', sport: 'triathlon', date: DateTime(2027, 6, 1));
    final needs = SeasonTimeline.needsOf(timelineOf([tri]).intentsFor(week(4)));
    expect(needs.map((n) => n.sport).toSet(), {
      'running',
      'cycling_road',
      'swimming',
    });
  });

  test('the same goals in any order give the same week', () {
    final a = goal('a', sport: 'running', date: DateTime(2027, 4, 10));
    final b = goal(
      'b',
      sport: 'cycling_road',
      date: DateTime(2027, 3, 20),
      priority: GoalPriority.b,
      distanceM: 200000,
    );
    List<String> read(SeasonTimeline t) => [
      for (final w in t.intentsFor(week(12)))
        '${w.goal.id}:${w.intent.name}:${w.weeksToEvent}',
    ];
    expect(read(timelineOf([a, b])), read(timelineOf([b, a])));
  });
}
