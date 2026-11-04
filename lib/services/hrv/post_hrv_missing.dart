import '../../db/database.dart';
import 'hrv_post_reminder_policy.dart' show ReminderState;
import 'hrv_training_service.dart';

/// Of [activityIds], those whose post-workout HRV is still owed: a pre
/// reading, or a resting one earlier that day, exists but no post reading.
/// Workouts the dedicated HRV reminder already covers are left out, so the
/// athlete is not told twice.
Future<Set<String>> postHrvMissing(
  AppDatabase db,
  HrvTrainingService training,
  List<String> activityIds,
) async {
  if (activityIds.isEmpty) return const {};
  final snapshot = await training.reconcile();
  final covered = {
    for (final r in await db.select(db.hrvPostReminders).get())
      if (r.desiredState == ReminderState.scheduled.name ||
          r.desiredState == ReminderState.snoozed.name ||
          r.desiredState == ReminderState.awaitingAction.name)
        r.episodeId,
  };
  final result = <String>{};
  for (final id in activityIds) {
    final episodeId = await training.episodeIdOfActivity(id);
    if (episodeId == null || covered.contains(episodeId)) continue;
    final episode = snapshot.episode(episodeId);
    if (episode == null || !episode.live) continue;
    final pairing = snapshot.pairings[episodeId];
    if (pairing?.post != null || (pairing?.additionalPosts ?? []).isNotEmpty) {
      continue;
    }
    // A post that was not paired (yet) still counts as measured.
    if (snapshot.measurements.any(
      (m) => m.isPost && m.startedAt.isAfter(episode.start),
    )) {
      continue;
    }
    final start = episode.start.toLocal();
    final restedBefore = snapshot.measurements.any((m) {
      final at = m.startedAt.toLocal();
      // A watch's wellness check (COROS) is no cue for a strap reading.
      return m.context == 'resting' &&
          m.deviceId != 'coros' &&
          m.usable &&
          at.isBefore(start) &&
          at.year == start.year &&
          at.month == start.month &&
          at.day == start.day;
    });
    if (pairing?.pre != null || restedBefore) result.add(id);
  }
  return result;
}
