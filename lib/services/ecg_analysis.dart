import 'dart:math' as math;

import '../models/ecg.dart';

/// App-side pre-analysis of a single-lead ECG for the coach.
///
/// The signal is cut into 10 s windows and only windows that pass the quality
/// checks (contact, noise, plausible beat spacing) are analysed. Every figure
/// is left out (`na`) when the data behind it is too thin to be plausible.
/// These are screening measurements of one chest-strap lead, not a diagnosis.
class EcgAnalysis {
  EcgAnalysis._({
    required this.sampleRateHz,
    required this.durationSeconds,
    required this.analysedSeconds,
    required this.windows,
    required this.usableWindows,
    required this.excluded,
    required this.beats,
    required this.rhythm,
    required this.morphology,
    required this.pacerSpikes,
    required this.raw,
    required this.template,
  });

  final double sampleRateHz, durationSeconds, analysedSeconds;
  final int windows, usableWindows;

  /// Why windows were left out, e.g. {'noise': 2, 'no contact': 1}.
  final Map<String, int> excluded;
  final int beats;
  final EcgRhythm? rhythm;
  final EcgMorphology? morphology;

  /// Null when the sample rate is too low to see pacemaker spikes.
  final int? pacerSpikes;
  final EcgExcerpt? raw;
  final EcgTemplate? template;

  /// At least 10 s of clean signal; below that nothing is interpreted.
  bool get usable => analysedSeconds >= 10 && beats >= 8;

  String get quality {
    if (!usable) return 'insufficient';
    final share = usableWindows / math.max(1, windows);
    return share >= .9
        ? 'good'
        : share >= .6
        ? 'fair'
        : 'poor';
  }

  /// Context lines for the coach, in English like the rest of its context.
  /// Lists inside a line are separated by spaces, not commas.
  List<String> contextLines({
    required String device,
    required String source,
    required DateTime recordedAt,
    required bool linkedToWorkout,
  }) {
    final hz = sampleRateHz;
    final local = recordedAt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final summary = [
      'Device:${_clean(device)}',
      'Source:${_clean(source)}',
      'Recorded:${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}',
      'Situation:${linkedToWorkout ? 'linked to a workout (may be during or after exercise)' : 'not linked to a workout'}',
      'Lead:single chest-strap lead (not a 12-lead ECG; electrode position not standardised)',
      'Rate:${hz.toStringAsFixed(hz % 1 == 0 ? 0 : 1)}Hz (${(1000 / hz).toStringAsFixed(1)}ms per sample)',
      'Duration:${durationSeconds.round()}s',
      'Analysed:${analysedSeconds.round()}s in $usableWindows of $windows windows',
      if (excluded.isNotEmpty)
        'Excluded:${[for (final e in excluded.entries) '${e.value}x ${e.key}'].join(' ')}',
      'Quality:$quality',
      'PacerSpikes:${pacerSpikes == null ? 'not assessable below 500Hz' : '$pacerSpikes'}',
    ];
    final r = rhythm, m = morphology;
    // The few figures a small on-device model can take, first.
    final key = [
      'Quality:$quality',
      'Analysed:${analysedSeconds.round()}s',
      'OneChestStrapLead',
      if (r != null) ...[
        'HR:${r.hrMean}bpm',
        'Pattern:${r.pattern.split(' ').first}',
        'Premature:${r.premature}',
        'Pauses>2s:${r.pausesOver2s}',
      ],
      if (m != null) ...[
        'QRS:${_na(m.qrsMs, 'ms')}',
        'PR:${_na(m.prMs, 'ms')}',
        'ST60:${_signed(m.st60Uv)}',
        'QTcF:${_na(m.qtcFridericia, 'ms')}',
      ],
    ];
    final lines = [
      '[ECG:Key,${key.join(',')}]',
      '[ECG:Summary,${summary.join(',')}]',
    ];
    if (!usable) return lines;
    if (r != null) lines.add('[ECG:Rhythm,${r.fields().join(',')}]');
    if (m != null) lines.add('[ECG:Beat,${m.fields().join(',')}]');
    if (template case final t?) {
      lines.add(
        '[ECG:Template,Beats:${t.beats},StartMs:${t.startMs},StepMs:${(1000 / t.hz).toStringAsFixed(1)},'
        'uV relative to PR baseline:${t.microvolts.join(' ')}]',
      );
    }
    if (raw case final e?) {
      lines.add(
        '[ECG:Raw,Start:${e.startSeconds.toStringAsFixed(1)}s,Hz:${e.hz.toStringAsFixed(e.hz % 1 == 0 ? 0 : 1)},'
        'Rpeaks s from start:${[for (final t in e.rPeaks) t.toStringAsFixed(2)].join(' ')},'
        'uV as recorded:${e.microvolts.join(' ')}]',
      );
    }
    return lines;
  }
}

