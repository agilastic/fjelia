import 'dart:math' as math;

import '../providers/health_monitor_alerts_provider.dart';
import '../providers/health_monitor_trends_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/day_data_provider.dart';
import '../providers/visibility_provider.dart';
import 'app_widgets.dart';
import 'metric_card.dart';
import 'metric_detail_sheet.dart';

class HealthMonitorGrid extends ConsumerWidget {
  const HealthMonitorGrid({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider),
        h = ref.watch(hrvForDateProvider(date)).valueOrNull,
        w = ref.watch(wellnessForDateProvider(date)).valueOrNull;
    final vis = ref.watch(healthMonitorVisibilityProvider).valueOrNull ?? {};
    final alerts =
        ref.watch(healthMonitorAlertsProvider(date)).valueOrNull ??
        <HealthMetric>{};
    final trends = ref.watch(healthMonitorTrendsProvider(date));
    final need = ref.watch(dayScoresProvider(date)).valueOrNull?.sleep?.need;
    final values = <String, (HealthMetric, num?, String)>{
      'rhr': (HealthMetric.rhr, h?.restingHeartRate, 'bpm'),
      'hrv': (HealthMetric.hrv, h?.hrvLastNight, 'ms'),
      'spo2': (HealthMetric.spo2, h?.spo2, '%'),
      'resp': (HealthMetric.respiration, h?.respirationRate, 'rpm'),
      'stress': (HealthMetric.stress, h?.stressLevel, '/100'),
      'skin_temp': (HealthMetric.skinTemperature, h?.skinTempDelta, '°C'),
      'steps': (HealthMetric.steps, w?.steps, 'steps'),
      'sleep': (
        HealthMetric.sleep,
        need == null ? null : need.inMinutes / 60,
        '',
      ),
    };
    return SectionCard(
      title: 'Health Monitor',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(11) / 11;
          final columns = constraints.maxWidth < 240 || textScale >= 1.3
              ? 1
              : 2;
          final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;
          final height = math.max(
            columns == 2 ? width / 2.05 : 0.0,
            90.0 * math.max(1.0, textScale),
          );
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in values.entries)
                if (vis[e.key] ?? true)
                  SizedBox(
                    width: width,
                    height: height,
                    child: MetricCard(
                      label: e.value.$1.label,
                      highlighted: alerts.contains(e.value.$1),
                      icon: switch (e.key) {
                        'hrv' => Icons.show_chart,
                        'spo2' => Icons.air,
                        'resp' => Icons.waves,
                        'stress' => Icons.psychology_outlined,
                        'skin_temp' => Icons.thermostat,
                        'steps' => Icons.directions_walk,
                        'sleep' => Icons.bedtime_outlined,
                        _ => Icons.favorite_border,
                      },
                      showTrend: e.key != 'sleep' && e.key != 'steps',
                      trendDelta: e.key == 'rhr'
                          ? trends.rhr
                          : e.key == 'hrv'
                          ? trends.hrv
                          : null,
                      higherIsBetter: e.key != 'rhr',
                      helper: e.key == 'sleep'
                          ? 'recommended'
                          : e.key == 'steps'
                          ? '/ 10k steps'
                          : null,
                      value: e.key == 'sleep' && need != null
                          ? '${need.inHours}h ${(need.inMinutes % 60).toString().padLeft(2, '0')}min'
                          : valueText(
                              e.value.$2,
                              e.key == 'resp' ||
                                      e.key == 'skin_temp' ||
                                      e.key == 'sleep'
                                  ? 1
                                  : 0,
                            ),
                      unit: e.value.$3,
                      color: Colors.white,
                      onTap: () => MetricDetailSheet.show(context, e.value.$1),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
