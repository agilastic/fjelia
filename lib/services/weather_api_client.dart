import '../config/secrets.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'global_weather_client.dart';
import 'open_meteo_client.dart';

/// weatherapi.com (forecast and history endpoints).
class WeatherApiClient extends GlobalWeatherClient {
  WeatherApiClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  static const _baseUrl = 'https://api.weatherapi.com/v1';
  static const _apiKey = Secrets.weatherApiKey;

  @override
  String get serviceName => 'WeatherAPI';

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
    if (point == null) throw Exception('WeatherAPI: no data');
    final hour =
        DateTime(point.time.year, point.time.month, point.time.day, point.time.hour);
    return WeatherSnapshotData(
      cacheKey: 'weatherapi:${latitude.toStringAsFixed(2)}:'
          '${longitude.toStringAsFixed(2)}:${hour.toIso8601String()}',
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final historic = start.isBefore(today);
    final uri = Uri.parse('$_baseUrl/${historic ? 'history.json' : 'forecast.json'}')
        .replace(queryParameters: {
      'key': _apiKey,
      'q': '$latitude,$longitude',
      'dt': dayKey(start),
      if (!historic)
        'days': '${(end.difference(start).inDays + 1).clamp(1, 3)}',
      'aqi': 'no',
      'alerts': 'no',
    });
    final response = await _http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('WeatherAPI HTTP ${response.statusCode}: ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final forecastDays = ((json['forecast'] as Map?)?['forecastday'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const [];

    final points = <OpenMeteoPoint>[];
    final sunrise = <String, DateTime>{};
    final sunset = <String, DateTime>{};
    for (final day in forecastDays) {
      final date = DateTime.tryParse(day['date'] as String? ?? '');
      if (date != null) {
        final key = dayKey(date);
        final astro = day['astro'] as Map<String, dynamic>? ?? const {};
        final rise = _parseAmPm(date, astro['sunrise'] as String? ?? '');
        final set = _parseAmPm(date, astro['sunset'] as String? ?? '');
        if (rise != null) sunrise[key] = rise;
        if (set != null) sunset[key] = set;
      }
      for (final h in (day['hour'] as List? ?? const [])
          .cast<Map<String, dynamic>>()) {
        double d(String k, double fallback) =>
            (h[k] as num?)?.toDouble() ?? fallback;
        final cloud = d('cloud', 0.0);
        final isDay = (h['is_day'] as num?) == 1;
        points.add(OpenMeteoPoint(
          time: DateTime.fromMillisecondsSinceEpoch(
                  (h['time_epoch'] as num).toInt() * 1000,
                  isUtc: true)
              .toLocal(),
          temperatureC: d('temp_c', 0.0),
          humidityPct: d('humidity', 0.0),
          pressureHpa: d('pressure_mb', 1013.0),
          precipitationMm: d('precip_mm', 0.0),
          precipitationProbability: (h['chance_of_rain'] as num?)?.round(),
          windSpeedKmh: d('wind_kph', 0.0),
          windDirection: d('wind_degree', 0.0),
          cloudCover: cloud.round(),
          uvIndex: (h['uv'] as num?)?.round(),
          // Rough sunshine estimate from cloud cover during daylight.
          sunshineSeconds:
              isDay ? (3600 * (100 - cloud) / 100 * 1.0).round() : 0,
        ));
      }
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

  /// `"06:41 AM"` on [date] → local DateTime.
  DateTime? _parseAmPm(DateTime date, String text) {
    final parts = text.trim().split(' ');
    if (parts.length != 2) return null;
    final hm = parts[0].split(':');
    if (hm.length != 2) return null;
    var hour = int.parse(hm[0]) % 12;
    final minute = int.parse(hm[1]);
    if (parts[1].toUpperCase() == 'PM') hour += 12;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
