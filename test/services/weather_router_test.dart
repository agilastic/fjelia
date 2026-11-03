import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fjelia/providers/plan_weather_provider.dart';
import 'package:fjelia/services/bright_sky_client.dart';
import 'package:fjelia/services/global_weather_client.dart';
import 'package:fjelia/services/open_meteo_client.dart';

// Hemmingen, near Hannover.
const _lat = 52.32, _lng = 9.74;
final _start = DateTime(2026, 11, 2);

/// DWD for 2 Nov 2026 as measured at Hannover-Kirchrode: drizzle all day,
/// 3.2 mm in the gauge; then two forecast days.
String _brightSky() {
  final rain = {
    7: .2,
    8: .8,
    9: .6,
    11: .3,
    12: .5,
    13: .1,
    14: .2,
    16: .2,
    17: .1,
    18: .2,
  };
  return jsonEncode({
    'weather': [
      for (var h = 0; h < 72; h++)
        {
          'timestamp': DateTime(2026, 11, 2, h).toUtc().toIso8601String(),
          'temperature': 8.0,
          'relative_humidity': 95.0,
          'pressure_msl': 1012.0,
          'precipitation': h < 24 ? (rain[h] ?? 0.0) : 0.0,
          'wind_speed': 10.0,
          'wind_direction': 220.0,
          'cloud_cover': 100,
          'condition': h >= 5 && h <= 18 ? 'rain' : 'dry',
          'icon': 'cloudy',
        },
    ],
  });
}

/// Open-Meteo's model for the same place: almost no rain, but 14 days.
String _openMeteo() => jsonEncode({
  'hourly': {
    'time': [
      for (var h = 0; h < 14 * 24; h++)
        DateTime(2026, 11, 2, h).toIso8601String().substring(0, 16),
    ],
    'temperature_2m': [for (var h = 0; h < 14 * 24; h++) 9.0],
    'relative_humidity_2m': [for (var h = 0; h < 14 * 24; h++) 90.0],
    'precipitation': [for (var h = 0; h < 14 * 24; h++) h == 9 ? .1 : 0.0],
    'weather_code': [for (var h = 0; h < 14 * 24; h++) 3],
  },
  'daily': {'time': <String>[], 'sunrise': <String>[], 'sunset': <String>[]},
});

http.Client _serving(String body, {int status = 200}) =>
    MockClient((_) async => http.Response(body, status));

void main() {
  group('Bright Sky weather codes', () {
    test('rain that barely fills the gauge is drizzle', () {
      expect(
        BrightSkyClient.wmoCode(condition: 'rain', precipitationMm: .1),
        51,
      );
      expect(
        BrightSkyClient.wmoCode(condition: 'rain', precipitationMm: .8),
        61,
      );
      expect(
        BrightSkyClient.wmoCode(condition: 'rain', precipitationMm: 4),
        63,
      );
    });

    test('dry hours follow the icon or the cloud cover', () {
      expect(BrightSkyClient.wmoCode(condition: 'dry', icon: 'clear-day'), 0);
      expect(BrightSkyClient.wmoCode(condition: 'dry', icon: 'cloudy'), 3);
      expect(BrightSkyClient.wmoCode(condition: 'dry', cloudCover: 40), 2);
      expect(BrightSkyClient.wmoCode(condition: 'snow'), 71);
      expect(BrightSkyClient.wmoCode(condition: 'thunderstorm'), 95);
    });
  });

  group('WeatherRouter', () {
    Future<OpenMeteoResult> week({
      required http.Client dwd,
      required http.Client global,
      double lat = _lat,
      double lng = _lng,
    }) =>
        WeatherRouter(
          clients: [
            BrightSkyClient(client: dwd),
            OpenMeteoClient(client: global),
          ],
        ).fetchHourlyWeather(
          latitude: lat,
          longitude: lng,
          start: _start,
          end: DateTime(2026, 11, 15),
        );

    test(
      'in Germany DWD gives the hours it has, Open-Meteo the rest',
      () async {
        final result = await week(
          dwd: _serving(_brightSky()),
          global: _serving(_openMeteo()),
        );
        expect(result.source, 'Bright Sky (DWD)');
        final today = PlanWeatherData(
          result,
          DateTime(2026, 11, 2, 21),
        ).sevenDays(_start).first;
        // The measured 3.2 mm, not the model's 0.1 mm.
        expect(today.rainMm, closeTo(3.2, .001));
        expect(today.wet, isTrue);
        // Two weeks are still covered, by Open-Meteo after DWD's last hour.
        expect(
          result.points.last.time,
          DateTime(2026, 11, 2).add(const Duration(hours: 14 * 24 - 1)),
        );
        final hours = result.points.map((p) => p.time).toList();
        expect(hours.toSet().length, hours.length);
      },
    );

    test('without DWD the week comes from Open-Meteo', () async {
      final result = await week(
        dwd: _serving('down', status: 503),
        global: _serving(_openMeteo()),
      );
      expect(result.source, 'Open-Meteo');
    });

    test('outside Germany DWD is not asked', () async {
      var asked = false;
      final result = await week(
        dwd: MockClient((_) async {
          asked = true;
          return http.Response(_brightSky(), 200);
        }),
        global: _serving(_openMeteo()),
        lat: 48.86,
        lng: 2.35,
      );
      expect(asked, isFalse);
      expect(result.source, 'Open-Meteo');
    });
  });

  test('drizzle with nothing in the gauge still counts as wet', () {
    final day = PlanWeatherDay(DateTime(2026, 11, 3), [
      OpenMeteoPoint(
        time: DateTime(2026, 11, 3, 9),
        temperatureC: 8,
        humidityPct: 95,
        pressureHpa: 1012,
        precipitationMm: 0,
        windSpeedKmh: 10,
        windDirection: 220,
        weatherCode: 51,
      ),
    ]);
    expect(day.rainMm, 0);
    expect(day.wet, isTrue);
    expect(isWetWeatherCode(3), isFalse);
    expect(isWetWeatherCode(81), isTrue);
  });
}
