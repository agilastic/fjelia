import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/formats.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/plan_proposal_provider.dart';
import '../../providers/plan_week_provider.dart' show PlanWeekItem;
import '../../providers/fjelia_edition_provider.dart';
import '../../providers/readiness_provider.dart';
import 'coach_revision_view.dart';
import '../../providers/sync_provider.dart';
import '../../services/missed_workout_reminder_service.dart'
    show MissedWorkoutActionKind;
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';
import 'missed_workout_sheet.dart';

const _missedAccent = [Color(0xFF9D7BFF), Color(0xFF3EE0FF)];

/// Sessions missed in the last two days, waiting for an answer on top of
/// the Plan. Today's readiness proposal has no card: it comes as one push
/// in the morning and opens [ReadinessProposalSheet].
class PlanProposalCards extends ConsumerWidget {
  const PlanProposalCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missed = ref.watch(pastMissedProvider).valueOrNull ?? const [];
    if (missed.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in missed) _MissedCard(day: m.day, items: m.items),
      ],
    );
  }
}

/// Opened from the proposal notification.
class ReadinessProposalSheet extends ConsumerWidget {
  const ReadinessProposalSheet({super.key, required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposal = ref.watch(morningAdaptationProvider).proposal;
    final coachState = ref.watch(coachRevisionProvider(day));
    final coach = coachState.valueOrNull;
    final busy =
        ref.watch(syncProvider).status == SyncStatus.syncing ||
        ref.watch(morningAdaptationProvider).running ||
        coachState.isLoading;
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    return SheetPage(
      title: isToday
          ? context.l10n.proposalCardTitle
          : context.l10n.proposalForDay(dayName(context, day, now)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (proposal != null && proposal.day == day && coach != null)
            CoachRevisionView(
              revision: coach.revision,
              context: coach.context,
              onDone: () => Navigator.of(context).pop(),
            )
          else if (proposal != null && proposal.day == day && !busy)
            RulesProposalView(
              proposal: proposal,
              coachUnavailable:
                  ref.watch(fjeliaEditionProvider).isPro &&
                  (ref.watch(proposalProCoachProvider).valueOrNull ?? true),
              onDone: () => Navigator.of(context).pop(),
            )
          else if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator(color: mint)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                context.l10n.proposalAnswered,
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _MissedCard extends ConsumerWidget {
  const _MissedCard({required this.day, required this.items});
  final DateTime day;
  final List<PlanWeekItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final yesterday =
        DateTime(now.year, now.month, now.day - 1) ==
        DateTime(day.year, day.month, day.day);
    return _ProposalCard(
      accent: _missedAccent,
      icon: Icons.event_busy_rounded,
      label: yesterday
          ? l10n.missedYesterdayTitle
          : l10n.missedOnDayTitle(DateFormat.EEEE().format(day)),
      title: [
        for (final i in items)
          i.plannedMinutes == null
              ? i.plannedTitle
              : '${i.plannedTitle} (${planDuration(i.plannedMinutes!)})',
      ].join(', '),
      primary: l10n.replanMissed,
      secondary: l10n.leaveIt,
      onPrimary: () => showAppSheet(
        context,
        MissedWorkoutSheet(day: day, intent: MissedWorkoutActionKind.move),
      ),
      onSecondary: () => runUiAction(
        context,
        () => ref.read(planProposalLifecycleProvider).leaveMissed(day),
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.accent,
    required this.icon,
    required this.label,
    required this.title,
    required this.primary,
    required this.secondary,
    required this.onPrimary,
    required this.onSecondary,
  });

  final List<Color> accent;
  final IconData icon;
  final String label, title, primary, secondary;
  final VoidCallback onPrimary, onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        accent: accent,
        title: label,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: fjAccent(accent.first)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: fjInk,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onPrimary,
                    child: Text(primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSecondary,
                    child: Text(secondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
