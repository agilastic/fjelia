import '../../providers/connection_actions_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/source_priority_provider.dart';
import '../../providers/health_connect_provider.dart';
import '../../providers/hilo_sync_provider.dart';
import '../../providers/coros_provider.dart';
import '../../providers/suunto_provider.dart';
import '../../providers/polar_h10_provider.dart';
import '../../providers/polar_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/scale_pairing_tile.dart';
import '../../widgets/hilo_cuff_pairing_tile.dart';
import '../onboarding/connect_aktiia_screen.dart';
import '../onboarding/connect_garmin_screen.dart';
import '../onboarding/connect_health_screen.dart';
import '../onboarding/connect_hilo_ble_screen.dart';
import '../onboarding/connect_renpho_screen.dart';
import '../onboarding/connect_coros_screen.dart';
import '../onboarding/connect_suunto_screen.dart';
import '../onboarding/connect_polar_h10_screen.dart';
import '../onboarding/connect_polar_screen.dart';

class ConnectionsTab extends ConsumerWidget {
  const ConnectionsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return SheetPage(
      title: 'Connections',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionLabel('Apple Health'),
          _Connection(
            'Apple Health',
            ref.watch(healthConnectPermissionProvider).valueOrNull ?? false,
            const ConnectHealthScreen(fromOnboarding: true),
          ),
          const SectionLabel('Connected Services'),
          for (final e in <(ConnectionType, String, bool, Widget)>[
            (
              ConnectionType.garmin,
              'Garmin Connect',
              auth.garminConnected,
              const ConnectGarminScreen(fromOnboarding: true),
            ),
            (
              ConnectionType.bloodPressure,
              'Hilo (Blood Pressure)',
              auth.aktiiaConnected,
              const ConnectAktiiaScreen(fromOnboarding: true),
            ),
            (
              ConnectionType.bodyScale,
              'Renpho (Body Scale)',
              auth.renphoConnected,
              const ConnectRenphoScreen(fromOnboarding: true),
            ),
            (
              ConnectionType.coros,
              'Coros',
              ref.watch(corosConnectedProvider).valueOrNull ?? false,
              const ConnectCorosScreen(fromOnboarding: true),
            ),
            (
              ConnectionType.suunto,
              'Suunto',
              ref.watch(suuntoConnectedProvider).valueOrNull ?? false,
              const ConnectSuuntoScreen(fromOnboarding: true),
            ),
            (
              ConnectionType.polar,
              'Polar',
              ref.watch(polarConnectedProvider).valueOrNull ?? false,
              const ConnectPolarScreen(fromOnboarding: true),
            ),
          ])
            _Connection(
              e.$2,
              e.$3,
              e.$4,
              disconnect: () =>
                  ref.read(connectionActionsProvider).disconnect(e.$1),
            ),
          const SectionLabel('Hilo Blood Pressure BLE'),
          _Connection(
            'Hilo pod / cuff',
            ref.watch(hiloBleConnectedProvider).valueOrNull ?? false,
            const ConnectHiloBleScreen(fromOnboarding: true),
          ),
          SwitchListTile(
            title: const Text('Write Heart data to Apple Health'),
            value: ref.watch(hiloWriteHealthProvider),
            onChanged: (_) =>
                ref.read(hiloWriteHealthProvider.notifier).toggle(),
          ),
          SwitchListTile(
            title: const Text('Write Weight data to Apple Health'),
            value: ref.watch(renphoWriteHealthProvider),
            onChanged: (_) =>
                ref.read(renphoWriteHealthProvider.notifier).toggle(),
          ),
          const HiloCuffPairingTile(),
          const SectionLabel('Renpho Scale (BLE)'),
          const ScalePairingTile(),
          const SectionLabel('Polar H10 (HRV strap, BLE)'),
          _Connection(
            ref.watch(polarH10PairedProvider).valueOrNull?.name ?? 'Polar H10',
            ref.watch(polarH10PairedProvider).valueOrNull != null,
            const ConnectPolarH10Screen(fromOnboarding: true),
            disconnect: () => ref.read(polarH10ActionsProvider).unpair(),
          ),
          const SectionLabel('Data Source Priority'),
          const Text(
            'When multiple sources provide the same metric, the higher source wins. Drag to reorder.',
            style: TextStyle(color: muted, fontSize: 11),
          ),
          ref
              .watch(sourcePriorityProvider)
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => DataError(e),
                data: (groups) => Column(
                  children: [
                    for (final group in SourceGroup.values) ...[
                      SectionLabel(switch (group) {
                        SourceGroup.sleep => 'Sleep & Recovery',
                        SourceGroup.activity => 'Activities & Training',
                        SourceGroup.body => 'Body & Wellness',
                      }),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: groups[group.name]!.length,
                        onReorderItem: (a, b) => runUiAction(
                          context,
                          () => ref
                              .read(sourcePriorityProvider.notifier)
                              .reorder(group, a, b > a ? b + 1 : b),
                        ),
                        itemBuilder: (c, i) {
                          final source = groups[group.name]![i];
                          return Card(
                            key: ValueKey('${group.name}-$source'),
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              dense: true,
                              leading: Text('${i + 1}'),
                              title: Text(
                                const {
                                      'health_connect': 'Apple Health',
                                      'aktiia': 'Hilo',
                                      'hilo_ble': 'Hilo BLE',
                                      'garmin_api': 'Garmin (API)',
                                      'renpho': 'Renpho Scale',
                                    }[source] ??
                                    source,
                              ),
                              trailing: ReorderableDragStartListener(
                                index: i,
                                child: const Icon(Icons.drag_handle, size: 18),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
          TextButton(
            onPressed: () => runUiAction(
              context,
              () => ref.read(sourcePriorityProvider.notifier).reset(),
            ),
            child: const Text('Reset to default'),
          ),
        ],
      ),
    );
  }
}

class _Connection extends StatelessWidget {
  const _Connection(this.label, this.connected, this.screen, {this.disconnect});
  final Future<void> Function()? disconnect;
  final String label;
  final bool connected;
  final Widget screen;
  @override
  Widget build(BuildContext context) => SectionCard(
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(Icons.link, color: connected ? mint : muted),
      title: Text(label),
      subtitle: Text(
        connected ? 'Connected' : 'Not connected',
        style: const TextStyle(color: muted, fontSize: 10),
      ),
      trailing: connected && disconnect != null
          ? TextButton(
              onPressed: () async {
                if (await confirmAction(
                      context,
                      'Disconnect $label?',
                      'Your saved measurements will remain on this device.',
                    ) &&
                    context.mounted) {
                  await runUiAction(context, disconnect!);
                }
              },
              child: const Text(
                'Disconnect',
                style: TextStyle(color: Colors.redAccent, fontSize: 10),
              ),
            )
          : Text(
              connected ? 'Manage' : 'Connect',
              style: const TextStyle(color: mint, fontSize: 11),
            ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => screen),
      ),
    ),
  );
}
