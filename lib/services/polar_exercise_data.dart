import 'fit_activity_data.dart';

/// Decodes the AccessLink exercise schema, including hyphenated sample fields.
/// Optional FIT data enriches the summary; it never replaces timer duration
/// with elapsed duration, or equates timer duration with moving duration.
/// Schema: https://www.polar.com/accesslink-api/#exercisehashid
class PolarExerciseData {
  const PolarExerciseData({
    required this.start,
    required this.durationSeconds,
    required this.samples,
    this.distanceMeters,
    this.avgHeartRate,
    this.maxHeartRate,
    this.trainingLoad,
    this.avgPower,
    this.ascentMeters,
    this.movingSeconds,
  });

  final DateTime start;
  final int durationSeconds;
  final double? distanceMeters, avgHeartRate, maxHeartRate, trainingLoad;
  final double? avgPower, ascentMeters;
  final int? movingSeconds;
  final List<Map<String, num>> samples;

  static PolarExerciseData? parse(
    Map<String, dynamic> json, {
    FitActivityData? fit,
    Object? previousSamples,
  }) {
    final start = _start(json, fit?.start);
    if (start == null) return null;
    final duration = parsePolarDuration(
      json['duration'] is String ? json['duration'] as String : '',
    );
    final seconds = duration > 0 ? duration : fit?.timerSeconds?.round() ?? 0;
    if (seconds <= 0) return null;
    final hr = _field(json, 'heart_rate');
    final load = _field(json, 'training_load_pro');
    final byTime = <int, Map<String, num>>{};
    void merge(Map<String, num> sample) {
      final time = sample['t']?.toInt();
      if (time != null) (byTime[time] ??= {}).addAll(sample);
    }

    if (previousSamples is List) {
      for (final row in previousSamples.whereType<Map>()) {
        final time = row['t'];
        if (time is! num || !time.isFinite) continue;
        final sample = <String, num>{'t': time.toInt()};
        for (final key in ['d', 'hr', 'spd', 'ele', 'w', 'cad']) {
          final value = _number(row[key], allowNegative: key == 'ele');
          if (value != null && (key != 'hr' || value > 0)) sample[key] = value;
        }
        merge(sample);
      }
    }

    final raw = json['samples'];
    if (raw is List) {
      for (final series in raw.whereType<Map>()) {
        final type = int.tryParse('${_field(series, 'sample_type')}');
        final rate = _number(_field(series, 'recording_rate'));
        final data = series['data'];
        final key = switch (type) {
          0 => 'hr',
          1 => 'spd',
          3 => 'ele',
          4 => 'w',
          8 => 'cad',
          10 => 'd',
          _ => null,
        };
        if (key == null || rate == null || rate <= 0 || data is! String) {
          continue;
        }
        final values = data.split(',');
        for (var i = 0; i < values.length; i++) {
          final value = _number(values[i].trim(), allowNegative: key == 'ele');
          if (value == null || (key == 'hr' && value <= 0)) continue;
          merge({
            't': start.millisecondsSinceEpoch + (i * rate * 1000).round(),
            key: key == 'spd' ? value / 3.6 : value,
          });
        }
      }
      // Retain compatibility with previously supported timestamp/HR rows.
      for (final row in raw.whereType<Map>()) {
        final time = row['t'] ?? row['timestamp'];
        final bpm = _number(row['hr'] ?? row['heartRate']);
        if (time is num && time.isFinite && bpm != null && bpm > 0) {
          merge({'t': time.toInt(), 'hr': bpm});
        }
      }
    }
    for (final sample in fit?.samples ?? <Map<String, num>>[]) {
      merge(sample);
    }
    final samples = byTime.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final encoded = [for (final entry in samples) entry.value];
    final moving = fit?.movingSeconds;
    return PolarExerciseData(
      start: start,
      durationSeconds: seconds,
      distanceMeters: _number(json['distance']) ?? fit?.distanceMeters,
      avgHeartRate: hr is Map ? _number(hr['average']) : null,
      maxHeartRate: hr is Map ? _number(hr['maximum']) : null,
      trainingLoad:
          (load is Map ? _number(_field(load, 'cardio_load')) : null) ??
          _number(_field(json, 'training_load')),
      avgPower: fit?.avgPower,
      ascentMeters: fit?.ascentMeters,
      movingSeconds:
          moving != null &&
              moving.isFinite &&
              moving >= 0 &&
              moving <= seconds + 1
          ? moving.round()
          : null,
      samples: encoded,
    );
  }
}

Object? _field(Map json, String key) =>
    json[key] ?? json[key.replaceAll('_', '-')];

double? _number(Object? raw, {bool allowNegative = false}) {
  final value = raw is num
      ? raw.toDouble()
      : raw is String
      ? double.tryParse(raw)
      : null;
  return value != null && value.isFinite && (allowNegative || value >= 0)
      ? value
      : null;
}

DateTime? _start(Map json, DateTime? fallback) {
  final raw = _field(json, 'start_time');
  if (raw is! String) return fallback;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return fallback;
  if (RegExp(r'(?:Z|[+-]\d{2}:?\d{2})$', caseSensitive: false).hasMatch(raw)) {
    return parsed.toUtc();
  }
  final offset = _field(json, 'start_time_utc_offset');
  if (offset is num && offset.isFinite && offset >= -840 && offset <= 840) {
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).subtract(Duration(minutes: offset.round()));
  }
  return fallback?.toUtc() ?? parsed.toUtc();
}

/// ISO-8601 day/hour/minute/second duration, including fractional seconds and
/// recordings longer than a day. Unsupported/malformed values are unavailable.
int parsePolarDuration(String iso) {
  final match = RegExp(
    r'^P(?:(\d+(?:\.\d+)?)D)?(?:T(?:(\d+(?:\.\d+)?)H)?(?:(\d+(?:\.\d+)?)M)?(?:(\d+(?:\.\d+)?)S)?)?$',
  ).firstMatch(iso);
  if (match == null) return 0;
  final values = [
    for (var i = 1; i <= 4; i++) double.tryParse(match.group(i) ?? '0') ?? 0,
  ];
  final seconds =
      values[0] * 86400 + values[1] * 3600 + values[2] * 60 + values[3];
  return seconds.isFinite ? seconds.round() : 0;
}