class EcgRhythm {
  const EcgRhythm({
    required this.rrCount,
    required this.hrMean,
    required this.hrMin,
    required this.hrMax,
    required this.rrMedianMs,
    required this.longestRrMs,
    required this.sdnn,
    required this.rmssd,
    required this.pnn50,
    required this.irregularityPct,
    required this.pattern,
    required this.premature,
    required this.prematureSameShape,
    required this.prematureDifferentShape,
    required this.differentShapeRuns,
    required this.longestDifferentShapeRun,
    required this.pausesOver2s,
    required this.doubleRrPauses,
    required this.secondsOver100,
    required this.secondsUnder50,
  });
  final int rrCount;
  final int hrMean, hrMin, hrMax, rrMedianMs, longestRrMs;

  /// Null when there are too few normal beats for HRV.
  final double? sdnn, rmssd, pnn50;
  final double irregularityPct;

  /// regular, mildly variable, irregular, or na (recording too short).
  final String pattern;
  final int premature, prematureSameShape, prematureDifferentShape;
  final int differentShapeRuns, longestDifferentShapeRun;
  final int pausesOver2s, doubleRrPauses, secondsOver100, secondsUnder50;

  List<String> fields() => [
    'RR:$rrCount',
    'HRmean:${hrMean}bpm',
    'HRmin5beat:${hrMin}bpm',
    'HRmax5beat:${hrMax}bpm',
    'RRmedian:${rrMedianMs}ms',
    'LongestRR:${longestRrMs}ms',
    'SDNN:${_na(sdnn, 'ms')}',
    'RMSSD:${_na(rmssd, 'ms')}',
    'pNN50:${_na(pnn50, '%')}',
    'Irregularity:${irregularityPct.toStringAsFixed(1)}% (median successive RR change / mean RR)',
    'Pattern:$pattern',
    'PrematureBeats:$premature (same QRS shape:$prematureSameShape different QRS shape:$prematureDifferentShape)',
    'RunsOf3+DifferentShapeBeats:$differentShapeRuns${longestDifferentShapeRun > 0 ? ' (longest $longestDifferentShapeRun beats)' : ''}',
    'Pauses>2s:$pausesOver2s',
    'PausesAbout2xRR:$doubleRrPauses',
    'TimeOver100bpm:${secondsOver100}s',
    'TimeUnder50bpm:${secondsUnder50}s',
  ];
}

class EcgMorphology {
  const EcgMorphology({
    required this.baseline,
    required this.beats,
    required this.consistency,
    required this.polarity,
    required this.rUv,
    required this.sUv,
    required this.qrsMs,
    required this.pUv,
    required this.prMs,
    required this.st60Uv,
    required this.tUv,
    required this.qtMs,
    required this.qtcBazett,
    required this.qtcFridericia,
  });

  /// The PR-segment level the other levels are measured against.
  final double baseline;
  final int beats;
  final double consistency;
  final String polarity;
  final int rUv, sUv;
  final int? qrsMs, pUv, prMs, st60Uv, tUv, qtMs;
  final int? qtcBazett, qtcFridericia;

  List<String> fields() => [
    'TemplateBeats:$beats',
    'ShapeConsistency:${consistency.toStringAsFixed(2)}',
    'QRSpolarity:$polarity',
    'R:${rUv}uV',
    'S:${sUv}uV',
    'QRS:${_na(qrsMs, 'ms')}',
    'P:${pUv == null ? 'not identified' : '${pUv}uV'}',
    'PR:${_na(prMs, 'ms')}',
    'STatJ+60ms:${_signed(st60Uv)}',
    'T:${tUv == null
        ? 'na'
        : tUv!.abs() < 50
        ? 'flat (${tUv}uV)'
        : '${_signed(tUv)} ${tUv! > 0 ? 'upright' : 'inverted'}'}',
    'QT:${_na(qtMs, 'ms')}',
    'QTcBazett:${_na(qtcBazett, 'ms')}',
    'QTcFridericia:${_na(qtcFridericia, 'ms')}',
  ];
}

class EcgTemplate {
  const EcgTemplate(this.hz, this.startMs, this.beats, this.microvolts);
  final double hz;
  final int startMs, beats;
  final List<int> microvolts;
}

class EcgExcerpt {
  const EcgExcerpt(this.startSeconds, this.hz, this.rPeaks, this.microvolts);
  final double startSeconds, hz;
  final List<double> rPeaks;
  final List<int> microvolts;
}

