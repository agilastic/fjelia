import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/app_widgets.dart';
import '../../utils/week.dart';

const loadBlue = Color(0xFF4BC0EB);
const loadOrange = Color(0xFFFF9100);
const loadRed = Color(0xFFFF454B);
const loadSurface = Color(0xFF1E1E1E);
const loadInset = Color(0xFF282828);
const loadLabel = TextStyle(
  fontSize: 11,
  color: Color(0xFFBBBBBB),
  letterSpacing: 1,
  fontWeight: FontWeight.w600,
);
const loadCaption = TextStyle(fontSize: 10, color: Color(0xFF888888));

class LoadCard extends StatelessWidget {
  const LoadCard({
    super.key,
    required this.child,
    this.color = loadSurface,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class LoadBadge extends StatelessWidget {
  const LoadBadge(
    this.text, {
    super.key,
    this.color = const Color(0xFFBBBBBB),
    this.fontSize = 11,
  });
  final String text;
  final Color color;
  final double fontSize;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class LoadLegend extends StatelessWidget {
  const LoadLegend(this.text, this.color, {super.key, this.line = false});
  final String text;
  final Color color;
  final bool line;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: line ? 2 : 9,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(text, style: loadCaption),
    ],
  );
}

class LoadRange extends StatelessWidget {
  const LoadRange({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.color = mint,
    this.segmented = false,
  });
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;
  final Color color;
  final bool segmented;
  @override
  Widget build(BuildContext context) {
    final buttons = [
      for (final label in labels)
        Padding(
          padding: EdgeInsets.only(right: segmented ? 0 : 8),
          child: Material(
            color: selected == label
                ? color.withValues(alpha: segmented ? 1 : .2)
                : segmented
                ? Colors.transparent
                : loadInset,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(segmented ? 7 : 24),
              side: !segmented && selected == label
                  ? BorderSide(color: color)
                  : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onChanged(label),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: segmented ? 8 : 13,
                  vertical: segmented ? 6 : 8,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: segmented ? 10 : 12,
                    fontWeight: FontWeight.w600,
                    color: selected == label
                        ? (segmented ? Colors.black : color)
                        : muted,
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
    return segmented
        ? Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: loadInset,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: buttons),
          )
        : Wrap(runSpacing: 8, children: buttons);
  }
}

Future<T?> showLoadSheet<T>(
  BuildContext context,
  Widget child, {
  double height = .55,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  backgroundColor: loadSurface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  clipBehavior: Clip.antiAlias,
  builder: (context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * height,
    child: SafeArea(top: false, child: child),
  ),
);

class LoadSheet extends StatelessWidget {
  const LoadSheet({
    super.key,
    required this.title,
    required this.child,
    this.centerTitle = false,
    this.close = false,
    this.largeTitle = false,
  });
  final String title;
  final Widget child;
  final bool centerTitle, close, largeTitle;
  @override
  Widget build(BuildContext context) => Material(
    color: loadSurface,
    child: Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 19),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  textAlign: centerTitle ? TextAlign.center : TextAlign.left,
                  style: loadLabel.copyWith(
                    fontSize: largeTitle ? 16 : 11,
                    color: largeTitle ? Colors.white : const Color(0xFFBBBBBB),
                  ),
                ),
              ),
              if (close)
                IconButton(
                  tooltip: 'Close',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: child),
      ],
    ),
  );
}

String loadDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);

/// Calendar-week number of the week starting on [date].
int loadWeekNumber(DateTime date, {bool mondayFirst = true}) =>
    isoWeekNumber(date, mondayFirst: mondayFirst);

/// The original overview charts are twelve filled tracks, not axis charts.
class LoadWeekBars extends StatelessWidget {
  const LoadWeekBars({
    super.key,
    required this.dates,
    required this.values,
    this.weekNumbers = false,
    this.limit = false,
    this.mondayFirst = true,
    this.inProgressLast = false,
  });
  final bool mondayFirst;
  final List<DateTime> dates;
  final List<double> values;
  final bool weekNumbers, limit;

