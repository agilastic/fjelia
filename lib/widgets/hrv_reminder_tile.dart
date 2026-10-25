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
          title: const Text(
            'Remind me to measure HRV after training',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            style: const TextStyle(color: muted, fontSize: 12, height: 1.35),
            !status.sensorReady
                ? 'Pair a Polar H10 first.'
                : 'Around 30 minutes after training, when the workout is available in time.',
          ),
          value: status.enabled,
          onChanged: status.sensorReady || status.enabled
              ? (on) async {
                  final permission = await actions.setEnabled(on);
                  if (on && !permission.allowed) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Notifications are off. You can still measure from your workout.',
                        ),
                      ),
                    );
                  }
                }
              : null,
        ),
        if (status.blocked)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Notifications are off. You can still measure from your workout.',
              style: TextStyle(color: hrvNoticeColor, fontSize: 12),
            ),
          ),
        if (status.enabled)
          SwitchListTile(
            // Lines up with the text of the main switch above.
            secondary: const SizedBox(width: 40),
            title: const Text(
              'No reminders from 22:00 to 07:00',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: const Text(
              'A reminder that would fall in this time is skipped, not moved to the morning.',
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
                      ? 'Hide reminder diagnostics'
                      : 'Reminder diagnostics',
                ),
              ),
            ),
          ),
        if (status.enabled && diagnostics)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              ref.watch(hrvDiagnosticsProvider).valueOrNull?.lines.join('\n') ??
                  'Loading…',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: muted,
              ),
            ),
          ),
        if (status.enabled &&
            status.permission == NotificationPermission.provisional)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Reminders arrive quietly in the notification list.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
