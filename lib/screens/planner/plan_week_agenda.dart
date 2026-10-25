import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/day_data_provider.dart';
import '../../providers/plan_week_provider.dart';
import '../../theme/activity_colors.dart';
import '../../widgets/app_widgets.dart';
import '../strain/activity_detail_sheet.dart';
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
                        'of ${_duration(planned)} planned',
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
    VoidCallback? onTap;
    if (item.session != null) {
      onTap = () =>
          showAppSheet(context, PlanSessionSheet(session: item.session!));
    } else if (item.activity != null) {
      onTap = () =>
          showAppSheet(context, ActivityDetailSheet(activity: item.activity!));
    }
    final phase = item.session?.phase;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: _Line(
        icon: activitySportIcon(item.sport),
        color: skipped || missed
            ? Colors.white38
            : completedActivityColor(item.sport),
        label: sportLabel(item.sport),
        badge: done
            ? (item.session == null ? 'EXTRA' : null)
            : skipped
            ? 'SKIPPED'
            : phase?.toUpperCase(),
        badgeColor: skipped
            ? Colors.orangeAccent
            : done
            ? muted
            : plannedActivityColor(phase),
        detail: skipped
            ? (item.skipReason ?? 'Skipped')
            : missed
            ? 'Not recorded'
            : item.title,
        trailing: item.minutes == null ? '—' : '${item.minutes} min',
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
    this.badgeColor = muted,
    this.dim = false,
    this.struck = false,
    this.done = false,
  });
  final IconData icon;
  final Color color;
  final String label, trailing;
  final String? detail, badge;
  final Color badgeColor;
  final bool dim, struck, done;

  @override
  Widget build(BuildContext context) {
    final text = dim ? Colors.white38 : Colors.white;
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          color: text,
                          fontWeight: FontWeight.w600,
                          decoration: struck
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: Colors.white38,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            fontSize: 8,
                            color: badgeColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .4,
                          ),
                        ),
                      ),
                    ],
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
          if (done) ...[
            const Icon(Icons.check_circle_rounded, size: 16, color: mint),
            const SizedBox(width: 4),
          ],
          Text(
            trailing,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: done ? mint : (dim ? Colors.white38 : Colors.white70),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
