import '../theme/fjelia_style.dart';
import '../l10n/formats.dart';
import '../models/chart_point.dart';
export '../models/chart_point.dart';

import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

const mint = Color(0xFF00D4A0);
Color get panel => fjPanel;
Color get muted => fjMuted;
String valueText(num? v, [int digits = 0]) =>
    v == null || !v.isFinite ? '—' : v.fixed(digits);
String dayText(DateTime d) => DateFormat.yMMMd().format(d);

/// A day heading for lists: TODAY, YESTERDAY and TOMORROW by name, any other
/// day by its date.
String dayHeading(BuildContext context, DateTime d) {
  final today = DateUtils.dateOnly(DateTime.now());
  final day = DateUtils.dateOnly(d);
  final offset = day.difference(today).inDays;
  return switch (offset) {
    0 => context.l10n.today2,
    -1 => context.l10n.yesterday2,
    1 => context.l10n.tomorrow,
    _ => dayText(d).toUpperCase(),
  };
}

Future<T?> showAppSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: duo(0xFF111111, 0xFFF2F4F7),
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
            color: fjInk24,
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
                    tooltip: context.l10n.back,
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
                  tooltip: context.l10n.close,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
        if (headerDivider) Divider(height: 1, color: fjInk12),
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
    this.accent,
  });
  final String? title;
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry padding;

  /// Two colours that give the card its own glow: the title in their
  /// gradient, a faint light from the top left and a tinted edge.
  final List<Color>? accent;
  @override
  Widget build(BuildContext context) {
    final accent = this.accent;
    final label = title?.toUpperCase();
    final heading = label == null
        ? null
        : accent == null
        ? Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: muted,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          )
        : GradientTitle(label, colors: accent);
    final body = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading != null) ...[
            Row(
              children: [
                Expanded(
                  child: Align(alignment: Alignment.centerLeft, child: heading),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: accent == null
                        ? muted
                        : fjAccent(accent.last).withValues(alpha: .8),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color ?? panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: accent == null ? BorderSide.none : fjEdge(accent),
        ),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: accent == null ? null : fjGlow(accent, strength: .55),
          child: InkWell(onTap: onTap, child: body),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  Color get _color => color ?? muted;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 22, 12, 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(
          color: _color,
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
        style: TextStyle(color: muted, fontSize: 12),
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
      EmptyState(context.l10n.unableToLoadData),
      if (retry != null)
        TextButton(onPressed: retry, child: Text(context.l10n.retry)),
    ],
  );
}

class StatPair extends StatelessWidget {
  const StatPair(this.label, this.value, {super.key, this.color});
  final String label, value;
  final Color? color;
  Color get _color => color ?? fjInk;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: TextStyle(color: muted, fontSize: 9, letterSpacing: .8),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _color,
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
    this.secondaryColor = Colors.orange,
    this.bars = false,
    this.height = 200,
    this.referenceLine,
    this.minY,
    this.maxY,
  });
  final List<ChartPoint> points, secondary;
  final Color color, secondaryColor;
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
        (span < 2 ? DateFormat.Hm() : DateFormat.MMMd()).format(
          origin.add(Duration(seconds: (v * 86400).round())),
        ),
        style: TextStyle(fontSize: 8, color: muted),
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
            style: TextStyle(fontSize: 9, color: muted),
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
      getDrawingHorizontalLine: (_) => FlLine(color: fjInk10, strokeWidth: .5),
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
                  style: TextStyle(fontSize: 9, color: muted),
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
                          DateFormat.d().format(clean[i].at),
                          style: TextStyle(fontSize: 8, color: muted),
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
                color: secondaryColor,
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
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(context.l10n.continueLabel),
          ),
        ],
      ),
    ) ??
    false;
