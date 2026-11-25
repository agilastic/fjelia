import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia_core/services/apple_context_facts.dart';
import 'package:fjelia/services/apple_coach_request.dart';
import 'package:fjelia/services/briefing_brief.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the plugin throws when Apple's safety filter blocks a reply.
final blocked = Exception(
  'PlatformException(Response may contain sensitive or unsafe content, '
  'LanguageModelError, Stacktrace: [], null)',
);

const answer =
    'Your recovery is fine today. Keep the planned easy run and go to bed early.';

void main() {
  final settings = const AiCoachSettings(enabled: true);
  final messages = [ChatMessage(text: 'How am I today?', isUser: true)];
  const context =
      '[Activity:run,Min:47]\n[BP:Latest,Sys:987,Dia:654]\n[ECG:Key,Rhythm:sinus]';

  test('recognises the safety filter error', () {
    expect(isAppleGuardrailViolation(blocked), isTrue);
    expect(isAppleGuardrailViolation(Exception('Guardrail violation')), isTrue);
    expect(isAppleGuardrailViolation(Exception('Rate limited')), isFalse);
  });

  test('a block is retried with permissive guardrails first', () async {
    final requests = <AppleCoachRequest>[];
    final client = AiCoachClient(
      appleSender: (request) async {
        requests.add(request);
        if (requests.length == 1) throw blocked;
        return answer;
      },
    );
    expect(await client.send(settings, messages, context), answer);
    expect(requests.map((r) => r.permissive), [false, true]);
    // The permissive retry still has all the data.
    expect(requests[1].prompt, contains('987'));
  });

  test('a second block sends the same data in plain words', () async {
    final requests = <AppleCoachRequest>[];
    final client = AiCoachClient(
      appleSender: (request) async {
        requests.add(request);
        if (requests.length < 3) throw blocked;
        return answer;
      },
    );
    expect(await client.send(settings, messages, context), answer);
    expect(requests, hasLength(3));
    expect(requests[0].prompt, contains('Blood pressure'));
    final plain = requests[2];
    expect(plain.permissive, isTrue);
    // Every value is still there, only the clinical words are gone.
    expect(plain.prompt, contains('987/654'));
    expect(plain.prompt, contains('circulation reading'));
    expect(plain.prompt, contains('heart recording'));
    expect(plain.prompt, isNot(contains('Blood pressure')));
    expect(plain.prompt, isNot(contains('ECG')));
  });

  test('three blocks end the on-device attempt', () async {
    var calls = 0;
    final client = AiCoachClient(
      appleSender: (request) async {
        calls++;
        throw blocked;
      },
    );
    await expectLater(
      client.send(settings, messages, context),
      throwsA(isA<AiCoachException>()),
    );
    expect(calls, 3);
  });

  test('the neutral briefing keeps every finding in plain words', () {
    const brief = BriefingBrief(
      readiness: 'red',
      findings: ['spo2Low', 'respHigh', 'hrvLow'],
      away: 'illness',
      awayTomorrow: 'injury',
    );
    final plain = brief.toModelText();
    expect(plain, contains('low blood oxygen'));
    expect(plain, contains('Today the athlete is ill'));
    final neutral = brief.toModelText(neutral: true);
    expect(neutral, contains('oxygen level lower than usual'));
    expect(neutral, contains('breathing faster than usual at night'));
    expect(neutral, contains('low sleep HRV'));
    expect(neutral, contains('Today the athlete is unwell'));
    expect(neutral, contains('Tomorrow the athlete is hurt'));
    for (final word in ['blood oxygen', ' ill ', 'injured']) {
      expect(neutral, isNot(contains(word)), reason: word);
    }
  });

  test('plain words keep the figures', () {
    expect(
      applePlainFactLine(
        'ECG on 2026-11-20: atrial fibrillation suspected, 12 PVCs, '
        'blood pressure 132/84 mmHg, SpO2 94%; no diagnosis.',
      ),
      'heart recording on 2026-11-20: irregular rhythm suspected, 12 extra beats, '
      'circulation reading 132/84 mmHg, oxygen level 94%; no reading.',
    );
    expect(
      applePlainFactLine('Activity on run: 47 min.'),
      'Activity on run: 47 min.',
    );
  });

  test('the log names the topics, never the values', () {
    final topics = appleSensitiveTopics(
      const AppleCoachRequest(
        'For worrying symptoms advise seeing a doctor.',
        '[BP:Latest,Sys:987]\nlow blood oxygen',
      ),
    );
    expect(topics, ['blood pressure', 'blood oxygen']); // not the instructions
    expect(topics.join(), isNot(contains('987')));
  });
}
