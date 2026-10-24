import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/heat_acclimation.dart';
import '../services/bright_sky_client.dart';
import '../services/global_weather_client.dart';
import '../services/heat_acclimation_service.dart';
import '../services/heat_acclimation_settings.dart';
import '../services/location_service.dart';
import '../services/open_meteo_client.dart';
import '../services/pirate_weather_client.dart';
import '../services/weather_api_client.dart';
import 'database_provider.dart';

final weatherRouterProvider = Provider<WeatherRouter>(
  (ref) => WeatherRouter(
    clients: [
      OpenMeteoClient(),
      PirateWeatherClient(),
      BrightSkyClient(),
      WeatherApiClient(),
    ],
  ),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final heatAcclimationSettingsStoreProvider =
    Provider<HeatAcclimationSettingsStore>(
      (ref) => const HeatAcclimationSettingsStore(),
    );

final heatAcclimationServiceProvider = Provider<HeatAcclimationService>(
  (ref) => HeatAcclimationService(
    ref.read(databaseProvider),
    weather: ref.read(weatherRouterProvider),
    location: ref.read(locationServiceProvider),
    settings: ref.read(heatAcclimationSettingsStoreProvider),
  ),
);

final heatAcclimationSettingsProvider =
    AsyncNotifierProvider<
      HeatAcclimationSettingsNotifier,
      HeatAcclimationSettings
    >(HeatAcclimationSettingsNotifier.new);

class HeatAcclimationSettingsNotifier
    extends AsyncNotifier<HeatAcclimationSettings> {
  HeatAcclimationSettingsStore get _store =>
      ref.read(heatAcclimationSettingsStoreProvider);

  @override
  Future<HeatAcclimationSettings> build() => _store.load();

  Future<void> setEnabled(bool enabled) async {
    await _store.saveEnabled(enabled);
    final current = state.valueOrNull ?? const HeatAcclimationSettings();
    state = AsyncData(current.copyWith(enabled: enabled));
  }

  Future<void> setLocationMode(HeatLocationMode mode) async {
    await _store.saveLocationMode(mode);
    final current = state.valueOrNull ?? const HeatAcclimationSettings();
    state = AsyncData(current.copyWith(locationMode: mode));
  }

  Future<void> setFixedLocation(
    double latitude,
    double longitude, {
    String? name,
  }) async {
    await _store.saveFixedLocation(latitude, longitude, name: name);
    await _store.saveLocationMode(HeatLocationMode.fixed);
    state = AsyncData(await _store.load());
  }
}

final heatTodayStateProvider = FutureProvider<HeatDailyStateData?>((ref) async {
  final settings = await ref.watch(heatAcclimationSettingsProvider.future);
  if (!settings.enabled) return null;
  return ref.read(heatAcclimationServiceProvider).getTodayState();
});

final heatForecastProvider = FutureProvider.family<HeatPlanForecast?, DateTime>(
  (ref, at) async {
    final settings = await ref.watch(heatAcclimationSettingsProvider.future);
    if (!settings.enabled) return null;
    return ref
        .read(heatAcclimationServiceProvider)
        .forecastForCurrentLocation(at);
  },
);

final heatPreferredLocationProvider = FutureProvider<CurrentLocationData?>((
  ref,
) async {
  final settings = await ref.watch(heatAcclimationSettingsProvider.future);
  if (settings.locationMode == HeatLocationMode.none) return null;
  if (settings.locationMode == HeatLocationMode.fixed &&
      settings.fixedLatitude != null &&
      settings.fixedLongitude != null) {
    return CurrentLocationData(
      latitude: settings.fixedLatitude!,
      longitude: settings.fixedLongitude!,
      timestamp: DateTime.now(),
    );
  }
  return ref.read(locationServiceProvider).getCurrentLocation();
});

/// Hourly weather for the next 14 days at the preferred location. Also caches
/// today's sunset hour for the evening-briefing schedule.
final heatHourlyWeatherProvider = FutureProvider<OpenMeteoResult?>((ref) async {
  await ref.watch(heatAcclimationSettingsProvider.future);
  final location = await ref.watch(heatPreferredLocationProvider.future);
  if (location == null) return null;
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final result = await ref
      .read(weatherRouterProvider)
      .fetchHourlyWeather(
        latitude: location.latitude,
        longitude: location.longitude,
        start: start,
        end: DateTime(start.year, start.month, start.day + 13),
      );
  final key =
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
  final sunset = result.sunset[key];
  if (sunset != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fjelia_sunset_hour', sunset.hour);
  }
  return result;
});

final heatWorkoutContextProvider =
    FutureProvider.family<HeatWorkoutContextData?, String>((
      ref,
      activityId,
    ) async {
      final settings = await ref.watch(heatAcclimationSettingsProvider.future);
      if (!settings.enabled) return null;
      final db = ref.read(databaseProvider);
      final service = ref.read(heatAcclimationServiceProvider);

      HeatWorkoutContextData? fromRow(dynamic row) => row == null
          ? null
          : HeatWorkoutContextData(
              activityId: row.activityId as String,
              activityStart: row.activityStart as DateTime,
              source: row.source as String,
              isOutdoor: row.isOutdoor as bool,
              qualifies: row.qualifies as bool,
              durationMinutes: row.durationMinutes as double,
              temperatureC: row.temperatureC as double?,
              humidityPct: row.humidityPct as double?,
              pressureHpa: row.pressureHpa as double?,
              wetBulbC: row.wetBulbC as double?,
              scoreBefore: row.scoreBefore as double,
              scoreAfter: row.scoreAfter as double,
              weatherCacheKey: row.weatherCacheKey as String?,
              rawJson: row.rawJson as String?,
            );

      final existing = await db.getHeatWorkoutContextForActivity(activityId);
      if (existing != null) return fromRow(existing);
      final activity = await db.getActivityById(activityId);
      if (activity == null) return null;
      await service.processActivity(activity);
      return fromRow(await db.getHeatWorkoutContextForActivity(activityId));
    });

final heatHistoryProvider =
    FutureProvider.family<List<HeatDailyStateData>, int>((ref, days) async {
      final settings = await ref.watch(heatAcclimationSettingsProvider.future);
      if (!settings.enabled) return const [];
      final rows = await ref.read(databaseProvider).getHeatStateRange(days);
      return rows
          .map(
            (r) => HeatDailyStateData(
              date: r.date,
              score: r.score,
              status: HeatStatus.values.byName(r.status),
              decayApplied: r.decayApplied,
              workoutGain: r.workoutGain,
              lastActivityId: r.lastActivityId,
              recommendation: r.recommendation,
              updatedAt: r.updatedAt,
            ),
          )
          .toList();
    });
