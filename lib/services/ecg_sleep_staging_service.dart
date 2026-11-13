import 'dart:math' as math;
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import '../models/ecg.dart';
import '../models/ecg_sleep_staging.dart';

const ecgSleepModelAsset = 'assets/models/ecg_sleep_staging.onnx';
const _modelEpochSamples = 30 * 256;
const _outputRate = 256.0;

/// On-device inference for the ECG-only research model. The accelerometer
/// recording is intentionally not an input to this model.
class EcgSleepStagingService {
  final OnnxRuntime _runtime = OnnxRuntime();

  Future<EcgSleepStageEstimate> estimate({
    required List<EcgChunk> chunks,
    required double sampleRateHz,
    required DateTime recordedAt,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Sleep-stage estimation requires the on-device runtime.',
      );
    }
    if (sampleRateHz < 125 || sampleRateHz > 135) {
      throw const FormatException(
        'Sleep staging currently supports Polar H10 ECG at about 130 Hz.',
      );
    }
    final prepared = await Isolate.run(
      () => _prepareSegments(chunks, sampleRateHz),
    );
    if (prepared.isEmpty) {
      throw const FormatException(
        'No complete, continuous 30-second ECG sections were found.',
      );
    }

    final session = await _runtime.createSessionFromAsset(
      ecgSleepModelAsset,
      options: OrtSessionOptions(
        intraOpNumThreads: 2,
        interOpNumThreads: 1,
        providers: const [OrtProvider.CPU],
      ),
    );
    final epochs = <EcgSleepStageEpoch>[];
    try {
      for (final segment in prepared) {
        final count = segment.samples.length ~/ _modelEpochSamples;
        if (count == 0) continue;
        final ecg = await OrtValue.fromList(segment.samples, [
          1,
          count,
          1,
          _modelEpochSamples,
        ]);
        final additional = await OrtValue.fromList(
          _standardNormalFeatures(
            count * 4,
            recordedAt.microsecondsSinceEpoch ^ segment.startOffsetSeconds,
          ),
          [1, count, 4],
        );
        final valid = Float32List(count);
        valid.fillRange(0, count, 1.0);
        final mask = await OrtValue.fromList(valid, [1, count, 1]);
        Map<String, OrtValue>? outputs;
        try {
          outputs = await session.run({
            'ecg': ecg,
            'additional': additional,
            'valid_epochs': mask,
          });
          final values = await outputs['stage_probabilities']!
              .asFlattenedList();
          if (values.length != count * 5) {
            throw StateError('Sleep model returned an unexpected output size.');
          }
          for (var epoch = 0; epoch < count; epoch++) {
            var bestStage = 0;
            var bestProbability = -double.infinity;
            for (var stage = 0; stage < 5; stage++) {
              final probability = (values[epoch * 5 + stage] as num).toDouble();
              if (probability > bestProbability) {
                bestStage = stage;
                bestProbability = probability;
              }
            }
            epochs.add(
              EcgSleepStageEpoch(
                startOffsetSeconds: segment.startOffsetSeconds + epoch * 30,
                stage: bestStage,
                confidence: bestProbability.clamp(0.0, 1.0),
              ),
            );
          }
        } finally {
          await ecg.dispose();
          await additional.dispose();
          await mask.dispose();
          for (final output in outputs?.values ?? const <OrtValue>[]) {
            await output.dispose();
          }
        }
      }
    } finally {
      await session.close();
    }
    if (epochs.isEmpty) {
      throw const FormatException(
        'No complete 30-second ECG sections could be analyzed.',
      );
    }
    return EcgSleepStageEstimate(createdAt: DateTime.now(), epochs: epochs);
  }
}

class _PreparedEcgSegment {
  const _PreparedEcgSegment(this.startOffsetSeconds, this.samples);
  final int startOffsetSeconds;
  final Float32List samples;
}

Float32List _standardNormalFeatures(int count, int seed) {
  final random = math.Random(seed & 0x7fffffff);
  final values = Float32List(count);
  for (var i = 0; i < count; i += 2) {
    final radius = math.sqrt(
      -2 * math.log(math.max(random.nextDouble(), 1e-12)),
    );
    final angle = 2 * math.pi * random.nextDouble();
    values[i] = radius * math.cos(angle);
    if (i + 1 < count) values[i + 1] = radius * math.sin(angle);
  }
  return values;
}

