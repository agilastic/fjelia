import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather_place.dart';

class WeatherGeocodingService {
  WeatherGeocodingService({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  Future<void> _queue = Future.value();
  DateTime? _lastReverse;
  final _pending = <String, Future<String?>>{};
  void dispose() => _client.close();
  Future<List<WeatherPlace>> search(String query) async {
    final term = query.trim();
    if (term.length < 2) return [];
    final response = await _client
        .get(
          Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
            'name': term,
            'count': '6',
            'language': 'en',
            'format': 'json',
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw StateError('City search unavailable. Try again.');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return [
      for (final row in json['results'] as List? ?? [])
        WeatherPlace(
          name: [
            row['name'],
            row['admin1'],
            row['country'],
          ].whereType<String>().where((s) => s.isNotEmpty).toSet().join(', '),
          latitude: (row['latitude'] as num).toDouble(),
          longitude: (row['longitude'] as num).toDouble(),
        ),
    ];
  }

  Future<String?> reverse(double latitude, double longitude) {
    final key =
        'weather_city_${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';
    return _pending.putIfAbsent(
      key,
      () => _reverse(key, latitude, longitude).whenComplete(() {
        _pending.remove(key);
      }),
    );
  }

  Future<String?> _reverse(
    String key,
    double latitude,
    double longitude,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    if (cached != null) return cached;
    final previous = _queue;
    final done = Completer<void>();
    _queue = done.future;
    try {
      await previous;
      if (_lastReverse != null) {
        final remaining =
            const Duration(seconds: 1) -
            DateTime.now().difference(_lastReverse!);
        if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      }
      _lastReverse = DateTime.now();
      final response = await _client
          .get(
            Uri.https('nominatim.openstreetmap.org', '/reverse', {
              'format': 'jsonv2',
              'lat': '$latitude',
              'lon': '$longitude',
              'zoom': '10',
              'addressdetails': '1',
              'accept-language': 'en',
            }),
            headers: {'User-Agent': 'Fjelia/1.0 (de.ebeling-hoppe.fjelia)'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final address = json['address'] as Map?;
      final name = [
        address?['city'] ??
            address?['town'] ??
            address?['village'] ??
            address?['municipality'] ??
            json['name'],
        address?['country'],
      ].whereType<String>().where((s) => s.isNotEmpty).toSet().join(', ');
      if (name.isEmpty) return null;
      await prefs.setString(key, name);
      return name;
    } catch (_) {
      return null;
    } finally {
      done.complete();
    }
  }
}
