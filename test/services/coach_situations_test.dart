import 'dart:convert';

import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/services/apple_coach_request.dart';
import 'package:fjelia/services/coach_tasks.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The situations the coach has to handle, as fixed contexts. No model is
/// called: the tests pin what the model is given, so a change to a prompt
/// shows up as a failing test instead of as a worse answer weeks later.
class Situation {
  const Situation(this.name, this.context, this.question, this.task);
  final String name, context, question;
  final CoachTask task;
}

const planned =
    '[Session:Status:planned,Date:2026-10-24 Sat,Sport:running,Type:intervals,Duration:107min,TRIMP:126,Zone:Z1,Structure:10 min Warm-up>5x(4 min Interval,2 min Recovery)]';
const completed =
    '[Activity:2026-10-22 Thu,Sport:run,Min:47,Km:8.4,AvgHR:138,Load:126]\n'
    '[DataStatus:PreviousActivity:2026-10-21,DaysBefore:1,MissingRecord:Unknown]';

const situations = [
  Situation(
    'planned workout',
    '$planned\n[HRV:Latest:52ms,Avg7d:55ms]',
    'How do I execute this workout?',
    CoachTask.explainWorkout,
  ),
  Situation(
    'rest day',
    '[TodayWorkout:Status:rest_day]\n[Recovery:Score:41]',
    'Should I train today?',
    CoachTask.general,
  ),
  Situation(
    'gaps in the data',
    '[DataStatus:Activities(Last:2026-09-02,DaysAgo:52),Gaps:HRV none/Sleep none,MissingRecord:Unknown]',
    'Am I recovered?',
    CoachTask.general,
  ),
  Situation(
    'evaluate an activity',
    completed,
    'How did this session go?',
    CoachTask.evaluateActivity,
  ),
  Situation(
    'compare with similar sessions',
    '$completed\n[Compare:run,N:5,Min:47 vs 53,Load:126 vs 110]',
    'How does it compare with similar sessions?',
    CoachTask.evaluateActivity,
  ),
  Situation(
    'follow-up question',
    '[Session:Status:completed,Date:2026-10-22 Thu,Sport:running,Duration:46min]',
    'And what should I eat afterwards?',
    CoachTask.evaluateActivity,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('task detection', () {
    test('reads the task from the context', () {
      expect(coachTaskFor(planned), CoachTask.explainWorkout);
      expect(
        coachTaskFor('[Session:Status:skipped,Date:2026-10-24]'),
        CoachTask.explainWorkout,
      );
      expect(coachTaskFor(completed), CoachTask.evaluateActivity);
      expect(coachTaskFor('[Activities:run]'), CoachTask.general);
      expect(coachTaskFor(''), CoachTask.general);
    });
  });

  group('follow-up questions', () {
    test('at most three, from the task, without what was asked', () {
      final all = followUpQuestions(CoachTask.evaluateActivity);
      expect(all, hasLength(3));
      final rest = followUpQuestions(
        CoachTask.evaluateActivity,
        asked: [all.first.toUpperCase()],
      );
      expect(rest, hasLength(3));
      expect(rest, isNot(contains(all.first)));
      expect(followUpQuestions(CoachTask.general, max: 2), hasLength(2));
    });

    test('nothing is left when everything was asked', () {
      final every = followUpQuestions(CoachTask.explainWorkout, max: 99);
      expect(
        followUpQuestions(CoachTask.explainWorkout, asked: every),
        isEmpty,
      );
    });
  });

  group('the situations', () {
    for (final s in situations) {
      group(s.name, () {
        test('is recognised as ${s.task.name}', () {
          expect(coachTaskFor(s.context), s.task);
        });

        test('the Apple prompt stays small and keeps the rules', () {
          final request = AppleCoachRequest.build([
            ChatMessage(text: s.question, isUser: true),
          ], s.context);
          expect(request.inputBytes, lessThanOrEqualTo(3000));
          expect(request.instructions, contains('You MUST use only numbers'));
          expect(request.instructions, contains('DO NOT invent'));
          expect(request.prompt, endsWith(appleAnswerInstruction));
          expect(request.prompt, contains(s.question));
          // The model reads sentences, not the compact tags.
          expect(request.prompt, isNot(contains('[Session:')));
          expect(request.prompt, isNot(contains('[DataStatus:')));
          expect(request.prompt, isNot(contains('[Activity:')));
          final short = coachTaskTemplateShort(s.task);
          if (short.isEmpty) {
            expect(request.instructions, isNot(contains('This is about')));
          } else {
            expect(request.instructions, contains(short));
          }
        });

        test('the cloud prompt carries the structure of its task', () async {
          FlutterSecureStorage.setMockInitialValues({
            'ai_coach_api_key_openai': 'test-key',
          });
          late String body;
          final client = AiCoachClient(
            client: MockClient((request) async {
              body = request.body;
              return http.Response('{}', 200);
            }),
          );
          try {
            await client.send(
              const AiCoachSettings(
                provider: AiProvider.openai,
                model: 'test-model',
                hasApiKey: true,
                enabled: true,
                consentMode: AiConsentMode.session,
              ),
              [ChatMessage(text: s.question, isUser: true)],
              s.context,
            );
          } catch (_) {
            // Only the request matters.
          }
          final sent = jsonEncode(jsonDecode(body));
          expect(sent, contains('ANSWER STANDARD'));
          final template = jsonEncode(coachTaskTemplate(s.task));
          final inner = template.substring(1, template.length - 1);
          if (s.task == CoachTask.general) {
            expect(sent, isNot(contains('ANSWER STRUCTURE')));
          } else {
            expect(sent, contains(inner));
          }
        });
      });
    }

    test('gaps stay unknown in the Apple prompt', () {
      final request = AppleCoachRequest.build([
        ChatMessage(text: 'Am I recovered?', isUser: true),
      ], situations[2].context);
      expect(request.prompt, contains('A missing record means unknown'));
    });

    test('the comparison reaches the model as a sentence with both sides', () {
      final request = AppleCoachRequest.build([
        ChatMessage(text: 'How does it compare?', isUser: true),
      ], situations[4].context);
      expect(request.prompt, contains('against the average of 5 other run'));
      expect(request.prompt, contains('47 vs 53'));
    });

    test('an earlier question stays in the chat history', () {
      final request = AppleCoachRequest.build([
        ChatMessage(text: 'How did this session go?', isUser: true),
        ChatMessage(text: 'It was a solid aerobic run.', isUser: false),
        ChatMessage(text: situations[5].question, isUser: true),
      ], situations[5].context);
      expect(request.prompt, contains('User: How did this session go?'));
      expect(
        request.prompt,
        contains('Assistant: It was a solid aerobic run.'),
      );
      expect(request.prompt, contains(situations[5].question));
    });
  });

  test('the training status is worded as an estimate', () {
    final request = AppleCoachRequest.build([
      ChatMessage(text: 'Am I fit?', isUser: true),
    ], '[TrainingMonitor:CTL:52,ATL:61,TSB:-9,CurWeekH:6,PrevWeekH:7]');
    expect(request.prompt, contains('estimated by a model and not measured'));
    expect(request.prompt, contains('form (TSB) -9'));
  });
}
