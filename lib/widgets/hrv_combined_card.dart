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
  HrvSeries.sleep: Colors.lightBlue,
  HrvSeries.before: mint,
  HrvSeries.after: Colors.orange,
  HrvSeries.resting: Colors.purpleAccent,
};

/// Overnight HRV and Polar H10 spot readings (before / after training,
/// resting) for one period in a single chart.
class HrvCombinedCard extends ConsumerStatefulWidget {
  const HrvCombinedCard({
    super.key,
    required this.start,
    required this.end,
    required this.sleepPoints,
  });

  final DateTime start, end;
  final List<ChartPoint> sleepPoints;

  @override
  ConsumerState<HrvCombinedCard> createState() => _State();
}

class _State extends ConsumerState<HrvCombinedCard> {
  final _hidden = <HrvSeries>{};
  String? _posture;

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
      posture: _posture,
    );
    final visible = [
      for (final s in all)
        if (!_hidden.contains(s.series) && s.points.isNotEmpty) s,
    ];
    final delta = afterMinusBefore(all);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HRV · sleep and spot readings',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Overnight HRV (watch) next to Polar H10 spot RMSSD before and '
            'after training. The methods differ, so compare trends rather '
            'than single values.',
            style: TextStyle(color: muted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final s in HrvSeries.values)
                FilterChip(
                  label: Text(s.label, style: const TextStyle(fontSize: 11)),
                  avatar: CircleAvatar(radius: 5, backgroundColor: _colors[s]),
                  selected: !_hidden.contains(s),
                  showCheckmark: false,
                  onSelected: (on) =>
                      setState(() => on ? _hidden.remove(s) : _hidden.add(s)),
                ),
            ],
          ),
          Wrap(
            spacing: 6,
            children: [
              for (final p in <(String?, String)>[
                (null, 'All postures'),
                for (final v in SpotHrvPosture.values) (v.name, v.label),
              ])
                ChoiceChip(
                  label: Text(p.$2, style: const TextStyle(fontSize: 11)),
                  selected: _posture == p.$1,
                  onSelected: (_) => setState(() => _posture = p.$1),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const EmptyState('No HRV readings in this period')
          else
            SizedBox(
              height: 220,
              child: _Chart(
                start: widget.start,
                end: widget.end,
                series: visible,
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              for (final s in all)
                if (s.count > 0)
                  Text(
                    '${s.series.label}: ${valueText(s.average, 0)} ms (${s.count})',
                    style: TextStyle(fontSize: 11, color: _colors[s.series]),
                  ),
            ],
          ),
          if (delta != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'After training is ${delta >= 0 ? '+' : '−'}'
                '${delta.abs().toStringAsFixed(0)} ms vs before training '
                '(average of this period).',
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => showAppSheet(context, const PolarH10HrvSheet()),
            icon: const Icon(Icons.monitor_heart_outlined, size: 16),
            label: const Text('Measure with Polar H10'),
          ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.start, required this.end, required this.series});
  final DateTime start, end;
  final List<HrvSeriesData> series;

  @override
  Widget build(BuildContext context) {
    final span = end.difference(start).inMinutes / 1440.0;
    double x(DateTime t) =>
        (t.difference(start).inMinutes / 1440.0).clamp(0, span).toDouble();
    final values = [
      for (final s in series)
        for (final p in s.points) p.value,
    ];
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    final pad = ((high - low) * .15).clamp(3, 1000).toDouble();
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: span <= 0 ? 1 : span,
        minY: (low - pad).clamp(0, 100000).toDouble(),
        maxY: high + pad,
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: _line,
        ),
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
              reservedSize: 34,
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(fontSize: 9, color: muted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: (span / 3).clamp(1, 1000).toDouble(),
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  DateFormat(
                    'd MMM',
                  ).format(start.add(Duration(minutes: (v * 1440).round()))),
                  style: const TextStyle(fontSize: 8, color: muted),
                ),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touched) => [
              for (final spot in touched)
                LineTooltipItem(
                  '${series[spot.barIndex].series.label}\n'
                  '${spot.y.toStringAsFixed(0)} ms · '
                  '${DateFormat('d MMM HH:mm').format(series[spot.barIndex].points[spot.spotIndex].at)}',
                  TextStyle(
                    color: _colors[series[spot.barIndex].series],
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          for (final s in series)
            LineChartBarData(
              spots: [for (final p in s.points) FlSpot(x(p.at), p.value)],
              color: _colors[s.series],
              // Overnight HRV is a continuous trend; spot readings are single
              // points and are drawn as dots only.
              barWidth: s.series == HrvSeries.sleep ? 2 : 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: s.series == HrvSeries.sleep ? 2.5 : 4.5,
                      color: _colors[s.series]!,
                      strokeWidth: 0,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  static FlLine _line(double _) =>
      const FlLine(color: Colors.white10, strokeWidth: .5);
}
