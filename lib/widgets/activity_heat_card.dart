import '../l10n/l10n_ext.dart';
import '../providers/activity_heat_provider.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_widgets.dart';

class ActivityHeatCard extends ConsumerWidget {
  const ActivityHeatCard({super.key, required this.activityId});
  final String activityId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(activityHeatDetailsProvider(activityId)).valueOrNull;
    final h = data?.context;
    if (h == null) return const SizedBox.shrink();
    final samples = data!.samples;
    final temps =
        samples.map((s) => s.temperatureC).where((v) => v.isFinite).toList()
          ..sort();
    final temperature = temps.length < 2
        ? '${valueText(h.temperatureC, 1)} °C'
        : '${valueText(temps.first, 1)}–${valueText(temps.last, 1)} °C';
    final delta = h.scoreAfter - h.scoreBefore;
    final color = h.qualifies ? mint : Colors.redAccent;
    Widget cell(String label, String value) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: .8,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return SectionCard(
      color: const Color(0xFF282828),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                size: 18,
                color: Colors.orange,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.l10n.heatAcclimation2,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: Colors.white70,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  h.qualifies
                      ? context.l10n.qualified
                      : context.l10n.noHeatLoad,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                context.l10n.scorebeforeScoreafter(
                  valueText(h.scoreBefore),
                  valueText(h.scoreAfter),
                ),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${delta > 0 ? '+' : ''}${valueText(delta, 1)}',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            h.qualifies
                ? context.l10n.workoutQualifiedForHeatAccumulation
                : context.l10n.workoutDidNotAddHeat,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              cell(context.l10n.temp, temperature),
              cell(context.l10n.humidity2, '${valueText(h.humidityPct)}%'),
              cell(context.l10n.pressure, '${valueText(h.pressureHpa)} hPa'),
              cell(context.l10n.wetBulb, '${valueText(h.wetBulbC, 1)} °C'),
            ],
          ),
          if (samples.length > 1) ...[
            const SizedBox(height: 26),
            Text(
              context.l10n.temperatureOverTime,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 115,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
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
                        reservedSize: 28,
                        getTitlesWidget: (v, _) => Text(
                          context.l10n.round2(v.round()),
                          style: const TextStyle(fontSize: 9, color: muted),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        interval: 1,
                        getTitlesWidget: (v, _) => Text(
                          context.l10n.roundh(v.round()),
                          style: const TextStyle(fontSize: 9, color: muted),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (final s in samples)
                          if (s.temperatureC.isFinite)
                            FlSpot(
                              s.observedAt
                                      .difference(h.activityStart)
                                      .inSeconds /
                                  3600,
                              s.temperatureC,
                            ),
                      ],
                      color: Colors.orange,
                      isCurved: true,
                      barWidth: 2,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.withValues(alpha: .1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
