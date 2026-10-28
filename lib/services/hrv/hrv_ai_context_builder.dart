import '../../models/hrv_pair_assessment.dart';
import '../../models/hrv_training_episode.dart';
import 'hrv_comparison_service.dart';
import 'hrv_timing_policy.dart';
import 'hrv_training_service.dart';

/// Renders the shared HRV assessment as compact context lines for every AI
/// provider. It only formats: values, signs, counts and limitations come from
/// the assessment, never from a calculation made here. No names, no GPS, no
/// RR data, no device identifiers.
class HrvAiContextBuilder {
  const HrvAiContextBuilder({this.policy = HrvTimingPolicy.standard});
  final HrvTimingPolicy policy;

  static String _hm(DateTime t) {
    final u = t.toUtc();
    return '${u.hour.toString().padLeft(2, '0')}:${u.minute.toString().padLeft(2, '0')}Z';
  }

  static String _date(DateTime t) {
    final u = t.toUtc();
    return '${u.year}-${u.month.toString().padLeft(2, '0')}-${u.day.toString().padLeft(2, '0')}';
  }

  static String _num(double v, [int digits = 1]) => v.toStringAsFixed(digits);

  static String _signed(double v, [int digits = 1]) {
    final text = v.toStringAsFixed(digits);
    return v > 0 && double.parse(text) != 0 ? '+$text' : text;
  }

  String _reading(MeasurementFact m, {Duration? delay}) =>
      '${_num(m.rmssdMs)}ms/${_hm(m.startedAt)}/${m.posture}/'
      '${m.durationSeconds}s/settle${m.settleSeconds}s'
      '${delay == null ? '' : '/after${delay.inMinutes}min'}';

  /// One line for one workout. [purpose] is `retrospective` for an
  /// explanation of a finished workout; a pre-training decision must not be
  /// given this line, because it contains what happened afterwards.
  String pairLine(
    EpisodeFact episode,
    HrvPairAssessment a, {
    HrvCohort? cohort,
    int? rpe,
    bool withHistory = true,
    bool withDate = false,
  }) {
    final end = episode.interval.endKnown ? episode.end : null;
    final parts = <String>[
      'Pair',
      'Policy:${a.policyVersion}',
      'Analysis:${a.analysisVersion}',
      'Evidence:${a.fingerprint}',
      'Purpose:retrospective',
      if (withDate) 'Date:${_date(episode.start)}',
      'Sport:${episode.sport}',
      'Assoc:${a.association.name}',
      'WorkoutStart:${_hm(episode.start)}',
      'WorkoutEnd:${end == null ? 'unknown' : _hm(end)}',
      'EndBasis:${episode.interval.basis.name}',
      'Pre:${a.pre == null ? 'none' : _reading(a.pre!)}',
      'Post:${a.post == null ? 'none' : _reading(a.post!, delay: a.postDelay)}',
      if (a.comparable)
        'Change:${_signed(a.deltaMs!)}ms/${_signed(a.deltaPercent!)}%/ln${_signed(a.deltaLn!, 4)}'
      else
        'Change:none',
      'Comparable:${a.comparable ? 'yes' : 'no'}',
      if (a.postDelay != null)
        'Timing:${a.inTargetBand ? 'inTargetBand' : 'outsideTargetBand'}',
      if (withHistory && cohort != null) 'History:${_history(cohort)}',
      'Limits:${_limits(a)}',
      if (rpe != null) 'Rpe:$rpe',
      'Unknown:${_unknown(a, cohort, rpe)}',
    ];
    return '[HRV:${parts.join(',')}]';
  }

  String _history(HrvCohort c) {
    if (!c.sufficient) {
      return 'n=${c.eligible}/need${policy.cohortMinimum}/insufficientData';
    }
    return 'n=${c.eligible}/median${_signed(c.medianMs!)}ms/'
        'q1${_signed(c.q1Ms!)}/q3${_signed(c.q3Ms!)}/'
        'span${c.span!.inDays}d';
  }

  String _limits(HrvPairAssessment a) {
    const order = [
      HrvReason.ambiguousActivity,
      HrvReason.interveningWorkout,
      HrvReason.unknownActualEnd,
      HrvReason.clockUncertain,
      HrvReason.postureMismatch,
      HrvReason.durationMismatch,
      HrvReason.metricMismatch,
      HrvReason.invalidValue,
      HrvReason.invalidSignal,
      HrvReason.missingPre,
      HrvReason.missingPost,
      HrvReason.postOutsideTargetBand,
      HrvReason.legacyQualityUnknown,
    ];
    final found = [
      for (final r in order)
        if (a.reasons.contains(r)) r.name,
    ];
    return found.isEmpty ? 'none' : found.join('|');
  }