List<_PreparedEcgSegment> _prepareSegments(
  List<EcgChunk> chunks,
  double sampleRateHz,
) {
  final ordered = [...chunks]..sort((a, b) => a.offsetUs.compareTo(b.offsetUs));
  final groups = <({int startUs, List<double> samples})>[];
  List<double>? current;
  var currentStart = 0;
  var expectedNext = 0.0;
  final maxGapUs = 1.5e6 / sampleRateHz;
  for (final chunk in ordered) {
    final startUs = chunk.offsetUs;
    final gapUs = startUs - expectedNext;
    if (current != null && gapUs.abs() > maxGapUs) {
      groups.add((startUs: currentStart, samples: current));
      current = null;
    }
    if (current == null) {
      currentStart = startUs;
      current = <double>[];
    }
    current.addAll(chunk.microvolts.map((value) => value.toDouble()));
    expectedNext = startUs + chunk.microvolts.length * 1e6 / sampleRateHz;
  }
  if (current != null && current.isNotEmpty) {
    groups.add((startUs: currentStart, samples: current));
  }

  final prepared = <_PreparedEcgSegment>[];
  for (final group in groups) {
    final sourceEpochSamples = (sampleRateHz * 30).round();
    final epochCount = group.samples.length ~/ sourceEpochSamples;
    if (epochCount == 0) continue;
    final sourceLength = epochCount * sourceEpochSamples;
    final filtered = Float64List(sourceLength);
    for (var i = 0; i < sourceLength; i++) {
      filtered[i] = group.samples[i];
    }
    _zeroPhaseBiquad(filtered, _highPassCoefficients(sampleRateHz, .5));
    // Polar H10 data may contain local mains interference. Applying both
    // common bands is safe at 130 Hz (Nyquist 65 Hz), as in the offline run.
    _zeroPhaseBiquad(filtered, _notchCoefficients(sampleRateHz, 50, 33));
    _zeroPhaseBiquad(filtered, _notchCoefficients(sampleRateHz, 60, 33));
    final resampled = _resampleSinc(filtered, sampleRateHz, epochCount * 7680);
    _scaleUsingBeatPeaks(resampled);
    prepared.add(
      _PreparedEcgSegment(
        (group.startUs / 1e6).round(),
        Float32List.fromList(resampled),
      ),
    );
  }
  return prepared;
}

({double b0, double b1, double b2, double a1, double a2}) _highPassCoefficients(
  double sampleRate,
  double frequency,
) {
  const q = .7071067811865476;
  final w = 2 * math.pi * frequency / sampleRate;
  final c = math.cos(w), alpha = math.sin(w) / (2 * q);
  final a0 = 1 + alpha;
  return (
    b0: (1 + c) / (2 * a0),
    b1: -(1 + c) / a0,
    b2: (1 + c) / (2 * a0),
    a1: -2 * c / a0,
    a2: (1 - alpha) / a0,
  );
}

({double b0, double b1, double b2, double a1, double a2}) _notchCoefficients(
  double sampleRate,
  double frequency,
  double q,
) {
  final w = 2 * math.pi * frequency / sampleRate;
  final c = math.cos(w), alpha = math.sin(w) / (2 * q);
  final a0 = 1 + alpha;
  return (
    b0: 1 / a0,
    b1: -2 * c / a0,
    b2: 1 / a0,
    a1: -2 * c / a0,
    a2: (1 - alpha) / a0,
  );
}

void _zeroPhaseBiquad(
  Float64List signal,
  ({double b0, double b1, double b2, double a1, double a2}) c,
) {
  final filtered = _biquad(signal, c);
  final reversed = Float64List.fromList(filtered.reversed.toList());
  final backward = _biquad(reversed, c);
  for (var i = 0; i < signal.length; i++) {
    signal[i] = backward[signal.length - i - 1];
  }
}

Float64List _biquad(
  Float64List input,
  ({double b0, double b1, double b2, double a1, double a2}) c,
) {
  final output = Float64List(input.length);
  var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0;
  for (var i = 0; i < input.length; i++) {
    final x = input[i];
    final y = c.b0 * x + c.b1 * x1 + c.b2 * x2 - c.a1 * y1 - c.a2 * y2;
    output[i] = y;
    x2 = x1;
    x1 = x;
    y2 = y1;
    y1 = y;
  }
  return output;
}

