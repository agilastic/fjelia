import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../theme/fjelia_style.dart';
import 'app_widgets.dart';

/// What the plan is for when there is no race: none, `fun` or `fitness`.
/// Plain text chips (style.md); what each one means is said below them.
class CasualGoalPicker extends StatelessWidget {
  const CasualGoalPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.hasRaceGoal = false,
    this.enabled = true,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  /// A race goal is set: the choice waits until there is none.
  final bool hasRaceGoal;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hint = switch (value) {
      'fun' => l.casualFunHint,
      'fitness' => l.casualFitnessHint,
      _ => l.casualGoalHint,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (key, label) in [
              (null, l.casualNone),
              ('fun', l.casualFun),
              ('fitness', l.casualFitness),
            ])
              ChoiceChip(
                key: ValueKey('casual-goal-${key ?? 'none'}'),
                label: Text(label),
                selected: value == key,
                showCheckmark: false,
                onSelected: enabled ? (_) => onChanged(key) : null,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(hint, style: TextStyle(fontSize: 12, color: fjInk70)),
        if (hasRaceGoal && value != null) ...[
          const SizedBox(height: 4),
          Text(
            l.casualGoalAfterRace,
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ],
    );
  }
}
