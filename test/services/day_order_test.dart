import 'package:fjelia/l10n/app_localizations_de.dart';
import 'package:fjelia/l10n/app_localizations_en.dart';
import 'package:fjelia/services/briefing_brief.dart';
import 'package:fjelia_core/services/day_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const strength = (sport: 'strength', minutes: 45, type: 'key');
  const longRun = (sport: 'trail_running', minutes: 114, type: 'long');
  const keyRun = (sport: 'running', minutes: 60, type: 'key');
  const morning = (6 * 60, 7 * 60 + 30), evening = (17 * 60, 20 * 60);

  test('a long session goes where it fits, strength in the other window', () {
    final order = dayOrder(
      [strength, longRun],
      [morning, evening],
      nowMinute: 5 * 60,
    )!;
    expect(
      dayOrderLine(order),
      'strength/45@06:00-07:30|trail_running/114@17:00-20:00',
    );
    expect(order.reason, 'fit');
  });

  test('the key endurance session first, strength later in the day', () {
    final order = dayOrder(
      [strength, keyRun],
      [(6 * 60, 8 * 60), (17 * 60, 19 * 60)],
      nowMinute: 5 * 60,
    )!;
    expect(
      dayOrderLine(order),
      'running/60@06:00-08:00|strength/45@17:00-19:00',
    );
    expect(order.reason, 'priority');
  });

  test('a window already gone is left out', () {
    final order = dayOrder(
      [strength, keyRun],
      [morning, evening],
      nowMinute: 12 * 60,
    )!;
    // Both fit the evening: the run first, strength right after.
    expect(
      dayOrderLine(order),
      'running/60@17:00-20:00|strength/45@17:00-20:00',
    );
    expect(order.reason, 'together');
  });

  test('without training times only the order', () {
    final order = dayOrder([strength, keyRun], const [], nowMinute: 600)!;
    expect(dayOrderLine(order), 'running/60|strength/45');
    expect(dayOrder([keyRun], [morning], nowMinute: 0), isNull);
  });

  test('the brief says it: parts of the day to a model, times in the app', () {
    final order = dayOrder(
      [strength, longRun],
      [morning, evening],
      nowMinute: 5 * 60,
    )!;
    final brief = BriefingBrief.parse(
      BriefingBrief(
        readiness: 'yellow',
        today: const ['strength/45', 'trail_running/114'],
        order: dayOrderLine(order).split('|'),
        orderWhy: order.reason,
      ).toLine(),
    )!;
    final model = brief.toModelText();
    expect(
      model,
      contains(
        'first strength 45 min in the morning training window, '
        'then trail running 114 min in the evening training window',
      ),
    );
    expect(model, isNot(contains('06:00')));
    expect(
      brief.localText(AppLocalizationsDe()),
      contains('Zuerst Kraft 45 min (06:00–07:30), danach'),
    );
    expect(
      brief.orderText(AppLocalizationsEn()),
      'First Strength 45 min (06:00–07:30), '
      'then Running 114 min (17:00–20:00).',
    );
  });
}
