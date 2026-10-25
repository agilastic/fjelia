import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/day_data_provider.dart';
import '../../widgets/app_widgets.dart';
import 'load_visuals.dart';

class TrainingFormCard extends ConsumerStatefulWidget {
  const TrainingFormCard({
    super.key,
    this.fullscreen = false,
    this.initialDays = 60,
  });
  final int initialDays;
  final bool fullscreen;
  @override
  ConsumerState<TrainingFormCard> createState() => _FormState();
}

class _FormState extends ConsumerState<TrainingFormCard> {
  late int days = widget.initialDays;
  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDateProvider);
    final end = DateTime(selected.year, selected.month, selected.day + 1);
    final start = DateTime(
      selected.year,
      selected.month,
      selected.day - days + 1,
    );
    final history = ref.watch(trainingFormSeriesProvider);
    final points = (history.valueOrNull ?? [])
        .where((p) => !p.date.isBefore(start) && p.date.isBefore(end))
        .toList();
    final last = points.lastOrNull;
    final colors = [loadBlue, loadRed, mint];
    final status = !history.hasValue && history.isLoading
        ? 'Loading'
        : !history.hasValue && history.hasError
        ? 'Unavailable'
        : formStatus(last?.tsb);
    final statusColor = last == null
        ? muted
        : last.tsb > 5
        ? mint
        : last.tsb < -10
        ? loadRed
        : loadOrange;
    return LoadCard(
      color: loadInset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'FORM · ATL / CTL / TSB',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFBBBBBB),
                    letterSpacing: .7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final n in [60, 30, 14])
                InkWell(
                  onTap: () => setState(() => days = n),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: days == n ? loadBlue.withValues(alpha: .2) : null,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${n}d',
                      style: TextStyle(
                        fontSize: 11,
                        color: days == n ? loadBlue : muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (!widget.fullscreen)
                IconButton(
                  tooltip: 'Expand training form',
                  constraints: const BoxConstraints.tightFor(
                    width: 24,
                    height: 30,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.fullscreen, size: 18, color: muted),
                  onPressed: () => showLoadSheet(
                    context,
                    LoadSheet(
                      title: 'FORM · ATL / CTL / TSB',
                      close: true,
                      child: SingleChildScrollView(
                        child: TrainingFormCard(
                          fullscreen: true,
                          initialDays: days,
                        ),
                      ),
                    ),
                    height: .8,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final stat in [
                ('CTL', last?.ctl, colors[0]),
                ('ATL', last?.atl, colors[1]),
                ('TSB', last?.tsb, statusColor),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stat.$1, style: loadCaption),
                      Text(
                        valueText(stat.$2),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: stat.$3,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: LoadBadge(status, color: statusColor, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (history.isLoading && !history.hasValue)
            SizedBox(
              height: widget.fullscreen ? 350 : 150,
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (history.hasError && !history.hasValue)
            DataError(
              history.error!,
              retry: () => ref.invalidate(trainingFormSeriesProvider),
            )
          else if (points.isEmpty)
            const EmptyState('No training history')
          else
            SizedBox(
              height: widget.fullscreen ? 350 : 150,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (days - 1).toDouble(),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: Colors.white10, strokeWidth: .6),
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
                        minIncluded: false,
                        maxIncluded: false,
                        getTitlesWidget: (v, _) => Text(
                          valueText(v),
                          style: const TextStyle(fontSize: 9, color: muted),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 25,
                        interval: days / 4,
                        minIncluded: true,
                        maxIncluded: true,
                        getTitlesWidget: (v, _) => Text(
                          DateFormat('d/M').format(
                            DateTime(
                              start.year,
                              start.month,
                              start.day + v.round(),
                            ),
                          ),
                          style: const TextStyle(fontSize: 9, color: muted),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    for (var i = 0; i < 3; i++)
                      LineChartBarData(
                        color: colors[i],
                        barWidth: i == 0 ? 2.5 : 1.5,
                        isCurved: true,
                        preventCurveOverShooting: true,
                        belowBarData: BarAreaData(
                          show: i == 0,
                          color: loadBlue.withValues(alpha: .045),
                        ),
                        dashArray: i == 2 ? [5, 4] : null,
                        dotData: FlDotData(show: points.length == 1),
                        spots: [
                          for (final p in points)
                            FlSpot(
                              DateTime.utc(
                                    p.date.year,
                                    p.date.month,
                                    p.date.day,
                                  )
                                  .difference(
                                    DateTime.utc(
                                      start.year,
                                      start.month,
                                      start.day,
                                    ),
                                  )
                                  .inDays
                                  .toDouble(),
                              i == 0
                                  ? p.ctl
                                  : i == 1
                                  ? p.atl
                                  : p.tsb,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 10,
            runSpacing: 5,
            children: [
              LoadLegend('Fitness (CTL)', loadBlue),
              LoadLegend('Fatigue (ATL)', loadRed),
              LoadLegend('Form (TSB)', mint),
            ],
          ),
          if (last?.historyStart != null) ...[
            const SizedBox(height: 8),
            Tooltip(
              message:
                  'Calculated from the first available load record. Days without recorded load count as zero; earlier training is unknown.',
              child: Text(
                'History since ${DateFormat.yMMMd().format(last!.historyStart!)}${last.historyDays! < 42 ? ' · building baseline' : ''}',
                style: loadCaption,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Form status label thresholds.
String formStatus(double? tsb) => tsb == null
    ? 'No history'
    : tsb > 15
    ? 'Fresh'
    : tsb > 5
    ? 'Optimal'
    : tsb > -10
    ? 'Neutral'
    : tsb > -20
    ? 'Tired'
    : 'Very Fatigued';
