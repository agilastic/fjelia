import 'package:fjelia_core/services/race_prediction.dart';

import '../db/database.dart';

/// Race-time prediction from the athlete's best recent run (Riegel): loads
/// runs and VO2max history for [RacePrediction] in fjelia_core.
abstract class RacePredictor {
  /// Fastest run of ≤ 10 km, corrected for fitness change since then: by the
  /// VO2max trend when Garmin has history, otherwise 1 %/week of detraining
  /// (max 30 %).
  static Future<({double distM, String label, int timeSec})?> bestRunAnchor(
    AppDatabase db,
  ) async {
    final runs = await db.getRunningActivitiesForPrediction();
    if (!runs.any((a) => (a.distanceMeters ?? 0) <= 10000.0)) return null;
    final wellness = await db.getWellnessRange(1825);
    return RacePrediction.bestRunAnchor(runs, [
      for (final w in wellness)
        if ((w.vo2max ?? 0) > 0) (date: w.date, vo2max: w.vo2max!),
    ], now: DateTime.now());
  }

  /// 5 km time implied by a VO2max (inverse of Daniels' oxygen-cost curve).
  static int vo2maxToAnchor5kSec(double vo2max) =>
      RacePrediction.vo2maxToAnchor5kSec(vo2max);

  /// How much longer a course with [elevationGainM] over [distM] runs than a
  /// flat one: the course counts as that many times its distance.
  static double hillFactor(double distM, double? elevationGainM) =>
      RacePrediction.hillFactor(distM, elevationGainM);

  /// Riegel prediction with an uphill penalty for hilly courses.
  static int predict(
    int anchorSec,
    double anchorDistM,
    double targetDistM, {
    double? elevationGainM,
  }) => RacePrediction.predict(
    anchorSec,
    anchorDistM,
    targetDistM,
    elevationGainM: elevationGainM,
  );

  /// What recent running predicts for [goal]; null for other sports or
  /// without a usable run.
  static Future<int?> estimateFinish(AppDatabase db, RaceGoal goal) async {
    if (!RacePrediction.isPredictable(goal)) return null;
    return RacePrediction.estimateFinish(goal, await bestRunAnchor(db));
  }

  static String formatTime(int seconds) => RacePrediction.formatTime(seconds);
}
