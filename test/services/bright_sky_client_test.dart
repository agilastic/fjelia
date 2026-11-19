import 'dart:convert';

import 'package:fjelia/services/bright_sky_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('forecast hours without humidity take it from the dew point', () async {
    final client = BrightSkyClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'weather': [
              {
                'timestamp': '2026-11-19T11:00:00+00:00',
                'temperature': 8.0,
                'relative_humidity': 70,
                'dew_point': 2.9,
              },
              {
                'timestamp': '2026-11-19T12:00:00+00:00',
                'temperature': 8.7,
                'relative_humidity': null,
                'dew_point': 7.7,
              },
            ],
          }),
          200,
        ),
      ),
    );
    final result = await client.fetchHourlyWeather(
      latitude: 52.32,
      longitude: 9.73,
      start: DateTime(2026, 11, 19),
      end: DateTime(2026, 11, 19),
    );
    expect(result.points.first.humidityPct, 70);
    expect(result.points.last.humidityPct, closeTo(93.4, .5));
  });
}
