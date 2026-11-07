import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_ext.dart';
import '../models/indoor_recording.dart';
import '../providers/activity_blood_pressure_provider.dart';
import 'app_widgets.dart';

/// Blood pressure taken during an activity, on its own time axis below the
/// heart-rate, pace and elevation charts: each reading as a bar from
/// diastolic to systolic, then the list. Cuffs often cannot measure while
/// moving, so an empty card says why.
class ActivityBloodPressureCard extends ConsumerWidget {
  const ActivityBloodPressureCard({super.key, required this.capture});
  final IndoorCapture capture;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!capture.includeBloodPressure) return const SizedBox.shrink();
    final l = context.l10n;
    final readings = ref.watch(
      activityBloodPressureProvider(capture.startedAt),
    );
    final rows =
        (readings.valueOrNull ?? [])
            .where((r) => bloodPressureDuringActivity(capture, r))
            .toList()
          ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    final end = capture.samples.isEmpty
        ? capture.startedAt
        : DateTime.fromMillisecondsSinceEpoch(
            capture.samples.last['t']!.round(),
            isUtc: true,
          );
    double minuteOf(DateTime at) =>
        at.toUtc().difference(capture.startedAt).inSeconds / 60;
    final maxX = math.max(1.0, minuteOf(end));
    final maxY = math.max(
      180.0,
      rows.fold<double>(0, (m, r) => math.max(m, r.systolic + 10.0)),
    );
    return SectionCard(
      title: l.typeBloodPressure,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (readings.isLoading) const LinearProgressIndicator(),
          if (readings.hasError) Text(l.manualBpUnavailable),
          if (!readings.isLoading && rows.isEmpty) ...[
            Text(l.manualBpEmpty),
            const SizedBox(height: 4),
            Text(
              l.bpActivityHint,
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ],
          if (rows.isNotEmpty) ...[
            SizedBox(
              key: const ValueKey('activity-bp-chart'),
              height: 130,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxX,
                  minY: 40,
                  maxY: maxY,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 40,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Colors.white12,
                      strokeWidth: .5,
                      dashArray: [4, 4],
                    ),
                  ),
                  lineTouchData: const LineTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 40,
                        getTitlesWidget: (v, _) => Text(
                          v.round().toString(),
                          style: const TextStyle(fontSize: 9, color: muted),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 18,
                        interval: math.max(5, (maxX / 4).roundToDouble()),
                        getTitlesWidget: (v, _) => Text(
                          '${v.round()}′',
                          style: const TextStyle(fontSize: 9, color: muted),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    for (final r in rows)
                      LineChartBarData(
                        spots: [
                          FlSpot(
                            minuteOf(r.measuredAt),
                            r.diastolic.toDouble(),
                          ),
                          FlSpot(minuteOf(r.measuredAt), r.systolic.toDouble()),
                        ],
                        color: _bpColor,
                        barWidth: 6,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                            radius: 3.5,
                            color: Colors.white,
                            strokeColor: _bpColor,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Text(
                      DateFormat.Hm().format(r.measuredAt.toLocal()),
                      style: const TextStyle(color: muted),
                    ),
                    const SizedBox(width: 12),
                    Text.rich(
                      TextSpan(
                        text: '${r.systolic}/${r.diastolic}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        children: const [
                          TextSpan(
                            text: ' mmHg',
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (r.heartRate > 0)
                      Text(
                        '${r.heartRate} bpm',
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

const _bpColor = Color(0xFFFF5C7A);

class RecordedActivityBloodPressureCard extends ConsumerWidget {
  const RecordedActivityBloodPressureCard({
    super.key,
    required this.activityId,
  });
  final String activityId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capture = ref.watch(activityCaptureProvider(activityId)).valueOrNull;
    return capture == null
        ? const SizedBox.shrink()
        : ActivityBloodPressureCard(capture: capture);
  }
}
