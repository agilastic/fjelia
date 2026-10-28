import '../../l10n/l10n_ext.dart';
import '../../providers/connection_actions_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connect_renpho_screen.dart';
import 'onboarding_widgets.dart';

const _accent = Color(0xFFFF3B30);

class ConnectHealthScreen extends ConsumerStatefulWidget {
  const ConnectHealthScreen({super.key, this.fromOnboarding = false});

  final bool fromOnboarding;

  @override
  ConsumerState<ConnectHealthScreen> createState() =>
      _ConnectHealthScreenState();
}

class _ConnectHealthScreenState extends ConsumerState<ConnectHealthScreen> {
  bool _loading = false;
  String? _error;

  void _next() {
    if (widget.fromOnboarding) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ConnectRenphoScreen()),
      );
    }
  }

  Future<void> _connect() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(connectionActionsProvider).requestHealthAccess();
      if (!mounted) return;
      _next();
    } catch (e) {
      setState(() => _error = context.l10n.errorE(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        leading: const BackButton(color: Color(0xFFCCCCCC)),
        title: const Text(''),
        actions: [
          TextButton(
            onPressed: _next,
            child: Text(
              context.l10n.skip,
              style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingDeviceHeader(
                icon: Icons.favorite_rounded,
                color: _accent,
                title: context.l10n.appleHealth,
                subtitle:
                    'Connect Apple Health to automatically sync sleep, '
                    'heart rate, HRV, steps, and SpO2.',
              ),
              const SizedBox(height: 28),
              const _DataPointsBox(),
              const SizedBox(height: 20),
              OnboardingInfoBox(context.l10n.appleHealthDataAccess),
              if (_error != null) ...[
                const SizedBox(height: 16),
                OnboardingErrorBanner(_error!),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _loading ? null : _connect,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          context.l10n.connectAppleHealth,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataPointsBox extends StatelessWidget {
  const _DataPointsBox();

  static const _items = [
    (Icons.bedtime_outlined, 'Sleep stages', 'Deep, REM, light, awake'),
    (Icons.favorite_border, 'Heart rate & HRV', 'Resting HR + SDNN'),
    (Icons.directions_walk_outlined, 'Steps', 'Daily step count'),
    (Icons.air_outlined, 'SpO2 & respiration', 'Blood oxygen & breathing rate'),
    (
      Icons.thermostat_outlined,
      'Body temperature',
      'Overnight skin temp delta',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.dataSynced,
            style: TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          for (final (icon, title, sub) in _items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF888888)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        sub,
                        style: const TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
