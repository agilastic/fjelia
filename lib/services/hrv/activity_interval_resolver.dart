import '../../models/hrv_training_episode.dart';
import 'hrv_timing_policy.dart';

/// Resolves the actual start and end of a workout from what a source stored.
///
/// Never uses a planned duration, an import time or the moving time as the
/// end. A paused 120 minute ride with 90 minutes moving ends after 120.
class ActivityIntervalResolver {
  const ActivityIntervalResolver({this.policy = HrvTimingPolicy.standard});
  final HrvTimingPolicy policy;

  /// Sources whose stored `durationSeconds` is the elapsed time from start to
  /// finish (the moving time is kept apart). Anything else has no trusted end.
  static const elapsedSources = {
    'garmin_api',
    'health_connect',
    'coros',
    'suunto',
    'polar',
  };

  ActualInterval resolve({
    required DateTime start,
    required int durationSeconds,
    String? source,
    int? movingDurationSeconds,
    DateTime? userReportedEnd,
    DateTime? now,
  }) {
    final tolerance = policy.futureTolerance;
    bool future(DateTime d) => now != null && d.isAfter(now.add(tolerance));

    // 1. Provider elapsed time added to the actual start.
    if (durationSeconds > 0 && elapsedSources.contains(source)) {
      final end = start.add(Duration(seconds: durationSeconds));
      if (future(end)) {
        return ActualInterval(start: start, clockUncertain: true);
      }
      // An elapsed time shorter than the moving time is not elapsed time.
      if (movingDurationSeconds == null ||
          movingDurationSeconds <= durationSeconds) {
        return ActualInterval(
          start: start,
          end: end,
          basis: IntervalBasis.providerElapsed,
        );
      }
    }
    // 2. The athlete said when the workout finished.
    if (userReportedEnd != null &&
        userReportedEnd.isAfter(start) &&
        !future(userReportedEnd)) {
      return ActualInterval(
        start: start,
        end: userReportedEnd,
        basis: IntervalBasis.userReported,
      );
    }
    // 3. Unknown: show what exists, schedule nothing.
    return ActualInterval(start: start);
  }
}
