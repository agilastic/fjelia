import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/hrv_series.dart';
import '../models/spot_hrv.dart';
import '../providers/polar_h10_provider.dart';
import 'app_widgets.dart';
import 'polar_h10_hrv_sheet.dart';

const _colors = {
  HrvSeries.sleep: Color(0xFF4FC3F7),
  HrvSeries.before: Color(0xFF00D4A0),
  HrvSeries.after: Color(0xFFFFA94D),
  HrvSeries.resting: Color(0xFFB58CFF),
};

const _surface = Color(0xFF262626);
const _grid = Color(0x14FFFFFF);

/// Overnight HRV and Polar H10 spot readings (before / after training,
/// resting) in one chart, with a tile per series that also acts as its
/// on/off switch.
class HrvCombinedCard extends ConsumerStatefulWidget {
  const HrvCombinedCard({
    super.key,
    required this.start,
    required this.end,
    required this.sleepPoints,
    this.average,
    this.averageLabel = 'Average',
  });

  final DateTime start, end;
  final List<ChartPoint> sleepPoints;

  /// Average of the overnight readings, drawn as a reference line.
  final double? average;
  final String averageLabel;

  @override
  ConsumerState<HrvCombinedCard> createState() => _State();
}

class _State extends ConsumerState<HrvCombinedCard> {
  final _hidden = <HrvSeries>{};
  String _posture = 'all';

  @override
  Widget build(BuildContext context) {
    final rows = ref
        .watch(spotHrvWindowProvider((start: widget.start, end: widget.end)))
        .valueOrNull;
    final all = buildHrvSeries(
      sleep: widget.sleepPoints,
      spot: [
        for (final r in rows ?? const [])
          SpotHrvPoint(
            at: r.startedAt,
            context: r.context,
            posture: r.posture,
            rmssdMs: r.rmssdMs,
          ),
      ],
      posture: _posture == 'all' ? null : _posture,
    );
    final visible = [
      for (final s in all)
        if (!_hidden.contains(s.series) && s.points.isNotEmpty) s,
    ];
    final delta = afterMinusBefore(all);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Tiles(
          series: all,
          hidden: _hidden,
          onToggle: (s) => setState(
            () => _hidden.contains(s) ? _hidden.remove(s) : _hidden.add(s),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 12),
              side: const BorderSide(color: Color(0x1FFFFFFF)),
              foregroundColor: muted,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: const Color(0x3300D4A0),
            ),
            segments: [
              const ButtonSegment(value: 'all', label: Text('All postures')),
              for (final p in SpotHrvPosture.values)
                ButtonSegment(value: p.name, label: Text(p.label)),
            ],
            selected: {_posture},
            onSelectionChanged: (v) => setState(() => _posture = v.first),
          ),
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          const SizedBox(
            height: 180,
            child: EmptyState('No HRV readings in this period'),
          )
        else
          SizedBox(
            height: 250,
            child: _Chart(
              start: widget.start,
              end: widget.end,
              series: visible,
              average: _hidden.contains(HrvSeries.sleep)
                  ? null
                  : widget.average,
              averageLabel: widget.averageLabel,
            ),
          ),
        if (widget.average != null && !_hidden.contains(HrvSeries.sleep))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(width: 16, height: 1.5, color: Colors.white38),
                const SizedBox(width: 6),
                Text(
                  '${widget.averageLabel} ${widget.average!.toStringAsFixed(0)} ms',
                  style: const TextStyle(fontSize: 10, color: muted),
                ),
              ],
            ),
          ),
        if (delta != null) ...[
          const SizedBox(height: 14),
          _Insight(delta: delta),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0x2200D4A0),
              foregroundColor: mint,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => showAppSheet(context, const PolarH10HrvSheet()),
            icon: const Icon(Icons.monitor_heart_outlined, size: 18),
            label: const Text('Measure with Polar H10'),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Overnight HRV comes from your watch, spot readings from the Polar '
          'H10 (RMSSD). The methods differ: compare trends, not single values.',
          style: TextStyle(color: muted, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }
}

