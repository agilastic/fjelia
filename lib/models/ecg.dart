import 'dart:math' as math;
import 'dart:typed_data';

/// Polar PMD ECG type 0: a timestamp of the last sample (nanoseconds on the
/// device's clock), followed by signed 24-bit values in microvolts.
class EcgFrame {
  const EcgFrame(this.lastSampleNs, this.microvolts);
  final int lastSampleNs;
  final List<int> microvolts;

  factory EcgFrame.decode(List<int> bytes) {
    if (bytes.length < 13 ||
        bytes[0] != 0 ||
        bytes[9] != 0 ||
        (bytes.length - 10) % 3 != 0) {
      throw const FormatException('Unsupported or truncated Polar ECG frame.');
    }
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final values = <int>[];
    for (var i = 10; i < bytes.length; i += 3) {
      final raw = bytes[i] | bytes[i + 1] << 8 | bytes[i + 2] << 16;
      values.add(raw & 0x800000 != 0 ? raw - 0x1000000 : raw);
    }
    return EcgFrame(data.getUint64(1, Endian.little), values);
  }
}

/// Polar PMD accelerometer type 2, uncompressed frame type 1. Values are
/// signed milli-g on the wire; keep the device timestamp for synchronization.
class AccelerationFrame {
  const AccelerationFrame(this.lastSampleNs, this.samplesMilliG);
  final int lastSampleNs;
  final List<({int x, int y, int z})> samplesMilliG;

  factory AccelerationFrame.decode(List<int> bytes) {
    if (bytes.length < 16 ||
        bytes[0] != 2 ||
        bytes[9] != 1 ||
        (bytes.length - 10) % 6 != 0) {
      throw const FormatException('Unsupported or truncated Polar ACC frame.');
    }
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final samples = <({int x, int y, int z})>[];
    for (var i = 10; i < bytes.length; i += 6) {
      samples.add((
        x: data.getInt16(i, Endian.little),
        y: data.getInt16(i + 2, Endian.little),
        z: data.getInt16(i + 4, Endian.little),
      ));
    }
    return AccelerationFrame(data.getUint64(1, Endian.little), samples);
  }
}

class AccelerationChunk {
  const AccelerationChunk({
    required this.offsetUs,
    required this.samplesMilliG,
    this.deviceLastSampleNs,
    this.receivedAt,
  });
  final int offsetUs;
  final List<({int x, int y, int z})> samplesMilliG;
  final int? deviceLastSampleNs;
  final DateTime? receivedAt;

  Map<String, Object?> toJson() => {
    'stream': 'acc',
    'offset_us': offsetUs,
    'mg': [
      for (final s in samplesMilliG) [s.x, s.y, s.z],
    ],
    'device_last_sample_ns': deviceLastSampleNs?.toString(),
    'received_at': receivedAt?.toUtc().toIso8601String(),
  };

  factory AccelerationChunk.fromJson(Map<String, dynamic> json) =>
      AccelerationChunk(
        offsetUs: (json['offset_us'] as num).toInt(),
        samplesMilliG: [
          for (final row in json['mg'] as List)
            (
              x: ((row as List)[0] as num).toInt(),
              y: (row[1] as num).toInt(),
              z: (row[2] as num).toInt(),
            ),
        ],
        deviceLastSampleNs: int.tryParse('${json['device_last_sample_ns']}'),
        receivedAt: DateTime.tryParse('${json['received_at']}'),
      );
}

class AccelerationTimeline {
  AccelerationTimeline(this.sampleRateHz);
  final double sampleRateHz;
  int? _firstNs, _lastNs;
  int sampleCount = 0;

  AccelerationChunk? add(AccelerationFrame frame, DateTime receivedAt) {
    if (_lastNs != null && frame.lastSampleNs <= _lastNs!) return null;
    final period = 1e9 / sampleRateHz;
    final start =
        frame.lastSampleNs -
        ((frame.samplesMilliG.length - 1) * period).round();
    _firstNs ??= start;
    final offset = ((start - _firstNs!) / 1000).round();
    _lastNs = frame.lastSampleNs;
    sampleCount += frame.samplesMilliG.length;
    return AccelerationChunk(
      offsetUs: offset,
      samplesMilliG: frame.samplesMilliG,
      deviceLastSampleNs: frame.lastSampleNs,
      receivedAt: receivedAt,
    );
  }
}

