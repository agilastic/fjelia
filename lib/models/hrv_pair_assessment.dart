import 'hrv_training_episode.dart';

/// Why a pair is incomplete, limited or not comparable. UI and AI render the
/// same codes, so they never disagree about a limitation.
enum HrvReason {
  missingPre,
  missingPost,
  invalidSignal,
  legacyQualityUnknown,
  postureMismatch,
  durationMismatch,
  metricMismatch,
  clockUncertain,
  unknownActualEnd,
  interveningWorkout,
  postOutsideTargetBand,
  ambiguousActivity,
  insufficientComparableHistory,
  invalidValue,
}

/// Everything known about the HRV around one workout, computed once from
/// facts. The card, the chart and every AI provider read this object.
class HrvPairAssessment {
  const HrvPairAssessment({
    required this.episodeId,
    required this.association,
    required this.reasons,
    required this.policyVersion,
    required this.analysisVersion,
    required this.fingerprint,
    this.interval,
    this.pre,
    this.post,
    this.additionalPosts = const [],
    this.preGap,
    this.postDelay,
    this.comparable = false,
    this.deltaMs,
    this.deltaPercent,
    this.deltaLn,
    this.inTargetBand = false,
    this.timingCohortMinutes,
  });

  final String episodeId;
  final Association association;
  final ActualInterval? interval;
  final MeasurementFact? pre, post;
  final List<MeasurementFact> additionalPosts;

  /// Sampling end of the pre to the workout start, and the workout end to the
  /// sampling start of the post. Measured, never the reminder target.
  final Duration? preGap, postDelay;

  /// Directly comparable: same metric, posture and protocol, trustworthy
  /// timing. Only then the deltas below exist.
  final bool comparable;
  final double? deltaMs, deltaPercent, deltaLn;
  final bool inTargetBand;
  final int? timingCohortMinutes;
  final Set<HrvReason> reasons;
  final String policyVersion, analysisVersion, fingerprint;

  bool get hasPre => pre != null;
  bool get hasPost => post != null;
  bool get hasPair => hasPre && hasPost;
}
