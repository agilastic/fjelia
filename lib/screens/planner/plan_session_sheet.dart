import '../../theme/fjelia_style.dart';
import '../../l10n/formats.dart';
import '../../l10n/plan_text.dart';
import '../../l10n/l10n_ext.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../db/database.dart';
import '../../models/coach_context_card.dart';
import '../../models/planned_workout_presentation.dart';
import '../../models/strength_workout.dart';
import '../../models/workout_profile.dart';
import '../../providers/ftp_provider.dart';
import '../../providers/hr_zones_provider.dart';
import '../../providers/planner_providers.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/workout_destination_provider.dart';
import '../../providers/workout_providers_provider.dart';
import '../../providers/workout_push_provider.dart';
import '../../providers/day_data_provider.dart';
import '../../services/plan_session_actions.dart';
import '../../services/workout_replacement_service.dart';
import '../../services/season/goal_set.dart' show DayLoad;
import '../../utils/target_time.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/plan_timeline.dart' show planGradient;
import '../../widgets/move_workout_card.dart';
import '../../widgets/workout_profile_bar.dart';
import '../../widgets/workout_structure_list.dart';
import '../../widgets/nutrition_widgets.dart';
import '../../models/workout_nutrition.dart';
import '../ai_coach/ai_coach_screen.dart';
import '../strength/strength_sections.dart';
import '../../services/strength/strength_repository.dart';
import '../../services/strength/strength_templates.dart';
import 'workout_delivery_setup.dart';
import '../../providers/media_provider.dart';
import '../../widgets/media_gallery.dart';
import '../../widgets/manual_activity_sheet.dart';

class PlanSessionSheet extends ConsumerStatefulWidget {
  const PlanSessionSheet({super.key, required this.session});
  final TrainingSession session;
  @override
  ConsumerState<PlanSessionSheet> createState() => _SessionState();
}

class _SessionState extends ConsumerState<PlanSessionSheet> {
  late TrainingSession session = widget.session;
  bool busy = false;

