import 'dart:math' as math;

import '../models/garmin_data.dart';

/// Length of one step of the estimate.
const _step = Duration(minutes: 5);

/// An estimated stage timeline for a night whose watch gives only the stage
/// totals (COROS), built from the HRV and stress it measured overnight.
///
/// The totals stay exactly the watch's: only *when* each stage happened is
/// estimated. Deep sleep goes where stress is low and HRV steady, REM where
/// stress rises and HRV varies, both on the usual frame of a night (deep
/// early, REM late, cycles of about 90 minutes). Empty when there is too
/// little to go on.
List<SleepPhase> estimateSleepStages({
  required DateTime start,
  required DateTime end,
  required Duration deep,
  required Duration light,
  required Duration rem,
  required Duration awake,
  required List<(DateTime, double)> hrv,
  required List<(DateTime, double)> stress,
}) {
  final n = (end.difference(start).inSeconds / _step.inSeconds).ceil();
  if (n < 6 || (hrv.length < 3 && stress.length < 3)) return const [];
  if (deep + rem + light + awake == Duration.zero) return const [];

  final times = [for (var i = 0; i < n; i++) start.add(_step * i + _step ~/ 2)];
  final h = _fill([for (final t in times) _near(hrv, t, 10)]);
  final s = _fill([for (final t in times) _near(stress, t, 5)]);
  final zs = _z(_detrend(_smooth(s ?? List.filled(n, 0))));
  final zh = _z(_detrend(_smooth(h ?? List.filled(n, 0))));
  final hv = h ?? List.filled(n, 0.0);
  final change = _z([
    for (var i = 0; i < n; i++) i == 0 ? 0 : (hv[i] - hv[i - 1]).abs(),
  ]);

  // Steps per stage, matching the watch's totals; light takes the rest.
  int steps(Duration d) => (d.inSeconds / _step.inSeconds).round();
  final target = {
    'awake': steps(awake),
    'deep': steps(deep),
    'rem': steps(rem),
  };
  var used = target.values.fold(0, (a, b) => a + b);
  if (used > n) {
    // Rounding over a short night: trim deep, then REM.
    for (final k in ['deep', 'rem', 'awake']) {
      final cut = math.min(target[k]!, used - n);
      target[k] = target[k]! - cut;
      used -= cut;
    }
  }

  double score(int i, String stage) {
    final f = i / n;
    final cycle = math.cos(2 * math.pi * (i * _step.inMinutes) / 90);
    return switch (stage) {
      'deep' =>
        1.2 * (1 - f) -
            0.8 * f +
            0.4 * cycle -
            1.2 * zs[i] +
            0.3 * zh[i] -
            0.4 * change[i],
      'rem' =>
        -1.0 +
            1.6 * f -
            0.4 * cycle +
            1.0 * zs[i] -
            0.3 * zh[i] +
            0.4 * change[i],
      'awake' =>
        (i == 0 || i == n - 1 ? 1.5 : 0) +
            0.8 * math.max(0, change[i] - 1) +
            0.8 * math.max(0, zs[i] - 1.5),
      _ => 0,
    };
  }

  final path = List.filled(n, 'light');
  final free = {for (var i = 0; i < n; i++) i};
  for (final stage in ['awake', 'deep', 'rem']) {
    final best = free.toList()
      ..sort((a, b) => score(b, stage).compareTo(score(a, stage)));
    for (final i in best.take(target[stage]!)) {
      path[i] = stage;
      free.remove(i);
    }
  }

  // A single step between two of another stage swaps with the weakest
  // step of that stage elsewhere: fewer flickers, same totals.
  for (var pass = 0; pass < 3; pass++) {
    for (var i = 1; i < n - 1; i++) {
      final k = path[i], nb = path[i - 1];
      if (k == nb || k == 'awake' || path[i + 1] != nb) continue;
      final edges = [
        for (var j = 0; j < n; j++)
          if (path[j] == nb &&
              (j - i).abs() > 1 &&
              (j == 0 || j == n - 1 || path[j - 1] != nb || path[j + 1] != nb))
            j,
      ];
      if (edges.isEmpty) continue;
      edges.sort(
        (a, b) =>
            (score(b, k) - score(b, nb)).compareTo(score(a, k) - score(a, nb)),
      );
      path[i] = nb;
      path[edges.first] = k;
    }
  }

  final phases = <SleepPhase>[];
  for (var i = 0; i < n; i++) {
    final from = start.add(_step * i);
    final to = i == n - 1 ? end : start.add(_step * (i + 1));
    if (phases.isNotEmpty && phases.last.phase == path[i]) {
      phases[phases.length - 1] = SleepPhase(phases.last.start, to, path[i]);
    } else {
      phases.add(SleepPhase(from, to, path[i]));
    }
  }
  return phases;
}

double? _near(List<(DateTime, double)> series, DateTime t, int minutes) {
  double? best, value;
  for (final (at, v) in series) {
    final d = at.difference(t).inSeconds.abs() / 60;
    if (d <= minutes && (best == null || d < best)) {
      best = d;
      value = v;
    }
  }
  return value;
}

/// Gaps take the last value before them; null when there is none at all.
List<double>? _fill(List<double?> a) {
  final first = a.firstWhere((v) => v != null, orElse: () => null);
  if (first == null) return null;
  var last = first;
  return [for (final v in a) last = v ?? last];
}

List<double> _smooth(List<double> a, [int k = 1]) => [
  for (var i = 0; i < a.length; i++)
    _mean(a.sublist(math.max(0, i - k), math.min(a.length, i + k + 1))),
];

/// Minus the mean of the surrounding ~90 minutes: what counts is the change
/// within a cycle, not the drift over the night.
List<double> _detrend(List<double> a, [int k = 9]) => [
  for (var i = 0; i < a.length; i++)
    a[i] - _mean(a.sublist(math.max(0, i - k), math.min(a.length, i + k + 1))),
];

List<double> _z(List<double> a) {
  final mu = _mean(a);
  var sd = math.sqrt(_mean([for (final x in a) (x - mu) * (x - mu)]));
  if (sd == 0) sd = 1;
  return [for (final x in a) (x - mu) / sd];
}

double _mean(List<double> a) =>
    a.isEmpty ? 0 : a.reduce((x, y) => x + y) / a.length;