  String _unknown(HrvPairAssessment a, HrvCohort? c, int? rpe) {
    final unknown = <String>[
      if (rpe == null) 'RPE',
      'Heat',
      'Fuelling',
      'FollowUpNight',
      if (c == null || !c.sufficient) 'PersonalRange',
    ];
    return unknown.join('|');
  }

  /// Up to [limit] of the most recent workouts with HRV in the last seven
  /// days, plus one line saying how many workouts there were and how many had
  /// readings, so a workout that is not listed is never read as rest.
  List<String> recentLines(
    HrvSnapshot snapshot,
    DateTime now, {
    int limit = 3,
    Map<String, int> rpeByEpisode = const {},
  }) {
    final since = now.subtract(const Duration(days: 7));
    final inWindow = [
      for (final e in snapshot.episodes)
        if (e.end != null && !e.start.isBefore(since) && !e.start.isAfter(now))
          e,
    ]..sort((a, b) => b.start.compareTo(a.start));
    final withReadings = [
      for (final e in inWindow)
        if (snapshot.assessments[e.id] != null &&
            (snapshot.assessments[e.id]!.hasPre ||
                snapshot.assessments[e.id]!.hasPost))
          e,
    ];
    if (withReadings.isEmpty) return const [];
    final shown = withReadings.take(limit).toList();
    return [
      '[HRV:RecentPairs,Window:7d,Workouts:${inWindow.length},'
          'WithReadings:${withReadings.length},Shown:${shown.length},'
          'Note:UnlistedWorkoutsHaveNoReadingOrWereOmitted]',
      for (final e in shown)
        pairLine(
          e,
          snapshot.assessments[e.id]!,
          withHistory: false,
          withDate: true,
          rpe: rpeByEpisode[e.id],
        ),
    ];
  }

  /// One plain verdict per recent workout with chest-strap readings, for the
  /// daily briefing: before and after, which way HRV moved and whether that
  /// is the favourable direction. It is a different measurement from the
  /// overnight watch HRV and says so. Nothing is calculated here: the change
  /// comes from the assessment.
  List<String> analysisLines(
    HrvSnapshot snapshot,
    DateTime now, {
    int limit = 2,
  }) {
    final since = now.subtract(const Duration(days: 7));
    final recent = [
      for (final e in snapshot.episodes)
        if (e.end != null &&
            !e.start.isBefore(since) &&
            !e.start.isAfter(now) &&
            snapshot.assessments[e.id] != null &&
            (snapshot.assessments[e.id]!.hasPre ||
                snapshot.assessments[e.id]!.hasPost))
          e,
    ]..sort((a, b) => b.start.compareTo(a.start));
    final today = DateTime(now.year, now.month, now.day);
    final lines = <String>[];
    for (final e in recent.take(limit)) {
      final a = snapshot.assessments[e.id]!;
      final local = e.start.toLocal();
      final ago = today
          .difference(DateTime(local.year, local.month, local.day))
          .inDays;
      final when = ago == 0 ? 'today' : '$ago days ago';
      final pre = a.pre?.rmssdMs, post = a.post?.rmssdMs;
      final have = [
        if (pre != null) 'before ${_num(pre, 0)} ms',
        if (post != null) 'after ${_num(post, 0)} ms',
      ].join(' and ');
      final sport = e.sport.replaceAll('_', ' ');
      final String verdict, text;
      if (a.comparable && a.deltaMs != null && a.deltaPercent != null) {
        final rose = a.deltaMs! > 0;
        final flat = a.deltaPercent!.abs() < 3;
        verdict = flat
            ? 'steady'
            : rose
            ? 'better'
            : 'worse';
        text =
            'Training HRV (chest strap) around the $sport $when: $have; '
            '${flat
                ? 'about the same'
                : rose
                ? 'ROSE ${_num(a.deltaPercent!.abs(), 0)}% (favourable)'
                : 'FELL ${_num(a.deltaPercent!.abs(), 0)}% (less favourable)'}. '
            'This is NOT sleep HRV: never compare the two values.';
      } else {
        verdict = 'none';
        text =
            'Training HRV (chest strap) around the $sport $when: $have; '
            'not comparable (${_limits(a).replaceAll('|', ' ')}) so no change is given. '
            'This is NOT sleep HRV: never compare the two values.';
      }
      lines.add(
        '[Analysis:TrainingHRV,Date:${_date(e.start)},DaysAgo:$ago,Sport:${e.sport},'
        'Pre:${pre == null ? 'none' : '${_num(pre, 0)}ms'},'
        'Post:${post == null ? 'none' : '${_num(post, 0)}ms'},'
        'Verdict:$verdict,Text:$text]',
      );
    }
    return lines;
  }
}
