import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/day_data_provider.dart';
import '../../widgets/app_widgets.dart';

class TrainingMetricsSheet extends ConsumerWidget {
  const TrainingMetricsSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(selectedDateProvider);
    return SheetPage(
      title: context.l10n.trainingMonitor,
      child: ref
          .watch(trainingMonitorProvider(d))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => DataError(e),
            data: (m) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final e in {
                  'CTL (Fitness)': m.ctl,
                  'ATL (Fatigue)': m.atl,
                  'TSB (Form)': m.ctl - m.atl,
                  'Daily load': m.dayLoad,
                  'Week hours': m.weekHours,
                  'Previous week hours': m.previousWeekHours,
                  'Week distance (km)': m.weekKm,
                  'Previous week distance (km)': m.previousWeekKm,
                  'VO₂max Run': m.vo2max,
                  'VO₂max Cycle': m.vo2maxCycling,
                }.entries)
                  SectionCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key),
                        Text(
                          valueText(e.value, 1),
                          style: const TextStyle(color: mint),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
    );
  }
}
