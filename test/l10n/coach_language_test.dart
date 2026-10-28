import 'package:fjelia/l10n/l10n_ext.dart';
import 'package:fjelia/models/chat_message.dart';
import 'package:fjelia/services/apple_coach_request.dart';
import 'package:fjelia/services/coach_language.dart';
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
      'Today is Wednesday 2026-10-28 (the phone clock). ',
    );
  });
}
