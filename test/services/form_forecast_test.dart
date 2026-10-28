import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/services/briefing_brief.dart';
import 'package:fjelia/services/form_forecast.dart';
import 'package:flutter_test/flutter_test.dart';

/// 60 days of history ending today, with [load] for each day (oldest first).
List<FormPoint> history(double Function(int day) load, {int days = 60}) {
  final end = DateTime(2026, 10, 28);
  final loads = <DateTime, double>{
    for (var i = 0; i < days; i++)
      DateTime(end.year, end.month, end.day - (days - 1 - i)): load(i),
  };
  return buildTrainingFormSeries(dailyLoads: loads, through: end);
}

void main() {
  final today = DateTime(2026, 10, 28);
  DateTime day(int n) => DateTime(today.year, today.month, today.day + n);

  test('a steady athlete is in the optimal range', () {
    final f = FormForecast.compute(history((_) => 60))!;
    expect(f.state, 'optimal');
    expect(f.trend, 'steady');
    expect(f.rampState, 'steady');
    expect(f.overreaching, isFalse);
    expect(f.restDaysToOptimal, isNull);
    expect(f.outlook, isNull);
  });

  test('a hard block makes form tired; rest brings it back', () {
    // Easy base, then a hard last week.
    final f = FormForecast.compute(history((i) => i < 53 ? 50 : 140))!;
    expect(f.tsb, lessThan(-10));
    expect(f.state, anyOf('tired', 'veryFatigued'));
    expect(f.trend, 'falling');
    expect(f.ramp, greaterThan(3));
    // Rest raises form every day.
    for (var i = 1; i < 7; i++) {
      expect(f.restTsb[i], greaterThan(f.restTsb[i - 1]));
    }
    expect(f.restTsb.first, greaterThan(f.tsb));
    final days = f.restDaysToOptimal!;
    expect(days, inInclusiveRange(1, 21));
    // The projection really reaches the optimal range after that many days.
    if (days <= 7) expect(f.restTsb[days - 1], greaterThanOrEqualTo(-10));
    if (days > 1 && days <= 7) expect(f.restTsb[days - 2], lessThan(-10));
    expect(f.outlook, anyOf(startsWith('restFixes:'), 'needsLongRest'));
  });

  test('the projection follows the model exactly', () {
    final h = history((_) => 60);
    final f = FormForecast.compute(h)!;
    var c = h.last.ctl, a = h.last.atl;
    c += (0 - c) * (2 / 43);
    a += (0 - a) * 0.25;
    expect(f.restTsb.first, closeTo(c - a, 1e-9));
  });

  test('the plan projection needs a plan and uses planned load', () {
    final h = history((_) => 60);
    expect(FormForecast.compute(h)!.planTsb, isEmpty);
    final hard = FormForecast.compute(
      h,
      planned: {for (var i = 1; i <= 7; i++) day(i): 150},
    )!;
    final easy = FormForecast.compute(
      h,
      planned: {for (var i = 1; i <= 7; i++) day(i): 20},
    )!;
    expect(hard.planTsb, hasLength(7));
    expect(hard.planLoad7d, 1050);
    expect(hard.planTsb[6], lessThan(easy.planTsb[6]));
    expect(hard.planTsb[6], lessThan(FormForecast.compute(h)!.restTsb[6]));
  });

  test('race-day form is predicted from the plan', () {
    final h = history((_) => 60);
    // A taper: 14 days of reduced load, then the race.
    final planned = {for (var i = 1; i <= 14; i++) day(i): 25};
    final f = FormForecast.compute(
      h,
      planned: planned.map((k, v) => MapEntry(k, v.toDouble())),
      raceInDays: 14,
    )!;
    expect(f.raceTsb, isNotNull);
    expect(f.raceTsb!, greaterThan(f.tsb));
    expect(f.toLine(), contains('Race:14d/+'));
    expect(f.text, contains('On race day in 14 days'));
    // Too far away or without a plan: no race prediction.
    expect(
      FormForecast.compute(h, planned: {day(1): 50}, raceInDays: 200)!.raceTsb,
      isNull,
    );
    expect(FormForecast.compute(h, raceInDays: 14)!.raceTsb, isNull);
  });

  test('overreaching: fatigue far ahead of fitness', () {
    final f = FormForecast.compute(history((i) => i < 50 ? 30 : 200))!;
    expect(f.overreaching, isTrue);
    expect(f.text, contains('overreaching risk'));
  });

  test('too little history gives no forecast', () {
    expect(FormForecast.compute(history((_) => 60, days: 10)), isNull);
  });

  test('the line is parseable and the text has no commas', () {
    final f = FormForecast.compute(
      history((i) => i < 53 ? 50 : 140),
      planned: {day(1): 80, day(2): 0, day(3): 90},
    )!;
    final line = f.toLine();
    expect(line, startsWith('[Analysis:FormForecast,CTL:'));
    expect(line, contains('State:'));
    expect(line, contains('Rest2d:'));
    expect(line, contains('Plan7d:'));
    final text = line.substring(line.indexOf('Text:') + 5, line.length - 1);
    expect(text.contains(','), isFalse);
    expect(text, endsWith('estimates from a model.'));
  });

  test('the outlook reaches the Brief and its fallback text', () {
    expect(
      BriefingBrief.outlookEnglish('restFixes:3'),
      contains('about 3 easy days'),
    );
    final b = BriefingBrief(
      readiness: 'yellow',
      findings: const ['formTired'],
      outlook: 'restFixes:3',
    );
    expect(BriefingBrief.parse(b.toLine())!.outlook, 'restFixes:3');
    expect(
      b.toModelText(),
      contains('Outlook: about 3 easy days bring form back'),
    );
  });
}
