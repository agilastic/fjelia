import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bio_age_provider.dart';
import 'app_widgets.dart';

class BioAgeCard extends ConsumerWidget {
  const BioAgeCard({super.key, this.expanded = false});
  final bool expanded;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(bioAgeProvider);
    return result.when(
      loading: () => const SectionCard(
        title: 'Biological Age',
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => DataError(e),
      data: (r) => SectionCard(
        title: 'Biological Age',
        onTap: expanded
            ? null
            : () => showAppSheet(
                context,
                SheetPage(
                  title: 'Biological Age',
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: BioAgeCard(expanded: true),
                  ),
                ),
              ),
        child: r == null
            ? const EmptyState(
                'Add your birth year in Settings → Profile to see your estimate.',
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      StatPair(
                        'Fitness Age',
                        '${valueText(r.fitnessAge)} y',
                        color: mint,
                      ),
                      StatPair(
                        'Est. Lifespan',
                        '${valueText(r.lifeExpectancy)} y',
                      ),
                      StatPair(
                        'Delta',
                        '${r.deltaYears <= 0 ? '+' : ''}${valueText(-r.deltaYears, 1)} y',
                        color: mint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'VO₂max ${valueText(r.vo2max, 1)} ml/kg/min · ${r.vo2Class}',
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                  if (expanded) ...[
                    const SectionLabel('Factor contributions'),
                    for (final e in r.contributions.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.key,
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
                              '${e.value <= 0 ? '+' : ''}${valueText(-e.value, 1)} y',
                              style: TextStyle(
                                fontSize: 10,
                                color: e.value <= 0 ? mint : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Estimated range ${math.min(r.rangeLow, r.rangeHigh).round()}–${math.max(r.rangeLow, r.rangeHigh).round()} years. A model estimate, not a medical diagnosis.',
                      style: const TextStyle(color: muted, fontSize: 10),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
