import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../models/hrv_pair_assessment.dart';
import '../models/hrv_training_episode.dart';
import '../services/hrv/hrv_comparison_service.dart';
import '../services/hrv/hrv_timing_policy.dart';
import '../services/hrv/hrv_training_service.dart';
import 'database_provider.dart';
import 'spot_hrv_provider.dart';

final hrvTrainingServiceProvider = Provider<HrvTrainingService>(
  (ref) => HrvTrainingService(ref.watch(databaseProvider)),
);

/// Bumped after activities were imported or changed, so the associations are
/// worked out again.
final hrvActivitiesChangedProvider = StateProvider<int>((ref) => 0);

/// The shared result: episodes, links and assessments from one pass. The
/// workout card, the chart and the AI all read this.
final hrvSnapshotProvider = FutureProvider<HrvSnapshot>((ref) {
  ref.watch(spotHrvProvider);
  ref.watch(hrvActivitiesChangedProvider);
  return ref.watch(hrvTrainingServiceProvider).reconcile();
});

/// What the athlete said about a workout, and where it came from.
class WorkoutFeedback {
  const WorkoutFeedback({this.rpe, this.note, this.fromSession = false});
  final int? rpe;
  final String? note;

  /// Taken from the planned session's own RPE, not from a report made here.
  final bool fromSession;
  bool get isEmpty => rpe == null && (note == null || note!.isEmpty);
}

/// Everything the completed-workout card shows.
class WorkoutHrvView {
  const WorkoutHrvView({
    required this.episode,
    required this.assessment,
    required this.cohort,
    required this.feedback,
    this.reminder,
  });
  final EpisodeFact episode;
  final HrvPairAssessment assessment;
  final HrvCohort cohort;
  final WorkoutFeedback feedback;
  final HrvPostReminder? reminder;
}

/// The HRV view of one completed activity, or null when it is not a workout
/// the feature knows (a manual entry without a usable interval is still one).
final workoutHrvProvider = FutureProvider.family<WorkoutHrvView?, String>((
  ref,
  activityId,
) async {
  final snapshot = await ref.watch(hrvSnapshotProvider.future);
  final service = ref.watch(hrvTrainingServiceProvider);
  final db = ref.watch(databaseProvider);
  final episodeId = await service.episodeIdOfActivity(activityId);
  if (episodeId == null) return null;
  final episode = snapshot.episode(episodeId);
  final assessment = snapshot.assessments[episodeId];
  if (episode == null || assessment == null) return null;

  final assessed = [
    for (final e in snapshot.episodes)
      if (snapshot.assessments[e.id] != null)
        AssessedEpisode(e, snapshot.assessments[e.id]!),
  ];
  final cohort = const HrvComparisonService().cohortFor(
    AssessedEpisode(episode, assessment),
    assessed,
    asOf: episode.start,
  );

  final own = await service.latestFeedback(episodeId);
  var feedback = WorkoutFeedback(rpe: own?.rpe, note: own?.note);
  if (own == null) {
    final actual = await (db.select(
      db.sessionActuals,
    )..where((t) => t.activityId.equals(activityId))).getSingleOrNull();
    if (actual?.rpe != null) {
      feedback = WorkoutFeedback(rpe: actual!.rpe, fromSession: true);
    }
  }
  final reminder = await (db.select(
    db.hrvPostReminders,
  )..where((t) => t.episodeId.equals(episodeId))).getSingleOrNull();
  return WorkoutHrvView(
    episode: episode,
    assessment: assessment,
    cohort: cohort,
    feedback: feedback,
    reminder: reminder,
  );
});

/// The view of an episode by its own id, for a notification that names no
/// activity.
final episodeActivityIdProvider = FutureProvider.family<String?, String>((
  ref,
  episodeId,
) async {
  final db = ref.watch(databaseProvider);
  final e = await (db.select(
    db.hrvTrainingEpisodes,
  )..where((t) => t.episodeId.equals(episodeId))).getSingleOrNull();
  return e?.primaryActivityId;
});

/// The paired changes of the workouts that fit the chart's filters. Only
/// episodes with a comparable pair count, once each.
class HrvPairSummary {
  const HrvPairSummary({
    required this.pairs,
    required this.medianMs,
    required this.medianPercent,
    required this.first,
    required this.last,
  });
  final int pairs;
  final double? medianMs, medianPercent;
  final DateTime? first, last;
}

