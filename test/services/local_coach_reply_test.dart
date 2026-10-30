import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/services/local_coach_reply.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const context =
    '[Analysis:Stress,Latest:20,Avg7d:24,Rule:lowerIsBetter,Verdict:better]\n'
    '[Analysis:Energy,Latest:34,Avg7d:50,Rule:higherIsBetter,Verdict:worse]\n'
    '[Analysis:SleepDuration,Latest:7h,Avg7d:8h,Verdict:worse]\n'
    '[Analysis:SleepVsNeed,Slept:7h,Need:8h,Verdict:slightlyShort]\n'
    '[Analysis:Form,TSB:-11,Band:tired]\n'
    '[BP:Latest:2026-10-29,Sys:139,Dia:77,HR:55]\n'
    '[RaceGoal:Sport:running,DistKm:42.2,Date:2027-08-08,Target:4:00:00,Priority:A]\n'
    '[RaceGoal:Sport:cycling_road,DistKm:200,Date:2027-03-20,Target:none,Priority:B]\n'
    '[RaceGoal:Sport:running,DistKm:21.1,Date:2027-10-10,Target:none,Priority:C]';

void main() {
  test('rejects the reversed comparison from the screenshot', () {
    expect(
      localCoachReplyIssue(
        'Der Stresswert von 20 ist höher als der Durchschnitt (24).',
        context,
        '',
      ),
      'reversed_stress_comparison',
    );
    expect(
      localCoachReplyIssue(
        'Stress 20 is above the average of 24.',
        context,
        '',
      ),
      'reversed_stress_comparison',
    );
  });

  test('keeps correct and negated stress comparisons', () {
    for (final reply in [
      'Dein Stresswert von 20 ist niedriger als dein Durchschnitt von 24.',
      'Stress 20 is below the average of 24.',
      'Stress 20 ist nicht höher als der Durchschnitt 24.',
    ]) {
      expect(localCoachReplyIssue(reply, context, ''), isNull);
    }
  });

  test('seven hours slept cannot become seven hours of missing sleep', () {
    for (final reply in [
      'Die 7-Stunden-Schlafmangel wirken negativ.',
      'Dein Schlafmangel beträgt 7 Stunden.',
      'Your sleep deficit is 7 hours.',
    ]) {
      expect(
        localCoachReplyIssue(reply, context, ''),
        'incorrect_sleep_shortfall',
      );
    }
    expect(
      localCoachReplyIssue(
        'Ihr Schlafmangel beträgt eine Stunde, da Sie 7 Stunden schliefen statt der erforderten 8 Stunden.',
        context,
        '',
      ),
      isNull,
    );
    expect(
      localCoachReplyIssue('Your sleep deficit is 1 hour.', context, ''),
      isNull,
    );
    expect(
      localCoachReplyIssue('Your sleep deficit is 1 hour.', '', ''),
      'incorrect_sleep_shortfall',
    );
  });

  test('a form value is not a weekly rate', () {
    expect(
      localCoachReplyIssue('Die Form (-11 a Woche) nimmt ab.', context, ''),
      'form_used_as_weekly_change',
    );
    expect(
      localCoachReplyIssue('Current form is -11 points per week.', context, ''),
      'form_used_as_weekly_change',
    );
    expect(
      localCoachReplyIssue(
        'Die aktuelle Form liegt bei -11 Punkten.',
        context,
        '',
      ),
      isNull,
    );
  });

  test('blood pressure cannot establish the current training phase', () {
    expect(
      localCoachReplyIssue(
        'Die aktuelle Rekonstruktion zeigt eine starke Reduktionsphase bei 139/77 Blutdruck.',
        context,
        '',
      ),
      'blood_pressure_used_as_training_phase',
    );
    expect(
      localCoachReplyIssue(
        'Der Blutdruck zeigt keine Reduktionsphase an.',
        context,
        '',
      ),
      isNull,
    );
    expect(
      localCoachReplyIssue('Blood pressure shows no taper.', context, ''),
      isNull,
    );
  });

  test('an energy score is not a glucose measurement in any app language', () {
    for (final reply in [
      'Blood glucose is 34.',
      'Der Blutzuckerspiegel ist 34.',
      'La glycémie est de 34.',
      'La glicemia è 34.',
      'La glucosa es 34.',
      'La glucosa és 34.',
      'Blodsukkeret er 34.',
      'Glykémia je 34.',
      'Verensokeri on 34.',
    ]) {
      expect(
        localCoachReplyIssue(reply, context, ''),
        'unsupported_glucose_value',
        reason: reply,
      );
    }
    expect(
      localCoachReplyIssue('Deine Energie liegt bei 34.', context, ''),
      isNull,
    );
    expect(
      localCoachReplyIssue(
        'Blood glucose is 34.',
        '',
        'My blood glucose is 34. What does that mean?',
      ),
      isNull,
    );
    expect(
      localCoachReplyIssue(
        'Blood glucose is 34.',
        context,
        'My blood glucose is 100.',
      ),
      'unsupported_glucose_value',
    );
    expect(
      localCoachReplyIssue('No glucose reading is available.', context, ''),
      isNull,
    );
  });

  test('the app summary keeps every goal and the actual metric identities', () {
    final l = lookupAppLocalizations(const Locale('de'));
    final text = localCoachDataSummary(context, l, 'de');
    expect(text, startsWith(l.coachDataFallback));
    expect(text, contains('20 < 24'));
    expect(text, contains('34 < 50'));
    expect(text, contains('7 h < 8 h'));
    expect(text, contains('Schlafbedarf: 8 h; fehlend: 1 h.'));
    expect(text, contains('Aktuelle Form (TSB): -11 Punkte.'));
    expect(text, contains('139/77 mmHg'));
    expect(text, contains(l.raceGoalsLength(3)));
    for (final date in ['2027-08-08', '2027-03-20', '2027-10-10']) {
      expect(text, contains(date));
    }
    expect(text, isNot(contains('Blutzucker')));
  });

  test('the fallback is localised in all ten app languages', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = lookupAppLocalizations(locale);
      final text = localCoachDataSummary(context, l, locale.languageCode);
      expect(text, startsWith(l.coachDataFallback));
      expect(text, contains(l.raceGoalsLength(3)));
      expect(text, contains(l.coachSevenDayAverage));
      expect(text, isNot(contains('{need}')));
    }
  });

  test('an answer about goals cannot leave the other goals out', () {
    const questions = {
      'en': 'What are my goals?',
      'de': 'Welche Ziele habe ich?',
      'fr': 'Quels sont mes objectifs ?',
      'it': 'Quali sono i miei obiettivi?',
      'es': '¿Cuáles son mis objetivos?',
      'ca': 'Quins són els meus objectius?',
      'nb': 'Hva er mine mål?',
      'sk': 'Aké sú moje ciele?',
      'fi': 'Mitkä ovat tavoitteeni?',
      'da': 'Hvad er mine mål?',
    };
    for (final entry in questions.entries) {
      final l = lookupAppLocalizations(Locale(entry.key));
      final reply = completeLocalCoachCalendar(
        '2027-08-08',
        context,
        entry.value,
        l,
        entry.key,
      );
      for (final date in ['2027-08-08', '2027-03-20', '2027-10-10']) {
        expect(reply, contains(date), reason: entry.key);
      }
    }
    final l = lookupAppLocalizations(const Locale('en'));
    expect(
      completeLocalCoachCalendar(
        'Keep today easy.',
        context,
        'How am I recovered?',
        l,
        'en',
      ),
      'Keep today easy.',
    );
    const all = '2027-08-08, 2027-03-20, 2027-10-10';
    expect(
      completeLocalCoachCalendar(all, context, 'What are my goals?', l, 'en'),
      all,
    );
  });
}
