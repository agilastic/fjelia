import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/formats.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/plan_proposal_provider.dart';
import '../../providers/plan_week_provider.dart' show PlanWeekItem;
import '../../providers/readiness_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/missed_workout_reminder_service.dart'
    show MissedWorkoutActionKind;
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';
import 'missed_workout_sheet.dart';

const _readinessAccent = [Color(0xFFFFB13D), Color(0xFFFF4D8D)];
const _missedAccent = [Color(0xFF9D7BFF), Color(0xFF3EE0FF)];

/// What Fjelia would change and waits for an answer: today's readiness
/// proposal and sessions missed in the last two days. Shown on top of the
/// Plan; the same proposals come as notifications when the app is closed.
class PlanProposalCards extends ConsumerWidget {
  const PlanProposalCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposal = ref.watch(morningAdaptationProvider).proposal;
    final missed = ref.watch(pastMissedProvider).valueOrNull ?? const [];
    if (proposal == null && missed.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (proposal != null) _ReadinessCard(proposal: proposal),
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
    final busy =
        ref.watch(syncProvider).status == SyncStatus.syncing ||
        ref.watch(morningAdaptationProvider).running;
    return SheetPage(
      title: context.l10n.proposalCardTitle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (proposal != null && proposal.day == day)
            _ReadinessCard(
              proposal: proposal,
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

class _ReadinessCard extends ConsumerStatefulWidget {
  const _ReadinessCard({required this.proposal, this.onDone});
  final ReadinessProposal proposal;
  final VoidCallback? onDone;

  @override
  ConsumerState<_ReadinessCard> createState() => _ReadinessCardState();
}

class _ReadinessCardState extends ConsumerState<_ReadinessCard> {
  bool _busy = false;

  Future<void> _answer(bool accept) async {
    setState(() => _busy = true);
    await runUiAction(
      context,
      () => ref
          .read(planProposalLifecycleProvider)
          .answerReadiness(accept: accept),
    );
    if (mounted) setState(() => _busy = false);
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final text = readinessProposalText(widget.proposal, context.l10n);
    return _ProposalCard(
      accent: _readinessAccent,
      icon: Icons.battery_charging_full_rounded,
      label: context.l10n.proposalCardTitle,
      title: text.title,
      body: text.body,
      primary: context.l10n.apply,
      secondary: context.l10n.keepPlan,
      busy: _busy,
      onPrimary: () => _answer(true),
      onSecondary: () => _answer(false),
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
    this.body,
    this.busy = false,
  });

  final List<Color> accent;
  final IconData icon;
  final String label, title, primary, secondary;
  final String? body;
  final bool busy;
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
            if (body case final b? when b.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 30),
                child: Text(
                  b,
                  style: TextStyle(color: fjInk70, fontSize: 13, height: 1.35),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(colors: accent),
                    ),
                    child: TextButton(
                      onPressed: busy ? null : onPrimary,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black87,
                      ),
                      child: busy
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black87,
                              ),
                            )
                          : Text(
                              primary,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onSecondary,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: fjInk70,
                      side: fjEdge(accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
