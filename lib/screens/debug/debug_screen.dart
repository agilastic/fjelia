import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/missed_workout_provider.dart';
import '../../services/debug_log.dart';
import '../../services/missed_workout_reminder_service.dart';
import '../../widgets/app_widgets.dart';
import '../planner/missed_workout_sheet.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  /// Tries the evening reminder on the device without waiting for 19:30.
  Future<void> _testReminder(
    BuildContext context,
    WidgetRef ref,
    String choice,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    if (choice == 'push') {
      final day = await ref.read(missedWorkoutReminderProvider).scheduleTest();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Reminder for ${day.day}.${day.month}. in 10 s — '
            'lock the phone or leave the app.',
          ),
        ),
      );
      return;
    }
    final now = DateTime.now();
    await showAppSheet(
      context,
      MissedWorkoutSheet(
        day: DateTime(now.year, now.month, now.day),
        intent: choice == 'skip'
            ? MissedWorkoutActionKind.skip
            : MissedWorkoutActionKind.move,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      Row(
        children: [
          const Expanded(child: SectionLabel('Diagnostics')),
          PopupMenuButton<String>(
            tooltip: 'Test missed-workout reminder',
            icon: const Icon(Icons.notifications_active_outlined, size: 18),
            onSelected: (choice) => _testReminder(context, ref, choice),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'push', child: Text('Reminder in 10 s')),
              PopupMenuItem(value: 'move', child: Text('Open Move sheet')),
              PopupMenuItem(value: 'skip', child: Text('Open Skip sheet')),
            ],
          ),
          IconButton(
            tooltip: 'Copy log',
            onPressed: () => Clipboard.setData(
              ClipboardData(text: DebugLog.lines.join('\n')),
            ),
            icon: const Icon(Icons.copy, size: 18),
          ),
          IconButton(
            tooltip: 'Clear log',
            onPressed: DebugLog.clear,
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
        ],
      ),
      Expanded(
        child: StreamBuilder<List<String>>(
          stream: DebugLog.stream,
          initialData: DebugLog.lines,
          builder: (c, s) => ListView(
            reverse: true,
            padding: const EdgeInsets.all(12),
            children: [
              for (final line in (s.data ?? []).reversed)
                SelectableText(
                  line,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: muted,
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}
