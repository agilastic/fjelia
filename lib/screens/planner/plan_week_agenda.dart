import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/day_data_provider.dart';
import '../../providers/plan_week_provider.dart';
import '../../providers/upcoming_plan_provider.dart' show PlanCompletionMatch;
import '../../theme/activity_colors.dart';
import '../../widgets/app_widgets.dart';
import '../strain/activity_detail_sheet.dart';
import '../activities/workout_detail_sheet.dart';
import 'plan_session_sheet.dart';

const _divider = Color(0x14FFFFFF);

/// The week at a glance: one row per day with what is planned, what was done
/// and what was dropped, and the planned total at the bottom.
class PlanWeekAgenda extends ConsumerWidget {
  const PlanWeekAgenda({super.key, required this.mondayFirst});
  final bool mondayFirst;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider);
    final start = weekStartFor(selected, mondayFirst: mondayFirst);
    final week = ref.watch(planWeekProvider(start));
    void shift(int days) => ref.read(selectedDateProvider.notifier).state =
        DateTime(selected.year, selected.month, selected.day + days);
    final end = DateTime(start.year, start.month, start.day + 6);
    final now = DateTime.now();
    final thisWeek = weekStartFor(now, mondayFirst: mondayFirst) == start;
    final range = start.month == end.month
        ? '${start.day}–${DateFormat('d MMM').format(end)}'
        : '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM').format(end)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous week',
              onPressed: () => shift(-7),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    range,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!thisWeek)
                    GestureDetector(
                      onTap: () =>
                          ref.read(selectedDateProvider.notifier).state =
                              DateTime(now.year, now.month, now.day),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          'Back to this week',
                          style: TextStyle(fontSize: 11, color: mint),
                        ),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'This week',
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Next week',
              onPressed: () => shift(7),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        week.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => DataError(
            e,
            retry: () => ref.invalidate(planWeekProvider(start)),
          ),
          data: (w) => _WeekTable(week: w),
        ),
      ],
    );
  }
}

class _WeekTable extends StatelessWidget {
  const _WeekTable({required this.week});
  final PlanWeek week;

  @override
  Widget build(BuildContext context) {
    final planned = week.plannedMinutes, done = week.doneMinutes;
    final progress = planned == 0 ? 0.0 : (done / planned).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // How far the week is: done against planned, at a glance.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 6,
                  children: [
                    Text(
                      _duration(done),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        planned > 0
                            ? 'of ${_duration(planned)} planned'
                            : 'completed · no workouts planned',
                        style: const TextStyle(fontSize: 13, color: muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(height: 6, color: Colors.white10),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 6,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [mint, Color(0xFF4FC3F7)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _divider),
          for (var i = 0; i < week.days.length; i++) ...[
            _DayRow(day: week.days[i]),
            if (i < week.days.length - 1)
              const Divider(height: 1, thickness: 1, color: _divider),
          ],
        ],
      ),
    );
  }
}

String _duration(int minutes) => minutes < 120
    ? '$minutes min'
    : '${minutes ~/ 60} h${minutes % 60 == 0 ? '' : ' ${minutes % 60} min'}';

