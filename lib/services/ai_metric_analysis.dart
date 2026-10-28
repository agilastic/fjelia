import 'dart:math' as math;

import '../db/database.dart';
import 'briefing_brief.dart';

/// How one metric compares with the athlete's own recent average, worked out
/// in the app so the model does not have to (a small on-device model reads
/// "higher or lower than average" badly). Every line carries the direction
/// rule, the verdict and one plain sentence without commas.
///
/// Lines look like `[Analysis:HRV,Date:...,DaysAgo:0,Verdict:worse,...]`.
class MetricAnalysis {
  const MetricAnalysis(this.today);

  /// The real current date: "today" is never the selected or latest record.
  final DateTime today;

  List<String> lines({
    required List<HrvRecord> hrv,
    required List<SleepRecord> sleep,
    required List<WellnessRecord> wellness,
    double? tsb,
    double? atl,
    double? ctl,
    List<String> done = const [],
    List<String> plannedToday = const [],
    List<String> tomorrow = const [],
    String? trainingHrv,
  }) {
    final out = <String>[];
    // Findings for the Brief: id, severity (red, yellow, good) and a fixed
    // rank that orders equally severe ones.
    final flags = <(String, String, int)>[];
    void flag(String id, String severity, int rank) =>
        flags.add((id, severity, rank));
    String sev(String? verdict) => switch (verdict) {
      'clearlyWorse' => 'red',
      'worse' => 'yellow',
      'better' => 'good',
      _ => 'none',
    };
    final verdicts = <String, String>{};
    void add(String? line, String name, String? verdict) {
      if (line == null) return;
      out.add(line);
      if (verdict != null) verdicts[name] = verdict;
    }

    // Newest first, as the builder sorts them.
    final hrvRows = [
      for (final r in hrv)
        if (r.hrvLastNight != null) r,
    ];
    final r1 = _judge(
      'SleepHRV',
      'ms',
      [for (final r in hrvRows) (r.date, r.hrvLastNight!)],
      higherIsBetter: true,
      worse: 'lower HRV means less recovery',
      better: 'higher HRV means better recovery',
      // Yellow from -10% (functional overload), red from -20% against the
      // personal baseline, or two days in a row of -10% or worse.
      yellowPct: 10,
      redPct: 20,
      twoDaysRed: true,
    );
    add(r1?.line, 'SleepHRV', r1?.verdict);
    if (r1 != null) {
      final v = sev(r1.verdict);
      if (v == 'good') flag('hrvHigh', 'good', 0);
      if (v == 'red' || v == 'yellow') flag('hrvLow', v, 0);
    }

    final rhr = _judge(
      'RHR',
      'bpm',
      [
        for (final r in hrv)
          if (r.restingHeartRate != null) (r.date, r.restingHeartRate! + 0.0),
      ],
      higherIsBetter: false,
      worse: 'a higher resting heart rate means more strain or less recovery',
      better: 'a lower resting heart rate means better recovery',
      steady: 2,
      yellowAbs: 2,
      redAbs: 4,
    );
    add(rhr?.line, 'RHR', rhr?.verdict);
    if (rhr != null) {
      final v = sev(rhr.verdict);
      if (v == 'good') flag('rhrDown', 'good', 1);
      if (v == 'red' || v == 'yellow') flag('rhrUp', v, 1);
    }

    final sleepRows = [
      for (final r in sleep)
        if (r.totalSleepSeconds > 0) r,
    ];
    final sl = _judge(
      'SleepDuration',
      'h',
      [for (final r in sleepRows) (r.date, r.totalSleepSeconds / 3600)],
      higherIsBetter: true,
      worse: 'less sleep than usual',
      better: 'more sleep than usual',
      digits: 1,
      steady: 7,
    );
    add(sl?.line, 'Sleep', sl?.verdict);
    if (sleepRows.isNotEmpty) {
      final s = sleepRows.first;
      final need = s.sleepNeedSeconds;
      if (need != null && need > 0) {
        final gap = (s.totalSleepSeconds - need) / 3600;
        if (gap < -1) {
          flag('sleepShort', 'red', 2);
        } else if (gap < -0.25) {
          flag('sleepShort', 'yellow', 2);
        } else {
          flag('sleepGood', 'good', 2);
        }
        out.add(
          '[Analysis:SleepVsNeed,Slept:${_n(s.totalSleepSeconds / 3600, 1)}h,'
          'Need:${_n(need / 3600, 1)}h,'
          'Verdict:${gap >= -0.25
              ? 'metNeed'
              : gap >= -1
              ? 'slightlyShort'
              : 'short'},'
          'Text:Last night you slept ${_n(s.totalSleepSeconds / 3600, 1)} h against a need of '
          '${_n(need / 3600, 1)} h; '
          '${gap >= -0.25 ? 'the need was met' : 'that is ${_n(-gap, 1)} h short'}.]',
        );
      }
    }

