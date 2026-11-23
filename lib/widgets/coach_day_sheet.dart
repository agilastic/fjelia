import '../theme/fjelia_style.dart';
import '../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../db/database.dart' show CoachMessage;
import '../l10n/app_localizations.dart';
import '../providers/coach_messages_provider.dart';
import '../services/briefing_text.dart';
import 'app_widgets.dart';

const coachDayAccent = [Color(0xFF9D7BFF), Color(0xFF3EE0FF)];

/// The heading of a kept coach message: its briefing's name.
String coachMessageTitle(AppLocalizations l, CoachMessage m) =>
    switch (m.period) {
      'morning' => l.morningBriefing,
      'lunch' => l.lunchBriefing,
      'afternoon' => l.afternoonBriefing,
      'evening' => l.eveningBriefing,
      _ => l.coachMessage,
    };

/// Everything the coach said on [day], in the order it was written: each
/// briefing and every rewrite of it during the day, with its time and who
/// wrote it.
class CoachDaySheet extends ConsumerWidget {
  const CoachDaySheet({super.key, required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final messages = ref.watch(coachMessagesProvider(day));
    return SheetPage(
      title: l.coachDayTitle(DateFormat.MMMMEEEEd().format(day)),
      child: messages.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            DataError(e, retry: () => ref.invalidate(coachMessagesProvider)),
        data: (list) => list.isEmpty
            ? EmptyState(l.coachDayEmpty)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  for (final m in list.reversed) ...[
                    SectionCard(
                      accent: coachDayAccent,
                      title:
                          '${coachMessageTitle(l, m)} · '
                          '${DateFormat.Hm().format(m.createdAt)}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            flattenBriefing(m.body),
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                          if (m.source != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                m.source!,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    l.coachDayKept,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: fjInk54),
                  ),
                ],
              ),
      ),
    );
  }
}
