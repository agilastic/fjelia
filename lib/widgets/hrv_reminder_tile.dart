import '../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/hrv_reminder_provider.dart';
import '../services/notifications/local_notification_gateway.dart';
import '../theme/hrv_colors.dart';
import 'app_widgets.dart';

/// The optional post-training HRV reminder. Off until the athlete turns it
/// on; the system permission is asked for only then.
class HrvReminderTile extends ConsumerStatefulWidget {
  const HrvReminderTile({super.key});

  @override
  ConsumerState<HrvReminderTile> createState() => _HrvReminderTileState();
}

class _HrvReminderTileState extends ConsumerState<HrvReminderTile> {
  bool diagnostics = false;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(hrvReminderStatusProvider).valueOrNull;
    if (status == null) return const SizedBox.shrink();
    final actions = ref.read(hrvReminderActionsProvider);
    final messenger = ScaffoldMessenger.of(context);
    return Column(
      children: [
        SwitchListTile(
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hrvAfterColor.withValues(alpha: .14),
            ),
            child: Icon(
              status.enabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: hrvAfterColor,
              size: 20,
            ),
          ),
          title: Text(
            context.l10n.remindMeToMeasureHrv,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            style: const TextStyle(color: muted, fontSize: 12, height: 1.35),
            !status.sensorReady
                ? context.l10n.pairAPolarH10First
                : context.l10n.around30MinutesAfterTraining,
          ),
          value: status.enabled,
          onChanged: status.sensorReady || status.enabled
              ? (on) async {
                  final permission = await actions.setEnabled(on);
                  if (on && !permission.allowed) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(tr.notificationsAreOffYouCan)),
                    );
                  }
                }
              : null,
        ),
        if (status.blocked)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              context.l10n.notificationsAreOffYouCan,
              style: TextStyle(color: hrvNoticeColor, fontSize: 12),
            ),
          ),
        if (status.enabled)
          SwitchListTile(
            // Lines up with the text of the main switch above.
            secondary: const SizedBox(width: 40),
            title: Text(
              context.l10n.noRemindersFrom2200,
              style: TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              context.l10n.aReminderThatWouldFall,
              style: TextStyle(color: muted, fontSize: 12, height: 1.35),
            ),
            value: status.prefs.quietEnabled,
            onChanged: (on) => actions.setQuietHours(
              enabled: on,
              startMinute: 22 * 60,
              endMinute: 7 * 60,
              postpone: false,
            ),
          ),
        if (status.enabled)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(
                onPressed: () => setState(() => diagnostics = !diagnostics),
                child: Text(
                  diagnostics
                      ? context.l10n.hideReminderDiagnostics
                      : context.l10n.reminderDiagnostics,
                ),
              ),
            ),
          ),
        if (status.enabled && diagnostics)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              ref.watch(hrvDiagnosticsProvider).valueOrNull?.lines.join('\n') ??
                  context.l10n.loading,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: muted,
              ),
            ),
          ),
        if (status.enabled &&
            status.permission == NotificationPermission.provisional)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              context.l10n.remindersArriveQuietlyInThe,
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