String _na(num? v, String unit) =>
    v == null ? 'na' : '${v is double ? v.toStringAsFixed(1) : v}$unit';

String _signed(int? uv) => uv == null ? 'na' : '${uv >= 0 ? '+' : ''}${uv}uV';

String _clean(String s) => s.replaceAll(RegExp(r'[,:\[\]]'), ' ').trim();

const _windowSeconds = 10.0;

class _Segment {
  _Segment(this.start, this.raw);
  final double start;
  final List<double> raw;
  List<double> y = const [];
  List<int> r = const [];

  /// The recorded signal minus a line through the PR segments of the beats,
  /// for shapes and levels; [y] is high-pass filtered for detection only.
  List<double> m = const [];
}

class _Beat {
  _Beat(this.segment, this.index, this.time);
  final _Segment segment;
  final int index;
  final double time;
  double? rrBefore;
  bool premature = false;
  double corr = 1;
}

class _Window {
  _Window(this.segment, this.from, this.to);
  final _Segment segment;
  final int from, to;
  String? problem;
  double noiseRatio = 1;
}

/// Runs the whole pre-analysis. Pure and synchronous: callers with long
/// recordings run it in an isolate.
EcgAnalysis analyzeEcg(List<EcgChunk> chunks, double hz) {
  final segments = _segments(chunks, hz);
  final duration = segments.isEmpty
      ? 0.0
      : segments.last.start + segments.last.raw.length / hz;
  final windows = <_Window>[];
  final beats = <_Beat>[];
  for (final s in segments) {
    if (s.raw.length < hz * 3) continue;
    // Baseline: a 200 ms median removes QRS and P, a 600 ms median the T
    // wave. Unlike an average it is not pulled up by the R peak, so ST levels
    // stay where they are.
    final base = _movingMedian(
      _movingMedian(s.raw, (0.2 * hz).round(), hz),
      (0.6 * hz).round(),
      hz,
    );
    s.y = [for (var i = 0; i < s.raw.length; i++) s.raw[i] - base[i]];
    s.r = _detectR(s.y, hz);
    s.m = _isoelectric(s.raw, s.r, hz);
    final hf = _movingAverage(s.y, math.max(3, (0.02 * hz).round()));
    final step = (_windowSeconds * hz).round();
    for (var from = 0; from < s.raw.length; from += step) {
      final to = math.min(s.raw.length, from + step);
      if (to - from < hz * 5) break;
      final w = _Window(s, from, to);
      _rateWindow(w, hz, hf);
      windows.add(w);
    }
    for (final i in s.r) {
      final w = _windowOf(windows, s, i);
      if (w != null && w.problem == null) {
        beats.add(_Beat(s, i, s.start + i / hz));
      }
    }
  }
  final usableWindows = windows.where((w) => w.problem == null).toList();
  final analysed = usableWindows.fold<double>(
    0,
    (sum, w) => sum + (w.to - w.from) / hz,
  );
  final excluded = <String, int>{};
  for (final w in windows) {
    if (w.problem case final p?) excluded[p] = (excluded[p] ?? 0) + 1;
  }
  // RR only between neighbours in the same segment whose windows both passed.
  for (var k = 1; k < beats.length; k++) {
    final a = beats[k - 1], b = beats[k];
    if (a.segment != b.segment) continue;
    if (_windowOf(windows, b.segment, a.index) !=
            _windowOf(windows, b.segment, b.index) &&
        !_adjacentUsable(windows, b.segment, a.index, b.index)) {
      continue;
    }
    b.rrBefore = (b.index - a.index) / hz * 1000;
  }
  final pacer = hz >= 500 ? _pacerSpikes(segments, hz) : null;
  final rr = [
    for (final b in beats)
      if (b.rrBefore != null) b.rrBefore!,
  ];
  if (analysed < 10 || beats.length < 8 || rr.length < 6) {
    return EcgAnalysis._(
      sampleRateHz: hz,
      durationSeconds: duration,
      analysedSeconds: analysed,
      windows: windows.length,
      usableWindows: usableWindows.length,
      excluded: excluded,
      beats: beats.length,
      rhythm: null,
      morphology: null,
      pacerSpikes: pacer,
      raw: null,
      template: null,
    );
  }
  final medianRr = _median(rr);
  _markPremature(beats);
  final pre = math.min(0.35, 0.45 * medianRr / 1000),
      post = math.min(0.6, 0.7 * medianRr / 1000);
  final preN = (pre * hz).round(), postN = (post * hz).round();
  List<double>? cut(_Beat b) =>
      b.index - preN < 0 || b.index + postN >= b.segment.m.length
      ? null
      : b.segment.m.sublist(b.index - preN, b.index + postN + 1);
  // A first template from beats at normal timing, then each beat's QRS is
  // compared with it.
  final firstTemplate = _medianBeat([
    for (final b in beats.where((b) => !b.premature).take(400)) ?cut(b),
  ]);
  final qrsFrom = math.max(0, preN - (0.1 * hz).round()),
      qrsTo = math.min(preN + postN, preN + (0.15 * hz).round());
  if (firstTemplate != null) {
    for (final b in beats) {
      final c = cut(b);
      if (c != null) {
        b.corr = _correlation(
          c.sublist(qrsFrom, qrsTo + 1),
          firstTemplate.sublist(qrsFrom, qrsTo + 1),
        );
      }
    }
  }
  final rhythm = _rhythm(beats, hz);
  final normal = [
    for (final b in beats)
      if (!b.premature && b.corr >= .9) ?cut(b),
  ];
  final template = normal.length >= 8 ? _medianBeat(normal) : null;
  final morphology = template == null
      ? null
      : _morphology(
          template,
          preN,
          hz,
          medianRr,
          normal.length,
          consistency: _median([
            for (final b in beats)
              if (!b.premature) b.corr,
          ]),
          noise: _median([for (final w in usableWindows) w.noiseRatio]),
        );
  final best = usableWindows.reduce(
    (a, b) => b.noiseRatio < a.noiseRatio ? b : a,
  );
  return EcgAnalysis._(
    sampleRateHz: hz,
    durationSeconds: duration,
    analysedSeconds: analysed,
    windows: windows.length,
    usableWindows: usableWindows.length,
    excluded: excluded,
    beats: beats.length,
    rhythm: rhythm,
    morphology: morphology,
    pacerSpikes: pacer,
    raw: _excerpt(best, hz),
    template: template == null || morphology == null
        ? null
        : _templateOut(template, preN, hz, normal.length, morphology),
  );
}

