import 'dart:isolate';
import 'dart:math' as math;

import 'package:fjelia/models/chat_message.dart';
import 'package:fjelia/models/ecg.dart';
import 'package:fjelia/services/apple_coach_request.dart';
import 'package:fjelia/services/coach_tasks.dart';
import 'package:fjelia/services/ecg_analysis.dart';
import 'package:fjelia_service/fjelia_service.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
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

/// FjeliaPro's medical reading, from the private package.
EcgAnalysis _read(List<EcgChunk> chunks) =>
    analyzeEcg(chunks, hz, clinical: createEcgClinicalRules());

List<String> _lines(EcgAnalysis a, {int seconds = 60, bool linked = false}) =>
    a.clinical!.lines(
      EcgRecordingMeta(
        device: 'Polar H10',
        source: 'Polar H10',
        recordedAt: DateTime(2026, 11, 5, 8),
        durationMs: seconds * 1000,
        linkedToWorkout: linked,
      ),
    );

/// The number after [key] in the reading's lines ("QRS:96ms" → 96).
int? _figure(List<String> lines, String key) {
  final m = RegExp(
    '[\\[,]${RegExp.escape(key)}:([+-]?\\d+)',
  ).firstMatch(lines.join('\n'));
  return m == null ? null : int.parse(m[1]!);
}

String? _text(List<String> lines, String key) => RegExp(
  '[\\[,]${RegExp.escape(key)}:([^,\\]]+)',
).firstMatch(lines.join('\n'))?[1];

