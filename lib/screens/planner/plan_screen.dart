import '../../providers/upcoming_plan_provider.dart';
import '../../models/calendar_activity.dart';
import '../../providers/activity_calendar_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/planner_providers.dart';
import '../../providers/plan_view_provider.dart';
import '../../providers/day_data_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/app_widgets.dart';
import 'plan_overview_cards.dart';
import 'plan_calendar_markers.dart';
import 'plan_week_agenda.dart';
import '../activities/activities_screen.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});
  @override
  ConsumerState<PlanScreen> createState() => _PlanState();
}

class _PlanState extends ConsumerState<PlanScreen> {
  late DateTime month;
  @override
  void initState() {
    super.initState();
    final selected = ref.read(selectedDateProvider);
    month = DateTime(selected.year, selected.month);
  }

  @override
  Widget build(BuildContext context) {
    final defaultView = ref.watch(planViewProvider).valueOrNull ?? 'list';
    final view = defaultView[0].toUpperCase() + defaultView.substring(1);
    final upcoming = ref.watch(upcomingPlanProvider);
    final selected = ref.watch(selectedDateProvider);
    final calendar = view == 'Month'
        ? ref.watch(planCalendarActivitiesProvider(month)).valueOrNull ??
              <CalendarActivity>[]
        : <CalendarActivity>[];
    final mondayFirst =
        ref.watch(userProfileProvider).valueOrNull?.weekStartsOnMonday ?? true;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
      children: [
        const PlanWeatherStrip(),
        const RaceCountdownCard(),
        const Center(
          child: Text(
            'ACTIVITY LOG',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        if (view == 'Month') ...[
          Row(
            children: [
              IconButton(
                onPressed: () => setState(
                  () => month = DateTime(month.year, month.month - 1),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${month.year} / ${month.month}',
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () => setState(
                  () => month = DateTime(month.year, month.month + 1),
                ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          GridView.count(
            padding: EdgeInsets.zero,
            childAspectRatio: 1.35,
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final d
                  in (mondayFirst
                      ? ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      : ['S', 'M', 'T', 'W', 'T', 'F', 'S']))
                Center(
                  child: Text(
                    d,
                    style: const TextStyle(fontSize: 10, color: muted),
                  ),
                ),
              for (
                var i = 0;
                i < (mondayFirst ? month.weekday - 1 : month.weekday % 7);
                i++
              )
                const SizedBox(),
              for (
                var day = 1;
                day <= DateTime(month.year, month.month + 1, 0).day;
                day++
              )
                Builder(
                  builder: (c) {
                    final d = DateTime(month.year, month.month, day);
                    final activities = calendar
                        .where((a) => DateUtils.isSameDay(a.date, d))
                        .toList();
                    return Tooltip(
                      message: activities.isEmpty
                          ? dayText(d)
                          : '${dayText(d)}\n${activities.map((a) => '${a.title} · ${a.statusLabel}').join('\n')}',
                      child: InkWell(
                        onTap: () =>
                            ref.read(selectedDateProvider.notifier).state = d,
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: DateUtils.isSameDay(d, selected)
                                ? mint.withValues(alpha: .25)
                                : DateUtils.isSameDay(d, DateTime.now())
                                ? Colors.amber.withValues(alpha: .12)
                                : null,
                            border: DateUtils.isSameDay(d, DateTime.now())
                                ? Border.all(color: Colors.amber, width: 1.5)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  color: DateUtils.isSameDay(d, DateTime.now())
                                      ? Colors.amber
                                      : null,
                                  fontWeight:
                                      DateUtils.isSameDay(d, DateTime.now())
                                      ? FontWeight.bold
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 3),
                              SizedBox(
                                height: 6,
                                child: CalendarActivityBubbles(
                                  activities: activities,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
        if (view == 'Month')
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final entry in {
                  for (final a in calendar)
                    '${a.sport}:${a.completed}:${a.phase}:${a.skipped}': a,
                }.values)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: calendarActivityColor(entry),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.sport.replaceAll('_', ' ')}${entry.completed
                            ? ''
                            : entry.skipped
                            ? ' · skipped'
                            : ' · ${entry.phase ?? 'planned'}'}',
                        style: const TextStyle(fontSize: 9, color: muted),
                      ),
                    ],
                  ),
                const Text(
                  '○ Planned   ● Completed   ✕ Skipped',
                  style: TextStyle(fontSize: 9, color: muted),
                ),
              ],
            ),
          ),
        if (view == 'Week')
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: PlanWeekAgenda(mondayFirst: mondayFirst),
          ),
        // The week table already lists every planned day.
        if (view != 'Week')
          upcoming.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => DataError(
              e,
              retry: () {
                ref.invalidate(upcomingSessionsProvider);
                ref.invalidate(scheduledWorkoutsProvider);
              },
            ),
            data: (rows) => UpcomingWorkoutList(
              entries: rows,
              selectedDay: view == 'List' ? null : selected,
            ),
          ),
        ActivityHistory(
          showHeader: false,
          monthMode: view != 'Week',
          selectedDayOnly: view == 'Month',
        ),
      ],
    );
  }
}