    final energy = _judge(
      'Energy',
      '',
      [
        for (final r in hrv)
          if (r.computedEnergie != null) (r.date, r.computedEnergie!),
      ],
      higherIsBetter: true,
      worse: 'lower energy is worse',
      better: 'higher energy is better',
      steady: 5,
    );
    add(energy?.line, 'Energy', energy?.verdict);
    if (energy != null) {
      final v = sev(energy.verdict);
      if (v == 'good') flag('energyHigh', 'good', 3);
      if (v == 'red' || v == 'yellow') flag('energyLow', v, 3);
    }

    final stress = _judge(
      'Stress',
      '',
      [
        for (final r in hrv)
          if (r.stressLevel != null) (r.date, r.stressLevel!),
      ],
      higherIsBetter: false,
      worse: 'higher stress is worse',
      better: 'lower stress is better',
      steady: 5,
    );
    add(stress?.line, 'Stress', stress?.verdict);
    if (stress != null) {
      final v = sev(stress.verdict);
      if (v == 'red' || v == 'yellow') flag('stressHigh', v, 5);
    }

    final resp = _judge(
      'RespRate',
      'brpm',
      [
        for (final r in hrv)
          if (r.respirationRate != null) (r.date, r.respirationRate!),
      ],
      higherIsBetter: false,
      worse: 'a clearly higher breathing rate can mean illness or strain',
      better: 'a lower breathing rate is calmer',
      digits: 1,
      steady: 1,
    );
    add(resp?.line, 'RespRate', resp?.verdict);
    if (resp != null) {
      final v = sev(resp.verdict);
      if (v == 'red' || v == 'yellow') flag('respHigh', v, 6);
    }

    final spo = hrv.where((r) => r.spo2 != null).toList();
    if (spo.isNotEmpty) {
      final v = spo.first.spo2!;
      final verdict = v >= 95
          ? 'normal'
          : v >= 92
          ? 'slightlyLow'
          : 'low';
      out.add(
        '[Analysis:SpO2,Date:${_d(spo.first.date)},DaysAgo:${_ago(spo.first.date)},'
        'Latest:${_n(v, 0)}%,Verdict:$verdict,'
        'Text:Overnight SpO2 was ${_n(v, 0)}%; '
        '${verdict == 'normal' ? 'normal (95% or more)' : 'below the normal 95%; mention it and advise a doctor if it stays low'}.]',
      );
      if (verdict != 'normal') verdicts['SpO2'] = 'worse';
      if (verdict == 'low') flag('spo2Low', 'red', 7);
      if (verdict == 'slightlyLow') flag('spo2Low', 'yellow', 7);
    }

    final skin = hrv.where((r) => r.skinTempDelta != null).toList();
    if (skin.isNotEmpty) {
      final v = skin.first.skinTempDelta!;
      final verdict = v.abs() < 0.5 ? 'normal' : 'unusual';
      out.add(
        '[Analysis:SkinTemp,Date:${_d(skin.first.date)},DaysAgo:${_ago(skin.first.date)},'
        'Latest:${_n(v, 1)}C,Verdict:$verdict,'
        'Text:Skin temperature was ${_n(v, 1)} C from your baseline; '
        '${verdict == 'normal' ? 'within the normal range' : 'an unusual shift that can come with illness or a very hard load'}.]',
      );
      if (verdict != 'normal') verdicts['SkinTemp'] = 'worse';
      if (verdict != 'normal') flag('skinTempOff', 'yellow', 8);
    }

