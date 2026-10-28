import 'package:fjelia/l10n/l10n_ext.dart';
import 'package:fjelia/models/chat_message.dart';
import 'package:fjelia/services/apple_coach_request.dart';
import 'package:fjelia/services/briefing_brief.dart';
import 'package:fjelia/services/coach_language.dart';
import 'package:fjelia/services/coach_tasks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => setActiveLocale(const Locale('en')));

  test('the coach answers in the chosen app language', () {
    setActiveLocale(const Locale('de'));
    expect(coachLanguageName(), 'German');
    expect(coachLanguageDirective(), contains('German'));
    expect(coachLanguageDirective(chat: true), contains('writes in another'));
    expect(coachLanguageDirective(), isNot(contains('writes in another')));
    expect(coachLocaleTag(), 'de_DE');

    final request = AppleCoachRequest.build(
      [ChatMessage(text: 'Wie erhole ich mich?', isUser: true)],
      'HRV:50',
      locale: coachLocaleTag(),
    );
    expect(request.instructions, contains('Reply in German.'));
    expect(request.instructions, contains('de_DE'));
  });

  test('every app language has a name for the model', () {
    final names = {
      for (final code in [
        'en',
        'de',
        'fr',
        'it',
        'es',
        'ca',
        'nb',
        'sk',
        'fi',
        'da',
      ])
        coachLanguageName(code),
    };
    expect(names, hasLength(10));
  });

  test('the coach is told today from the phone clock', () {
    expect(
      coachTodayLine(DateTime(2026, 10, 28, 21, 8)),
      'Today is Wednesday 2026-10-28. ',
    );
  });

  test('a German chat is told firmly to answer in German, without an English example', () {
    setActiveLocale(const Locale('de'));
    final request = AppleCoachRequest.build([
      const ChatMessage(
        text: 'morgen geht es mit Training weiter',
        isUser: true,
      ),
    ], '[HRV:Latest:2026-10-28,Night:40ms]');
    expect(request.instructions, contains('Reply in German.'));
    expect(request.instructions, isNot(contains('Example.')));
    expect(request.prompt, contains('MUST write your answer in German'));
    expect(request.prompt, contains('NEVER in English'));
    final again = AppleCoachRequest.build(
      [
        const ChatMessage(
          text: 'morgen geht es mit Training weiter',
          isUser: true,
        ),
      ],
      '[HRV:Latest:2026-10-28,Night:40ms]',
      forceLanguage: true,
    );
    expect(again.instructions, contains('write ONLY in German'));
    // English stays as it was, with its example.
    setActiveLocale(const Locale('en'));
    final english = AppleCoachRequest.build([
      const ChatMessage(text: 'How am I?', isUser: true),
    ], '[HRV:Latest:2026-10-28,Night:40ms]');
    expect(english.instructions, contains('Example.'));
    expect(english.prompt, isNot(contains('NEVER in English')));
  });

  test('an English answer in a German app is recognised', () {
    const slip =
        "The HRV is 40 ms, which is below the athlete's average of 43 ms. This suggests poor recovery.";
    expect(looksWrongLanguage(slip, 'de'), isTrue);
    expect(looksWrongLanguage(slip, 'en'), isFalse);
    expect(
      looksWrongLanguage(
        'Deine HRV liegt mit 40 ms unter deinem Durchschnitt. Das spricht für eine schwächere Erholung.',
        'de',
      ),
      isFalse,
    );
  });

  test('the follow-up questions are in the app language', () {
    setActiveLocale(const Locale('de'));
    final q = followUpQuestions(CoachTask.evaluateActivity);
    expect(q, hasLength(3));
    expect(q.first, 'Was bedeutet das für meine nächsten Tage?');
    expect(q.join(' '), isNot(contains('What')));
    setActiveLocale(const Locale('en'));
    expect(
      followUpQuestions(CoachTask.evaluateActivity).first,
      'What does it mean for my next days?',
    );
  });
}
