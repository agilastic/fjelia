import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'global_weather_client.dart';
import 'open_meteo_client.dart';

/// Bright Sky — free JSON API over Deutscher Wetterdienst (DWD) data.
class BrightSkyClient extends GlobalWeatherClient {
  BrightSkyClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  @override
  String get serviceName => 'Bright Sky (DWD)';

  String _fmt(DateTime d) => dayKey(d);

  @override
  Future<WeatherSnapshotData> fetchSnapshot({
    required double latitude,
    required double longitude,
    required DateTime at,
  }) async {
    final day = DateTime(at.year, at.month, at.day);
    final result = await fetchHourlyWeather(
      latitude: latitude,
      longitude: longitude,
      start: day,
      end: day,
    );
    final point = _closest(result.points, at);
    if (point == null) throw Exception('BrightSky: no data');
    return WeatherSnapshotData(
      cacheKey: 'brightsky:${latitude.toStringAsFixed(2)}:'
          '${longitude.toStringAsFixed(2)}:'
          '${DateTime(point.time.year, point.time.month, point.time.day, point.time.hour).toIso8601String()}',
      source: serviceName,
      observedAt: point.time,
      latitude: latitude,
      longitude: longitude,
      temperatureC: point.temperatureC,
      humidityPct: point.humidityPct,
      pressureHpa: point.pressureHpa,
      wetBulbC: OpenMeteoClient.wetBulbC(point.temperatureC, point.humidityPct),
      rawJson: result.rawJson,
    );
  }

  OpenMeteoPoint? _closest(List<OpenMeteoPoint> points, DateTime at) {
    if (points.isEmpty) return null;
    final target = at.toLocal();
    var best = points.first;
    var bestDiff = best.time.difference(target).abs();
    for (final p in points.skip(1)) {
      final diff = p.time.difference(target).abs();
      if (diff < bestDiff) {
        best = p;
        bestDiff = diff;
      }
    }
    return best;
  }

  @override
  Future<OpenMeteoResult> fetchHourlyWeather({
    required double latitude,
    required double longitude,
    required DateTime start,
    required DateTime end,
    double? elevation,
  }) async {
    final uri = Uri.parse('https://api.brightsky.dev/weather').replace(
      queryParameters: {
        'lat': latitude.toStringAsFixed(4),
        'lon': longitude.toStringAsFixed(4),
        'date': _fmt(start),
        'last_date': _fmt(end.add(const Duration(days: 1))),
        'units': 'dwd',
      },
    );
    final response = await _http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('BrightSky HTTP ${response.statusCode}: ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = (json['weather'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];

    final days = <String>{};
    final points = <OpenMeteoPoint>[];
    for (final row in rows) {
      final ts = DateTime.tryParse(row['timestamp'] as String? ?? '');
      if (ts == null) continue;
      final local = ts.toLocal();
      days.add(_fmt(local));
      double d(String k, double fallback) =>
          (row[k] as num?)?.toDouble() ?? fallback;
      // DWD reports sunshine in minutes per hour; fall back to solar
      // irradiance (kWh/m²) when sunshine is missing.
      final sunshineMin = (row['sunshine'] as num?)?.toDouble() ??
          ((row['solar'] as num?)?.toDouble() ?? 0.0) * 1000 * 0.008;
      points.add(OpenMeteoPoint(
        time: local,
        temperatureC: d('temperature', 0.0),
        humidityPct: d('relative_humidity', 0.0),
        pressureHpa: d('pressure_msl', 1013.0),
        precipitationMm: d('precipitation', 0.0),
        precipitationProbability:
            (row['precipitation_probability'] as num?)?.round(),
        windSpeedKmh: d('wind_speed', 0.0),
        windDirection: d('wind_direction', 0.0),
        cloudCover: (row['cloud_cover'] as num?)?.round(),
        sunshineSeconds: (sunshineMin * 60).round(),
      ));
    }

    final sunrise = <String, DateTime>{};
    final sunset = <String, DateTime>{};
    for (final key in days) {
      final parts = key.split('-');
      final date = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final rise = _calcSunrise(date, true, latitude, longitude);
      final set = _calcSunrise(date, false, latitude, longitude);
      if (rise != null) sunrise[key] = rise;
      if (set != null) sunset[key] = set;
    }

    return OpenMeteoResult(
      points: points,
      sunrise: sunrise,
      sunset: sunset,
      fetchedAt: DateTime.now(),
      rawJson: response.body,
      source: serviceName,
    );
  }

  /// NOAA solar position algorithm; null during polar day/night.
  static DateTime? _calcSunrise(
      DateTime date, bool rise, double lat, double lng) {
    double rad(double deg) => deg * math.pi / 180;
    double deg(double rad) => rad * 180 / math.pi;

    final jd = _julianDay(date);
    final t = (jd - 2451545.0) / 36525.0;
    final l0 = (280.46646 + t * (36000.76983 + t * 0.0003032)) % 360;
    final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
    final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
    final c = math.sin(rad(m)) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
        math.sin(rad(2 * m)) * (0.019993 - 0.000101 * t) +
        math.sin(rad(3 * m)) * 0.000289;
    final omega = 125.04 - 1934.136 * t;
    final lambda = l0 + c - 0.00569 - 0.00478 * math.sin(rad(omega));
    final eps0 =
        23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60;
    final eps = eps0 + 0.00256 * math.cos(rad(omega));
    final decl = math.asin(math.sin(rad(eps)) * math.sin(rad(lambda)));

    final y = math.pow(math.tan(rad(eps) / 2), 2).toDouble();
    final eqTime = 4 *
        deg(y * math.sin(2 * rad(l0)) -
            2 * e * math.sin(rad(m)) +
            4 * e * y * math.sin(rad(m)) * math.cos(2 * rad(l0)) -
            0.5 * y * y * math.sin(4 * rad(l0)) -
            1.25 * e * e * math.sin(2 * rad(m)));

    final cosHa = math.cos(1.585335) / (math.cos(rad(lat)) * math.cos(decl)) -
        math.tan(rad(lat)) * math.tan(decl);
    if (cosHa < -1.0 || cosHa > 1.0) return null;
    final ha = deg(math.acos(cosHa));
    final minutesUtc = 720 - 4 * (lng + (rise ? ha : -ha)) - eqTime;
    return DateTime.utc(date.year, date.month, date.day)
        .add(Duration(seconds: (minutesUtc * 60).round()))
        .toLocal();
  }

  static double _julianDay(DateTime date) {
    var y = date.year;
    var m = date.month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        date.day +
        b -
        1524.5;
  }
}
