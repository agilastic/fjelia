import 'package:flutter/material.dart';

import '../screens/onboarding/connect_health_screen.dart';

/// Tells the user that Apple Health stopped answering and was disconnected.
class HealthAccessLostDialog {
  const HealthAccessLostDialog._();

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('Apple Health is no longer available'),
      content: const Text(
        'Apple Health stopped answering, so Fjelia disconnected it and no '
        'longer reads or writes Health data.\n\n'
        'Allow Fjelia again under Settings → Health → Data Access & Devices '
        '→ Fjelia, then reconnect Apple Health.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialog);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ConnectHealthScreen(fromOnboarding: true),
              ),
            );
          },
          child: const Text('Reconnect'),
        ),
      ],
    ),
  );
}
