import '../../providers/device_actions_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/hilo_sync_provider.dart';
import '../../widgets/hilo_device_picker.dart';
import 'onboarding_widgets.dart';

const _accent = Color(0xFFFF8C00);

/// Pair the Hilo/Aktiia wristband over Bluetooth.
class ConnectHiloBleScreen extends ConsumerStatefulWidget {
  const ConnectHiloBleScreen({super.key, this.fromOnboarding = false});

  final bool fromOnboarding;

  @override
  ConsumerState<ConnectHiloBleScreen> createState() =>
      _ConnectHiloBleScreenState();
}

class _ConnectHiloBleScreenState extends ConsumerState<ConnectHiloBleScreen> {
  String? _pairedMac;
  String? _pairedName;
  bool _scanning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPaired();
  }

  Future<void> _loadPaired() async {
    final actions = ref.read(deviceActionsProvider);
    final mac = await actions.pairedId(DeviceRole.bracelet);
    final name = await actions.pairedName(DeviceRole.bracelet);
    if (!mounted) return;
    setState(() {
      _pairedMac = mac;
      _pairedName = name;
    });
    ref.invalidate(hiloBleConnectedProvider);
  }

  void _next() => Navigator.of(context).pop();

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final found = await ref
          .read(deviceActionsProvider)
          .scan(DeviceRole.bracelet);
      if (!mounted) return;
      setState(() => _scanning = false);
      if (found.isEmpty) {
        setState(
          () =>
              _error = 'No Hilo pod found. Make sure it is charged and nearby.',
        );
        return;
      }
      await HiloDevicePicker.show(context, devices: found);
      await _loadPaired();
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _error = 'Scan failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paired = _pairedMac != null;
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(leading: const BackButton(color: Color(0xFFCCCCCC))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const OnboardingDeviceHeader(
                icon: Icons.monitor_heart_outlined,
                color: _accent,
                title: 'Pair Hilo Pod',
                subtitle:
                    'Connect your Hilo / Aktiia wristband via Bluetooth '
                    'to sync raw blood pressure data directly from the pod.',
              ),
              const SizedBox(height: 36),
              if (paired) ...[
                _PairedBanner(
                  name: _pairedName ?? 'Hilo Pod',
                  mac: _pairedMac!,
                ),
                const SizedBox(height: 24),
              ],
              if (_error != null) ...[
                OnboardingErrorBanner(_error!),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFF2A2A2A),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _scanning ? null : _scan,
                  icon: _scanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.bluetooth_searching_rounded, size: 20),
                  label: Text(
                    _scanning
                        ? 'Scanning…'
                        : paired
                        ? 'Scan again'
                        : 'Scan for pod',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const OnboardingInfoBox(
                'Wear the Hilo band during sleep for continuous blood pressure '
                'recording. Data syncs automatically each morning when the app '
                'opens.',
              ),
              if (paired) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4A0),
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _next,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continue'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PairedBanner extends StatelessWidget {
  const _PairedBanner({required this.name, required this.mac});

  final String name;
  final String mac;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accent.withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withAlpha(90)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: _accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  mac,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 11,
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
