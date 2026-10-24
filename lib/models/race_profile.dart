import '../services/race_predictor.dart';

/// How hilly a race is, from its climb per kilometre. Product thresholds, not
/// a standard: they only choose between kinds of training.
enum Terrain { flat, rolling, hilly, mountainous }

/// What a race asks, worked out from its distance, climbing and target time.
class RaceProfile {
  const RaceProfile({
    required this.sport,
    required this.distanceM,
    this.elevationM,
    this.targetSeconds,
  });

  final String sport;
  final double distanceM;
  final double? elevationM;
  final int? targetSeconds;

  double get distanceKm => distanceM / 1000;

  /// Metres climbed per kilometre, or null without elevation data.
  double? get climbPerKm {
    final e = elevationM;
    return e == null || e <= 0 || distanceKm <= 0 ? null : e / distanceKm;
  }

  /// Flat when the climbing is unknown: no data does not make a race hilly.
  Terrain get terrain {
    final c = climbPerKm;
    if (c == null || c < 10) return Terrain.flat;
    if (c < 20) return Terrain.rolling;
    if (c < 40) return Terrain.hilly;
    return Terrain.mountainous;
  }

  bool get isFootRace => sport == 'running' || sport == 'trail_running';
  bool get isRide => sport.startsWith('cycling');

  /// Target time as a pace in seconds per kilometre, climbing included.
  double? get goalPaceSecPerKm {
    final t = targetSeconds;
    return t == null || distanceKm <= 0 ? null : t / distanceKm;
  }

  /// The same pace on a flat course: the part of the time the climbing takes
  /// is taken out, so it compares with flat training paces.
  double? get flatEquivalentPaceSecPerKm {
    final t = targetSeconds;
    if (t == null || distanceKm <= 0) return null;
    return t / (distanceKm * RacePredictor.hillFactor(distanceM, elevationM));
  }

  /// Average speed of the target in km/h, for rides.
  double? get goalSpeedKmh {
    final t = targetSeconds;
    return t == null || t <= 0 ? null : distanceKm / (t / 3600);
  }

  /// Threshold speed in m/s estimated from the goal, for running only. Race
  /// pace is a share of threshold pace that falls with distance (about 104 %
  /// at 5 km, 97 % at a half marathon, 91 % at a marathon, 80 % beyond 80 km);
  /// an estimate for athletes without a measured threshold, nothing more.
  double? get estimatedThresholdSpeedMps {
    final pace = flatEquivalentPaceSecPerKm;
    if (!isFootRace || pace == null || pace <= 0) return null;
    return (1000 / pace) / _shareOfThreshold(distanceKm);
  }

  static double _shareOfThreshold(double km) {
    const points = [
      (5.0, 1.04),
      (10.0, 1.01),
      (21.1, 0.97),
      (42.2, 0.91),
      (80.0, 0.80),
    ];
    if (km <= points.first.$1) return points.first.$2;
    if (km >= points.last.$1) return points.last.$2;
    for (var i = 1; i < points.length; i++) {
      final (x1, y1) = points[i];
      if (km <= x1) {
        final (x0, y0) = points[i - 1];
        return y0 + (y1 - y0) * (km - x0) / (x1 - x0);
      }
    }
    return points.last.$2;
  }

  /// How the target compares with a prediction: positive when the target is
  /// that share faster than the prediction.
  double? aheadOfPrediction(int predictedSeconds) {
    final t = targetSeconds;
    return t == null || predictedSeconds <= 0
        ? null
        : (predictedSeconds - t) / predictedSeconds;
  }
}
