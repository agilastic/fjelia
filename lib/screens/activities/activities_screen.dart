import '../../l10n/l10n_ext.dart';
import '../../theme/activity_colors.dart'
    show completedActivityColor, activitySportIcon;
import '../../providers/activity_history_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../providers/training_load_provider.dart';
import '../../providers/day_data_provider.dart';
import '../../widgets/app_widgets.dart';
import '../strain/activity_detail_sheet.dart';
import '../../utils/week.dart';
import '../../providers/week_start_provider.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => SheetPage(
    title: context.l10n.activityLog,
    child: SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: ActivityHistory(),
    ),
  );
}

class ActivityHistory extends ConsumerStatefulWidget {
  const ActivityHistory({
    super.key,
    this.showHeader = true,
    this.monthMode,
    this.selectedDayOnly = false,
  });
  final bool showHeader;
  final bool selectedDayOnly;
  final bool? monthMode;
  @override
  ConsumerState<ActivityHistory> createState() => _HistoryState();
}

class _HistoryState extends ConsumerState<ActivityHistory> {
  bool month = true;
  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDateProvider);
    final monthFilter = widget.monthMode ?? month;
    final start = monthFilter
        ? DateTime(selected.year, selected.month)
        : weekStartOf(
            selected,
            mondayFirst: ref.watch(weekStartsOnMondayProvider),
          );
    final end = monthFilter
        ? DateTime(selected.year, selected.month + 1)
        : start.add(const Duration(days: 7));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader)
          Row(
            children: [
              Expanded(child: SectionLabel(context.l10n.activityLog2)),
              TextButton(
                onPressed: () => setState(() => month = !month),
                child: Text(month ? context.l10n.month2 : context.l10n.week2),
              ),
            ],
          ),
        ref
            .watch(loadActivitiesProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => DataError(
                e,
                retry: () => ref.invalidate(loadActivitiesProvider),
              ),
              data: (rows) {
                final filtered = rows
                    .where(
                      (a) => widget.selectedDayOnly
                          ? DateUtils.isSameDay(a.startDate, selected)
                          : !a.startDate.isBefore(start) &&
                                a.startDate.isBefore(end),
                    )
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 12, bottom: 8),
                      child: Text(
                        context.l10n.history2,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                    if (filtered.isEmpty)
                      EmptyState(context.l10n.noActivitiesInThisPeriod),
                    for (var i = 0; i < filtered.length; i++) ...[
                      if (i == 0 ||
                          !DateUtils.isSameDay(
                            filtered[i].startDate,
                            filtered[i - 1].startDate,
                          ))
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 6),
                          child: Text(
                            dayHeading(context, filtered[i].startDate),
                            style: const TextStyle(fontSize: 9, color: muted),
                          ),
                        ),
                      _ActivityHistoryTile(activity: filtered[i]),
                    ],
                  ],
                );
              },
            ),
      ],
    );
  }
}

class _ActivityHistoryTile extends StatelessWidget {
  const _ActivityHistoryTile({required this.activity});
  final ActivityRecord activity;
  @override
  Widget build(BuildContext context) {
    final a = activity;
    final color = completedActivityColor(a.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          leading: CircleAvatar(
            radius: 17,
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(activitySportIcon(a.type), size: 19, color: color),
          ),
          title: Text(
            a.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            context.l10n
                .durationsecondshDurationseconds2mDistancemetersKmAvgheartrate(
                  a.durationSeconds ~/ 3600,
                  a.durationSeconds ~/ 60 % 60,
                  valueText(
                    a.distanceMeters == null ? null : a.distanceMeters! / 1000,
                    1,
                  ),
                  valueText(a.avgHeartRate),
                  valueText(a.totalElevation),
                ),
            style: const TextStyle(fontSize: 9, color: muted),
          ),
          trailing: Icon(Icons.check_circle_outline, size: 15, color: color),
          onTap: () => showAppSheet(context, ActivityDetailSheet(activity: a)),
        ),
      ),
    );
  }
}

double activityLoad(ActivityRecord a) {
  try {
    return effectiveLoad(a);
  } on FormatException {
    return a.trainingLoad ?? 0;
  } on TypeError {
    return a.trainingLoad ?? 0;
  }
}
