import '../../providers/activity_history_provider.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/day_data_provider.dart';
import '../../widgets/app_widgets.dart';
import 'load_visuals.dart';
import '../../utils/week.dart';
import '../../providers/week_start_provider.dart';

class LoadHistoryCards extends ConsumerWidget {
  const LoadHistoryCards({super.key, required this.polarization});
  final bool polarization;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider);
    final date = DateTime(selected.year, selected.month, selected.day);
    final mondayFirst = ref.watch(weekStartsOnMondayProvider);
    final monday = weekStartOf(date, mondayFirst: mondayFirst);
    final weeks = {
      for (var i = 11; i >= 0; i--)
        DateTime(monday.year, monday.month, monday.day - i * 7):
            List<double>.filled(4, 0),
    };
    for (final a in ref.watch(loadActivitiesProvider).valueOrNull ?? []) {
      final d = DateTime(a.startDate.year, a.startDate.month, a.startDate.day);
      final week = weekStartOf(d, mondayFirst: mondayFirst);
      final values = weeks[week];
      if (values == null) continue;
      values[3] += a.totalElevation ?? 0;
      try {
        final z = jsonDecode(a.hrZonesJson ?? '{}');
        if (z is! Map) continue;
        for (var i = 1; i <= 5; i++) {
          final pct = z['zone$i'];
          if (pct is num && pct.isFinite && pct >= 0) {
            values[i <= 2
                    ? 0
                    : i == 3
                    ? 1
                    : 2] +=
                a.durationSeconds / 60 * pct / 100;
          }
        }
      } on FormatException {
        /* Skip malformed zone data. */
      }
    }
    if (!polarization) {
      return LoadCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: mint.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.landscape, color: mint, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ELEVATION',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Text('12-WEEK HISTORY', style: loadCaption),
              ],
            ),
            const SizedBox(height: 12),
            LoadWeekBars(
              dates: weeks.keys.toList(),
              values: [for (final v in weeks.values) v[3]],
              mondayFirst: mondayFirst,
            ),
            const Divider(height: 30, color: Colors.white10),
            Text(
              weeks[monday]![3] == 0
                  ? 'No elevation this week'
                  : '${valueText(weeks[monday]![3])} m this week',
              style: const TextStyle(fontSize: 13, color: muted),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    }
    const colors = [loadBlue, Color(0xFFFFCC00), loadRed];
    return LoadCard(
      color: loadInset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(child: Text('ZONE POLARIZATION', style: loadLabel)),
              LoadLegend('EASY', loadBlue),
              SizedBox(width: 8),
              LoadLegend('MOD', Color(0xFFFFCC00)),
              SizedBox(width: 8),
              LoadLegend('HARD', loadRed),
            ],
          ),
          const SizedBox(height: 12),
          // Latest week on top, oldest at the bottom.
          for (final e in weeks.entries.toList().reversed)
            if (e.value.take(3).any((v) => v > 0))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        // Calendar week (ISO), the current one highlighted.
                        'W${loadWeekNumber(e.key, mondayFirst: mondayFirst)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: e.key == monday
                              ? FontWeight.w800
                              : FontWeight.w400,
                          color: e.key == monday
                              ? Colors.white
                              : const Color(0xFFBBBBBB),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            for (var i = 0; i < 3; i++)
                              if (e.value[i] > 0)
                                Expanded(
                                  flex: (e.value[i] * 100).round().clamp(
                                    1,
                                    100000000,
                                  ),
                                  child: Container(
                                    height: 14,
                                    color: colors[i],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${(100 * e.value[0] / e.value.take(3).reduce((a, b) => a + b)).round()}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              100 *
                                      e.value[0] /
                                      e.value.take(3).reduce((a, b) => a + b) >=
                                  80
                              ? loadBlue
                              : const Color(0xFFFFCC00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          if (!weeks.values.any((v) => v.take(3).any((n) => n > 0)))
            const EmptyState('No recorded HR zones'),
          const SizedBox(height: 14),
          const Text(
            'Seiler 80/20: ≥80% easy, ≤20% high intensity',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFFBBBBBB),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
