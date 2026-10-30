import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/coros_provider.dart';
import '../../providers/device_actions_provider.dart';
import '../../providers/health_connect_provider.dart';
import '../../providers/hilo_sync_provider.dart';
import '../../providers/polar_h10_provider.dart';
import '../../providers/polar_provider.dart';
import '../../providers/suunto_provider.dart';
import 'connect_aktiia_screen.dart';
import 'connect_coros_screen.dart';
import 'connect_garmin_screen.dart';
import 'connect_health_screen.dart';
import 'connect_hilo_ble_screen.dart';
import 'connect_polar_h10_screen.dart';
import 'connect_polar_screen.dart';
import 'connect_renpho_ble_screen.dart';
import 'connect_renpho_screen.dart';
import 'connect_suunto_screen.dart';
import 'ai_coach_onboarding_screen.dart';

/// Onboarding grid of every supported source.
class ConnectDevicesScreen extends ConsumerWidget {
  const ConnectDevicesScreen({super.key});

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));

  ({List<_DeviceTile> ble, List<_DeviceTile> api}) _tiles(
    BuildContext context, {
    required AuthState auth,
    required bool hiloBle,
    required bool coros,
    required bool suunto,
    required bool polar,
    required bool health,
    required bool renphoBle,
    required bool polarH10,
  }) {
    final tiles = [
      _DeviceTile(
        icon: Icons.bluetooth_rounded,
        color: const Color(0xFF00C4B4),
        name: context.l10n.hiloPod,
        subtitle: context.l10n.bluetoothBloodPressure,
        connected: hiloBle,
        onTap: () =>
            _push(context, const ConnectHiloBleScreen(fromOnboarding: true)),
      ),
      _DeviceTile(
        icon: Icons.favorite_rounded,
        color: const Color(0xFFFF4444),
        name: context.l10n.hiloAccount,
        subtitle: context.l10n.cloudCuffData,
        connected: auth.aktiiaConnected,
        onTap: () =>
            _push(context, const ConnectAktiiaScreen(fromOnboarding: true)),
      ),
      _DeviceTile(
        icon: Icons.watch_rounded,
        color: const Color(0xFF1A73E8),
        name: context.l10n.garmin,
        subtitle: context.l10n.apiSync,
        connected: auth.garminConnected,
        onTap: () =>
            _push(context, const ConnectGarminScreen(fromOnboarding: true)),
      ),
      _DeviceTile(
        icon: Icons.watch_rounded,
        color: const Color(0xFF00C8FF),
        name: context.l10n.coros,
        subtitle: context.l10n.apiSync,
        connected: coros,
        onTap: () =>
            _push(context, const ConnectCorosScreen(fromOnboarding: true)),
      ),
      _DeviceTile(
        icon: Icons.watch_rounded,
        color: const Color(0xFFE84C22),
        name: context.l10n.suunto,
        subtitle: context.l10n.apiSync,
        connected: suunto,
        onTap: () =>
            _push(context, const ConnectSuuntoScreen(fromOnboarding: true)),
      ),
      _DeviceTile(
        icon: Icons.monitor_heart_outlined,
        color: const Color(0xFFFF5A5F),
        name: context.l10n.polarH10,
        subtitle: context.l10n.bluetoothHrvStrap,
        connected: polarH10,
        onTap: () =>
            _push(context, const ConnectPolarH10Screen(fromOnboarding: true)),
      ),
      _DeviceTile(
        icon: Icons.watch_rounded,
        color: const Color(0xFFD0011B),
        name: context.l10n.polar,
        subtitle: context.l10n.accesslinkApi,
        connected: polar,
        onTap: () =>
            _push(context, const ConnectPolarScreen(fromOnboarding: true)),
      ),
      _DeviceTile(
        icon: Icons.favorite_border_rounded,
        color: const Color(0xFFFF4444),
        name: context.l10n.appleHealth,
        subtitle: context.l10n.systemHealthData,
        connected: health,
        onTap: () =>
            _push(context, const ConnectHealthScreen(fromOnboarding: true)),
      ),
      _DeviceTile(
        icon: Icons.monitor_weight_rounded,
        color: const Color(0xFF9C27B0),
        name: context.l10n.renphoAccount,
        subtitle: context.l10n.cloudScaleHistory,
        connected: auth.renphoConnected,
        onTap: () =>
            _push(context, const ConnectRenphoScreen(fromOnboarding: true)),
      ),
      _DeviceTile(
        icon: Icons.monitor_weight_rounded,
        color: const Color(0xFF9C27B0),
        name: 'RENPHO scale',
        subtitle: context.l10n.bluetoothWeightBody,
        connected: renphoBle,
        onTap: () =>
            _push(context, const ConnectRenphoBleScreen(fromOnboarding: true)),
      ),
    ];
    // Bluetooth devices pair directly with the phone; the rest sign in to an
    // account or system service.
    bool isBle(_DeviceTile t) => t.subtitle.startsWith('Bluetooth');
    return (
      ble: [
        for (final t in tiles)
          if (isBle(t)) t,
      ],
      api: [
        for (final t in tiles)
          if (!isBle(t)) t,
      ],
    );
  }

  Widget _section(String title, List<_DeviceTile> tiles) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: tiles,
      ),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = _tiles(
      context,
      auth: ref.watch(authProvider),
      hiloBle: ref.watch(hiloBleConnectedProvider).valueOrNull ?? false,
      coros: ref.watch(corosConnectedProvider).valueOrNull ?? false,
      suunto: ref.watch(suuntoConnectedProvider).valueOrNull ?? false,
      polar: ref.watch(polarConnectedProvider).valueOrNull ?? false,
      health: ref.watch(healthConnectPermissionProvider).valueOrNull ?? false,
      renphoBle: ref.watch(renphoBleConnectedProvider).valueOrNull ?? false,
      polarH10: ref.watch(polarH10PairedProvider).valueOrNull != null,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                context.l10n.connectYourDevices,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                context.l10n.connectAnyCombinationYouCan,
                style: TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _section(context.l10n.bluetoothDevices, tiles.ble),
                  const SizedBox(height: 20),
                  _section(context.l10n.accountsServices, tiles.api),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4A0),
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AiCoachOnboardingScreen(),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.l10n.continueLabel),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.icon,
    required this.color,
    required this.name,
    required this.subtitle,
    required this.connected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String name;
  final String subtitle;
  final bool connected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: connected
                ? const Color(0xFF00D4A0)
                : const Color(0xFF333333),
            width: connected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                if (connected)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4A0).withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Color(0xFF00D4A0),
                    ),
                  )
                else
                  const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: Color(0xFF888888),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