List<_Segment> _segments(List<EcgChunk> chunks, double hz) {
  final sorted = [...chunks]..sort((a, b) => a.offsetUs.compareTo(b.offsetUs));
  final out = <_Segment>[];
  _Segment? current;
  for (final c in sorted) {
    if (c.microvolts.isEmpty) continue;
    final start = c.offsetUs / 1e6;
    final values = [for (final v in c.microvolts) v.toDouble()];
    if (current != null &&
        (start - (current.start + current.raw.length / hz)).abs() <= 1.5 / hz) {
      current.raw.addAll(values);
      continue;
    }
    current = _Segment(start, values);
    out.add(current);
  }
  return out;
}

/// Subtracts a line through the PR segment of each beat (50 to 80 ms before
/// its R peak), so ST and T levels are measured against the isoelectric line
/// and not against a filter that partly follows them.
List<double> _isoelectric(List<double> raw, List<int> r, double hz) {
  final n = raw.length;
  final knotAt = <int>[], knotValue = <double>[];
  final from = (0.08 * hz).round(), to = math.max(1, (0.05 * hz).round());
  for (final p in r) {
    if (p - from < 0) continue;
    knotAt.add(p - (from + to) ~/ 2);
    knotValue.add(_median(raw.sublist(p - from, p - to + 1)));
  }
  if (knotAt.isEmpty) return List.of(raw);
  final out = List<double>.filled(n, 0);
  var k = 0;
  for (var i = 0; i < n; i++) {
    while (k + 1 < knotAt.length && knotAt[k + 1] <= i) {
      k++;
    }
    final double base;
    if (i <= knotAt.first) {
      base = knotValue.first;
    } else if (k + 1 >= knotAt.length) {
      base = knotValue.last;
    } else {
      final a = knotAt[k], b = knotAt[k + 1];
      base =
          knotValue[k] + (knotValue[k + 1] - knotValue[k]) * (i - a) / (b - a);
    }
    out[i] = raw[i] - base;
  }
  return out;
}

