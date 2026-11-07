import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/l10n/l10n_ext.dart';
import 'package:fjelia/l10n/plan_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final de = lookupAppLocalizations(const Locale('de'));
  final en = lookupAppLocalizations(const Locale('en'));
  const names = ['Hannover Marathon'];

  setUp(() => setActiveLocale(const Locale('de')));
  tearDown(() => setActiveLocale(const Locale('en')));

  test('every purpose the week allocator writes', () {
    for (final (text, german) in const [
      (
        'Long run for Hannover Marathon',
        'Laufen: lange Einheit für Hannover Marathon',
      ),
      (
        'Steady quality ride for Hannover Marathon',
        'Radfahren: gleichmäßige Qualitätseinheit für Hannover Marathon',
      ),
      ('Intervals for Hannover Marathon', 'Intervalle für Hannover Marathon'),
      (
        'Threshold ride for Hannover Marathon',
        'Radfahren: Schwellentraining für Hannover Marathon',
      ),
      (
        'Hill hike for Hannover Marathon',
        'Wandern: Bergeinheit für Hannover Marathon',
      ),
      (
        'Openers for Hannover Marathon',
        'Kurze Aktivierung für Hannover Marathon',
      ),
      (
        'Easy swim: recovery around Hannover Marathon',
        'Schwimmen locker: Erholung rund um Hannover Marathon',
      ),
      (
        'Easy endurance run for Hannover Marathon',
        'Laufen: lockere Ausdauer für Hannover Marathon',
      ),
      (
        'Strength to support your training',
        'Kraft zur Unterstützung deines Trainings',
      ),
      (
        'Optional variety you chose in the settings',
        'Optionale Abwechslung aus deinen Einstellungen',
      ),
    ]) {
      expect(planObjectiveLabel(de, text, goalNames: names), german);
      expect(planObjectiveLabel(en, text), text);
    }
  });

  test('unmet lines, with the lowercased goal name restored', () {
    expect(
      planUnmetLabel(
        de,
        'Not enough training days for long run for hannover marathon.',
        goalNames: names,
      ),
      'Nicht genug Trainingstage für: Laufen: lange Einheit für Hannover Marathon.',
    );
    expect(
      planUnmetLabel(
        de,
        'The week holds 40 min, too little for a long ride for Hannover Marathon.',
        goalNames: names,
      ),
      'Die Woche hat 40 Min., zu wenig für eine lange Einheit (Radfahren) für Hannover Marathon.',
    );
    expect(planUnmetLabel(de, 'Something new.'), 'Something new.');
  });

  test('season lines from codes; an old season keeps its English', () {
    final report = {
      'goals': {
        'm': {'name': 'Hannover Marathon'},
        'h': {'name': 'Halbmarathon'},
      },
      'conflicts': [
        {
          'kind': 'sameDay',
          'goals': ['m', 'h'],
          'gapDays': 0,
          'message': 'x',
          'alternatives': ['Move one of the events', 'Mark one as cancelled'],
        },
      ],
      'summary': ['a', 'b'],
      'summaryCodes': [
        {'code': 'noRoom', 'n': 2},
        {'code': 'noHistory', 'sport': 'swimming', 'priority': 'B'},
      ],
    };
    expect(seasonReportLines(de, report), [
      'Hannover Marathon und Halbmarathon sind am selben Tag. Nur eines davon kann gelaufen bzw. gefahren werden.',
      '2 Einheiten fielen weg, weil die gewählten Trainings länger dauerten als die restliche Zeit der Woche.',
      'In deinem Verlauf gibt es kein aktuelles Training (Schwimmen), daher ist der Plan für das B-Ziel vorläufig.',
    ]);
    expect(seasonAlternatives(de, report), [
      'Eines der Events verschieben',
      'Eines als abgesagt markieren',
    ]);
    expect(seasonReportLines(en, report), ['x', 'a', 'b']);
    expect(seasonReportLines(de, {...report, 'summaryCodes': null}).skip(1), [
      'a',
      'b',
    ]);
  });

  test('badges and steps', () {
    expect(planPhaseLabel(de, 'taper'), 'TAPERING');
    expect(sessionTypeLabel(de, 'long'), 'LANG');
    expect(sessionStatusLabel(de, 'planned'), 'GEPLANT');
    expect(stepRoleLabel(de, 'Cool-down'), 'Auslaufen');
    expect(stepAmountLabel(de, '4× repeat'), '4× wiederholen');
    expect(stepAmountLabel(de, '5 min 30 sec'), '5 min 30 Sek.');
    expect(stepAmountLabel(en, '30 sec'), '30 sec');
    expect(planPhaseLabel(de, 'unknown'), 'UNKNOWN');
  });
}
