import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/services/apple_coach_request.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the on-device model returned instead of an answer.
const echoed = '''HEALTH_CONTEXT (excerpt):

Activity: run, Min: 47, Km: 8.4, Pace: 5:34/km, AvgHR: 138, MaxHR: 171, Load: 126.

DataStatus: PreviousActivity: 2026-10-22, DaysBefore: 0, MissingRecord: Unknown.

Similar 30 days: run, N: 14, AvgMin: 53, AvgKm: 8.0.

Last 30 days: 2026-09-23..2026-10-22, Sessions: 32, ActiveDays: 20.''';

const answer =
    'This run was easy to moderate: 47 minutes at 138 bpm average. Keep tomorrow light, '
    'then add a longer session on the weekend.';

void main() {
  group('looksLikeContextEcho', () {
    test('recognises a repeated context', () {
      expect(looksLikeContextEcho(echoed), isTrue);
      expect(looksLikeContextEcho('HEALTH_CONTEXT'), isTrue);
      expect(
        looksLikeContextEcho('Sure. REFERENCE DATA (excerpt): Activity run'),
        isTrue,
      );
      // Without the heading, the tags of the context give it away.
      expect(
        looksLikeContextEcho(
          'DataStatus: ok. MissingRecord: Unknown. PreviousActivity: 2026-10-22.',
        ),
        isTrue,
      );
    });

    test('lets real answers through', () {
      expect(looksLikeContextEcho(answer), isFalse);
      expect(looksLikeContextEcho(''), isFalse);
      expect(
        looksLikeContextEcho(
          '- Pacing: The 132 bpm average shows disciplined aerobic work.\n'
          '- Training cost: 272 TSS is a substantial load.\n'
          '- What to carry forward: climb by effort.',
        ),
        isFalse,
      );
      // One tag name in a sentence is fine.
      expect(
        looksLikeContextEcho('Your last 30 days: 32 sessions, a solid month.'),
        isFalse,
      );
    });
  });

  group('Apple prompt', () {
    test('asks for an answer after the question and labels the data', () {
      final request = AppleCoachRequest.build(
        [
          ChatMessage(
            text: 'What does it mean for my next days?',
            isUser: true,
          ),
        ],
        '[Activity:run,Min:47]\n[DataStatus:Activities(None),MissingRecord:Unknown]',
      );
      expect(request.prompt, contains('REFERENCE DATA'));
      expect(request.prompt, isNot(contains('HEALTH_CONTEXT')));
      expect(request.prompt, endsWith(appleAnswerInstruction));
      expect(
        request.prompt.indexOf('Latest user message'),
        lessThan(request.prompt.indexOf(appleAnswerInstruction)),
      );
      expect(request.inputBytes, lessThanOrEqualTo(3000));
    });
  });

  group('on-device client', () {
    final settings = const AiCoachSettings(enabled: true);
    final messages = [ChatMessage(text: 'What now?', isUser: true)];
    final context = [
      '[Activity:run,Min:47]',
      for (var i = 0; i < 50; i++) '[Filler:$i,${'x' * 50}]',
    ].join('\n');

    test('a repeated context is retried with less data', () async {
      final sizes = <int>[];
      final client = AiCoachClient(
        appleSender: (request) async {
          sizes.add(request.inputBytes);
          return sizes.length == 1 ? echoed : answer;
        },
      );
      expect(await client.send(settings, messages, context), answer);
      expect(sizes, hasLength(2));
      expect(sizes[1], lessThan(sizes[0]));
      expect(sizes[1], lessThanOrEqualTo(2200));
    });

    test('a context repeated twice is reported instead of shown', () async {
      var calls = 0;
      final client = AiCoachClient(
        appleSender: (request) async {
          calls++;
          return echoed;
        },
      );
      await expectLater(
        client.send(settings, messages, context),
        throwsA(
          isA<AiCoachException>().having(
            (e) => e.message,
            'message',
            contains('could not produce a usable answer'),
          ),
        ),
      );
      expect(calls, 2);
    });

    test('a normal answer needs one request', () async {
      var calls = 0;
      final client = AiCoachClient(
        appleSender: (request) async {
          calls++;
          return answer;
        },
      );
      expect(await client.send(settings, messages, context), answer);
      expect(calls, 1);
    });
  });
}
