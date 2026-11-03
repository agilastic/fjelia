import 'dart:math' as math;

/// DFA alpha1 from beat-to-beat (RR) intervals recorded during exercise.
///
/// alpha1 describes how correlated the heartbeat pattern is. Around 1.0 at
/// easy intensity, it falls with effort: about 0.75 at the first ventilatory
/// (aerobic) threshold and about 0.5 at the second (Rogers et al. 2021,
/// Front. Physiol. 11:596567; Rogers et al. 2021, Front. Physiol. 12:668882).
/// The estimate needs a chest strap; optical wrist sensors don't record
/// usable RR intervals during exercise.

/// Window length and step of the rolling calculation (Rogers: 2 min).
const dfaWindow = Duration(minutes: 2);
const dfaStep = Duration(seconds: 30);

/// A window is skipped when more than this share of its beats are artifacts.
const dfaMaxArtifacts = 0.05;

/// alpha1 at the aerobic (HRVT1) and anaerobic (HRVT2) thresholds.
const hrvt1Alpha = 0.75;
const hrvt2Alpha = 0.5;

/// alpha1 of one window, with what the athlete did meanwhile.
class DfaWindow {
  const DfaWindow({
    required this.t,
    required this.alpha1,
    required this.heartRate,
    required this.artifacts,
    this.watts,
    this.speed,
  });

  /// Middle of the window, ms since epoch.
  final int t;
  final double alpha1, heartRate;

  /// Share of the window's beats removed as artifacts (0–1).
  final double artifacts;
  final double? watts, speed;

  Map<String, num> toJson() => {
    't': t,
    'a1': _round(alpha1, 3),
    'hr': _round(heartRate, 1),
    'art': _round(artifacts, 3),
    'w': ?(watts == null ? null : _round(watts!, 0)),
    'spd': ?(speed == null ? null : _round(speed!, 2)),
  };

  static DfaWindow? fromJson(Object? json) {
    if (json is! Map) return null;
    final t = json['t'], a1 = json['a1'], hr = json['hr'];
    if (t is! num || a1 is! num || hr is! num) return null;
    return DfaWindow(
      t: t.toInt(),
      alpha1: a1.toDouble(),
      heartRate: hr.toDouble(),
      artifacts: (json['art'] as num?)?.toDouble() ?? 0,
      watts: (json['w'] as num?)?.toDouble(),
      speed: (json['spd'] as num?)?.toDouble(),
    );
  }
}

/// Where alpha1 crossed a threshold, by heart rate and (when recorded)
/// power or speed.
class DfaThreshold {
  const DfaThreshold({required this.heartRate, this.watts, this.speed});
  final double heartRate;
  final double? watts, speed;
}

class DfaAlpha1Analysis {
  const DfaAlpha1Analysis({
    required this.windows,
    required this.rrCount,
    required this.artifacts,
    this.hrvt1,
    this.hrvt2,
  });

  final List<DfaWindow> windows;
  final int rrCount;

  /// Share of all beats removed as artifacts.
  final double artifacts;

  /// Null unless the session covered the threshold clearly enough.
  final DfaThreshold? hrvt1, hrvt2;

  /// Share of the analysed time spent above alpha1 0.75, i.e. below the
  /// aerobic threshold. Null without windows.
  double? get easyShare => windows.isEmpty
      ? null
      : windows.where((w) => w.alpha1 >= hrvt1Alpha).length / windows.length;
}

/// RR intervals with the time of each beat.
class RrSeries {
  const RrSeries(this.times, this.intervals);

  /// Beat times, ms since epoch, ascending.
  final List<int> times;

  /// Interval ending at each beat, ms.
  final List<double> intervals;

  /// Builds the beat times from consecutive intervals after [start].
  factory RrSeries.fromIntervals(DateTime start, List<double> intervals) {
    final times = <int>[];
    var t = start.millisecondsSinceEpoch.toDouble();
    for (final rr in intervals) {
      t += rr;
      times.add(t.round());
    }
    return RrSeries(times, intervals);
  }
}

/// Rolling DFA alpha1 over [rr]. [samples] are the activity's timed samples
/// ('t', 'w', 'spd') for power and speed per window.
DfaAlpha1Analysis analyseDfaAlpha1(
  RrSeries rr, {
  List<Map<String, num>> samples = const [],
}) {
  final n = rr.intervals.length;
  final artifact = _artifacts(rr.intervals);
  final windows = <DfaWindow>[];
  if (n > 0) {
    final windowMs = dfaWindow.inMilliseconds, stepMs = dfaStep.inMilliseconds;
    var from = 0;
    for (
      var start = rr.times.first;
      start + windowMs <= rr.times.last;
      start += stepMs
    ) {
      while (from < n && rr.times[from] < start) {
        from++;
      }
      final clean = <double>[];
      var total = 0, removed = 0;
      for (var i = from; i < n && rr.times[i] < start + windowMs; i++) {
        total++;
        if (artifact[i]) {
          removed++;
        } else {
          clean.add(rr.intervals[i]);
        }
      }
      if (total == 0 || removed / total > dfaMaxArtifacts) continue;
      if (clean.length < 100) continue;
      final a1 = dfaAlpha1(clean);
      if (a1 == null) continue;
      final mean = clean.reduce((a, b) => a + b) / clean.length;
      final end = start + windowMs;
      windows.add(
        DfaWindow(
          t: start + windowMs ~/ 2,
          alpha1: a1,
          heartRate: 60000 / mean,
          artifacts: removed / total,
          watts: _meanOf(samples, 'w', start, end),
          speed: _meanOf(samples, 'spd', start, end),
        ),
      );
    }
  }
  final removed = artifact.where((a) => a).length;
  return DfaAlpha1Analysis(
    windows: windows,
    rrCount: n,
    artifacts: n == 0 ? 0 : removed / n,
    hrvt1: dfaThreshold(windows, hrvt1Alpha),
    hrvt2: dfaThreshold(windows, hrvt2Alpha),
  );
}

