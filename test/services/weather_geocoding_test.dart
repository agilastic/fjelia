import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fjelia/services/weather_geocoding_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('city lookup returns disambiguated names and coordinates', () async {
    final service = WeatherGeocodingService(
      client: MockClient((request) async {
        expect(request.url.queryParameters['name'], 'Hannover');
        return http.Response(
          jsonEncode({
            'results': [
              {
                'name': 'Hannover',
                'admin1': 'Lower Saxony',
                'country': 'Germany',
                'latitude': 52.37,
                'longitude': 9.73,
              },
            ],
          }),
          200,
        );
      }),
    );
    addTearDown(service.dispose);
    final places = await service.search(' Hannover ');
    expect(places.single.name, 'Hannover, Lower Saxony, Germany');
    expect(places.single.latitude, 52.37);
    expect(await service.search('H'), isEmpty);
  });
  test(
    'coordinate names are cached rather than requested repeatedly',
    () async {
      var calls = 0;
      final service = WeatherGeocodingService(
        client: MockClient((request) async {
          calls++;
          expect(request.headers['User-Agent'], contains('Fjelia'));
          return http.Response(
            jsonEncode({
              'address': {'town': 'Sa Pobla', 'country': 'Spain'},
            }),
            200,
          );
        }),
      );
      addTearDown(service.dispose);
      expect(await service.reverse(39.77, 3.02), 'Sa Pobla, Spain');
      expect(await service.reverse(39.77, 3.02), 'Sa Pobla, Spain');
      expect(calls, 1);
    },
  );
}
