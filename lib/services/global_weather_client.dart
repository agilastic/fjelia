import '../config/secrets.dart';
import 'dart:math';

import '../models/heat_acclimation.dart';
import '../utils/log.dart';
import 'bright_sky_client.dart';
import 'open_meteo_client.dart';
import 'pirate_weather_client.dart';
import 'weather_api_client.dart';

export '../models/heat_acclimation.dart' show WeatherSnapshotData;

/// A weather provider with Open-Meteo-shaped hourly output.
abstract class GlobalWeatherClient {
  String get serviceName;

  Future<WeatherSnapshotData> fetchSnapshot({
    required double latitude,
    required double longitude,
    required DateTime at,
  });

  Future<OpenMeteoResult> fetchHourlyWeather({
    required double latitude,
    required double longitude,
    required DateTime start,
    required DateTime end,
    double? elevation,
  });
}

/// Spreads requests over several free weather APIs. A provider that errors
/// is paused for 24 h; Bright Sky (DWD) is preferred inside Germany.
class WeatherRouter extends GlobalWeatherClient {
  WeatherRouter({List<GlobalWeatherClient>? clients})
    : _clients =
          clients ??
          [
            BrightSkyClient(),
            OpenMeteoClient(),
            // Optional services: only with their keys in the build.
            if (Secrets.pirateWeatherKey.isNotEmpty) PirateWeatherClient(),
            if (Secrets.weatherApiKey.isNotEmpty) WeatherApiClient(),
          ];

  final List<GlobalWeatherClient> _clients;
  final Map<String, DateTime> _pausedUntil = {};

  @override
  String get serviceName => 'Weather';

  static bool _inGermany(double lat, double lng) =>
      lat >= 47.3 && lat <= 55.1 && lng >= 5.9 && lng <= 15.1;

  List<GlobalWeatherClient> _available(double lat, double lng) {
    final now = DateTime.now();
    bool notPaused(GlobalWeatherClient c) {
      final until = _pausedUntil[c.serviceName];
      return until == null || now.isAfter(until);
    }

    final regional = _clients
        .where(
          (c) => c is BrightSkyClient && notPaused(c) && _inGermany(lat, lng),
        )
        .toList();
    final global =
        _clients.where((c) => c is! BrightSkyClient && notPaused(c)).toList()
          ..shuffle(Random());
    return [...regional, ...global];
  }

  void _pause(GlobalWeatherClient c, Object error) {
    log('[Weather] ${c.serviceName} error: $error');
    _pausedUntil[c.serviceName] = DateTime.now().add(const Duration(days: 1));
    log('[Weather] ${c.serviceName} paused for 24h after error');
  }

  @override
  Future<WeatherSnapshotData> fetchSnapshot({
    required double latitude,
    required double longitude,
    required DateTime at,
  }) async {
    for (final c in _available(latitude, longitude)) {
      try {
        log('[Weather] fetchSnapshot via ${c.serviceName}');
        return await c.fetchSnapshot(
          latitude: latitude,
          longitude: longitude,
          at: at,
        );
      } catch (e) {
        _pause(c, e);
      }
    }
    throw Exception('All weather services failed or paused');
  }

  @override
  Future<OpenMeteoResult> fetchHourlyWeather({
    required double latitude,
    required double longitude,
    required DateTime start,
    required DateTime end,
    double? elevation,
  }) async {
    final candidates = _available(latitude, longitude);
    if (end.difference(start).inDays >= 7) {
      candidates.sort(
        (a, b) => (a is OpenMeteoClient ? 0 : 1).compareTo(
          b is OpenMeteoClient ? 0 : 1,
        ),
      );
    }
    OpenMeteoResult? longest;
    for (final c in candidates) {
      try {
        log('[Weather] fetchHourlyWeather via ${c.serviceName}');
        final result = await c.fetchHourlyWeather(
          latitude: latitude,
          longitude: longitude,
          start: start,
          end: end,
          elevation: elevation,
        );
        if (end.difference(start).inDays < 7) return result;
        if (longest == null || result.points.length > longest.points.length) {
          longest = result;
        }
        final lastDay = DateTime(end.year, end.month, end.day);
        if (result.points.any((p) => !p.time.isBefore(lastDay))) return result;
      } catch (e) {
        _pause(c, e);
      }
    }
    if (longest != null) return longest;
    throw Exception('All weather services failed or paused');
  }

  Future<List<OpenMeteoResult>> forecastComparison({
    required double latitude,
    required double longitude,
    required DateTime start,
    required DateTime end,
    required String primarySource,
  }) async {
    final results = await Future.wait(
      _available(
        latitude,
        longitude,
      ).where((c) => c.serviceName != primarySource).map((client) async {
        try {
          final limitedEnd = client is WeatherApiClient
              ? DateTime(start.year, start.month, start.day + 2)
              : client is BrightSkyClient
              ? DateTime(start.year, start.month, start.day + 2)
              : end;
          return await client
              .fetchHourlyWeather(
                latitude: latitude,
                longitude: longitude,
                start: start,
                end: limitedEnd,
              )
              .timeout(const Duration(seconds: 15));
        } catch (_) {
          return null;
        }
      }),
    );
    return results.whereType<OpenMeteoResult>().toList();
  }
}
