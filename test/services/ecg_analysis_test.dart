import 'dart:isolate';
import 'dart:math' as math;

import 'package:fjelia/models/chat_message.dart';
import 'package:fjelia/models/ecg.dart';
import 'package:fjelia/services/apple_coach_request.dart';
import 'package:fjelia/services/coach_tasks.dart';
import 'package:fjelia/services/ecg_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

const hz = 130.0;

double _g(double t, double at, double amp, double sigma) =>
    amp * math.exp(-math.pow(t - at, 2) / (2 * sigma * sigma));

/// One beat around its R peak at t = 0: P, Q, R, S and T as Gaussians.
double _beat(double t, {double width = 1, double st = 0}) =>
    _g(t, .13, st, .06) +
    _g(t, -.16, 120, .022) +
    _g(t, -.03 * width, -100, .01 * width) +
    _g(t, 0, 1200, .012 * width) +
    _g(t, .03 * width, -300, .012 * width) +
    _g(t, .28, 300, .045);

/// [rPeaks] in seconds; [noise] µV of white noise; [wide] marks R peaks whose
/// QRS is twice as wide (a different shape).
List<EcgChunk> _ecg(
  List<double> rPeaks,
  double seconds, {
  double noise = 0,
  Set<int> wide = const {},
  double flatFrom = double.infinity,
  double width = 1,
  double st = 0,
  int seed = 1,
}) {
  final random = math.Random(seed);
  final n = (seconds * hz).round();
  final values = List<num>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    final t = i / hz;
    if (t >= flatFrom) continue;
    var v = 40 * math.sin(2 * math.pi * .25 * t); // breathing baseline
    for (var k = 0; k < rPeaks.length; k++) {
      final d = t - rPeaks[k];
      if (d.abs() < .6) {
        v += _beat(d, width: wide.contains(k) ? 2.2 : width, st: st);
      }
    }
    v += noise * (random.nextDouble() * 2 - 1);
    values[i] = v.round();
  }
  // 73-sample frames like the H10.
  return [
    for (var i = 0; i < n; i += 73)
      EcgChunk(
        offsetUs: (i / hz * 1e6).round(),
        microvolts: values.sublist(i, math.min(n, i + 73)),
      ),
  ];
}

List<double> _regular(double seconds, double rr, {double start = .5}) => [
  for (var t = start; t < seconds - .6; t += rr) t,
];