/// One tile per series with its average and count; tapping hides or shows it.
class _Tiles extends StatelessWidget {
  const _Tiles({
    required this.series,
    required this.hidden,
    required this.onToggle,
  });
  final List<HrvSeriesData> series;
  final Set<HrvSeries> hidden;
  final ValueChanged<HrvSeries> onToggle;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = 10.0;
      final width = (box.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final s in series)
            SizedBox(
              width: width,
              child: _Tile(
                data: s,
                off: hidden.contains(s.series),
                onTap: s.count == 0 ? null : () => onToggle(s.series),
              ),
            ),
        ],
      );
    },
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.data, required this.off, this.onTap});
  final HrvSeriesData data;
  final bool off;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colors[data.series]!;
    final empty = data.count == 0;
    final dim = off || empty;
    final average = data.average;
    return Semantics(
      button: !empty,
      label:
          '${data.series.label}, ${empty ? 'no readings' : '${average!.round()} milliseconds, ${data.count} readings'}',
      child: Material(
        color: dim ? _surface : color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dim
                    ? const Color(0x1AFFFFFF)
                    : color.withValues(alpha: .55),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dim ? const Color(0x55FFFFFF) : color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.series.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: dim ? const Color(0x80FFFFFF) : muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      empty ? '—' : '${average!.round()}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: dim ? const Color(0x80FFFFFF) : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ms',
                      style: TextStyle(
                        fontSize: 11,
                        color: dim ? const Color(0x66FFFFFF) : muted,
                      ),
                    ),
                  ],
                ),
                Text(
                  empty
                      ? 'No readings'
                      : data.count == 1
                      ? '1 reading'
                      : '${data.count} readings',
                  style: TextStyle(
                    fontSize: 10,
                    color: dim ? const Color(0x66FFFFFF) : muted,
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

/// How the evening reading compares with the morning one.
class _Insight extends StatelessWidget {
  const _Insight({required this.delta});
  final double delta;

  @override
  Widget build(BuildContext context) {
    final lower = delta < 0;
    final color = lower
        ? _colors[HrvSeries.after]!
        : _colors[HrvSeries.before]!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Icon(
            lower ? Icons.trending_down_rounded : Icons.trending_up_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'After training ${lower ? '−' : '+'}${delta.abs().toStringAsFixed(0)} ms '
              'vs before training (average of this period).',
              style: const TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({
    required this.start,
    required this.end,
    required this.series,
    required this.average,
    required this.averageLabel,
  });
  final DateTime start, end;
  final List<HrvSeriesData> series;
  final double? average;
  final String averageLabel;

  @override
  Widget build(BuildContext context) {
    final span = end.difference(start).inMinutes / 1440.0;
    double x(DateTime t) =>
        (t.difference(start).inMinutes / 1440.0).clamp(0, span).toDouble();
    final values = [
      for (final s in series)
        for (final p in s.points) p.value,
      ?average,
    ];
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    final pad = ((high - low) * .18).clamp(4, 1000).toDouble();
    final minY = ((low - pad) / 5).floor() * 5.0;
    final maxY = ((high + pad) / 5).ceil() * 5.0;
    return LineChart(
      duration: const Duration(milliseconds: 250),
      LineChartData(
        minX: 0,
        maxX: span <= 0 ? 1 : span,
        minY: minY.clamp(0, 100000).toDouble(),
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) > 40 ? 10 : 5,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: _grid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (average != null)
              HorizontalLine(
                y: average!,
                color: Colors.white38,
                strokeWidth: 1,
                dashArray: const [5, 4],
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
              reservedSize: 32,
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10, color: muted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: (span / 3).clamp(1, 1000).toDouble(),
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  // The right edge is the end of the last day, so it carries
                  // that day's date and not the next one.
                  DateFormat('d MMM').format(
                    v >= span - .001
                        ? end.subtract(const Duration(days: 1))
                        : start.add(Duration(minutes: (v * 1440).round())),
                  ),
                  style: const TextStyle(fontSize: 10, color: muted),
                ),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF2E2E2E),
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            getTooltipItems: (touched) => [
              for (final spot in touched)
                LineTooltipItem(
                  '${series[spot.barIndex].series.label}\n',
                  TextStyle(
                    color: _colors[series[spot.barIndex].series],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: '${spot.y.toStringAsFixed(0)} ms',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text:
                          '\n${DateFormat('d MMM · HH:mm').format(series[spot.barIndex].points[spot.spotIndex].at)}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        lineBarsData: [for (final s in series) _bar(s, x)],
      ),
    );
  }

  LineChartBarData _bar(HrvSeriesData s, double Function(DateTime) x) {
    final color = _colors[s.series]!;
    final sleep = s.series == HrvSeries.sleep;
    return LineChartBarData(
      spots: [for (final p in s.points) FlSpot(x(p.at), p.value)],
      color: color,
      // Overnight HRV is a continuous trend; spot readings are single points
      // and are drawn as rings only.
      barWidth: sleep ? 2.5 : 0,
      isCurved: sleep,
      curveSmoothness: .18,
      preventCurveOverShooting: true,
      belowBarData: BarAreaData(
        show: sleep,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .28), color.withValues(alpha: 0)],
        ),
      ),
      dotData: FlDotData(
        show: !sleep || s.count <= 20,
        getDotPainter: (spot, percent, bar, index) => sleep
            ? FlDotCirclePainter(radius: 2.5, color: color, strokeWidth: 0)
            : FlDotCirclePainter(
                radius: 5.5,
                color: _surface,
                strokeColor: color,
                strokeWidth: 3,
              ),
      ),
    );
  }
}