    if (tsb != null) {
      final band = tsb > 5
          ? 'fresh'
          : tsb >= -10
          ? 'optimal'
          : tsb >= -30
          ? 'tired'
          : 'veryFatigued';
      final text = switch (band) {
        'fresh' => 'fresh and rested (form above +5)',
        'optimal' => 'in the optimal training zone (form -10 to +5)',
        'tired' => 'tired from accumulated training (form -10 to -30)',
        _ => 'very fatigued (form below -30); recovery comes first',
      };
      final trend = atl != null && ctl != null
          ? (atl > ctl * 1.15
                ? ' Recent load (ATL ${_n(atl, 0)}) is clearly above fitness (CTL ${_n(ctl, 0)}).'
                : atl < ctl * .85
                ? ' Recent load (ATL ${_n(atl, 0)}) is below fitness (CTL ${_n(ctl, 0)}).'
                : '')
          : '';
      out.add(
        '[Analysis:Form,TSB:${_n(tsb, 0)},Band:$band,'
        'Verdict:${band == 'fresh' || band == 'optimal' ? 'good' : 'worse'},'
        'Text:Training form (TSB ${_n(tsb, 0)}) is $text.$trend]',
      );
      if (band == 'tired' || band == 'veryFatigued') verdicts['Form'] = 'worse';
      if (band == 'fresh') verdicts['Form'] = 'better';
      if (band == 'tired') flag('formTired', 'yellow', 4);
      if (band == 'veryFatigued') flag('formVeryTired', 'red', 4);
      if (band == 'fresh') flag('formFresh', 'good', 4);
    }

    final better = [
      for (final e in verdicts.entries)
        if (e.value == 'better') e.key,
    ];
    final worse = [
      for (final e in verdicts.entries)
        if (e.value == 'worse' || e.value == 'clearlyWorse') e.key,
    ];
    // The traffic light follows the two core markers, sleep HRV and resting
    // heart rate: green = train as planned, yellow = functional overload,
    // red = non-functional overload, recovery first.
    final core = [verdicts['SleepHRV'], verdicts['RHR']];
    final readiness = core.contains('clearlyWorse')
        ? 'red'
        : core.contains('worse')
        ? 'yellow'
        : 'green';
    final advice = switch (readiness) {
      'red' =>
        'RED: recovery comes first; easy day or rest and no intense training',
      'yellow' => 'YELLOW: functional overload; keep planned training but add no extra intensity',
      _ => 'GREEN: train as planned; hard sessions are fine',
    };
    // The Brief: what matters, ranked, decided here and not by a model.
    int bySeverity((String, String, int) a, (String, String, int) b) {
      const order = {'red': 0, 'yellow': 1, 'good': 2};
      final c = order[a.$2]!.compareTo(order[b.$2]!);
      return c != 0 ? c : a.$3.compareTo(b.$3);
    }

