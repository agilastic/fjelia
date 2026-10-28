import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/body_measurements_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/metric_detail_sheet.dart';

class RenphoScreen extends ConsumerWidget {
  const RenphoScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => SheetPage(
    title: context.l10n.bodyScale,
    showHeader: false,
    backgroundColor: panel,
    child: ref
        .watch(latestBodyMeasurementProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => DataError(e),
          data: (r) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: context.l10n.bodyScale,
                onTap: () =>
                    MetricDetailSheet.show(context, HealthMetric.weight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: valueText(r?.weight, 1),
                            style: const TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                            ),
                          ),
                          const TextSpan(
                            text: ' kg',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r == null
                          ? context.l10n.noMeasurementsYet
                          : context.l10n.latestReadingAtTimestamp(
                              DateFormat.yMd().add_Hm().format(r.timestamp),
                            ),
                      style: const TextStyle(color: muted, fontSize: 11),
                    ),
                    const Divider(),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        StatPair('BMI', valueText(r?.bmi, 1)),
                        StatPair(
                          context.l10n.bodyFat,
                          '${valueText(r?.bodyFat, 1)}%',
                        ),
                        StatPair(
                          context.l10n.date,
                          r == null
                              ? '—'
                              : DateFormat.yMd().format(r.timestamp),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: context.l10n.bodyComposition,
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    for (final pair in <(HealthMetric, double?)>[
                      (HealthMetric.bodyFat, r?.bodyFat),
                      (HealthMetric.muscle, r?.muscleMass),
                      (HealthMetric.water, r?.bodyWater),
                      (HealthMetric.protein, r?.protein),
                      (HealthMetric.visceralFat, r?.visceralFat),
                      (HealthMetric.bmr, r?.bmr),
                      (HealthMetric.bone, r?.boneMass),
                      (HealthMetric.bmi, r?.bmi),
                      (HealthMetric.waist, r?.waistCm),
                    ])
                      MetricCard(
                        label: pair.$1.label,
                        value: valueText(pair.$2, 1),
                        unit: pair.$1.unit,
                        color: Colors.white,
                        onTap: () => MetricDetailSheet.show(context, pair.$1),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
  );
}