  /// The platform a workout is being sent to: only its button says so.
  String? pushingTo;

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
    // The goal this session prepares for, when the plan has more than one.
    final goals = ref.watch(goalSetProvider).valueOrNull;
    final goalPriority = goals != null && goals.active.length > 1
        ? goals.byId(s.goalId ?? '')?.priority.name
        : null;
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
    // Every goal decides what a day can take, not only the one shown.
    final raceDay =
        goals?.horizonEnd ??
        ref.watch(primaryRaceGoalProvider).valueOrNull?.raceDate;
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
            event: goals?.eventBlocking(d)?.name,
            isEasyOnly: goals?.loadOn(d) == DayLoad.easyOnly,
          );
        }(),
    ];

    Future<void> moveTo(DateTime day) async {
      final event = goals?.eventBlocking(day);
      if (event != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${DateFormat.MMMMEEEEd().format(day)} belongs to '
              '${event.name}. Pick another day.',
            ),
          ),
        );
        return;
      }
      final info = moveDays.where((m) => DateUtils.isSameDay(m.date, day));
      final target = info.isEmpty ? null : info.first;
      final warning = target == null
          ? null
          : target.isRestDay
          ? '${DateFormat.EEEE().format(day)} is a rest day in your plan.'
          : target.isFull
          ? '${DateFormat.MMMMEEEEd().format(day)} already has '
                '${target.sessions} ${target.sessions == 1 ? 'session' : 'sessions'}.'
          : null;
      if (warning != null &&
          !await confirmAction(context, context.l10n.moveAnyway, warning)) {
        return;
      }
      final previous = s.sessionDate;
      final onWatch =
          (await ref.read(workoutProvidersProvider).deliveredTo(s)).isNotEmpty;
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
    // Lifting has exercises and sets, not zones or a time-in-zone split.
    final strength = isStrengthSport(s.sport);
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
        style: TextStyle(
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
                    '${planPhaseLabel(context.l10n, s.phase)} · '
                    '${sessionTypeLabel(context.l10n, s.sessionType)}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              badge(
                s.status == 'skipped'
                    ? (skipReason == null
                          ? context.l10n.skipped2
                          : context.l10n.skippedTouppercase(
                              skipReason.toUpperCase(),
                            ))
                    : sessionStatusLabel(context.l10n, s.status),
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
            DateFormat.yMMMMEEEEd().format(s.sessionDate),
            style: TextStyle(fontSize: 13, color: fjInk70),
          ),
          if (s.goalObjective != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.flag_outlined,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      goalPriority == null
                          ? planObjectiveLabel(context.l10n, s.goalObjective!)
                          : '${planObjectiveLabel(context.l10n, s.goalObjective!)} · ${goalPriority.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          WorkoutStatTiles(
            items: [
              (planDuration(s.plannedDurationMin), context.l10n.duration2),
              if (!strength) ...[
                ('${s.plannedTrimp}', 'TRIMP'),
                ('Z${s.primaryZone}', context.l10n.primaryZone),
              ],
              ('${s.weekNumber}', context.l10n.week2),
            ],
          ),
          if (isRide) ...[
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: 'hr',
                    icon: Icon(Icons.favorite, size: 16),
                    label: Text(context.l10n.heartRate3),
                  ),
                  ButtonSegment(
                    value: 'power',
                    icon: Icon(Icons.bolt, size: 16),
                    label: Text(context.l10n.watts),
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
                          ? context.l10n.wattsNeedYourFtpSet
                          : context.l10n.mainTargetInWattsFrom)
                    : context.l10n.mainTargetHeartRateWatts,
                style: TextStyle(fontSize: 11, color: muted),
              ),
            ),
          ],
          if (_paceGuide(s) case final guide?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                guide,
                style: TextStyle(fontSize: 12, color: fjInk70),
              ),
            ),
          if (s.sessionNotes?.isNotEmpty ?? false) ...[
            heading(context.l10n.aboutThisWorkout),
            Text(
              s.sessionNotes!,
              style: TextStyle(fontSize: 14, color: fjInk70, height: 1.6),
            ),
          ],
          if (s.mainSet?.isNotEmpty ?? false) ...[
            heading(context.l10n.coachingCues),
            SectionCard(
              color: duo(0xFF282828, 0xFFEEF1F5),
              child: Text(
                s.mainSet!,
                style: TextStyle(fontSize: 13, color: fjInk70, height: 1.5),
              ),
            ),
          ],
          if (strength &&
              editable &&
              isLegacyStrengthSession(
                s.subType,
                s.phase,
                sessionNotes: s.sessionNotes,
              ))
            StrengthProgrammeUpdateCard(
              // The session was replaced; its sheet shows what no longer is.
              onUpdated: () {
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          if (strength)
            PlannedStrengthSection(
              owner: StrengthPlanOwner.session(s.id),
              sessionDate: s.sessionDate,
              editable: editable,
              // Taper, recovery and protected days keep their load.
              // Gym mode may have completed the session.
              onLiveFinished: () => perform(() async {}),
              progressionBlockedReason: s.phase == 'taper'
                  ? context.l10n.taperPhase
                  : s.sessionType == 'recovery'
                  ? context.l10n.recoverySession
                  : goals?.loadOn(s.sessionDate) == DayLoad.easyOnly
                  ? context.l10n.closeToYourEvent
                  : null,
              fallback: bundledStrengthPlanFor(
                subType: s.subType,
                sessionNotes: s.sessionNotes,
              ),
            ),
          if (!strength) ...[
            if (editable &&
                s.indoor &&
                (sport.contains('run') ||
                    sport.contains('cycl') ||
                    sport.contains('bik') ||
                    sport.contains('row')))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () => showAppSheet(
                          context,
                          ManualActivitySheet(session: s),
                        ),
                  icon: const Icon(Icons.bluetooth),
                  label: Text(context.l10n.manualRecordTitle),
                ),
              ),
            heading(context.l10n.workoutStructure),
            if (profile.isNotEmpty) ...[
              WorkoutProfileBar(blocks: profile),
              if (stepsDiffer)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    context.l10n.theStepsAddUpTo(
                      formatBlockDuration(totals.total),
                      s.plannedDurationMin,
                    ),
                    style: TextStyle(fontSize: 11, color: muted),
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
                    ? context.l10n.noWorkoutStructureAvailable
                    : [s.warmUp, s.coolDown]
                          .whereType<String>()
                          .where((s) => s.isNotEmpty)
                          .join('\n'),
                style: TextStyle(fontSize: 13, color: fjInk70),
              ),
            WorkoutStructureList(steps: steps),
            heading(context.l10n.targets),
            if (fromSteps == null)
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  context.l10n.typicalSplitForThisKind,
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ),
            SectionCard(
              color: duo(0xFF282828, 0xFFEEF1F5),
              child: Column(
                children: [
                  for (var i = 0; i < 5; i++)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              'Z${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: fjInk70,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 84,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  [
                                    context.l10n.zoneRecovery,
                                    context.l10n.aerobic,
                                    context.l10n.tempo,
                                    context.l10n.threshold,
                                    'VO2max',
                                  ][i],
                                  style: TextStyle(fontSize: 10, color: muted),
                                ),
                                for (final part in zoneTargetText(
                                  i + 1,
                                  hrFloors: zoneBounds,
                                  ftp: ftp,
                                ).split(' · ').skip(1))
                                  Text(
                                    part,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: fjInk38,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: fractions[i],
                              color: colors[i],
                              backgroundColor: fjInk10,
                              borderRadius: BorderRadius.circular(5),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 30,
                            child: Text(
                              context.l10n.round3((fractions[i] * 100).round()),
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 10, color: fjInk70),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (s.adaptationTrigger?.isNotEmpty ?? false) ...[
            heading(context.l10n.adaptation),
            Text(
              s.adaptationTrigger!,
              style: TextStyle(fontSize: 12, color: fjInk70),
            ),
          ],
          const SizedBox(height: 12),
          PlannedNutritionCard(
            editable: editable,
            workout: NutritionWorkout(
              key: 'plan:${s.id}',
              title: s.title,
              sport: s.sport,
              date: s.sessionDate,
              minutes: s.plannedDurationMin.toDouble(),
              zone: s.primaryZone,
              indoor: s.indoor,
            ),
          ),
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
            note: movedOnWatch ? context.l10n.pushAgainToUpdateYour : null,
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
          const SizedBox(height: 16),
          MediaGallery(owner: MediaOwner.session(s)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: style(mint, filled: true),
            onPressed: () => openCoachTab(
              context,
              prompt: context.l10n.howDoIExecuteThis,
              card: CoachContextCard.planned(
                s,
                skipReason: skipReason,
                zoneTarget: (z) =>
                    zoneTargetText(z, hrFloors: zoneBounds, ftp: ftp),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: Text(
              context.l10n.askAiCoach,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (buttonContext) {
              // One button per connected watch platform.
              final targets =
                  ref.watch(workoutTargetsProvider).valueOrNull ??
                  const <WorkoutTarget>[];
              Future<void> share(String? why) async {
                final workout = await ref
                    .read(trainingPlanServiceProvider)
                    .workoutText(s.id);
                if (!context.mounted || !buttonContext.mounted) return;
                final box = buttonContext.findRenderObject() as RenderBox?;
                if (why != null) {
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
                final provider = t.provider;
                // A platform that cannot hold exercises gets the list.
                final strengthShare = strength && !provider.supportsStrength;
                final pushes = t.route == WorkoutRoute.push && !strengthShare;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      style: style(blue, filled: first),
                      onPressed:
                          !editable ||
                              busy ||
                              (s.stepsJson == null && !strength)
                          ? null
                          : () async {
                              setState(() => pushingTo = provider.id);
                              await perform(() async {
                                if (!pushes) return share(null);
                                if (!await ensureWorkoutDeliveryReady(
                                  context,
                                  provider,
                                )) {
                                  return;
                                }
                                if (!context.mounted) return;
                                final result = await ref.read(
                                  pushWorkoutProvider,
                                )(s.id, provider);
                                if (!result.sent) {
                                  return share(
                                    '${result.shareReason} Shared as text.',
                                  );
                                }
                                final omitted = strength
                                    ? await ref
                                          .read(trainingPlanServiceProvider)
                                          .strengthUploadOmissions(s.id)
                                    : const <String>[];
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        omitted.isEmpty
                                            ? context.l10n.workoutSentToLabel(
                                                provider.label,
                                              )
                                            : context.l10n
                                                  .workoutSentKeptInFjelia(
                                                    provider.label,
                                                    omitted.join(', '),
                                                  ),
                                      ),
                                    ),
                                  );
                                }
                              });
                              if (mounted) setState(() => pushingTo = null);
                            },
                      icon: Icon(
                        pushes ? Icons.watch_outlined : Icons.ios_share,
                        size: 20,
                      ),
                      label: Text(
                        busy && pushingTo == provider.id
                            ? context.l10n.updating2
                            : pushes
                            ? context.l10n.pushToLabel(provider.label)
                            : strengthShare
                            ? context.l10n.shareExerciseListForLabel(
                                provider.label,
                              )
                            : context.l10n.shareWorkoutForLabel(provider.label),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!pushes)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          strengthShare
                              ? '${provider.label} does not take strength exercises from Fjelia. Share the list and enter it in the ${provider.label} app.'
                              : provider.shareNote,
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ),
                    if (!pushes && !strengthShare && provider.optIn != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          style: style(mint),
                          icon: const Icon(Icons.science_outlined, size: 20),
                          onPressed: () async {
                            final optIn = provider.optIn!;
                            if (!await confirmAction(
                              context,
                              optIn.title,
                              optIn.message,
                            )) {
                              return;
                            }
                            if (!context.mounted) return;
                            await runUiAction(context, optIn.enable);
                          },
                          label: Text(
                            provider.optIn!.buttonLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (pushes && strength)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          context.l10n.labelGetsEachExerciseWith(
                            provider.label,
                          ),
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ),
                    if (pushes && provider.pushNote != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          provider.pushNote!,
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: style(Colors.grey),
                  onPressed: !editable || busy
                      ? null
                      : () async {
                          final onPlatforms = [
                            for (final p
                                in await ref
                                    .read(workoutProvidersProvider)
                                    .deliveredTo(s))
                              p.label,
                          ];
                          if (!context.mounted) return;
                          final reason = await _pickSkipReason(
                            context,
                            platforms: onPlatforms,
                          );
                          if (reason == null || !context.mounted) return;
                          await perform(() async {
                            await actions.markRest(s, reason: reason);
                          });
                        },
                  icon: const Icon(Icons.bed_outlined, size: 20),
                  label: Text(
                    context.l10n.markAsRest,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (_supportsSportChange(s.sport)) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: style(mint),
                    onPressed: !editable || busy
                        ? null
                        : () async {
                            final onPlatforms = [
                              for (final p
                                  in await ref
                                      .read(workoutProvidersProvider)
                                      .deliveredTo(s))
                                p.label,
                            ];
                            if (!context.mounted) return;
                            final preferences =
                                ref
                                    .read(userProfileProvider)
                                    .valueOrNull
                                    ?.preferredSports ??
                                const <String>[];
                            final alternatives = _replacementSports(
                              s.sport,
                              preferences,
                            );
                            final sport = await _pickReplacementSport(
                              context,
                              alternatives: alternatives,
                              initialSport: _defaultReplacementSport(
                                preferences,
                                alternatives,
                              ),
                              platforms: onPlatforms,
                            );
                            if (sport == null || !context.mounted) return;
                            final selected = alternatives.firstWhere(
                              (option) => option.id == sport,
                            );
                            final preview = await ref
                                .read(workoutReplacementServiceProvider)
                                .preview(
                                  s,
                                  targetSport: selected.id,
                                  targetLabel: selected.label(context),
                                );
                            if (!context.mounted) return;
                            final apply = await _confirmReplacement(
                              context,
                              preview,
                              platforms: onPlatforms,
                            );
                            if (!context.mounted || apply == null) return;
                            if (apply == false) {
                              await perform(() async {
                                await actions.markRest(
                                  s,
                                  reason: 'Rest recommended for replacement',
                                );
                              });
                              return;
                            }
                            await perform(() async {
                              await actions.replaceWithSport(
                                preview,
                                reason: 'My choice',
                              );
                            });
                          },
                    icon: const Icon(Icons.swap_horiz, size: 20),
                    label: Text(
                      context.l10n.changeSport,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
              label: Text(
                context.l10n.restoreWorkout,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<bool?> _confirmReplacement(
  BuildContext context,
  WorkoutReplacementPreview preview, {
  required List<String> platforms,
}) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(context.l10n.replacementPreviewTitle),
    content: SingleChildScrollView(
      child: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionCard(
              title: preview.targetLabel,
              accent: planGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FigureLabel(context.l10n.duration),
                            const SizedBox(height: 3),
                            KeyFigure.hero(
                              '${preview.durationMin}',
                              unit: 'min',
                              color: fjAccent(planGradient.last),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 48, color: fjInk12),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FigureLabel(context.l10n.trainingLoad),
                            const SizedBox(height: 3),
                            KeyFigure(
                              '${preview.targetLoad}',
                              unit: 'TRIMP',
                              color: fjInk,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FigureLabel(context.l10n.replacementTrainingGoal),
                  const SizedBox(height: 4),
                  Text(
                    _objectiveLabel(context, preview.objective),
                    style: TextStyle(
                      color: fjInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: fjInk70),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          preview.usedAthleteHistory
                              ? context.l10n.replacementHistoryEstimate
                              : context.l10n.replacementFallbackEstimate,
                          style: TextStyle(fontSize: 12, color: fjInk70),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (preview.warnings.isNotEmpty || preview.suggestRest)
              SectionCard(
                title: context.l10n.replacementPreviewWarnings,
                accent: const [Color(0xFFFFB13D), Color(0xFFFF4D8D)],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final warning in preview.warnings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 17,
                              color: fjAccent(const Color(0xFFFFB13D)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _replacementWarning(context, warning),
                                style: TextStyle(fontSize: 13, color: fjInk),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (preview.suggestRest)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.bed_outlined, size: 17, color: fjInk70),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.replacementRestSuggestion,
                              style: TextStyle(
                                fontSize: 13,
                                color: fjInk,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            if (platforms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: Text(
                  context.l10n.replacementCalendarNote(platforms.join(', ')),
                  style: TextStyle(fontSize: 12, color: fjInk70),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      if (preview.suggestRest)
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.markAsRest),
        ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text(context.l10n.applySportChange),
      ),
    ],
  ),
);

String _objectiveLabel(BuildContext context, WorkoutObjective objective) =>
    switch (objective) {
      WorkoutObjective.recovery => context.l10n.replacementObjectiveRecovery,
      WorkoutObjective.base => context.l10n.replacementObjectiveBase,
      WorkoutObjective.tempo => context.l10n.replacementObjectiveTempo,
      WorkoutObjective.threshold => context.l10n.replacementObjectiveThreshold,
      WorkoutObjective.vo2max => context.l10n.replacementObjectiveVo2,
      WorkoutObjective.longEndurance => context.l10n.replacementObjectiveLong,
    };

String _replacementWarning(BuildContext context, String code) => switch (code) {
  'noHistory' => context.l10n.replacementWarningNoHistory,
  'runningCap' => context.l10n.replacementWarningRunningCap,
  'longRun' => context.l10n.replacementWarningLong,
  'raceSpecific' => context.l10n.replacementWarningRace,
  'swimTechnique' => context.l10n.replacementWarningSwim,
  'strengthMismatch' => context.l10n.replacementWarningStrength,
  'nearbyHard' => context.l10n.replacementWarningNearby,
  'largeWeeklyShare' => context.l10n.replacementWarningWeekly,
  'lowRecovery' => context.l10n.replacementWarningLowRecovery,
  'highRecentVolume' => context.l10n.replacementWarningRecentVolume,
  _ => code,
};

/// Asks why a session is skipped; null when cancelled.
Future<String?> _pickSkipReason(
  BuildContext context, {
  required List<String> platforms,
}) => showDialog<String>(
  context: context,
  builder: (context) => SimpleDialog(
    title: Text(context.l10n.skipThisWorkout),
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        child: Text(
          platforms.isEmpty
              ? context.l10n.whyNothingIsAddedTo
              : 'Why? It is also taken off your ${platforms.join(' and ')} '
                    'calendar. Nothing is added to make it up.',
          style: TextStyle(fontSize: 13, color: fjInk70),
        ),
      ),
      for (final reason in skipReasons)
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, reason),
          child: Text(reason),
        ),
      SimpleDialogOption(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel, style: TextStyle(color: fjInk54)),
      ),
    ],
  ),
);

class _ReplacementSport {
  const _ReplacementSport(this.id, this.label);
  final String id;
  final String Function(BuildContext) label;
}

List<_ReplacementSport> _replacementSports(
  String sourceSport,
  List<String> preferences,
) {
  const supported = <String, _ReplacementSport>{
    'running': _ReplacementSport('running', _runningLabel),
    'trail_running': _ReplacementSport('trail_running', _trailRunningLabel),
    'cycling_road': _ReplacementSport('cycling_road', _cyclingLabel),
    'indoor_cycling': _ReplacementSport('indoor_cycling', _indoorCyclingLabel),
    'swimming': _ReplacementSport('swimming', _swimmingLabel),
    'indoor_rowing': _ReplacementSport('indoor_rowing', _rowingLabel),
    'rowing': _ReplacementSport('rowing', _rowingLabel),
    'hiking': _ReplacementSport('hiking', _hikingLabel),
    'walking': _ReplacementSport('walking', _walkingLabel),
    'elliptical': _ReplacementSport('elliptical', _ellipticalLabel),
    'nordic_skiing': _ReplacementSport('nordic_skiing', _skiingLabel),
    'skate_skiing': _ReplacementSport('skate_skiing', _skateSkiingLabel),
  };
  final source = _sportFamily(sourceSport);
  if (!_replaceableSportFamilies.contains(source)) return const [];
  final preferenceOrder = <String>[];
  for (final preference in preferences) {
    switch (preference) {
      case 'triathlon':
        preferenceOrder.addAll(const ['running', 'cycling_road', 'swimming']);
      case 'running':
      case 'trail_running':
        preferenceOrder.add(preference);
      case 'cycling':
      case 'cycling_road':
        preferenceOrder.add('cycling_road');
      case 'indoor_cycling':
        preferenceOrder.add('indoor_cycling');
      case 'swimming':
      case 'indoor_rowing':
      case 'hiking':
        preferenceOrder.add(preference);
      case 'nordic_skiing':
      case 'skate_skiing':
      case 'elliptical':
      case 'rowing':
        preferenceOrder.add(preference);
    }
  }
  final defaults = switch (source) {
    'run' =>
      sourceSport == 'trail_running'
          ? const [
              'running',
              'cycling_road',
              'indoor_cycling',
              'elliptical',
              'indoor_rowing',
              'hiking',
            ]
          : const [
              'trail_running',
              'cycling_road',
              'indoor_cycling',
              'elliptical',
              'indoor_rowing',
              'swimming',
              'hiking',
              'nordic_skiing',
            ],
    'cycle' =>
      sourceSport == 'cycling_road'
          ? const [
              'indoor_cycling',
              'running',
              'elliptical',
              'indoor_rowing',
              'swimming',
            ]
          : const [
              'cycling_road',
              'running',
              'elliptical',
              'indoor_rowing',
              'swimming',
            ],
    'swim' => const ['cycling_road', 'running', 'indoor_rowing'],
    'row' => const [
      'rowing',
      'indoor_rowing',
      'nordic_skiing',
      'cycling_road',
      'running',
    ],
    'hike' => const ['walking', 'trail_running', 'running', 'nordic_skiing'],
    'ski' => const [
      'nordic_skiing',
      'skate_skiing',
      'indoor_rowing',
      'cycling_road',
      'running',
    ],
    'elliptical' => const ['running', 'cycling_road', 'indoor_rowing'],
    _ => const ['running', 'cycling_road', 'indoor_rowing', 'swimming'],
  };
  final ordered = <String>{...preferenceOrder, ...defaults};
  return [
    for (final id in ordered)
      if (supported.containsKey(id) && id != sourceSport) supported[id]!,
  ];
}

const _replaceableSportFamilies = {
  'run',
  'cycle',
  'swim',
  'row',
  'hike',
  'ski',
  'elliptical',
};

bool _supportsSportChange(String sport) =>
    _replaceableSportFamilies.contains(_sportFamily(sport));

String _sportFamily(String sport) {
  final value = sport.toLowerCase();
  if (value.contains('run')) return 'run';
  if (value.contains('cycl') || value.contains('bik')) return 'cycle';
  if (value.contains('swim')) return 'swim';
  if (value.contains('row')) return 'row';
  if (value.contains('ski')) return 'ski';
  if (value.contains('ellipt')) return 'elliptical';
  if (value.contains('hik') || value.contains('walk')) return 'hike';
  return value;
}

String? _defaultReplacementSport(
  List<String> preferences,
  List<_ReplacementSport> alternatives,
) {
  final byId = {for (final sport in alternatives) sport.id: sport.id};
  for (final preference in preferences) {
    final candidates = preference == 'triathlon'
        ? const ['running', 'cycling_road', 'swimming']
        : [preference == 'cycling' ? 'cycling_road' : preference];
    for (final candidate in candidates) {
      if (byId.containsKey(candidate)) return candidate;
    }
  }
  return alternatives.firstOrNull?.id;
}

String _runningLabel(BuildContext c) => c.l10n.running;
String _trailRunningLabel(BuildContext c) => c.l10n.trailRunning;
String _cyclingLabel(BuildContext c) => c.l10n.cycling;
String _swimmingLabel(BuildContext c) => c.l10n.swimming;
String _rowingLabel(BuildContext c) => c.l10n.indoorRowing;
String _hikingLabel(BuildContext c) => c.l10n.hiking;
String _walkingLabel(BuildContext c) => c.l10n.walking;
String _indoorCyclingLabel(BuildContext c) => c.l10n.sportIndoorCycling;
String _ellipticalLabel(BuildContext c) => c.l10n.sportElliptical;
String _skiingLabel(BuildContext c) => c.l10n.skiing;
String _skateSkiingLabel(BuildContext c) => c.l10n.skateSkiing;

Future<String?> _pickReplacementSport(
  BuildContext context, {
  required List<_ReplacementSport> alternatives,
  required String? initialSport,
  required List<String> platforms,
}) => showDialog<String>(
  context: context,
  builder: (context) => _ReplacementSportDialog(
    alternatives: alternatives,
    initialSport: initialSport,
    platforms: platforms,
  ),
);

class _ReplacementSportDialog extends StatefulWidget {
  const _ReplacementSportDialog({
    required this.alternatives,
    required this.initialSport,
    required this.platforms,
  });
  final List<_ReplacementSport> alternatives;
  final String? initialSport;
  final List<String> platforms;

  @override
  State<_ReplacementSportDialog> createState() =>
      _ReplacementSportDialogState();
}

class _ReplacementSportDialogState extends State<_ReplacementSportDialog> {
  late String? sport = widget.initialSport;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.changeSport),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: sport,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.l10n.replacementSport),
          items: [
            for (final option in widget.alternatives)
              DropdownMenuItem(
                value: option.id,
                child: Text(option.label(context)),
              ),
          ],
          onChanged: (value) => setState(() => sport = value),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.replacementLoadNote,
          style: TextStyle(fontSize: 12, color: fjInk70),
        ),
        if (widget.platforms.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            context.l10n.replacementCalendarNote(widget.platforms.join(', ')),
            style: TextStyle(fontSize: 12, color: fjInk70),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: sport == null ? null : () => Navigator.pop(context, sport),
        child: Text(context.l10n.applySportChange),
      ),
    ],
  );
}

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
    return '${tr.paceGuideRange(formatPace(low.toDouble()), formatPace(high.toDouble()))}'
        '${pace['basis'] == 'goal' ? tr.paceGuideFromGoal : ''}'
        '${goal is num ? tr.paceGuideGoalFlat(formatPace(goal.toDouble())) : ''}. '
        '${tr.paceGuideHeartRateDecides}';
  } catch (_) {
    return null;
  }
}
