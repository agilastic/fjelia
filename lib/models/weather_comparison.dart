import '../services/open_meteo_client.dart';

class WeatherForecastSeries {
  const WeatherForecastSeries(this.source, this.points);
  final String source;
  final List<OpenMeteoPoint> points;
}

class WeatherSpread {
  const WeatherSpread(this.time, this.low, this.high);
  final DateTime time;
  final double low, high;
}

class WeatherComparison {
  WeatherComparison(
    List<OpenMeteoPoint> primary,
    String source,
    List<OpenMeteoResult> alternatives,
  ) {
    series = [WeatherForecastSeries(source, primary)];
    spread = [];
    if (primary.isEmpty) return;
    final start = primary.first.time, end = primary.last.time;
    final seen = {source};
    final sorted = alternatives.toList()
      ..sort((a, b) => a.source.compareTo(b.source));
    for (final result in sorted) {
      if (!seen.add(result.source)) continue;
      final points =
          result.points
              .where(
                (p) =>
                    p.temperatureC.isFinite &&
                    !p.time.isBefore(start) &&
                    !p.time.isAfter(end),
              )
              .toList()
            ..sort((a, b) => a.time.compareTo(b.time));
      if (points.isNotEmpty) {
        series.add(WeatherForecastSeries(result.source, points));
      }
    }
    final hours = <int, List<double>>{};
    final timestamps = <int, DateTime>{};
    for (final provider in series) {
      final unique = <int, double>{};
      for (final p in provider.points) {
        if (p.temperatureC.isFinite) {
          timestamps.putIfAbsent(
            p.time.millisecondsSinceEpoch ~/ 3600000,
            () => p.time,
          );
          unique.putIfAbsent(
            p.time.millisecondsSinceEpoch ~/ 3600000,
            () => p.temperatureC,
          );
        }
      }
      for (final entry in unique.entries) {
        hours.putIfAbsent(entry.key, () => []).add(entry.value);
      }
    }
    for (final entry in hours.entries) {
      if (entry.value.length < 2) continue;
      entry.value.sort();
      spread.add(
        WeatherSpread(
          timestamps[entry.key]!,
          entry.value.first,
          entry.value.last,
        ),
      );
    }
    spread.sort((a, b) => a.time.compareTo(b.time));
  }
  late final List<WeatherForecastSeries> series;
  late final List<WeatherSpread> spread;
}

/// Mark only the actual current hour in a single-day forecast.
int? currentWeatherHourIndex(
  List<OpenMeteoPoint> points,
  DateTime now, {
  bool overview = false,
}) {
  if (overview) return null;
  final index = points.indexWhere(
    (p) =>
        !p.time.isAfter(now) &&
        now.isBefore(p.time.add(const Duration(hours: 1))),
  );
  return index < 0 ? null : index;
}
