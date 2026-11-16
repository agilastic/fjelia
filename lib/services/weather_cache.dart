import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'open_meteo_client.dart';

/// Hourly weather kept for [weatherCacheTtl], so a sync does not ask the
/// weather services for the same two weeks again. Stored on the device, so
/// it survives a restart of the app.
const weatherCacheTtl = Duration(hours: 4);

abstract class WeatherCacheStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class PrefsWeatherCacheStore implements WeatherCacheStore {
  const PrefsWeatherCacheStore();

  static const _prefix = 'weather_cache_v1:';

  @override
  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).getString('$_prefix$key');

  @override
  Future<void> write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    // Expired entries are dropped, so the cache never grows.
    for (final k in prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      final saved = RegExp(
        r'"savedAt":"([^"]+)"',
      ).firstMatch(prefs.getString(k) ?? '')?[1];
      final at = saved == null ? null : DateTime.tryParse(saved);
      if (at == null || DateTime.now().difference(at) >= weatherCacheTtl) {
        await prefs.remove(k);
      }
    }
    await prefs.setString('$_prefix$key', value);
  }
}

class MemoryWeatherCacheStore implements WeatherCacheStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class WeatherCache {
  WeatherCache({WeatherCacheStore? store, DateTime Function()? now})
    : _store = store ?? const PrefsWeatherCacheStore(),
      _now = now ?? DateTime.now;

  final WeatherCacheStore _store;
  final DateTime Function() _now;

  static String key({
    required double latitude,
    required double longitude,
    required DateTime start,
    required DateTime end,
    double? elevation,
  }) {
    String d(DateTime t) => t.toIso8601String().substring(0, 10);
    return '${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)},'
        '${d(start)},${d(end)},${elevation?.round() ?? '-'}';
  }

  /// The stored result when it is younger than [weatherCacheTtl].
  Future<OpenMeteoResult?> read(String key) async {
    try {
      final raw = await _store.read(key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final saved = DateTime.parse(json['savedAt'] as String);
      if (_now().difference(saved) >= weatherCacheTtl) return null;
      return _decode(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, OpenMeteoResult result) async {
    try {
      await _store.write(key, jsonEncode(_encode(result)));
    } catch (_) {
      // A cache that cannot be written only costs the next request.
    }
  }

  Map<String, dynamic> _encode(OpenMeteoResult r) => {
    'savedAt': _now().toIso8601String(),
    'fetchedAt': r.fetchedAt.toIso8601String(),
    'source': r.source,
    'elevation': r.elevation,
    'sunrise': {
      for (final e in r.sunrise.entries) e.key: e.value.toIso8601String(),
    },
    'sunset': {
      for (final e in r.sunset.entries) e.key: e.value.toIso8601String(),
    },
    'points': [
      for (final p in r.points)
        [
          p.time.toIso8601String(),
          p.temperatureC,
          p.humidityPct,
          p.pressureHpa,
          p.precipitationMm,
          p.precipitationProbability,
          p.windSpeedKmh,
          p.windDirection,
          p.cloudCover,
          p.uvIndex,
          p.weatherCode,
          p.sunshineSeconds,
        ],
    ],
  };

  static OpenMeteoResult _decode(Map<String, dynamic> json) {
    Map<String, DateTime> days(Object? v) => {
      for (final e in (v as Map<String, dynamic>).entries)
        e.key: DateTime.parse(e.value as String),
    };
    double n(Object? v) => (v as num).toDouble();
    int? i(Object? v) => (v as num?)?.toInt();
    return OpenMeteoResult(
      points: [
        for (final p in (json['points'] as List).cast<List>())
          OpenMeteoPoint(
            time: DateTime.parse(p[0] as String),
            temperatureC: n(p[1]),
            humidityPct: n(p[2]),
            pressureHpa: n(p[3]),
            precipitationMm: n(p[4]),
            precipitationProbability: i(p[5]),
            windSpeedKmh: n(p[6]),
            windDirection: n(p[7]),
            cloudCover: i(p[8]),
            uvIndex: i(p[9]),
            weatherCode: i(p[10]),
            sunshineSeconds: i(p[11]),
          ),
      ],
      sunrise: days(json['sunrise']),
      sunset: days(json['sunset']),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      rawJson: '',
      source: json['source'] as String,
      elevation: (json['elevation'] as num?)?.toDouble(),
    );
  }
}
