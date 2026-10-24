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
      title: 'Display',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionLabel('Health Page'),
          SectionCard(
            child: Column(
              children: [
                for (final e in healthItemLabels.entries)
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          dense: true,
                          title: Text(e.value),
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
          const SectionLabel('Load Page'),
          SectionCard(
            child: Column(
              children: [
                for (final e in loadItemLabels.entries)
                  SwitchListTile(
                    dense: true,
                    title: Text(e.value),
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
      title: 'Health Monitor',
      child: ListView(
        children: [
          for (final e in healthMonitorItemLabels.entries)
            SwitchListTile(
              title: Text(e.value),
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
