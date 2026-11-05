import 'dart:math' as math;

import '../models/garmin_data.dart';

/// Length of one step of the estimate.
const _step = Duration(minutes: 5);

/// Length of one sleep cycle: light, deep, light, REM.
const _cycleMinutes = 90;

/// An estimated stage timeline for a night whose watch gives only the stage
/// totals (COROS), built from the HRV and stress it measured overnight and,
/// when another device recorded it, the night's heart rate.
///
/// The totals stay the watch's: only *when* each stage happened is
/// estimated. The night is laid out in cycles of about 90 minutes. Deep
/// sleep comes early in a cycle and shrinks from cycle to cycle, REM closes
/// a cycle and grows. Within a cycle REM goes where HRV dips and stress (and
/// heart rate) rise against their surroundings; with a heart rate, deep
/// sleep goes where it is lowest. Checked against two nights of COROS,
/// Garmin and Polar: it agrees with each about as well as those watches
/// agree with each other, which is not much. Empty when there is too little
/// to go on.
List<SleepPhase> estimateSleepStages({
  required DateTime start,
  required DateTime end,
  required Duration deep,
  required Duration light,
  required Duration rem,
  required Duration awake,
  required List<(DateTime, double)> hrv,
  required List<(DateTime, double)> stress,
  List<List<(DateTime, double)>> heartRates = const [],
}) {
  final n = (end.difference(start).inSeconds / _step.inSeconds).ceil();
  if (n < 12 || (hrv.length < 3 && stress.length < 3)) return const [];
  if (deep + rem + light + awake == Duration.zero) return const [];

  final times = [for (var i = 0; i < n; i++) start.add(_step * i + _step ~/ 2)];
  List<double> signal(List<(DateTime, double)> series, int minutes) {
    final filled = _fill([
      for (final t in times) _mean(_near(series, t, minutes)),
    ]);
    return filled == null ? List.filled(n, 0.0) : _z(_detrend(filled));
  }

  final zh = signal(hrv, 6);
  final zs = signal(stress, 3);
  // Heart rate from every device that recorded the night, each against its
  // own level (their levels differ), averaged where several have a value.
  // Only when together they cover most of the night.
  final hrSum = List.filled(n, 0.0), hrCount = List.filled(n, 0);
  for (final series in heartRates) {
    final z = signal(series, 3);
    for (var i = 0; i < n; i++) {
      if (_near(series, times[i], 3).isEmpty) continue;
      hrSum[i] += z[i];
      hrCount[i]++;
    }
  }
  final withHr = hrCount.where((c) => c > 0).length >= n * 0.7;
  final zr = [
    for (var i = 0; i < n; i++)
      withHr && hrCount[i] > 0 ? hrSum[i] / hrCount[i] : 0.0,
  ];
  final remSignal = [
    for (var i = 0; i < n; i++)
      -zh[i] + 0.5 * zs[i] + (withHr ? 0.5 * zr[i] : 0),
  ];

  int steps(Duration d) => (d.inSeconds / _step.inSeconds).round();
  final awakeSteps = math.min(steps(awake), n ~/ 4);
  // Awake at sleep onset, as COROS draws it, then a short light lead-in;
  // the last minutes before waking are light.
  final from = awakeSteps + 2, to = n - 2;
  final span = to - from;
  var deepLeft = math.min(steps(deep), span ~/ 2);
  var remLeft = math.min(steps(rem), span - deepLeft);

  final path = List.filled(n, 'light');
  for (var i = 0; i < awakeSteps; i++) {
    path[i] = 'awake';
  }
  final cycles = math.max(1, (span * _step.inMinutes / _cycleMinutes).round());
  final bounds = [for (var k = 0; k <= cycles; k++) from + span * k ~/ cycles];
  final deepShare = _split(deepLeft, [
    for (var k = 0; k < cycles; k++) math.exp(-0.7 * k),
  ]);
  final remShare = _split(remLeft, [
    for (var k = 0; k < cycles; k++) (k == 0 ? 0.3 : 1) + 0.5 * k,
  ]);

  var deepCarry = 0, remCarry = 0;
  for (var k = 0; k < cycles; k++) {
    final s = bounds[k], e = bounds[k + 1], len = e - s;
    final d = math.min(deepShare[k] + deepCarry, math.max(0, len - 2));
    final r = math.min(remShare[k] + remCarry, math.max(0, len - 1 - d));
    deepCarry += deepShare[k] - d;
    remCarry += remShare[k] - r;
    deepLeft -= d;
    remLeft -= r;

    // REM: the window where HRV dips most, leaning to the cycle's end.
    if (r > 0) {
      var best = double.negativeInfinity, at = e - r;
      for (var st = s + 1; st <= e - r; st++) {
        var sum = 0.0;
        for (var i = st; i < st + r; i++) {
          sum += remSignal[i];
        }
        final pos = (st + r / 2 - s) / len;
        final score = sum / r + 0.5 * (pos - 0.5) * 2;
        if (score > best) {
          best = score;
          at = st;
        }
      }
      for (var i = at; i < at + r; i++) {
        path[i] = 'rem';
      }
    }

    // Deep: early in the cycle after a light lead-in; with a heart rate,
    // where it is lowest in the first part of the cycle.
    int first =
        s + (k == 0 ? 1 : math.max(1, math.min(3, (len - d - r) ~/ 3)).toInt());
    if (withHr && d > 0) {
      var best = double.negativeInfinity;
      for (var st = s + 1; st <= s + (len - d) ~/ 2; st++) {
        var sum = 0.0;
        for (var i = st; i < st + d; i++) {
          sum += -zr[i];
        }
        if (sum / d > best) {
          best = sum / d;
          first = st;
        }
      }
    }
    var placed = 0;
    for (var i = first; i < e && placed < d; i++) {
      if (path[i] == 'light') {
        path[i] = 'deep';
        placed++;
      }
    }
    deepCarry += d - placed;
  }
  // What did not fit: deep into the earliest light, REM into the latest,
  // so the totals stay the watch's.
  for (var i = from; i < to && deepCarry > 0; i++) {
    if (path[i] == 'light') {
      path[i] = 'deep';
      deepCarry--;
    }
  }
  for (var i = to - 1; i >= from && remCarry > 0; i--) {
    if (path[i] == 'light') {
      path[i] = 'rem';
      remCarry--;
    }
  }

  final phases = <SleepPhase>[];
  for (var i = 0; i < n; i++) {
    final a = start.add(_step * i);
    final b = i == n - 1 ? end : start.add(_step * (i + 1));
    if (phases.isNotEmpty && phases.last.phase == path[i]) {
      phases[phases.length - 1] = SleepPhase(phases.last.start, b, path[i]);
    } else {
      phases.add(SleepPhase(a, b, path[i]));
    }
  }
  return phases;
}

