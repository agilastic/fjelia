import 'package:drift/drift.dart';

import '../db/database.dart';
import 'dfa_alpha1_service.dart';

import 'package:fjelia_core/services/activity_coach_context.dart';
import 'package:fjelia_core/services/hrv/hrv_ai_context_builder.dart';
import 'package:fjelia_core/services/hrv/hrv_comparison_service.dart';

import 'hrv/hrv_training_service.dart';

export 'package:fjelia_core/services/activity_coach_context.dart'
    show hrvAroundLine;

/// Compact TOON context for chatting about one activity: the activity with
/// its details (zones, pacing, DFA alpha1), the day around it (sleep, HRV,
/// readiness), the planned session it fulfilled, the sessions just before and
/// after it, the 30 days of training leading up to it and the year's
/// progression (with the same period of the previous year). Anchored to the activity's date, so
/// older activities are judged against the training around them. Names and
/// GPS are never included.
class ActivityCoachContextBuilder {
  ActivityCoachContextBuilder(this._db);

  final AppDatabase _db;

  Future<String> build(ActivityRecord activity) async {
    final from = DateTime(activity.startDate.year - 1, 1, 1);
    final days = DateTime.now().difference(from).inDays + 1;
    final all = await _db.getActivitiesInRange(days);
    var nights = await _hrvAround(activity);
    final pair = await _hrvPair(activity);
    // "Unavailable" would contradict a pair that exists.
    if (pair != null && nights == '[HRV:AroundActivity,Unavailable]') {
      nights = '';
    }
    final base = buildFrom(
      activity,
      all,
      hrvLine: nights.isEmpty ? null : nights,
    );
    final side = [
      await _dayLine(activity),
      await _planLine(activity),
      await _dfaLine(activity),
    ].whereType<String>();
    return [base, ?pair, ...side].join('\n');
  }

  /// Sleep, readiness and daily load of the day the activity was on.
  Future<String?> _dayLine(ActivityRecord a) async {
    final day = DateTime(a.startDate.year, a.startDate.month, a.startDate.day);
    final sleep = await _db.getSleepForDate(day);
    final wellness = await _db.getWellnessForDate(day);
    final score = await _db.getScoreForDate(day);
    final readiness =
        await (_db.select(_db.dailyReadinessRecords)
              ..where(
                (t) =>
                    t.date.isBiggerOrEqualValue(day) &
                    t.date.isSmallerThanValue(day.add(const Duration(days: 1))),
              )
              ..limit(1))
            .getSingleOrNull();
    final parts = [
      if (sleep != null && sleep.totalSleepSeconds > 0)
        'SleepH:${_dec(sleep.totalSleepSeconds / 3600)}',
      if (sleep?.sleepScore != null) 'SleepScore:${_int(sleep!.sleepScore)}',
      if (readiness?.restingHrToday != null)
        'RHR:${_int(readiness!.restingHrToday)}'
            '${readiness.restingHrElevation == null ? '' : '(${readiness.restingHrElevation! >= 0 ? '+' : ''}${_int(readiness.restingHrElevation)} vs 7d)'}',
      if (readiness?.hrvDropPct != null)
        'HRVvs7d:${readiness!.hrvDropPct! > 0 ? '-' : '+'}${_int(readiness.hrvDropPct!.abs())}%',
      if (readiness?.tsb != null) 'TSB:${_int(readiness!.tsb)}',
      if (score?.readinessScore != null)
        'Readiness:${_int(score!.readinessScore)}',
      if (score?.recoveryScore != null)
        'Recovery:${_int(score!.recoveryScore)}',
      if (wellness?.averageStress != null)
        'Stress:${_int(wellness!.averageStress)}',
      if (wellness?.bodyBatteryHighest != null)
        'BodyBattery:${_int(wellness!.bodyBatteryLowest)}-${_int(wellness.bodyBatteryHighest)}',
      if (wellness?.steps != null) 'Steps:${wellness!.steps}',
    ];
    return parts.isEmpty ? null : '[DayOfActivity:${parts.join(',')}]';
  }

  /// The planned session this activity fulfilled and how it went against it.
  Future<String?> _planLine(ActivityRecord a) async {
    final actual = await (_db.select(
      _db.sessionActuals,
    )..where((t) => t.activityId.equals(a.activityId))).getSingleOrNull();
    if (actual == null) return null;
    final session = await (_db.select(
      _db.trainingSessions,
    )..where((t) => t.id.equals(actual.sessionId))).getSingleOrNull();
    final parts = [
      if (session != null) ...[
        'Type:${session.sessionType}',
        'Phase:${session.phase}',
        'PlannedMin:${session.plannedDurationMin}',
        'PlannedZone:Z${session.primaryZone}',
      ],
      if (actual.durationRatio != null)
        'DurationVsPlan:${_dec(actual.durationRatio)}x',
      if (actual.executionScore != null)
        'Execution:${actual.executionScore}/100',
      if (actual.executionVerdict != null) 'Verdict:${actual.executionVerdict}',
      if (actual.outcome != null) 'Outcome:${actual.outcome}',
      if (actual.intensityVerdict != null)
        'IntensityVsPlan:${actual.intensityVerdict}',
      if (actual.shortReason != null) 'ShorterBecause:${actual.shortReason}',
      if (actual.matchKind != null) 'DoneAs:${actual.matchKind}',
      if (actual.rpe != null) 'RPE:${actual.rpe}',
    ];
    return parts.isEmpty ? null : '[PlannedSession:${parts.join(',')}]';
  }

