import 'chart_point.dart';

class ActivityTimelineSpan {
  const ActivityTimelineSpan({
    required this.id,
    required this.name,
    required this.startDate,
    required this.durationSeconds,
    this.avgHeartRate,
  });
  final String id, name;
  final DateTime startDate;
  final int durationSeconds;
  final double? avgHeartRate;
}

/// Integrates adjacent timestamped readings; never bridges gaps above five minutes.
class HeartRateStatistics {
  const HeartRateStatistics(this.average, this.coveredDuration);
  final double? average;
  final Duration coveredDuration;
  factory HeartRateStatistics.fromPoints(List<ChartPoint> points) {
    final unique = <int, double>{};
    for (final p in points) {
      if (p.value.isFinite && p.value > 0) {
        unique.putIfAbsent(p.at.millisecondsSinceEpoch, () => p.value);
      }
    }
    final times = unique.keys.toList()..sort();
    var covered = 0;
    var integral = 0.0;
    for (var i = 1; i < times.length; i++) {
      final duration = times[i] - times[i - 1];
      if (duration <= 0 || duration > const Duration(minutes: 5).inMilliseconds) {
        continue;
      }
      integral += (unique[times[i - 1]]! + unique[times[i]]!) / 2 * duration;
      covered += duration;
    }
    return HeartRateStatistics(
      covered == 0 ? null : integral / covered,
      Duration(milliseconds: covered),
    );
  }
}

class HeartRateDaySummary {
  HeartRateDaySummary({
    required this.points,
    required this.activities,
    this.resting,
  }) {
    final statistics = HeartRateStatistics.fromPoints(points);
    average = statistics.average;
    coveredDuration = statistics.coveredDuration;
    final valid = points
        .where((p) => p.value.isFinite && p.value > 0)
        .map((p) => p.value);
    peak = valid.isEmpty ? null : valid.reduce((a, b) => a > b ? a : b);
  }
  final List<ChartPoint> points;
  final List<ActivityTimelineSpan> activities;
  final int? resting;
  late final double? average, peak;
  late final Duration coveredDuration;
}
