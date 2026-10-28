import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/day_data_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/metric_detail_sheet.dart';
import '../../widgets/sleep_stages.dart';

class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});
  String hours(Duration d) =>
      '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDateProvider);
    final scores = ref.watch(dayScoresProvider(day));
    return SheetPage(
      title: context.l10n.sleep,
      showBack: false,
      titleSize: 13,
      backgroundColor: panel,
      headerDivider: true,
      child: ref
          .watch(sleepDataProvider(day))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => DataError(e),
            data: (sleep) {
              final score =
                  sleep?.sleepScore?.toDouble() ??
                  scores.valueOrNull?.sleep?.score;
              final need = sleep?.sleepNeedSeconds == null
                  ? scores.valueOrNull?.sleep?.need
                  : Duration(seconds: sleep!.sleepNeedSeconds!);
              final status = score == null
                  ? context.l10n.noData2
                  : score < 50
                  ? context.l10n.poorSleep
                  : score < 80
                  ? context.l10n.fairSleep
                  : context.l10n.goodSleep;
              Widget duration(String label, String value, Color color) =>
                  Expanded(
                    child: Column(
                      children: [
                        FittedBox(
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: color.withValues(alpha: .5),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
              Widget metric(
                String label,
                String value,
                IconData icon,
                Color color,
              ) => Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              String time(DateTime? t) =>
                  t == null ? '—' : DateFormat.Hm().format(t.toLocal());
              final tip = sleep == null
                  ? null
                  : sleep.deepPercent < 15
                  ? context.l10n.deepSleepIsBelowOptimal(
                      sleep.deepPercent.round(),
                    )
                  : context.l10n.keepAConsistentBedtimeAnd;
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 42, 20, 20),
                      child: Column(
                        children: [
                          Text(
                            context.l10n.sleepPerformance,
                            style: TextStyle(
                              fontSize: 11,
                              color: muted,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            score == null ? '—' : '${score.round()}%',
                            style: const TextStyle(
                              fontSize: 70,
                              fontWeight: FontWeight.w800,
                              color: Colors.lightBlue,
                            ),
                          ),
                          Text(
                            status,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.lightBlue,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              duration(
                                context.l10n.hoursOfSleep,
                                sleep == null ? '—' : hours(sleep.totalSleep),
                                Colors.white70,
                              ),
                              const SizedBox(width: 12),
                              duration(
                                context.l10n.sleepNeeded,
                                need == null ? '—' : hours(need),
                                mint,
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          if (sleep != null) ...[
                            SleepStagesSection(sleep: sleep),
                            const SizedBox(height: 32),
                          ],
                          GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 2,
                            mainAxisSpacing: 28,
                            crossAxisSpacing: 16,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            children: [
                              metric(
                                context.l10n.deepSleep,
                                sleep == null
                                    ? '—'
                                    : '${sleep.deepPercent.round()}%',
                                Icons.bedtime_outlined,
                                Colors.lightBlue,
                              ),
                              metric(
                                'REM SLEEP',
                                sleep == null
                                    ? '—'
                                    : '${sleep.remPercent.round()}%',
                                Icons.psychology_outlined,
                                mint,
                              ),
                              metric(
                                'EFFICIENCY',
                                sleep?.sleepStart == null ||
                                        sleep?.sleepEnd == null
                                    ? '—'
                                    : '${sleep!.efficiency.round()}%',
                                Icons.speed,
                                Colors.white70,
                              ),
                              metric(
                                'BEDTIME',
                                time(sleep?.sleepStart),
                                Icons.bedtime_outlined,
                                Colors.lightBlue,
                              ),
                              metric(
                                'WAKE TIME',
                                time(sleep?.sleepEnd),
                                Icons.wb_sunny_outlined,
                                Colors.amber,
                              ),
                            ],
                          ),
                          const SizedBox(height: 45),
                          if (tip != null)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  color: mint,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          TextButton(
                            onPressed: () => MetricDetailSheet.show(
                              context,
                              HealthMetric.sleep,
                            ),
                            child: Text(context.l10n.sleepHistory),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}