  /// DFA alpha1 thresholds from the beat-to-beat data, when there were any.
  Future<String?> _dfaLine(ActivityRecord a) async {
    final r = await DfaAlpha1Service(_db).load(a.activityId);
    if (r == null) return null;
    // Thresholds only from a session that built from easy to hard.
    final thresholds = r.windows.isNotEmpty && !r.progression
        ? 'NoThresholds:NotAProgression'
        : 'HRVT1:${_int(r.hrvt1?.heartRate)}bpm,'
              'HRVT2:${_int(r.hrvt2?.heartRate)}bpm'
              '${r.hrvt1?.watts == null ? '' : ',HRVT1W:${_int(r.hrvt1!.watts)}'}'
              '${r.hrvt2?.watts == null ? '' : ',HRVT2W:${_int(r.hrvt2!.watts)}'}';
    return '[DFAalpha1:Beats:${r.rrCount},'
        'Artifacts:${_dec(r.artifacts * 100)}%,$thresholds]';
  }

  /// The overnight HRV before and after the activity, when it was recorded.
  /// Watch values come from another method than the chest strap, so they are
  /// labelled as such and never compared with the spot readings. The night
  /// after is the first one that starts after the workout ended, which for a
  /// workout over midnight is a day later than its start date suggests.
  Future<String> _hrvAround(ActivityRecord a) async {
    final end = a.startDate.add(Duration(seconds: a.durationSeconds));
    final day = DateTime(a.startDate.year, a.startDate.month, a.startDate.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final before = await _db.getHrvForDate(day);
    final after = await _db.getHrvForDate(
      DateTime(endDay.year, endDay.month, endDay.day + 1),
    );
    return hrvAroundLine(
      start: a.startDate,
      end: end,
      preNight: before?.hrvLastNight,
      preDate: before?.date,
      weeklyAverage: before?.hrvWeeklyAvg,
      postNight: after?.hrvLastNight,
      postDate: after?.date,
    );
  }

  /// The pre/post readings of this workout from the shared assessment: the
  /// same facts the workout card shows. Null when the workout is unknown to
  /// the HRV feature.
  Future<String?> _hrvPair(ActivityRecord a) async {
    final service = HrvTrainingService(_db);
    final snapshot = await service.reconcile();
    final episodeId = await service.episodeIdOfActivity(a.activityId);
    if (episodeId == null) return null;
    final episode = snapshot.episode(episodeId);
    final assessment = snapshot.assessments[episodeId];
    if (episode == null || assessment == null) return null;
    final cohort = const HrvComparisonService().cohortFor(
      AssessedEpisode(episode, assessment),
      [
        for (final e in snapshot.episodes)
          if (snapshot.assessments[e.id] != null)
            AssessedEpisode(e, snapshot.assessments[e.id]!),
      ],
      asOf: episode.start,
    );
    final feedback = await service.latestFeedback(episodeId);
    int? rpe = feedback?.rpe;
    if (rpe == null) {
      final actual = await (_db.select(
        _db.sessionActuals,
      )..where((t) => t.activityId.equals(a.activityId))).getSingleOrNull();
      rpe = actual?.rpe;
    }
    // Readings that belong to no workout are not a pair; say that they exist.
    final unassigned = snapshot.measurements
        .where(
          (m) =>
              snapshot.episodeOfMeasurement(m.uid) == null &&
              m.context != 'resting' &&
              m.startedAt.difference(a.startDate).abs() <
                  const Duration(hours: 6),
        )
        .length;
    final line = const HrvAiContextBuilder().pairLine(
      episode,
      assessment,
      cohort: cohort,
      rpe: rpe,
    );
    if (!assessment.hasPre && !assessment.hasPost && unassigned == 0) {
      return null;
    }
    return unassigned == 0
        ? line
        : '$line\n[HRV:Unassigned,Count:$unassigned,'
              'Note:ReadingsNearThisWorkoutThatBelongToNoWorkoutNotAPair]';
  }

  static String buildFrom(
    ActivityRecord activity,
    List<ActivityRecord> all, {
    String? hrvLine,
  }) => ActivityCoachContext.buildFrom(activity, all, hrvLine: hrvLine);

  static String _int(num? v) => ActivityCoachContext.formatInt(v);
  static String _dec(num? v) => ActivityCoachContext.formatDecimal(v);
}
