import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/strength_workout.dart';
import '../../providers/strength_provider.dart';
import '../../services/strength/strength_estimates.dart';
import '../../widgets/app_widgets.dart';

/// Series colours, validated for the dark panel (lightness band, chroma,
/// colour-vision separation and contrast all pass).
const _topLoadColor = Color(0xFF9A66E8);
const _oneRmColor = Color(0xFFC87000);

/// One exercise's history in one context: top working load and estimated
/// 1RM per session on one kg/lb axis, with the same numbers as a table.
class StrengthTrendSheet extends ConsumerWidget {
  const StrengthTrendSheet({
    super.key,
    required this.name,
    required this.contextKey,
    required this.convention,
    required this.equipment,
  });
  final String name, contextKey, equipment;
  final StrengthConvention convention;

  Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(massUnitProvider);
    final async = ref.watch(strengthTrendSessionsProvider(contextKey));
    return SheetPage(
      title: name,
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DataError(
          e,
          retry: () =>
              ref.invalidate(strengthTrendSessionsProvider(contextKey)),
        ),
        data: (sessions) {
          final points = strengthTrend(sessions, convention);
          final load = [
            for (final p in points)
              if (p.topLoadKg != null)
                ChartPoint(p.date, unit.fromKg(p.topLoadKg!)),
          ];
          final oneRm = [
            for (final p in points)
              if (p.oneRm != null)
                ChartPoint(
                  p.date,
                  unit.fromKg((p.oneRm!.lowKg + p.oneRm!.highKg) / 2),
                ),
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Text(
                [
                  if (equipment.isNotEmpty) equipment,
                  convention.text,
                ].join(' · '),
                style: const TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 16),
              if (load.length < 2)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'A trend appears after two logged sessions with this '
                    'exercise, equipment and load setup.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                )
              else ...[
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _legend(
                      _topLoadColor,
                      context.l10n.topWorkingLoadName(unit.name),
                    ),
                    if (oneRm.isNotEmpty)
                      _legend(
                        _oneRmColor,
                        context.l10n.estimated1rmMiddleOfRange,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ExcludeSemantics(
                  child: HistoryChart(
                    points: load,
                    secondary: oneRm,
                    color: _topLoadColor,
                    secondaryColor: _oneRmColor,
                    height: 220,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                context.l10n.estimated1rmUsesEpleyAnd,
                style: TextStyle(fontSize: 11, color: muted),
              ),
              const SizedBox(height: 16),
              SectionLabel(context.l10n.sessions),
              if (points.isEmpty) EmptyState(context.l10n.noLoggedSessionsYet),
              for (final p in points.reversed)
                Semantics(
                  container: true,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(DateFormat.yMMMEd().format(p.date)),
                    subtitle: Text(
                      [
                        '${p.completedSets} completed ${p.completedSets == 1 ? 'set' : 'sets'}',
                        if (p.topLoadKg != null)
                          'top ${formatStrengthLoad(p.topLoadKg!, unit)}',
                        if (p.oneRm != null) '1RM ${oneRmText(p.oneRm!, unit)}',
                      ].join(' · '),
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
