import 'dart:math' as math;

import 'package:fjelia_service_api/fjelia_service_api.dart';

import '../models/ecg.dart';

/// App-side pre-analysis of a single-lead ECG for training: heart rate,
/// heart-rate variability and signal quality.
///
/// The signal is cut into 10 s windows and only windows that pass the quality
/// checks (contact, noise, plausible beat spacing) are analysed. Every figure
/// is left out (`na`) when the data behind it is too thin to be plausible.
/// The medical reading (rhythm, intervals, the beat's shape) is FjeliaPro's
/// and comes from the private package ([clinical]).
class EcgAnalysis {
  EcgAnalysis._({
    required this.sampleRateHz,
    required this.durationSeconds,
    required this.analysedSeconds,
    required this.windows,
    required this.usableWindows,
    required this.excluded,
    required this.blocks,
    required this.beats,
    required this.heartRate,
    required this.clinical,
  });

  final double sampleRateHz, durationSeconds, analysedSeconds;
  final int windows, usableWindows;

  /// Why windows were left out, e.g. {'noise': 2, 'no contact': 1}.
  final Map<String, int> excluded;

  /// Five-minute blocks (at most 12) with heart rate and signal quality.
  final List<EcgBlock> blocks;

  final int beats;
  final EcgHeartRate? heartRate;

  /// The medical reading, when it was asked for and this build has it.
  final EcgClinicalReading? clinical;

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

  /// The coach's context for training only: heart rate, heart-rate
  /// variability and signal quality, per 5-minute block on long recordings.
  /// Nothing about rhythm patterns, extra beats, pauses, intervals or the
  /// waveform: reading those is FjeliaPro's medical reading ([clinical]).
  List<String> fitnessLines({
    required String device,
    required String source,
    required DateTime recordedAt,
    required bool linkedToWorkout,
  }) {
    final local = recordedAt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final r = heartRate;
    final lines = [
      '[ECG:Key,Quality:$quality,Analysed:${analysedSeconds.round()}s,'
          'TrainingViewOnly${r == null ? '' : ',HR:${r.hrMean}bpm,RMSSD:${_na(r.rmssd, 'ms')}'}]',
      '[ECG:Summary,Device:${_clean(device)},Source:${_clean(source)},'
          'Recorded:${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)},'
          'Situation:${linkedToWorkout ? 'linked to a workout (may be during or after exercise)' : 'not linked to a workout'},'
          'Duration:${durationSeconds.round()}s,'
          'Analysed:${analysedSeconds.round()}s in $usableWindows of $windows windows,'
          '${excluded.isEmpty ? '' : 'Excluded:${[for (final e in excluded.entries) '${e.value}x ${e.key}'].join(' ')},'}'
          'Quality:$quality,'
          'Use:training view only (heart rate, HRV, signal quality); no medical reading]',
    ];
    if (!usable || r == null) return lines;
    lines.add(
      '[ECG:Training,HRmean:${r.hrMean}bpm,HRmin5beat:${r.hrMin}bpm,'
      'HRmax5beat:${r.hrMax}bpm,RMSSD:${_na(r.rmssd, 'ms')},'
      'SDNN:${_na(r.sdnn, 'ms')},pNN50:${_na(r.pnn50, '%')}]',
    );
    if (blocks.length > 1) {
      lines.add('[ECG:Timeline,Blocks:${blocks.length}]');
      for (final b in blocks) {
        lines.add('[ECG:Block,${b.toTrainingLine()}]');
      }
      // Heart-rate phases and signal quality, as on long recordings before;
      // the anomaly timeline is a rhythm reading and stays out.
      if (_phaseSummary(blocks) case final p?) lines.add('[ECG:Phases,$p]');
      if (_qualityMap(blocks) case final q?) lines.add('[ECG:QualityMap,$q]');
    }
    return lines;
  }

