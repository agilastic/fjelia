import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_ext.dart';
import '../providers/polar_h10_provider.dart';
import 'app_widgets.dart';

/// Below this the coin cell should be replaced soon.
const h10BatteryLow = 20;

IconData h10BatteryIcon(int level) => switch (level) {
  >= 80 => Icons.battery_full,
  >= 60 => Icons.battery_5_bar,
  >= 40 => Icons.battery_3_bar,
  >= h10BatteryLow => Icons.battery_2_bar,
  _ => Icons.battery_alert,
};

Color h10BatteryColor(int level) => level < h10BatteryLow
    ? Colors.redAccent
    : level < 40
    ? Colors.amber
    : mint;

/// "🔋 80 %" while the strap is connected.
class H10BatteryChip extends StatelessWidget {
  const H10BatteryChip({super.key, required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    final color = h10BatteryColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(h10BatteryIcon(level), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$level %',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The paired strap's battery in Settings: last reading, when, a warning
/// when low, and a button that wakes the strap and reads it again.
class PolarH10BatteryTile extends ConsumerStatefulWidget {
  const PolarH10BatteryTile({super.key});

  @override
  ConsumerState<PolarH10BatteryTile> createState() =>
      _PolarH10BatteryTileState();
}

class _PolarH10BatteryTileState extends ConsumerState<PolarH10BatteryTile> {
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    int? level;
    try {
      level = await ref.read(polarH10ActionsProvider).checkBattery();
    } catch (_) {
      level = null;
    }
    if (!mounted) return;
    setState(() => _checking = false);
    if (level == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.h10BatteryUnreachable)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(polarH10PairedProvider).valueOrNull == null) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final battery = ref.watch(polarH10BatteryProvider).valueOrNull;
    final level = battery?.level;
    final color = level == null ? muted : h10BatteryColor(level);
    return ListTile(
      leading: Icon(
        level == null ? Icons.battery_unknown : h10BatteryIcon(level),
        color: color,
      ),
      title: Text(
        level == null ? l10n.h10BatteryUnknown : l10n.h10Battery(level),
      ),
      subtitle: Text(
        [
          if (battery != null)
            l10n.h10BatteryChecked(
              DateFormat.MMMd().add_Hm().format(battery.at.toLocal()),
            ),
          if (level != null && level < h10BatteryLow) l10n.h10BatteryLowHint,
        ].join('\n'),
        style: TextStyle(
          fontSize: 11,
          color: level != null && level < h10BatteryLow
              ? Colors.redAccent
              : muted,
        ),
      ),
      trailing: _checking
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              tooltip: l10n.h10BatteryCheck,
              icon: const Icon(Icons.refresh),
              onPressed: () => unawaited(_check()),
            ),
    );
  }
}