/// A centred running median, evaluated about every 20 ms and interpolated in
/// between so long recordings at high sample rates stay fast.
List<double> _movingMedian(List<double> x, int width, double hz) {
  final n = x.length, half = width ~/ 2;
  if (width <= 1 || n == 0) return List.of(x);
  final stride = math.max(1, (hz / 50).round());
  final at = <int>[], values = <double>[];
  for (var i = 0; i < n; i += stride) {
    at.add(i);
    values.add(
      _median(x.sublist(math.max(0, i - half), math.min(n, i + half + 1))),
    );
  }
  if (at.last != n - 1) {
    at.add(n - 1);
    values.add(_median(x.sublist(math.max(0, n - 1 - half), n)));
  }
  final out = List<double>.filled(n, 0);
  for (var k = 0; k + 1 < at.length; k++) {
    final a = at[k], b = at[k + 1];
    for (var i = a; i <= b; i++) {
      out[i] = values[k] + (values[k + 1] - values[k]) * (i - a) / (b - a);
    }
  }
  if (at.length == 1) out[0] = values[0];
  return out;
}

List<double> _movingAverage(List<double> x, int width) {
  final n = x.length, half = width ~/ 2;
  if (width <= 1 || n == 0) return List.of(x);
  final prefix = List<double>.filled(n + 1, 0);
  for (var i = 0; i < n; i++) {
    prefix[i + 1] = prefix[i] + x[i];
  }
  final out = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    final a = math.max(0, i - half), b = math.min(n, i + half + 1);
    out[i] = (prefix[b] - prefix[a]) / (b - a);
  }
  return out;
}

/// QRS detection after Pan and Tompkins, simplified: squared slope, 150 ms
/// integration, adaptive threshold, 250 ms refractory time and a search back
/// for missed beats. The R peak is the extreme of the dominant polarity.
List<int> _detectR(List<double> y, double hz) {
  final n = y.length;
  final energy = List<double>.filled(n, 0);
  for (var i = 1; i < n - 1; i++) {
    final d = y[i + 1] - y[i - 1];
    energy[i] = d * d;
  }
  final integ = _movingAverage(energy, math.max(1, (0.15 * hz).round()));
  final refractory = (0.25 * hz).round();
  final learn = integ.sublist(0, math.min(n, (2 * hz).round()));
  var signal = learn.reduce(math.max) * .5,
      noise = learn.fold<double>(0, (a, b) => a + b) / learn.length * .5;
  final peaks = <int>[];
  for (var i = 1; i < n - 1; i++) {
    if (integ[i] < integ[i - 1] || integ[i] < integ[i + 1]) continue;
    final threshold = noise + .25 * (signal - noise);
    if (integ[i] <= threshold) {
      noise = .125 * integ[i] + .875 * noise;
    } else if (peaks.isEmpty || i - peaks.last >= refractory) {
      peaks.add(i);
      signal = .125 * integ[i] + .875 * signal;
    } else if (integ[i] > integ[peaks.last]) {
      peaks[peaks.length - 1] = i;
    }
  }
  // Search back in gaps over 1.66 times the usual spacing.
  if (peaks.length >= 4) {
    final spacing = _median([
      for (var k = 1; k < peaks.length; k++)
        (peaks[k] - peaks[k - 1]).toDouble(),
    ]);
    final level = _median([for (final p in peaks) integ[p]]) * .3;
    for (var k = peaks.length - 1; k > 0; k--) {
      if (peaks[k] - peaks[k - 1] <= 1.66 * spacing) continue;
      var best = -1;
      for (var i = peaks[k - 1] + refractory; i < peaks[k] - refractory; i++) {
        if (integ[i] > level && (best < 0 || integ[i] > integ[best])) best = i;
      }
      if (best >= 0) peaks.insert(k, best);
    }
  }
  if (peaks.isEmpty) return const [];
  final reach = math.max(1, (0.1 * hz).round());
  int extreme(int p, double sign) {
    var best = p;
    for (var i = math.max(0, p - reach); i <= math.min(n - 1, p + reach); i++) {
      if (sign * y[i] > sign * y[best]) best = i;
    }
    return best;
  }

  double absPeak(int p) {
    var best = 0.0;
    for (var i = math.max(0, p - reach); i <= math.min(n - 1, p + reach); i++) {
      if (y[i].abs() > best.abs()) best = y[i];
    }
    return best;
  }

  final sign = _median([for (final p in peaks) absPeak(p)]) >= 0 ? 1.0 : -1.0;
  final out = <int>[];
  for (final p in peaks) {
    final r = extreme(p, sign);
    if (out.isEmpty || r - out.last >= refractory) out.add(r);
  }
  return out;
}

