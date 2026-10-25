import 'dart:convert';
import 'dart:math' as math;

import 'package:uuid/uuid.dart';

enum SpotHrvContext {
  beforeTraining('Before training'),
  afterTraining('After training'),
  resting('Resting');

  const SpotHrvContext(this.label);
  final String label;
}

enum SpotHrvPosture {
  seated('Seated'),
  supine('Lying down');

  const SpotHrvPosture(this.label);
  final String label;
}

/// Bluetooth SIG Heart Rate Measurement (0x2A37), not the Polar ECG service.
class H10HeartRatePacket {
  const H10HeartRatePacket(this.bpm, this.rrMs, this.contact);
  final int bpm;
  final List<double> rrMs;
  final bool? contact;

  factory H10HeartRatePacket.decode(List<int> bytes) {
    if (bytes.isEmpty) throw const FormatException('Empty heart rate packet');
    final flags = bytes[0];
    var offset = 1;
    int read16() {
      if (offset + 2 > bytes.length) {
        throw const FormatException('Truncated heart rate packet');
      }
      final value = bytes[offset] | (bytes[offset + 1] << 8);
      offset += 2;
      return value;
    }

    int bpm;
    if (flags & 1 != 0) {
      bpm = read16();
    } else {
      if (offset >= bytes.length) {
        throw const FormatException('Missing heart rate');
      }
      bpm = bytes[offset++];
    }
    if (flags & 8 != 0) read16(); // Optional energy-expended field.
    final rr = <double>[];
    if (flags & 16 != 0) {
      while (offset < bytes.length) {
        rr.add(read16() * 1000.0 / 1024.0);
      }
    }
    return H10HeartRatePacket(bpm, rr, flags & 4 == 0 ? null : flags & 2 != 0);
  }
}

class SpotRrSample {
  const SpotRrSample(this.elapsedMs, this.rrMs, {this.contact});
  final double elapsedMs;
  final double rrMs;
  final bool? contact;
}

/// Time-domain spot HRV. Rejected intervals are never interpolated or bridged.
class SpotHrvAnalysis {
  SpotHrvAnalysis._({
    required this.rmssdMs,
    required this.rawRmssdMs,
    required this.sdnnMs,
    required this.meanHr,
    required this.samples,
    required this.rejections,
    required this.accepted,
    required this.coverage,
    required this.pairs,
  });
  final double? rmssdMs, rawRmssdMs, sdnnMs, meanHr;
  final List<SpotRrSample> samples;
  final List<String?> rejections;
  final int accepted, pairs;
  final double coverage;
  double? get lnRmssd =>
      rmssdMs != null && rmssdMs! > 0 ? math.log(rmssdMs!) : null;
  double get usableFraction => samples.isEmpty ? 0 : accepted / samples.length;
  bool get reliable =>
      rmssdMs != null &&
      accepted >= 30 &&
      pairs >= 20 &&
      usableFraction >= .95 &&
      coverage >= .90;

