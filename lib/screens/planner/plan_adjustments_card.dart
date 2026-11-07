import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../db/database.dart' show PlanAdjustment;
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/planner_providers.dart';
import '../../widgets/app_widgets.dart';

/// What the app changed in the plan by itself in the last two days, each
/// decision with its reason and a way back.
class PlanAdjustmentsCard extends ConsumerWidget {
  const PlanAdjustmentsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups =
        ref.watch(recentPlanAdjustmentsProvider).valueOrNull ?? const [];
    if (groups.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.lightBlueAccent.withValues(alpha: .6)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_fix_high_outlined,
                    color: Colors.lightBlueAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.planAdjustedTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              for (final g in groups) ...[
                const SizedBox(height: 8),
                for (final x in g.items)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                    child: Text(
                      planAdjustmentText(l, x),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          ref.read(dismissPlanAdjustmentProvider)(g.id),
                      child: Text(l.ok),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.undo, size: 18),
                      label: Text(l.undo),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        await ref.read(undoPlanAdjustmentProvider)(g.id);
                        messenger?.showSnackBar(
                          SnackBar(content: Text(l.planAdjUndone)),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One change in words, from the numbers the decision kept.
String planAdjustmentText(AppLocalizations l, PlanAdjustment x) {
  final p = jsonDecode(x.paramsJson) as Map<String, dynamic>;
  String day(String key) {
    final at = DateTime.tryParse(p[key] as String? ?? '');
    return at == null ? '' : DateFormat.EEEE().format(at);
  }

  final session = p['session'] as String? ?? '';
  final activity = p['activity'] as String? ?? '';
  return switch (x.reasonCode) {
    'swap' => l.planAdjSwap(session, day('to'), day('from')),
    'substitute' => l.planAdjSubstitute(activity, session, day('from')),
    'strengthCredit' => l.planAdjStrengthCredit(activity, session),
    'movedEasy' => l.planAdjMovedEasy(session, day('to'), activity),
    _ => l.planAdjMoved(session, day('to')),
  };
}
