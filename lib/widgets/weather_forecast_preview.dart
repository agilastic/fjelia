import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/open_meteo_client.dart';
import 'app_widgets.dart';

/// A temperature preview whose horizontal scale stays at the next 24 hours,
/// including when the provider has fewer readings or some hours are missing.
class WeatherForecastPreview extends StatelessWidget {
  const WeatherForecastPreview({
    super.key,
    required this.points,
    required this.start,
  });

  final List<OpenMeteoPoint> points;
  final DateTime start;

  @override
  Widget build(BuildContext context) {
    final end = start.add(const Duration(hours: 24));
    final hours =
        points
            .where(
              (point) =>
                  point.temperatureC.isFinite &&
                  !point.time.isBefore(start) &&
                  !point.time.isAfter(end),
            )
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    if (hours.isEmpty) {
      return const SizedBox(
        height: 110,
        child: Center(
          child: Text(
            'Hourly forecast unavailable',
            style: TextStyle(color: muted),
          ),
        ),
      );
    }
    final low = (hours.map((p) => p.temperatureC).reduce(math.min) - 1)
        .floorToDouble();
    final high = (hours.map((p) => p.temperatureC).reduce(math.max) + 1)
        .ceilToDouble();
    const temperatureColor = Colors.deepOrangeAccent;
    const labelStyle = TextStyle(fontSize: 9, color: muted);
    return Semantics(
      label: 'Temperature forecast for the next 24 hours',
      child: SizedBox(
        height: 110,
        child: IgnorePointer(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 24,
              minY: low,
              maxY: high,
              clipData: const FlClipData.all(),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              gridData: FlGridData(
                verticalInterval: 6,
                horizontalInterval: (high - low) / 2,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colors.white10, strokeWidth: .6),
                getDrawingVerticalLine: (_) =>
                    const FlLine(color: Colors.white10, strokeWidth: .6),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: (high - low) / 2,
                    getTitlesWidget: (value, _) =>
                        Text('${value.round()}°', style: labelStyle),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 6,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      fitInside: SideTitleFitInsideData.fromTitleMeta(
                        meta,
                        enabled: true,
                      ),
                      child: Text(
                        value == 0 ? 'Now' : '${value.round()}h',
                        style: labelStyle,
                      ),
                    ),
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (final point in hours)
                      FlSpot(
                        point.time.difference(start).inMilliseconds / 3600000,
                        point.temperatureC,
                      ),
                  ],
                  color: temperatureColor,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        temperatureColor.withValues(alpha: .18),
                        temperatureColor.withValues(alpha: .01),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
