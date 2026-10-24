import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../db/database.dart';
import '../../models/planned_workout_presentation.dart';
import '../../providers/planner_providers.dart';
import '../../providers/day_data_provider.dart';
import '../../services/plan_session_actions.dart';
import '../../widgets/app_widgets.dart';
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
    final steps = plannedStepLines(s.stepsJson);
    final fractions = plannedZoneFractions(s.plannedZonesJson, s.primaryZone);
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
          Row(
            children: [
              for (final e in [
                ('${s.plannedDurationMin} min', 'DURATION'),
                ('${s.plannedTrimp}', 'TRIMP'),
                ('Z${s.primaryZone}', 'PRIMARY ZONE'),
                ('${s.weekNumber}', 'WEEK'),
              ])
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        FittedBox(
                          child: Text(
                            e.$1,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        FittedBox(
                          child: Text(
                            e.$2,
                            style: const TextStyle(fontSize: 8, color: muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
          for (final step in steps)
            Padding(
              padding: EdgeInsets.only(left: step.depth * 12, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 15,
                    margin: const EdgeInsets.only(top: 2, right: 9),
                    decoration: BoxDecoration(
                      color: step.repeat
                          ? Colors.white12
                          : step.label == 'Interval'
                          ? mint
                          : step.label == 'Recovery'
                          ? blue
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: step.amount,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (step.label.isNotEmpty)
                            TextSpan(
                              text: '  ${step.label}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          if (step.zone != null)
                            TextSpan(
                              text: ' Z${step.zone}',
                              style: const TextStyle(color: muted),
                            ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          heading('TARGETS'),
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
                          width: 71,
                          child: Text(
                            const [
                              'Recovery',
                              'Aerobic',
                              'Tempo',
                              'Threshold',
                              'VO2max',
                            ][i],
                            style: const TextStyle(fontSize: 10, color: muted),
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
            onPressed: () => showCoachSheet(
              context,
              title: 'Workout Coach',
              prompt: [
                'Help me prepare for this planned workout: its purpose, how to pace it, and whether I should adjust it based on my current recovery and training load.',
                '',
                'Workout: ${s.title}',
                'Date: ${DateFormat('EEEE, yyyy-MM-dd').format(s.sessionDate)}',
                'Sport: ${s.sport.replaceAll('_', ' ')}',
                'Type: ${s.sessionType} (${s.phase} phase, week ${s.weekNumber})',
                'Planned: ${s.plannedDurationMin} min, TRIMP ${s.plannedTrimp}, primary zone Z${s.primaryZone}',
                if (steps.isNotEmpty) 'Structure:',
                for (final l in steps)
                  '${'  ' * l.depth}- ${l.amount} ${l.label}${l.zone == null ? '' : ' (Z${l.zone})'}',
              ].join('\n'),
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
