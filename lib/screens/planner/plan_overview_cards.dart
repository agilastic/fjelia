import '../../theme/fjelia_style.dart';
import '../../l10n/plan_text.dart';
import '../../l10n/l10n_ext.dart';
import '../../l10n/formats.dart';
import '../../providers/plan_weather_provider.dart';
import '../../widgets/race_calendar_share.dart';
import '../../widgets/rain_nowcast_line.dart';
import '../../widgets/weather_glyph.dart';
import '../../widgets/weather_sky.dart';
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
import '../../widgets/plan_timeline.dart';
import '../settings/training_tab.dart';
import 'plan_session_sheet.dart';
import '../../utils/target_time.dart';
import '../../models/race_profile.dart';

/// The coming week as small skies: the day's weather is the picture
/// (sun glow, clouds, rain falling as hard as forecast, wind streaks) and
/// only the high and low are written on it. A tap on a day opens the full
/// forecast on that day; a tap elsewhere opens it on today.
class PlanWeatherStrip extends ConsumerWidget {
  const PlanWeatherStrip({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(weatherLocationEnabledProvider)) {
      return const SizedBox.shrink();
    }
    return SectionCard(
      padding: const EdgeInsets.all(6),
      onTap: () => showAppSheet(context, const WeatherScreen()),
      child: ref
          .watch(planWeatherProvider)
          .when(
            loading: () => const SizedBox(
              height: 28,
              child: Center(child: LinearProgressIndicator()),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                context.l10n.weatherUnavailableTapToRetry,
                style: TextStyle(color: muted),
              ),
            ),
            data: (data) {
              if (data?.current == null) {
                return Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    context.l10n.weatherSetYourLocation,
                    style: TextStyle(color: muted),
                  ),
                );
              }
              final now = DateTime.now();
              final days = data!.sevenDays(now);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The next hour or two from the DWD radar (Germany).
                  const RainNowcastLine(
                    padding: EdgeInsets.fromLTRB(6, 2, 6, 6),
                  ),
                  // About four and a half days in view, the rest a swipe away.
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: days.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, i) => GestureDetector(
                        key: ValueKey('plan-weather-day-$i'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => showAppSheet(
                          context,
                          WeatherScreen(initialDay: days[i].date),
                        ),
                        child: SizedBox(
                          width: 74,
                          child: _SkyTile(
                            day: days[i],
                            label: i == 0
                                ? context.l10n.today
                                : DateFormat.E().format(days[i].date),
                            // The daytime hours make the picture.
                            kind: dominantWeather(
                              data
                                  .pointsFor(days[i].date, false)
                                  .where(
                                    (p) => p.time.hour >= 7 && p.time.hour < 20,
                                  )
                                  .map((p) => weatherKindOf(p.weatherCode)),
                            ),
                            index: i,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }
}

/// One day: the sky behind, the high large and the low beside it.
class _SkyTile extends StatelessWidget {
  const _SkyTile({
    required this.day,
    required this.label,
    required this.kind,
    required this.index,
  });
  final PlanWeatherDay day;
  final String label;
  final WeatherKind? kind;
  final int index;

  @override
  Widget build(BuildContext context) {
    final kind = this.kind ?? WeatherKind.cloudy;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + 80 * index),
      curve: Curves.easeOutCubic,
      // Moves and grows in rather than fading: an Opacity layer over the
      // glyph's blurred glow trips Impeller's validation.
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, (1 - t) * 8),
        child: Transform.scale(scale: .9 + .1 * t, child: child),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 64,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: WeatherSkyPainter(
                  kind,
                  rainMm: day.rainMm ?? 0,
                  windKmh: day.windKmh ?? 0,
                ),
              ),
              Positioned(
                right: -9,
                top: -5,
                child: WeatherGlyph(kind: kind, size: 44),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: fjInk,
                        shadows: _shadow,
                      ),
                    ),
                    const Spacer(),
                    if (day.maxC != null)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${day.maxC!.round()}°',
                                style: const TextStyle(
                                  fontSize: 19,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: ' ${day.minC!.round()}°',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: fjInk70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          style: TextStyle(color: fjInk, shadows: _shadow),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _shadow = [Shadow(color: Colors.black45, blurRadius: 4)];
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
    // How the goals fit together goes into the FjeliaPro season analysis
    // (seasonCheckLines), not onto the plan.
    return _GoalsAccordion(goals: goals);
  }
}

/// All race goals as one slim item: the season as a line from today to the
/// last race with a dot per goal, and the weeks to the plan's own goal. A tap
/// unfolds the full cards and folds them back.
class _GoalsAccordion extends StatefulWidget {
  const _GoalsAccordion({required this.goals});
  final List<RaceGoal> goals;

  @override
  State<_GoalsAccordion> createState() => _GoalsAccordionState();
}

class _GoalsAccordionState extends State<_GoalsAccordion> {
  static const _accent = [Color(0xFFFFB13D), Color(0xFFFFE066)];
  bool open = false;

  static int _weeks(RaceGoal g) =>
      (g.raceDate.difference(DateUtils.dateOnly(DateTime.now())).inDays / 7)
          .ceil()
          .clamp(0, 999);

