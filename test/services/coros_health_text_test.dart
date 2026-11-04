import 'package:fjelia/services/coros_health_text.dart';
import 'package:flutter_test/flutter_test.dart';

// The formats COROS's MCP tools answer with (values made up).
const _overview = '''Sleep Overview
========================
Note: each record below is dated by its wake-up day.

2026-11-03
Sleep Score: 0
Sleep detail for this day is not available yet.

2026-11-04
Sleep Score: 88
Daily Sleep: 7h 12min (incl. naps)
Main Sleep (asleep): 7h 2min
Main Sleep Period (incl. awake): 7h 20min
Sleep metrics scope: daily
Deep Sleep Ratio: 25%
Light Sleep Ratio: 48%
REM Ratio: 22%
Awake Ratio: 5%
Awake Time: 18 min
Awake Count (>5 min): 1
Main Sleep Window: 2026-11-03 23:40 - 2026-11-04 07:00
Naps Total: 10 min''';

const _daily = '''Daily Health Data — Last 2 days | Resting HR: 50 bpm | HRV Baseline: 40 ms
Note: sleep entries are dated by their wake-up day.

--- 20261103 ---
Steps: 12,345 | Calories: 501 kcal | Exercise: 60 min
Stress: Avg 28

--- 20261104 ---
Steps: 300 | Calories: 20 kcal | Exercise: 0 min
Stress: Avg 11
Sleep Summary:
  Total: 7h 20min | Deep: 1h 46min | Light: 3h 23min | REM: 1h 33min | Awake: 18 min
  Sleep HR: Avg 50 bpm | Min 41 bpm | Max 80 bpm''';

const _hrv = '''Sleep HRV — 2026-11-03 to 2026-11-04
========================

HRV Assessment — Last 2 days
========================

2026-11-04:
  HRV Avg: 37 ms

Sleep HRV Time Series — Last 2 days
========================

2026-11-04:
  timestamp=1793747690, timezone=4, hrv=25 ms, status=4, confidence=100000''';

void main() {
  test('durations as COROS writes them', () {
    expect(corosMinutes('6h 27min'), 387);
    expect(corosMinutes('10 min'), 10);
    expect(corosMinutes('3h 0min'), 180);
    expect(corosMinutes('—'), isNull);
  });

  test('a night: score, window, stages and sleep heart rate', () {
    final nights = parseCorosSleepOverview(_overview);
    // The night without detail is left out.
    expect(nights.keys, [DateTime(2026, 11, 4)]);
    final days = parseCorosDailyHealth(_daily, nights: nights);
    final n = nights[DateTime(2026, 11, 4)]!;
    expect(n.score, 88);
    expect(n.asleepMin, 422);
    expect(n.periodMin, 440);
    expect(n.awakeMin, 18);
    expect((n.deepMin, n.lightMin, n.remMin), (106, 203, 93));
    expect((n.avgHr, n.minHr, n.maxHr), (50, 41, 80));
    expect(n.start, DateTime(2026, 11, 3, 23, 40));
    expect(n.end, DateTime(2026, 11, 4, 7));
    expect(days[DateTime(2026, 11, 3)]!.steps, 12345);
    expect(days[DateTime(2026, 11, 4)]!.stress, 11);
  });

  test('HRV, resting heart rate and stress per day', () {
    expect(parseCorosSleepHrv(_hrv), {DateTime(2026, 11, 4): 37.0});
    expect(
      parseCorosRestingHr(
        'Resting Heart Rate\n\n2026-11-04: 48 bpm\n2026-11-03: No data',
      ),
      {DateTime(2026, 11, 4): 48},
    );
    expect(
      parseCorosStress(
        '2026-11-04:\nAverage Stress: 9\nRelaxed: No data\n\n2026-11-03:\nAverage Stress: 31',
      ),
      {DateTime(2026, 11, 4): 9, DateTime(2026, 11, 3): 31},
    );
  });

  test('the night as curves: HRV per wake-up day, stress points', () {
    final hrv = parseCorosHrvSeries(_hrv);
    expect(hrv.keys, [DateTime(2026, 11, 4)]);
    expect(hrv.values.single.single.value, 25);
    expect(
      hrv.values.single.single.at,
      DateTime.fromMillisecondsSinceEpoch(1793747690 * 1000),
    );
    final stress = parseCorosStressSeries(
      '2026-11-04:\n  timestamp=1793747690, timezone=4, stress=12, score=1, '
      'stressHrv=0, stressHr=0\n  timestamp=1793747990, timezone=4, stress=0, '
      'score=0, stressHrv=0, stressHr=0',
    );
    // 0 is no measurement.
    expect([for (final p in stress) p.value], [12]);
  });

  test('wellness check: SpO2 and breathing rate', () {
    final checks = parseCorosHealthCheck(
      'Health Check Time Series\n\nDate: 2026-11-04\n'
      'timestamp=1793781086, timezone=4\n'
      'Heart Rate List: [1793781086=63 bpm]\nHRV List: [1793781086=56 ms]\n'
      'Respiration Rate List: [1793781086=16/min, 1793781146=14/min]\n'
      'SpO2 List: [1793781086=98%]\n',
    );
    expect(checks.single.hrv, 56);
    expect(checks.single.heartRate, 63);
    expect(checks.single.at!.millisecondsSinceEpoch, 1793781086000);
    expect(checks.single.day, DateTime(2026, 11, 4));
    expect(checks.single.spo2, 98);
    expect(checks.single.respiration, 15);
    expect(
      parseCorosHealthCheck(
        '"No complete health check time series data found in last 7 days."',
      ),
      isEmpty,
    );
  });
}