String sportLabel(String sport) => switch (activityKind(sport)) {
  ActivityKind.running => 'Running',
  ActivityKind.cycling => 'Cycling',
  ActivityKind.swimming => 'Swimming',
  ActivityKind.strength => 'Strength',
  ActivityKind.rowing => 'Rowing',
  ActivityKind.hiking => 'Hiking',
  ActivityKind.walking => 'Walking',
  ActivityKind.yoga => 'Yoga',
  ActivityKind.other =>
    sport.isEmpty
        ? 'Workout'
        : '${sport[0].toUpperCase()}${sport.substring(1).replaceAll('_', ' ')}',
};

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});
  final PlanWeekDay day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today =
        day.date.year == now.year &&
        day.date.month == now.month &&
        day.date.day == now.day;
    final first = day.rest ? null : day.items.first;
    final stripe = first == null
        ? Colors.transparent
        : first.state == PlanWeekState.skipped ||
              first.state == PlanWeekState.missed
        ? Colors.white24
        : completedActivityColor(first.sport);
    return Container(
      decoration: BoxDecoration(
        color: today ? mint.withValues(alpha: .06) : null,
        border: Border(left: BorderSide(color: stripe, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(13, 6, 16, 6),
      constraints: const BoxConstraints(minHeight: 60),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE').format(day.date),
                  style: TextStyle(
                    fontSize: 13,
                    color: today ? mint : muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                if (today)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: mint.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 8,
                        color: mint,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  )
                else
                  Text(
                    '${day.date.day}',
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
              ],
            ),
          ),
          Expanded(
            child: day.rest
                ? const _Line(
                    icon: Icons.bedtime_outlined,
                    color: Colors.white38,
                    label: 'Rest',
                    trailing: '—',
                    dim: true,
                  )
                : Column(
                    children: [
                      for (final item in day.items) _ItemLine(item: item),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItemLine extends StatelessWidget {
  const _ItemLine({required this.item});
  final PlanWeekItem item;

  @override
  Widget build(BuildContext context) {
    final state = item.state;
    final skipped = state == PlanWeekState.skipped;
    final missed = state == PlanWeekState.missed;
    final done = state == PlanWeekState.done;
    VoidCallback? viewPlan;
    if (item.session != null) {
      viewPlan = () =>
          showAppSheet(context, PlanSessionSheet(session: item.session!));
    } else if (item.workout != null) {
      viewPlan = () =>
          showAppSheet(context, WorkoutDetailSheet(workout: item.workout!));
    }
    final phase = item.session?.phase;
    return InkWell(
      onTap: item.activity != null
          ? () => showAppSheet(
              context,
              ActivityDetailSheet(activity: item.activity!),
            )
          : viewPlan,
      borderRadius: BorderRadius.circular(10),
      child: _Line(
        icon: activitySportIcon(item.sport),
        color: skipped || missed
            ? Colors.white38
            : completedActivityColor(item.sport),
        label: sportLabel(item.sport),
        badge: done
            ? 'DONE'
            : skipped
            ? 'SKIPPED'
            : missed
            ? 'NOT RECORDED'
            : 'PLANNED',
        secondaryBadge: done && !item.hasPlan ? 'EXTRA' : null,
        badgeTooltip: switch (item.completionMatch) {
          PlanCompletionMatch.activityLink =>
            'Recorded activity linked to this workout',
          PlanCompletionMatch.recordedStart =>
            'Matched to the recorded workout start',
          PlanCompletionMatch.workoutName || PlanCompletionMatch.activityName =>
            'Matched by workout name, sport and date',
          PlanCompletionMatch.duration => 'Matched by sport, date and duration',
          null => null,
        },
        badgeColor: skipped
            ? Colors.orangeAccent
            : done
            ? mint
            : plannedActivityColor(phase),
        detail: skipped
            ? (item.skipReason ?? 'Skipped')
            : missed
            ? 'Not recorded'
            : item.title,
        trailing: item.minutes == null ? '—' : '${item.minutes} min',
        target:
            done &&
                item.plannedMinutes != null &&
                item.plannedMinutes != item.minutes
            ? 'Plan ${item.plannedMinutes} min'
            : null,
        onPlanTap: done ? viewPlan : null,
        dim: skipped || missed,
        struck: skipped,
        done: done,
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.color,
    required this.label,
    required this.trailing,
    this.detail,
    this.badge,
    this.secondaryBadge,
    this.badgeTooltip,
    this.target,
    this.onPlanTap,
    this.badgeColor = muted,
    this.dim = false,
    this.struck = false,
    this.done = false,
  });
  final IconData icon;
  final Color color;
  final String label, trailing;
  final String? detail, badge, secondaryBadge, badgeTooltip, target;
  final VoidCallback? onPlanTap;
  final Color badgeColor;
  final bool dim, struck, done;

  @override
  Widget build(BuildContext context) {
    final text = dim ? Colors.white38 : Colors.white;
    Widget statusBadge(String value, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: .4,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 3,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: text,
                        fontWeight: FontWeight.w600,
                        decoration: struck ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.white38,
                      ),
                    ),
                    if (badge != null)
                      Tooltip(
                        message: badgeTooltip ?? badge!,
                        child: statusBadge(badge!, badgeColor),
                      ),
                    if (secondaryBadge != null)
                      statusBadge(secondaryBadge!, muted),
                  ],
                ),
                if (detail != null && detail!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (done) ...[
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: mint,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    trailing,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: done
                          ? mint
                          : (dim ? Colors.white38 : Colors.white70),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              if (target != null)
                TextButton(
                  onPressed: onPlanTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: muted,
                  ),
                  child: Text(target!, style: const TextStyle(fontSize: 10)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
