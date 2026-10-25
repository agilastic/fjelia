import '../../providers/plan_weather_provider.dart';
import '../../widgets/weather_visuals.dart';
import '../weather/weather_screen.dart';
import '../../providers/upcoming_plan_provider.dart';
import '../../models/garmin_data.dart';
import '../../models/workout_presentation.dart';
import '../activities/workout_detail_sheet.dart';
import '../../theme/activity_colors.dart'
    show plannedActivityColor, completedActivityColor, activitySportIcon;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../db/database.dart';
import '../../providers/planner_providers.dart';
import '../../services/race_predictor.dart';
import '../../widgets/app_widgets.dart';
import '../settings/training_tab.dart';
import 'plan_session_sheet.dart';
import '../../utils/target_time.dart';
import '../../models/race_profile.dart';

class PlanWeatherStrip extends ConsumerWidget {
  const PlanWeatherStrip({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(weatherLocationEnabledProvider)) {
      return const SizedBox.shrink();
    }
    final state = ref.watch(planWeatherProvider);
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: () => showAppSheet(context, const WeatherScreen()),
      child: state.when(
        loading: () => const SizedBox(
          height: 34,
          child: Center(child: LinearProgressIndicator()),
        ),
        error: (e, st) => const Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: muted),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Weather unavailable · Tap to retry',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
          ],
        ),
        data: (data) {
          final current = data?.current;
          if (current == null) {
            return const Row(
              children: [
                Icon(Icons.location_on_outlined, color: muted),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Weather · Set your location',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ),
                Icon(Icons.chevron_right, color: muted),
              ],
            );
          }
          return Row(
            children: [
              Icon(
                weatherIcon(current.weatherCode),
                size: 22,
                color: Colors.lightBlue,
              ),
              const SizedBox(width: 8),
              Text(
                '${current.temperatureC.round()}°',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${current.humidityPct.round()}%',
                style: const TextStyle(fontSize: 10, color: muted),
              ),
              const SizedBox(width: 12),
              for (final p in data!.upcoming.skip(1))
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${p.temperatureC.round()}°',
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('HH').format(p.time),
                        style: const TextStyle(fontSize: 9, color: muted),
                      ),
                    ],
                  ),
                ),
              const Icon(Icons.chevron_right, size: 16, color: muted),
            ],
          );
        },
      ),
    );
  }
}

RaceProfile _profileOf(RaceGoal goal) => RaceProfile(
  sport: goal.primarySport,
  distanceM: goal.distanceM,
  elevationM: goal.elevationM,
  targetSeconds: goal.targetFinishSeconds,
);

/// " · 4:59/km" or " · 25.0 km/h" for the goal.
String _goalPace(RaceGoal goal) {
  final profile = _profileOf(goal);
  if (profile.isRide) {
    final speed = profile.goalSpeedKmh;
    return speed == null ? '' : ' · ${speed.toStringAsFixed(1)} km/h';
  }
  final pace = profile.goalPaceSecPerKm;
  return pace == null ? '' : ' · ${formatPace(pace)}';
}

/// A note when the goal is clearly faster than the estimate, so the athlete
/// knows it is a stretch, not a forecast.
String _ambition(RaceGoal goal, int estimate) {
  final ahead = _profileOf(goal).aheadOfPrediction(estimate);
  if (ahead == null || ahead < 0.05) return '';
  return ' · goal ${(ahead * 100).round()}% faster';
}

/// Every goal of the season, the plan's own first, and what the plan makes of
/// them together.
class RaceCountdownCard extends ConsumerWidget {
  const RaceCountdownCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(seasonGoalsProvider).valueOrNull ?? const [];
    if (goals.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final (i, goal) in goals.indexed)
          _GoalCard(
            goal: goal,
            primary: i == 0,
            showPriority: goals.length > 1,
          ),
        if (goals.length > 1) const SeasonSummaryCard(),
      ],
    );
  }
}

