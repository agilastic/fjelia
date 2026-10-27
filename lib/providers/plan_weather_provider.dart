import '../services/heat_acclimation_settings.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/open_meteo_client.dart';
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
}

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
