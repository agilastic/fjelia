import '../services/weather_geocoding_service.dart';
import '../models/weather_place.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/heat_acclimation_settings.dart';
import '../services/location_service.dart';
import 'heat_acclimation_provider.dart';
import 'weather_radar_provider.dart';

final weatherLocationActionsProvider = Provider(
  (ref) => WeatherLocationActions(ref),
);

class WeatherLocationActions {
  WeatherLocationActions(this.ref);
  final Ref ref;
  void _refresh() {
    ref.invalidate(heatPreferredLocationProvider);
    ref.invalidate(heatHourlyWeatherProvider);
    ref.invalidate(heatTodayStateProvider);
    ref.invalidate(weatherRadarProvider);
  }

  Future<List<WeatherPlace>> searchCities(String query) =>
      ref.read(weatherGeocodingServiceProvider).search(query);
  Future<void> useCity(WeatherPlace place) =>
      saveFixed('${place.latitude}', '${place.longitude}', name: place.name);

  Future<void> useNone() async {
    await ref
        .read(heatAcclimationSettingsProvider.notifier)
        .setLocationMode(HeatLocationMode.none);
    _refresh();
  }

  Future<void> saveFixed(
    String latitude,
    String longitude, {
    String? name,
  }) async {
    final lat = double.tryParse(latitude.trim().replaceAll(',', '.'));
    final lng = double.tryParse(longitude.trim().replaceAll(',', '.'));
    if (lat == null ||
        lng == null ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat.abs() > 90 ||
        lng.abs() > 180) {
      throw ArgumentError(
        'Enter latitude from −90 to 90 and longitude from −180 to 180.',
      );
    }
    await ref
        .read(heatAcclimationSettingsProvider.notifier)
        .setFixedLocation(lat, lng, name: name);
    _refresh();
  }

  Future<CurrentLocationData> useCurrent() async {
    final location = await ref
        .read(locationServiceProvider)
        .getCurrentLocation();
    if (location == null) {
      throw StateError(
        'Location unavailable. Allow location access in iOS Settings, or enter a fixed location.',
      );
    }
    await ref
        .read(heatAcclimationSettingsProvider.notifier)
        .setLocationMode(HeatLocationMode.current);
    _refresh();
    return location;
  }
}

final weatherGeocodingServiceProvider = Provider((ref) {
  final service = WeatherGeocodingService();
  ref.onDispose(service.dispose);
  return service;
});
final weatherPlaceNameProvider = FutureProvider<String?>((ref) async {
  final settings = await ref.watch(heatAcclimationSettingsProvider.future);
  if (settings.locationMode == HeatLocationMode.none) return null;
  if (settings.locationMode == HeatLocationMode.fixed &&
      settings.fixedLocationName != null) {
    return settings.fixedLocationName;
  }
  final location = await ref.watch(heatPreferredLocationProvider.future);
  if (location == null) return null;
  return ref
      .read(weatherGeocodingServiceProvider)
      .reverse(location.latitude, location.longitude);
});
