import 'dart:math' as math;

import 'package:fjelia/models/garmin_data.dart';
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

  test('heart rate of several devices moves deep sleep to its lows', () {
    // Two devices at different levels, both lowest 150–175 min into the
    // night; the second only every 10 minutes.
    double bpm(int m) => m >= 150 && m < 175 ? 48 : 58;
    final watch = [
      for (var m = 0; m < 390; m += 2)
        (start.add(Duration(minutes: m)), bpm(m)),
    ];
    final band = [
      for (var m = 0; m < 390; m += 10)
        (start.add(Duration(minutes: m)), bpm(m) + 9),
    ];
    List<SleepPhase> estimate(List<List<(DateTime, double)>> hr) =>
        estimateSleepStages(
          start: start,
          end: end,
          deep: const Duration(minutes: 90),
          light: const Duration(minutes: 200),
          rem: const Duration(minutes: 85),
          awake: const Duration(minutes: 15),
          hrv: hrv,
          stress: stress,
          heartRates: hr,
        );
    Duration deepIn(List<SleepPhase> phases) =>
        phases.where((p) => p.phase == 'deep').fold(Duration.zero, (a, p) {
          final from = p.start.isAfter(start.add(const Duration(minutes: 150)))
              ? p.start
              : start.add(const Duration(minutes: 150));
          final to = p.end.isBefore(start.add(const Duration(minutes: 175)))
              ? p.end
              : start.add(const Duration(minutes: 175));
          return to.isAfter(from) ? a + to.difference(from) : a;
        });
    final without = estimate(const []);
    final withHr = estimate([watch, band]);
    expect(deepIn(withHr), greaterThan(deepIn(without)));
    expect(total(withHr, 'deep'), const Duration(minutes: 90));
    expect(total(withHr, 'rem'), const Duration(minutes: 85));
  });
}
