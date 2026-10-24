import 'garmin_data.dart';

/// What the horizontal axis of an activity chart measures.
enum ActivityAxis { distance, time }

/// Samples closer together than this have no distance worth plotting.
const _minDistanceMeters = 100.0;

/// Strength, yoga and many indoor sessions record no distance: every sample
/// sits at 0 m, so a distance axis would squeeze the whole chart into one
/// point. Those activities are plotted over time instead.
ActivityAxis activityAxisFor(List<ActivitySample> samples) {
  var farthest = 0.0;
  for (final s in samples) {
    if (s.distanceMeters.isFinite && s.distanceMeters > farthest) {
      farthest = s.distanceMeters;
    }
  }
  return farthest >= _minDistanceMeters
      ? ActivityAxis.distance
      : ActivityAxis.time;
}

/// Minutes since the start for every sample, in the order of [samples].
///
/// Uses the recorded timestamps. When fewer than two samples have one, the
/// samples are spread evenly over [duration]; that is exact for the usual
/// regular recording and honest about the total length.
List<double> sampleMinutes(List<ActivitySample> samples, Duration duration) {
  final times = [for (final s in samples) s.timestamp];
  final known = times.whereType<DateTime>().toList()..sort();
  if (known.length >= 2) {
    final first = known.first;
    var previous = 0.0;
    return [
      for (final t in times)
        t == null
            ? previous
            : previous = t.difference(first).inMilliseconds / 60000,
    ];
  }
  final total = duration.inMilliseconds / 60000;
  if (samples.length < 2) return List.filled(samples.length, 0);
  return [
    for (var i = 0; i < samples.length; i++) total * i / (samples.length - 1),
  ];
}

/// An axis label for [minutes] of a chart that spans [totalMinutes].
String formatAxisMinutes(double minutes, double totalMinutes) {
  final m = minutes.round();
  if (totalMinutes >= 60) {
    return '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';
  }
  return '$m min';
}

/// A round tick spacing in minutes that gives about six labels over
/// [totalMinutes].
double niceMinuteInterval(double totalMinutes) {
  const steps = [1.0, 2.0, 5.0, 10.0, 15.0, 20.0, 30.0, 60.0, 120.0, 180.0];
  final wanted = totalMinutes / 6;
  for (final step in steps) {
    if (step >= wanted) return step;
  }
  return steps.last;
}
