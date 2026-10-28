import 'dart:convert';
import 'dart:io';

import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/l10n/formats.dart';
import 'package:fjelia/l10n/l10n_ext.dart';
import 'package:fjelia/providers/locale_provider.dart';
import 'package:fjelia/screens/settings/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _arb(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _placeholders(String text) =>
    RegExp(r'\{(\w+)(?:\s*,|\})')
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet();

void main() {
  final en = _arb('en');
  final keys = en.keys.where((k) => !k.startsWith('@')).toSet();

  for (final code in supportedLanguageCodes) {
    test(
      '$code translates every English message with the same placeholders',
      () {
        final arb = _arb(code);
        expect(arb['@@locale'], code);
        expect(
          arb.keys.where((k) => !k.startsWith('@')).toSet(),
          keys,
          reason: 'message keys differ in app_$code.arb',
        );
        for (final key in keys.where(
          (k) => k != '@@locale' && en[k] is String,
        )) {
          expect(arb[key], isA<String>(), reason: '$code/$key');
          expect((arb[key] as String).trim(), isNotEmpty, reason: '$code/$key');
          expect(
            _placeholders(arb[key] as String),
            _placeholders(en[key] as String),
            reason: '$code/$key',
          );
        }
      },
    );
  }

  test('reading counts use singular, plural and Slovak few forms', () {
    const forms = {
      'en': ['readings', 'reading', 'readings', 'readings'],
      'de': ['Messungen', 'Messung', 'Messungen', 'Messungen'],
      'fr': ['mesure', 'mesure', 'mesures', 'mesures'],
      'it': ['misurazioni', 'misurazione', 'misurazioni', 'misurazioni'],
      'es': ['mediciones', 'medición', 'mediciones', 'mediciones'],
      'ca': ['mesuraments', 'mesurament', 'mesuraments', 'mesuraments'],
      'nb': ['målinger', 'måling', 'målinger', 'målinger'],
      'sk': ['meraní', 'meranie', 'merania', 'meraní'],
      'fi': ['mittausta', 'mittaus', 'mittausta', 'mittausta'],
      'da': ['målinger', 'måling', 'målinger', 'målinger'],
    };
    const counts = [0, 1, 2, 5];
    expect(forms.keys.toSet(), supportedLanguageCodes.toSet());
    for (final entry in forms.entries) {
      final l10n = lookupAppLocalizations(Locale(entry.key));
      for (var i = 0; i < counts.length; i++) {
        expect(
          l10n.lengthReadingsAverageMinMax(counts[i]),
          startsWith('${counts[i]} ${entry.value[i]} · '),
          reason: '${entry.key}/${counts[i]} readings',
        );
        expect(
          l10n.valueUpcomingWorkoutsGenerated(counts[i]),
          l10n.countUpcomingWorkoutsGenerated(counts[i]),
          reason: '${entry.key}/${counts[i]} workout counts agree',
        );
      }
    }
  });

  test('workout and training-day counts select the grammatical forms', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(
      en.countUpcomingWorkoutsGenerated(1),
      '1 upcoming workout generated',
    );
    expect(
      en.countUpcomingWorkoutsGenerated(2),
      '2 upcoming workouts generated',
    );
    expect(
      en.trainingdaysperweekTrainingDaysTapTo(1),
      startsWith('1 training day ·'),
    );
    expect(
      en.trainingdaysperweekTrainingDaysTapTo(2),
      startsWith('2 training days ·'),
    );

    final sk = lookupAppLocalizations(const Locale('sk'));
    expect(
      sk.countUpcomingWorkoutsGenerated(1),
      'Vytvorený 1 nadchádzajúci tréning',
    );
    expect(
      sk.countUpcomingWorkoutsGenerated(2),
      'Vytvorené 2 nadchádzajúce tréningy',
    );
    expect(
      sk.countUpcomingWorkoutsGenerated(5),
      'Vytvorených 5 nadchádzajúcich tréningov',
    );
    expect(
      sk.trainingdaysperweekTrainingDaysTapTo(1),
      startsWith('1 tréningový deň ·'),
    );
    expect(
      sk.trainingdaysperweekTrainingDaysTapTo(2),
      startsWith('2 tréningové dni ·'),
    );
    expect(
      sk.trainingdaysperweekTrainingDaysTapTo(5),
      startsWith('5 tréningových dní ·'),
    );
  });

  test('numbers and dates follow the app language', () {
    addTearDown(() => setActiveLocale(const Locale('en')));
    final day = DateTime(2026, 11, 5);
    setActiveLocale(const Locale('en'));
    expect(1.5.fixed(1), '1.5');
    expect(DateFormat.yMd().format(day), '05/11/2026');
    setActiveLocale(const Locale('de'));
    expect(1.5.fixed(1), '1,5');
    expect(DateFormat.yMMMd().format(day), '5. Nov. 2026');
    setActiveLocale(const Locale('fi'));
    expect(1.5.fixed(1), '1,5');
    expect(DateFormat.yMd().format(day), '5.11.2026');
  });

  testWidgets('settings follow the saved language', (tester) async {
    SharedPreferences.setMockInitialValues({'app_language': 'de'});
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            locale: ref.watch(appLocaleProvider),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Sprache', skipOffstage: false), findsOneWidget);
  });
}
