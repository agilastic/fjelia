import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/heat_acclimation_provider.dart';
import '../../widgets/app_widgets.dart';
import 'load_visuals.dart';

class HeatWeatherSheet extends ConsumerStatefulWidget {
  const HeatWeatherSheet({super.key});
  @override
  ConsumerState<HeatWeatherSheet> createState() => _HeatWeatherState();
}

class _HeatWeatherState extends ConsumerState<HeatWeatherSheet> {
  int days = 7;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(heatTodayStateProvider);
    final history = ref.watch(heatHistoryProvider(days));
    return LoadSheet(
      title: 'HEAT ACCLIMATION',
      close: true,
      largeTitle: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        children: [
          state.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => DataError(e),
            data: (h) => h == null
                ? const EmptyState(
                    'Enable heat acclimation in Training settings.',
                  )
                : Row(
                    children: [
                      Text(
                        '${valueText(h.score)}%',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      LoadBadge(h.status.name.toUpperCase(), color: loadOrange),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          LoadRange(
            labels: const ['WEEK', 'MONTH', 'QUARTER', 'YEAR'],
            selected: {
              7: 'WEEK',
              30: 'MONTH',
              90: 'QUARTER',
              365: 'YEAR',
            }[days]!,
            color: loadOrange,
            onChanged: (v) => setState(
              () => days = {
                'WEEK': 7,
                'MONTH': 30,
                'QUARTER': 90,
                'YEAR': 365,
              }[v]!,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${{7: 'WEEK', 30: 'MONTH', 90: 'QUARTER', 365: 'YEAR'}[days]} TIMELINE',
            style: loadLabel,
          ),
          const SizedBox(height: 12),
          history.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => DataError(e),
            data: (rows) => LoadTrendChart(
              points: [for (final r in rows) ChartPoint(r.date, r.score)],
              color: loadOrange,
              minY: 0,
              maxY: 100,
              heat: true,
              height: 250,
            ),
          ),
        ],
      ),
    );
  }
}
