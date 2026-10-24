import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/polar_h10_provider.dart';
import 'onboarding_widgets.dart';

const _accent = Color(0xFFFF5A5F);

/// Pair a Polar H10 chest strap over Bluetooth for spot HRV measurements.
class ConnectPolarH10Screen extends ConsumerStatefulWidget {
  const ConnectPolarH10Screen({super.key, this.fromOnboarding = false});

  final bool fromOnboarding;

  @override
  ConsumerState<ConnectPolarH10Screen> createState() => _State();
}

class _State extends ConsumerState<ConnectPolarH10Screen> {
  bool _scanning = false;
  String? _error;

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final actions = ref.read(polarH10ActionsProvider);
      final found = await actions.scan();
      if (!mounted) return;
      setState(() => _scanning = false);
      if (found.isEmpty) {
        setState(
          () => _error =
              'No Polar H10 found. Wear the strap with moist electrodes and '
              'make sure no other app (or watch) is connected to it, then '
              'scan again.',
        );
        return;
      }
      final chosen = found.length == 1
          ? found.first
          : await showDialog<H10Device>(
              context: context,
              builder: (c) => SimpleDialog(
                title: const Text('Choose strap'),
                children: [
                  for (final d in found)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(c, d),
                      child: Text('${d.name} · ${d.rssi} dBm'),
                    ),
                ],
              ),
            );
      if (chosen == null) return;
      await actions.pair(chosen);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${chosen.name} paired.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _error = 'Scan failed: $e';
        });
      }
    }
  }

  Future<void> _forget() async {
    await ref.read(polarH10ActionsProvider).unpair();
  }

  @override
  Widget build(BuildContext context) {
    final paired = ref.watch(polarH10PairedProvider).valueOrNull;
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
                title: 'Pair Polar H10',
                subtitle:
                    'Use your Polar H10 chest strap for spot HRV readings '
                    'before and after training, next to your overnight HRV.',
              ),
              const SizedBox(height: 36),
              if (paired != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accent.withAlpha(90)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: _accent,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          paired.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _forget,
                        child: const Text(
                          'Forget',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
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
                    foregroundColor: Colors.white,
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
                        : paired != null
                        ? 'Scan again'
                        : 'Scan for Polar H10',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const OnboardingInfoBox(
                'Wear the strap with moist electrodes before scanning. '
                'Measure later with + → Polar H10 HRV measurement; results '
                'appear next to your overnight HRV.',
              ),
              if (paired != null) ...[
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
                    onPressed: () => Navigator.of(context).pop(),
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
