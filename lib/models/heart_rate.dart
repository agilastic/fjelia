class TimedHeartRate {
  const TimedHeartRate(this.timestamp, this.bpm, this.source);
  final DateTime timestamp;
  final double bpm;
  final String source;
}

/// Accept absolute sample timestamps only, never dates or inferred durations.
DateTime? heartRateTimestamp(Object? value) {
  if (value is num && value.isFinite) {
    final ms = value >= 100000000000
        ? value.round()
        : value >= 1000000000
        ? (value * 1000).round()
        : null;
    return ms == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }
  if (value is String && value.contains('T')) return DateTime.tryParse(value);
  return null;
}

List<TimedHeartRate> parseTimedHeartRates(Object? raw, String source) {
  if (raw is! List) return [];
  final result = <TimedHeartRate>[];
  for (final row in raw) {
    final timestamp = row is List && row.length >= 2
        ? heartRateTimestamp(row[0])
        : row is Map
        ? heartRateTimestamp(row['t'] ?? row['timestamp'] ?? row['time'])
        : null;
    final bpm = row is List && row.length >= 2
        ? row[1]
        : row is Map
        ? row['hr'] ?? row['heartRate'] ?? row['heart_rate']
        : null;
    if (timestamp != null && bpm is num && bpm.isFinite && bpm > 0) {
      result.add(TimedHeartRate(timestamp, bpm.toDouble(), source));
    }
  }
  return result;
}
