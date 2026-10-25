import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../db/database.dart';
import '../../models/coach_context_card.dart';
import '../../models/planned_workout_presentation.dart';
import '../../models/workout_profile.dart';
import '../../providers/ftp_provider.dart';
import '../../providers/hr_zones_provider.dart';
import '../../providers/planner_providers.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/workout_destination_provider.dart';
import '../../providers/workout_push_provider.dart';
import '../../providers/day_data_provider.dart';
import '../../services/plan_session_actions.dart';
import '../../services/workout_destination.dart';
import '../../utils/target_time.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/move_workout_card.dart';
import '../../widgets/workout_profile_bar.dart';
import '../../widgets/workout_structure_list.dart';
import '../ai_coach/ai_coach_screen.dart';

class PlanSessionSheet extends ConsumerStatefulWidget {
  const PlanSessionSheet({super.key, required this.session});
  final TrainingSession session;
  @override
  ConsumerState<PlanSessionSheet> createState() => _SessionState();
}

class _SessionState extends ConsumerState<PlanSessionSheet> {
  late TrainingSession session = widget.session;
  bool busy = false;

  /// Where the workout was before it was moved in this sheet, for the undo.
  DateTime? movedFrom;
  bool movedOnWatch = false;
  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    await runUiAction(context, () async {
      await action();
      final fresh = await ref.refresh(
        plannedSessionProvider(session.id).future,
      );
      if (fresh != null && mounted) setState(() => session = fresh);
      ref.invalidate(sessionSkipReasonsProvider);
      ref.invalidate(upcomingSessionsProvider);
      ref.invalidate(scheduledWorkoutsProvider);
    });
    if (mounted) setState(() => busy = false);
  }

  PlanSessionActions get actions => ref.read(planSessionActionsProvider);
  @override
  Widget build(BuildContext context) {
    final s = session;
    final skipReason = ref.watch(sessionSkipReasonsProvider).valueOrNull?[s.id];
    final sport = s.sport.toLowerCase();
    final zones = ref.watch(hrZonesProvider);
    final zoneBounds =
        (sport.contains('cycl') || sport.contains('bik')
                ? zones.cycling
                : zones.running)
            .bounds;
    // Ranges are worked out from today's zones and FTP, not from what was
    // stored when the plan was made; both change over time.
    final isRide = sport.contains('cycl') || sport.contains('bik');
    final rideProfile = ref.watch(userProfileProvider).valueOrNull;
    // The ride's own choice wins; otherwise watts indoors or after the last
    // ride chosen on watts. Heart rate stays the guide next to them.
    final powerOn =
        isRide &&
        (s.targetMetric != null
            ? s.targetMetric == 'power'
            : rideProfile?.powerOnBike(indoor: s.indoor) ?? s.indoor);
    final ftp = powerOn ? ref.watch(ftpProvider).valueOrNull?.ftpWatts : null;
    final steps = plannedStepLines(
      s.stepsJson,
      primaryZone: s.primaryZone,
      zoneTarget: (z) => zoneTargetText(z, hrFloors: zoneBounds, ftp: ftp),
    );
    final profile = workoutProfile(
      s.stepsJson,
      primaryZone: s.primaryZone,
      sport: s.sport,
    );
    // The split comes from the steps when they are known; a stored split or
    // the typical one for the main zone only stands in without steps.
    final fromSteps = zoneFractionsOf(profile);
    final fractions =
        fromSteps ?? plannedZoneFractions(s.plannedZonesJson, s.primaryZone);
    // The days a move can go to: today up to the day before the race (or 60
    // days out), each with what is on it.
    final profileSettings = ref.watch(userProfileProvider).valueOrNull;
    final restDays = profileSettings?.restDays ?? const <int>[];
    final perDay = profileSettings?.maxSessionsPerDay ?? 1;
    final raceDay = ref.watch(primaryRaceGoalProvider).valueOrNull?.raceDate;
    final others = [
      for (final u
          in ref.watch(upcomingSessionsProvider).valueOrNull ??
              const <TrainingSession>[])
        if (u.id != s.id && u.status != 'skipped') u,
    ];
    final today0 = DateUtils.dateOnly(DateTime.now());
    final horizon = DateTime(today0.year, today0.month, today0.day + 60);
    var lastDay = raceDay == null
        ? horizon
        : DateTime(raceDay.year, raceDay.month, raceDay.day - 1);
    if (lastDay.isAfter(horizon)) lastDay = horizon;
    if (lastDay.isBefore(s.sessionDate)) lastDay = s.sessionDate;
    final moveDays = [
      for (
        var d = today0;
        !d.isAfter(lastDay);
        d = DateTime(d.year, d.month, d.day + 1)
      )
        () {
          final count = others
              .where((u) => DateUtils.isSameDay(u.sessionDate, d))
              .length;
          return MoveDay(
            date: d,
            sessions: count,
            isRestDay: restDays.contains(d.weekday),
            isFull: count >= perDay,
          );
        }(),
    ];

    Future<void> moveTo(DateTime day) async {
      final info = moveDays.where((m) => DateUtils.isSameDay(m.date, day));
      final target = info.isEmpty ? null : info.first;
      final warning = target == null
          ? null
          : target.isRestDay
          ? '${DateFormat('EEEE').format(day)} is a rest day in your plan.'
          : target.isFull
          ? '${DateFormat('EEEE d MMMM').format(day)} already has '
                '${target.sessions} ${target.sessions == 1 ? 'session' : 'sessions'}.'
          : null;
      if (warning != null &&
          !await confirmAction(context, 'Move anyway?', warning)) {
        return;
      }
      final previous = s.sessionDate;
      final onWatch =
          s.garminWorkoutId != null || s.garminAlternativeId != null;
      await perform(() async {
        await actions.moveToDate(s, day);
      });
      if (!mounted) return;
      // The way back stays on the card, with the first day it left; no
      // message that has to be swiped away.
      setState(() {
        movedFrom ??= previous;
        movedOnWatch = movedOnWatch || onWatch;
      });
    }

    final totals = blockTotals(profile);
    final planned = s.plannedDurationMin * 60.0;
    final stepsDiffer =
        profile.isNotEmpty &&
        !totals.anyEstimated &&
        (planned - totals.total).abs() >= 120;
    final editable = ['planned', 'adapted'].contains(s.status);
    const blue = Color(0xFF4FC3F7);
    const colors = [
      blue,
      mint,
      Color(0xFFFFCC00),
      Colors.orange,
      Colors.redAccent,
    ];
    Widget heading(String title) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          color: muted,
          fontWeight: FontWeight.w700,
          letterSpacing: .8,
        ),
      ),
    );
    Widget badge(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: blue.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: blue,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: .6,
        ),
      ),
    );
    ButtonStyle style(Color color, {bool filled = false}) =>
        OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: color.withValues(alpha: filled ? .12 : .04),
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: BorderSide(color: color.withValues(alpha: .45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
    return SheetPage(
      title: s.title,
      showHeader: false,
      backgroundColor: panel,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: badge(
                    '${s.phase.toUpperCase()} · ${s.sessionType.toUpperCase()}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              badge(
                s.status == 'skipped'
                    ? (skipReason == null
                          ? 'SKIPPED'
                          : 'SKIPPED · ${skipReason.toUpperCase()}')
                    : s.status.toUpperCase(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('EEEE, d MMMM yyyy').format(s.sessionDate),
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          WorkoutStatTiles(
            items: [
              ('${s.plannedDurationMin} min', 'DURATION'),
              ('${s.plannedTrimp}', 'TRIMP'),
              ('Z${s.primaryZone}', 'PRIMARY ZONE'),
              ('${s.weekNumber}', 'WEEK'),
            ],
          ),
          if (isRide) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 'hr',
                    icon: Icon(Icons.favorite, size: 16),
                    label: Text('Heart rate'),
                  ),
                  ButtonSegment(
                    value: 'power',
                    icon: Icon(Icons.bolt, size: 16),
                    label: Text('Watts'),
                  ),
                ],
                selected: {powerOn ? 'power' : 'hr'},
                onSelectionChanged: !editable || busy
                    ? null
                    : (v) => perform(() async {
                        await actions.setTargetMetric(s, v.first);
                        await ref
                            .read(userProfileProvider.notifier)
                            .save(rideProfile!.copyWith(bikeMetric: v.first));
                      }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                powerOn
                    ? (ref.watch(ftpProvider).valueOrNull?.ftpWatts == null
                          ? 'Watts need your FTP: set it under Load, Thresholds.'
                          : 'Main target in watts from your FTP, heart rate as the guide.')
                    : 'Main target heart rate, watts are not set on the watch.',
                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ),
          ],
          if (_paceGuide(s) case final guide?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                guide,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          if (s.sessionNotes?.isNotEmpty ?? false) ...[
            heading('ABOUT THIS WORKOUT'),
            Text(
              s.sessionNotes!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.6,
              ),
            ),
          ],
          if (s.mainSet?.isNotEmpty ?? false) ...[
            heading('COACHING CUES'),
            SectionCard(
              color: const Color(0xFF282828),
              child: Text(
                s.mainSet!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ),
          ],
          heading('WORKOUT STRUCTURE'),
          if (profile.isNotEmpty) ...[
            WorkoutProfileBar(blocks: profile),
            if (stepsDiffer)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'The steps add up to ${formatBlockDuration(totals.total)}; the plan counts ${s.plannedDurationMin} min.',
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ),
            const SizedBox(height: 14),
          ],
          if (steps.isEmpty)
            Text(
              [s.warmUp, s.coolDown]
                      .whereType<String>()
                      .where((s) => s.isNotEmpty)
                      .join('\n')
                      .isEmpty
                  ? 'No workout structure available.'
                  : [
                      s.warmUp,
                      s.coolDown,
                    ].whereType<String>().where((s) => s.isNotEmpty).join('\n'),
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          WorkoutStructureList(steps: steps),
          heading('TARGETS'),
          if (fromSteps == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Typical split for this kind of session; no steps to calculate it from.',
                style: TextStyle(fontSize: 11, color: muted),
              ),
            ),
          SectionCard(
            color: const Color(0xFF282828),
            child: Column(
              children: [
                for (var i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            'Z${i + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 84,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                const [
                                  'Recovery',
                                  'Aerobic',
                                  'Tempo',
                                  'Threshold',
                                  'VO2max',
                                ][i],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: muted,
                                ),
                              ),
                              for (final part in zoneTargetText(
                                i + 1,
                                hrFloors: zoneBounds,
                                ftp: ftp,
                              ).split(' · ').skip(1))
                                Text(
                                  part,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white38,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: fractions[i],
                            color: colors[i],
                            backgroundColor: Colors.white10,
                            borderRadius: BorderRadius.circular(5),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${(fractions[i] * 100).round()}%',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (s.adaptationTrigger?.isNotEmpty ?? false) ...[
            heading('ADAPTATION'),
            Text(
              s.adaptationTrigger!,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
          const SizedBox(height: 12),
          MoveWorkoutCard(
            title: s.title,
            current: s.sessionDate,
            days: moveDays,
            enabled: editable && !busy,
            onMove: moveTo,
            movedFrom:
                movedFrom != null &&
                    !DateUtils.isSameDay(movedFrom, s.sessionDate)
                ? movedFrom
                : null,
            note: movedOnWatch
                ? 'Push again to update your watch calendar.'
                : null,
            onUndo: () => perform(() async {
              final back = movedFrom;
              if (back == null) return;
              await actions.moveToDate(session, back);
              if (mounted) setState(() => movedFrom = null);
            }),
            onPickDate: () async {
              final today = DateUtils.dateOnly(DateTime.now());
              final last = moveDays.isEmpty ? today : moveDays.last.date;
              final chosen = await showDatePicker(
                context: context,
                initialDate: s.sessionDate.isBefore(today)
                    ? today
                    : s.sessionDate.isAfter(last)
                    ? last
                    : s.sessionDate,
                firstDate: today,
                lastDate: last.isBefore(today) ? today : last,
              );
              if (chosen != null) await moveTo(chosen);
            },
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            style: style(mint, filled: true),
            onPressed: () => openCoachTab(
              context,
              prompt: 'How do I execute this workout?',
              card: CoachContextCard.planned(
                s,
                skipReason: skipReason,
                zoneTarget: (z) =>
                    zoneTargetText(z, hrFloors: zoneBounds, ftp: ftp),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: const Text(
              'Ask AI Coach',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (buttonContext) {
              // One button per connected watch platform.
              final targets =
                  ref.watch(workoutTargetsProvider).valueOrNull ??
                  const <WorkoutTarget>[
                    (
                      destination: WorkoutDestination.garmin,
                      route: WorkoutRoute.push,
                    ),
                  ];
              Future<void> share(String? why) async {
                final workout = await ref
                    .read(trainingPlanServiceProvider)
                    .workoutText(s.id);
                final box = buttonContext.findRenderObject() as RenderBox?;
                if (why != null && context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(why)));
                }
                await SharePlus.instance.share(
                  ShareParams(
                    subject: workout.title,
                    text:
                        '${workout.title}\n${dayText(workout.date)}\n\n${workout.text}',
                    sharePositionOrigin: box == null
                        ? null
                        : box.localToGlobal(Offset.zero) & box.size,
                  ),
                );
              }

              Widget button(WorkoutTarget t, {required bool first}) {
                final destination = t.destination;
                final pushes = t.route == WorkoutRoute.push;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      style: style(blue, filled: first),
                      onPressed: !editable || busy || s.stepsJson == null
                          ? null
                          : () => perform(() async {
                              if (!pushes) return share(null);
                              final result = await ref.read(
                                pushWorkoutProvider,
                              )(s.id, destination);
                              if (!result.sent) {
                                return share(
                                  '${result.shareReason} Shared as text.',
                                );
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Workout sent to ${destination.label}',
                                    ),
                                  ),
                                );
                              }
                            }),
                      icon: Icon(
                        pushes ? Icons.watch_outlined : Icons.ios_share,
                        size: 20,
                      ),
                      label: Text(
                        busy
                            ? 'Updating…'
                            : pushes
                            ? 'Push to ${destination.label}'
                            : 'Share workout for ${destination.label}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!pushes && destination.unavailableNote != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          destination.unavailableNote!,
                          style: const TextStyle(fontSize: 11, color: muted),
                        ),
                      ),
                    if (!pushes && destination == WorkoutDestination.coros)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          style: style(mint),
                          icon: const Icon(Icons.science_outlined, size: 20),
                          onPressed: () async {
                            if (!await confirmAction(
                              context,
                              'Send workouts to COROS?',
                              'COROS has no workout import, so this uses the Training Hub\'s unofficial web interface with your COROS login. It is not endorsed by COROS, can stop working, and a workout should be checked in the Training Hub afterwards. Turn it on?',
                            )) {
                              return;
                            }
                            final profile = ref
                                .read(userProfileProvider)
                                .valueOrNull;
                            if (profile == null || !context.mounted) return;
                            await runUiAction(
                              context,
                              () => ref
                                  .read(userProfileProvider.notifier)
                                  .save(
                                    profile.copyWith(corosWorkoutPush: true),
                                  ),
                            );
                          },
                          label: const Text(
                            'Send to COROS instead (experimental)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (pushes && destination != WorkoutDestination.garmin)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Experimental: sent through the COROS Training Hub\'s unofficial interface. Check the workout in the Training Hub; a changed workout has to be removed there by hand.',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < targets.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    button(targets[i], first: i == 0),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: style(Colors.grey),
            onPressed: !editable || busy
                ? null
                : () async {
                    final reason = await _pickSkipReason(
                      context,
                      onGarmin: s.garminAlternativeId != null,
                    );
                    if (reason == null || !mounted) return;
                    await perform(() async {
                      await actions.markRest(s, reason: reason);
                    });
                  },
            icon: const Icon(Icons.bed_outlined, size: 20),
            label: const Text(
              'Mark as Rest',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          if (s.status == 'skipped') ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: style(mint),
              onPressed: busy
                  ? null
                  : () => perform(() async {
                      await actions.restore(s);
                    }),
              icon: const Icon(Icons.undo, size: 20),
              label: const Text(
                'Restore workout',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Asks why a session is skipped; null when cancelled.
Future<String?> _pickSkipReason(
  BuildContext context, {
  required bool onGarmin,
}) => showDialog<String>(
  context: context,
  builder: (context) => SimpleDialog(
    title: const Text('Skip this workout?'),
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        child: Text(
          onGarmin
              ? 'Why? It is also taken off your Garmin calendar. Nothing is added to make it up.'
              : 'Why? Nothing is added to make it up.',
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
      ),
      for (final reason in skipReasons)
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, reason),
          child: Text(reason),
        ),
      SimpleDialogOption(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
      ),
    ],
  ),
);

/// "Pace guide 5:20/km to 5:50/km, estimated from your goal" for a run that has
/// one; heart rate stays the target.
String? _paceGuide(TrainingSession s) {
  final json = s.paceRangesJson;
  if (json == null) return null;
  try {
    final pace = jsonDecode(json) as Map<String, dynamic>;
    final low = pace['low_sec_per_km'], high = pace['high_sec_per_km'];
    if (low is! num || high is! num) return null;
    final goal = pace['goal_sec_per_km'];
    return 'Pace guide ${formatPace(low.toDouble())} to ${formatPace(high.toDouble())}'
        '${pace['basis'] == 'goal' ? ', estimated from your goal' : ''}'
        '${goal is num ? ' · goal pace on the flat ${formatPace(goal.toDouble())}' : ''}. '
        'Heart rate decides.';
  } catch (_) {
    return null;
  }
}
