import '../../providers/activity_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/day_data_provider.dart';
import '../../db/database.dart';
import '../../widgets/app_widgets.dart';
import '../ai_coach/ai_coach_screen.dart';
import 'activities_screen.dart';
import 'load_visuals.dart';
import '../../models/week_progress.dart';
import '../../utils/week.dart';
import '../../providers/week_start_provider.dart';

class WeeklyLoadCard extends ConsumerStatefulWidget {
  const WeeklyLoadCard({super.key});
  @override
  ConsumerState<WeeklyLoadCard> createState() => _WeeklyLoadState();
}

class _WeeklyLoadState extends ConsumerState<WeeklyLoadCard> {
  String metric = 'Load';
  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(loadActivitiesProvider).valueOrNull ?? [];
    final date = ref.watch(selectedDateProvider);
    final mondayFirst = ref.watch(weekStartsOnMondayProvider);
    final monday = weekStartOf(date, mondayFirst: mondayFirst);
    final priorMonday = DateTime(monday.year, monday.month, monday.day - 7);
    final weeks = {
      for (var i = 11; i >= 0; i--)
        DateTime(monday.year, monday.month, monday.day - i * 7): 0.0,
    };
    final sports = <String, List<double>>{};
    final progress = WeekProgress(weekStart: monday, now: DateTime.now());
    double current = 0, previous = 0, previousComparable = 0;
    double value(ActivityRecord a) => switch (metric) {
      'Time' => a.durationSeconds / 3600,
      'Distance' => (a.distanceMeters ?? 0) / 1000,
      _ => activityLoad(a),
    };
    for (final a in rows) {
      final week = weekStartOf(a.startDate, mondayFirst: mondayFirst);
      if (weeks.containsKey(week)) weeks[week] = weeks[week]! + value(a);
      if (week != monday && week != priorMonday) continue;
      final load = activityLoad(a), index = week == monday ? 0 : 1;
      (sports[a.type] ??= [0, 0])[index] += load;
      if (index == 0) {
        current += load;
      } else {
        previous += load;
        // A running week is compared with the same span of the week before.
        if (a.startDate.isBefore(progress.previousCutoff)) {
          previousComparable += load;
        }
      }
    }
    final change = previousComparable > 0
        ? (current - previousComparable) / previousComparable * 100
        : null;
    final limit = previous * 1.1;
    return LoadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: loadOrange.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.bolt, color: loadOrange, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'WEEKLY TRAINING LOAD',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    letterSpacing: .5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (change != null) LoadBadge('${change.round()}%'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            weeklyLoadHeadline(
              weekNumber: loadWeekNumber(monday, mondayFirst: mondayFirst),
              current: current,
              previousComparable: previousComparable,
              progress: progress,
            ),
            style: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.inProgress ? 'THIS WEEK · SO FAR' : 'WEEK',
                      style: loadCaption,
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: valueText(current),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(
                            text: '     pts',
                            style: TextStyle(fontSize: 14, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('PREV WEEK', style: loadCaption),
                  const SizedBox(height: 4),
                  Text(
                    valueText(previous),
                    style: const TextStyle(
                      fontSize: 23,
                      color: Color(0xFFBBBBBB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: limit > 0 ? (current / limit).clamp(0, 1) : 0,
            color: current > limit ? loadOrange : mint,
            backgroundColor: Colors.white.withValues(alpha: .045),
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 8),
          if (previous > 0)
            Row(
              children: [
                Icon(
                  current <= limit
                      ? Icons.check_circle_outline
                      : Icons.warning_amber,
                  size: 12,
                  color: current <= limit ? mint : loadOrange,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    current <= limit
                        ? '${valueText(limit - current)} pts remaining until recommended max'
                        : '${valueText(current - limit)} pts above recommended max',
                    style: TextStyle(
                      fontSize: 10,
                      color: current <= limit ? mint : loadOrange,
                    ),
                  ),
                ),
              ],
            ),
          const Divider(height: 30, color: Colors.white10),
          const Text('BY SPORT', style: loadLabel),
          const SizedBox(height: 5),
          for (final e in sports.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(
                    sportIcon(e.key),
                    size: 16,
                    color: const Color(0xFFBBBBBB),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      sportName(e.key),
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                  Text(
                    valueText(e.value[0]),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  if (e.value[1] > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: LoadBadge(
                        '${((e.value[0] - e.value[1]) / e.value[1] * 100).round()}%',
                        color: loadBlue,
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
            ),
          if (sports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No activities this week', style: loadCaption),
            ),
          const Divider(height: 28, color: Colors.white10),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('12-WEEK HISTORY', style: loadLabel),
                LoadRange(
                  labels: const ['Load', 'Time', 'Distance'],
                  selected: metric,
                  segmented: true,
                  onChanged: (m) => setState(() => metric = m),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            children: [
              const LoadLegend('10% limit', Colors.amber, line: true),
              LoadLegend(
                progress.inProgress ? 'this week (so far)' : 'selected week',
                mint,
              ),
            ],
          ),
          const SizedBox(height: 10),
          LoadWeekBars(
            dates: weeks.keys.toList(),
            values: weeks.values.toList(),
            weekNumbers: true,
            limit: true,
            mondayFirst: mondayFirst,
            inProgressLast: progress.inProgress,
          ),
          if (current > 0 || previous > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: mint,
                  padding: const EdgeInsets.only(top: 8),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: Text(
                  change != null && change < 0
                      ? 'What explains this drop?'
                      : 'What explains this rise?',
                ),
                onPressed: () => openCoachTab(
                  context,
                  prompt:
                      'My training load this week is ${valueText(current)} points'
                      '${progress.inProgress ? ' so far' : ''}, last week it was '
                      '${valueText(previous)}'
                      '${change == null ? '' : ' (${change.round()}% against the same point of last week)'}. '
                      '${change != null && change < 0 ? 'What explains this drop' : 'What explains this rise'}, '
                      'and which sessions drove it?',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

IconData sportIcon(String type) {
  final t = type.toLowerCase();
  return t.contains('run')
      ? Icons.directions_run
      : t.contains('swim')
      ? Icons.pool
      : t.contains('cycl') || t.contains('bik')
      ? Icons.directions_bike
      : t.contains('walk') || t.contains('hik')
      ? Icons.hiking
      : Icons.fitness_center;
}

String sportName(String type) => type
    .split('_')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');