    final bad = [
      for (final f in flags)
        if (f.$2 != 'good') f,
    ]..sort(bySeverity);
    final good = [
      for (final f in flags)
        if (f.$2 == 'good') f,
    ]..sort(bySeverity);
    final brief = BriefingBrief(
      readiness: readiness,
      findings: [for (final f in bad.take(3)) f.$1],
      good: [for (final f in good.take(2)) f.$1],
      done: done,
      today: plannedToday,
      tomorrow: tomorrow,
      trainingHrv: trainingHrv,
    );
    out.insert(0, brief.toLine());
    out.insert(
      0,
      '[Analysis:Overall,Today:${_d(today)},Readiness:$readiness,'
      'BetterThanAverage:${better.isEmpty ? 'none' : better.join('/')},'
      'WorseThanAverage:${worse.isEmpty ? 'none' : worse.join('/')},'
      'Text:Readiness from sleep HRV and resting heart rate is $advice. '
      'Compared with your own recent averages these are better: '
      '${better.isEmpty ? 'none' : better.join(' ')}; these are worse: '
      '${worse.isEmpty ? 'none' : worse.join(' ')}.]',
    );
    return out;
  }

  _Judged? _judge(
    String name,
    String unit,
    List<(DateTime, double)> series, {
    required bool higherIsBetter,
    required String worse,
    required String better,
    int digits = 0,
    double steady = 0,
    double yellowPct = 5,
    double redPct = 10,
    double? yellowAbs,
    double? redAbs,
    bool twoDaysRed = false,
  }) {
    if (series.length < 3) return null;
    final (date, latest) = series.first;
    final prior7 = series.skip(1).take(7).map((e) => e.$2).toList();
    final prior60 = series.skip(1).take(60).map((e) => e.$2).toList();
    if (prior7.length < 2) return null;
    double mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;
    final avg7 = mean(prior7), avg60 = mean(prior60);
    final pct = avg7 == 0 ? 0.0 : (latest - avg7) / avg7 * 100;
    // Trend: the newest three values against the three before them.
    final recent = series.take(3).map((e) => e.$2).toList();
    final before = series.skip(3).take(3).map((e) => e.$2).toList();
    final slope = before.length < 2 ? 0.0 : mean(recent) - mean(before);
    final band = math.max(avg7.abs() * .03, steady == 0 ? 0 : steady * .1);
    final trend = slope > band
        ? 'rising'
        : slope < -band
        ? 'falling'
        : 'steady';
    // Sign the change so that positive always means "good".
    final good = higherIsBetter ? pct : -pct;
    // Resting heart rate is judged in beats per minute (+2 to 3 is
    // functional overload, +3 to 6 non-functional); the others in percent.
    final goodAbs = higherIsBetter ? latest - avg7 : avg7 - latest;
    // The day before, against its own prior week: two bad days in a row are
    // worse than one.
    double? yesterdayGood;
    if (twoDaysRed && series.length >= 4) {
      final prior = series.skip(2).take(7).map((e) => e.$2).toList();
      if (prior.length >= 2) {
        final avgY = mean(prior);
        final pctY = avgY == 0 ? 0.0 : (series[1].$2 - avgY) / avgY * 100;
        yesterdayGood = higherIsBetter ? pctY : -pctY;
      }
    }
    final String verdict;
    if (yellowAbs != null && redAbs != null) {
      verdict = goodAbs <= -redAbs
          ? 'clearlyWorse'
          : goodAbs <= -yellowAbs
          ? 'worse'
          : goodAbs >= 1
          ? 'better'
          : 'normal';
    } else if (good <= -redPct ||
        (twoDaysRed &&
            good <= -yellowPct &&
            yesterdayGood != null &&
            yesterdayGood <= -yellowPct)) {
      verdict = 'clearlyWorse';
    } else if (good <= -yellowPct) {
      verdict = 'worse';
    } else if (good >= 5) {
      verdict = 'better';
    } else {
      verdict = 'normal';
    }
    final state = switch (verdict) {
      'clearlyWorse' => 'red',
      'worse' => 'yellow',
      _ => 'green',
    };
    final dir = pct >= 0 ? 'above' : 'below';
    final stale = _ago(date);
    final when = stale == 0 ? 'today' : '$stale days ago (${_d(date)})';
    final unitText = unit.isEmpty ? '' : ' $unit';
    final value = '${_n(latest, digits)}$unitText';
    final rule = higherIsBetter ? 'higher is better' : 'lower is better';
    final verdictText = switch (verdict) {
      'better' => 'BETTER than usual',
      'clearlyWorse' => 'MUCH WORSE than usual',
      'worse' => 'WORSE than usual',
      _ => 'NORMAL for you',
    };
    final change = yellowAbs != null
        ? '${_n(goodAbs.abs(), 0)} ${unit.isEmpty ? '' : '$unit '}${goodAbs >= 0 ? (higherIsBetter ? 'above' : 'below') : (higherIsBetter ? 'below' : 'above')}'
        : '${_n(pct.abs(), 0)}% $dir';
    final line =
        '[Analysis:$name,Date:${_d(date)},DaysAgo:$stale,Latest:${_n(latest, digits)}$unit,'
        'Avg7d:${_n(avg7, digits)}$unit,Avg60d:${_n(avg60, digits)}$unit,'
        'Delta7d:${pct >= 0 ? '+' : ''}${_n(pct, 0)}%,Trend:$trend,Verdict:$verdict,State:$state,'
        'Rule:${higherIsBetter ? 'higherIsBetter' : 'lowerIsBetter'},'
        'Text:${_label(name)} $value ($when): $change your 7-day average of '
        '${_n(avg7, digits)}$unitText; $trend. $verdictText (state ${state.toUpperCase()}; $rule).]';
    return _Judged(line, verdict);
  }

  /// How a metric is named in a sentence.
  static String _label(String name) => switch (name) {
    'SleepHRV' => 'Sleep HRV (overnight watch)',
    'RHR' => 'Resting heart rate',
    'SleepDuration' => 'Sleep duration',
    'RespRate' => 'Breathing rate',
    _ => name,
  };

  int _ago(DateTime date) {
    final a = DateTime(today.year, today.month, today.day);
    final l = date.toLocal();
    return a.difference(DateTime(l.year, l.month, l.day)).inDays;
  }

  static String _d(DateTime date) {
    final l = date.toLocal();
    return '${l.year.toString().padLeft(4, '0')}-'
        '${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
  }

  static String _n(num v, int digits) {
    if (!v.isFinite) return 'na';
    final s = v.toStringAsFixed(digits);
    return digits > 0 && s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}

class _Judged {
  const _Judged(this.line, this.verdict);
  final String line, verdict;
}
