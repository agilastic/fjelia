import '../l10n/l10n_ext.dart';
import '../l10n/formats.dart';

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_axis.dart';
import '../models/garmin_data.dart';
import '../models/pace_series.dart';
import '../providers/hr_zones_provider.dart';
import 'app_widgets.dart';

const _zoneColors = [
  Color(0xFF4FC3F7),
  mint,
  Color(0xFFFFCC00),
  Colors.orange,
  Colors.redAccent,
];
List<int> _bounds(WidgetRef ref, String type) {
  final zones = ref.watch(hrZonesProvider);
  return RegExp('cycl|bik').hasMatch(type.toLowerCase())
      ? zones.cycling.bounds
      : zones.running.bounds;
}

/// A readable step for the pace axis, in minutes.
double _paceStep(double span) => span <= 1.5
    ? .25
    : span <= 3
    ? .5
    : span <= 6
    ? 1
    : 2;

String _pace(double minutes) =>
    '${minutes.floor()}′${((minutes % 1) * 60).round().clamp(0, 59).toString().padLeft(2, '0')}″';

/// Stored samples share one axis: distance, or time for activities that record
/// no distance (strength, yoga, indoor). HR colors and guides use the
/// configured sport zones.
class ActivityPerformanceChart extends ConsumerWidget {
  const ActivityPerformanceChart({
    super.key,
    required this.activity,
    this.fullscreen = false,
  });
  final GarminActivity activity;
  final bool fullscreen;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = activity.type.toLowerCase().contains('run');
    final bounds = _bounds(ref, activity.type);
    final axis = activityAxisFor(activity.samples);
    final byTime = axis == ActivityAxis.time;
    final minutes = byTime
        ? sampleMinutes(activity.samples, activity.duration)
        : const <double>[];
    // Label, colour, points, and for pace and speed an axis range that
    // follows the bulk of the values rather than the outliers.
    final series = <(String, Color, List<FlSpot>, (double, double)?)>[];
    double? xOf(int i) {
      final sample = activity.samples[i];
      if (byTime) return minutes[i];
      return sample.distanceMeters.isFinite && sample.distanceMeters >= 0
          ? sample.distanceMeters / 1000
          : null;
    }

    void add(String label, Color color, double? Function(ActivitySample) read) {
      final points = <FlSpot>[];
      for (var i = 0; i < activity.samples.length; i++) {
        final value = read(activity.samples[i]);
        final x = xOf(i);
        if (value == null || !value.isFinite || x == null) continue;
        points.add(FlSpot(x, value));
      }
      points.sort((a, b) => a.x.compareTo(b.x));
      if (points.isNotEmpty) series.add((label, color, points, null));
    }

    // Pace and speed: a stop breaks the line instead of drawing a spike.
    // Pace is plotted negated so a faster pace sits higher, as on a watch.
    void addMotion() {
      final speeds = [for (final s in activity.samples) s.speed];
      final values = running ? chartPace(speeds) : chartSpeed(speeds);
      final entries = <(double, double?)>[];
      for (var i = 0; i < values.length; i++) {
        final x = xOf(i);
        if (x == null) continue;
        final v = values[i];
        entries.add((x, v == null ? null : (running ? -v : v)));
      }
      entries.sort((a, b) => a.$1.compareTo(b.$1));
      final shown = [
        for (final e in entries)
          if (e.$2 != null) e.$2!,
      ];
      if (shown.isEmpty) return;
      final points = <FlSpot>[];
      for (final e in entries) {
        if (e.$2 != null) {
          points.add(FlSpot(e.$1, e.$2!));
        } else if (points.isNotEmpty && !points.last.isNull()) {
          points.add(FlSpot.nullSpot);
        }
      }
      while (points.isNotEmpty && points.last.isNull()) {
        points.removeLast();
      }
      series.add((
        running ? context.l10n.paceMinKm : context.l10n.speedKmH,
        _zoneColors.first,
        points,
        robustRange(shown, minSpan: running ? 1 : 5),
      ));
    }

