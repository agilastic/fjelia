import '../../l10n/l10n_ext.dart';
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
import '../../widgets/hrv_reminder_tile.dart';
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
      title: context.l10n.connections,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionLabel(context.l10n.appleHealth),
          _Connection(
            context.l10n.appleHealth,
            ref.watch(healthConnectPermissionProvider).valueOrNull ?? false,
            const ConnectHealthScreen(fromOnboarding: true),
          ),
          SectionLabel(context.l10n.connectedServices),
          for (final e in <(ConnectionType, String, bool, Widget)>[
            (
              ConnectionType.garmin,
              context.l10n.garminConnect,
              auth.garminConnected,
              const ConnectGarminScreen(fromOnboarding: true),
            ),
            (
              ConnectionType.bloodPressure,
              context.l10n.hiloBloodPressure,
              auth.aktiiaConnected,
              const ConnectAktiiaScreen(fromOnboarding: true),
            ),
            (
              ConnectionType.bodyScale,
              context.l10n.renphoBodyScale,
              auth.renphoConnected,
              const ConnectRenphoScreen(fromOnboarding: true),
            ),
            (
              ConnectionType.coros,
              context.l10n.coros,
              ref.watch(corosConnectedProvider).valueOrNull ?? false,
              const ConnectCorosScreen(fromOnboarding: true),
            ),
            (
              ConnectionType.suunto,
              context.l10n.suunto,
              ref.watch(suuntoConnectedProvider).valueOrNull ?? false,
              const ConnectSuuntoScreen(fromOnboarding: true),
            ),
            (
              ConnectionType.polar,
              context.l10n.polar,
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
          SectionLabel(context.l10n.hiloBloodPressureBle),
          _Connection(
            context.l10n.hiloPodCuff,
            ref.watch(hiloBleConnectedProvider).valueOrNull ?? false,
            const ConnectHiloBleScreen(fromOnboarding: true),
          ),
          SwitchListTile(
            title: Text(context.l10n.writeHeartDataToApple),
            value: ref.watch(hiloWriteHealthProvider),
            onChanged: (_) =>
                ref.read(hiloWriteHealthProvider.notifier).toggle(),
          ),
          SwitchListTile(
            title: Text(context.l10n.writeWeightDataToApple),
            value: ref.watch(renphoWriteHealthProvider),
            onChanged: (_) =>
                ref.read(renphoWriteHealthProvider.notifier).toggle(),
          ),
          const HiloCuffPairingTile(),
          SectionLabel(context.l10n.renphoScaleBle),
          const ScalePairingTile(),
          SectionLabel(context.l10n.polarH10HrvStrapBle),
          _Connection(
            ref.watch(polarH10PairedProvider).valueOrNull?.name ??
                context.l10n.polarH10,
            ref.watch(polarH10PairedProvider).valueOrNull != null,
            const ConnectPolarH10Screen(fromOnboarding: true),
            disconnect: () => ref.read(polarH10ActionsProvider).unpair(),
          ),
          HrvReminderTile(),
          SectionLabel(context.l10n.dataSourcePriority),
          Text(
            context.l10n.whenMultipleSourcesProvideThe,
            style: TextStyle(color: muted, fontSize: 11),
          ),
          ref
              .watch(sourcePriorityProvider)
              .when(
                loading: () => LinearProgressIndicator(),
                error: (e, _) => DataError(e),
                data: (groups) => Column(
                  children: [
                    for (final group in SourceGroup.values) ...[
                      SectionLabel(switch (group) {
                        SourceGroup.sleep => context.l10n.sleepRecovery,
                        SourceGroup.activity => context.l10n.activitiesTraining,
                        SourceGroup.body => context.l10n.bodyWellness,
                      }),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
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
                            margin: EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              dense: true,
                              leading: Text('${i + 1}'),
                              title: Text(
                                {
                                      'health_connect':
                                          context.l10n.appleHealth,
                                      'aktiia': context.l10n.hilo,
                                      'hilo_ble': context.l10n.hiloBle,
                                      'garmin_api': context.l10n.garminApi,
                                      'renpho': context.l10n.renphoScale,
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
            child: Text(context.l10n.resetToDefault),
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
        connected ? context.l10n.connected : context.l10n.notConnected,
        style: const TextStyle(color: muted, fontSize: 10),
      ),
      trailing: connected && disconnect != null
          ? TextButton(
              onPressed: () async {
                if (await confirmAction(
                      context,
                      context.l10n.disconnectLabel(label),
                      context.l10n.yourSavedMeasurementsWillRemain,
                    ) &&
                    context.mounted) {
                  await runUiAction(context, disconnect!);
                }
              },
              child: Text(
                context.l10n.disconnect,
                style: TextStyle(color: Colors.redAccent, fontSize: 10),
              ),
            )
          : Text(
              connected ? context.l10n.manage : context.l10n.connect,
              style: const TextStyle(color: mint, fontSize: 11),
            ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => screen),
      ),
    ),
  );
}
