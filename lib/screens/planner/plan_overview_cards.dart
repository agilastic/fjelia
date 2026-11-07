import '../../l10n/plan_text.dart';
import '../../l10n/l10n_ext.dart';
import '../../l10n/formats.dart';
import '../../providers/plan_weather_provider.dart';
import '../../widgets/race_calendar_share.dart';
import '../../widgets/rain_nowcast_line.dart';
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
import '../../services/open_meteo_client.dart' show OpenMeteoResult;
import '../../services/race_predictor.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/plan_timeline.dart';
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
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onTap: () => showAppSheet(context, const WeatherScreen()),
      child: ref
          .watch(planWeatherProvider)
          .when(
            loading: () => const SizedBox(
              height: 28,
              child: Center(child: LinearProgressIndicator()),
            ),
            error: (_, _) => Text(
              context.l10n.weatherUnavailableTapToRetry,
              style: TextStyle(color: muted),
            ),
            data: (data) {
              if (data?.current == null) {
                return Text(
                  context.l10n.weatherSetYourLocation,
                  style: TextStyle(color: muted),
                );
              }
              final now = DateTime.now();
              final days = data!.sevenDays(now);
              final others =
                  ref.watch(weatherComparisonProvider).valueOrNull ??
                  const <OpenMeteoResult>[];
              String amount(double? n) => n == null
                  ? '—'
                  : n < 10 && n != n.roundToDouble()
                  ? n.fixed(1)
                  : n.round().toString();
              const small = TextStyle(fontSize: 9, color: muted);
              Widget cell(String text, {Color? color, bool bold = false}) =>
                  SizedBox(
                    height: 15,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 9,
                          color: color ?? Colors.white70,
                          fontWeight: bold
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        weatherIcon(data.current!.weatherCode),
                        size: 15,
                        color: Colors.lightBlue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.l10n.t7DayForecast,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        context.l10n.round2(data.current!.temperatureC.round()),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 16, color: muted),
                    ],
                  ),
                  // The next hour or two from the DWD radar (Germany).
                  const RainNowcastLine(padding: EdgeInsets.only(top: 4)),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 42,
                        child: Column(
                          children: [
                            SizedBox(height: 15),
                            SizedBox(
                              height: 15,
                              child: Text(context.l10n.minMax, style: small),
                            ),
                            SizedBox(
                              height: 15,
                              child: Text(context.l10n.rainMm2, style: small),
                            ),
                            SizedBox(
                              height: 15,
                              child: Text(context.l10n.uvMax, style: small),
                            ),
                            SizedBox(
                              height: 15,
                              child: Text(context.l10n.kmH, style: small),
                            ),
                          ],
                        ),
                      ),
                      for (final day in days)
                        Expanded(
                          child: Column(
                            children: [
                              cell(DateFormat.E().format(day.date), bold: true),
                              cell(
                                day.minC == null
                                    ? '—'
                                    : '${day.minC!.round()}/${day.maxC!.round()}°',
                              ),
                              cell(switch (dailyRainRange(
                                day.date,
                                data.result,
                                others,
                                now,
                              )) {
                                // The forecasts disagree: their range.
                                final r? when r.high - r.low >= .5 =>
                                  '${amount(r.low)}–${amount(r.high)}',
                                // Drizzle that barely registers still shows.
                                _ when day.wet && (day.rainMm ?? 0) < .05 =>
                                  '<0.1',
                                _ => amount(day.rainMm),
                              }, color: Colors.lightBlue),
                              cell(amount(day.uv), color: Colors.amber),
                              cell(amount(day.windKmh)),
                            ],
                          ),
                        ),
                    ],
                  ),
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
    return speed == null ? '' : ' · ${speed.fixed(1)} km/h';
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
    // One goal is shown in full. With several they are one item, a line each,
    // that unfolds into the full cards.
    if (goals.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _GoalCard(goal: goals.first, primary: true, showPriority: false),
          Transform.translate(
            offset: const Offset(0, -10),
            child: _ShareGoalsButton(goals: goals, label: true),
          ),
        ],
      );
    }
    return Column(
      children: [
        _GoalsAccordion(goals: goals),
        const SeasonSummaryCard(),
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
    final lines = seasonReportLines(context.l10n, report);
    if (outcome == 'feasible' && lines.isEmpty) return const SizedBox.shrink();
    final (label, color) = switch (outcome) {
      'feasibleWithTradeoffs' => (
        context.l10n.seasonWithTradeOffs,
        Colors.orange,
      ),
      'requiresDecision' => (
        context.l10n.seasonNeedsYourDecision,
        Colors.redAccent,
      ),
      'infeasible' => (context.l10n.seasonCannotBeCombined, Colors.redAccent),
      'insufficientData' => (context.l10n.seasonProvisional, Colors.amber),
      _ => (context.l10n.season, Colors.green),
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
              lines.isEmpty ? context.l10n.allGoalsFit : lines.first,
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
              for (final alt in seasonAlternatives(context.l10n, report))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    context.l10n.alt(alt),
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// All race goals as one item: a header with a line per goal (name, priority,
/// date, weeks to go) that unfolds into the full cards and folds back.
class _GoalsAccordion extends StatefulWidget {
  const _GoalsAccordion({required this.goals});
  final List<RaceGoal> goals;

  @override
  State<_GoalsAccordion> createState() => _GoalsAccordionState();
}

class _GoalsAccordionState extends State<_GoalsAccordion> {
  bool open = false;

  static int _weeks(RaceGoal g) =>
      (g.raceDate.difference(DateUtils.dateOnly(DateTime.now())).inDays / 7)
          .ceil()
          .clamp(0, 999);

  @override
  Widget build(BuildContext context) {
    final goals = widget.goals;
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: panel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.orange.withValues(alpha: .6)),
              ),
              child: InkWell(
                key: const Key('goals-header'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => open = !open),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.flag_outlined,
                          size: 22,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.raceGoalsLength(goals.length),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!open)
                              for (final (i, g) in goals.indexed)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${g.name} · ${g.priority.toUpperCase()}'
                                          ' · ${dayText(g.raceDate)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        context.l10n.gWk(_weeks(g)),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: i == 0
                                              ? Colors.orange
                                              : Colors.lightBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                      // Unfolded, the season can be shared as an image.
                      if (open) _ShareGoalsButton(goals: goals),
                      Icon(
                        open ? Icons.expand_less : Icons.expand_more,
                        size: 22,
                        color: muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (open)
            for (final (i, g) in goals.indexed)
              _GoalCard(goal: g, primary: i == 0, showPriority: true),
        ],
      ),
    );
  }
}

