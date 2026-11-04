import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../l10n/l10n_ext.dart';
import '../models/garmin_data.dart';
import 'app_widgets.dart';

const _hrvColor = Color(0xFF4FD1C5);
const _stressColor = Color(0xFFFFA94D);

/// HRV and stress over the night, for a watch that gives no phase timeline
/// (COROS): what it measured, not an estimate of the stages.
class NightCurvesSection extends StatelessWidget {
  const NightCurvesSection({super.key, required this.sleep});
  final SleepData sleep;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.nightCurves.toUpperCase(),
          style: const TextStyle(
            color: muted,
            fontSize: 12,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          sleep.phasesEstimated ? l10n.nightCurvesBasis : l10n.noPhaseTimeline,
          style: const TextStyle(color: muted, fontSize: 11, height: 1.4),
        ),
        if (sleep.hrvCurve.length > 1) ...[
          const SizedBox(height: 16),
          _Curve(
            label: 'HRV',
            unit: 'ms',
            color: _hrvColor,
            points: sleep.hrvCurve,
          ),
        ],
        if (sleep.stressCurve.length > 1) ...[
          const SizedBox(height: 16),
          _Curve(
            label: l10n.stress,
            unit: '',
            color: _stressColor,
            points: sleep.stressCurve,
          ),
        ],
      ],
    );
  }
}

class _Curve extends StatelessWidget {
  const _Curve({
    required this.label,
    required this.unit,
    required this.color,
    required this.points,
  });

  final String label, unit;
  final Color color;
  final List<(DateTime, double)> points;

  @override
  Widget build(BuildContext context) {
    final sorted = [...points]..sort((a, b) => a.$1.compareTo(b.$1));
    final t0 = sorted.first.$1;
    double x(DateTime t) => t.difference(t0).inSeconds / 3600;
    final values = [for (final p in sorted) p.$2];
    final avg = values.reduce((a, b) => a + b) / values.length;
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final span = (hi - lo).abs() < 1 ? 1.0 : hi - lo;
    final fmt = DateFormat.Hm();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              '⌀ ${avg.round()}${unit.isEmpty ? '' : ' $unit'} · '
              '${lo.round()}–${hi.round()}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: LineChart(
            LineChartData(
              minY: lo - span * .1,
              maxY: hi + span * .1,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              titlesData: const FlTitlesData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: avg,
                    color: Colors.white24,
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [for (final p in sorted) FlSpot(x(p.$1), p.$2)],
                  isCurved: true,
                  curveSmoothness: .25,
                  color: color,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color.withValues(alpha: .3), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              fmt.format(sorted.first.$1),
              style: const TextStyle(color: muted, fontSize: 11),
            ),
            const Spacer(),
            Text(
              fmt.format(sorted.last.$1),
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