void _rateWindow(_Window w, double hz, List<double> smooth) {
  final s = w.segment;
  final raw = s.raw.sublist(w.from, w.to);
  if (_std(raw) < 15) {
    w.problem = 'no contact';
    return;
  }
  final peaks = [
    for (final r in s.r)
      if (r >= w.from && r < w.to) r,
  ];
  if (peaks.length < 2) {
    w.problem = 'no beats detected';
    return;
  }
  final amplitude = _median([for (final r in peaks) s.y[r].abs()]);
  if (amplitude < 150) {
    w.problem = 'low amplitude';
    return;
  }
  // Noise: high-frequency residue outside the QRS complexes.
  final guard = (0.08 * hz).round();
  var sum = 0.0, count = 0, p = 0;
  for (var i = w.from; i < w.to; i++) {
    while (p < peaks.length && peaks[p] + guard < i) {
      p++;
    }
    if (p < peaks.length && (peaks[p] - i).abs() <= guard) continue;
    final d = s.y[i] - smooth[i];
    sum += d * d;
    count++;
  }
  w.noiseRatio = count == 0 ? 1 : math.sqrt(sum / count) / amplitude;
  final close = [
    for (var k = 1; k < peaks.length; k++)
      if ((peaks[k] - peaks[k - 1]) / hz < .25) 1,
  ].length;
  if (w.noiseRatio > .2) {
    w.problem = 'noise';
  } else if (close > .1 * peaks.length) {
    w.problem = 'implausible beat spacing';
  }
}

_Window? _windowOf(List<_Window> windows, _Segment s, int i) {
  for (final w in windows) {
    if (w.segment == s && i >= w.from && i < w.to) return w;
  }
  return null;
}

bool _adjacentUsable(List<_Window> windows, _Segment s, int a, int b) {
  final wa = _windowOf(windows, s, a), wb = _windowOf(windows, s, b);
  return wa != null &&
      wb != null &&
      wa.problem == null &&
      wb.problem == null &&
      wb.from == wa.to;
}

/// A beat is premature when it comes more than 20 % before the median of the
/// eight surrounding intervals.
void _markPremature(List<_Beat> beats) {
  for (var k = 0; k < beats.length; k++) {
    final rr = beats[k].rrBefore;
    if (rr == null) continue;
    final around = [
      for (
        var j = math.max(0, k - 4);
        j <= math.min(beats.length - 1, k + 4);
        j++
      )
        if (j != k && j != k + 1 && beats[j].rrBefore != null)
          beats[j].rrBefore!,
    ];
    if (around.length >= 4 && rr < .8 * _median(around)) {
      beats[k].premature = true;
    }
  }
}

EcgRhythm _rhythm(List<_Beat> beats, double hz) {
  final rr = [
    for (final b in beats)
      if (b.rrBefore != null) b.rrBefore!,
  ];
  final mean = rr.reduce((a, b) => a + b) / rr.length;
  final median = _median(rr);
  // HR range from five-interval means, so a single beat does not set it.
  var lo = double.infinity, hi = 0.0;
  for (var k = 0; k + 5 <= rr.length; k++) {
    final m = rr.sublist(k, k + 5).reduce((a, b) => a + b) / 5;
    lo = math.min(lo, m);
    hi = math.max(hi, m);
  }
  if (hi == 0) lo = hi = mean;
  // Successive differences only between intervals that follow each other.
  final diffs = <double>[], nnDiffs = <double>[], nn = <double>[];
  for (var k = 1; k < beats.length; k++) {
    final a = beats[k - 1], b = beats[k];
    final normal = b.rrBefore != null && !b.premature && b.corr >= .9;
    if (normal) nn.add(b.rrBefore!);
    if (a.rrBefore == null || b.rrBefore == null) continue;
    final d = b.rrBefore! - a.rrBefore!;
    diffs.add(d.abs());
    if (normal && !a.premature && a.corr >= .9) nnDiffs.add(d);
  }
  final premature = beats.where((b) => b.premature).toList();
  final prematureShare = premature.length / beats.length;
  final hrv = nn.length >= 20 && nnDiffs.length >= 15 && prematureShare < .2;
  final irregularity = diffs.isEmpty ? 0.0 : _median(diffs) / mean * 100;
  final seconds = rr.fold<double>(0, (a, b) => a + b) / 1000;
  final pattern = seconds < 30 || rr.length < 25
      ? 'na (under 30 s of clean signal)'
      : irregularity > 8 && prematureShare < .3
      ? 'irregular'
      : irregularity < 4
      ? 'regular'
      : 'mildly variable';
  // Runs of beats with a different QRS shape at a fast rate.
  var runs = 0, longest = 0, current = 0;
  for (final b in beats) {
    final different = b.corr < .8 && (b.premature || (b.rrBefore ?? 1e9) < 600);
    current = different ? current + 1 : 0;
    if (current == 3) runs++;
    longest = math.max(longest, current);
  }
  var doubled = 0;
  for (var k = 0; k < beats.length; k++) {
    final v = beats[k].rrBefore;
    if (v == null) continue;
    final around = [
      for (
        var j = math.max(0, k - 4);
        j <= math.min(beats.length - 1, k + 4);
        j++
      )
        if (j != k && beats[j].rrBefore != null) beats[j].rrBefore!,
    ];
    if (around.length >= 4) {
      final m = _median(around);
      if (v > 1.8 * m && v < 2.2 * m) doubled++;
    }
  }
  return EcgRhythm(
    rrCount: rr.length,
    hrMean: (60000 / mean).round(),
    hrMin: (60000 / hi).round(),
    hrMax: (60000 / lo).round(),
    rrMedianMs: median.round(),
    longestRrMs: rr.reduce(math.max).round(),
    sdnn: hrv ? _std(nn) : null,
    rmssd: hrv
        ? math.sqrt(
            nnDiffs.fold<double>(0, (a, d) => a + d * d) / nnDiffs.length,
          )
        : null,
    pnn50: hrv
        ? nnDiffs.where((d) => d.abs() > 50).length / nnDiffs.length * 100
        : null,
    irregularityPct: irregularity,
    pattern: pattern,
    premature: premature.length,
    prematureSameShape: premature.where((b) => b.corr >= .9).length,
    prematureDifferentShape: premature.where((b) => b.corr < .9).length,
    differentShapeRuns: runs,
    longestDifferentShapeRun: longest >= 3 ? longest : 0,
    pausesOver2s: rr.where((v) => v > 2000).length,
    doubleRrPauses: doubled,
    secondsOver100:
        (rr.where((v) => v < 600).fold<double>(0, (a, b) => a + b) / 1000)
            .round(),
    secondsUnder50:
        (rr.where((v) => v > 1200).fold<double>(0, (a, b) => a + b) / 1000)
            .round(),
  );
}