  /// The last bar is a week that is still running: drawn lighter with an
  /// outline and labelled "so far", so a smaller bar does not read as a drop.
  final bool inProgressLast;
  @override
  Widget build(BuildContext context) {
    final limits = [
      for (var i = 0; i < values.length; i++) i > 0 ? values[i - 1] * 1.1 : 0.0,
    ];
    final max =
        math.max(
          1.0,
          [...values, if (limit) ...limits].fold<double>(0, math.max),
        ) *
        1.05;
    return SizedBox(
      height: 86,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == values.length - 1 ? 0 : 3),
                child: Column(
                  children: [
                    Expanded(
                      child: Tooltip(
                        message:
                            '${DateFormat('d MMM').format(dates[i])}: ${valueText(values[i], 1)}'
                            '${inProgressLast && i == values.length - 1 ? ' (so far)' : ''}',
                        child: LayoutBuilder(
                          builder: (context, box) => ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Stack(
                              children: [
                                Container(
                                  color: Colors.white.withValues(alpha: .045),
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: (values[i] / max).clamp(0, 1),
                                    widthFactor: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: limit
                                            ? i == values.length - 1
                                                  ? inProgressLast
                                                        ? mint.withValues(
                                                            alpha: .5,
                                                          )
                                                        : mint
                                                  : i > 0 &&
                                                        values[i] > limits[i]
                                                  ? loadOrange.withValues(
                                                      alpha: .5,
                                                    )
                                                  : Colors.white.withValues(
                                                      alpha: .19,
                                                    )
                                            : Colors.white.withValues(
                                                alpha: .19,
                                              ),
                                        borderRadius: BorderRadius.circular(3),
                                        border:
                                            inProgressLast &&
                                                i == values.length - 1
                                            ? Border.all(color: mint)
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                                if (limit &&
                                    i == values.length - 1 &&
                                    limits[i] > 0)
                                  Positioned(
                                    bottom:
                                        (limits[i] / max).clamp(0, 1) *
                                        (box.maxHeight - 2),
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 2,
                                      color: Colors.amber,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      weekNumbers
                          ? '${loadWeekNumber(dates[i], mondayFirst: mondayFirst)}'
                          : '${dates[i].day}',
                      style: TextStyle(
                        fontSize: 8,
                        color: i == values.length - 1
                            ? const Color(0xFFBBBBBB)
                            : const Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LoadTrendChart extends StatelessWidget {
  const LoadTrendChart({
    super.key,
    required this.points,
    this.bars = false,
    this.average,
    this.color = loadBlue,
    this.minY,
    this.maxY,
    this.height = 150,
    this.pace = false,
    this.unit = '',
    this.heat = false,
    this.step = false,
  });
  final List<ChartPoint> points;
  final bool bars, pace, heat, step;
  final double? average, minY, maxY;
  final Color color;
  final double height;
  final String unit;
  @override
  Widget build(BuildContext context) {
    final clean = points.where((p) => p.value.isFinite).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    if (clean.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('No measurements in this period', style: loadCaption),
        ),
      );
    }
    final low =
        minY ??
        (bars
            ? 0
            : clean.map((p) => p.value).reduce(math.min) - (pace ? 10 : 5));
    final high =
        maxY ??
        math.max(
          low + 1,
          clean.map((p) => p.value).reduce(math.max) * (bars ? 1.15 : 1) +
              (bars
                  ? 0
                  : pace
                  ? 10
                  : 5),
        );
    final origin = clean.first.at;
    double x(ChartPoint p) => p.at.difference(origin).inSeconds / 86400;
    final last = x(clean.last);
    final titles = FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 35,
          interval: heat ? 20 : (high - low) / 2,
          getTitlesWidget: (v, _) => Text(
            pace
                ? '${v ~/ 60}:${(v.round() % 60).toString().padLeft(2, '0')}'
                : '${valueText(v, v.abs() < 10 ? 1 : 0)}$unit',
            style: const TextStyle(fontSize: 8, color: Color(0xFF777777)),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: bars
              ? math.max(1, (clean.length / 14).ceilToDouble())
              : math.max(1, last / (heat ? 6 : 4)),
          getTitlesWidget: (v, _) {
            final i = v.round();
            if (bars && (i < 0 || i >= clean.length)) return const SizedBox();
            final date = bars
                ? clean[i].at
                : origin.add(Duration(seconds: (v * 86400).round()));
            return Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                DateFormat(heat ? 'M/d' : 'd/M').format(date),
                style: const TextStyle(fontSize: 7, color: Color(0xFF777777)),
              ),
            );
          },
        ),
      ),
    );
    final grid = FlGridData(
      show: !bars,
      drawVerticalLine: false,
      horizontalInterval: heat ? 20 : null,
      getDrawingHorizontalLine: (_) => FlLine(
        color: Colors.white12,
        strokeWidth: .6,
        dashArray: heat ? [8, 4] : null,
      ),
    );
    return SizedBox(
      height: height,
      child: bars
          ? BarChart(
              BarChartData(
                minY: low,
                maxY: high,
                titlesData: titles,
                gridData: grid,
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (average != null)
                      HorizontalLine(
                        y: average!,
                        color: mint.withValues(alpha: .65),
                        strokeWidth: 1.3,
                      ),
                  ],
                ),
                barGroups: [
                  for (var i = 0; i < clean.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: clean[i].value,
                          width: clean.length > 30 ? 3 : 13,
                          color: color.withValues(alpha: .55),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                ],
              ),
            )
          : LineChart(
              LineChartData(
                minX: 0,
                maxX: math.max(1, last),
                minY: low,
                maxY: high,
                titlesData: titles,
                gridData: grid,
                borderData: FlBorderData(
                  show: heat,
                  border: Border.all(color: Colors.white10),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (final p in clean) FlSpot(x(p), p.value)],
                    color: color,
                    isCurved: heat,
                    isStepLineChart: step,
                    lineChartStepData: const LineChartStepData(
                      stepDirection: 1,
                    ),
                    preventCurveOverShooting: true,
                    barWidth: heat ? 2.5 : 1.7,
                    dotData: FlDotData(show: !heat),
                    belowBarData: BarAreaData(
                      show: heat,
                      color: color.withValues(alpha: .15),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
