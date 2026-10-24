import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/models/chat_message.dart';
import 'package:fjelia/services/apple_coach_request.dart';

void main() {
  test('language rejection is distinguished from context size and unknown failures', () {
    expect(
      appleCoachFailureMessage(
        Exception('unsupportedLanguageOrLocale: Unsupported language.'),
      ),
      contains('rejected the request’s language'),
    );
    expect(
      appleCoachFailureMessage(Exception('exceededContextWindowSize')),
      contains('shorter question'),
    );
    expect(
      appleCoachFailureMessage(Exception('native failure')),
      isNot(contains('native failure')),
    );
  });
  test('budgets instructions, history and context together; keeps latest question', () {
    final history = List.generate(
      80,
      (i) => ChatMessage(
        text: 'Old turn $i ${'training ' * 100}',
        isUser: i.isEven,
      ),
    );
    const question =
        'Review this activity: running, 45 minutes, average HR 138.';
    final request = AppleCoachRequest.build(
      [...history, const ChatMessage(text: question, isUser: true)],
      '${'[Activities:old:${'run ' * 500}]\n' * 100}[HRV:Latest:Night:42ms,RHR:47bpm]\n[Sleep:Latest:Dur:8h]',
    );
    expect(request.inputBytes, lessThanOrEqualTo(3000));
    expect(request.prompt, contains(question));
    expect(request.prompt, contains('Night:42ms'));
    expect(request.prompt, isNot(contains('Old turn 0 ')));
  });
  test('UTF8 budget handles multibyte characters without splitting values', () {
    final request = AppleCoachRequest.build([
      const ChatMessage(text: 'Wie war mein Lauf? 🏃', isUser: true),
    ], '[HRV:Latest:Night:42ms]\n${'[Notes:${'训练🏃' * 300}]\n' * 50}');
    expect(
      utf8.encode(request.instructions + request.prompt).length,
      lessThanOrEqualTo(3000),
    );
    expect(request.prompt, contains('Wie war mein Lauf? 🏃'));
    expect(request.prompt, isNot(contains('�')));
  });
  test(
    'briefing uses compact period instructions instead of cloud system prompt',
    () {
      final request = AppleCoachRequest.build(
        [const ChatMessage(text: 'Give me a briefing.', isUser: true)],
        '[TodayWorkout:Status:rest_day]',
        briefingInstructions:
            'Generate a short evening briefing. ${'long rules ' * 1000}',
      );
      expect(request.instructions, contains('evening'));
      expect(request.instructions, contains('rest_day'));
      expect(request.inputBytes, lessThanOrEqualTo(3000));
      expect(request.instructions, isNot(contains('long rules')));
    },
  );
  test('oversized user message gets a readable error rather than silent truncation', () {
    expect(
      () => AppleCoachRequest.build([
        ChatMessage(text: 'x' * 2000, isUser: true),
      ], ''),
      throwsA(isA<AiCoachException>()),
    );
  });

  test('adds a locale hint and strict mode keeps only core ASCII lines', () {
    const context = '[Date:2026-10-20]\n'
        '[HRV:Latest:52ms]\n'
        '[Weather:Leichter Regen, 12°C]\n'
        '[Notes:Morgenlauf am Fluss]';
    final messages = [
      ChatMessage(text: 'Vorher', isUser: true),
      ChatMessage(text: 'Give me my briefing.', isUser: true),
    ];
    final normal = AppleCoachRequest.build(messages, context, locale: 'en_DE');
    expect(normal.instructions, contains("The person's locale is en_DE."));
    expect(normal.prompt, contains('[Notes:Morgenlauf am Fluss]'));
    expect(normal.prompt, contains('User: Vorher'));

    final strict = AppleCoachRequest.build(messages, context, strict: true);
    expect(strict.prompt, contains('[HRV:Latest:52ms]'));
    expect(strict.prompt, contains('[Weather:Leichter Regen, 12C]'));
    expect(strict.prompt, isNot(contains('Morgenlauf')));
    expect(strict.prompt, isNot(contains('Vorher')));
    expect(strict.prompt, contains('Give me my briefing.'));
  });
}
