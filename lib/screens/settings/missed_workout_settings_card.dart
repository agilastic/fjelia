import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/hrv_reminder_provider.dart';
import '../../providers/missed_workout_provider.dart';
import '../../services/missed_workout_reminder_service.dart';
import '../../services/notifications/local_notification_gateway.dart';
import '../../widgets/app_widgets.dart';
import 'training_tab.dart' show SettingsSegments;

/// The evening reminder for a planned workout that is still open: on or off,
/// at what time, and how many days ahead a missed session may move.
class MissedWorkoutSettingsCard extends ConsumerWidget {
  const MissedWorkoutSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s =
        ref.watch(missedWorkoutSettingsProvider).valueOrNull ??
        const MissedWorkoutSettings();
    final permission = ref.watch(notificationPermissionProvider).valueOrNull;
    void save(MissedWorkoutSettings next) => runUiAction(
      context,
      () => ref.read(missedWorkoutSettingsProvider.notifier).save(next),
    );
    return SectionCard(
      color: const Color(0xFF282828),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.orange,
            ),
            title: Text(
              l10n.missedWorkoutReminder,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.missedWorkoutReminderSubtitle,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            activeThumbColor: Colors.orange,
            activeTrackColor: Colors.orangeAccent.withValues(alpha: .4),
            value: s.enabled,
            onChanged: (v) => save(s.copyWith(enabled: v)),
          ),
          if (s.enabled) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(l10n.time),
              trailing: Text(
                TimeOfDay(hour: s.hour, minute: s.minute).format(context),
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: s.hour, minute: s.minute),
                );
                if (picked == null) return;
                save(s.copyWith(minutes: picked.hour * 60 + picked.minute));
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                l10n.moveWithinDays,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
            SettingsSegments(
              values: {
                for (final d in [3, 4, 5]) '$d': l10n.daysN(d),
              },
              selected: '${s.daysAhead}',
              color: Colors.orange,
              onSelect: (v) => save(s.copyWith(daysAhead: int.parse(v))),
            ),
            if (permission != null && !permission.allowed) ...[
              const SizedBox(height: 12),
              Text(
                l10n.notificationsAreOff,
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
              if (permission == NotificationPermission.notDetermined)
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(localNotificationGatewayProvider)
                        .requestPermission();
                    ref.invalidate(notificationPermissionProvider);
                    await ref.read(missedWorkoutReminderProvider).reconcile();
                  },
                  child: Text(l10n.allowNotifications),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
