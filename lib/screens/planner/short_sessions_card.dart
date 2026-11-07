import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/planner_providers.dart';
import '../../services/control/execution.dart' show shortReasons;
import '../../widgets/app_widgets.dart';

/// Asks why a recent session was clearly shorter than planned. The answer
/// tells fatigue from a lack of time or bad weather, so a short session is
/// not taken for low fitness.
class ShortSessionsCard extends ConsumerWidget {
  const ShortSessionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(shortSessionsProvider).valueOrNull ?? const [];
    if (rows.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.amber.withValues(alpha: .6)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timelapse_outlined,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.shortSessionTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              for (final r in rows) ...[
                const SizedBox(height: 10),
                Text(
                  l.shortSessionLine(
                    r.session.title,
                    r.session.actualDurationMin ??
                        ((r.actual.durationRatio ?? 0) *
                                r.session.plannedDurationMin)
                            .round(),
                    r.session.plannedDurationMin,
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final reason in shortReasons)
                      ActionChip(
                        label: Text(shortReasonLabel(l, reason)),
                        onPressed: () => ref.read(setShortReasonProvider)(
                          r.session.id,
                          reason,
                        ),
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

String shortReasonLabel(AppLocalizations l, String reason) => switch (reason) {
  'time' => l.shortReasonTime,
  'weather' => l.shortReasonWeather,
  'fatigue' => l.shortReasonFatigue,
  'pain' => l.shortReasonPain,
  _ => l.shortReasonOther,
};
