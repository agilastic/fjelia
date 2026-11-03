import '../services/heat_acclimation_settings.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/open_meteo_client.dart';
import '../services/rain_nowcast.dart';
import '../utils/log.dart';
import 'heat_acclimation_provider.dart';

class PlanWeatherData {
  PlanWeatherData(this.result, DateTime now) {
    final sorted = result.points.toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    current = sorted.isEmpty
        ? null
        : sorted.reduce(
            (a, b) =>
                a.time.difference(now).abs() < b.time.difference(now).abs()
                ? a
                : b,
          );
  }
  final OpenMeteoResult result;
  late final OpenMeteoPoint? current;
  List<PlanWeatherDay> sevenDays(DateTime from) => [
    for (var i = 0; i < 7; i++)
      PlanWeatherDay(
        DateTime(from.year, from.month, from.day + i),
        pointsFor(DateTime(from.year, from.month, from.day + i), false),
      ),
  ];
  double? get wetBulb => current == null
      ? null
      : OpenMeteoClient.wetBulbC(current!.temperatureC, current!.humidityPct);
  int availableDays(DateTime day, int days) => pointsFor(
    day,
    days > 1,
    forecastDays: days,
  ).map((p) => DateTime(p.time.year, p.time.month, p.time.day)).toSet().length;
  List<OpenMeteoPoint> pointsFor(
    DateTime day,
    bool week, {
    int forecastDays = 7,
  }) {
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(
      start.year,
      start.month,
      start.day + (week ? forecastDays : 1),
    );
    return result.points
        .where((p) => !p.time.isBefore(start) && p.time.isBefore(end))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }
}

class PlanWeatherDay {
  PlanWeatherDay(this.date, List<OpenMeteoPoint> points) {
    if (points.isEmpty) return;
    final temperatures = points
        .map((p) => p.temperatureC)
        .where((v) => v.isFinite)
        .toList();
    if (temperatures.isNotEmpty) {
      minC = temperatures.reduce((a, b) => a < b ? a : b);
      maxC = temperatures.reduce((a, b) => a > b ? a : b);
    }
    rainMm = points.fold<double>(0, (sum, p) => sum + p.precipitationMm);
    // Drizzle often leaves (almost) nothing in the gauge, but the weather
    // code still says it was or will be wet.
    wet = points.any((p) => isWetWeatherCode(p.weatherCode));
    windKmh = points.map((p) => p.windSpeedKmh).reduce((a, b) => a > b ? a : b);
    final values = points
        .map((p) => p.uvIndex)
        .whereType<num>()
        .map((v) => v.toDouble())
        .toList();
    uv = values.isEmpty ? null : values.reduce((a, b) => a > b ? a : b);
  }
  final DateTime date;
  double? minC, maxC, rainMm, windKmh, uv;

  /// Rain, drizzle, showers, snow or thunder at some hour of the day.
  bool wet = false;
}

/// The day's rain as the lowest and highest total of all forecasts. Hours
/// before [now] count as [primary] has them (in Germany: measured); the
/// rest per forecast that covers all of them. Null with fewer than two.
({double low, double high})? dailyRainRange(
  DateTime day,
  OpenMeteoResult primary,
  List<OpenMeteoResult> others,
  DateTime now,
) {
  final start = DateTime(day.year, day.month, day.day);
  final end = DateTime(day.year, day.month, day.day + 1);
  final hourNow = DateTime(now.year, now.month, now.day, now.hour);
  final cut = hourNow.isAfter(start) ? hourNow : start;
  if (!cut.isBefore(end)) return null;
  int key(DateTime t) => t.millisecondsSinceEpoch ~/ 3600000;
  var past = 0.0;
  final future = <int>{};
  for (final p in primary.points) {
    if (p.time.isBefore(start) || !p.time.isBefore(end)) continue;
    if (p.time.isBefore(cut)) {
      past += p.precipitationMm;
    } else {
      future.add(key(p.time));
    }
  }
  if (future.isEmpty) return null;
  final totals = <double>[];
  for (final result in [primary, ...others]) {
    final byHour = <int, double>{};
    for (final p in result.points) {
      final k = key(p.time);
      if (future.contains(k)) byHour.putIfAbsent(k, () => p.precipitationMm);
    }
    if (byHour.length == future.length) {
      totals.add(byHour.values.fold(0.0, (a, b) => a + b));
    }
  }
  if (totals.length < 2) return null;
  totals.sort();
  return (low: past + totals.first, high: past + totals.last);
}

/// WMO weather codes with precipitation: drizzle (51–57), rain (61–67),
/// snow (71–77), showers (80–86) and thunderstorms (95–99).
bool isWetWeatherCode(int? code) =>
    code != null &&
    ((code >= 51 && code <= 67) ||
        (code >= 71 && code <= 86) ||
        (code >= 95 && code <= 99));

final planWeatherProvider = Provider<AsyncValue<PlanWeatherData?>>(
  (ref) => ref
      .watch(heatHourlyWeatherProvider)
      .whenData(
        (result) =>
            result == null ? null : PlanWeatherData(result, DateTime.now()),
      ),
);

final weatherLocationEnabledProvider = Provider<bool>(
  (ref) =>
      ref.watch(heatAcclimationSettingsProvider).valueOrNull?.locationMode !=
      HeatLocationMode.none,
);

final weatherComparisonProvider = FutureProvider<List<OpenMeteoResult>>((
  ref,
) async {
  final primary = await ref.watch(heatHourlyWeatherProvider.future);
  final location = await ref.watch(heatPreferredLocationProvider.future);
  if (primary == null || location == null) return [];
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  return ref
      .read(weatherRouterProvider)
      .forecastComparison(
        latitude: location.latitude,
        longitude: location.longitude,
        start: start,
        end: DateTime(start.year, start.month, start.day + 13),
        primarySource: primary.source,
      );
});

/// The DWD radar for the next hour or two at the weather location (Germany
/// only). [RainNowcastLine] refreshes it every 5 minutes while it shows.
final rainNowcastProvider = FutureProvider.autoDispose<RainNowcast?>((
  ref,
) async {
  final location = await ref.watch(heatPreferredLocationProvider.future);
  if (location == null ||
      !inDwdRadarArea(location.latitude, location.longitude)) {
    return null;
  }
  try {
    return await fetchRainNowcast(location.latitude, location.longitude);
  } catch (e) {
    log('[Weather] radar unavailable: ${e.runtimeType}');
    return null;
  }
});
