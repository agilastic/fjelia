import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/load_week_history.dart';
import '../../providers/activity_history_provider.dart';
import '../../providers/day_data_provider.dart';
import '../../providers/week_start_provider.dart';
import '../../providers/hr_zones_provider.dart';
import '../../widgets/app_widgets.dart';
import 'load_visuals.dart';

class LoadHistoryCards extends ConsumerWidget {
  const LoadHistoryCards({super.key, required this.polarization});
  final bool polarization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider);
    final mondayFirst = ref.watch(weekStartsOnMondayProvider);
    return ref
        .watch(loadActivitiesProvider)
        .when(
          loading: () => LoadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  polarization ? 'ZONE POLARIZATION' : 'ELEVATION',
                  style: loadLabel,
                ),
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ),
          ),
          error: (error, _) => LoadCard(
            child: DataError(
              error,
              retry: () => ref.invalidate(loadActivitiesProvider),
            ),
          ),
          data: (activities) {
            final zones =
                polarization && activities.any((a) => a.metricsJson != null)
                ? ref.watch(hrZonesProvider)
                : null;
            final weeks = buildLoadWeekHistory(
              through: selected,
              activities: activities,
              mondayFirst: mondayFirst,
              runningZones: zones?.running.bounds,
              cyclingZones: zones?.cycling.bounds,
            );
            if (!polarization) {
              final elevation = weeks.last.elevation;
              return LoadCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: mint.withValues(alpha: .13),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.landscape,
                            color: mint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('ELEVATION', style: loadLabel),
                        ),
                        const Text('12-WEEK HISTORY', style: loadCaption),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LoadWeekBars(
                      dates: [for (final week in weeks) week.start],
                      values: [for (final week in weeks) week.elevation],
                      mondayFirst: mondayFirst,
                    ),
                    const Divider(height: 30, color: Colors.white10),
                    Text(
                      elevation == 0
                          ? 'No elevation this week'
                          : '${valueText(elevation)} m this week',
                      style: const TextStyle(fontSize: 13, color: muted),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            }
            final zoneWeeks = weeks.reversed.take(5).toList();
            final recorded = zoneWeeks.fold<int>(
              0,
              (sum, week) => sum + week.activities,
            );
            final withZones = zoneWeeks.fold<int>(
              0,
              (sum, week) => sum + week.activitiesWithZones,
            );
            final fromSamples = zoneWeeks.fold<int>(
              0,
              (sum, week) => sum + week.activitiesFromSamples,
            );
            return LoadCard(
              color: loadInset,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ZONE POLARIZATION', style: loadLabel),
                  const SizedBox(height: 10),
                  const Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      LoadLegend('EASY', loadBlue),
                      LoadLegend('MOD', Color(0xFFFFCC00)),
                      LoadLegend('HARD', loadRed),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Expanded(
                        child: Text('5-WEEK HISTORY', style: loadCaption),
                      ),
                      Text('EASY %', style: loadCaption),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final week in zoneWeeks)
                    _ZoneWeekRow(
                      week: week,
                      selected: week == weeks.last,
                      mondayFirst: mondayFirst,
                    ),
                  const SizedBox(height: 12),
                  Text(
                    '$withZones of $recorded activities with HR-zone data',
                    style: loadCaption,
                  ),
                  if (fromSamples > 0) ...[
                    const SizedBox(height: 5),
                    Text(
                      '$fromSamples reconstructed from recorded HR samples',
                      style: loadCaption,
                    ),
                  ],
                  const SizedBox(height: 5),
                  const Text(
                    'Easy: Z1–2 · Moderate: Z3 · Hard: Z4–5',
                    style: loadCaption,
                  ),
                  if (withZones < recorded) ...[
                    const SizedBox(height: 5),
                    const Text(
                      'Activities without HR-zone data are excluded from percentages.',
                      style: loadCaption,
                    ),
                  ],
                ],
              ),
            );
          },
        );
  }
}

class _ZoneWeekRow extends StatelessWidget {
  const _ZoneWeekRow({
    required this.week,
    required this.selected,
    required this.mondayFirst,
  });
  final LoadWeekHistory week;
  final bool selected, mondayFirst;

  @override
  Widget build(BuildContext context) {
    final easy = week.easyPercent;
    final end = DateTime(week.start.year, week.start.month, week.start.day + 6);
    final label = 'W${loadWeekNumber(week.start, mondayFirst: mondayFirst)}';
    final coverage =
        '${week.activitiesWithZones} of ${week.activities} activities with HR-zone data';
    final status = week.activities == 0
        ? 'No activities synced'
        : 'No HR-zone data';
    final recordedTime = week.classifiedMinutes < 1
        ? '${(week.classifiedMinutes * 60).round()} sec'
        : '${week.classifiedMinutes.round()} min';
    final description =
        '${loadDate(week.start)} – ${loadDate(end)} · $coverage${easy == null ? '' : ' · ${easy.round()}% easy · $recordedTime recorded zone time'}';
    const colors = [loadBlue, Color(0xFFFFCC00), loadRed];
    return Tooltip(
      message: description,
      child: Semantics(
        label: '$label, $description${easy == null ? ', $status' : ''}',
        excludeSemantics: true,
        child: Container(
          key: ValueKey('polarization-week-${week.start.toIso8601String()}'),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withValues(alpha: .04) : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : const Color(0xFFBBBBBB),
                      ),
                    ),
                    Text(
                      DateFormat('d MMM').format(week.start),
                      style: const TextStyle(fontSize: 8, color: muted),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: easy == null
                    ? Container(
                        height: 20,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: muted),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            for (var i = 0; i < 3; i++)
                              if (week.zoneMinutes[i] > 0)
                                Expanded(
                                  flex: (week.zoneMinutes[i] * 100)
                                      .round()
                                      .clamp(1, 100000000),
                                  child: Container(
                                    height: 14,
                                    color: colors[i],
                                  ),
                                ),
                          ],
                        ),
                      ),
              ),
              SizedBox(
                width: 42,
                child: Text(
                  easy == null ? '—' : '${easy.round()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    color: easy == null ? muted : loadBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
