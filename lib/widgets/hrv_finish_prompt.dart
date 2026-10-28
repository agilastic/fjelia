import '../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/hrv_reminder_provider.dart';
import '../providers/hrv_training_provider.dart';
import '../theme/hrv_colors.dart';
import 'app_widgets.dart';

/// Offered while a before-training reading waits for its workout and the
/// reminder is on: a workout that is not imported in time can be reported as
/// finished by hand. Never required; the ordinary case needs no tap.
class HrvFinishPrompt extends ConsumerWidget {
  const HrvFinishPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(hrvPendingPreProvider).valueOrNull;
    final status = ref.watch(hrvReminderStatusProvider).valueOrNull;
    if (pending == null || status == null || !status.enabled) {
      return const SizedBox.shrink();
    }
    return SectionCard(
      title: context.l10n.workoutFinished,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hrvBeforeColor.withValues(alpha: .14),
            ),
            child: const Icon(
              Icons.sports_score_rounded,
              color: hrvBeforeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.yourWorkoutIsNotIn,
                  style: TextStyle(color: muted, fontSize: 12, height: 1.35),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => _report(context, ref, pending.endedAt),
                  icon: const Icon(Icons.flag_rounded, size: 18),
                  label: Text(context.l10n.workoutFinished2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _report(
    BuildContext context,
    WidgetRef ref,
    DateTime preEnd,
  ) async {
    final now = DateTime.now();
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(hrvReminderActionsProvider);
    // A planned start is not evidence: the athlete confirms both times.
    final startGuess = preEnd.add(const Duration(minutes: 5));
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(startGuess),
      helpText: context.l10n.whenDidTheWorkoutStart,
    );
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      helpText: context.l10n.whenDidItEnd,
    );
    if (end == null) return;
    // A time later than now belongs to yesterday: a workout over midnight.
    DateTime at(TimeOfDay t) {
      final today = DateTime(now.year, now.month, now.day, t.hour, t.minute);
      return today.isAfter(now.add(const Duration(minutes: 2)))
          ? today.subtract(const Duration(days: 1))
          : today;
    }

    final from = at(start), to = at(end);
    if (!to.isAfter(from) ||
        to.isAfter(now.add(const Duration(minutes: 2))) ||
        from.isBefore(preEnd)) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.theWorkoutMustStartAfter)),
      );
      return;
    }
    await actions.reportFinish(start: from, end: to);
  }
}
