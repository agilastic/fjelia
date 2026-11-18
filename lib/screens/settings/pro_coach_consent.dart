import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/plan_proposal_provider.dart';
import '../../services/plan_proposal_store.dart';

bool _asking = false;

/// FjeliaPro: asks once, after a subscription first becomes active, whether
/// the coach may write the morning push. That sends the day's plan and the
/// health summary to Fjelia AI Pro without asking each time, so it stays off
/// until allowed. The answer is the switch in Settings → Training.
Future<void> askProCoachOnce(BuildContext context, WidgetRef ref) async {
  if (_asking || await PlanProposalStore.proCoachAsked()) return;
  if (!context.mounted) return;
  _asking = true;
  try {
    final l10n = context.l10n;
    final allowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text(l10n.proCoachAskTitle),
        content: SingleChildScrollView(child: Text(l10n.proCoachAskBody)),
        actions: [
          TextButton(
            key: const ValueKey('pro-coach-deny'),
            onPressed: () => Navigator.pop(c, false),
            child: Text(l10n.proCoachAskDeny),
          ),
          TextButton(
            key: const ValueKey('pro-coach-allow'),
            onPressed: () => Navigator.pop(c, true),
            child: Text(l10n.proCoachAskAllow),
          ),
        ],
      ),
    );
    // Only a tap on a button counts; the dialog cannot be dismissed otherwise.
    if (allowed != null) {
      await ref.read(proposalProCoachProvider.notifier).set(allowed);
    }
  } finally {
    _asking = false;
  }
}
