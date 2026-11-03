import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thresholds a platform reports for the athlete (Garmin's detected lactate
/// threshold and FTP, COROS's threshold heart rate and pace, the values in
/// the Polar profile). Kept apart from the app's own test results
/// (`ThresholdRecords`), which the training plan reads directly: a platform
/// value only takes effect when the athlete applies it.
class DeviceThreshold {
  const DeviceThreshold({
    required this.source,
    required this.date,
    this.lt1Bpm,
    this.lt2Bpm,
    this.lt2PaceSecPerKm,
    this.lt2BikeBpm,
    this.ftpWatts,
  });

  /// `garmin_api`, `coros` or `polar_profile`.
  final String source;
  final DateTime date;
  final int? lt1Bpm, lt2Bpm, lt2PaceSecPerKm, lt2BikeBpm, ftpWatts;

  bool get isEmpty =>
      lt1Bpm == null &&
      lt2Bpm == null &&
      lt2PaceSecPerKm == null &&
      lt2BikeBpm == null &&
      ftpWatts == null;

  Map<String, Object?> toJson() => {
    'source': source,
    'date': date.toIso8601String(),
    'lt1': lt1Bpm,
    'lt2': lt2Bpm,
    'lt2Pace': lt2PaceSecPerKm,
    'lt2Bike': lt2BikeBpm,
    'ftp': ftpWatts,
  };

  static DeviceThreshold? fromJson(Object? json) {
    if (json is! Map) return null;
    final date = DateTime.tryParse('${json['date']}');
    if (date == null) return null;
    int? n(String key) => (json[key] as num?)?.round();
    return DeviceThreshold(
      source: '${json['source']}',
      date: date,
      lt1Bpm: n('lt1'),
      lt2Bpm: n('lt2'),
      lt2PaceSecPerKm: n('lt2Pace'),
      lt2BikeBpm: n('lt2Bike'),
      ftpWatts: n('ftp'),
    );
  }
}

class DeviceThresholdStore {
  const DeviceThresholdStore();

  static const _storage = FlutterSecureStorage();
  static const _key = 'device_thresholds_v1';

  Future<Map<String, DeviceThreshold>> all() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in map.entries) e.key: ?DeviceThreshold.fromJson(e.value),
      };
    } on FormatException {
      return {};
    }
  }

  /// Writes one after another: platforms sync in parallel, and two
  /// overlapping read-modify-writes would drop one platform's values.
  static Future<void> _queue = Future.value();

  /// Replaces what [threshold.source] reported. Empty reports are ignored,
  /// so a failed fetch keeps the previous values.
  Future<void> save(DeviceThreshold threshold) {
    if (threshold.isEmpty) return Future.value();
    final write = _queue.then((_) async {
      final current = await all();
      current[threshold.source] = threshold;
      await _storage.write(
        key: _key,
        value: jsonEncode({
          for (final e in current.entries) e.key: e.value.toJson(),
        }),
      );
    });
    _queue = write.catchError((Object _) {});
    return write;
  }
}

/// A heart rate in a plausible range, else null.
int? plausibleBpm(Object? raw) {
  final v = raw is num ? raw : num.tryParse('${raw ?? ''}');
  return v != null && v >= 80 && v <= 220 ? v.round() : null;
}

/// Threshold pace in s/km from a value that is either s/km or m/s.
int? paceSecPerKm(Object? raw) {
  final v = raw is num ? raw : num.tryParse('${raw ?? ''}');
  if (v == null || !v.isFinite || v <= 0) return null;
  if (v >= 120 && v <= 900) return v.round(); // already s/km (2:00–15:00)
  if (v >= 1.1 && v <= 8.4) return (1000 / v).round(); // m/s
  return null;
}
