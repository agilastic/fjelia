import '../config/secrets.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'global_weather_client.dart';
import 'open_meteo_client.dart';

/// Pirate Weather (Dark Sky–compatible API).
class PirateWeatherClient extends GlobalWeatherClient {
  PirateWeatherClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  static const _apiKey = Secrets.pirateWeatherKey;

  @override
  String get serviceName => 'Pirate Weather';

  @override
  Future<WeatherSnapshotData> fetchSnapshot({
    required double latitude,
    required double longitude,
    required DateTime at,
  }) async {
    final result = await fetchHourlyWeather(
      latitude: latitude,
      longitude: longitude,
      start: at,
      end: at,
    );
    final point = _closest(result.points, at);
    if (point == null) throw Exception('PirateWeather: no data');
    final hour =
        DateTime(point.time.year, point.time.month, point.time.day, point.time.hour);
    return WeatherSnapshotData(
      cacheKey: '${serviceName.toLowerCase().replaceAll(' ', '_')}:'
          '${latitude.toStringAsFixed(2)}:${longitude.toStringAsFixed(2)}:'
          '${hour.toIso8601String()}',
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
    // Past days need a time-machine request anchored on that day.
    final now = DateTime.now();
    final historic = start.isBefore(DateTime(now.year, now.month, now.day));
    final time = historic ? ',${start.millisecondsSinceEpoch ~/ 1000}' : '';
    final uri = Uri.parse('https://api.pirateweather.net/forecast/$_apiKey/'
        '$latitude,$longitude$time?units=si&exclude=minutely,alerts');
    final response = await _http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
          'PirateWeather HTTP ${response.statusCode}: ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final hourly =
        ((json['hourly'] as Map?)?['data'] as List?)?.cast<Map<String, dynamic>>() ??
            const [];
    final daily =
        ((json['daily'] as Map?)?['data'] as List?)?.cast<Map<String, dynamic>>() ??
            const [];

    DateTime fromEpoch(Object? v) => DateTime.fromMillisecondsSinceEpoch(
            (v as num).toInt() * 1000,
            isUtc: true)
        .toLocal();
    double d(Map<String, dynamic> m, String k, double fallback) =>
        (m[k] as num?)?.toDouble() ?? fallback;

    final points = <OpenMeteoPoint>[
      for (final h in hourly)
        OpenMeteoPoint(
          time: fromEpoch(h['time']),
          temperatureC: d(h, 'temperature', 0.0),
          humidityPct: (d(h, 'humidity', 0.0) * 100).clamp(0.0, 100.0),
          pressureHpa: d(h, 'pressure', 1013.0),
          precipitationMm: d(h, 'precipIntensity', 0.0),
          precipitationProbability:
              (d(h, 'precipProbability', 0.0) * 100).round(),
          windSpeedKmh: d(h, 'windSpeed', 0.0) * 3.6,
          windDirection: d(h, 'windBearing', 0.0),
          cloudCover: (d(h, 'cloudCover', 0.0) * 100).round(),
          uvIndex: (h['uvIndex'] as num?)?.round(),
        ),
    ];

    final sunrise = <String, DateTime>{};
    final sunset = <String, DateTime>{};
    for (final day in daily) {
      final key = dayKey(fromEpoch(day['time']));
      if (day['sunriseTime'] != null) sunrise[key] = fromEpoch(day['sunriseTime']);
      if (day['sunsetTime'] != null) sunset[key] = fromEpoch(day['sunsetTime']);
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
}
