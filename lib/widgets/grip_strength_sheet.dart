import '../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/grip_strength_provider.dart';
import 'app_widgets.dart';
import '../utils/decimal.dart';

class GripStrengthSheet extends ConsumerStatefulWidget {
  const GripStrengthSheet({super.key});
  @override
  ConsumerState<GripStrengthSheet> createState() => _GripState();
}

class _GripState extends ConsumerState<GripStrengthSheet> {
  final left = TextEditingController(), right = TextEditingController();
  bool saving = false;
  @override
  void dispose() {
    left.dispose();
    right.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SheetPage(
    title: context.l10n.gripStrength,
    child: ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: left,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: context.l10n.leftKg),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: right,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: context.l10n.rightKg),
              ),
            ),
          ],
        ),
        FilledButton(
          onPressed: saving
              ? null
              : () async {
                  final l = parseDecimal(left.text),
                      r = parseDecimal(right.text);
                  if ((l == null && r == null) ||
                      (l != null && l <= 0) ||
                      (r != null && r <= 0)) {
                    return;
                  }
                  setState(() => saving = true);
                  await runUiAction(
                    context,
                    () => ref
                        .read(gripStrengthNotifierProvider.notifier)
                        .add(DateTime.now(), l, r),
                  );
                  if (mounted) setState(() => saving = false);
                },
          child: Text(context.l10n.saveMeasurement),
        ),
        ref
            .watch(gripStrengthProvider)
            .when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => DataError(e),
              data: (rows) => Column(
                children: [
                  HistoryChart(
                    points: [
                      for (final r in rows)
                        if (r.leftKg != null)
                          ChartPoint(r.measuredAt, r.leftKg!),
                    ],
                    secondary: [
                      for (final r in rows)
                        if (r.rightKg != null)
                          ChartPoint(r.measuredAt, r.rightKg!),
                    ],
                  ),
                  for (final r in rows.reversed)
                    ListTile(
                      title: Text(
                        context.l10n.lLeftkgRRightkgKg(
                          valueText(r.leftKg, 1),
                          valueText(r.rightKg, 1),
                        ),
                      ),
                      subtitle: Text(dayText(r.measuredAt)),
                      trailing: IconButton(
                        tooltip: context.l10n.deleteMeasurement,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (await confirmAction(
                            context,
                            'Delete measurement?',
                            context.l10n.thisRemovesTheSelectedGrip,
                          )) {
                            if (context.mounted) {
                              await runUiAction(
                                context,
                                () => ref
                                    .read(gripStrengthNotifierProvider.notifier)
                                    .delete(r.id),
                              );
                            }
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
      ],
    ),
  );
}
