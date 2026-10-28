import '../providers/day_data_provider.dart' show FormPoint;

/// The training-load chart (CTL fitness, ATL fatigue, TSB form) as background
/// analysis: where form stands, where it has been heading, and what it will be
/// if the athlete rests or follows the plan. Worked out here with the same
/// smoothing as the chart (CTL 42-day, ATL 7-day), so a model never has to do
/// the arithmetic and its predictions are the app's own numbers.
class FormForecast {
  const FormForecast({
    required this.ctl,
    required this.atl,
    required this.ctlWeekAgo,
    required this.tsbWeekAgo,
    required this.restTsb,
    required this.restDaysToOptimal,
    required this.planTsb,
    required this.planLoad7d,
    this.raceInDays,
    this.raceTsb,
  });

  final double ctl, atl, ctlWeekAgo, tsbWeekAgo;
  double get tsb => ctl - atl;

  /// CTL change over the last 7 days: points per week.
  double get ramp => ctl - ctlWeekAgo;

  /// Form after 1, 2 ... 7 rest days (index 0 = tomorrow).
  final List<double> restTsb;

  /// Rest days until form is back at -10 or better; null when it already is,
  /// or 99 when it takes longer than three weeks.
  final int? restDaysToOptimal;

  /// Form on each of the next 7 days when the planned sessions are done; empty
  /// without a plan.
  final List<double> planTsb;
  final double planLoad7d;
  final int? raceInDays;
  final double? raceTsb;

  static const _ctlAlpha = 2 / 43;
  static const _atlAlpha = 0.25;

  /// fresh, optimal, tired or veryFatigued.
  String get state => tsb > 5
      ? 'fresh'
      : tsb >= -10
      ? 'optimal'
      : tsb >= -30
      ? 'tired'
      : 'veryFatigued';

  /// rising, falling or steady: the form against a week ago.
  String get trend {
    final d = tsb - tsbWeekAgo;
    return d > 4
        ? 'rising'
        : d < -4
        ? 'falling'
        : 'steady';
  }

  /// calm, building or aggressive: how fast fitness is being added.
  String get rampState => ramp > 8
      ? 'aggressive'
      : ramp > 3
      ? 'building'
      : ramp < -3
      ? 'losing'
      : 'steady';

  /// Whether fatigue has run far ahead of fitness.
  bool get overreaching => atl > ctl * 1.3 || tsb < -30;

  /// [series] is the daily history up to today, [planned] the planned load per
  /// calendar day after today. A missing day is rest.
  static FormForecast? compute(
    List<FormPoint> series, {
    Map<DateTime, double> planned = const {},
    int? raceInDays,
    DateTime? now,
  }) {
    if (series.length < 14) return null;
    final last = series.last;
    final week = series[series.length - 8];
    double ctl = last.ctl, atl = last.atl;
    final start = DateTime(last.date.year, last.date.month, last.date.day);

    List<double> project(int days, double Function(int i, DateTime d) load) {
      var c = last.ctl, a = last.atl;
      final out = <double>[];
      for (var i = 1; i <= days; i++) {
        final d = DateTime(start.year, start.month, start.day + i);
        final l = load(i, d);
        c += (l - c) * _ctlAlpha;
        a += (l - a) * _atlAlpha;
        out.add(c - a);
      }
      return out;
    }

    final rest = project(7, (_, _) => 0);
    int? toOptimal;
    if (last.ctl - last.atl < -10) {
      toOptimal = 99;
      final longer = project(21, (_, _) => 0);
      for (var i = 0; i < longer.length; i++) {
        if (longer[i] >= -10) {
          toOptimal = i + 1;
          break;
        }
      }
    }
    final hasPlan = planned.entries.any(
      (e) => e.value > 0 && e.key.isAfter(start),
    );
    final plan = hasPlan
        ? project(7, (_, d) => planned[d] ?? 0)
        : const <double>[];
    var load7 = 0.0;
    for (var i = 1; i <= 7; i++) {
      load7 += planned[DateTime(start.year, start.month, start.day + i)] ?? 0;
    }
    double? raceTsb;
    if (raceInDays != null && raceInDays > 0 && raceInDays <= 70 && hasPlan) {
      raceTsb = project(raceInDays, (_, d) => planned[d] ?? 0).last;
    }
    return FormForecast(
      ctl: ctl,
      atl: atl,
      ctlWeekAgo: week.ctl,
      tsbWeekAgo: week.ctl - week.atl,
      restTsb: rest,
      restDaysToOptimal: toOptimal,
      planTsb: plan,
      planLoad7d: load7,
      raceInDays: raceInDays,
      raceTsb: raceTsb,
    );
  }

