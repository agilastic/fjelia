import '../../l10n/formats.dart';
import '../../l10n/l10n_ext.dart';
import 'weather_location_tab.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/plan_schedule_provider.dart';

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
import '../../providers/plan_goal_sync_provider.dart';
import '../../providers/workout_push_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/nutrition_widgets.dart';
import '../../utils/target_time.dart';
import 'race_goal_editor.dart';
import '../strength/strength_sections.dart';

class TrainingTab extends ConsumerWidget {
  const TrainingTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(userProfileProvider).valueOrNull;
    final heat = ref.watch(heatAcclimationSettingsProvider).valueOrNull;
    final generation = ref.watch(workoutGenerationProvider);
    return SheetPage(
      title: context.l10n.training,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionLabel(context.l10n.raceGoals, color: Colors.orange),
          const RaceGoalsCard(),
          SectionLabel(context.l10n.yourActivities, color: Colors.orange),
          if (p != null) ...[
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                context.l10n.usedByAiCoachAnd,
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final e in {
                  'running': context.l10n.running,
                  'trail_running': context.l10n.trail,
                  'cycling_road': context.l10n.cycling,
                  'cycling_gravel': context.l10n.gravel,
                  'cycling_mtb': context.l10n.mtb,
                  'swimming': context.l10n.swimming,
                  'triathlon': context.l10n.triathlon,
                  'indoor_rowing': context.l10n.rowing,
                  'hiking': context.l10n.hiking,
                  'inline_skating': context.l10n.inlineSkating,
                  'nordic_skiing': context.l10n.nordicClassic,
                  'skate_skiing': context.l10n.skateSkiing,
                  'strength': context.l10n.strength,
                  'walking': context.l10n.walking,
                  'yoga': context.l10n.yoga,
                  'skiing': context.l10n.skiing,
                  'climbing': context.l10n.climbing,
                  'other': context.l10n.other,
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
            SectionLabel(context.l10n.calendarWeekStart, color: Colors.orange),
            SettingsSegments(
              values: {
                'monday': context.l10n.monday,
                'sunday': context.l10n.sunday,
              },
              selected: p.weekStartsOnMonday ? 'monday' : 'sunday',
              onSelect: (v) => runUiAction(
                context,
                () => ref
                    .read(userProfileProvider.notifier)
                    .save(p.copyWith(weekStartsOnMonday: v == 'monday')),
              ),
            ),
            SectionLabel(context.l10n.planDefaultView, color: Colors.orange),
            SettingsSegments(
              values: {
                'month': context.l10n.month,
                'week': context.l10n.week,
                'list': context.l10n.list,
              },
              selected: ref.watch(planViewProvider).valueOrNull ?? 'list',
              onSelect: (v) => runUiAction(
                context,
                () => ref.read(planViewProvider.notifier).setView(v),
              ),
            ),
            SectionLabel(context.l10n.weeklySchedule, color: Colors.orange),
            Text(
              context.l10n.trainingdaysperweekTrainingDaysTapTo(
                p.trainingDaysPerWeek,
              ),
              style: TextStyle(color: muted, fontSize: 10),
            ),
            Wrap(
              spacing: 5,
              children: [
                for (final day
                    in p.weekStartsOnMonday
                        ? [1, 2, 3, 4, 5, 6, 7]
                        : [7, 1, 2, 3, 4, 5, 6])
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
                      '${[context.l10n.mon, context.l10n.tue, context.l10n.wed, context.l10n.thu, context.l10n.fri, context.l10n.sat, context.l10n.sun][day - 1]} ${p.restDays.contains(day)
                          ? context.l10n.restDay
                          : p.preferredStrengthDays.contains(day)
                          ? context.l10n.strength
                          : context.l10n.train}',
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
            if (ref.watch(planScheduleOutdatedProvider).valueOrNull ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.tonalIcon(
                  onPressed: () => runUiAction(
                    context,
                    () => ref.read(applyScheduleProvider)(),
                  ),
                  icon: const Icon(Icons.event_repeat_rounded, size: 18),
                  label: Text(context.l10n.updatePlanToThisSchedule),
                ),
              ),
            if (ref.watch(strengthProgrammeOutdatedProvider).valueOrNull ??
                false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.tonalIcon(
                  onPressed: () => confirmStrengthUpdate(context, ref),
                  icon: const Icon(Icons.fitness_center, size: 18),
                  label: Text(context.l10n.updateStrengthSessions),
                ),
              ),
            SectionLabel(context.l10n.sessionsPerDay, color: Colors.orange),
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                context.l10n.canYouFitTwoWorkouts,
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
            NutritionPreferencesTile(),
            SectionLabel(context.l10n.strengthLoadUnit, color: Colors.orange),
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                context.l10n.weightsThemselvesAreSetIn,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            SettingsSegments(
              values: {
                'kg': context.l10n.kilogramsKg,
                'lb': context.l10n.poundsLb,
              },
              selected: p.massUnit,
              color: Colors.orange,
              onSelect: (v) => runUiAction(
                context,
                () => ref
                    .read(userProfileProvider.notifier)
                    .save(p.copyWith(massUnit: v)),
              ),
            ),
            SectionLabel(context.l10n.hoursAvailableWeek, color: Colors.orange),
            Text(
              context.l10n.hoursperweekHWeek(valueText(p.hoursPerWeek)),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            Slider(
              value: p.hoursPerWeek.clamp(3, 25),
              min: 3,
              max: 25,
              divisions: 22,
              activeColor: Colors.orange,
              label: context.l10n.hoursperweekH(valueText(p.hoursPerWeek)),
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
          SectionLabel(context.l10n.heatAcclimation, color: Colors.orange),
          SectionCard(
            color: const Color(0xFF282828),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.thermostat, color: Colors.orange),
                  title: Text(
                    context.l10n.showHeatAcclimation,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    context.l10n.weatherEvaluatedAgainstAConfigurable,
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
                  title: Text(context.l10n.weatherLocation),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      showAppSheet(context, const WeatherLocationTab()),
                ),
              ],
            ),
          ),
          SectionLabel(context.l10n.trainingPlan, color: Colors.orange),
          Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text(
              context.l10n.regenerateReplacesFutureSessionsAnd,
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
                  : context.l10n.regenerateWorkouts,
            ),
          ),
          if (generation.valueOrNull != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                context.l10n.valueUpcomingWorkoutsGenerated(
                  generation.value ?? 0,
                ),
                style: const TextStyle(color: mint, fontSize: 12),
              ),
            ),
          if (generation.hasError)
            Text(
              context.l10n.generationFailedCheckYourRace,
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
                      context.l10n.deleteAllWorkouts2,
                      context.l10n.thisDeletesPlannedWorkoutsOn,
                    )) {
                      if (context.mounted) await _deleteAll(context, ref);
                    }
                  },
            label: Text(
              context.l10n.deleteAllWorkouts,
              style: TextStyle(color: Colors.red),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text(
              context.l10n.changesAreSavedAutomatically2,
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
    throw StateError(tr.addAFutureRaceGoal);
  }
  final goals = await ref.read(goalSetProvider.future);
  final others = goals.active.length - 1;
  if (!context.mounted ||
      !await confirmAction(
        context,
        context.l10n.regenerateWorkouts2,
        'Replace future workouts and rebuild toward ${goal.name}'
        '${others > 0 ? ' and your $others other goal${others == 1 ? '' : 's'}' : ''}'
        ' using your current schedule?',
      )) {
    return;
  }
  final count = await ref.read(workoutGenerationProvider.notifier).generate();
  if (context.mounted && count != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.countUpcomingWorkoutsGenerated(count)),
      ),
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
            Expanded(
              child: Text(
                context.l10n.raceGoals,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: context.l10n.importRaceGoalsFromGarmin,
              icon: const Icon(Icons.sync, size: 18, color: Colors.lightBlue),
              onPressed: () => runUiAction(context, () async {
                await ref.read(raceGoalImportProvider)();
              }),
            ),
            IconButton(
              tooltip: context.l10n.addRaceGoal,
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
                  ? EmptyState(context.l10n.noRaceGoalsYetAdd)
                  : Column(
                      children: [
                        for (final g in goals)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(g.name),
                            onTap: () => showRaceGoalEditor(context, goal: g),
                            subtitle: Text(
                              '${dayText(g.raceDate)} · ${(g.distanceM / 1000).fixed(1)} km'
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
                                ref.invalidate(goalSetProvider);
                              }),
                              itemBuilder: (_) => [
                                for (final s in ['a', 'b', 'c'])
                                  PopupMenuItem(
                                    value: s,
                                    child: Text(
                                      context.l10n.priorityTouppercase(
                                        s.toUpperCase(),
                                      ),
                                    ),
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
                                  context.l10n.deleteRaceGoal,
                                  g.name,
                                )) {
                                  if (context.mounted) {
                                    await runUiAction(context, () async {
                                      await ref
                                          .read(raceGoalServiceProvider)
                                          .delete(g.id);
                                      ref.invalidate(upcomingRaceGoalsProvider);
                                      ref.invalidate(primaryRaceGoalProvider);
                                      ref.invalidate(goalSetProvider);
                                      await ref.read(
                                        retirePlanWithoutGoalsProvider,
                                      )();
                                    });
                                  }
                                }
                              },
                            ),
                          ),
                      ],
                    ),
            ),
        Padding(
          padding: EdgeInsets.only(top: 14),
          child: Text(
            context.l10n.goalsAreSharedWithAi,
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
  // Kept before the dialog opens: the dialog is closed through these, whether
  // or not the screen that started it is still there when the work is done.
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);
  final progress = ValueNotifier<(int, int, String)>((
    0,
    0,
    context.l10n.starting,
  ));
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(context.l10n.deletingWorkouts),
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
  if (navigator.mounted) navigator.pop();
  progress.dispose();
  final removed = result?.summary ?? '';
  final message = failure != null
      ? tr.deletingFailedFailure(failure)
      : removed.isNotEmpty
      ? tr.allPlannedWorkoutsDeletedRemoved(removed)
      : tr.allPlannedWorkoutsDeleted;
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
