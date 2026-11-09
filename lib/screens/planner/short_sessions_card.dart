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
    return SectionCard(
      title: l.shortSessionTitle,
      accent: const [Color(0xFFFFB13D), Color(0xFFFFE066)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    onPressed: () =>
                        ref.read(setShortReasonProvider)(r.session.id, reason),
                  ),
              ],
            ),
          ],
        ],
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
