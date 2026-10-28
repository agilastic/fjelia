import '../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';

import '../screens/onboarding/connect_health_screen.dart';

/// Tells the user that Apple Health stopped answering and was disconnected.
class HealthAccessLostDialog {
  const HealthAccessLostDialog._();

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(context.l10n.appleHealthIsNoLonger),
      content: Text(context.l10n.appleHealthStoppedAnsweringSo),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: Text(context.l10n.later),
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
          child: Text(context.l10n.reconnect),
        ),
      ],
    ),
  );
}
