import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/device_actions_provider.dart';
import 'app_widgets.dart';

class HiloCuffPairingTile extends ConsumerStatefulWidget {
  const HiloCuffPairingTile({super.key});
  @override
  ConsumerState<HiloCuffPairingTile> createState() => _CuffState();
}

class _CuffState extends ConsumerState<HiloCuffPairingTile> {
  late Future<String?> name;
  bool scanning = false;
  @override
  void initState() {
    super.initState();
    name = ref.read(deviceActionsProvider).pairedName(DeviceRole.cuff);
  }

  Future<void> pair() async {
    setState(() => scanning = true);
    await runUiAction(context, () async {
      final actions = ref.read(deviceActionsProvider);
      final candidates = await actions.scan(DeviceRole.cuff);
      if (!mounted) return;
      final selected = await showDialog<NearbyDevice>(
        context: context,
        builder: (c) => SimpleDialog(
          title: const Text('Choose Hilo cuff'),
          children: [
            if (candidates.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No cuff found. Wake your cuff and try scanning again.',
                ),
              ),
            for (final d in candidates)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(c, d),
                child: Text('${d.name} · ${d.rssi} dBm'),
              ),
          ],
        ),
      );
      if (selected != null) {
        await actions.pair(DeviceRole.cuff, selected);
        if (mounted) setState(() => name = actions.pairedName(DeviceRole.cuff));
      }
    });
    if (mounted) setState(() => scanning = false);
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Hilo cuff (AKTIIA C…)',
    child: FutureBuilder<String?>(
      future: name,
      builder: (c, s) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(s.data ?? 'No cuff paired'),
        subtitle: const Text(
          'On-demand blood pressure via BLE',
          style: TextStyle(fontSize: 10, color: muted),
        ),
        leading: const Icon(Icons.bluetooth, color: Colors.lightBlue),
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
