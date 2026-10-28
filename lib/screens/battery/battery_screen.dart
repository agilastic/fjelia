import '../../l10n/l10n_ext.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/garmin_data.dart';

import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/day_data_provider.dart';
import '../../widgets/app_widgets.dart';

class BatteryScreen extends ConsumerWidget {
  const BatteryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(selectedDateProvider);
    return SheetPage(
      title: context.l10n.energy,
      showBack: false,
      titleSize: 13,
      backgroundColor: panel,
      headerDivider: true,
      child: ref
          .watch(bodyBatteryReportProvider(d))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => DataError(e),
            data: (r) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Text(
                    context.l10n.currentEnergy,
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.4,
                      color: muted,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 190,
                    height: 170,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(190, 170),
                          painter: _EnergyArc(
                            r == null || r.samples.isEmpty
                                ? null
                                : r.samples.last.value.toDouble(),
                          ),
                        ),
                        Text(
                          r == null || r.samples.isEmpty
                              ? '—'
                              : '${r.samples.last.value}%',
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    r == null || r.samples.isEmpty
                        ? context.l10n.noData2
                        : r.samples.last.value < 50
                        ? context.l10n.lowReserve
                        : context.l10n.goodReserve,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                if (r != null && r.samples.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        context.l10n.latestReadingAtTolocal(
                          DateFormat.Hm().format(
                            r.samples.last.timestamp.toLocal(),
                          ),
                        ),
                        style: const TextStyle(color: muted, fontSize: 10),
                      ),
                    ),
                  ),
                if (r != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      children: [
                        for (final e in [
                          (
                            Icons.arrow_upward,
                            r.charged,
                            'CHARGED',
                            Colors.lightBlue,
                          ),
                          (
                            Icons.arrow_downward,
                            r.drained,
                            'DRAINED',
                            Colors.orange,
                          ),
                        ])
                          Expanded(
                            child: Column(
                              children: [
                                Icon(e.$1, size: 14, color: e.$4),
                                const SizedBox(height: 6),
                                Text(
                                  '${e.$3 == 'CHARGED' ? '+' : '−'}${valueText(e.$2)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  e.$3,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: muted,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const Divider(height: 20, color: Colors.white10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.dailyTimeline,
                        style: TextStyle(
                          fontSize: 10,
                          color: muted,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    if (r != null && r.samples.isNotEmpty)
                      Text(
                        context.l10n.valueValue2(
                          r.samples.first.value,
                          r.samples.last.value,
                        ),
                        style: const TextStyle(fontSize: 10, color: muted),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                EnergyTimeline(report: r),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, color: Colors.lightBlue, size: 8),
                    SizedBox(width: 5),
                    Text(
                      context.l10n.energy2,
                      style: TextStyle(fontSize: 10, color: muted),
                    ),
                    SizedBox(width: 20),
                    Icon(Icons.circle, color: Colors.white12, size: 8),
                    SizedBox(width: 5),
                    Text(
                      context.l10n.noData,
                      style: TextStyle(fontSize: 10, color: muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}

class _EnergyArc extends CustomPainter {
  const _EnergyArc(this.value);
  final double? value;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(12, 8, size.width - 24, size.width - 24);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = Colors.white12;
    canvas.drawArc(rect, math.pi * .75, math.pi * 1.5, false, paint);
    if (value != null) {
      paint.color = value! < 50 ? Colors.amber : mint;
      canvas.drawArc(
        rect,
        math.pi * .75,
        math.pi * 1.5 * (value! / 100).clamp(0, 1),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyArc oldDelegate) =>
      oldDelegate.value != value;
}

class EnergyTimeline extends StatelessWidget {
  const EnergyTimeline({super.key, required this.report});
  final BodyBatteryReport? report;
  @override
  Widget build(BuildContext context) {
    final r = report;
    if (r == null || r.samples.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: EmptyState(context.l10n.noEnergyMeasurementsForThis),
        ),
      );
    }
    final samples = r.samples.where((s) {
      final d = s.timestamp.toLocal();
      return d.year == r.date.year &&
          d.month == r.date.month &&
          d.day == r.date.day;
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 24,
          minY: 0,
          maxY: 100,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: true,
            horizontalInterval: 25,
            verticalInterval: 6,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Colors.white10,
              strokeWidth: .5,
              dashArray: [2, 3],
            ),
            getDrawingVerticalLine: (_) => const FlLine(
              color: Colors.white10,
              strokeWidth: .5,
              dashArray: [2, 3],
            ),
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
                reservedSize: 30,
                interval: 25,
                getTitlesWidget: (v, _) => Text(
                  valueText(v),
                  style: const TextStyle(fontSize: 8, color: muted),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 6,
                reservedSize: 24,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString().padLeft(2, '0'),
                  style: const TextStyle(fontSize: 9, color: muted),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (final s in samples)
                  FlSpot(
                    s.timestamp.toLocal().hour +
                        s.timestamp.toLocal().minute / 60,
                    s.value.toDouble(),
                  ),
              ],
              color: Colors.white,
              barWidth: 1.5,
              dotData: FlDotData(show: samples.length == 1),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.lightBlue.withValues(alpha: .35),
                    Colors.lightBlue.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
