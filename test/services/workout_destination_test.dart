import 'package:fjelia/services/workout_destination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const order = ['garmin_api', 'coros', 'polar', 'suunto', 'health_connect'];

  test('the first connected watch platform in the athlete\'s order', () {
    expect(
      pickWorkoutDestination(order, {'garmin_api', 'coros'}),
      WorkoutDestination.garmin,
    );
    // Garmin not connected: the next one in the order.
    expect(
      pickWorkoutDestination(order, {'coros', 'suunto'}),
      WorkoutDestination.coros,
    );
    // The athlete moved Suunto to the top.
    expect(
      pickWorkoutDestination(
        ['suunto', 'garmin_api', 'coros'],
        {'garmin_api', 'suunto'},
      ),
      WorkoutDestination.suunto,
    );
    expect(pickWorkoutDestination(order, {'polar'}), WorkoutDestination.polar);
  });

  test('nothing connected, or only a phone source, stays on Garmin', () {
    expect(pickWorkoutDestination(order, {}), WorkoutDestination.garmin);
    expect(
      pickWorkoutDestination(order, {'health_connect'}),
      WorkoutDestination.garmin,
    );
    expect(
      pickWorkoutDestination(const [], {'coros'}),
      WorkoutDestination.garmin,
    );
  });

  test('only Garmin is pushed to, the others explain what they need', () {
    expect(WorkoutDestination.garmin.canPush, isTrue);
    expect(WorkoutDestination.garmin.unavailableNote, isNull);
    for (final d in [
      WorkoutDestination.coros,
      WorkoutDestination.polar,
      WorkoutDestination.suunto,
    ]) {
      expect(d.canPush, isFalse);
      expect(d.unavailableNote, contains(d.label));
      expect(d.unavailableNote, contains('partner access'));
    }
  });
}
