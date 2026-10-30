import '../l10n/l10n_ext.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bio_age_provider.dart';
import '../services/bio_age_activity.dart';
import 'app_widgets.dart';

class BioAgeCard extends ConsumerWidget {
  const BioAgeCard({super.key, this.expanded = false});
  final bool expanded;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(bioAgeProvider);
    return result.when(
      loading: () => SectionCard(
        title: context.l10n.biologicalAge,
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => DataError(e),
      data: (r) => SectionCard(
        title: context.l10n.biologicalAge,
        onTap: expanded
            ? null
            : () => showAppSheet(
                context,
                SheetPage(
                  title: context.l10n.biologicalAge,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: BioAgeCard(expanded: true),
                  ),
                ),
              ),
        child: r == null
            ? EmptyState(context.l10n.addYourBirthYearIn)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      StatPair(
                        context.l10n.fitnessAge,
                        '${valueText(r.fitnessAge)} y',
                        color: mint,
                      ),
                      StatPair(
                        context.l10n.estLifespan,
                        '${valueText(r.lifeExpectancy)} y',
                      ),
                      StatPair(
                        context.l10n.delta,
                        '${r.deltaYears <= 0 ? '+' : ''}${valueText(-r.deltaYears, 1)} y',
                        color: mint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.voMaxVo2maxMlKg(
                      valueText(r.vo2max, 1),
                      r.vo2Class,
                    ),
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                  if (!r.activity.isComplete || r.activity.usesStepEstimate)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: muted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              r.activity.isComplete
                                  ? context.l10n.bioAgeActivityEstimatedLabel
                                  : context.l10n.bioAgeActivityUnknownLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                color: muted,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (expanded) ...[
                    SectionLabel(context.l10n.factorContributions),
                    for (final e in r.contributions.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.key == 'activity'
                                    ? context.l10n.bioAgeActivity
                                    : e.key,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: muted,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: LinearProgressIndicator(
                                value: (e.value.abs() / 10).clamp(0, 1),
                                color: e.value <= 0 ? mint : Colors.red,
                                backgroundColor: Colors.white10,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${e.key == 'activity' && r.activity.usesStepEstimate ? '≈ ' : ''}'
                              '${e.value < 0 ? '+' : ''}'
                              '${valueText(e.value == 0 ? 0 : -e.value, 1)} y',
                              style: TextStyle(
                                fontSize: 10,
                                color: e.value <= 0 ? mint : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    _ActivityDetails(activity: r.activity),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.estimatedRangeRoundRound2Years(
                        math.min(r.rangeLow, r.rangeHigh).round(),
                        math.max(r.rangeLow, r.rangeHigh).round(),
                      ),
                      style: const TextStyle(color: muted, fontSize: 10),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ActivityDetails extends StatelessWidget {
  const _ActivityDetails({required this.activity});

  final BioAgeActivity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 11, color: muted, height: 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bioAgeActivityBasis,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            if (activity.reportedDays > 0)
              Text(
                l10n.bioAgeActivityReported(
                  valueText(activity.reportedMinutes),
                ),
              ),
            if (activity.usesStepEstimate)
              Text(
                l10n.bioAgeActivitySteps(
                  valueText(activity.estimatedWalkingMinutes),
                ),
              ),
            Text(l10n.bioAgeActivityCoverage(activity.coveredDays)),
            if (activity.usesStepEstimate) ...[
              const SizedBox(height: 8),
              Text(l10n.bioAgeActivityEstimateNotice),
            ],
            if (!activity.isComplete) ...[
              const SizedBox(height: 8),
              Text(l10n.bioAgeActivityIncomplete),
            ],
          ],
        ),
      ),
    );
  }
}
