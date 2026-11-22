import 'package:fjelia/services/session_stress.dart';
import 'package:flutter_test/flutter_test.dart';

double load(String sport, int minutes, int zone) =>
    sessionStress(sport: sport, minutes: minutes, zone: zone);

void main() {
  group('a key session next to a heavy day', () {
    test('bike intervals before a long easy ride are fine', () {
      // 60 min of bike intervals the day before 150 min of easy riding.
      expect(
        heavyPair(load('cycling_road', 60, 5), load('cycling_road', 150, 2)),
        isFalse,
      );
    });

    test('VO2max running before three hours on a trail is too much', () {
      expect(
        heavyPair(load('running', 60, 5), load('trail_running', 180, 2)),
        isTrue,
      );
    });

    test('a hard day followed by an easy one never is', () {
      expect(
        heavyPair(load('running', 75, 4), load('running', 60, 2)),
        isFalse,
      );
    });

    test('the planner judges borderline days more strictly', () {
      // A 145-min long run: just under a heavy day, inside the margin.
      final long = load('running', 145, 2);
      final key = load('trail_running', 55, 4);
      expect(heavyPair(key, long), isFalse);
      expect(heavyPair(key, long, margin: 0.9), isTrue);
    });
  });

  test('the trail weighs more than the road, the bike and pool less', () {
    expect([
      load('trail_running', 60, 2),
      load('running', 60, 2),
      load('hiking', 60, 2),
      load('cycling_road', 60, 2),
      load('swimming', 60, 2),
    ], orderedEquals([78.0, 60.0, 42.0, 36.0, 24.0]));
  });
}