  /// Identifies phases (resting, exercise, recovery) from HR trends.
  String? _phaseSummary(List<EcgBlock> blocks) {
    if (blocks.length < 3) return null;

    final phases = <String>[];
    var phase = 'resting';
    var phaseStart = blocks.first.startSeconds.round();

    for (var i = 1; i < blocks.length; i++) {
      final prev = blocks[i - 1], curr = blocks[i];

      // Detect phase transitions based on HR changes.
      if (prev.hrMean > 0 && curr.hrMean > 0) {
        final hrChange = (curr.hrMean - prev.hrMean).abs();

        if (hrChange > 15 && curr.hrMean > prev.hrMean) {
          // HR increased significantly — transition to exercise.
          phases.add('resting ${phaseStart}–${prev.startSeconds.round()}s');
          phase = 'exercise';
          phaseStart = curr.startSeconds.round();
        } else if (hrChange > 15 && curr.hrMean < prev.hrMean) {
          // HR decreased significantly — transition to recovery.
          phases.add('exercise ${phaseStart}–${prev.startSeconds.round()}s');
          phase = 'recovery';
          phaseStart = curr.startSeconds.round();
        }
      }
    }

    // Close the last phase.
    phases.add('$phase ${phaseStart}–${blocks.last.startSeconds.round()}s');

    return 'Phases: ${phases.join(", ")}';
  }

  /// Summarizes signal quality across the recording.
  String? _qualityMap(List<EcgBlock> blocks) {
    final qualityParts = <String>[];

    for (final b in blocks) {
      if (b.totalWindows == 0) {
        qualityParts.add(
          'Block ${b.startSeconds.round()}–${(b.startSeconds + b.durationSeconds).round()}s: no data',
        );
      } else {
        final ratio = b.usableWindows / b.totalWindows;
        if (ratio < .5) {
          qualityParts.add(
            'Block ${b.startSeconds.round()}–${(b.startSeconds + b.durationSeconds).round()}s: poor (${b.usableWindows}/${b.totalWindows})',
          );
        } else if (ratio < .8) {
          qualityParts.add(
            'Block ${b.startSeconds.round()}–${(b.startSeconds + b.durationSeconds).round()}s: fair (${b.usableWindows}/${b.totalWindows})',
          );
        }
      }
    }

    if (qualityParts.isEmpty) return 'All blocks good quality';
    return 'Quality issues: ${qualityParts.join("; ")}';
  }
}

class EcgBlock {
  const EcgBlock({
    required this.startSeconds,
    required this.durationSeconds,
    required this.hrMean,
    required this.hrMin,
    required this.hrMax,
    required this.beats,
    required this.usableWindows,
    required this.totalWindows,
  });

  /// Start of the block in seconds from recording start.
  final double startSeconds;
  final double durationSeconds;

  /// HR stats for this block (bpm).
  final int hrMean, hrMin, hrMax;

  /// Number of beats detected in this block.
  final int beats;

  /// Quality: usable windows vs total windows in this block.
  final int usableWindows, totalWindows;

  String get _quality => totalWindows == 0
      ? 'no data'
      : usableWindows / totalWindows >= .9
      ? 'good'
      : usableWindows / totalWindows >= .6
      ? 'fair'
      : 'poor';

  /// Heart rate and quality of the block, for the training view.
  String toTrainingLine() =>
      'Block ${startSeconds.round()}–${(startSeconds + durationSeconds).round()}s: '
      'HR~${hrMean}bpm ($hrMin–$hrMax), quality=$_quality';
}

/// Heart rate and heart-rate variability of the clean beats.
class EcgHeartRate {
  const EcgHeartRate({
    required this.rrCount,
    required this.hrMean,
    required this.hrMin,
    required this.hrMax,
    required this.sdnn,
    required this.rmssd,
    required this.pnn50,
  });
  final int rrCount;

  /// The range comes from five-interval means, so one beat does not set it.
  final int hrMean, hrMin, hrMax;

  /// Null when there are too few normal beats for HRV.
  final double? sdnn, rmssd, pnn50;
}

