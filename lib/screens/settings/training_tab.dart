import 'weather_location_tab.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../models/weekly_hours.dart';
import '../../providers/activity_history_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/week_start_provider.dart';
import '../../providers/planner_providers.dart';
import '../../providers/plan_view_provider.dart';
import '../../providers/day_data_provider.dart';
import '../../providers/heat_acclimation_provider.dart';
import '../../providers/workout_generation_provider.dart';
import '../../providers/workout_push_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../utils/target_time.dart';
import 'race_goal_editor.dart';

class TrainingTab extends ConsumerWidget {
  const TrainingTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(userProfileProvider).valueOrNull;
    final heat = ref.watch(heatAcclimationSettingsProvider).valueOrNull;
    final generation = ref.watch(workoutGenerationProvider);
    return SheetPage(
      title: 'Training',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionLabel('Race Goals', color: Colors.orange),
          const RaceGoalsCard(),
          const SectionLabel('Your Activities', color: Colors.orange),
          if (p != null) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Used by AI Coach and training plan. Plan sports marked with ✦.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final e in {
                  'running': 'Running',
                  'trail_running': 'Trail',
                  'cycling_road': 'Cycling',
                  'cycling_gravel': 'Gravel',
                  'cycling_mtb': 'MTB',
                  'swimming': 'Swimming',
                  'triathlon': 'Triathlon',
                  'indoor_rowing': 'Rowing',
                  'hiking': 'Hiking',
                  'inline_skating': 'Inline Skating',
                  'nordic_skiing': 'Nordic Classic',
                  'skate_skiing': 'Skate Skiing',
                  'strength': 'Strength',
                  'walking': 'Walking',
                  'yoga': 'Yoga',
                  'skiing': 'Skiing',
                  'climbing': 'Climbing',
                  'other': 'Other',
                }.entries)
                  FilterChip(
                    label: Text(
                      '${_sportEmoji[e.key] ?? ''} ${e.value}${_planSports.contains(e.key) ? ' ✦' : ''}${p.preferredSports.contains(e.key) ? ' ✓' : ''}',
                    ),
                    selectedColor: Colors.orange.withValues(alpha: .14),
                    backgroundColor: panel,
                    side: BorderSide(
                      color: p.preferredSports.contains(e.key)
                          ? Colors.orange
                          : Colors.white12,
                    ),
                    labelStyle: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: p.preferredSports.contains(e.key)
                          ? Colors.orange
                          : Colors.white,
                    ),
                    selected: p.preferredSports.contains(e.key),
                    onSelected: (selected) => runUiAction(context, () async {
                      final current = await ref.read(
                        userProfileProvider.future,
                      );
                      final sports = current.preferredSports.toSet();
                      if (selected) {
                        sports.add(e.key);
                      } else if (sports.length > 1) {
                        sports.remove(e.key);
                      }
                      await ref
                          .read(userProfileProvider.notifier)
                          .save(
                            current.copyWith(preferredSports: sports.toList()),
                          );
                    }),
                  ),
              ],
            ),
            const SectionLabel('Calendar week start', color: Colors.orange),
            SettingsSegments(
              values: const {'monday': 'Monday', 'sunday': 'Sunday'},
              selected: p.weekStartsOnMonday ? 'monday' : 'sunday',
              onSelect: (v) => runUiAction(
                context,
                () => ref
                    .read(userProfileProvider.notifier)
                    .save(p.copyWith(weekStartsOnMonday: v == 'monday')),
              ),
            ),
            const SectionLabel('Plan Default View', color: Colors.orange),
            SettingsSegments(
              values: const {'month': 'Month', 'week': 'Week', 'list': 'List'},
              selected: ref.watch(planViewProvider).valueOrNull ?? 'list',
              onSelect: (v) => runUiAction(
                context,
                () => ref.read(planViewProvider.notifier).setView(v),
              ),
            ),
            const SectionLabel('Weekly Schedule', color: Colors.orange),
            Text(
              '${p.trainingDaysPerWeek} training days · tap to cycle Rest / Strength',
              style: const TextStyle(color: muted, fontSize: 10),
            ),
            Wrap(
              spacing: 5,
              children: [
                for (final day
                    in p.weekStartsOnMonday
                        ? const [1, 2, 3, 4, 5, 6, 7]
                        : const [7, 1, 2, 3, 4, 5, 6])
                  ActionChip(
                    backgroundColor:
                        (p.restDays.contains(day)
                                ? Colors.grey
                                : p.preferredStrengthDays.contains(day)
                                ? Colors.orange
                                : mint)
                            .withValues(alpha: .12),
                    side: BorderSide(
                      color: p.restDays.contains(day)
                          ? Colors.grey
                          : p.preferredStrengthDays.contains(day)
                          ? Colors.orange
                          : mint,
                    ),
                    label: Text(
                      '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1]} ${p.restDays.contains(day)
                          ? 'Rest'
                          : p.preferredStrengthDays.contains(day)
                          ? 'Strength'
                          : 'Train'}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    onPressed: () => runUiAction(context, () async {
                      final rest = p.restDays.toSet(),
                          strength = p.preferredStrengthDays.toSet();
                      if (rest.remove(day)) {
                        strength.add(day);
                      } else if (!strength.remove(day) && rest.length < 6) {
                        rest.add(day);
                      }
                      await ref
                          .read(userProfileProvider.notifier)
                          .save(
                            p.copyWith(
                              restDays: rest.toList()..sort(),
                              preferredStrengthDays: strength.toList()..sort(),
                              trainingDaysPerWeek: 7 - rest.length,
                            ),
                          );
                    }),
                  ),
              ],
            ),
            const SectionLabel('Sessions per day', color: Colors.orange),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Can you fit two workouts in one day?',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            SettingsSegments(
              values: const {
                '1': '1 — Single session',
                '2': '2 — Double day possible',
              },
              selected: '${p.maxSessionsPerDay}',
              color: Colors.orange,
              onSelect: (v) => runUiAction(
                context,
                () => ref
                    .read(userProfileProvider.notifier)
                    .save(p.copyWith(maxSessionsPerDay: int.parse(v))),
              ),
            ),
            const SectionLabel('Targets in workouts', color: Colors.orange),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.orange,
              title: const Text(
                'Send workouts to COROS (experimental)',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                'Uses the COROS Training Hub\'s unofficial web interface with your COROS login. It is not endorsed by COROS and can stop working. Without it the workout is shared as text.',
                style: TextStyle(fontSize: 11, color: muted),
              ),
              value: p.corosWorkoutPush,
              onChanged: (v) => ref
                  .read(userProfileProvider.notifier)
                  .save(p.copyWith(corosWorkoutPush: v)),
            ),
            const SectionLabel('Hours available / week', color: Colors.orange),
            Text(
              '${valueText(p.hoursPerWeek)} h / week',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            Slider(
              value: p.hoursPerWeek.clamp(3, 25),
              min: 3,
              max: 25,
              divisions: 22,
              activeColor: Colors.orange,
              label: '${valueText(p.hoursPerWeek)} h',
              onChanged: (v) => ref
                  .read(userProfileProvider.notifier)
                  .save(p.copyWith(hoursPerWeek: v)),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('3 h', style: TextStyle(color: muted, fontSize: 10)),
                Text('25 h', style: TextStyle(color: muted, fontSize: 10)),
              ],
            ),
            Builder(
              builder: (context) {
                final recent = WeeklyHours.of(
                  [
                    for (final a
                        in ref.watch(loadActivitiesProvider).valueOrNull ??
                            const <ActivityRecord>[])
                      (a.startDate, a.durationSeconds),
                  ],
                  now: DateTime.now(),
                  mondayFirst: ref.watch(weekStartsOnMondayProvider),
                );
                if (recent == null) return const SizedBox.shrink();
                final far = recent.isFarAbove(p.hoursPerWeek);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Your last 12 weeks: ${valueText(recent.average)} h on average, '
                    'busiest week ${valueText(recent.peak)} h.'
                    '${far ? ' ${valueText(p.hoursPerWeek)} h is far above that; the plan builds up from what you do and will stay below it.' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: far ? Colors.orangeAccent : muted,
                    ),
                  ),
                );
              },
            ),
          ],
          const SectionLabel('Heat Acclimation', color: Colors.orange),
          SectionCard(
            color: const Color(0xFF282828),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.thermostat, color: Colors.orange),
                  title: const Text(
                    'Show Heat Acclimation',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Weather evaluated against a configurable location.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  activeThumbColor: Colors.orange,
                  activeTrackColor: Colors.orangeAccent.withValues(alpha: .4),
                  value: heat?.enabled ?? false,
                  onChanged: (v) => runUiAction(
                    context,
                    () => ref
                        .read(heatAcclimationSettingsProvider.notifier)
                        .setEnabled(v),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Weather & Location'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      showAppSheet(context, const WeatherLocationTab()),
                ),
              ],
            ),
          ),
          const SectionLabel('Training Plan', color: Colors.orange),
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text(
              'Regenerate replaces future sessions and rebuilds from today using current settings.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Colors.white70,
              ),
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              minimumSize: const Size(double.infinity, 46),
            ),
            onPressed: generation.isLoading
                ? null
                : () => runUiAction(
                    context,
                    () => generateTrainingPlan(context, ref),
                  ),
            icon: generation.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 20),
            label: Text(
              generation.isLoading
                  ? 'Generating workouts…'
                  : 'Regenerate Workouts',
            ),
          ),
          if (generation.valueOrNull != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${generation.value} upcoming workouts generated',
                style: const TextStyle(color: mint, fontSize: 12),
              ),
            ),
          if (generation.hasError)
            const Text(
              'Generation failed. Check your race goal and try again.',
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              minimumSize: const Size(double.infinity, 46),
            ),
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: generation.isLoading
                ? null
                : () async {
                    if (await confirmAction(
                      context,
                      'Delete all workouts?',
                      'This deletes planned workouts on this phone and on your connected watch platform. Completed activities are kept.',
                    )) {
                      if (context.mounted) await _deleteAll(context, ref);
                    }
                  },
            label: const Text(
              'Delete All Workouts',
              style: TextStyle(color: Colors.red),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text(
              '✓ Changes are saved automatically',
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> generateTrainingPlan(BuildContext context, WidgetRef ref) async {
  final goal = await ref.read(primaryRaceGoalProvider.future);
  if (goal == null) {
    throw StateError('Add a future race goal with priority A first.');
  }
  if (!context.mounted ||
      !await confirmAction(
        context,
        'Regenerate workouts?',
        'Replace future workouts and rebuild toward ${goal.name} using your current schedule?',
      )) {
    return;
  }
  final count = await ref.read(workoutGenerationProvider.notifier).generate();
  if (context.mounted && count != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count upcoming workouts generated')),
    );
  }
}

class RaceGoalsCard extends ConsumerWidget {
  const RaceGoalsCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => SectionCard(
    color: const Color(0xFF282828),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.flag_outlined, color: Colors.orange, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Race Goals',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: 'Import race goals from Garmin',
              icon: const Icon(Icons.sync, size: 18, color: Colors.lightBlue),
              onPressed: () => runUiAction(context, () async {
                await ref.read(raceGoalImportProvider)();
              }),
            ),
            IconButton(
              tooltip: 'Add race goal',
              icon: const Icon(Icons.add, size: 18, color: mint),
              onPressed: () => showRaceGoalEditor(context),
            ),
          ],
        ),
        const Divider(height: 20, color: Colors.white12),
        ref
            .watch(upcomingRaceGoalsProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => DataError(e),
              data: (goals) => goals.isEmpty
                  ? const EmptyState(
                      'No race goals yet. Add one or sync from Garmin.',
                    )
                  : Column(
                      children: [
                        for (final g in goals)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(g.name),
                            onTap: () => showRaceGoalEditor(context, goal: g),
                            subtitle: Text(
                              '${dayText(g.raceDate)} · ${(g.distanceM / 1000).toStringAsFixed(1)} km'
                              '${g.elevationM == null ? '' : ' · ↑${g.elevationM!.round()} m'}'
                              '${g.targetFinishSeconds == null ? '' : ' · goal ${formatTargetTime(g.targetFinishSeconds!)}'}',
                            ),
                            leading: PopupMenuButton<String>(
                              initialValue: g.priority,
                              onSelected: (v) => runUiAction(context, () async {
                                await ref
                                    .read(raceGoalServiceProvider)
                                    .updatePriority(g.id, v);
                                ref.invalidate(upcomingRaceGoalsProvider);
                                ref.invalidate(primaryRaceGoalProvider);
                              }),
                              itemBuilder: (_) => [
                                for (final s in ['a', 'b', 'c'])
                                  PopupMenuItem(
                                    value: s,
                                    child: Text('Priority ${s.toUpperCase()}'),
                                  ),
                              ],
                              child: Text(
                                g.priority.toUpperCase(),
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () async {
                                if (await confirmAction(
                                  context,
                                  'Delete race goal?',
                                  g.name,
                                )) {
                                  if (context.mounted) {
                                    await runUiAction(context, () async {
                                      await ref
                                          .read(raceGoalServiceProvider)
                                          .delete(g.id);
                                      ref.invalidate(upcomingRaceGoalsProvider);
                                      ref.invalidate(primaryRaceGoalProvider);
                                    });
                                  }
                                }
                              },
                            ),
                          ),
                      ],
                    ),
            ),
        const Padding(
          padding: EdgeInsets.only(top: 14),
          child: Text(
            'Goals are shared with AI Coach. A-priority drives your training plan.',
            style: TextStyle(fontSize: 11, color: muted, height: 1.5),
          ),
        ),
      ],
    ),
  );
}

