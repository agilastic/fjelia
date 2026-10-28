import '../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/coach_context_card.dart';
import 'app_widgets.dart';

IconData _sportIcon(String sport) {
  final t = sport.toLowerCase();
  if (t.contains('run')) return Icons.directions_run;
  if (t.contains('cycl') || t.contains('bik') || t.contains('ride')) {
    return Icons.directions_bike;
  }
  if (t.contains('swim')) return Icons.pool;
  if (t.contains('walk') || t.contains('hik')) return Icons.hiking;
  if (t.contains('yoga') || t.contains('mobil')) return Icons.self_improvement;
  return Icons.fitness_center;
}

Color _statusColor(CoachCardStatus status) => switch (status) {
  CoachCardStatus.planned => const Color(0xFF4FC3F7),
  CoachCardStatus.adapted => const Color(0xFFFFA94D),
  CoachCardStatus.completed => mint,
  CoachCardStatus.skipped => const Color(0xFF9E9E9E),
};

/// The session a coach chat is about, as a card at the top of the chat.
class CoachContextCardView extends StatelessWidget {
  const CoachContextCardView({super.key, required this.card});

  final CoachContextCard card;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(card.status);
    return Semantics(
      container: true,
      label: context.l10n.titleDateLabel(
        card.title,
        DateFormat.MMMMd().format(card.date),
        card.status.label,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_sportIcon(card.sport), color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        DateFormat.yMMMEd().format(card.date),
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          card.status.label,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (card.facts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      card.facts.join(' · '),
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