/// Intervals and levels of the median beat. Each one is only given when it
/// lands in a physiologically plausible range; otherwise it is na.
EcgMorphology _morphology(
  List<double> t,
  int r,
  double hz,
  double medianRr,
  int beats, {
  required double consistency,
  required double noise,
}) {
  int ms(num samples) => (samples / hz * 1000).round();
  int at(double seconds) => (seconds * hz).round();
  final n = t.length;
  final slope = [for (var i = 0; i < n - 1; i++) (t[i + 1] - t[i]).abs(), 0.0];
  var maxSlope = 0.0;
  for (var i = math.max(0, r - at(.08)); i < math.min(n, r + at(.1)); i++) {
    maxSlope = math.max(maxSlope, slope[i]);
  }
  final flatSlope = .12 * maxSlope;
  bool flat(int i) => i >= 1 && i < n - 1 && slope[i] < flatSlope;
  var onset = r;
  while (onset > 1 &&
      onset > r - at(.12) &&
      !(flat(onset - 1) && flat(onset - 2))) {
    onset--;
  }
  var offset = r + 1;
  while (offset < n - 2 &&
      offset < r + at(.16) &&
      !(flat(offset) && flat(offset + 1))) {
    offset++;
  }
  final qrs = ms(offset - onset);
  final qrsOk = qrs >= 40 && qrs <= 200;
  final baseFrom = math.max<int>(0, onset - math.max<int>(2, at(.04)));
  final baseline = onset - baseFrom < 2
      ? t[math.max(0, onset - 1)]
      : _median(t.sublist(baseFrom, onset));
  double level(int i) => t[i.clamp(0, n - 1)] - baseline;
  final rUv = level(r).round();
  // S: the deepest deflection against the R direction up to the J point.
  var sUv = 0.0;
  for (var i = r; i <= offset && i < n; i++) {
    final v = level(i);
    if (rUv >= 0 ? v < sUv : v > sUv) sUv = v;
  }
  final reliable = beats >= 8 && consistency >= .9 && noise < .12 && qrsOk;
  int? st60, tUv, qt, qtcB, qtcF, pUv, pr;
  if (reliable) {
    if (offset + at(.06) < n) st60 = level(offset + at(.06)).round();
    final tFrom = offset + at(.08), tTo = math.min(n - 1, offset + at(.45));
    if (tFrom < tTo) {
      var peak = tFrom;
      for (var i = tFrom; i <= tTo; i++) {
        if (level(i).abs() > level(peak).abs()) peak = i;
      }
      tUv = level(peak).round();
      if (tUv.abs() >= 50) {
        var end = peak;
        while (end < n - 1 && level(end).abs() > .15 * tUv.abs()) {
          end++;
        }
        final q = ms(end - onset);
        if (end < n - 1 && q >= 280 && q <= 600) {
          qt = q;
          final rrS = medianRr / 1000;
          qtcB = (q / math.sqrt(rrS)).round();
          qtcF = (q / math.pow(rrS, 1 / 3)).round();
        }
      }
    }
    final pFrom = math.max(1, onset - at(.25)), pTo = onset - at(.04);
    if (pTo - pFrom >= at(.08)) {
      var peak = pFrom;
      for (var i = pFrom; i <= pTo; i++) {
        if (level(i).abs() > level(peak).abs()) peak = i;
      }
      final amp = level(peak);
      if (amp.abs() >= 40 &&
          amp.abs() < .5 * rUv.abs() &&
          amp.abs() > 4 * noise * rUv.abs() / math.sqrt(beats)) {
        pUv = amp.round();
        var start = peak;
        while (start > 0 && level(start).abs() > .2 * amp.abs()) {
          start--;
        }
        final p = ms(onset - start);
        if (start > 1 && p >= 80 && p <= 400) pr = p;
      }
    }
  }
  return EcgMorphology(
    baseline: baseline,
    beats: beats,
    consistency: consistency,
    polarity: rUv >= 0 ? 'positive' : 'negative',
    rUv: rUv,
    sUv: sUv.round(),
    qrsMs: qrsOk ? qrs : null,
    pUv: pUv,
    prMs: pr,
    st60Uv: st60,
    tUv: tUv,
    qtMs: qt,
    qtcBazett: qtcB,
    qtcFridericia: qtcF,
  );
}

