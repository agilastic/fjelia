// Cleaning of pace and speed samples for activity charts.
//
// Pace is minutes per kilometre, the inverse of speed: standing at a traffic
// light gives a near-zero speed and a pace of 30 or 60 min/km. Plotted as is,
// those moments become tall spikes and the axis stretches until the real
// running pace is a flat line at the bottom. Sports apps treat such moments
// as stops, not as pace.

/// Pace (min/km) slower than this is never running pace in a chart. Walking
/// breaks around 10–14 min/km stay visible; standing does not.
const stopPaceMinutes = 15.0;

/// Below this speed a ride or walk counts as standing still (about 2 km/h).
const stopSpeedMps = 0.55;

/// Running pace per sample: null for a stop, so the line breaks there instead
/// of shooting up. Single-sample GPS jumps are smoothed with a short median
/// that never reaches across a stop.
List<double?> chartPace(List<double?> speedsMps, {int window = 9}) {
  final raw = [
    for (final s in speedsMps)
      s == null || !s.isFinite || s < stopSpeedMps ? null : 1000 / s / 60,
  ];
  final moving = [
    for (final p in raw) p == null || p > stopPaceMinutes ? null : p,
  ];
  return _rollingMedian(moving, window);
}

/// Speed (km/h) per sample, standing still left out and jumps smoothed.
List<double?> chartSpeed(List<double?> speedsMps, {int window = 9}) =>
    _rollingMedian([
      for (final s in speedsMps)
        s == null || !s.isFinite || s < stopSpeedMps ? null : s * 3.6,
    ], window);

List<double?> _rollingMedian(List<double?> values, int window) {
  final half = window ~/ 2;
  return [
    for (var i = 0; i < values.length; i++)
      if (values[i] == null)
        null
      else
        () {
          // Only the unbroken stretch around i: a stop ends the window.
          final near = <double>[values[i]!];
          for (var j = i - 1; j >= i - half && j >= 0; j--) {
            if (values[j] == null) break;
            near.add(values[j]!);
          }
          for (var j = i + 1; j <= i + half && j < values.length; j++) {
            if (values[j] == null) break;
            near.add(values[j]!);
          }
          near.sort();
          final m = near.length ~/ 2;
          return near.length.isOdd ? near[m] : (near[m - 1] + near[m]) / 2;
        }(),
  ];
}

/// The axis range that shows the bulk of the values: the 2nd to 98th
/// percentile with some room, so one leftover outlier cannot flatten the
/// rest. Values outside are clipped at the edge of the chart.
(double, double) robustRange(
  Iterable<double> values, {
  double minSpan = 1,
  double padding = .12,
}) {
  final sorted = [
    for (final v in values)
      if (v.isFinite) v,
  ]..sort();
  if (sorted.isEmpty) return (0, minSpan);
  double at(double q) => sorted[((sorted.length - 1) * q).round()];
  var low = at(.02), high = at(.98);
  if (high - low < minSpan) {
    final mid = (high + low) / 2;
    low = mid - minSpan / 2;
    high = mid + minSpan / 2;
  }
  final pad = (high - low) * padding;
  return (low - pad, high + pad);
}