void main() {
  test('regular sinus rhythm: rate, intervals and levels', () {
    final a = analyzeEcg(_ecg(_regular(60, 1.0), 60, noise: 10), hz);
    expect(a.quality, 'good');
    expect(a.analysedSeconds, greaterThanOrEqualTo(50));
    final r = a.rhythm!;
    expect(r.hrMean, inInclusiveRange(59, 61));
    expect(r.pattern, 'regular');
    expect(r.premature, 0);
    expect(r.pausesOver2s, 0);
    final m = a.morphology!;
    expect(m.polarity, 'positive');
    expect(m.rUv, inInclusiveRange(1000, 1300));
    expect(m.qrsMs, inInclusiveRange(60, 130));
    expect(m.prMs, isNotNull);
    expect(m.prMs, inInclusiveRange(110, 260));
    expect(m.tUv, greaterThan(150));
    expect(m.st60Uv!.abs(), lessThan(100));
    expect(m.qtMs, inInclusiveRange(330, 480));
    expect(a.raw!.microvolts.length, 1300);
    expect(a.raw!.rPeaks.length, inInclusiveRange(9, 11));
    expect(a.template!.microvolts, isNotEmpty);
    final lines = a.contextLines(
      device: 'Polar H10',
      source: 'Polar H10',
      recordedAt: DateTime(2026, 11, 5, 8),
      linkedToWorkout: false,
    );
    expect(lines.map((l) => l.substring(0, 10)), [
      '[ECG:Key,Q',
      '[ECG:Summa',
      '[ECG:Rhyth',
      '[ECG:Beat,',
      '[ECG:Templ',
      '[ECG:Raw,S',
    ]);
    expect(a.pacerSpikes, isNull);
  });

  test('a premature beat with a different shape is counted', () {
    final peaks = _regular(60, 1.0);
    // Beat 30 comes 400 ms early and is wide, then a compensatory pause.
    peaks[30] -= .4;
    final a = analyzeEcg(_ecg(peaks, 60, noise: 10, wide: {30}), hz);
    final r = a.rhythm!;
    expect(r.premature, 1);
    expect(r.prematureDifferentShape, 1);
    expect(a.morphology!.qrsMs, inInclusiveRange(60, 130));
  });

  test('random intervals read as irregular, not as premature beats', () {
    final random = math.Random(7);
    final peaks = <double>[];
    for (var t = .5; t < 59; t += .55 + random.nextDouble() * .5) {
      peaks.add(t);
    }
    final a = analyzeEcg(_ecg(peaks, 60, noise: 10), hz);
    expect(a.rhythm!.pattern, 'irregular');
  });

  test('a long pause is reported', () {
    final peaks = [
      ..._regular(30, 1.0),
      for (var t = 32.5; t < 59; t += 1.0) t,
    ];
    final a = analyzeEcg(_ecg(peaks, 60, noise: 10), hz);
    expect(a.rhythm!.pausesOver2s, 1);
    expect(a.rhythm!.longestRrMs, greaterThan(2400));
  });

  test('noisy and flat windows are left out', () {
    final clean = analyzeEcg(
      _ecg(_regular(60, 1.0), 60, noise: 10, flatFrom: 40),
      hz,
    );
    expect(clean.excluded['no contact'], 2);
    expect(clean.analysedSeconds, closeTo(40, 1));
    final noisy = analyzeEcg(_ecg(_regular(60, 1.0), 60, noise: 900), hz);
    expect(noisy.usable, isFalse);
    expect(noisy.quality, 'insufficient');
    final lines = noisy.contextLines(
      device: 'Polar H10',
      source: 'Polar H10',
      recordedAt: DateTime(2026, 11, 5),
      linkedToWorkout: false,
    );
    expect(lines, hasLength(2));
    expect(lines.first, startsWith('[ECG:Key,Quality:insufficient'));
  });

  test('ST elevation shows at J+60 ms', () {
    final a = analyzeEcg(_ecg(_regular(60, 1.0), 60, noise: 10, st: 250), hz);
    expect(a.morphology!.st60Uv, greaterThan(150));
  });

  test('a wide QRS in every beat is measured as wide', () {
    final a = analyzeEcg(
      _ecg(_regular(60, 1.0), 60, noise: 10, width: 2.2),
      hz,
    );
    expect(a.morphology!.qrsMs, greaterThanOrEqualTo(120));
  });

  test('a regular fast rhythm reads as regular at 120 bpm', () {
    final a = analyzeEcg(_ecg(_regular(60, .5), 60, noise: 10), hz);
    expect(a.rhythm!.hrMean, inInclusiveRange(118, 122));
    expect(a.rhythm!.pattern, 'regular');
    expect(a.rhythm!.secondsOver100, greaterThan(50));
  });

  test('a five-minute recording fits the coach context', () {
    final a = analyzeEcg(_ecg(_regular(300, .9), 300, noise: 10), hz);
    final context = a
        .contextLines(
          device: 'Polar H10',
          source: 'Polar H10',
          recordedAt: DateTime(2026, 11, 5, 8),
          linkedToWorkout: true,
        )
        .join('\n');
    expect(coachTaskFor(context), CoachTask.ecg);
    // Raw excerpt plus template stay a few thousand tokens for the cloud.
    expect(context.length, lessThan(12000));
    final apple = AppleCoachRequest.build([
      const ChatMessage(text: 'What does my ECG show?', isUser: true),
    ], context);
    expect(apple.inputBytes, lessThanOrEqualTo(3000));
    expect(apple.prompt, contains('QTcF'));
    expect(apple.prompt, isNot(contains('uV as recorded')));
  });

  test('runs in an isolate and the result comes back', () async {
    final chunks = _ecg(_regular(30, 1.0), 30, noise: 10);
    final a = await Isolate.run(() => analyzeEcg(chunks, hz));
    expect(a.rhythm!.hrMean, inInclusiveRange(59, 61));
  });

  test('too short a recording is not interpreted', () {
    final a = analyzeEcg(_ecg(_regular(6, 1.0), 6), hz);
    expect(a.usable, isFalse);
    expect(a.rhythm, isNull);
  });
}
