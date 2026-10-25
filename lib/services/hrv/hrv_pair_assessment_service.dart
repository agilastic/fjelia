import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

import '../../models/hrv_pair_assessment.dart';
import '../../models/hrv_training_episode.dart';
import 'hrv_timing_policy.dart';

/// Pure pair facts and arithmetic. No scheduling, no AI, no I/O.
class HrvPairAssessmentService {
  const HrvPairAssessmentService({this.policy = HrvTimingPolicy.standard});
  final HrvTimingPolicy policy;

  static const analysisVersion = 'paired-response-v1';

  HrvPairAssessment assess(
    EpisodeFact episode,
    EpisodePairing pairing, {
    bool interveningWorkout = false,
  }) {
    final pre = pairing.pre, post = pairing.post;
    final interval = episode.interval;
    final reasons = <HrvReason>{};
    if (pre == null) reasons.add(HrvReason.missingPre);
    if (post == null) reasons.add(HrvReason.missingPost);
    if (!interval.endKnown) reasons.add(HrvReason.unknownActualEnd);
    if (interval.clockUncertain) reasons.add(HrvReason.clockUncertain);
    if (pairing.association == Association.ambiguous) {
      reasons.add(HrvReason.ambiguousActivity);
    }
    if (interveningWorkout) reasons.add(HrvReason.interveningWorkout);
    for (final m in [?pre, ?post]) {
      if (m.legacyQualityUnknown) reasons.add(HrvReason.legacyQualityUnknown);
      if (!m.usable) reasons.add(HrvReason.invalidSignal);
      if (m.clockUncertain) reasons.add(HrvReason.clockUncertain);
    }

    final preGap = pre == null ? null : episode.start.difference(pre.endedAt);
    final end = interval.end;
    final postDelay = post == null || end == null || !interval.endKnown
        ? null
        : post.startedAt.difference(end);
    final inBand = postDelay != null && policy.inTargetBand(postDelay);
    if (postDelay != null && !inBand) {
      reasons.add(HrvReason.postOutsideTargetBand);
    }

    var comparable = pre != null && post != null;
    if (pre != null && post != null) {
      if (pre.metricKind != post.metricKind) {
        reasons.add(HrvReason.metricMismatch);
        comparable = false;
      }
      if (pre.posture != post.posture) {
        reasons.add(HrvReason.postureMismatch);
        comparable = false;
      }
      if (pre.durationSeconds != post.durationSeconds ||
          pre.settleSeconds != post.settleSeconds) {
        reasons.add(HrvReason.durationMismatch);
        comparable = false;
      }
      if (!_positive(pre.rmssdMs) || !_positive(post.rmssdMs)) {
        reasons.add(HrvReason.invalidValue);
        comparable = false;
      }
    }
    if (!interval.endKnown ||
        interval.clockUncertain ||
        pairing.association == Association.ambiguous ||
        interveningWorkout ||
        (pre != null && (!pre.usable || pre.clockUncertain)) ||
        (post != null && (!post.usable || post.clockUncertain))) {
      comparable = false;
    }

    double? delta, percent, ln;
    if (comparable) {
      // Full precision; rounding is for the screen only.
      delta = post!.rmssdMs - pre!.rmssdMs;
      percent = 100 * delta / pre.rmssdMs;
      ln = math.log(post.rmssdMs) - math.log(pre.rmssdMs);
    }
    return HrvPairAssessment(
      episodeId: episode.id,
      association: pairing.association,
      interval: interval,
      pre: pre,
      post: post,
      additionalPosts: pairing.additionalPosts,
      preGap: preGap,
      postDelay: postDelay,
      comparable: comparable,
      deltaMs: delta,
      deltaPercent: percent,
      deltaLn: ln,
      inTargetBand: inBand,
      timingCohortMinutes: postDelay == null
          ? null
          : policy.timingCohort(postDelay),
      reasons: reasons,
      policyVersion: policy.version,
      analysisVersion: analysisVersion,
      fingerprint: _fingerprint(episode, pairing),
    );
  }

  static bool _positive(double v) => v.isFinite && v > 0;

  /// Changes whenever a fact the result depends on changes, so a cached
  /// answer built from older facts can be told apart.
  String _fingerprint(EpisodeFact e, EpisodePairing p) {
    final parts = [
      policy.version,
      analysisVersion,
      e.id,
      e.start.toUtc().toIso8601String(),
      e.end?.toUtc().toIso8601String() ?? '',
      e.interval.basis.name,
      '${e.intervalRevision}',
      for (final m in [p.pre, p.post, ...p.additionalPosts])
        if (m != null)
          '${m.uid}:${m.revision}:${m.context}:${m.posture}:'
              '${m.rmssdMs}:${m.durationSeconds}:${m.settleSeconds}',
    ];
    return sha1
        .convert(utf8.encode(parts.join('|')))
        .toString()
        .substring(0, 16);
  }
}
