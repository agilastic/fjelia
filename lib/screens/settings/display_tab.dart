import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/visibility_provider.dart';
import '../../widgets/app_widgets.dart';

class DisplayTab extends ConsumerWidget {
  const DisplayTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthVisibilityProvider).valueOrNull ?? {},
        load = ref.watch(loadVisibilityProvider).valueOrNull ?? {};
    return SheetPage(
      title: context.l10n.display,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionLabel(context.l10n.healthPage),
          SectionCard(
            child: Column(
              children: [
                for (final e in healthItemLabels.entries)
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          dense: true,
                          title: Text(
                            _visibilityLabel(context, e.key, e.value),
                          ),
                          onTap: e.key == 'health_monitor'
                              ? () => showAppSheet(
                                  context,
                                  const _MonitorVisibility(),
                                )
                              : null,
                        ),
                      ),
                      Switch(
                        value: health[e.key] ?? true,
                        onChanged: (_) => runUiAction(
                          context,
                          () => ref
                              .read(healthVisibilityProvider.notifier)
                              .toggle(e.key),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SectionLabel(context.l10n.loadPage),
          SectionCard(
            child: Column(
              children: [
                for (final e in loadItemLabels.entries)
                  SwitchListTile(
                    dense: true,
                    title: Text(_visibilityLabel(context, e.key, e.value)),
                    value: load[e.key] ?? true,
                    onChanged: (_) => runUiAction(
                      context,
                      () => ref
                          .read(loadVisibilityProvider.notifier)
                          .toggle(e.key),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitorVisibility extends ConsumerWidget {
  const _MonitorVisibility();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vis = ref.watch(healthMonitorVisibilityProvider).valueOrNull ?? {};
    return SheetPage(
      title: context.l10n.healthMonitor,
      child: ListView(
        children: [
          for (final e in healthMonitorItemLabels.entries)
            SwitchListTile(
              title: Text(_visibilityLabel(context, e.key, e.value)),
              value: vis[e.key] ?? true,
              onChanged: (_) => runUiAction(
                context,
                () => ref
                    .read(healthMonitorVisibilityProvider.notifier)
                    .toggle(e.key),
              ),
            ),
        ],
      ),
    );
  }
}

/// Card names are stored by key; the English label in the provider is the
/// fallback for a key without a translation.
String _visibilityLabel(BuildContext context, String key, String fallback) {
  final l10n = context.l10n;
  return switch (key) {
    'health_monitor' => l10n.healthMonitor,
    'hr_timeline' => l10n.hrTimeline,
    'grip_strength' => l10n.gripStrength,
    'body_composition' => l10n.bodyComposition,
    'bio_age' => l10n.biologicalAge,
    'heat_acclimation' => l10n.heatAcclimation,
    'day_load' => l10n.dayTrainingLoad,
    'weekday_load' => l10n.weekdayComparison,
    'weekly_load' => l10n.weeklyTrainingLoad,
    'zone_polarization' => l10n.zonePolarization,
    'elevation' => l10n.elevationOverview,
    'strain' => l10n.trainingMonitor,
    'form' => l10n.formAtlCtlTsb,
    'plan_banner' => l10n.trainingPlanProgress,
    'rhr' => l10n.rhrSleep,
    'hrv' => l10n.hrvSleep,
    'spo2' => l10n.spo2Sleep,
    'resp' => l10n.respRate,
    'stress' => l10n.stress,
    'skin_temp' => l10n.skinTemp,
    'steps' => l10n.steps,
    'sleep' => l10n.tonightsSleep,
    'bp' => l10n.typeBloodPressure,
    _ => fallback,
  };
}
