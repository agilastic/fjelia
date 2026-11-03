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
  /// [now]: hours before the current one get no range. They have happened,
  /// and in Germany the main series holds what was measured.
  WeatherComparison(
    List<OpenMeteoPoint> primary,
    String source,
    List<OpenMeteoResult> alternatives, {
    DateTime? now,
  }) {
    series = [WeatherForecastSeries(source, primary)];
    spread = [];
    rainSpread = [];
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
    final from = now == null ? null : _hour(now);
    spread = _spreadOf((p) => p.temperatureC, from);
    rainSpread = _spreadOf((p) => p.precipitationMm, from);
  }

  static int _hour(DateTime t) => t.millisecondsSinceEpoch ~/ 3600000;

  /// Lowest and highest value of [value] across the forecasts, per hour
  /// that at least two of them cover.
  List<WeatherSpread> _spreadOf(
    double Function(OpenMeteoPoint) value,
    int? fromHour,
  ) {
    final hours = <int, List<double>>{};
    final timestamps = <int, DateTime>{};
    for (final provider in series) {
      final unique = <int, double>{};
      for (final p in provider.points) {
        final v = value(p);
        final hour = _hour(p.time);
        if (!v.isFinite || (fromHour != null && hour < fromHour)) continue;
        timestamps.putIfAbsent(hour, () => p.time);
        unique.putIfAbsent(hour, () => v);
      }
      for (final entry in unique.entries) {
        hours.putIfAbsent(entry.key, () => []).add(entry.value);
      }
    }
    return [
      for (final entry in hours.entries)
        if (entry.value.length >= 2)
          WeatherSpread(
            timestamps[entry.key]!,
            entry.value.reduce((a, b) => a < b ? a : b),
            entry.value.reduce((a, b) => a > b ? a : b),
          ),
    ]..sort((a, b) => a.time.compareTo(b.time));
  }

  late final List<WeatherForecastSeries> series;

  /// Temperature range per hour.
  late List<WeatherSpread> spread;

  /// Rain range per hour, mm.
  late List<WeatherSpread> rainSpread;
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
