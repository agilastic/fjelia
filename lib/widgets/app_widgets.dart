import 'dart:math' as math;

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

/// A small figure with its label above, like LINKS 42 kg (style.md: key
/// figure).
class StatPair extends StatelessWidget {
  const StatPair(this.label, this.value, {super.key, this.color, this.unit});
  final String label, value;
  final String? unit;
  final Color? color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FigureLabel(label),
      const SizedBox(height: 4),
      KeyFigure(value, unit: unit, color: color),
    ],
  );
}

/// The small upper-case label of a figure (IN RUHE, SPITZE).
class FigureLabel extends StatelessWidget {
  const FigureLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: 10,
      color: muted,
      letterSpacing: 1,
      fontWeight: FontWeight.w700,
    ),
  );
}

/// A figure with its unit after it. [size] 44 is a card's hero figure
/// (135/75 mmHg), the default 24 a key figure (style.md: Figures).
class KeyFigure extends StatelessWidget {
  const KeyFigure(
    this.value, {
    super.key,
    this.unit,
    this.color,
    this.size = 24,
  });
  const KeyFigure.hero(this.value, {super.key, this.unit, this.color})
    : size = 44;
  final String value;
  final String? unit;
  final Color? color;
  final double size;
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: size >= 40 ? -1 : -.3,
            color: color ?? fjInk,
          ),
        ),
        if (unit != null && unit!.isNotEmpty) ...[
          SizedBox(width: size >= 40 ? 6 : 4),
          Text(
            unit!,
            style: TextStyle(fontSize: size >= 40 ? 14 : 11, color: muted),
          ),
        ],
      ],
    ),
  );
}

/// The status word beside a hero figure (HOCH-NORMAL, OPTIMAL) and the
/// comparison below it.
class StatusWord extends StatelessWidget {
  const StatusWord(this.word, {super.key, required this.color, this.detail});
  final String word;
  final Color color;
  final String? detail;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        word.toUpperCase(),
        textAlign: TextAlign.end,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: fjAccent(color),
        ),
      ),
      if (detail != null) ...[
        const SizedBox(height: 6),
        Text(
          detail!,
          textAlign: TextAlign.end,
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ],
    ],
  );
}

/// A hero figure with its status on the right: the head of a card like
/// blood pressure, day load or form.
class HeroRow extends StatelessWidget {
  const HeroRow({
    super.key,
    required this.value,
    this.unit,
    this.status,
    this.statusColor = mint,
    this.detail,
  });
  final String value;
  final String? unit, status, detail;
  final Color statusColor;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(child: KeyFigure.hero(value, unit: unit)),
      if (status != null || detail != null) ...[
        const SizedBox(width: 12),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: StatusWord(status ?? '', color: statusColor, detail: detail),
          ),
        ),
      ],
    ],
  );
}

/// A tile in a card's grid, like the health monitor's: an icon in a tinted
/// circle, the name, the figure with its unit and an optional trend.
class FigureTile extends StatelessWidget {
  const FigureTile({
    super.key,
    required this.icon,
    required this.name,
    required this.value,
    required this.color,
    this.unit,
    this.trend,
    this.trendColor,
    this.onTap,
  });
  final IconData icon;
  final String name, value;
  final String? unit;
  final Color color;
  final IconData? trend;
  final Color? trendColor;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: color.withValues(alpha: .16)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Ink(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: .09), Colors.transparent],
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: .16),
                    ),
                    child: Icon(icon, size: 13, color: fjAccent(color)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: fjInk,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: KeyFigure(value, unit: unit, size: 22)),
                  if (trend != null)
                    Icon(trend, size: 18, color: trendColor ?? muted),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Tiles two by two, 8 apart (one column with large text).
class FigureGrid extends StatelessWidget {
  const FigureGrid(this.tiles, {super.key});
  final List<Widget> tiles;
  @override
  Widget build(BuildContext context) {
    final one = MediaQuery.textScalerOf(context).scale(10) / 10 >= 1.3;
    if (one) {
      return Column(
        children: [
          for (final (i, t) in tiles.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            t,
          ],
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: 8),
                Expanded(
                  child: i + 1 < tiles.length
                      ? tiles[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Chart tooltips with rounded figures (style.md: no decimals in overview
/// figures), on the panel, each value in its line's colour.
/// [format] writes a value its own way (a pace).
LineTouchData roundedLineTouch({
  int decimals = 0,
  String Function(double)? format,
}) => LineTouchData(
  touchTooltipData: LineTouchTooltipData(
    getTooltipColor: (_) => duo(0xFF2E2E2E, 0xFFE3E7EC),
    fitInsideHorizontally: true,
    fitInsideVertically: true,
    getTooltipItems: (spots) => [
      for (final s in spots)
        LineTooltipItem(
          format?.call(s.y) ?? valueText(s.y, decimals),
          TextStyle(
            color: fjAccent(
              s.bar.color ?? s.bar.gradient?.colors.first ?? fjInk,
            ),
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
    ],
  ),
);

/// The same for bar charts.
BarTouchData roundedBarTouch({int decimals = 0}) => BarTouchData(
  touchTooltipData: BarTouchTooltipData(
    getTooltipColor: (_) => duo(0xFF2E2E2E, 0xFFE3E7EC),
    fitInsideHorizontally: true,
    fitInsideVertically: true,
    getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
      valueText(rod.toY, decimals),
      TextStyle(color: fjInk, fontWeight: FontWeight.w800, fontSize: 13),
    ),
  ),
);

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
    // Whole numbers, unless the values lie so close that they would all
    // read the same (weight, waist).
    final values = [for (final p in clean) p.value];
    final tipDigits =
        values.isEmpty || values.reduce(math.max) - values.reduce(math.min) >= 5
        ? 0
        : 1;
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
          barTouchData: roundedBarTouch(decimals: tipDigits),
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
          lineTouchData: roundedLineTouch(decimals: tipDigits),
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
