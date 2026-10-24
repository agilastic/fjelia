import 'dart:convert';

/// Best 20-minute mean from cached distance/speed/power samples. Elapsed time
/// is derived from distance and speed.
/// Missing power interrupts the window; it is never treated as zero watts.
double? best20MinutePower(String? metricsJson) {
  if (metricsJson == null) return null;
  try {
    final raw = jsonDecode(metricsJson);
    if (raw is! List) return null;
    final segments = <(double, double)>[];
    double? previousDistance;
    double duration = 0, energy = 0, best = 0;
    var first = 0;
    for (final row in raw) {
      if (row is! Map) continue;
      final distance = row['d'];
      final speed = row['spd'];
      final watts = row['w'];
      final prior = previousDistance;
      previousDistance = distance is num && distance.isFinite
          ? distance.toDouble()
          : null;
      if (previousDistance == null ||
          prior == null ||
          speed is! num ||
          !speed.isFinite ||
          speed <= 0 ||
          watts is! num ||
          !watts.isFinite ||
          watts < 0) {
        segments.clear();
        duration = 0;
        energy = 0;
        first = 0;
        continue;
      }
      final dt = (previousDistance - prior) / speed;
      // Large gaps or distance resets cannot establish a continuous effort.
      if (dt <= 0 || dt > 60) {
        segments.clear();
        duration = 0;
        energy = 0;
        first = 0;
        continue;
      }
      segments.add((dt, watts.toDouble()));
      duration += dt;
      energy += dt * watts;
      while (first < segments.length && duration - segments[first].$1 >= 1200) {
        duration -= segments[first].$1;
        energy -= segments[first].$1 * segments[first].$2;
        first++;
      }
      if (duration >= 1200) {
        final average =
            (energy - (duration - 1200) * segments[first].$2) / 1200;
        if (average > best) best = average;
      }
    }
    return best > 0 ? best : null;
  } on FormatException {
    return null;
  }
}