/// Opens the race calendar as a shareable image.
class _ShareGoalsButton extends StatelessWidget {
  const _ShareGoalsButton({required this.goals, this.label = false});
  final List<RaceGoal> goals;
  final bool label;

  void _open(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RaceCalendarSharePage(goals: goals),
    ),
  );

  @override
  Widget build(BuildContext context) => label
      ? TextButton.icon(
          onPressed: () => _open(context),
          icon: const Icon(Icons.ios_share, size: 16),
          label: Text(context.l10n.shareRaceCalendar),
        )
      : IconButton(
          tooltip: context.l10n.shareRaceCalendar,
          visualDensity: VisualDensity.compact,
          onPressed: () => _open(context),
          icon: const Icon(Icons.ios_share, size: 20, color: Colors.orange),
        );
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
                          context.l10n.goalTargetfinishsecondsgoal(
                            formatTargetTime(goal.targetFinishSeconds!),
                            _goalPace(goal),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (estimate != null)
                        Text(
                          context.l10n.estEstimateestimate2(
                            RacePredictor.formatTime(estimate),
                            _ambition(goal, estimate),
                          ),
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
                      context.l10n.weeks(weeks),
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    Text(
                      context.l10n.weeks2,
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
    this.restToday = false,
  });
  final List<UpcomingPlanEntry> entries;
  final DateTime? selectedDay;

  /// Today is a planned rest day: it gets its own item, so the list does not
  /// start with tomorrow as if today were forgotten.
  final bool restToday;
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
    final today = DateUtils.dateOnly(DateTime.now());
    final showRest =
        widget.restToday &&
        !groups.containsKey(today) &&
        (widget.selectedDay == null ||
            DateUtils.isSameDay(widget.selectedDay, today));
    if (groups.isEmpty && !showRest) return const SizedBox.shrink();
    final entries = groups.entries
        .take(widget.selectedDay == null ? visibleDays : groups.length)
        .toList();
    final tomorrow = today.add(const Duration(days: 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: TimelineSectionHeader(
            label: context.l10n.upcoming,
            icon: Icons.rocket_launch_rounded,
            colors: planGradient,
          ),
        ),
        if (showRest) ...[
          TimelineDayLabel(context.l10n.today2, future: true, highlight: true),
          const _RestTile(),
        ],
        for (final e in entries) ...[
          TimelineDayLabel(
            e.key == today
                ? context.l10n.today2
                : e.key == tomorrow
                ? context.l10n.tomorrow
                : DateFormat.MMMMEEEEd().format(e.key).toUpperCase(),
            future: true,
            highlight: e.key == today,
          ),
          for (final s in e.value)
            if (s.session != null)
              _SessionTile(
                session: s.session!,
                skipReason: s.skipReason,
                doneBy: s.doneBy,
              )
            else
              _ScheduledTile(workout: s.workout!, doneBy: s.doneBy),
        ],
        if (groups.length > entries.length)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: planGradient.last,
              padding: EdgeInsets.zero,
            ),
            onPressed: () => setState(() => visibleDays += 5),
            child: Text(
              context.l10n.lengthMoreDays(groups.length - entries.length),
            ),
          ),
      ],
    );
  }
}