  static String _n(double v) => v.round().toString();
  static String _s(double v) => '${v >= 0 ? '+' : ''}${v.round()}';

  /// The compact line for every provider.
  String toLine() =>
      '[Analysis:FormForecast,CTL:${_n(ctl)},ATL:${_n(atl)},TSB:${_s(tsb)},'
      'State:$state,Trend:$trend,Ramp:${_s(ramp)}/wk,RampState:$rampState,'
      'Overreaching:${overreaching ? 'yes' : 'no'},'
      'Rest2d:${_s(restTsb[1])},Rest4d:${_s(restTsb[3])},Rest7d:${_s(restTsb[6])},'
      'RestDaysToOptimal:${restDaysToOptimal ?? 'already'},'
      'PlanTomorrow:${planTsb.isEmpty ? 'na' : _s(planTsb[0])},'
      'Plan7d:${planTsb.isEmpty ? 'na' : _s(planTsb[6])},PlanLoad7d:${_n(planLoad7d)},'
      'Race:${raceTsb == null ? 'na' : '${raceInDays}d/${_s(raceTsb!)}'},'
      'Text:$text]';

  /// The same in one plain sentence block, without commas.
  String get text {
    final b = StringBuffer(
      'Form (TSB ${_s(tsb)}) is $state and $trend against last week; '
      'fitness (CTL ${_n(ctl)}) is $rampState (${_s(ramp)} a week) and fatigue (ATL ${_n(atl)}). ',
    );
    if (overreaching) {
      b.write('Fatigue is far ahead of fitness: overreaching risk. ');
    }
    if (restDaysToOptimal == null) {
      b.write('Form is already in the optimal range or better. ');
    } else if (restDaysToOptimal == 99) {
      b.write(
        'Resting alone would take more than three weeks to reach the optimal range. ',
      );
    } else {
      b.write(
        'With $restDaysToOptimal easy or rest days form is back to the optimal range '
        '(about ${_s(restTsb[restDaysToOptimal! - 1 > 6 ? 6 : restDaysToOptimal! - 1])}). ',
      );
    }
    if (planTsb.isNotEmpty) {
      b.write(
        'Following the plan for 7 days (planned load ${_n(planLoad7d)}) form reaches '
        '${_s(planTsb[6])}. ',
      );
    }
    if (raceTsb != null) {
      b.write(
        'On race day in $raceInDays days form is predicted at ${_s(raceTsb!)} '
        '(+5 to +25 is a good range). ',
      );
    }
    b.write('These are estimates from a model.');
    return b.toString().replaceAll(',', ';');
  }

  /// A short outlook id for the Brief: what happens next.
  /// restFixes: form is tired but a few easy days fix it; planKeepsTired: the
  /// plan keeps form low; planBuilds: form stays fine; raceReady / raceOff.
  String? get outlook {
    if (restDaysToOptimal != null && restDaysToOptimal! <= 4) {
      return 'restFixes:$restDaysToOptimal';
    }
    if (restDaysToOptimal != null) return 'needsLongRest';
    if (planTsb.isNotEmpty && planTsb.any((t) => t < -20)) {
      return 'planKeepsTired';
    }
    return null;
  }
}