const _planSports = {
  'running',
  'trail_running',
  'cycling_road',
  'cycling_gravel',
  'cycling_mtb',
  'swimming',
  'triathlon',
  'indoor_rowing',
};
const _sportEmoji = {
  'running': '🏃',
  'trail_running': '⛰️',
  'cycling_road': '🚴',
  'cycling_gravel': '🪨',
  'cycling_mtb': '🚵',
  'swimming': '🏊',
  'triathlon': '🏅',
  'indoor_rowing': '🚣',
  'hiking': '🥾',
  'inline_skating': '🛼',
  'nordic_skiing': '⛷️',
  'skate_skiing': '⛷️',
  'strength': '🏋️',
  'walking': '🚶',
  'yoga': '🧘',
  'skiing': '⛷️',
  'climbing': '🧗',
  'other': '🏅',
};

class SettingsSegments extends StatelessWidget {
  const SettingsSegments({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelect,
    this.color = Colors.lightBlue,
  });
  final Map<String, String> values;
  final String selected;
  final ValueChanged<String> onSelect;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final e in values.entries)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key == values.keys.last ? 0 : 6),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 38),
                foregroundColor: selected == e.key ? color : Colors.white70,
                backgroundColor: selected == e.key
                    ? color.withValues(alpha: .12)
                    : const Color(0xFF282828),
                side: BorderSide(
                  color: selected == e.key ? color : Colors.white12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => onSelect(e.key),
              child: Text(e.value, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ),
    ],
  );
}

/// Deletes every planned workout behind a progress dialog.
Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
  final progress = ValueNotifier<(int, int, String)>((0, 0, 'Starting'));
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Deleting workouts'),
        content: ValueListenableBuilder<(int, int, String)>(
          valueListenable: progress,
          builder: (_, p, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: p.$2 == 0 ? null : p.$1 / p.$2,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                p.$2 == 0 ? p.$3 : '${p.$3} · ${p.$1} of ${p.$2}',
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  DeleteAllResult? result;
  Object? failure;
  try {
    result = await ref.read(deleteAllWorkoutsProvider)(
      (done, total, label) => progress.value = (done, total, label),
    );
    ref.invalidate(upcomingSessionsProvider);
    ref.invalidate(scheduledWorkoutsProvider);
  } catch (e) {
    failure = e;
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  progress.dispose();
  final removed = result?.corosRemoved ?? 0;
  final message = failure != null
      ? 'Deleting failed: $failure'
      : removed > 0
      ? 'All planned workouts deleted, $removed removed from COROS.'
      : 'All planned workouts deleted.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
