import '../models/weather_comparison.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../services/open_meteo_client.dart';
import 'app_widgets.dart';

IconData weatherIcon(int? code) => switch (code) {
  null => Icons.cloud_outlined,
  0 || 1 => Icons.wb_sunny_outlined,
  2 => Icons.cloud_queue,
  3 => Icons.cloud,
  >= 95 => Icons.thunderstorm_outlined,
  >= 71 && <= 77 || 85 || 86 => Icons.ac_unit,
  >= 51 => Icons.grain,
  _ => Icons.foggy,
};

class WeatherForecastChart extends StatefulWidget {
  const WeatherForecastChart({
    super.key,
    required this.points,
    required this.week,
    this.comparison = const [],
    this.primarySource,
    this.fullscreen = false,
    this.plotHeight = 250,
    this.initialSelected,
  });
  final List<OpenMeteoPoint> points;
  final bool week;
  final List<OpenMeteoResult> comparison;
  final String? primarySource;
  final bool fullscreen;
  final double plotHeight;
  final int? initialSelected;
  @override
  State<WeatherForecastChart> createState() => _WeatherChartState();
}

class _WeatherChartState extends State<WeatherForecastChart> {
  int? selected;
  @override
  void initState() {
    super.initState();
    selected = widget.initialSelected;
  }

