import 'dart:math' as math;

import '../db/database.dart';

/// Race-time prediction from the athlete's best recent run (Riegel).
abstract class RacePredictor {
  /// Fastest run of ≤ 10 km, corrected for fitness change since then: by the
  /// VO2max trend when Garmin has history, otherwise 1 %/week of detraining
  /// (max 30 %).
  static Future<({double distM, String label, int timeSec})?> bestRunAnchor(
      AppDatabase db) async {
    final runs = (await db.getRunningActivitiesForPrediction())
        .where((a) => (a.distanceMeters ?? 0) <= 10000.0)
        .toList();
    if (runs.isEmpty) return null;
    final best = runs.reduce((a, b) {
      final paceA = a.durationSeconds / a.distanceMeters!;
      final paceB = b.durationSeconds / b.distanceMeters!;
      return paceA <= paceB ? a : b;
    });

    final dist = best.distanceMeters!;
    final distLabel = '${(dist / 1000).toStringAsFixed(1)} km';

    final wellness = (await db.getWellnessRange(1825))
        .where((w) => (w.vo2max ?? 0) > 0)
        .toList();

    double factor;
    String label;
    if (wellness.length >= 2) {
      final then = wellness.reduce((a, b) =>
          a.date.difference(best.startDate).abs() <=
                  b.date.difference(best.startDate).abs()
              ? a
              : b);
      final now = wellness.last;
      factor = then.vo2max! / now.vo2max!;
      final pct = ((now.vo2max! / then.vo2max! - 1) * 100).round();
      label = pct != 0
          ? 'best $distLabel · VO2max ${pct > 0 ? '+' : ''}$pct% adj'
          : 'best $distLabel';
    } else {
      final weeks = DateTime.now().difference(best.startDate).inDays / 7;
      final decay = (weeks * 0.01).clamp(0.0, 0.3);
      factor = 1 + decay;
      label = weeks > 4
          ? 'best $distLabel · ${weeks.round()}w decay'
          : 'best $distLabel';
    }

    return (
      distM: dist,
      label: label,
      timeSec: (best.durationSeconds * factor).round(),
    );
  }

  /// 5 km time implied by a VO2max (inverse of Daniels' oxygen-cost curve).
  static int vo2maxToAnchor5kSec(double vo2max) {
    final metersPerMin = 29.54 + 5.000663 * vo2max - 0.007546 * vo2max * vo2max;
    return (5000 / metersPerMin * 60).round();
  }

  /// Riegel prediction with an uphill penalty for hilly courses.
  static int predict(
    int anchorSec,
    double anchorDistM,
    double targetDistM, {
    double? elevationGainM,
  }) {
    var grade = 0.0;
    if (elevationGainM != null && elevationGainM > 0) {
      grade = (elevationGainM / targetDistM * 100).clamp(0.0, 30.0);
    }
    final hillFactor = 1 + 0.033 * grade + 0.00185 * grade * grade;
    final effective = targetDistM * hillFactor;
    return (anchorSec * math.pow(effective / anchorDistM, 1.06)).round();
  }

  static String formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