class EcgChunk {
  const EcgChunk({
    required this.offsetUs,
    required this.microvolts,
    this.deviceLastSampleNs,
    this.receivedAt,
  });
  final int offsetUs;
  final List<num> microvolts;
  final int? deviceLastSampleNs;
  final DateTime? receivedAt;
  Map<String, Object?> toJson() => {
    'offset_us': offsetUs,
    'uv': microvolts,
    // Strings preserve all 64 bits in tools that decode JSON using doubles.
    'device_last_sample_ns': deviceLastSampleNs?.toString(),
    'received_at': receivedAt?.toUtc().toIso8601String(),
  };
  factory EcgChunk.fromJson(Map<String, dynamic> json) => EcgChunk(
    offsetUs: (json['offset_us'] as num).toInt(),
    microvolts: (json['uv'] as List).cast<num>(),
    deviceLastSampleNs: int.tryParse('${json['device_last_sample_ns']}'),
    receivedAt: DateTime.tryParse('${json['received_at']}'),
  );
}

/// Device time establishes relative sample timing. It is deliberately not
/// interpreted as wall time: an H10 can reset its clock when switched off.
class EcgTimeline {
  EcgTimeline(this.sampleRateHz);
  final double sampleRateHz;
  int? _firstNs, _lastNs;
  int sampleCount = 0;
  int durationUs = 0;
  int gaps = 0;

  EcgChunk? add(EcgFrame frame, DateTime receivedAt) {
    if (_lastNs != null && frame.lastSampleNs <= _lastNs!) return null;
    final period = 1e9 / sampleRateHz;
    final start =
        frame.lastSampleNs - ((frame.microvolts.length - 1) * period).round();
    if (_lastNs != null && start < _lastNs! + period / 2) {
      throw const FormatException('Overlapping ECG timestamps.');
    }
    if (_lastNs != null && start - _lastNs! > period * 1.5) gaps++;
    _firstNs ??= start;
    final offset = ((start - _firstNs!) / 1000).round();
    _lastNs = frame.lastSampleNs;
    sampleCount += frame.microvolts.length;
    durationUs = ((frame.lastSampleNs - _firstNs! + period) / 1000).round();
    return EcgChunk(
      offsetUs: offset,
      microvolts: frame.microvolts,
      deviceLastSampleNs: frame.lastSampleNs,
      receivedAt: receivedAt,
    );
  }
}

/// Display reduction preserves extrema. Stored samples are never downsampled.
List<({double seconds, double uv})> ecgDisplayPoints(
  List<EcgChunk> chunks,
  double hz, {
  required double startSeconds,
  required double endSeconds,
  int pixels = 800,
}) {
  if (hz <= 0 || endSeconds <= startSeconds) return const [];
  final buckets = <int, List<({double seconds, double uv})>>{};
  final width = math.max(1, pixels);
  for (final c in chunks) {
    final start = c.offsetUs / 1e6;
    final first = math.max(0, ((startSeconds - start) * hz).floor());
    final last = math.min(
      c.microvolts.length,
      ((endSeconds - start) * hz).ceil() + 1,
    );
    for (var i = first; i < last; i++) {
      final t = start + i / hz;
      final bucket = ((t - startSeconds) / (endSeconds - startSeconds) * width)
          .floor();
      final point = (seconds: t, uv: c.microvolts[i].toDouble());
      final values = buckets.putIfAbsent(bucket, () => [point, point]);
      if (point.uv < values[0].uv) values[0] = point;
      if (point.uv > values[1].uv) values[1] = point;
    }
  }
  final points = <({double seconds, double uv})>[];
  for (final values in buckets.values) {
    values.sort((a, b) => a.seconds.compareTo(b.seconds));
    points.add(values.first);
    if (values.last.seconds != values.first.seconds) points.add(values.last);
  }
  return points;
}
