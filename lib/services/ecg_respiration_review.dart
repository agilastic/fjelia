import 'dart:isolate';
import 'dart:math' as math;

import '../models/ecg.dart';
import 'ecg_analysis.dart';

class EcgRespirationReview {
  const EcgRespirationReview({
    required this.ecgAmplitude,
    required this.movement,
    required this.durationSeconds,
  });

  /// Normalized beat-amplitude modulation. This is not airflow or a
  /// respiratory-effort measurement.
  final List<({double seconds, double value})> ecgAmplitude;

  /// Relative accelerometer movement RMS by 30-second window.
  final List<({double seconds, double value})> movement;
  final double durationSeconds;
}

/// Exploratory, local-only signal visualization. No apnea events, AHI, or
/// clinical conclusions are inferred.
Future<EcgRespirationReview> reviewH10Signals({
  required List<EcgChunk> ecg,
  required List<AccelerationChunk> acceleration,
  required double ecgRateHz,
  required double accelerationRateHz,
}) => Isolate.run(
  () => _reviewH10Signals(ecg, acceleration, ecgRateHz, accelerationRateHz),
);

EcgRespirationReview _reviewH10Signals(
  List<EcgChunk> ecg,
  List<AccelerationChunk> acceleration,
  double ecgRateHz,
  double accelerationRateHz,
) {
  final ecgOrigin = _streamOriginNs([
    for (final c in ecg)
      (c.offsetUs, c.deviceLastSampleNs, c.microvolts.length),
  ], ecgRateHz);
  final accelerationOrigin = _streamOriginNs([
    for (final c in acceleration)
      (c.offsetUs, c.deviceLastSampleNs, c.samplesMilliG.length),
  ], accelerationRateHz);
  final deviceOrigin = [ecgOrigin, accelerationOrigin]
      .whereType<int>()
      .fold<int?>(
        null,
        (current, value) =>
            current == null || value < current ? value : current,
      );
  final ecgShift = ecgOrigin != null && deviceOrigin != null
      ? (ecgOrigin - deviceOrigin) / 1e9
      : 0.0;
  final accelerationShift = accelerationOrigin != null && deviceOrigin != null
      ? (accelerationOrigin - deviceOrigin) / 1e9
      : 0.0;
  final amplitudes = deriveEcgRespirationAmplitude(ecg, ecgRateHz);
  final median = _median([for (final point in amplitudes) point.microvolts]);
  final ecgPoints = <({double seconds, double value})>[
    for (final point in amplitudes)
      if (median > 0)
        (
          seconds: point.seconds + ecgShift,
          value: (point.microvolts / median).clamp(0, 3).toDouble(),
        ),
  ];

  final motionSums = <int, double>{};
  final motionCounts = <int, int>{};
  final motion = <({double seconds, double value})>[];
  final ordered = [...acceleration]
    ..sort((a, b) => a.offsetUs.compareTo(b.offsetUs));
  var duration = 0.0;
  for (final chunk in ordered) {
    final base = chunk.offsetUs / 1e6 + accelerationShift;
    for (var i = 0; i < chunk.samplesMilliG.length; i++) {
      final sample = chunk.samplesMilliG[i];
      final second = base + i / accelerationRateHz;
      final window = (second / 30).floor();
      // |a|-1g rejects the static gravity vector approximately; this is a
      // movement context only and does not estimate chest expansion.
      final magnitude = math.sqrt(
        sample.x * sample.x + sample.y * sample.y + sample.z * sample.z,
      );
      final dynamic = magnitude - 1000;
      motionSums[window] = (motionSums[window] ?? 0) + dynamic * dynamic;
      motionCounts[window] = (motionCounts[window] ?? 0) + 1;
      duration = math.max(duration, second).toDouble();
    }
  }
  final rms = [
    for (final entry in motionSums.entries)
      math.sqrt(entry.value / motionCounts[entry.key]!),
  ];
  final motionScale = _percentile(rms, .9);
  for (final entry in motionSums.entries) {
    final value = math.sqrt(entry.value / motionCounts[entry.key]!);
    motion.add((
      seconds: entry.key * 30.0 + 15,
      value: motionScale > 0
          ? (value / motionScale).clamp(0, 1.5).toDouble()
          : 0,
    ));
  }
  motion.sort((a, b) => a.seconds.compareTo(b.seconds));
  if (ecgPoints.isNotEmpty) {
    duration = math.max(duration, ecgPoints.last.seconds).toDouble();
  }
  return EcgRespirationReview(
    ecgAmplitude: ecgPoints,
    movement: motion,
    durationSeconds: duration,
  );
}

int? _streamOriginNs(List<(int, int?, int)> chunks, double rate) {
  final ordered = [...chunks]..sort((a, b) => a.$1.compareTo(b.$1));
  for (final chunk in ordered) {
    final lastNs = chunk.$2;
    if (lastNs != null && chunk.$3 > 0) {
      return lastNs - ((chunk.$3 - 1) * 1e9 / rate).round() - chunk.$1 * 1000;
    }
  }
  return null;
}

double _median(List<double> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

double _percentile(List<double> values, double fraction) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  return sorted[((sorted.length - 1) * fraction).round()];
}