typedef HrvPairFilter = ({String? posture, DateTime from, DateTime to});

final hrvPairSummaryProvider =
    FutureProvider.family<HrvPairSummary, HrvPairFilter>((ref, f) async {
      final snapshot = await ref.watch(hrvSnapshotProvider.future);
      final changes = <double>[], percents = <double>[];
      DateTime? first, last;
      for (final e in snapshot.episodes) {
        final a = snapshot.assessments[e.id];
        if (a == null || !a.comparable) continue;
        if (e.start.isBefore(f.from) || !e.start.isBefore(f.to)) continue;
        if (f.posture != null && a.pre!.posture != f.posture) continue;
        changes.add(a.deltaMs!);
        percents.add(a.deltaPercent!);
        if (first == null || e.start.isBefore(first)) first = e.start;
        if (last == null || e.start.isAfter(last)) last = e.start;
      }
      changes.sort();
      percents.sort();
      return HrvPairSummary(
        pairs: changes.length,
        medianMs: changes.isEmpty
            ? null
            : HrvComparisonService.quantile(changes, .5),
        medianPercent: percents.isEmpty
            ? null
            : HrvComparisonService.quantile(percents, .5),
        first: first,
        last: last,
      );
    });

/// The activity row behind an episode, for opening its workout card.
final episodeActivityProvider = FutureProvider.family<ActivityRecord?, String>((
  ref,
  episodeId,
) async {
  final activityId = await ref.watch(
    episodeActivityIdProvider(episodeId).future,
  );
  if (activityId == null) return null;
  return ref.watch(databaseProvider).getActivityById(activityId);
});

/// How to open the capture sheet for the post measurement of an episode: the
/// protocol of its pre measurement, and the real end of the workout.
final hrvPostLaunchProvider = FutureProvider.family<HrvLaunchContext?, String>((
  ref,
  episodeId,
) async {
  final snapshot = await ref.watch(hrvSnapshotProvider.future);
  final episode = snapshot.episode(episodeId);
  if (episode == null) return null;
  final pre = snapshot.pairings[episodeId]?.pre;
  return HrvLaunchContext(
    episodeId: episodeId,
    role: HrvRole.post,
    posture: pre?.posture,
    durationSeconds: pre?.durationSeconds,
    workoutEnd: episode.end,
  );
});

/// Changes the athlete makes to the result: feedback and corrections. Each one
/// leaves the readings alone and refreshes everything that shows them.
final hrvTrainingActionsProvider = Provider<HrvTrainingActions>(
  HrvTrainingActions.new,
);

class HrvTrainingActions {
  HrvTrainingActions(this.ref);
  final Ref ref;

  HrvTrainingService get _service => ref.read(hrvTrainingServiceProvider);

  void _refresh() {
    ref.invalidate(hrvSnapshotProvider);
  }

  Future<void> recordFeedback(
    String episodeId, {
    int? rpe,
    String? note,
  }) async {
    await _service.recordFeedback(episodeId, rpe: rpe, note: note);
    _refresh();
  }

  /// Fixes a reading to a workout. Only for an exception: the ordinary case
  /// pairs by itself.
  Future<void> correct(
    String measurementUid,
    String episodeId,
    HrvRole role,
  ) async {
    await _service.correct(measurementUid, episodeId, role);
    _refresh();
  }

  Future<void> unlink(String measurementUid) async {
    await _service.unlink(measurementUid);
    _refresh();
  }
}

/// How many comparable workouts the descriptive range needs.
final hrvCohortMinimumProvider = Provider<int>(
  (ref) => HrvTimingPolicy.standard.cohortMinimum,
);

/// A before-training reading from the last hours that belongs to no workout
/// yet: the athlete may still be out training, or the workout has not been
/// imported. The reminder waits for the real end of that workout.
final hrvPendingPreProvider = FutureProvider<MeasurementFact?>((ref) async {
  final snapshot = await ref.watch(hrvSnapshotProvider.future);
  final now = DateTime.now();
  MeasurementFact? best;
  for (final m in snapshot.measurements) {
    if (!m.isPre || !m.usable || m.clockUncertain) continue;
    if (snapshot.episodeOfMeasurement(m.uid) != null) continue;
    if (m.endedAt.isAfter(now) ||
        now.difference(m.endedAt) > const Duration(hours: 8)) {
      continue;
    }
    if (best == null || m.endedAt.isAfter(best.endedAt)) best = m;
  }
  return best;
});