  factory SpotHrvAnalysis.calculate(
    List<SpotRrSample> input,
    int durationSeconds,
  ) {
    final samples = List<SpotRrSample>.unmodifiable(input);
    final reasons = <String?>[];
    bool plausible(SpotRrSample s) =>
        s.rrMs.isFinite && s.rrMs >= 250 && s.rrMs <= 2500;
    for (var i = 0; i < samples.length; i++) {
      final sample = samples[i];
      if (!plausible(sample)) {
        reasons.add('RR outside 250–2500 ms');
        continue;
      }
      if (sample.contact == false) {
        reasons.add('Poor sensor contact');
        continue;
      }
      final neighbours = <double>[
        for (
          var j = math.max(0, i - 5);
          j <= math.min(samples.length - 1, i + 5);
          j++
        )
          if (plausible(samples[j]) && samples[j].contact != false)
            samples[j].rrMs,
      ]..sort();
      final median = neighbours.length.isOdd
          ? neighbours[neighbours.length ~/ 2]
          : (neighbours[neighbours.length ~/ 2 - 1] +
                    neighbours[neighbours.length ~/ 2]) /
                2;
      reasons.add(
        neighbours.length >= 5 && (sample.rrMs - median).abs() > median * .25
            ? 'More than 25% from local median'
            : null,
      );
    }
    final accepted = <double>[
      for (var i = 0; i < samples.length; i++)
        if (reasons[i] == null) samples[i].rrMs,
    ];
    var squared = 0.0, rawSquared = 0.0;
    var pairs = 0, rawPairs = 0;
    for (var i = 1; i < samples.length; i++) {
      final previous = samples[i - 1], current = samples[i];
      final delta = current.elapsedMs - previous.elapsedMs;
      if (delta <= 0 || delta > math.max(4000, current.rrMs + 1500)) continue;
      final difference = current.rrMs - previous.rrMs;
      if (current.rrMs.isFinite &&
          previous.rrMs.isFinite &&
          current.rrMs > 0 &&
          previous.rrMs > 0) {
        rawSquared += difference * difference;
        rawPairs++;
      }
      if (reasons[i] == null && reasons[i - 1] == null) {
        squared += difference * difference;
        pairs++;
      }
    }
    final mean = accepted.isEmpty
        ? null
        : accepted.reduce((a, b) => a + b) / accepted.length;
    final variance = accepted.length < 2
        ? null
        : accepted
                  .map((v) => math.pow(v - mean!, 2).toDouble())
                  .reduce((a, b) => a + b) /
              (accepted.length - 1);
    return SpotHrvAnalysis._(
      rmssdMs: pairs == 0 ? null : math.sqrt(squared / pairs),
      rawRmssdMs: rawPairs == 0 ? null : math.sqrt(rawSquared / rawPairs),
      sdnnMs: variance == null ? null : math.sqrt(variance),
      meanHr: mean == null ? null : 60000 / mean,
      samples: samples,
      rejections: List.unmodifiable(reasons),
      accepted: accepted.length,
      pairs: pairs,
      coverage: durationSeconds <= 0
          ? 0
          : math.min(
              1,
              accepted.fold(0.0, (a, b) => a + b) / (durationSeconds * 1000),
            ),
    );
  }

  String get rrJson => jsonEncode([
    for (var i = 0; i < samples.length; i++)
      {
        'elapsed_ms': samples[i].elapsedMs,
        'rr_ms': samples[i].rrMs,
        'contact': samples[i].contact,
        'excluded': rejections[i],
      },
  ]);
}

class SpotHrvCapture {
  SpotHrvCapture({
    required this.startedAt,
    required this.durationSeconds,
    this.settleSeconds = 60,
  });
  final DateTime startedAt;
  final int durationSeconds, settleSeconds;
  final samples = <SpotRrSample>[];

  /// One id per capture. Saving the same capture twice is the same save.
  final String captureId = const Uuid().v4();

  /// Wall clock minus monotonic time, at the end of the capture. A large
  /// value means the clock was set during the recording.
  Duration? clockJump;

  /// Compares the wall clock with the monotonic [elapsed] time.
  void checkClock(DateTime wallNow, Duration elapsed) {
    clockJump = wallNow.difference(startedAt) - elapsed;
  }

  /// More than 5 seconds apart: the absolute time of this recording is not
  /// trusted, the RR timing within it is.
  bool get clockUncertain =>
      clockJump != null && clockJump!.abs() > const Duration(seconds: 5);
  DateTime get measurementStartedAt =>
      startedAt.add(Duration(seconds: settleSeconds));
  bool complete(Duration elapsed) =>
      elapsed.inMilliseconds >= (durationSeconds + settleSeconds) * 1000;
  void add(H10HeartRatePacket packet, Duration elapsed) {
    var end = elapsed.inMicroseconds / 1000 - settleSeconds * 1000;
    final incoming = <SpotRrSample>[];
    for (final rr in packet.rrMs.reversed) {
      if (end - rr >= 0 && end <= durationSeconds * 1000) {
        incoming.add(SpotRrSample(end, rr, contact: packet.contact));
      }
      end -= rr;
    }
    samples.addAll(incoming.reversed);
  }

  SpotHrvAnalysis get analysis =>
      SpotHrvAnalysis.calculate(samples, durationSeconds);
}
