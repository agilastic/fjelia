import 'dart:math' as math;

import 'package:fjelia/services/sleep_stage_estimate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 11, 4, 0, 10);
  final end = DateTime(2026, 11, 4, 6, 40);
  // Calm, low-stress stretches every 90 minutes, rising stress late.
  final stress = [
    for (var m = 0; m < 390; m += 3)
      (
        start.add(Duration(minutes: m)),
        20 + 15 * math.sin(2 * math.pi * m / 90) + m / 30,
      ),
  ];
  final hrv = [
    for (var m = 0; m < 390; m += 5)
      (
        start.add(Duration(minutes: m)),
        35 - 8 * math.sin(2 * math.pi * m / 90),
      ),
  ];

  Duration total(List phases, String stage) => phases
      .where((p) => p.phase == stage)
      .fold(Duration.zero, (a, p) => a + p.end.difference(p.start));

  test('keeps the watch totals and covers the whole night', () {
    final phases = estimateSleepStages(
      start: start,
      end: end,
      deep: const Duration(minutes: 90),
      light: const Duration(minutes: 200),
      rem: const Duration(minutes: 85),
      awake: const Duration(minutes: 15),
      hrv: hrv,
      stress: stress,
    );
    expect(phases.first.start, start);
    expect(phases.last.end, end);
    for (var i = 1; i < phases.length; i++) {
      expect(phases[i].start, phases[i - 1].end);
      expect(phases[i].phase, isNot(phases[i - 1].phase));
    }
    expect(total(phases, 'deep'), const Duration(minutes: 90));
    expect(total(phases, 'rem'), const Duration(minutes: 85));
    expect(total(phases, 'awake'), const Duration(minutes: 15));
    // Deep sleep leans to the first half, REM to the second.
    final mid = start.add(end.difference(start) ~/ 2);
    Duration half(String stage, bool first) => total(
      phases.where((p) => p.start.isBefore(mid) == first).toList(),
      stage,
    );
    expect(half('deep', true), greaterThan(half('deep', false)));
    expect(half('rem', false), greaterThan(half('rem', true)));
  });

  test('nothing to go on gives no estimate', () {
    expect(
      estimateSleepStages(
        start: start,
        end: end,
        deep: const Duration(minutes: 90),
        light: const Duration(minutes: 200),
        rem: const Duration(minutes: 85),
        awake: Duration.zero,
        hrv: const [],
        stress: const [],
      ),
      isEmpty,
    );
  });
}