/// [total] steps in proportion to [weights], rounded so they add up.
List<int> _split(int total, List<double> weights) {
  final sum = weights.fold(0.0, (a, b) => a + b);
  final raw = [for (final w in weights) total * w / sum];
  final out = [for (final x in raw) x.floor()];
  final order = [for (var i = 0; i < raw.length; i++) i]
    ..sort((a, b) => (raw[b] - out[b]).compareTo(raw[a] - out[a]));
  for (final i in order.take(total - out.fold(0, (a, b) => a + b))) {
    out[i]++;
  }
  return out;
}

/// The values of [series] within [minutes] of [t].
List<double> _near(List<(DateTime, double)> series, DateTime t, int minutes) =>
    [
      for (final (at, v) in series)
        if (at.difference(t).inSeconds.abs() <= minutes * 60) v,
    ];

/// Gaps take the last value before them; null when there is none at all.
List<double>? _fill(List<double?> a) {
  final first = a.firstWhere((v) => v != null, orElse: () => null);
  if (first == null) return null;
  var last = first;
  return [for (final v in a) last = v ?? last];
}

/// Minus the mean of the surrounding ~90 minutes: what counts is the change
/// within a cycle, not the drift over the night.
List<double> _detrend(List<double> a, [int k = 9]) => [
  for (var i = 0; i < a.length; i++)
    a[i] -
        (_mean(a.sublist(math.max(0, i - k), math.min(a.length, i + k + 1))) ??
            0),
];

List<double> _z(List<double> a) {
  final mu = _mean(a) ?? 0;
  var sd = math.sqrt(_mean([for (final x in a) (x - mu) * (x - mu)]) ?? 0);
  if (sd == 0) sd = 1;
  return [for (final x in a) (x - mu) / sd];
}

double? _mean(List<double> a) =>
    a.isEmpty ? null : a.reduce((x, y) => x + y) / a.length;
