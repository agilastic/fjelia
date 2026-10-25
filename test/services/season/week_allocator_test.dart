import 'package:fjelia/services/season/goal_set.dart';
import 'package:fjelia/services/season/season_goal.dart';
import 'package:fjelia/services/season/season_timeline.dart';
import 'package:fjelia/services/season/week_allocator.dart';
import 'package:flutter_test/flutter_test.dart';

final marathon = SeasonGoal(
  id: 'marathon',
  name: 'Marathon',
  sport: 'running',
  date: DateTime(2027, 4, 10),
  distanceM: 42195,
);
final brevet = SeasonGoal(
  id: 'brevet',
  name: 'Brevet',
  sport: 'cycling_road',
  date: DateTime(2027, 3, 20),
  distanceM: 200000,
  elevationM: 1500,
  targetSeconds: 27000,
  priority: GoalPriority.b,
);

SportNeed need(
  SeasonGoal goal,
  GoalIntent intent, {
  double progress = 0.5,
  int weeksToEvent = 10,
  double? weight,
}) => SportNeed(
  sport: goal.sport,
  weight: weight ?? intent.weight * goal.priority.weight,
  intent: intent,
  goal: goal,
  weeksToEvent: weeksToEvent,
  progress: progress,
);

GoalWeek week(
  SeasonGoal goal,
  GoalIntent intent, {
  int weeksToEvent = 10,
  double progress = 0.5,
}) => GoalWeek(
  goal: goal,
  intent: intent,
  weeksToEvent: weeksToEvent,
  progress: progress,
);

const capacities = {
  'running': SportCapacity(
    sessions: 30,
    longestMin: 100,
    medianMin: 55,
    yearLongestMin: 130,
  ),
  'cycling_road': SportCapacity(
    sessions: 30,
    longestMin: 150,
    medianMin: 60,
    yearLongestMin: 360,
  ),
};

AllocationInput input(
  List<SportNeed> needs, {
  double budget = 540,
  int cap = 8,
  int strength = 0,
  int w = 8,
  int? maxKeys = 2,
  List<String> variety = const [],
  Map<String, SportCapacity> caps = capacities,
  bool recovering = false,
  bool easyStart = false,
}) => AllocationInput(
  needs: needs,
  budgetMin: budget,
  sessionCap: cap,
  strengthDays: [2, 4].take(strength).toList(),
  capacities: caps,
  weekInRun: w,
  weekIndex: w,
  maxKeySessions: maxKeys,
  varietySports: variety,
  recoveringFromEvent: recovering,
  easyStart: easyStart,
  footLongCap: (_) => 180,
);

