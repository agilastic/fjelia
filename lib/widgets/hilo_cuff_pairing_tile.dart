import '../l10n/l10n_ext.dart';

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
          title: Text(context.l10n.chooseHiloCuff),
          children: [
            if (candidates.isEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(context.l10n.noCuffFoundWakeYour),
              ),
            for (final d in candidates)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(c, d),
                child: Text(context.l10n.nameRssiDbm(d.name, d.rssi)),
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
    title: context.l10n.hiloCuffAktiiaC,
    child: FutureBuilder<String?>(
      future: name,
      builder: (c, s) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(s.data ?? context.l10n.noCuffPaired),
        subtitle: Text(
          context.l10n.onDemandBloodPressureVia,
          style: TextStyle(fontSize: 10, color: muted),
        ),
        leading: const Icon(Icons.bluetooth, color: Colors.lightBlue),
        trailing: TextButton(
          onPressed: scanning ? null : pair,
          child: Text(
            scanning
                ? context.l10n.scanning
                : s.data == null
                ? context.l10n.pair
                : context.l10n.change,
          ),
        ),
      ),
    ),
  );
}
