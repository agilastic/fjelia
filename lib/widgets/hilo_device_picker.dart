import '../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/device_actions_provider.dart';

/// Bottom sheet listing nearby Aktiia/Hilo wristbands to pair with.
class HiloDevicePicker extends ConsumerStatefulWidget {
  const HiloDevicePicker({super.key, this.initial = const []});

  final List<NearbyDevice> initial;

  static Future<void> show(
    BuildContext context, {
    List<NearbyDevice>? devices,
  }) {
    final container = ProviderScope.containerOf(context);
    final found =
        devices ?? container.read(deviceActionsProvider).knownBracelets();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: HiloDevicePicker(initial: found),
      ),
    );
  }

  @override
  ConsumerState<HiloDevicePicker> createState() => _HiloDevicePickerState();
}

class _HiloDevicePickerState extends ConsumerState<HiloDevicePicker> {
  List<NearbyDevice> _devices = [];
  bool _scanning = false;
  String? _pairingMac;

  @override
  void initState() {
    super.initState();
    _devices = widget.initial;
  }

  Future<void> _rescan() async {
    setState(() => _scanning = true);
    final found = await ref
        .read(deviceActionsProvider)
        .scan(DeviceRole.bracelet);
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _devices = found;
    });
  }

  Future<void> _pair(NearbyDevice device) async {
    setState(() => _pairingMac = device.mac);
    final actions = ref.read(deviceActionsProvider);
    await actions.pair(DeviceRole.bracelet, device);
    if (!mounted) return;
    Navigator.of(context).pop();
    await actions.synchronizeBracelet();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF888888),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.selectHiloPodWristband,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_scanning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF00D4A0),
                      strokeWidth: 2,
                    ),
                  )
                else
                  IconButton(
                    tooltip: context.l10n.rescan,
                    icon: const Icon(Icons.refresh, color: Color(0xFFCCCCCC)),
                    onPressed: _rescan,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.selectYourAktiiaPWristband,
              style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (_devices.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    context.l10n.noDevicesFoundTapTo,
                    style: TextStyle(color: Color(0xFF888888), fontSize: 14),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _devices.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: Color(0xFF888888), height: 1),
                itemBuilder: (context, i) {
                  final d = _devices[i];
                  final pairing = _pairingMac == d.mac;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.bluetooth,
                      size: 22,
                      color: Color(0xFF00D4A0),
                    ),
                    title: Text(
                      d.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${d.mac}  •  ${d.rssi} dBm'
                      '${d.isBonded ? '  •  Bonded' : ''}',
                      style: const TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontSize: 12,
                      ),
                    ),
                    trailing: pairing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFF00D4A0),
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF888888),
                          ),
                    onTap: _pairingMac == null ? () => _pair(d) : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
