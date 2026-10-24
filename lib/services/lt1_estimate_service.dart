class Lt1Estimate {
  const Lt1Estimate(this.bpm, this.source);

  final int bpm;

  /// Human-readable origin of the estimate.
  final String source;
}

/// Best available aerobic-threshold (LT1) heart rate.
abstract class Lt1EstimateService {
  static Lt1Estimate? compute({int? driftLt1, int? lt2, int? maxHr}) {
    if (driftLt1 != null) return Lt1Estimate(driftLt1, 'HR drift test');
    if (lt2 != null) return Lt1Estimate(lt2 - 30, 'LT2 − 30 bpm');
    if (maxHr != null) return Lt1Estimate((maxHr * 0.77).round(), '77% maxHR');
    return null;
  }
}
