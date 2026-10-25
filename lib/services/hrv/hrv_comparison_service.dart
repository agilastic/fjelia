import '../../models/hrv_pair_assessment.dart';
import '../../models/hrv_training_episode.dart';
import 'hrv_timing_policy.dart';

/// Why a preceding workout is not in the comparison.
enum CohortExclusion {
  notComparable,
  sport,
  workoutLength,
  posture,
  protocol,
  sensor,
  timing,
  tooOld,
  notEarlier,
}

class HrvCohort {
  const HrvCohort({
    required this.eligible,
    required this.excluded,
    required this.sufficient,
    this.first,
    this.last,
    this.medianMs,
    this.q1Ms,
    this.q3Ms,
    this.medianPercent,
    this.q1Percent,
    this.q3Percent,
  });

  /// Preceding episodes in the comparison, one pair each.
  final int eligible;
  final Map<CohortExclusion, int> excluded;

  /// Enough episodes over enough days to show a descriptive range.
  final bool sufficient;
  final DateTime? first, last;
  final double? medianMs, q1Ms, q3Ms, medianPercent, q1Percent, q3Percent;

  Duration? get span =>
      first == null || last == null ? null : last!.difference(first!);

  int get excludedTotal => excluded.values.fold(0, (a, b) => a + b);
}

/// A finished episode together with its assessment.
class AssessedEpisode {
  const AssessedEpisode(this.episode, this.assessment);
  final EpisodeFact episode;
  final HrvPairAssessment assessment;
}

/// Matched history of the same athlete: only earlier workouts, one selected
/// pair per workout, and the same protocol. It never widens a filter to reach
/// the minimum count.
class HrvComparisonService {
  const HrvComparisonService({this.policy = HrvTimingPolicy.standard});
  final HrvTimingPolicy policy;

  HrvCohort cohortFor(
    AssessedEpisode target,
    List<AssessedEpisode> history, {
    DateTime? asOf,
  }) {
    final t = target.assessment;
    final excluded = <CohortExclusion, int>{};
    void skip(CohortExclusion why) =>
        excluded.update(why, (n) => n + 1, ifAbsent: () => 1);
    final now = asOf ?? target.episode.start;
    final used = <AssessedEpisode>[];
    final tPre = t.pre, tPost = t.post;
    final targetLength = target.episode.interval.elapsed;
    for (final h in history) {
      if (h.episode.id == target.episode.id) continue;
      final a = h.assessment;
      if (!h.episode.start.isBefore(target.episode.start)) {
        skip(CohortExclusion.notEarlier);
        continue;
      }
      if (now.difference(h.episode.start) > policy.cohortHorizon) {
        skip(CohortExclusion.tooOld);
        continue;
      }
      if (!a.comparable || a.pre == null || a.post == null) {
        skip(CohortExclusion.notComparable);
        continue;
      }
      if (h.episode.sport != target.episode.sport) {
        skip(CohortExclusion.sport);
        continue;
      }
      final length = h.episode.interval.elapsed;
      if (targetLength != null &&
          length != null &&
          (length.inSeconds < targetLength.inSeconds * .7 ||
              length.inSeconds > targetLength.inSeconds * 1.3)) {
        skip(CohortExclusion.workoutLength);
        continue;
      }
      if (tPre != null && a.pre!.posture != tPre.posture) {
        skip(CohortExclusion.posture);
        continue;
      }
      if (tPre != null &&
          (a.pre!.durationSeconds != tPre.durationSeconds ||
              a.pre!.settleSeconds != tPre.settleSeconds ||
              a.pre!.metricKind != tPre.metricKind)) {
        skip(CohortExclusion.protocol);
        continue;
      }
      if (tPre != null &&
          tPre.deviceId.isNotEmpty &&
          a.pre!.deviceId != tPre.deviceId) {
        skip(CohortExclusion.sensor);
        continue;
      }
      if (tPost != null && a.timingCohortMinutes != t.timingCohortMinutes) {
        skip(CohortExclusion.timing);
        continue;
      }
      used.add(h);
    }
    used.sort((a, b) => a.episode.start.compareTo(b.episode.start));
    final ms = [for (final h in used) h.assessment.deltaMs!]..sort();
    final pct = [for (final h in used) h.assessment.deltaPercent!]..sort();
    final first = used.isEmpty ? null : used.first.episode.start;
    final last = used.isEmpty ? null : used.last.episode.start;
    final spanOk =
        first != null && last!.difference(first) >= policy.cohortMinimumSpan;
    final sufficient = used.length >= policy.cohortMinimum && spanOk;
    return HrvCohort(
      eligible: used.length,
      excluded: excluded,
      sufficient: sufficient,
      first: first,
      last: last,
      medianMs: sufficient ? quantile(ms, .5) : null,
      q1Ms: sufficient ? quantile(ms, .25) : null,
      q3Ms: sufficient ? quantile(ms, .75) : null,
      medianPercent: sufficient ? quantile(pct, .5) : null,
      q1Percent: sufficient ? quantile(pct, .25) : null,
      q3Percent: sufficient ? quantile(pct, .75) : null,
    );
  }

  /// Linear interpolation between ranks, on an already sorted list.
  static double quantile(List<double> sorted, double q) {
    if (sorted.isEmpty) return double.nan;
    if (sorted.length == 1) return sorted.first;
    final pos = (sorted.length - 1) * q;
    final lo = pos.floor(), hi = pos.ceil();
    return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
  }
}
