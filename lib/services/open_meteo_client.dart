import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'global_weather_client.dart';

/// One hour of weather from any provider (Open-Meteo field semantics).
class OpenMeteoPoint {
  const OpenMeteoPoint({
    required this.time,
    required this.temperatureC,
    required this.humidityPct,
    required this.pressureHpa,
    required this.precipitationMm,
    this.precipitationProbability,
    required this.windSpeedKmh,
    required this.windDirection,
    this.cloudCover,
    this.uvIndex,
    this.weatherCode,
    this.sunshineSeconds,
  });

  final DateTime time;
  final double temperatureC;
  final double humidityPct;
  final double pressureHpa;
  final double precipitationMm;
  final int? precipitationProbability;
  final double windSpeedKmh;
  final double windDirection;
  final int? cloudCover;
  final int? uvIndex;
  final int? weatherCode;
  final int? sunshineSeconds;
}

class OpenMeteoResult {
  const OpenMeteoResult({
    required this.points,
    required this.sunrise,
    required this.sunset,
    required this.fetchedAt,
    required this.rawJson,
    required this.source,
    this.elevation,
  });

  final List<OpenMeteoPoint> points;

  /// Keyed by `yyyy-MM-dd`.
  final Map<String, DateTime> sunrise;
  final Map<String, DateTime> sunset;
  final DateTime fetchedAt;
  final String rawJson;
  final String source;
  final double? elevation;
}

class OpenMeteoClient extends GlobalWeatherClient {
  OpenMeteoClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  static const _forecastUrl = 'https://api.open-meteo.com/v1/forecast';

  @override
  String get serviceName => 'Open-Meteo';

  /// Wet-bulb temperature (Stull 2011) from air temperature and relative
  /// humidity; RH is clamped to the formula's valid 5–99 % range.
  static double wetBulbC(double tempC, double humidityPct) {
    final rh = humidityPct.clamp(5.0, 99.0);
    return tempC * math.atan(0.151977 * math.sqrt(rh + 8.313659)) +
        math.atan(tempC + rh) -
        math.atan(rh - 1.676331) +
        0.00391838 * math.pow(rh, 1.5) * math.atan(0.023101 * rh) -
        4.686035;
  }

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
      end: day.add(const Duration(days: 1)),
    );
    if (result.points.isEmpty) {
      throw Exception('Open-Meteo returned no hourly weather data.');
    }
    final point = _closestPoint(result.points, at);
    return WeatherSnapshotData(
      cacheKey: _cacheKey(point.time, latitude, longitude),
      source: _forecastUrl,
      observedAt: point.time,
      latitude: latitude,
      longitude: longitude,
      temperatureC: point.temperatureC,
      humidityPct: point.humidityPct,
      pressureHpa: point.pressureHpa,
      wetBulbC: wetBulbC(point.temperatureC, point.humidityPct),
      rawJson: result.rawJson,
    );
  }

  static String _cacheKey(DateTime time, double lat, double lng) {
    final hour = DateTime(time.year, time.month, time.day, time.hour);
    return '$_forecastUrl:${lat.toStringAsFixed(2)}:'
        '${lng.toStringAsFixed(2)}:${hour.toIso8601String()}';
  }

  OpenMeteoPoint _closestPoint(List<OpenMeteoPoint> points, DateTime at) {
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
    final uri = _buildUri(start, end, elevation, latitude, longitude);
    final response = await _http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
          'Open-Meteo HTTP ${response.statusCode}: ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>? ?? const {};

    List<T> lst<T>(String key, T Function(dynamic) f) =>
        (hourly[key] as List?)?.map(f).toList() ?? <T>[];
    double d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
    int? i(dynamic v) => (v as num?)?.round();

    final times = lst<DateTime?>('time', (v) => DateTime.tryParse('$v'))
        .whereType<DateTime>()
        .toList();
    final temp = lst<double>('temperature_2m', d);
    final hum = lst<double>('relative_humidity_2m', d);
    final pressure = lst<double>('pressure_msl', (v) => (v as num?)?.toDouble() ?? 1013.0);
    final precip = lst<double>('precipitation', d);
    final precipProb = lst<int?>('precipitation_probability', i);
    final wind = lst<double>('wind_speed_10m', d);
    final windDir = lst<double>('wind_direction_10m', d);
    final cloud = lst<int?>('cloud_cover', i);
    final uv = lst<int?>('uv_index', i);
    final code = lst<int?>('weather_code', i);
    final sunshine = lst<int?>('sunshine_duration', i);

    final n = [times.length, temp.length, hum.length].reduce(math.min);
    T? at<T>(List<T> l, int k) => k < l.length ? l[k] : null;
    final points = <OpenMeteoPoint>[
      for (var k = 0; k < n; k++)
        OpenMeteoPoint(
          time: times[k],
          temperatureC: temp[k],
          humidityPct: hum[k],
          pressureHpa: at(pressure, k) ?? 1013.0,
          precipitationMm: at(precip, k) ?? 0.0,
          precipitationProbability: at<int?>(precipProb, k),
          windSpeedKmh: at(wind, k) ?? 0.0,
          windDirection: at(windDir, k) ?? 0.0,
          cloudCover: at<int?>(cloud, k),
          uvIndex: at<int?>(uv, k),
          weatherCode: at<int?>(code, k),
          sunshineSeconds: at<int?>(sunshine, k),
        ),
    ];

    final daily = json['daily'] as Map<String, dynamic>? ?? const {};
    final days = (daily['time'] as List?)?.map((e) => '$e').toList() ?? [];
    final rises = (daily['sunrise'] as List?)?.map((e) => '$e').toList() ?? [];
    final sets = (daily['sunset'] as List?)?.map((e) => '$e').toList() ?? [];
    final sunrise = <String, DateTime>{};
    final sunset = <String, DateTime>{};
    for (var k = 0; k < days.length; k++) {
      final r = k < rises.length ? DateTime.tryParse(rises[k]) : null;
      final s = k < sets.length ? DateTime.tryParse(sets[k]) : null;
      if (r != null) sunrise[days[k]] = r;
      if (s != null) sunset[days[k]] = s;
    }

    return OpenMeteoResult(
      points: points,
      sunrise: sunrise,
      sunset: sunset,
      fetchedAt: DateTime.now(),
      rawJson: response.body,
      source: serviceName,
      elevation: (json['elevation'] as num?)?.toDouble(),
    );
  }

  Uri _buildUri(DateTime start, DateTime end, double? elevation, double lat,
      double lng) {
    return Uri.parse(_forecastUrl).replace(queryParameters: {
      'latitude': lat.toStringAsFixed(4),
      'longitude': lng.toStringAsFixed(4),
      'hourly': 'temperature_2m,relative_humidity_2m,pressure_msl,'
          'precipitation,precipitation_probability,wind_speed_10m,'
          'wind_direction_10m,cloud_cover,uv_index,weather_code,'
          'sunshine_duration',
      'daily': 'sunrise,sunset',
      'timezone': 'auto',
      'start_date': dayKey(start),
      'end_date': dayKey(end),
      if (elevation != null) 'elevation': elevation.toStringAsFixed(0),
    });
  }
}

String dayKey(DateTime d) => '${d.year}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
