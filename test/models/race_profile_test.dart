import 'package:fjelia/models/race_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RaceProfile marathon({double? climb, int? target = 12600}) => RaceProfile(
    sport: 'running',
    distanceM: 42200,
    elevationM: climb,
    targetSeconds: target,
  );

  test('terrain follows the climb per kilometre', () {
    expect(marathon(climb: 100).terrain, Terrain.flat);
    expect(marathon(climb: 600).terrain, Terrain.rolling);
    expect(marathon(climb: 1200).terrain, Terrain.hilly);
    expect(
      const RaceProfile(
        sport: 'trail_running',
        distanceM: 73000,
        elevationM: 3000,
      ).terrain,
      Terrain.mountainous,
    );
    // Unknown climbing is not a hilly race.
    expect(marathon().terrain, Terrain.flat);
    expect(marathon(climb: 0).terrain, Terrain.flat);
  });

  test('goal pace and its flat equivalent', () {
    final flat = marathon(climb: 100);
    expect(flat.goalPaceSecPerKm, closeTo(298.6, .1));
    // A flat course changes the pace by little, a hilly one by a lot.
    expect(
      flat.flatEquivalentPaceSecPerKm!,
      closeTo(flat.goalPaceSecPerKm!, 3),
    );
    final hilly = marathon(climb: 1200);
    expect(
      hilly.flatEquivalentPaceSecPerKm!,
      lessThan(hilly.goalPaceSecPerKm! * 0.95),
    );
    expect(marathon(target: null).goalPaceSecPerKm, isNull);
  });

  test('threshold speed estimate from a marathon goal', () {
    // 3:30 is about 4:59/km, 3.35 m/s: threshold about 3.7 m/s (4:30/km).
    final speed = marathon(climb: 100).estimatedThresholdSpeedMps!;
    expect(speed, closeTo(3.68, .05));
    // A faster goal, a faster threshold.
    expect(
      marathon(target: 3 * 3600 + 1800 - 1800).estimatedThresholdSpeedMps!,
      greaterThan(speed),
    );
    // Not for rides, not without a target.
    expect(
      const RaceProfile(
        sport: 'cycling_road',
        distanceM: 100000,
        targetSeconds: 14400,
      ).estimatedThresholdSpeedMps,
      isNull,
    );
    expect(marathon(target: null).estimatedThresholdSpeedMps, isNull);
  });

  test('ride speed and how far a goal is ahead of a prediction', () {
    const ride = RaceProfile(
      sport: 'cycling_road',
      distanceM: 100000,
      targetSeconds: 14400,
    );
    expect(ride.goalSpeedKmh, closeTo(25, 1e-9));
    expect(marathon().aheadOfPrediction(12780), closeTo(0.0141, .001));
    expect(marathon().aheadOfPrediction(11000), lessThan(0));
    expect(marathon(target: null).aheadOfPrediction(12000), isNull);
  });
}
