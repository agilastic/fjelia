import '../../providers/activity_history_provider.dart';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/day_data_provider.dart';
import '../../widgets/app_widgets.dart';
import 'activities_screen.dart';
import 'load_visuals.dart';
import '../../utils/week.dart';
import '../../providers/week_start_provider.dart';

class WeekdayLoadCard extends ConsumerStatefulWidget {
  const WeekdayLoadCard({super.key});
  @override
  ConsumerState<WeekdayLoadCard> createState() => _WeekdayLoadState();
}

class _WeekdayLoadState extends ConsumerState<WeekdayLoadCard> {
  String metric = 'Load';
  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDateProvider);
    final mondayFirst = ref.watch(weekStartsOnMondayProvider);
    final monday = weekStartOf(selected, mondayFirst: mondayFirst);
    final previous = DateTime(monday.year, monday.month, monday.day - 7);
    final values = List.generate(14, (_) => 0.0);
    for (final a in ref.watch(loadActivitiesProvider).valueOrNull ?? []) {
      final d = DateTime.utc(
        a.startDate.year,
        a.startDate.month,
        a.startDate.day,
      );
      final i = d
          .difference(DateTime.utc(previous.year, previous.month, previous.day))
          .inDays;
      if (i < 0 || i >= 14) continue;
      values[i] += switch (metric) {
        'Time' => a.durationSeconds / 3600,
        'Distance' => (a.distanceMeters ?? 0) / 1000,
        _ => activityLoad(a),
      };
    }
    return LoadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WEEKDAY COMPARISON', style: loadLabel),
          const SizedBox(height: 12),
          LoadRange(
            labels: const ['Load', 'Time', 'Distance'],
            selected: metric,
            segmented: true,
            onChanged: (v) => setState(() => metric = v),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 16,
            children: [
              LoadLegend('Previous week', muted),
              LoadLegend('This week', mint),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: BarChart(
              BarChartData(
                maxY: math.max(1, values.reduce(math.max)) * 1.15,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        weekdayInitials(mondayFirst: mondayFirst)[v.toInt().clamp(
                          0,
                          6,
                        )],
                        style: loadCaption,
                      ),
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < 7; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          color: Colors.white24,
                          width: 8,
                        ),
                        BarChartRodData(
                          toY: values[i + 7],
                          color: mint,
                          width: 8,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrainingPlanProgressCard extends ConsumerWidget {
  const TrainingPlanProgressCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(trainingPlanMetaProvider)
      .when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => const SizedBox.shrink(),
        data: (plan) => plan == null
            ? const SizedBox.shrink()
            : LoadCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TRAINING PLAN PROGRESS', style: loadLabel),
                    const SizedBox(height: 10),
                    Text(
                      plan.planName,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Week ${plan.currentWeek} / ${plan.durationInWeeks}',
                      style: loadCaption,
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: plan.durationInWeeks > 0
                          ? (plan.currentWeek / plan.durationInWeeks).clamp(
                              0,
                              1,
                            )
                          : 0,
                      color: mint,
                      backgroundColor: Colors.white10,
                    ),
                  ],
                ),
              ),
      );
}
