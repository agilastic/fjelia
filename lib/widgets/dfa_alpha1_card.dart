import '../theme/fjelia_style.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/formats.dart';
import '../l10n/l10n_ext.dart';
import '../providers/dfa_alpha1_provider.dart';
import '../services/dfa_alpha1.dart';
import 'app_widgets.dart';

/// DFA alpha1 over the session and, when the session crossed them, the heart
/// rate (and power or pace) at the aerobic and anaerobic thresholds.
class DfaAlpha1Card extends ConsumerWidget {
  const DfaAlpha1Card({
    super.key,
    required this.activityId,
    required this.running,
  });

  final String activityId;

  /// Shows pace instead of power at the thresholds.
  final bool running;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dfa = ref.watch(dfaAlpha1Provider(activityId)).valueOrNull;
    if (dfa == null || dfa.windows.length < 3) return const SizedBox.shrink();
    final l10n = context.l10n;
    String threshold(DfaThreshold t) => [
      '${t.heartRate.round()} bpm',
      if (!running && t.watts != null) '${t.watts!.round()} W',
      if (running && t.speed != null && t.speed! > 0) _pace(t.speed!),
    ].join(' · ');
    final easy = dfa.easyShare;
    return SectionCard(
      title: l10n.dfaAlpha1Title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dfa.hrvt1 != null)
            _Row(l10n.dfaHrvt1, threshold(dfa.hrvt1!), mint),
          if (dfa.hrvt2 != null)
            _Row(l10n.dfaHrvt2, threshold(dfa.hrvt2!), Colors.orangeAccent),
          if (dfa.hrvt1 == null && dfa.hrvt2 == null) ...[
            if (easy != null)
              Text(l10n.dfaEasyShare((easy * 100).round().toString())),
            const SizedBox(height: 4),
            Text(
              l10n.dfaNoThreshold,
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(height: 120, child: _Chart(dfa.windows)),
          const SizedBox(height: 8),
          Text(
            l10n.dfaBeats(dfa.rrCount, (dfa.artifacts * 100).fixed(1)),
            style: TextStyle(color: muted, fontSize: 11),
          ),
          if (dfa.artifacts > dfaMaxArtifacts)
            Text(
              l10n.dfaArtifactsHigh,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
            ),
          const SizedBox(height: 4),
          Text(l10n.dfaExplainer, style: TextStyle(color: muted, fontSize: 11)),
        ],
      ),
    );
  }

  static String _pace(double metresPerSecond) {
    final seconds = (1000 / metresPerSecond).round();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} /km';
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _Chart extends StatelessWidget {
  const _Chart(this.windows);
  final List<DfaWindow> windows;

  @override
  Widget build(BuildContext context) {
    final start = windows.first.t;
    final spots = [
      for (final w in windows)
        FlSpot((w.t - start) / 60000, w.alpha1.clamp(0.0, 1.6)),
    ];
    HorizontalLine line(double y, Color color) => HorizontalLine(
      y: y,
      color: color.withValues(alpha: .7),
      strokeWidth: 1,
      dashArray: [6, 4],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        style: TextStyle(color: color, fontSize: 8),
        labelResolver: (_) => y.toStringAsFixed(2),
      ),
    );
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 1.6,
        minX: 0,
        maxX: spots.last.x,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 0.5,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(1),
                style: TextStyle(color: muted, fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              interval: spots.last.x > 90 ? 30 : 10,
              getTitlesWidget: (v, _) => Text(
                '${v.round()}′',
                style: TextStyle(color: muted, fontSize: 9),
              ),
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            line(hrvt1Alpha, mint),
            line(hrvt2Alpha, Colors.orangeAccent),
          ],
        ),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: fjInk70,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
