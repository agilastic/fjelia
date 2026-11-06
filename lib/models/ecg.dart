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