    add(context.l10n.hrBpm, Colors.redAccent, (s) => s.heartRate);
    addMotion();
    add(context.l10n.elevationM, mint, (s) => s.elevation);
    add(context.l10n.powerW, Colors.purpleAccent, (s) => s.power);
    if (series.isEmpty) return const SizedBox.shrink();
    final maxX = math.max(
      .001,
      series
          .expand((s) => s.$3)
          .where((p) => !p.isNull())
          .map((p) => p.x)
          .reduce(math.max),
    );
    Widget chart(
      (String, Color, List<FlSpot>, (double, double)?) row,
      bool last,
    ) {
      final hr = row.$1.startsWith('HR');
      final pace = row.$1.startsWith('PACE');
      final ys = [
        for (final p in row.$3)
          if (!p.isNull()) p.y,
      ];
      final minY = row.$4?.$1 ?? ys.reduce(math.min) - 2;
      final maxY = row.$4?.$2 ?? ys.reduce(math.max) + 2;
      final low = hr ? math.min(minY, bounds.first.toDouble() - 2) : minY;
      final high = hr ? math.max(maxY, bounds.last.toDouble() + 2) : maxY;
      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [_zoneColors.first, ..._zoneColors, _zoneColors.last],
        stops: [
          0,
          for (final b in bounds) ((b - low) / (high - low)).clamp(0, 1),
          1,
        ],
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: row.$2.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              row.$1,
              style: TextStyle(
                color: row.$2,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: fullscreen ? 215 : 120,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: low,
                maxY: high,
                borderData: FlBorderData(show: false),
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Colors.white12,
                    strokeWidth: .5,
                    dashArray: [4, 4],
                  ),
                  getDrawingVerticalLine: (_) => const FlLine(
                    color: Colors.white10,
                    strokeWidth: .5,
                    dashArray: [4, 4],
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (hr)
                      for (var i = 1; i < bounds.length; i++)
                        HorizontalLine(
                          y: bounds[i].toDouble(),
                          color: _zoneColors[i].withValues(alpha: .6),
                          dashArray: [6, 4],
                          strokeWidth: 1,
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            style: TextStyle(
                              color: _zoneColors[i],
                              fontSize: 8,
                            ),
                            labelResolver: (_) => 'Z${i + 1}',
                          ),
                        ),
                  ],
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
                      reservedSize: 35,
                      // Pace labels on round steps: 5′00″, 5′30″, not 5′12″.
                      interval: pace ? _paceStep(high - low) : null,
                      minIncluded: false,
                      maxIncluded: false,
                      getTitlesWidget: (v, _) => Text(
                        pace ? _pace(-v) : valueText(v),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: last,
                      interval: byTime ? niceMinuteInterval(maxX) : maxX / 6,
                      reservedSize: 24,
                      minIncluded: true,
                      maxIncluded: false,
                      getTitlesWidget: (v, _) => Text(
                        byTime
                            ? formatAxisMinutes(v, maxX)
                            : '${v.fixed(v == 0 ? 0 : 1)} km',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: row.$3,
                    color: hr ? null : row.$2,
                    gradient: hr ? gradient : null,
                    gradientArea: LineChartGradientArea.wholeChart,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: !hr,
                      color: row.$2.withValues(alpha: .1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!last) const Divider(height: 18, color: Colors.white10),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            byTime
                ? context.l10n.performanceTime2
                : context.l10n.performanceDistance2,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
        ),
        SectionCard(
          color: const Color(0xFF282828),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!fullscreen)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      textStyle: const TextStyle(fontSize: 10),
                    ),
                    icon: const Icon(Icons.fullscreen, size: 16),
                    label: Text(context.l10n.fullscreen),
                    onPressed: () => showAppSheet(
                      context,
                      SheetPage(
                        title: byTime
                            ? context.l10n.performanceTime
                            : context.l10n.performanceDistance,
                        backgroundColor: panel,
                        child: ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            ActivityPerformanceChart(
                              activity: activity,
                              fullscreen: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              for (var i = 0; i < series.length; i++)
                chart(series[i], i == series.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}

class ActivityZoneChart extends ConsumerWidget {
  const ActivityZoneChart({super.key, required this.activity});
  final GarminActivity activity;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bounds = _bounds(ref, activity.type);
    // The historical DB field hrZoneSeconds stores percentages, not seconds.
    final values = List.generate(
      5,
      (i) => (activity.hrZoneSeconds['zone${i + 1}'] ?? 0).clamp(0.0, 100.0),
    );
    final sum = values.fold(0.0, (a, b) => a + b);
    String duration(double pct) {
      final seconds = (activity.duration.inSeconds * pct / 100).round();
      return seconds >= 3600
          ? '${seconds ~/ 3600}h ${seconds ~/ 60 % 60}m'
          : '${seconds ~/ 60}m ${seconds % 60}s';
    }

    return SectionCard(
      title: context.l10n.timeInHrZones,
      color: const Color(0xFF282828),
      child: Column(
        children: [
          if (sum > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    if (values[i] > 0)
                      Expanded(
                        flex: (values[i] * 100).round().clamp(1, 10000),
                        child: Container(height: 10, color: _zoneColors[i]),
                      ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.circle, color: _zoneColors[i], size: 10),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.zoneI(i + 1),
                          style: TextStyle(
                            fontSize: 13,
                            color: _zoneColors[i],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          i == 4
                              ? '${bounds[i]}+ bpm'
                              : '${bounds[i]}–${bounds[i + 1]} bpm',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: LinearProgressIndicator(
                      value: values[i] / 100,
                      color: _zoneColors[i],
                      backgroundColor: Colors.white10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          duration(values[i]),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          context.l10n.round3(values[i].round()),
                          style: const TextStyle(fontSize: 9, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