  @override
  void didUpdateWidget(covariant WeatherForecastChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) selected = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'No forecast for this day',
            style: TextStyle(color: muted),
          ),
        ),
      );
    }
    final comparison = WeatherComparison(
      widget.points,
      widget.primarySource ?? 'Forecast',
      widget.comparison,
    );
    final currentHour = currentWeatherHourIndex(
      widget.points,
      DateTime.now(),
      overview: widget.week,
    );
    final plot = LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        onTapUp: (e) => setState(
          () => selected =
              ((e.localPosition.dx - 32) /
                      (constraints.maxWidth - 64) *
                      widget.points.length)
                  .floor()
                  .clamp(0, widget.points.length - 1),
        ),
        child: SizedBox(
          height: widget.fullscreen ? double.infinity : widget.plotHeight,
          width: double.infinity,
          child: CustomPaint(
            painter: _WeatherPainter(
              widget.points,
              widget.week,
              selected,
              comparison,
              currentHour,
            ),
          ),
        ),
      ),
    );
    return Column(
      mainAxisSize: widget.fullscreen ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (!widget.fullscreen)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => WeatherChartFullscreen(
                    points: widget.points,
                    week: widget.week,
                    comparison: widget.comparison,
                    primarySource: widget.primarySource,
                    selected: selected,
                  ),
                ),
              ),
              icon: const Icon(Icons.fullscreen, size: 19),
              label: const Text('Fullscreen', style: TextStyle(fontSize: 11)),
            ),
          ),
        if (widget.fullscreen) Expanded(child: plot) else plot,
        if (selected != null && selected! < widget.points.length)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '${DateFormat('EEE HH:mm').format(widget.points[selected!].time)} · ${widget.points[selected!].temperatureC.toStringAsFixed(1)}°C · ${widget.points[selected!].precipitationMm.toStringAsFixed(1)} mm · UV ${widget.points[selected!].uvIndex ?? '—'}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
        Padding(
          key: const ValueKey('weather-chart-legend'),
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (comparison.series.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 5,
                    children: [
                      for (final item in comparison.series.indexed)
                        Text(
                          '● ${item.$2.source}',
                          style: TextStyle(
                            fontSize: 10,
                            color: weatherProviderColor(
                              item.$2.source,
                              comparison.series.first.source,
                            ),
                          ),
                        ),
                      const Text(
                        'Shaded area: provider spread',
                        style: TextStyle(fontSize: 9, color: muted),
                      ),
                    ],
                  ),
                ),
              const Wrap(
                spacing: 14,
                children: [
                  Text(
                    '● Temperature °C',
                    style: TextStyle(
                      color: Colors.deepOrangeAccent,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '▥ Rain mm',
                    style: TextStyle(color: Colors.lightBlue, fontSize: 10),
                  ),
                  Text(
                    '— UV index',
                    style: TextStyle(color: Colors.amber, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Color weatherProviderColor(String source, String primary) {
  if (source == primary) return Colors.deepOrangeAccent;
  if (source.contains('Pirate')) return Colors.purpleAccent;
  if (source.contains('WeatherAPI')) return Colors.lightBlueAccent;
  return Colors.tealAccent;
}

class _WeatherPainter extends CustomPainter {
  _WeatherPainter(
    this.points,
    this.week,
    this.selected,
    this.comparison,
    this.currentHour,
  );
  final int? currentHour;
  final WeatherComparison comparison;
  final List<OpenMeteoPoint> points;
  final bool week;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(32, 12, size.width - 32, size.height - 25);
    final low =
        (comparison.series
                    .expand((s) => s.points)
                    .map((p) => p.temperatureC)
                    .reduce(math.min) -
                2)
            .floorToDouble();
    final high =
        (comparison.series
                    .expand((s) => s.points)
                    .map((p) => p.temperatureC)
                    .reduce(math.max) +
                2)
            .ceilToDouble();
    final rainMax = math.max(
      2.0,
      points.map((p) => p.precipitationMm).reduce(math.max) * 1.15,
    );
    double x(int i) => plot.left + (i + .5) * plot.width / points.length;
    double y(double value) =>
        plot.bottom - (value - low) / (high - low) * plot.height;
    void label(String text, Offset at, Color color) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, at);
    }

    if (currentHour != null) {
      final px = x(currentHour!);
      final half = plot.width / points.length / 2;
      canvas.drawRect(
        Rect.fromLTRB(px - half, plot.top, px + half, plot.bottom),
        Paint()..color = mint.withValues(alpha: .09),
      );
      canvas.drawLine(
        Offset(px, plot.top),
        Offset(px, plot.bottom),
        Paint()
          ..color = mint.withValues(alpha: .55)
          ..strokeWidth = 1,
      );
      label(
        'NOW',
        Offset(
          (px - 9).clamp(plot.left, plot.right - 20).toDouble(),
          plot.top - 12,
        ),
        mint,
      );
    }
    for (var i = 0; i <= 4; i++) {
      final value = low + (high - low) * i / 4;
      canvas.drawLine(
        Offset(plot.left, y(value)),
        Offset(plot.right, y(value)),
        Paint()..color = Colors.white12,
      );
      label('${value.round()}°', Offset(0, y(value) - 5), muted);
      label(
        (rainMax * i / 4).toStringAsFixed(1),
        Offset(plot.right + 3, plot.bottom - i / 4 * plot.height - 5),
        Colors.lightBlue,
      );
    }
    double timeX(DateTime at) {
      final span = points.last.time
          .difference(points.first.time)
          .inMilliseconds;
      final fraction = span == 0
          ? 0.5
          : at.difference(points.first.time).inMilliseconds / span;
      return plot.left +
          plot.width / points.length / 2 +
          fraction * (plot.width - plot.width / points.length);
    }

    for (var i = 1; i < comparison.spread.length; i++) {
      final a = comparison.spread[i - 1], b = comparison.spread[i];
      if (b.time.difference(a.time) > const Duration(hours: 2)) continue;
      canvas.drawPath(
        Path()
          ..moveTo(timeX(a.time), y(a.low))
          ..lineTo(timeX(a.time), y(a.high))
          ..lineTo(timeX(b.time), y(b.high))
          ..lineTo(timeX(b.time), y(b.low))
          ..close(),
        Paint()..color = Colors.white.withValues(alpha: .09),
      );
    }
    for (var provider = 1; provider < comparison.series.length; provider++) {
      final samples = comparison.series[provider].points;
      for (var i = 1; i < samples.length; i++) {
        if (samples[i].time.difference(samples[i - 1].time) >
            const Duration(hours: 3)) {
          continue;
        }
        canvas.drawLine(
          Offset(timeX(samples[i - 1].time), y(samples[i - 1].temperatureC)),
          Offset(timeX(samples[i].time), y(samples[i].temperatureC)),
          Paint()
            ..color = weatherProviderColor(
              comparison.series[provider].source,
              comparison.series.first.source,
            ).withValues(alpha: .8)
            ..strokeWidth = 1.6,
        );
      }
    }
    final temp = Path(), uv = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i], px = x(i);
      final rainTop = plot.bottom - p.precipitationMm / rainMax * plot.height;
      canvas.drawRect(
        Rect.fromLTRB(
          px - plot.width / points.length * .35,
          rainTop,
          px + plot.width / points.length * .35,
          plot.bottom,
        ),
        Paint()..color = Colors.lightBlue.withValues(alpha: .35),
      );
      final uvY =
          plot.bottom - (p.uvIndex ?? 0).clamp(0, 12) / 12 * plot.height;
      if (i == 0) {
        temp.moveTo(px, y(p.temperatureC));
        uv.moveTo(px, uvY);
      } else {
        temp.lineTo(px, y(p.temperatureC));
        uv.lineTo(px, uvY);
      }
      final stride = math.max(1, (points.length / 6).ceil());
      if (i % stride == 0) {
        label(
          DateFormat(week ? 'd MMM' : 'HH').format(p.time),
          Offset(px - 10, plot.bottom + 8),
          muted,
        );
      }
    }
    canvas.drawPath(
      temp,
      Paint()
        ..color = Colors.deepOrangeAccent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      uv,
      Paint()
        ..color = Colors.amber
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
    if (selected != null && selected! < points.length) {
      canvas.drawLine(
        Offset(x(selected!), plot.top),
        Offset(x(selected!), plot.bottom),
        Paint()
          ..color = Colors.white54
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter old) => true;
}

class WeatherChartFullscreen extends StatelessWidget {
  const WeatherChartFullscreen({
    super.key,
    required this.points,
    required this.week,
    required this.comparison,
    this.primarySource,
    this.selected,
  });
  final List<OpenMeteoPoint> points;
  final bool week;
  final List<OpenMeteoResult> comparison;
  final String? primarySource;
  final int? selected;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF111111),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'WEATHER · ${primarySource ?? 'FORECAST'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close fullscreen weather chart',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Expanded(
                  child: WeatherForecastChart(
                    points: points,
                    week: week,
                    comparison: comparison,
                    primarySource: primarySource,
                    fullscreen: true,
                    initialSelected: selected,
                  ),
                ),
              ],
            ),
          );
          return constraints.maxHeight > constraints.maxWidth
              ? RotatedBox(quarterTurns: 1, child: content)
              : content;
        },
      ),
    ),
  );
}
