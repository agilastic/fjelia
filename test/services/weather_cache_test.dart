import 'package:fjelia/services/global_weather_client.dart';
import 'package:fjelia/services/open_meteo_client.dart';
import 'package:fjelia/services/weather_cache.dart';
import 'package:flutter_test/flutter_test.dart';

/// A weather service that answers every hour with [temperature] and counts
/// what it was asked for.
class _Service extends GlobalWeatherClient {
  double temperature = 10;
  final requests = <(DateTime, DateTime)>[];

  @override
  String get serviceName => 'Fake';

  @override
  Future<WeatherSnapshotData> fetchSnapshot({
    required double latitude,
    required double longitude,
    required DateTime at,
  }) => throw UnimplementedError();

  @override
  Future<OpenMeteoResult> fetchHourlyWeather({
    required double latitude,
    required double longitude,
    required DateTime start,
    required DateTime end,
    double? elevation,
  }) async {
    requests.add((start, end));
    return OpenMeteoResult(
      points: [
        for (
          var t = start;
          t.isBefore(end.add(const Duration(days: 1)));
          t = t.add(const Duration(hours: 1))
        )
          OpenMeteoPoint(
            time: t,
            temperatureC: temperature,
            humidityPct: 70,
            pressureHpa: 1013,
            precipitationMm: 0.2,
            precipitationProbability: 30,
            windSpeedKmh: 12,
            windDirection: 270,
            cloudCover: 50,
            uvIndex: 1,
            weatherCode: 3,
            sunshineSeconds: 600,
          ),
      ],
      sunrise: {'2026-11-16': DateTime(2026, 11, 16, 7, 30)},
      sunset: {'2026-11-16': DateTime(2026, 11, 16, 16, 40)},
      fetchedAt: DateTime(2026, 11, 16, 9),
      rawJson: '{}',
      source: 'Fake',
      elevation: 120,
    );
  }
}

void main() {
  late DateTime now;
  late _Service service;
  late WeatherRouter router;

  setUp(() {
    now = DateTime(2026, 11, 16, 9);
    service = _Service();
    router = WeatherRouter(
      clients: [service],
      cache: WeatherCache(store: MemoryWeatherCacheStore(), now: () => now),
      now: () => now,
    );
  });

  Future<OpenMeteoResult> fetch(DateTime start, DateTime end) =>
      router.fetchHourlyWeather(
        latitude: 52.52,
        longitude: 13.40,
        start: start,
        end: end,
      );

  test('days without today come from the cache for four hours', () async {
    final start = DateTime(2026, 11, 2), end = DateTime(2026, 11, 9);
    await fetch(start, end);
    now = now.add(const Duration(hours: 3, minutes: 59));
    final again = await fetch(start, end);
    expect(service.requests, hasLength(1));
    // Nothing is lost on the way through the cache.
    final p = again.points.first;
    expect(p.temperatureC, 10);
    expect(p.precipitationProbability, 30);
    expect(p.sunshineSeconds, 600);
    expect(again.sunset['2026-11-16'], DateTime(2026, 11, 16, 16, 40));
    expect(again.elevation, 120);

    now = now.add(const Duration(minutes: 1));
    await fetch(start, end);
    expect(service.requests, hasLength(2));
  });

  test('today is always asked for again, the other days come from the '
      'cache', () async {
    final start = DateTime(2026, 11, 16), end = DateTime(2026, 11, 29);
    await fetch(start, end);
    service.temperature = 4;
    now = now.add(const Duration(hours: 2));
    final result = await fetch(start, end);
    expect(service.requests, hasLength(2));
    // Only today was requested the second time.
    expect(service.requests.last.$1, DateTime(2026, 11, 16));
    expect(service.requests.last.$2, DateTime(2026, 11, 17));
    final today = result.points.where((p) => p.time.day == 16).toList();
    final later = result.points.where((p) => p.time.day == 20).toList();
    expect(today, hasLength(24));
    expect(today.every((p) => p.temperatureC == 4), isTrue);
    expect(later.every((p) => p.temperatureC == 10), isTrue);
    // Every hour once, in order.
    final times = [for (final p in result.points) p.time];
    expect(times.toSet(), hasLength(times.length));
    expect([...times]..sort(), times);
  });
}