EcgTemplate _templateOut(
  List<double> t,
  int r,
  double hz,
  int beats,
  EcgMorphology m,
) {
  final base = m.baseline, step = _decimation(hz);
  final values = <int>[];
  for (var i = 0; i + step <= t.length; i += step) {
    values.add(
      (t.sublist(i, i + step).reduce((a, b) => a + b) / step - base).round(),
    );
  }
  return EcgTemplate(hz / step, -(r / hz * 1000).round(), beats, values);
}

EcgExcerpt _excerpt(_Window w, double hz) {
  final s = w.segment, step = _decimation(hz);
  final values = <int>[];
  for (var i = w.from; i + step <= w.to; i += step) {
    values.add(
      (s.raw.sublist(i, i + step).reduce((a, b) => a + b) / step).round(),
    );
  }
  return EcgExcerpt(s.start + w.from / hz, hz / step, [
    for (final r in s.r)
      if (r >= w.from && r < w.to) (r - w.from) / hz,
  ], values);
}

/// Keeps the text samples at no more than about 250 Hz.
int _decimation(double hz) => math.max(1, (hz / 250).ceil());

int _pacerSpikes(List<_Segment> segments, double hz) {
  var count = 0;
  final width = math.max(2, (0.004 * hz).round());
  for (final s in segments) {
    var last = -hz.toInt();
    for (var i = 1; i + width < s.raw.length; i++) {
      final jump = s.raw[i] - s.raw[i - 1];
      if (jump.abs() > 1500 &&
          (s.raw[i + width] - s.raw[i - 1]).abs() < jump.abs() * .3 &&
          i - last > .2 * hz) {
        count++;
        last = i;
      }
    }
  }
  return count;
}

List<double>? _medianBeat(List<List<double>> beats) {
  if (beats.isEmpty) return null;
  final length = beats.first.length;
  return [
    for (var i = 0; i < length; i++) _median([for (final b in beats) b[i]]),
  ];
}

double _correlation(List<double> a, List<double> b) {
  final n = math.min(a.length, b.length);
  if (n < 3) return 0;
  final ma = a.take(n).reduce((x, y) => x + y) / n,
      mb = b.take(n).reduce((x, y) => x + y) / n;
  var num = 0.0, da = 0.0, db = 0.0;
  for (var i = 0; i < n; i++) {
    num += (a[i] - ma) * (b[i] - mb);
    da += (a[i] - ma) * (a[i] - ma);
    db += (b[i] - mb) * (b[i] - mb);
  }
  return da == 0 || db == 0 ? 0 : num / math.sqrt(da * db);
}

double _median(List<double> values) {
  if (values.isEmpty) return 0;
  final s = [...values]..sort();
  final m = s.length ~/ 2;
  return s.length.isOdd ? s[m] : (s[m - 1] + s[m]) / 2;
}

double _std(List<double> values) {
  if (values.length < 2) return 0;
  final mean = values.reduce((a, b) => a + b) / values.length;
  return math.sqrt(
    values.fold<double>(0, (a, v) => a + (v - mean) * (v - mean)) /
        (values.length - 1),
  );
}