void main() {
  const allocator = WeekAllocator();

  group('long sessions', () {
    test('each goal sport gets a long session of its own', () {
      final a = allocator.allocate(
        input([
          need(marathon, GoalIntent.build),
          need(brevet, GoalIntent.build),
        ]),
      );
      expect(a.longTargets.keys, containsAll(['running', 'cycling_road']));
      expect(a.longTargets['cycling_road'], greaterThan(90));
    });

    test('MG-T07/T14: the ride follows the event duration and the history', () {
      final early = allocator.allocate(
        input([need(brevet, GoalIntent.build, progress: 0.1)], budget: 800),
      );
      final late = allocator.allocate(
        input(
          [need(brevet, GoalIntent.specificPreparation, progress: 0.9)],
          budget: 800,
          w: 20,
        ),
      );
      expect(
        late.longTargets['cycling_road']!,
        greaterThan(early.longTargets['cycling_road']!),
      );
      // Never more than a share of the event: 7.5 h is not a 7.5 h ride.
      expect(late.longTargets['cycling_road']!, lessThan(450 * 0.65));
    });

    test('history caps what is added to it', () {
      final thin = allocator.allocate(
        input(
          [need(brevet, GoalIntent.specificPreparation, progress: 0.9)],
          budget: 800,
          w: 0,
          caps: const {
            'cycling_road': SportCapacity(
              sessions: 20,
              longestMin: 60,
              medianMin: 45,
              yearLongestMin: 60,
            ),
          },
        ),
      );
      expect(thin.longTargets['cycling_road']!, lessThanOrEqualTo(70));
    });

    test('without history in the sport the long session starts modestly', () {
      final a = allocator.allocate(
        input(
          [need(brevet, GoalIntent.build)],
          budget: 800,
          w: 0,
          caps: const {},
        ),
      );
      expect(a.longTargets['cycling_road']!, lessThanOrEqualTo(80));
    });

    test('the foot sport follows its own long-run cap', () {
      final a = allocator.allocate(
        input(
          [need(marathon, GoalIntent.specificPreparation, progress: 1)],
          budget: 900,
          w: 40,
        ),
      );
      expect(a.longTargets['running']!, lessThanOrEqualTo(180));
    });

    test('MG-T12: long sessions are cut back together, and it is said', () {
      final a = allocator.allocate(
        input(
          [
            need(marathon, GoalIntent.specificPreparation, progress: 0.9),
            need(brevet, GoalIntent.specificPreparation, progress: 0.9),
          ],
          budget: 400,
          w: 30,
        ),
      );
      expect(a.tradeoffs.join(' '), contains('shortened'));
      // Both still get one: the second goal is not starved.
      expect(a.longTargets.keys, containsAll(['running', 'cycling_road']));
    });

    test('MG-T11: when both cannot fit the week they take turns', () {
      final needs = [
        need(marathon, GoalIntent.specificPreparation, progress: 0.9),
        need(brevet, GoalIntent.specificPreparation, progress: 0.9),
      ];
      final even = allocator.allocate(input(needs, budget: 240, w: 30));
      final odd = allocator.allocate(input(needs, budget: 240, w: 31));
      expect(even.tradeoffs.join(' '), contains('wait'));
      expect(even.longTargets.keys.length, 1);
      expect(odd.longTargets.keys.length, 1);
      expect(even.longTargets.keys.single, isNot(odd.longTargets.keys.single));
    });
  });

  group('the rest of the week', () {
    test(
      'quality is limited by the level and by a long event raced to finish',
      () {
        final a = allocator.allocate(
          input([
            need(marathon, GoalIntent.build),
            need(brevet, GoalIntent.build),
          ], maxKeys: 1),
        );
        expect(
          a.slots.where((s) => s.sessionType == 'key'),
          hasLength(lessThanOrEqualTo(1)),
        );
        final ride = allocator.allocate(
          input([need(brevet, GoalIntent.build)], budget: 700),
        );
        // A 7.5 h event with no stated ambition: one steady key ride, no intervals.
        expect(
          ride.slots.where(
            (s) => s.sessionType == 'key' && s.subType == 'intervals',
          ),
          isEmpty,
        );
      },
    );

    test('a stated performance ambition allows intervals on the bike', () {
      final fast = SeasonGoal(
        id: 'b',
        name: 'Brevet',
        sport: 'cycling_road',
        date: DateTime(2027, 3, 20),
        distanceM: 200000,
        targetSeconds: 27000,
        priority: GoalPriority.b,
        ambition: Ambition.performance,
      );
      final a = allocator.allocate(
        input([need(fast, GoalIntent.build)], budget: 700, maxKeys: 2),
      );
      expect(a.slots.where((s) => s.sessionType == 'key'), isNotEmpty);
    });

    test('unloading weeks hold no hard session', () {
      final a = allocator.allocate(
        input([
          need(marathon, GoalIntent.unload),
          need(brevet, GoalIntent.unload),
        ], budget: 380),
      );
      expect(a.slots.where((s) => s.sessionType == 'key'), isEmpty);
      expect(a.plannedMin, lessThanOrEqualTo(380));
    });

    test('event and recovery weeks are easy and short', () {
      final e = allocator.allocate(
        input([need(brevet, GoalIntent.event, weeksToEvent: 0)], budget: 100),
      );
      expect(e.slots, hasLength(1));
      expect(e.slots.single.sessionType, 'recovery');
      expect(e.slots.single.targetMin, lessThanOrEqualTo(45));
      final r = allocator.allocate(
        input([
          need(brevet, GoalIntent.recover, weeksToEvent: -1),
        ], budget: 200),
      );
      expect(r.slots.every((s) => s.sessionType == 'recovery'), isTrue);
    });

    test('a maintained sport gets one long and at most one key', () {
      final c = SeasonGoal(
        id: 'c',
        name: 'Fun ride',
        sport: 'cycling_road',
        date: DateTime(2027, 5, 1),
        distanceM: 80000,
        priority: GoalPriority.c,
      );
      final a = allocator.allocate(
        input([need(c, GoalIntent.maintain), need(marathon, GoalIntent.build)]),
      );
      final rides = a.slots.where((s) => s.sport == 'cycling_road').toList();
      expect(
        rides.where((s) => s.sessionType == 'key'),
        hasLength(lessThanOrEqualTo(1)),
      );
      expect(rides.where((s) => s.role == 'maintenance'), isNotEmpty);
    });

    test('every session names its goal and its purpose', () {
      final a = allocator.allocate(
        input([
          need(marathon, GoalIntent.build),
          need(brevet, GoalIntent.build),
        ]),
      );
      for (final s in a.slots) {
        expect(s.goalId, anyOf('marathon', 'brevet'));
        expect(s.objective, isNotEmpty);
        expect(s.role, anyOf('primary', 'maintenance', 'support'));
      }
    });
  });

  group('limits', () {
    test('MG-T11: too few training days is reported, never hidden', () {
      final a = allocator.allocate(
        input([
          need(marathon, GoalIntent.build),
          need(brevet, GoalIntent.build),
        ], cap: 2),
      );
      expect(a.slots, hasLength(2));
      // The two kept are the long sessions; the quality work that no longer
      // fits is named, not dropped quietly.
      expect(a.slots.every((s) => s.sessionType == 'long'), isTrue);
      expect(a.unmet, isEmpty);
      expect(a.tradeoffs.join(' '), contains('is left out'));
      expect(a.outcome, FeasibilityOutcome.feasibleWithTradeoffs);
      // With a single day one goal's long session has no place at all.
      final one = allocator.allocate(
        input([
          need(marathon, GoalIntent.build),
          need(brevet, GoalIntent.build),
        ], cap: 1),
      );
      expect(one.slots, hasLength(1));
      expect(one.unmet, isNotEmpty);
      expect(one.outcome, FeasibilityOutcome.requiresDecision);
    });

    test('the sessions of a sport are placed by the allowed sports', () {
      final a = allocator.allocate(
        AllocationInput(
          needs: [
            need(marathon, GoalIntent.build),
            need(brevet, GoalIntent.build),
          ],
          budgetMin: 540,
          sessionCap: 8,
          capacities: capacities,
          allowedSports: const {'running'},
          footLongCap: (_) => 180,
        ),
      );
      expect(a.slots.every((s) => s.sport == 'running'), isTrue);
    });

    test('MG-T09: variety is optional, short, and only with room', () {
      final room = allocator.allocate(
        input(
          [need(marathon, GoalIntent.maintain)],
          budget: 600,
          variety: const ['swimming'],
        ),
      );
      expect(room.slots.where((s) => s.role == 'optional'), hasLength(1));
      final full = allocator.allocate(
        input(
          [need(marathon, GoalIntent.build)],
          budget: 200,
          variety: const ['swimming'],
        ),
      );
      expect(full.slots.where((s) => s.role == 'optional'), isEmpty);
      final eventWeek = allocator.allocate(
        input(
          [need(brevet, GoalIntent.event, weeksToEvent: 0)],
          budget: 600,
          variety: const ['swimming'],
        ),
      );
      expect(eventWeek.slots.where((s) => s.role == 'optional'), isEmpty);
    });

    test('MG-T10: strength time is kept out of the goals\' share', () {
      final withStrength = allocator.allocate(
        input([need(marathon, GoalIntent.build)], budget: 300, strength: 2),
      );
      // Strength is part of the week: both sessions, inside the 300 minutes.
      expect(
        withStrength.slots.where((s) => s.sport == 'strength'),
        hasLength(2),
      );
      expect(withStrength.plannedMin, lessThanOrEqualTo(300));
    });

    test('time is counted once, per session', () {
      final a = allocator.allocate(
        input([
          need(marathon, GoalIntent.build),
          need(brevet, GoalIntent.build),
        ]),
      );
      expect(a.plannedMin, lessThanOrEqualTo(540 + 1));
      expect(a.minutesBySport.values.fold(0, (x, y) => x + y), a.plannedMin);
    });

    test('an event in the week is said and counted', () {
      final a = allocator.allocate(
        AllocationInput(
          needs: [need(marathon, GoalIntent.build)],
          budgetMin: 200,
          sessionCap: 6,
          capacities: capacities,
          events: const [(name: 'Brevet', minutes: 450)],
          footLongCap: (_) => 180,
        ),
      );
      expect(a.tradeoffs.join(' '), contains('count as training'));
    });
  });

  group('budget factor', () {
    test('a build week keeps its time', () {
      expect(WeekAllocator.budgetFactor([week(marathon, GoalIntent.build)]), 1);
    });
    test('an easy week and a taper take 70 percent', () {
      expect(
        WeekAllocator.budgetFactor([week(marathon, GoalIntent.unload)]),
        closeTo(0.7, 1e-9),
      );
      expect(
        WeekAllocator.budgetFactor([week(marathon, GoalIntent.sharpen)]),
        closeTo(0.7, 1e-9),
      );
    });
    test('a recovering goal does not shrink a peaking one by weight alone', () {
      final f = WeekAllocator.budgetFactor([
        week(marathon, GoalIntent.specificPreparation),
        week(brevet, GoalIntent.recover, weeksToEvent: -3),
      ]);
      expect(f, greaterThan(0.9));
    });
    test('the first week after a long event is light for everything', () {
      final f = WeekAllocator.budgetFactor([
        week(marathon, GoalIntent.specificPreparation),
        week(brevet, GoalIntent.recover, weeksToEvent: -1),
      ]);
      expect(f, lessThanOrEqualTo(0.75));
      expect(
        WeekAllocator.isRecoveringFromLongEvent([
          week(brevet, GoalIntent.recover, weeksToEvent: -1),
        ]),
        isTrue,
      );
      final held = allocator.allocate(
        input(
          [
            need(marathon, GoalIntent.specificPreparation, progress: 0.9),
            need(brevet, GoalIntent.recover, weeksToEvent: -1),
          ],
          budget: 540 * f,
          w: 30,
          recovering: true,
        ),
      );
      final normal = allocator.allocate(
        input(
          [need(marathon, GoalIntent.specificPreparation, progress: 0.9)],
          budget: 540,
          w: 30,
        ),
      );
      expect(
        held.longTargets['running']!,
        lessThan(normal.longTargets['running']!),
      );
      expect(
        held.slots.where((s) => s.sessionType == 'key'),
        hasLength(lessThanOrEqualTo(1)),
      );
    });
    test('a short event does not hold the week back', () {
      final fast = SeasonGoal(
        id: 'k',
        name: '10k',
        sport: 'running',
        date: DateTime(2027, 2, 1),
        distanceM: 10000,
        priority: GoalPriority.b,
      );
      expect(
        WeekAllocator.budgetFactor([
          week(fast, GoalIntent.recover, weeksToEvent: -1),
        ]),
        greaterThanOrEqualTo(0.9),
      );
    });
  });

  group('limits that hold', () {
    SeasonGoal swim() => SeasonGoal(
      id: 'swim',
      name: 'Swim',
      sport: 'swimming',
      date: DateTime(2027, 4, 20),
      distanceM: 3800,
      priority: GoalPriority.c,
    );

    test('a long session that wants more than the week has is not kept', () {
      final a = allocator.allocate(
        input([need(brevet, GoalIntent.build)], budget: 50, w: 20),
      );
      expect(a.plannedMin, lessThanOrEqualTo(50));
      // Either it fits at its minimum, or the conflict is named.
      expect(
        a.slots.where((s) => s.isLong).isNotEmpty || a.unmet.isNotEmpty,
        isTrue,
      );
      final tiny = allocator.allocate(
        input([need(brevet, GoalIntent.build)], budget: 40, w: 20),
      );
      expect(tiny.plannedMin, lessThanOrEqualTo(40));
      expect(tiny.unmet, isNotEmpty);
      expect(tiny.outcome, FeasibilityOutcome.requiresDecision);
    });

    test('strength and endurance share the sessions and the minutes', () {
      final a = allocator.allocate(
        input(
          [need(marathon, GoalIntent.build)],
          budget: 150,
          cap: 3,
          strength: 2,
        ),
      );
      expect(a.slots.length, lessThanOrEqualTo(3));
      expect(a.plannedMin, lessThanOrEqualTo(150));
      // The long run is kept; whatever gave way is said.
      expect(a.slots.where((s) => s.isLong), isNotEmpty);
      final two = allocator.allocate(
        input(
          [need(marathon, GoalIntent.build)],
          budget: 150,
          cap: 2,
          strength: 2,
        ),
      );
      expect(two.slots.length, lessThanOrEqualTo(2));
      expect(two.tradeoffs.join(' '), contains('left out'));
    });

    test('minutes never exceed the budget, whatever is asked', () {
      for (final budget in [60.0, 100.0, 150.0, 240.0, 400.0, 700.0]) {
        for (final strength in [0, 1, 2]) {
          for (final cap in [1, 2, 3, 6]) {
            final a = allocator.allocate(
              input(
                [
                  need(marathon, GoalIntent.specificPreparation, progress: 0.9),
                  need(brevet, GoalIntent.specificPreparation, progress: 0.9),
                ],
                budget: budget,
                strength: strength,
                cap: cap,
                w: 25,
              ),
            );
            expect(
              a.plannedMin,
              lessThanOrEqualTo(budget.floor()),
              reason: 'budget $budget, strength $strength, cap $cap',
            );
            expect(a.slots.length, lessThanOrEqualTo(cap));
          }
        }
      }
    });

    test('easy start: one moderate session, in the steps too', () {
      final a = allocator.allocate(
        input(
          [need(marathon, GoalIntent.build)],
          budget: 540,
          easyStart: true,
          maxKeys: 2,
        ),
      );
      final keys = a.slots.where((s) => s.sessionType == 'key').toList();
      expect(keys, hasLength(lessThanOrEqualTo(1)));
      for (final k in keys) {
        expect(k.zone, lessThanOrEqualTo(3));
        expect(k.maxZone, 3);
        expect(k.subType, 'tempo');
      }
      final normal = allocator.allocate(
        input([need(marathon, GoalIntent.build)], budget: 540),
      );
      expect(
        normal.slots
            .where((s) => s.sessionType == 'key')
            .any((s) => s.zone >= 4),
        isTrue,
      );
    });

    test('three sports take turns for the long session, by weight', () {
      final needs = [
        need(marathon, GoalIntent.specificPreparation, progress: 0.9),
        need(brevet, GoalIntent.specificPreparation, progress: 0.9),
        need(swim(), GoalIntent.build, progress: 0.9),
      ];
      final seen = <String, int>{};
      for (var week = 0; week < 12; week++) {
        final a = allocator.allocate(input(needs, budget: 210, w: week));
        for (final sport in a.longTargets.keys) {
          seen[sport] = (seen[sport] ?? 0) + 1;
        }
        expect(a.plannedMin, lessThanOrEqualTo(210));
      }
      expect(seen.keys, containsAll(['running', 'cycling_road', 'swimming']));
      // The more important goals come round more often.
      expect(seen['running']!, greaterThanOrEqualTo(seen['swimming']!));
      expect(seen['cycling_road']!, greaterThanOrEqualTo(seen['swimming']!));
    });

    test('a goal that shares its sport still holds the week back', () {
      // Two marathons, the first two days ago: the later one's build week
      // is the strongest need for running, but the first is recovered from.
      final earlier = SeasonGoal(
        id: 'earlier',
        name: 'Earlier marathon',
        sport: 'running',
        date: DateTime(2026, 10, 23),
        distanceM: 42195,
        priority: GoalPriority.b,
      );
      final weeks = [
        week(marathon, GoalIntent.foundation, weeksToEvent: 24),
        week(earlier, GoalIntent.recover, weeksToEvent: -1),
      ];
      expect(WeekAllocator.isRecoveringFromLongEvent(weeks), isTrue);
      expect(WeekAllocator.budgetFactor(weeks), lessThanOrEqualTo(0.75));
    });
  });
}
