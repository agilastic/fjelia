import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../db/database.dart';
import '../../models/coach_context_card.dart';
import '../../models/planned_workout_presentation.dart';
import '../../models/workout_profile.dart';
import '../../providers/ftp_provider.dart';
import '../../providers/hr_zones_provider.dart';
import '../../providers/planner_providers.dart';
import '../../providers/day_data_provider.dart';
import '../../services/plan_session_actions.dart';
import '../../widgets/app_widgets.dart';
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
  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    await runUiAction(context, () async {
      await action();
      final fresh = await ref.refresh(
        plannedSessionProvider(session.id).future,
      );
      if (fresh != null && mounted) setState(() => session = fresh);
      ref.invalidate(upcomingSessionsProvider);
      ref.invalidate(scheduledWorkoutsProvider);
    });
    if (mounted) setState(() => busy = false);
  }

  PlanSessionActions get actions => ref.read(planSessionActionsProvider);
  @override
  Widget build(BuildContext context) {
    final s = session;
    final sport = s.sport.toLowerCase();
    final zones = ref.watch(hrZonesProvider);
    final zoneBounds =
        (sport.contains('cycl') || sport.contains('bik')
                ? zones.cycling
                : zones.running)
            .bounds;
    // Ranges are worked out from today's zones and FTP, not from what was
    // stored when the plan was made; both change over time.
    final ftp = sport.contains('cycl') || sport.contains('bik')
        ? ref.watch(ftpProvider).valueOrNull?.ftpWatts
        : null;
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
              badge(s.status == 'skipped' ? 'REST' : s.status.toUpperCase()),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: style(Colors.white70),
                  onPressed: !editable || busy
                      ? null
                      : () => perform(() async {
                          await actions.moveDay(s, -1);
                        }),
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: const Text(
                    'Previous day',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: style(Colors.white70),
                  onPressed: !editable || busy
                      ? null
                      : () => perform(() async {
                          await actions.moveDay(s, 1);
                        }),
                  icon: const Icon(Icons.chevron_right, size: 18),
                  iconAlignment: IconAlignment.end,
                  label: const Text('Next day', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            style: style(mint, filled: true),
            onPressed: () => openCoachTab(
              context,
              prompt: 'How do I execute this workout?',
              card: CoachContextCard.planned(
                s,
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
          OutlinedButton.icon(
            style: style(blue, filled: true),
            onPressed: !editable || busy || s.stepsJson == null
                ? null
                : () => perform(() async {
                    await ref
                        .read(trainingPlanServiceProvider)
                        .pushToGarmin(s.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Workout pushed to Garmin'),
                        ),
                      );
                    }
                  }),
            icon: const Icon(Icons.watch_outlined, size: 20),
            label: Text(
              busy ? 'Updating…' : 'Push to Garmin',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: style(Colors.grey),
            onPressed: !editable || busy
                ? null
                : () async {
                    if (!await confirmAction(
                      context,
                      'Mark as rest?',
                      'Skip this planned workout${s.garminAlternativeId == null ? '' : ' and remove its Garmin calendar entry'}?',
                    )) {
                      return;
                    }
                    if (mounted) {
                      await perform(() async {
                        await actions.markRest(s);
                      });
                    }
                  },
            icon: const Icon(Icons.bed_outlined, size: 20),
            label: const Text(
              'Mark as Rest',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