  @override
  Widget build(BuildContext context) {
    final goals = widget.goals;
    final first = goals.first;
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          // The same accordion card as everywhere (style.md): title, the
          // season and its weeks, the large chevron centred on the right.
          SectionCard(
            key: const Key('goals-header'),
            accent: _accent,
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            onTap: () => setState(() => open = !open),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GradientTitle(
                        goals.length == 1
                            ? first.name
                            : context.l10n.raceGoalsLength(goals.length),
                        colors: _accent,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _SeasonTrack(goals: goals)),
                          const SizedBox(width: 12),
                          // Unfolded, the season can be shared as an image.
                          if (open)
                            _ShareGoalsButton(goals: goals)
                          else
                            KeyFigure(
                              context.l10n.weeks(_weeks(first)),
                              unit: context.l10n.weeks2,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedRotation(
                  turns: open ? .5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(Icons.expand_more, size: 28, color: fjInk),
                ),
              ],
            ),
          ),
          if (open)
            for (final (i, g) in goals.indexed)
              // The cards come in one after the other.
              TweenAnimationBuilder<double>(
                key: ValueKey(g.id),
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 260 + 70 * i),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Transform.translate(
                  offset: Offset(0, (1 - t) * -12),
                  child: Transform.scale(scale: .96 + .04 * t, child: child),
                ),
                child: _GoalCard(
                  goal: g,
                  primary: i == 0,
                  showPriority: goals.length > 1,
                ),
              ),
        ],
      ),
    );
  }
}

/// The season from today to the last race: the line draws itself in and a
/// dot per goal, lettered with its priority, pops up where its date falls.
class _SeasonTrack extends StatelessWidget {
  const _SeasonTrack({required this.goals});
  final List<RaceGoal> goals;

  static Color _color(RaceGoal g, bool primary) => primary
      ? const Color(0xFFFFB13D)
      : switch (g.priority.toLowerCase()) {
          'a' => const Color(0xFFFF4D8D),
          'b' => const Color(0xFF6FA8FF),
          _ => fjInk54,
        };

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final span = goals
        .map((g) => g.raceDate.difference(today).inDays)
        .fold(1, (a, b) => b > a ? b : a);
    const dot = 16.0;
    return SizedBox(
      height: dot,
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth - dot;
          // The plan's own goal last, so it sits on top where dates meet.
          final order = [...goals.indexed.skip(1), goals.indexed.first];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: dot / 2,
                  right: dot / 2,
                  top: dot / 2 - 1,
                  child: Container(height: 2, color: fjInk12),
                ),
                Positioned(
                  left: dot / 2,
                  top: dot / 2 - 1,
                  child: Container(
                    width: width * t,
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFB13D).withValues(alpha: .15),
                          const Color(0xFFFFB13D),
                        ],
                      ),
                    ),
                  ),
                ),
                // Today.
                Positioned(
                  left: dot / 2 - 3,
                  top: dot / 2 - 3,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: fjInk70,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                for (final (i, g) in order)
                  () {
                    final at = (g.raceDate.difference(today).inDays / span)
                        .clamp(0.0, 1.0);
                    final shown = ((t - at * .8) / .2).clamp(0.0, 1.0);
                    final color = _color(g, i == 0);
                    return Positioned(
                      left: width * at,
                      top: 0,
                      child: Transform.scale(
                        scale: Curves.easeOutBack.transform(shown),
                        child: Container(
                          width: dot,
                          height: dot,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: panel, width: 1.5),
                            boxShadow: i == 0
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: .55),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            g.priority.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 8.5,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  }(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Opens the race calendar as a shareable image.
class _ShareGoalsButton extends StatelessWidget {
  const _ShareGoalsButton({required this.goals});
  final List<RaceGoal> goals;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.shareRaceCalendar,
    visualDensity: VisualDensity.compact,
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RaceCalendarSharePage(goals: goals),
      ),
    ),
    icon: Icon(
      Icons.ios_share,
      size: 20,
      color: fjAccent(const Color(0xFFFFB13D)),
    ),
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
    final accent = primary ? const Color(0xFFFFB13D) : const Color(0xFF6FA8FF);
    return SectionCard(
      accent: primary
          ? const [Color(0xFFFFB13D), Color(0xFFFFE066)]
          : const [Color(0xFF6FA8FF), Color(0xFF3EE0FF)],
      onTap: () => showAppSheet(context, const TrainingTab()),
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
                  style: TextStyle(fontSize: 11, color: fjInk70),
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
                          : fjInk70,
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
                    style: TextStyle(fontSize: 12, color: muted),
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
        ? fjInk38
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
                          color: skipped || done ? fjInk54 : null,
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
                    style: TextStyle(fontSize: 11, color: fjInk70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (done)
              const _DoneCheck()
            else
              Icon(Icons.chevron_right, size: 20, color: muted),
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
            color: done ? fjInk54 : null,
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: done ? mint : null,
          ),
        ),
        subtitle: Text(
          done
              ? context.l10n.doneDoneby(_doneSummary(doneBy!))
              : context.l10n.garminWorkoutWorkout(workoutSummary(workout)),
          style: TextStyle(fontSize: 11, color: fjInk70),
        ),
        trailing: done
            ? const _DoneCheck()
            : Icon(Icons.chevron_right, size: 20, color: muted),
        onTap: () =>
            showAppSheet(context, WorkoutDetailSheet(workout: workout)),
      ),
    );
  }
}
