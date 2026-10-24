import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/device_actions_provider.dart';
import 'app_widgets.dart';

class ScalePairingTile extends ConsumerStatefulWidget {
  const ScalePairingTile({super.key});
  @override
  ConsumerState<ScalePairingTile> createState() => _ScalePairingState();
}

class _ScalePairingState extends ConsumerState<ScalePairingTile> {
  DeviceActions get actions => ref.read(deviceActionsProvider);
  late Future<String?> name;
  bool scanning = false;
  String? justPaired;
  @override
  void initState() {
    super.initState();
    name = _pairedName();
  }

  Future<String?> _pairedName() async =>
      actions.pairedName(await actions.scaleRole());

  Future<void> pair() async {
    setState(() => scanning = true);
    await runUiAction(context, () async {
      final role = await actions.scaleRole();
      final found = await actions.scan(role);
      if (!mounted) return;
      final selected = await showDialog<NearbyDevice>(
        context: context,
        builder: (c) => SimpleDialog(
          title: const Text('Choose scale'),
          children: [
            if (found.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No scales found. Step on the scale and try again.',
                ),
              ),
            for (final s in found)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(c, s),
                child: Text('${s.name} · ${s.rssi} dBm'),
              ),
          ],
        ),
      );
      if (selected != null) {
        await actions.pair(role, selected);
        ref.invalidate(renphoBleConnectedProvider);
        if (mounted) {
          setState(() {
            name = _pairedName();
            justPaired = selected.name;
          });
          await showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
              icon: const Icon(Icons.check_circle, color: mint, size: 40),
              title: const Text('Scale paired'),
              content: Text(
                '${selected.name} is paired.\n\nTo measure, tap + → RENPHO '
                'Scale, step on the scale barefoot and stay on until the '
                'result appears.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    });
    if (mounted) setState(() => scanning = false);
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'RENPHO Scale (BLE)',
    child: FutureBuilder<String?>(
      future: name,
      builder: (c, s) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.monitor_weight, color: mint),
        title: Text(s.data ?? 'No scale paired'),
        subtitle: justPaired != null
            ? const Text(
                '✓ Paired — ready to measure',
                style: TextStyle(fontSize: 11, color: mint),
              )
            : Text(
                s.data == null
                    ? 'Step on your scale before scanning'
                    : 'Paired',
                style: const TextStyle(fontSize: 10, color: muted),
              ),
        trailing: TextButton(
          onPressed: scanning ? null : pair,
          child: Text(
            scanning
                ? 'Scanning…'
                : s.data == null
                ? 'Pair'
                : 'Change',
          ),
        ),
      ),
    ),
  );
}