/// Today's planned rest day, shaped like a session so it reads as part of
/// the plan.
class _RestTile extends StatelessWidget {
  const _RestTile();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF9FA8DA);
    return _PlannedCard(
      key: const Key('rest-day-today'),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const _PlannedIcon(icon: Icons.bedtime_outlined, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.restDayTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.restDayPlannedNote,
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The frame of a planned entry: a ghost card with a dashed edge in the
/// sport's colour and a faint glow of what is ahead. Once the entry is done
/// the edge turns solid, like the cards in the history.
class _PlannedCard extends StatelessWidget {
  const _PlannedCard({
    super.key,
    required this.color,
    required this.child,
    this.solid = false,
    this.onTap,
  });
  final Color color;
  final Widget child;
  final bool solid;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CustomPaint(
        foregroundPainter: solid
            ? null
            : DashedBorderPainter(color: color.withValues(alpha: .75)),
        child: Material(
          color: ghostPanel,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: solid
                ? BorderSide(color: color.withValues(alpha: .55), width: 1.5)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  planGradient.first.withValues(alpha: solid ? 0 : .10),
                  planGradient.last.withValues(alpha: 0),
                ],
              ),
            ),
            child: InkWell(onTap: onTap, child: child),
          ),
        ),
      ),
    );
  }
}

/// The sport icon of a planned entry: only outlined, not filled in yet.
class _PlannedIcon extends StatelessWidget {
  const _PlannedIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: .6), width: 1.5),
    ),
    child: Icon(icon, color: color, size: 20),
  );
}

/// "0h59m · 9.4 km" for the activity that did a planned entry.
String _doneSummary(ActivityRecord a) {
  final minutes = (a.durationSeconds / 60).round();
  // The way the history writes it.
  final time = '${minutes ~/ 60}h${(minutes % 60).toString().padLeft(2, '0')}m';
  final km = (a.distanceMeters ?? 0) / 1000;
  return km > 0.05 ? '$time · ${km.fixed(1)} km' : time;
}

/// The mark of a finished entry: a check that settles in, in the app's green.
class _DoneCheck extends StatelessWidget {
  const _DoneCheck();
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: const Key('done-check'),
    tween: Tween(begin: 0.4, end: 1),
    duration: const Duration(milliseconds: 380),
    curve: Curves.elasticOut,
    builder: (_, scale, child) =>
        Transform.scale(scale: scale.clamp(0.0, 1.2), child: child),
    child: Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: mint.withValues(alpha: .35), blurRadius: 10),
        ],
      ),
      child: const Icon(Icons.check_circle, size: 24, color: mint),
    ),
  );
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, this.skipReason, this.doneBy});
  final TrainingSession session;

  /// The activity that did this session, when there is one.
  final ActivityRecord? doneBy;

  /// Why the session was cancelled, shown on its tile.
  final String? skipReason;
  @override
  Widget build(BuildContext context) {
    final s = session;
    final skipped = s.status == 'skipped';
    final done = !skipped && (doneBy != null || s.status == 'completed');
    // A cancelled session stays in the list, greyed and struck through, so the
    // plan shows what was dropped and why. A finished one is struck through
    // too, with a check, and says what was really done.
    final color = skipped
        ? Colors.white38
        : done
        ? mint
        : completedActivityColor(s.sport);
    final phaseColor = skipped
        ? Colors.orangeAccent
        : plannedActivityColor(s.phase);
    return _PlannedCard(
      color: color,
      solid: done,
      onTap: () => showAppSheet(context, PlanSessionSheet(session: s)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _PlannedIcon(icon: workoutSportIcon(s.sport), color: color),
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
                          skipped
                              ? context.l10n.skipped2
                              : planPhaseLabel(context.l10n, s.phase),
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
                          color: skipped || done ? Colors.white54 : null,
                          decoration: skipped || done
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: done ? mint : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    skipped
                        ? context.l10n.sessionDropped(
                            skipReason ?? context.l10n.skipped,
                            planDuration(s.plannedDurationMin),
                          )
                        : done
                        ? 'Done${doneBy == null ? '' : ' · ${_doneSummary(doneBy!)}'}'
                        : '${planDuration(s.plannedDurationMin)} · TRIMP ${s.plannedTrimp} · Z${s.primaryZone}',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (done)
              const _DoneCheck()
            else
              const Icon(Icons.chevron_right, size: 20, color: muted),
          ],
        ),
      ),
    );
  }
}

class _ScheduledTile extends StatelessWidget {
  const _ScheduledTile({required this.workout, this.doneBy});
  final ScheduledWorkout workout;

  /// The activity that did this workout, when there is one.
  final ActivityRecord? doneBy;
  @override
  Widget build(BuildContext context) {
    final done = doneBy != null;
    final color = done ? mint : completedActivityColor(workout.sportType);
    return _PlannedCard(
      color: color,
      solid: done,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _PlannedIcon(
          icon: workoutSportIcon(workout.sportType),
          color: color,
        ),
        title: Text(
          workout.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: done ? Colors.white54 : null,
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: done ? mint : null,
          ),
        ),
        subtitle: Text(
          done
              ? context.l10n.doneDoneby(_doneSummary(doneBy!))
              : context.l10n.garminWorkoutWorkout(workoutSummary(workout)),
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
        trailing: done
            ? const _DoneCheck()
            : const Icon(Icons.chevron_right, size: 20, color: muted),
        onTap: () =>
            showAppSheet(context, WorkoutDetailSheet(workout: workout)),
      ),
    );
  }
}
