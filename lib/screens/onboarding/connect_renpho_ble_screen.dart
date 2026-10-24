import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/device_actions_provider.dart';
import 'onboarding_widgets.dart';

const _accent = Color(0xFF9C27B0);

/// Pair a RENPHO smart scale over Bluetooth.
class ConnectRenphoBleScreen extends ConsumerStatefulWidget {
  const ConnectRenphoBleScreen({super.key, this.fromOnboarding = false});

  final bool fromOnboarding;

  @override
  ConsumerState<ConnectRenphoBleScreen> createState() =>
      _ConnectRenphoBleScreenState();
}

class _ConnectRenphoBleScreenState
    extends ConsumerState<ConnectRenphoBleScreen> {
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
    final name = await actions.pairedName(await actions.scaleRole());
    if (!mounted) return;
    setState(() => _pairedName = name);
    ref.invalidate(renphoBleConnectedProvider);
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final actions = ref.read(deviceActionsProvider);
      final role = await actions.scaleRole();
      final found = await actions.scan(role);
      if (!mounted) return;
      setState(() => _scanning = false);
      if (found.isEmpty) {
        setState(
          () => _error =
              'No scale found. Step on the scale so it wakes up, then scan '
              'again.',
        );
        return;
      }
      final chosen = found.length == 1
          ? found.first
          : await showDialog<NearbyDevice>(
              context: context,
              builder: (c) => SimpleDialog(
                title: const Text('Choose scale'),
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
      await actions.pair(role, chosen);
      await _loadPaired();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${chosen.name} paired.')),
        );
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

  @override
  Widget build(BuildContext context) {
    final paired = _pairedName != null;
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
                icon: Icons.monitor_weight_rounded,
                color: _accent,
                title: 'Pair RENPHO Scale',
                subtitle:
                    'Connect your RENPHO smart scale over Bluetooth to '
                    'measure weight and body composition straight from the '
                    'scale.',
              ),
              const SizedBox(height: 36),
              if (paired) ...[
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
                          _pairedName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
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
                        : paired
                        ? 'Scan again'
                        : 'Scan for scale',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const OnboardingInfoBox(
                'Step on the scale before scanning so it wakes up. Later, use '
                '+ → RENPHO Scale to take a measurement.',
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