void main() {
  group('FjeliaPro medical reading', skip: !hasServicePackage, () {
    test('regular sinus rhythm: rate, intervals and levels', () {
      final a = _read(_ecg(_regular(60, 1.0), 60, noise: 10));
      expect(a.quality, 'good');
      expect(a.analysedSeconds, greaterThanOrEqualTo(50));
      final lines = _lines(a);
      expect(_figure(lines, 'HRmean'), inInclusiveRange(59, 61));
      expect(_text(lines, 'Pattern'), 'regular');
      expect(_figure(lines, 'PrematureBeats'), 0);
      expect(_figure(lines, 'Pauses>2s'), 0);
      expect(_text(lines, 'QRSpolarity'), 'positive');
      expect(_figure(lines, 'R'), inInclusiveRange(1000, 1300));
      expect(_figure(lines, 'QRS'), inInclusiveRange(60, 130));
      expect(_figure(lines, 'PR'), inInclusiveRange(110, 260));
      expect(_text(lines, 'T'), contains('upright'));
      expect(_figure(lines, 'STatJ+60ms')!.abs(), lessThan(100));
      expect(_figure(lines, 'QT'), inInclusiveRange(330, 480));
      final raw = lines.singleWhere((l) => l.startsWith('[ECG:Raw'));
      expect(raw.split('uV as recorded:').last.split(' '), hasLength(1300));
      expect(lines.map((l) => l.substring(0, 10)), [
        '[ECG:Key,Q',
        '[ECG:Summa',
        '[ECG:Rhyth',
        '[ECG:Beat,',
        '[ECG:Templ',
        '[ECG:Raw,S',
      ]);
      expect(_text(lines, 'PacerSpikes'), 'not assessable below 500Hz');
    });

    // A strap worn upside down records the mirror image; the reading says so
    // and measures the beat flipped back.
    test('an inverted lead is recognised and corrected', () {
      final upright = _lines(_read(_ecg(_regular(60, 1.0), 60, noise: 10)));
      final flipped = _lines(
        _read([
          for (final c in _ecg(_regular(60, 1.0), 60, noise: 10))
            EcgChunk(
              offsetUs: c.offsetUs,
              microvolts: [for (final v in c.microvolts) -v],
            ),
        ]),
      );
      expect(_text(flipped, 'QRSpolarity'), 'negative as recorded');
      expect(_text(flipped, 'Orientation'), startsWith('inverted lead'));
      expect(_figure(flipped, 'R'), closeTo(_figure(upright, 'R')!, 30));
      expect(_text(flipped, 'T'), contains('upright'));
      expect(_text(upright, 'Orientation'), isNull);
    });

    test('a premature beat with a different shape is counted', () {
      final peaks = _regular(60, 1.0);
      // Beat 30 comes 400 ms early and is wide, then a compensatory pause.
      peaks[30] -= .4;
      final lines = _lines(_read(_ecg(peaks, 60, noise: 10, wide: {30})));
      expect(_figure(lines, 'PrematureBeats'), 1);
      expect(_text(lines, 'PrematureBeats'), contains('different QRS shape:1'));
      expect(_figure(lines, 'QRS'), inInclusiveRange(60, 130));
    });

    test('random intervals read as irregular, not as premature beats', () {
      final random = math.Random(7);
      final peaks = <double>[];
      for (var t = .5; t < 59; t += .55 + random.nextDouble() * .5) {
        peaks.add(t);
      }
      final lines = _lines(_read(_ecg(peaks, 60, noise: 10)));
      expect(_text(lines, 'Pattern'), 'irregular');
    });

    test('a long pause is reported', () {
      final peaks = [
        ..._regular(30, 1.0),
        for (var t = 32.5; t < 59; t += 1.0) t,
      ];
      final lines = _lines(_read(_ecg(peaks, 60, noise: 10)));
      expect(_figure(lines, 'Pauses>2s'), 1);
      expect(_figure(lines, 'LongestRR'), greaterThan(2400));
    });

    test('an unusable recording gets only its key and summary', () {
      final noisy = _read(_ecg(_regular(60, 1.0), 60, noise: 900));
      final lines = _lines(noisy);
      expect(lines, hasLength(2));
      expect(lines.first, startsWith('[ECG:Key,Quality:insufficient'));
    });

    test('ST elevation shows at J+60 ms', () {
      final lines = _lines(
        _read(_ecg(_regular(60, 1.0), 60, noise: 10, st: 250)),
      );
      expect(_figure(lines, 'STatJ+60ms'), greaterThan(150));
    });

    test('a wide QRS in every beat is measured as wide', () {
      final lines = _lines(
        _read(_ecg(_regular(60, 1.0), 60, noise: 10, width: 2.2)),
      );
      expect(_figure(lines, 'QRS'), greaterThanOrEqualTo(120));
    });

    test('a regular fast rhythm reads as regular at 120 bpm', () {
      final lines = _lines(_read(_ecg(_regular(60, .5), 60, noise: 10)));
      expect(_figure(lines, 'HRmean'), inInclusiveRange(118, 122));
      expect(_text(lines, 'Pattern'), 'regular');
      expect(_figure(lines, 'TimeOver100bpm'), greaterThan(50));
    });

    test('a five-minute recording fits the coach context', () {
      final a = _read(_ecg(_regular(300, .9), 300, noise: 10));
      final context = _lines(a, seconds: 300, linked: true).join('\n');
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

    test('the timeline of a long recording places its premature beat', () {
      final peaks = _regular(660, 1.0);
      peaks[30] -= .4;
      final lines = _lines(
        _read(_ecg(peaks, 660, noise: 10, wide: {30})),
        seconds: 660,
      );
      expect(_figure(lines, 'PrematureBeats'), 1);
      final blocks = [
        for (final l in lines)
          if (l.startsWith('[ECG:Block,')) l,
      ];
      expect(blocks.first, contains('1 premature'));
      expect(blocks.skip(1).any((b) => b.contains('premature')), isFalse);
      expect(lines, contains(startsWith('[ECG:Anomalies,')));
    });

    test('runs in the analysis isolate', () async {
      final chunks = _ecg(_regular(30, 1.0), 30, noise: 10);
      final rules = createEcgClinicalRules();
      final a = await Isolate.run(
        () => analyzeEcg(chunks, hz, clinical: rules),
      );
      expect(
        _figure(_lines(a, seconds: 30), 'HRmean'),
        inInclusiveRange(59, 61),
      );
    });

    test('the rhythm line names what was seen, not a condition', () {
      final rules = createEcgClinicalRules();
      final a = analyzeEcg(
        _ecg(_regular(30, 1.0), 30, noise: 10),
        hz,
        clinical: rules,
      );
      expect(_text(_lines(a, seconds: 30), 'IrregularWithoutP'), 'none');
      expect(_lines(a, seconds: 30).join(), isNot(contains('PossibleAF')));
    });
  });

  test('without the reading the analysis has only the training figures', () {
    final a = analyzeEcg(_ecg(_regular(60, 1.0), 60, noise: 10), hz);
    expect(a.clinical, isNull);
    expect(a.heartRate!.hrMean, inInclusiveRange(59, 61));
    expect(a.heartRate!.rmssd, isNotNull);
  });

  // The quality gate compares the beats of a window with each other: extra
  // beats of one shape and a wide QRS in every beat are not noise.
  test('a bigeminy and a wide QRS pass the quality gate', () {
    final peaks = _regular(60, .8);
    final bigeminy = analyzeEcg(
      _ecg(
        peaks,
        60,
        noise: 10,
        wide: {for (var k = 1; k < peaks.length; k += 2) k},
      ),
      hz,
    );
    expect(bigeminy.excluded['noise'], isNull);
    final wide = analyzeEcg(
      _ecg(_regular(60, 1.0), 60, noise: 10, width: 2.2),
      hz,
    );
    expect(wide.excluded['noise'], isNull);
    expect(wide.quality, 'good');
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
  });

  test('the training view says nothing medical', () {
    final peaks = _regular(660, 1.0);
    peaks[30] -= .4;
    final a = analyzeEcg(_ecg(peaks, 660, noise: 10, wide: {30}), hz);
    final context = a
        .fitnessLines(
          device: 'Polar H10',
          source: 'Polar H10',
          recordedAt: DateTime(2026, 11, 5, 8),
          linkedToWorkout: false,
        )
        .join('\n');
    // Still an ECG chat, with heart rate and HRV per block.
    expect(coachTaskFor(context), CoachTask.ecg);
    expect(context, contains('RMSSD'));
    expect(context, contains('[ECG:Block'));
    for (final medical in [
      'premature',
      'Premature',
      'Pause',
      'QRS',
      'QTc',
      'PR:',
      'ST',
      'Pattern',
      'Irregular',
      'Pacer',
      'Template',
      'uV',
    ]) {
      expect(context, isNot(contains(medical)), reason: medical);
    }
    // Without the private rules the coach reads the ECG for training only.
    expect(ecgClinicalMode, isFalse);
    expect(coachEcgRules, contains('TRAINING VIEW'));
    expect(coachEcgRules, isNot(contains('AV block')));
    expect(coachTaskTemplateShort(CoachTask.ecg), isNot(contains('pattern')));
  });

  test('runs in an isolate and the result comes back', () async {
    final chunks = _ecg(_regular(30, 1.0), 30, noise: 10);
    final a = await Isolate.run(() => analyzeEcg(chunks, hz));
    expect(a.heartRate!.hrMean, inInclusiveRange(59, 61));
  });

  test('too short a recording is not interpreted', () {
    final a = analyzeEcg(_ecg(_regular(6, 1.0), 6), hz);
    expect(a.usable, isFalse);
    expect(a.heartRate, isNull);
  });
}
