import '../../theme/fjelia_style.dart';
import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/load_week_history.dart';
import '../../providers/activity_history_provider.dart';
import '../../providers/day_data_provider.dart';
import '../../providers/week_start_provider.dart';
import '../../providers/hr_zone_trends_provider.dart';
import '../../widgets/app_widgets.dart';
import 'hr_zone_trends_sheet.dart';
import 'load_visuals.dart';

class LoadHistoryCards extends ConsumerWidget {
  const LoadHistoryCards({super.key, required this.polarization});
  final bool polarization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (polarization) return const _PolarizationCard();
    final selected = ref.watch(selectedDateProvider);
    final mondayFirst = ref.watch(weekStartsOnMondayProvider);
    return ref
        .watch(loadActivitiesProvider)
        .when(
          loading: () => LoadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.elevation, style: loadLabel),
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
            final weeks = buildLoadWeekHistory(
              through: selected,
              activities: activities,
              mondayFirst: mondayFirst,
            );
            final elevation = weeks.last.elevation;
            return LoadCard(
              accent: const [Color(0xFFC6FF4D), Color(0xFF00D4A0)],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GradientTitle(
                          context.l10n.elevation,
                          colors: const [Color(0xFFC6FF4D), Color(0xFF00D4A0)],
                        ),
                      ),
                      Text(context.l10n.t12WeekHistory, style: loadCaption),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LoadWeekBars(
                    dates: [for (final week in weeks) week.start],
                    values: [for (final week in weeks) week.elevation],
                    mondayFirst: mondayFirst,
                  ),
                  Divider(height: 30, color: fjInk10),
                  Text(
                    elevation == 0
                        ? context.l10n.noElevationThisWeek
                        : context.l10n.elevationThisWeek(valueText(elevation)),
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
  }
}

/// Easy, moderate and hard time of the last five weeks, from the kept zone
/// summaries: each workout with the zones in force when it was done, the
/// same numbers the FjeliaPro zone trends show.
class _PolarizationCard extends ConsumerWidget {
  const _PolarizationCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider);
    final mondayFirst = ref.watch(weekStartsOnMondayProvider);
    return ref
        .watch(hrZoneWorkoutsProvider)
        .when(
          loading: () => LoadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.zonePolarization2, style: loadLabel),
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ),
          ),
          error: (error, _) => LoadCard(
            child: DataError(
              error,
              retry: () => ref.invalidate(hrZoneWorkoutsProvider),
            ),
          ),
          data: (workouts) {
            final weeks = buildZoneWeekHistory(
              through: selected,
              workouts: workouts,
              mondayFirst: mondayFirst,
            );
            final zoneWeeks = weeks.reversed.toList();
            final recorded = zoneWeeks.fold<int>(
              0,
              (sum, week) => sum + week.activities,
            );
            final withZones = zoneWeeks.fold<int>(
              0,
              (sum, week) => sum + week.activitiesWithZones,
            );
            return LoadCard(
              accent: const [Color(0xFF3EE0FF), Color(0xFF00D4A0)],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientTitle(
                    context.l10n.zonePolarization2,
                    colors: const [Color(0xFF3EE0FF), Color(0xFF00D4A0)],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      LoadLegend(context.l10n.easy3, loadBlue),
                      LoadLegend(context.l10n.mod, Color(0xFFFFCC00)),
                      LoadLegend(context.l10n.hard, loadRed),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.t5WeekHistory,
                          style: loadCaption,
                        ),
                      ),
                      Text(context.l10n.easy, style: loadCaption),
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
                    context.l10n.withzonesOfRecordedActivitiesWith(
                      withZones,
                      recorded,
                    ),
                    style: loadCaption,
                  ),
                  const SizedBox(height: 5),
                  Text(context.l10n.easyZ12ModerateZ3, style: loadCaption),
                  if (withZones < recorded) ...[
                    const SizedBox(height: 5),
                    Text(
                      context.l10n.activitiesWithoutHrZoneData,
                      style: loadCaption,
                    ),
                  ],
                  // FjeliaPro: the same zone time over months, by zone and
                  // sport, against the plan.
                  const SizedBox(height: 12),
                  const HrZoneTrendsTile(),
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
    final l = context.l10n;
    final coverage = l.withzonesOfRecordedActivitiesWith(
      week.activitiesWithZones,
      week.activities,
    );
    final status = week.activities == 0
        ? context.l10n.noActivitiesSynced
        : context.l10n.noHrZoneData;
    final description = [
      '${loadDate(week.start)} – ${loadDate(end)}',
      coverage,
      if (easy != null) ...[
        l.polarizationEasyShare(easy.round()),
        l.polarizationZoneTime(hrZoneDuration(week.classifiedMinutes * 60)),
      ],
    ].join(' · ');
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
            color: selected ? fjInk.withValues(alpha: .04) : null,
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
                        color: selected ? fjInk : duo(0xFFBBBBBB, 0xFF4B5563),
                      ),
                    ),
                    Text(
                      DateFormat.MMMd().format(week.start),
                      style: TextStyle(fontSize: 8, color: muted),
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
                          style: TextStyle(fontSize: 10, color: muted),
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
