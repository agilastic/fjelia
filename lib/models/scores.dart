enum RecoveryLevel { green, yellow, red }

/// Placeholder for per-zone strain breakdowns (not populated yet).
abstract class HrZone {
  const HrZone();
}

class RecoveryScore {
  const RecoveryScore({required this.score, required this.recommendation});

  /// 0–100, null when no input data was available.
  final double? score;

  /// `hard`, `moderate` or `rest`.
  final String recommendation;

  RecoveryLevel? get level {
    final s = score;
    if (s == null) return null;
    if (s >= 67) return RecoveryLevel.green;
    if (s >= 34) return RecoveryLevel.yellow;
    return RecoveryLevel.red;
  }
}

class SleepScore {
  const SleepScore({
    required this.score,
    required this.duration,
    required this.need,
    required this.deepPercent,
    required this.remPercent,
    required this.efficiency,
    this.wakeTime,
  });

  final double score;
  final Duration duration;
  final Duration need;
  final double deepPercent;
  final double remPercent;
  final double efficiency;
  final DateTime? wakeTime;
}

class StrainScore {
  const StrainScore({required this.score, this.zones = const []});

  /// TRIMP-based daily load, 0–2000.
  final double score;
  final List<HrZone> zones;
}

class BloodPressureScore {
  const BloodPressureScore({required this.score, this.nightDippingPercent});

  final double score;
  final double? nightDippingPercent;
}

class DayScores {
  const DayScores({
    required this.date,
    this.recovery,
    this.sleep,
    required this.strain,
    this.bloodPressure,
  });

  final DateTime date;
  final RecoveryScore? recovery;
  final SleepScore? sleep;
  final StrainScore strain;
  final BloodPressureScore? bloodPressure;
}
