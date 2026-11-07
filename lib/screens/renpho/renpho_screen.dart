import '../../theme/fjelia_style.dart';
import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/waist_ratios.dart';
import '../../providers/body_measurements_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/waist_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/metric_detail_sheet.dart';
import '../../widgets/waist_sheet.dart';

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
          data: (r) {
            // The waist history first; the profile only when nothing is
            // measured yet.
            final profile = ref.watch(userProfileProvider).valueOrNull;
            final waist =
                ref
                    .watch(waistMeasurementsProvider)
                    .valueOrNull
                    ?.lastOrNull
                    ?.waistCm ??
                profile?.waistCm;
            final whtr = waistToHeight(waist, profile?.heightCm);
            return ListView(
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
                              style: TextStyle(fontSize: 36, color: fjInk),
                            ),
                            TextSpan(
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
                        style: TextStyle(color: muted, fontSize: 11),
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
                        (HealthMetric.waist, waist),
                      ])
                        MetricCard(
                          label: pair.$1.label,
                          value: valueText(pair.$2, 1),
                          unit: pair.$1.unit,
                          color: fjInk,
                          onTap: pair.$1 == HealthMetric.waist
                              ? () => showAppSheet(context, const WaistSheet())
                              : () => MetricDetailSheet.show(context, pair.$1),
                        ),
                      MetricCard(
                        label: 'WHtR',
                        value: valueText(whtr, 2),
                        color: whtr == null
                            ? fjInk
                            : waistRiskColor(whtrRisk(whtr)),
                        onTap: () => showAppSheet(context, const WaistSheet()),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
  );
}
