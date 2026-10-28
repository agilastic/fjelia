import '../../l10n/l10n_ext.dart';
import '../../providers/activity_history_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/day_data_provider.dart';
import '../../widgets/app_widgets.dart';
import 'load_visuals.dart';

/// Each monitor tile opens its own history, rather than the threshold menu.
class LoadMetricSheet extends ConsumerStatefulWidget {
  const LoadMetricSheet({super.key, required this.metric});
  final String metric;
  @override
  ConsumerState<LoadMetricSheet> createState() => _LoadMetricState();
}

class _LoadMetricState extends ConsumerState<LoadMetricSheet> {
  int days = 14;
  @override
  Widget build(BuildContext context) {
    final date = ref.watch(selectedDateProvider);
    final end = DateTime(date.year, date.month, date.day + 1);
    final start = DateTime(date.year, date.month, date.day - days + 1);
    final distance = widget.metric == 'Activity km';
    final activity = distance || widget.metric == 'Activity hours';
    final points = <ChartPoint>[];
    if (activity) {
      final totals = <DateTime, double>{
        for (var i = 0; i < days; i++)
          DateTime(start.year, start.month, start.day + i): 0,
      };
      for (final a in ref.watch(loadActivitiesProvider).valueOrNull ?? []) {
        final day = DateTime(
          a.startDate.year,
          a.startDate.month,
          a.startDate.day,
        );
        if (!totals.containsKey(day)) continue;
        totals[day] =
            totals[day]! +
            (distance
                ? (a.distanceMeters ?? 0) / 1000
                : a.durationSeconds / 3600);
      }
      points.addAll(totals.entries.map((e) => ChartPoint(e.key, e.value)));
    } else {
      for (final row
          in ref.watch(wellnessRangeProvider(90)).valueOrNull ?? []) {
        if (row.date.isBefore(start) || !row.date.isBefore(end)) continue;
        final value = widget.metric == 'VO₂max cycling'
            ? row.vo2maxCycling
            : row.vo2max;
        if (value != null) points.add(ChartPoint(row.date, value));
      }
    }
    final measured = activity
        ? points.where((p) => p.value > 0).toList()
        : points;
    final average = measured.isEmpty
        ? null
        : measured.fold<double>(0, (v, p) => v + p.value) / measured.length;
    final unit = activity ? (distance ? 'km' : 'h') : 'ml/kg/min';
    return LoadSheet(
      title: loadMetricLabel(
        context,
        widget.metric,
      ).toUpperCase().replaceAll('₂', '2'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          LoadRange(
            labels: const ['14D', '30D', '90D'],
            selected: '${days}D',
            onChanged: (v) =>
                setState(() => days = int.parse(v.replaceAll('D', ''))),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: loadInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                context.l10n.avgAverageUnit(valueText(average, 1), unit),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          LoadTrendChart(
            points: points,
            bars: true,
            average: average,
            height: 150,
          ),
          const SizedBox(height: 10),
          LoadLegend(
            '$days-day avg  ${valueText(average, 1)} $unit',
            mint.withValues(alpha: .65),
            line: true,
          ),
        ],
      ),
    );
  }
}