/// Where the regression of alpha1 on heart rate reaches [alpha]. Requires
/// windows on both sides of it, a falling trend and a heart rate range of
/// at least 15 bpm; otherwise the session says nothing about the threshold.
DfaThreshold? dfaThreshold(List<DfaWindow> windows, double alpha) {
  if (windows.length < 6) return null;
  if (!windows.any((w) => w.alpha1 > alpha) ||
      !windows.any((w) => w.alpha1 < alpha)) {
    return null;
  }
  final hr = windows.map((w) => w.heartRate).toList();
  final lo = hr.reduce(math.min), hi = hr.reduce(math.max);
  if (hi - lo < 15) return null;
  final fit = _regression(hr, windows.map((w) => w.alpha1).toList());
  if (fit == null || fit.slope >= 0 || fit.r > -0.5) return null;
  final atHr = (alpha - fit.intercept) / fit.slope;
  if (atHr < lo - 5 || atHr > hi + 5) return null;

  double? along(double? Function(DfaWindow) read) {
    final points = [
      for (final w in windows)
        if (read(w) case final v? when v > 0) (v, w.alpha1),
    ];
    if (points.length < 6) return null;
    final f = _regression(
      points.map((p) => p.$1).toList(),
      points.map((p) => p.$2).toList(),
    );
    if (f == null || f.slope >= 0 || f.r > -0.5) return null;
    final at = (alpha - f.intercept) / f.slope;
    final values = points.map((p) => p.$1);
    final min = values.reduce(math.min), max = values.reduce(math.max);
    return at < min * .9 || at > max * 1.1 ? null : at;
  }

  return DfaThreshold(
    heartRate: atHr,
    watts: along((w) => w.watts),
    speed: along((w) => w.speed),
  );
}

/// Short-term scaling exponent (box sizes 4–16 beats) of [rr]; null for
/// fewer than 32 intervals.
double? dfaAlpha1(List<double> rr) {
  final n = rr.length;
  if (n < 32) return null;
  final mean = rr.reduce((a, b) => a + b) / n;
  final y = List<double>.filled(n, 0);
  var sum = 0.0;
  for (var i = 0; i < n; i++) {
    sum += rr[i] - mean;
    y[i] = sum;
  }
  final logN = <double>[], logF = <double>[];
  for (var box = 4; box <= 16; box++) {
    final boxes = n ~/ box;
    if (boxes < 2) break;
    var squares = 0.0;
    // Linear detrending in each box; x is 0..box-1.
    final xMean = (box - 1) / 2;
    var xVar = 0.0;
    for (var x = 0; x < box; x++) {
      xVar += (x - xMean) * (x - xMean);
    }
    for (var b = 0; b < boxes; b++) {
      final offset = b * box;
      var yMean = 0.0;
      for (var x = 0; x < box; x++) {
        yMean += y[offset + x];
      }
      yMean /= box;
      var cov = 0.0;
      for (var x = 0; x < box; x++) {
        cov += (x - xMean) * (y[offset + x] - yMean);
      }
      final slope = cov / xVar;
      for (var x = 0; x < box; x++) {
        final trend = yMean + slope * (x - xMean);
        final d = y[offset + x] - trend;
        squares += d * d;
      }
    }
    final f = math.sqrt(squares / (boxes * box));
    if (f <= 0) continue;
    logN.add(math.log(box));
    logF.add(math.log(f));
  }
  final fit = _regression(logN, logF);
  return fit?.slope;
}

/// Beats outside 300–2000 ms or more than 20 % away from the median of the
/// surrounding beats (missed or extra beats, contact loss).
List<bool> _artifacts(List<double> rr) {
  final n = rr.length;
  return [
    for (var i = 0; i < n; i++)
      rr[i] < 300 ||
          rr[i] > 2000 ||
          () {
            final from = math.max(0, i - 5), to = math.min(n, i + 6);
            final around = [
              for (var j = from; j < to; j++)
                if (j != i) rr[j],
            ]..sort();
            if (around.isEmpty) return false;
            final median = around[around.length ~/ 2];
            return (rr[i] - median).abs() > median * 0.2;
          }(),
  ];
}

double? _meanOf(List<Map<String, num>> samples, String key, int from, int to) {
  var sum = 0.0, count = 0;
  for (final s in samples) {
    final t = s['t'];
    if (t == null || t < from || t >= to) continue;
    final v = s[key];
    if (v == null || !v.isFinite) continue;
    sum += v;
    count++;
  }
  return count == 0 ? null : sum / count;
}

({double slope, double intercept, double r})? _regression(
  List<double> x,
  List<double> y,
) {
  final n = x.length;
  if (n < 2) return null;
  final mx = x.reduce((a, b) => a + b) / n, my = y.reduce((a, b) => a + b) / n;
  var sxx = 0.0, syy = 0.0, sxy = 0.0;
  for (var i = 0; i < n; i++) {
    sxx += (x[i] - mx) * (x[i] - mx);
    syy += (y[i] - my) * (y[i] - my);
    sxy += (x[i] - mx) * (y[i] - my);
  }
  if (sxx == 0) return null;
  final slope = sxy / sxx;
  return (
    slope: slope,
    intercept: my - slope * mx,
    r: syy == 0 ? 0 : sxy / math.sqrt(sxx * syy),
  );
}

double _round(double v, int digits) {
  final f = math.pow(10, digits);
  return (v * f).round() / f;
}