/// How the goals fit together: the outcome and, in words, what is limited or
/// needs a decision. Nothing is shown when the plan is plainly feasible.
class SeasonSummaryCard extends ConsumerWidget {
  const SeasonSummaryCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(seasonReportProvider).valueOrNull;
    if (report == null) return const SizedBox.shrink();
    final outcome = report['outcome'] as String? ?? 'feasible';
    final lines = <String>[
      for (final c in (report['conflicts'] as List? ?? const []))
        (c as Map)['message'] as String,
      for (final t in (report['summary'] as List? ?? const [])) t as String,
    ];
    if (outcome == 'feasible' && lines.isEmpty) return const SizedBox.shrink();
    final (label, color) = switch (outcome) {
      'feasibleWithTradeoffs' => ('Season: with trade-offs', Colors.orange),
      'requiresDecision' => ('Season: needs your decision', Colors.redAccent),
      'infeasible' => ('Season: cannot be combined', Colors.redAccent),
      'insufficientData' => ('Season: provisional', Colors.amber),
      _ => ('Season', Colors.green),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withValues(alpha: .6)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(Icons.balance_outlined, color: color),
            title: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              lines.isEmpty ? 'All goals fit.' : lines.first,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(line, style: const TextStyle(fontSize: 12)),
                ),
              for (final c in (report['conflicts'] as List? ?? const []))
                for (final alt
                    in ((c as Map)['alternatives'] as List? ?? const []))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '→ $alt',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
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

class _GoalCard extends ConsumerWidget {
  const _GoalCard({
    required this.goal,
    required this.primary,
    required this.showPriority,
  });
  final RaceGoal goal;
  final bool primary;
  final bool showPriority;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estimate = ref.watch(raceFinishEstimateProvider(goal)).valueOrNull;
    final weeks =
        (goal.raceDate.difference(DateUtils.dateOnly(DateTime.now())).inDays /
                7)
            .ceil()
            .clamp(0, 999);
    final accent = primary ? Colors.orange : Colors.lightBlue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: accent.withValues(alpha: .6)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showAppSheet(context, const TrainingTab()),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    goal.primarySport.startsWith('cycl')
                        ? Icons.pedal_bike
                        : Icons.flag_outlined,
                    size: 24,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showPriority
                            ? '${goal.name} · ${goal.priority.toUpperCase()}'
                            : goal.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${valueText(goal.distanceM / 1000, goal.distanceM % 1000 == 0 ? 0 : 1)} km${goal.elevationM == null ? '' : ' · ↑${valueText(goal.elevationM)} m'} · ${dayText(goal.raceDate)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                      if (goal.targetFinishSeconds != null)
                        Text(
                          'Goal ${formatTargetTime(goal.targetFinishSeconds!)}'
                          '${_goalPace(goal)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (estimate != null)
                        Text(
                          'Est. ${RacePredictor.formatTime(estimate)}'
                          '${_ambition(goal, estimate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: goal.targetFinishSeconds == null
                                ? accent
                                : Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    Text(
                      '$weeks',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const Text(
                      'weeks',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData workoutSportIcon(String sport) => activitySportIcon(sport);

class UpcomingWorkoutList extends StatefulWidget {
  const UpcomingWorkoutList({
    super.key,
    required this.entries,
    this.selectedDay,
  });
  final List<UpcomingPlanEntry> entries;
  final DateTime? selectedDay;
  @override
  State<UpcomingWorkoutList> createState() => _UpcomingState();
}

class _UpcomingState extends State<UpcomingWorkoutList> {
  int visibleDays = 2;
  @override
  Widget build(BuildContext context) {
    final groups = <DateTime, List<UpcomingPlanEntry>>{};
    final sorted = widget.entries;
    for (final s in sorted) {
      if (widget.selectedDay != null &&
          !DateUtils.isSameDay(s.date, widget.selectedDay)) {
        continue;
      }
      groups.putIfAbsent(DateUtils.dateOnly(s.date), () => []).add(s);
    }
    if (groups.isEmpty) return const SizedBox.shrink();
    final entries = groups.entries
        .take(widget.selectedDay == null ? visibleDays : groups.length)
        .toList();
    final tomorrow = DateUtils.dateOnly(
      DateTime.now(),
    ).add(const Duration(days: 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 10),
          child: Text(
            'UPCOMING',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
        ),
        for (final e in entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              e.key == tomorrow
                  ? 'TOMORROW'
                  : DateFormat('EEEE, d MMMM').format(e.key).toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                color: muted,
                letterSpacing: .7,
              ),
            ),
          ),
          for (final s in e.value)
            if (s.session != null)
              _SessionTile(session: s.session!, skipReason: s.skipReason)
            else
              _ScheduledTile(workout: s.workout!),
        ],
        if (groups.length > entries.length)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: mint,
              padding: EdgeInsets.zero,
            ),
            onPressed: () => setState(() => visibleDays += 5),
            child: Text('+ ${groups.length - entries.length} more days'),
          ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, this.skipReason});
  final TrainingSession session;

  /// Why the session was cancelled, shown on its tile.
  final String? skipReason;
  @override
  Widget build(BuildContext context) {
    final s = session;
    final skipped = s.status == 'skipped';
    // A cancelled session stays in the list, greyed and struck through, so the
    // plan shows what was dropped and why.
    final color = skipped ? Colors.white38 : completedActivityColor(s.sport);
    final phaseColor = skipped
        ? Colors.orangeAccent
        : plannedActivityColor(s.phase);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withValues(alpha: .45), width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showAppSheet(context, PlanSessionSheet(session: s)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    workoutSportIcon(s.sport),
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: phaseColor.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              skipped ? 'SKIPPED' : s.phase.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                color: phaseColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            s.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: skipped ? Colors.white54 : null,
                              decoration: skipped
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        skipped
                            ? '${skipReason ?? 'Skipped'} · ${s.plannedDurationMin} min dropped'
                            : '${s.plannedDurationMin} min · TRIMP ${s.plannedTrimp} · Z${s.primaryZone}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 20, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduledTile extends StatelessWidget {
  const _ScheduledTile({required this.workout});
  final ScheduledWorkout workout;
  @override
  Widget build(BuildContext context) {
    final color = completedActivityColor(workout.sportType);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withValues(alpha: .45), width: 1.5),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              workoutSportIcon(workout.sportType),
              color: color,
              size: 22,
            ),
          ),
          title: Text(
            workout.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            'Garmin Workout · ${workoutSummary(workout)}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20, color: muted),
          onTap: () =>
              showAppSheet(context, WorkoutDetailSheet(workout: workout)),
        ),
      ),
    );
  }
}