String _na(num? v, String unit) =>
    v == null ? 'na' : '${v is double ? v.toStringAsFixed(1) : v}$unit';

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
/// recordings run it in an isolate. With [clinical] the medical reading of
/// the private package is added; callers pass it only when it is available.
EcgAnalysis analyzeEcg(
  List<EcgChunk> chunks,
  double hz, {
  EcgClinicalRules? clinical,
}) {
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
    final clean = _highPass(s.raw, hz, .5);
    final step = (_windowSeconds * hz).round();
    for (var from = 0; from < s.raw.length; from += step) {
      final to = math.min(s.raw.length, from + step);
      if (to - from < hz * 5) break;
      final w = _Window(s, from, to);
      _rateWindow(w, hz, hf, clean);
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
  final rr = [
    for (final b in beats)
      if (b.rrBefore != null) b.rrBefore!,
  ];
  final enough = analysed >= 10 && beats.length >= 8 && rr.length >= 6;
  if (enough) {
    final medianRr = _median(rr);
    // Premature beats and beats of another shape stay out of the HRV, as in
    // any HRV analysis; the app does not report them.
    _markPremature(beats);
    _compareShapes(beats, medianRr, hz);
  }
  final reading = clinical?.read(
    EcgSignal(
      hz: hz,
      durationSeconds: duration,
      analysedSeconds: analysed,
      excluded: excluded,
      segments: [
        for (final s in segments)
          EcgSignalSegment(
            startSeconds: s.start,
            raw: s.raw,
            isoelectric: s.m,
            rPeaks: s.r,
          ),
      ],
      windows: [
        for (final w in windows)
          EcgSignalWindow(
            segment: segments.indexOf(w.segment),
            from: w.from,
            to: w.to,
            problem: w.problem,
            noiseRatio: w.noiseRatio,
          ),
      ],
      beats: [
        for (final b in beats)
          EcgSignalBeat(
            segment: segments.indexOf(b.segment),
            index: b.index,
            timeSeconds: b.time,
            rrBeforeMs: b.rrBefore,
            premature: b.premature,
            shapeCorrelation: b.corr,
          ),
      ],
    ),
  );
  return EcgAnalysis._(
    sampleRateHz: hz,
    durationSeconds: duration,
    analysedSeconds: analysed,
    windows: windows.length,
    usableWindows: usableWindows.length,
    excluded: excluded,
    blocks: _computeBlocks(beats, windows, hz),
    beats: beats.length,
    heartRate: enough ? _heartRate(beats) : null,
    clinical: reading,
  );
}

/// Each beat's QRS against the median beat of the beats at normal timing.
void _compareShapes(List<_Beat> beats, double medianRr, double hz) {
  final pre = math.min(0.35, 0.45 * medianRr / 1000),
      post = math.min(0.6, 0.7 * medianRr / 1000);
  final preN = (pre * hz).round(), postN = (post * hz).round();
  List<double>? cut(_Beat b) =>
      b.index - preN < 0 || b.index + postN >= b.segment.m.length
      ? null
      : b.segment.m.sublist(b.index - preN, b.index + postN + 1);
  final template = _medianBeat([
    for (final b in beats.where((b) => !b.premature).take(400))
      if (cut(b) != null) cut(b)!,
  ]);
  if (template == null) return;
  final qrsFrom = math.max(0, preN - (0.1 * hz).round()),
      qrsTo = math.min(preN + postN, preN + (0.15 * hz).round());
  for (final b in beats) {
    final c = cut(b);
    if (c != null) {
      b.corr = _correlation(
        c.sublist(qrsFrom, qrsTo + 1),
        template.sublist(qrsFrom, qrsTo + 1),
      );
    }
  }
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

void _rateWindow(
  _Window w,
  double hz,
  List<double> smooth,
  List<double> clean,
) {
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
  } else {
    // Thresholds from the bench (tools/ecg_bench in the private package):
    // MIT-BIH keeps 98 % of its windows, noise at 0 dB is mostly rejected.
    final similar = _beatSimilarity(clean, peaks, hz);
    final sqi = _zhaoQuality(clean.sublist(w.from, w.to), peaks, hz);
    // Electrode motion makes false detections that resemble each other: a
    // borderline spectrum then also needs clearly alike beats.
    if (similar.median < .85 ||
        similar.orphans > .25 ||
        sqi == _Sqi.unacceptable ||
        (sqi == _Sqi.barelyAcceptable && similar.median < .94)) {
      w.problem = 'noise';
    }
  }
}

/// How much the window's beats look like each other: per beat the best
/// correlation with another beat of the window (±250 ms around the R peak).
/// Extra beats of one shape still find their match, so a bundle branch block
/// or a bigeminy is not read as noise; noise and false detections match
/// nothing. Fewer than three beats in ten seconds count as noise.
({double median, double orphans}) _beatSimilarity(
  List<double> clean,
  List<int> peaks,
  double hz,
) {
  final half = (.25 * hz).round();
  final beats = [
    for (final p in peaks)
      if (p - half >= 0 && p + half < clean.length)
        clean.sublist(p - half, p + half),
  ];
  if (beats.length < 3) return (median: 0, orphans: 1);
  final best = <double>[];
  for (var i = 0; i < beats.length; i++) {
    var top = -1.0;
    for (var j = 0; j < beats.length; j++) {
      if (i != j) top = math.max(top, _correlation(beats[i], beats[j]));
    }
    best.add(top);
  }
  return (
    median: _median(best),
    orphans: best.where((c) => c < .8).length / best.length,
  );
}

enum _Sqi { excellent, barelyAcceptable, unacceptable }

/// Signal quality after Zhao and Zhang (2018), "simple" rules as in
/// NeuroKit2 (`ecg_quality`, method zhao2018; MIT licence): the QRS band's
/// share of the power (pSQI), the kurtosis (kSQI) and the share outside the
/// baseline band (basSQI) of a [clean] (0.5 Hz high-passed) window.
_Sqi _zhaoQuality(List<double> clean, List<int> peaks, double hz) {
  final power = _powerSpectrum(clean, hz);
  double band(double lo, double hi) {
    var sum = 0.0;
    for (final (f, p) in power) {
      if (f >= lo && f <= hi) sum += p;
    }
    return sum;
  }

  final total = band(0, 40), qrsBand = band(5, 40);
  final pSqi = qrsBand == 0 ? 0.0 : band(5, 15) / qrsBand;
  final basSqi = total == 0 ? 0.0 : 1 - band(0, 1) / total;
  final kSqi = _kurtosis(clean);
  // The fastest rate in the window picks the pSQI limits.
  var minRr = double.infinity;
  for (var k = 1; k < peaks.length; k++) {
    minRr = math.min(minRr, (peaks[k] - peaks[k - 1]) / hz);
  }
  final fast = minRr.isFinite && 60 / minRr >= 130;
  final (l1, l2, l3) = fast ? (.4, .7, .3) : (.5, .8, .4);
  // Unlike NeuroKit2, a pSQI above the band only counts as suspicious: it
  // comes from electrode motion, but also from the smooth QRS of a clean
  // 130 Hz chest-strap signal with some baseline wander (MIT-BIH 121, 202).
  final p = pSqi > l1 && pSqi < l2
      ? 2
      : pSqi > l3
      ? 1
      : 0;
  final k = kSqi > 5 ? 2 : 0;
  final b = basSqi >= .95
      ? 2
      : basSqi < .9
      ? 0
      : 1;
  final classes = [p, k, b];
  final optimal = classes.where((c) => c == 2).length;
  final suspicious = classes.where((c) => c == 1).length;
  final unqualified = classes.where((c) => c == 0).length;
  if (unqualified >= 2 || (unqualified == 1 && suspicious == 2)) {
    return _Sqi.unacceptable;
  }
  return optimal >= 2 && unqualified == 0
      ? _Sqi.excellent
      : _Sqi.barelyAcceptable;
}

/// Pearson's kurtosis (3 for a normal distribution).
double _kurtosis(List<double> x) {
  final n = x.length;
  if (n < 4) return 0;
  final mean = x.reduce((a, b) => a + b) / n;
  var m2 = 0.0, m4 = 0.0;
  for (final v in x) {
    final d = (v - mean) * (v - mean);
    m2 += d;
    m4 += d * d;
  }
  m2 /= n;
  m4 /= n;
  return m2 == 0 ? 0 : m4 / (m2 * m2);
}

/// One Hann-windowed periodogram of [x]: (frequency, power) per bin.
List<(double, double)> _powerSpectrum(List<double> x, double hz) {
  var n = 1;
  while (n < x.length) {
    n <<= 1;
  }
  final mean = x.reduce((a, b) => a + b) / x.length;
  final re = List<double>.filled(n, 0), im = List<double>.filled(n, 0);
  for (var i = 0; i < x.length; i++) {
    final w = .5 - .5 * math.cos(2 * math.pi * i / (x.length - 1));
    re[i] = (x[i] - mean) * w;
  }
  _fft(re, im);
  return [
    for (var k = 0; k <= n ~/ 2; k++)
      (k * hz / n, re[k] * re[k] + im[k] * im[k]),
  ];
}

/// In-place radix-2 FFT; the length must be a power of two.
void _fft(List<double> re, List<double> im) {
  final n = re.length;
  for (var i = 1, j = 0; i < n; i++) {
    var bit = n >> 1;
    for (; j & bit != 0; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      final r = re[i], m = im[i];
      re[i] = re[j];
      im[i] = im[j];
      re[j] = r;
      im[j] = m;
    }
  }
  for (var len = 2; len <= n; len <<= 1) {
    final angle = -2 * math.pi / len;
    for (var i = 0; i < n; i += len) {
      for (var k = 0; k < len ~/ 2; k++) {
        final c = math.cos(angle * k), sn = math.sin(angle * k);
        final a = i + k, b = a + len ~/ 2;
        final tr = re[b] * c - im[b] * sn, ti = re[b] * sn + im[b] * c;
        re[b] = re[a] - tr;
        im[b] = im[a] - ti;
        re[a] += tr;
        im[a] += ti;
      }
    }
  }
}

/// A 2nd-order Butterworth high-pass run forward and backward (zero phase,
/// 4th order in effect), like the 0.5 Hz cleaning step NeuroKit2 uses.
List<double> _highPass(List<double> x, double hz, double cutoff) {
  if (x.length < 3) return List.of(x);
  final k = math.tan(math.pi * cutoff / hz), q = math.sqrt2;
  final norm = 1 / (1 + k * q + k * k);
  final b0 = norm, b1 = -2 * norm, b2 = norm;
  final a1 = 2 * (k * k - 1) * norm, a2 = (1 - k * q + k * k) * norm;
  List<double> pass(List<double> v) {
    final out = List<double>.filled(v.length, 0);
    var x1 = v.first, x2 = v.first, y1 = 0.0, y2 = 0.0;
    for (var i = 0; i < v.length; i++) {
      final y = b0 * v[i] + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
      x2 = x1;
      x1 = v[i];
      y2 = y1;
      y1 = y;
      out[i] = y;
    }
    return out;
  }

  return pass(pass(x).reversed.toList()).reversed.toList();
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

EcgHeartRate _heartRate(List<_Beat> beats) {
  final rr = [
    for (final b in beats)
      if (b.rrBefore != null) b.rrBefore!,
  ];
  final mean = rr.reduce((a, b) => a + b) / rr.length;
  var lo = double.infinity, hi = 0.0;
  for (var k = 0; k + 5 <= rr.length; k++) {
    final m = rr.sublist(k, k + 5).reduce((a, b) => a + b) / 5;
    lo = math.min(lo, m);
    hi = math.max(hi, m);
  }
  if (hi == 0) lo = hi = mean;
  // Successive differences only between normal intervals that follow each
  // other.
  final nnDiffs = <double>[], nn = <double>[];
  for (var k = 1; k < beats.length; k++) {
    final a = beats[k - 1], b = beats[k];
    final normal = b.rrBefore != null && !b.premature && b.corr >= .9;
    if (normal) nn.add(b.rrBefore!);
    if (a.rrBefore == null || b.rrBefore == null) continue;
    if (normal && !a.premature && a.corr >= .9) {
      nnDiffs.add(b.rrBefore! - a.rrBefore!);
    }
  }
  final share = beats.where((b) => b.premature).length / beats.length;
  final hrv = nn.length >= 20 && nnDiffs.length >= 15 && share < .2;
  return EcgHeartRate(
    rrCount: rr.length,
    hrMean: (60000 / mean).round(),
    hrMin: (60000 / hi).round(),
    hrMax: (60000 / lo).round(),
    sdnn: hrv ? _std(nn) : null,
    rmssd: hrv
        ? math.sqrt(
            nnDiffs.fold<double>(0, (a, d) => a + d * d) / nnDiffs.length,
          )
        : null,
    pnn50: hrv
        ? nnDiffs.where((d) => d.abs() > 50).length / nnDiffs.length * 100
        : null,
  );
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

/// Heart rate and quality per 5-minute block, at most 12 so the coach's
/// context stays bounded.
List<EcgBlock> _computeBlocks(
  List<_Beat> beats,
  List<_Window> windows,
  double hz,
) {
  const blockSeconds = 300.0; // 5-minute blocks
  if (beats.isEmpty) return [];

  final duration = beats.last.time;
  final numBlocks = (duration / blockSeconds).ceil().clamp(1, 12);
  final actualBlockSeconds = duration / numBlocks;

  // Build a map from block index to list of beats in that block.
  final blocks = <int, List<_Beat>>{};
  for (var i = 0; i <= numBlocks; i++) blocks[i] = [];
  for (final b in beats) {
    final idx = (b.time / actualBlockSeconds).floor().clamp(0, numBlocks - 1);
    blocks[idx]!.add(b);
  }

  // Build a map from block index to list of windows in that block.
  final winBlocks = <int, List<_Window>>{};
  for (var i = 0; i <= numBlocks; i++) winBlocks[i] = [];
  for (final w in windows) {
    final startSec = w.segment.start + w.from / hz;
    final endSec = w.segment.start + w.to / hz;
    // A window belongs to the block containing its midpoint.
    final mid = (startSec + endSec) / 2;
    final idx = (mid / actualBlockSeconds).floor().clamp(0, numBlocks - 1);
    winBlocks[idx]!.add(w);
  }

  final result = <EcgBlock>[];
  for (var i = 0; i < numBlocks; i++) {
    final startSec = i * actualBlockSeconds;
    final blockBeats = blocks[i]!;

    // Compute HR stats from RR intervals within this block.
    final rrInBlock = <double>[];
    for (var k = 1; k < blockBeats.length; k++) {
      final a = blockBeats[k - 1], b = blockBeats[k];
      if (a.segment != b.segment) continue;
      final rr = (b.index - a.index) / hz * 1000;
      if (rr > 300 && rr < 2500) rrInBlock.add(rr);
    }

    int hrMean = 0, hrMin = 0, hrMax = 0;
    if (rrInBlock.isNotEmpty) {
      final meanRr = rrInBlock.reduce((a, b) => a + b) / rrInBlock.length;
      hrMean = (60000 / meanRr).round();
      // 5-beat rolling min/max for stability.
      var lo = double.infinity, hi = 0.0;
      for (var k = 0; k + 5 <= rrInBlock.length; k++) {
        final m = rrInBlock.sublist(k, k + 5).reduce((a, b) => a + b) / 5;
        lo = math.min(lo, m);
        hi = math.max(hi, m);
      }
      if (hi == 0) lo = hi = meanRr;
      hrMin = (60000 / hi).round();
      hrMax = (60000 / lo).round();
    }

    final blockWindows = winBlocks[i]!;
    final usable = blockWindows.where((w) => w.problem == null).length;

    result.add(
      EcgBlock(
        startSeconds: startSec,
        durationSeconds: actualBlockSeconds,
        hrMean: hrMean,
        hrMin: hrMin,
        hrMax: hrMax,
        beats: blockBeats.length,
        usableWindows: usable,
        totalWindows: blockWindows.length,
      ),
    );
  }

  return result;
}
