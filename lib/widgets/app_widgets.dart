import '../models/chart_point.dart';
export '../models/chart_point.dart';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

const mint = Color(0xFF00D4A0);
const panel = Color(0xFF202020);
const muted = Color(0xFF999999);
String valueText(num? v, [int digits = 0]) =>
    v == null || !v.isFinite ? '—' : v.toStringAsFixed(digits);
String dayText(DateTime d) => DateFormat('d MMM yyyy').format(d);

Future<T?> showAppSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FractionallySizedBox(heightFactor: .94, child: child),
    );

class SheetPage extends StatelessWidget {
  const SheetPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.showBack = true,
    this.backgroundColor = Colors.transparent,
    this.titleSize,
    this.headerDivider = false,
    this.showHeader = true,
  });
  final String title;
  final Widget child;
  final List<Widget> actions;
  final bool showBack, headerDivider, showHeader;
  final Color backgroundColor;
  final double? titleSize;
  @override
  Widget build(BuildContext context) => Material(
    color: backgroundColor,
    child: Column(
      children: [
        const SizedBox(height: 9),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        if (showHeader)
          SizedBox(
            height: 52,
            child: Row(
              children: [
                if (showBack)
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left, size: 20),
                  ),
                if (!showBack) const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: titleSize ?? (showBack ? 14 : 20),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...actions,
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
        if (headerDivider) const Divider(height: 1, color: Colors.white12),
        Expanded(child: child),
      ],
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(16),
  });
  final String? title;
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: color ?? panel,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: muted,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      const Icon(Icons.chevron_right, size: 16, color: muted),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              child,
            ],
          ),
        ),
      ),
    ),
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = muted});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 22, 12, 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          letterSpacing: 0,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Text(
        message,
        style: const TextStyle(color: muted, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class DataError extends StatelessWidget {
  const DataError(this.error, {super.key, this.retry});
  final Object error;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const EmptyState('Unable to load data'),
      if (retry != null)
        TextButton(onPressed: retry, child: const Text('Retry')),
    ],
  );
}

class StatPair extends StatelessWidget {
  const StatPair(
    this.label,
    this.value, {
    super.key,
    this.color = Colors.white,
  });
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(color: muted, fontSize: 9, letterSpacing: .8),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );
}

class HistoryChart extends StatelessWidget {
  const HistoryChart({
    super.key,
    required this.points,
    this.secondary = const [],
    this.color = mint,
    this.bars = false,
    this.height = 200,
    this.referenceLine,
    this.minY,
    this.maxY,
  });
  final List<ChartPoint> points, secondary;
  final Color color;
  final bool bars;
  final double height;
  final double? referenceLine, minY, maxY;
  @override
  Widget build(BuildContext context) {
    final clean = points.where((p) => p.value.isFinite).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    if (clean.isEmpty) {
      return const EmptyState('No measurements in this period');
    }
    final axisSpan = minY != null && maxY != null ? maxY! - minY! : null;
    final axisDigits = axisSpan == null
        ? null
        : axisSpan < 1
        ? 2
        : axisSpan < 10
        ? 1
        : 0;
    final origin = clean.first.at;
    double x(ChartPoint p) => p.at.difference(origin).inSeconds / 86400;
    final last = x(clean.last);
    final span = last > 0 ? last : 1.0;
    Widget label(double v, TitleMeta meta) => Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Text(
        DateFormat(span < 2 ? 'HH:mm' : 'd MMM')
            .format(origin.add(Duration(seconds: (v * 86400).round()))),
        style: const TextStyle(fontSize: 8, color: muted),
      ),
    );
    final titles = FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 38,
          minIncluded: false,
          maxIncluded: false,
          getTitlesWidget: (v, m) => Text(
            valueText(v, axisDigits ?? (v.abs() < 100 ? 1 : 0)),
            maxLines: 1,
            style: const TextStyle(fontSize: 9, color: muted),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: span / 3,
          getTitlesWidget: label,
        ),
      ),
    );
    final grid = FlGridData(
      show: true,
      getDrawingHorizontalLine: (_) =>
          const FlLine(color: Colors.white10, strokeWidth: .5),
      drawVerticalLine: false,
    );
    Widget chart;
    if (bars) {
      chart = BarChart(
        BarChartData(
          minY: minY,
          maxY: maxY,
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (referenceLine != null)
                HorizontalLine(y: referenceLine!, color: mint, strokeWidth: 1),
            ],
          ),
          gridData: grid,
          borderData: FlBorderData(show: false),
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
                reservedSize: 38,
                minIncluded: false,
                maxIncluded: false,
                getTitlesWidget: (v, m) => Text(
                  valueText(v, axisDigits ?? (v.abs() < 100 ? 1 : 0)),
                  maxLines: 1,
                  style: const TextStyle(fontSize: 9, color: muted),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (clean.length / 4).ceilToDouble().clamp(1, 10000),
                getTitlesWidget: (v, m) {
                  final i = v.toInt();
                  return i >= 0 && i < clean.length
                      ? Text(
                          DateFormat('d').format(clean[i].at),
                          style: const TextStyle(fontSize: 8, color: muted),
                        )
                      : const SizedBox();
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < clean.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: clean[i].value,
                    fromY: minY != null && maxY != null
                        ? 0.0.clamp(minY!, maxY!).toDouble()
                        : 0,
                    color: i == clean.length - 1
                        ? Colors.orange
                        : color.withValues(alpha: .6),
                    width: clean.length > 30 ? 3 : 10,
                  ),
                ],
              ),
          ],
        ),
      );
    } else {
      chart = LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (referenceLine != null)
                HorizontalLine(y: referenceLine!, color: mint, strokeWidth: 1),
            ],
          ),
          minX: 0,
          maxX: span,
          gridData: grid,
          borderData: FlBorderData(show: false),
          titlesData: titles,
          lineBarsData: [
            LineChartBarData(
              spots: clean.map((p) => FlSpot(x(p), p.value)).toList(),
              color: color,
              barWidth: 2,
              dotData: FlDotData(show: clean.length < 40),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: .04),
              ),
            ),
            if (secondary.isNotEmpty)
              LineChartBarData(
                spots: secondary
                    .where((p) => p.value.isFinite)
                    .map((p) => FlSpot(x(p), p.value))
                    .toList(),
                color: Colors.orange,
                barWidth: 2,
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      );
    }
    return SizedBox(height: height, child: chart);
  }
}

Future<void> runUiAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    ) ??
    false;