Float64List _resampleSinc(
  Float64List input,
  double sourceRate,
  int outputCount,
) {
  const radius = 4;
  final output = Float64List(outputCount);
  for (var i = 0; i < outputCount; i++) {
    final position = i * sourceRate / _outputRate;
    final center = position.floor();
    var total = 0.0, weightTotal = 0.0;
    for (var k = center - radius + 1; k <= center + radius; k++) {
      final distance = position - k;
      if (distance.abs() >= radius) continue;
      final sinc = distance.abs() < 1e-12
          ? 1.0
          : math.sin(math.pi * distance) / (math.pi * distance);
      final window = .5 + .5 * math.cos(math.pi * distance / radius);
      final weight = sinc * window;
      final bounded = k.clamp(0, input.length - 1);
      total += input[bounded] * weight;
      weightTotal += weight;
    }
    output[i] = weightTotal.abs() < 1e-12 ? input[center] : total / weightTotal;
  }
  return output;
}

/// The upstream requirements scale beats so that the 90th percentile of
/// heartbeat extrema is about +/-0.5. R peaks are approximated from local
/// absolute maxima here; the original pipeline uses template-based beat
/// locations and artifact rejection.
void _scaleUsingBeatPeaks(Float64List signal) {
  final center = _median(Float64List.fromList(signal));
  final absolute = Float64List(signal.length);
  for (var i = 0; i < signal.length; i++) {
    signal[i] -= center;
    absolute[i] = signal[i].abs();
  }
  final threshold = math.max(_percentile(absolute, .70) * .18, 1e-9);
  const refractory = 77; // 0.30 s at 256 Hz.
  const beatRadius = 31; // 0.12 s around each detected QRS candidate.
  final candidatePeaks = <int>[];
  for (var i = 1; i < absolute.length - 1; i++) {
    if (absolute[i] < threshold ||
        absolute[i] < absolute[i - 1] ||
        absolute[i] <= absolute[i + 1]) {
      continue;
    }
    if (candidatePeaks.isNotEmpty && i - candidatePeaks.last < refractory) {
      if (absolute[i] > absolute[candidatePeaks.last]) {
        candidatePeaks[candidatePeaks.length - 1] = i;
      }
    } else {
      candidatePeaks.add(i);
    }
  }
  if (candidatePeaks.length < 20) {
    throw const FormatException(
      'Too few heartbeats were detected for sleep-stage estimation.',
    );
  }
  final beatExtrema = Float64List(candidatePeaks.length);
  for (var beat = 0; beat < candidatePeaks.length; beat++) {
    final peak = candidatePeaks[beat];
    final start = math.max(0, peak - beatRadius);
    final end = math.min(signal.length, peak + beatRadius + 1);
    var maxAbs = 0.0;
    for (var i = start; i < end; i++) {
      maxAbs = math.max(maxAbs, absolute[i]);
    }
    beatExtrema[beat] = maxAbs;
  }
  final scale = _percentile(beatExtrema, .90) * 2;
  if (!scale.isFinite || scale < 1e-9) {
    throw const FormatException('The ECG heartbeat signal is too small.');
  }
  for (var i = 0; i < signal.length; i++) {
    signal[i] = (signal[i] / scale).clamp(-1.0, 1.0);
  }
}

double _percentile(Float64List values, double percentile) {
  if (values.isEmpty) return 0;
  final target = ((values.length - 1) * percentile).round();
  return _select(Float64List.fromList(values), target);
}

double _median(Float64List values) {
  final middle = values.length ~/ 2;
  final upper = _select(values, middle);
  if (values.length.isOdd) return upper;
  final lower = _select(values, middle - 1);
  return (lower + upper) / 2;
}

double _select(Float64List values, int target) {
  var left = 0, right = values.length - 1;
  while (left < right) {
    final pivot = values[(left + right) >> 1];
    var i = left, j = right;
    while (i <= j) {
      while (values[i] < pivot) {
        i++;
      }
      while (values[j] > pivot) {
        j--;
      }
      if (i <= j) {
        final temp = values[i];
        values[i] = values[j];
        values[j] = temp;
        i++;
        j--;
      }
    }
    if (target <= j) {
      right = j;
    } else if (target >= i) {
      left = i;
    } else {
      break;
    }
  }
  return values[target];
}
