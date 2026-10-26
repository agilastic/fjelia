import '../services/heat_acclimation_settings.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/open_meteo_client.dart';
import 'heat_acclimation_provider.dart';

class PlanWeatherData {
  PlanWeatherData(this.result, DateTime now) {
    final sorted = result.points.toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    previewStart = DateTime(now.year, now.month, now.day, now.hour);
    final previewEnd = previewStart.add(const Duration(hours: 24));
    upcoming = sorted
        .where(
          (p) => !p.time.isBefore(previewStart) && !p.time.isAfter(previewEnd),
        )
        .toList();
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
  late final DateTime previewStart;
  late final List<OpenMeteoPoint> upcoming;
  late final OpenMeteoPoint? current;
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
