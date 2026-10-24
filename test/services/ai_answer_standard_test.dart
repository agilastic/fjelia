import 'dart:convert';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/activity_coach_context.dart';
import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/services/ai_context_toon_builder.dart';
import 'package:fjelia/services/ai_data_status.dart';
import 'package:fjelia/services/apple_coach_request.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 24, 14, 30);
  DateTime ago(int days) => DateTime(now.year, now.month, now.day - days, 8);

  group('aiDataStatusLine', () {
    test('without any data everything is "none" and nothing is invented', () {
      final line = aiDataStatusLine(
        now: now,
        activityDays: const [],
        hrvDays: const [],
        sleepDays: const [],
        dailyDays: const [],
      );
      expect(line, contains('Activities(None)'));
      expect(line, contains('HRV(None)'));
      expect(line, contains('Gaps:HRV none/Sleep none/Daily none'));
      expect(line, endsWith(',MissingRecord:Unknown]'));
    });

    test('reports the newest record, coverage and the longest gap', () {
      final line = aiDataStatusLine(
        now: now,
        activityDays: [ago(2), ago(3), ago(20)],
        hrvDays: [for (var i = 0; i < 10; i++) ago(i)],
        sleepDays: [for (var i = 0; i < 28; i++) ago(i)],
        dailyDays: [for (var i = 0; i < 28; i++) ago(i)],
      );
      expect(
        line,
        contains(
          'Activities(Last:2026-10-22,DaysAgo:2,ActiveDays28:3/28,LongestGap:16d)',
        ),
      );
      // Days 4 to 19 ago have no activity: a gap of 16 days.
      expect(line, contains('HRV(Last:2026-10-24,DaysAgo:0,Days28:10/28)'));
      expect(line, contains('Sleep(Last:2026-10-24,DaysAgo:0,Days28:28/28)'));
      expect(line, isNot(contains('Gaps:')));
    });

    test('flags a metric that is two or more days old as a gap', () {
      final line = aiDataStatusLine(
        now: now,
        activityDays: [ago(0)],
        hrvDays: [ago(1)],
        sleepDays: [ago(3)],
        dailyDays: [ago(0)],
      );
      expect(line, contains('Gaps:Sleep 3d'));
      expect(line, isNot(contains('HRV 1d')));
    });
  });

  group('contexts carry the status', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('the daily context states what is on record', () async {
      final today = DateTime.now();
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'a1',
              name: 'Run',
              type: 'running',
              startDate: today.subtract(const Duration(days: 4)),
              durationSeconds: 3000,
            ),
          );
      final toon = await AiContextToonBuilder(db).build(null, '', null);
      final status = toon
          .split('\n')
          .firstWhere((l) => l.startsWith('[DataStatus:'));
      expect(status, contains('Activities(Last:'));
      expect(status, contains('DaysAgo:4'));
      expect(status, contains('HRV(None)'));
      expect(status, contains('MissingRecord:Unknown'));
    });

    test('an activity chat states how long ago the previous activity was', () {
      ActivityRecord act(String id, DateTime at) => ActivityRecord(
        id: 0,
        activityId: id,
        name: id,
        type: 'cycling',
        startDate: at,
        durationSeconds: 3600,
        source: 'garmin',
      );
      final target = act('t', DateTime(2026, 10, 22, 14));
      final toon = ActivityCoachContextBuilder.buildFrom(target, [
        act('old', DateTime(2026, 8, 23, 9)),
        target,
      ]);
      expect(
        toon,
        contains(
          '[DataStatus:PreviousActivity:2026-08-23,DaysBefore:60,MissingRecord:Unknown]',
        ),
      );
      final first = ActivityCoachContextBuilder.buildFrom(target, [target]);
      expect(first, contains('PreviousActivity:NoneInLoadedHistory'));
    });
  });

  group('answer standard reaches every provider', () {
    const context =
        '[Context:V4]\n[DataStatus:Activities(None),MissingRecord:Unknown]';

    test('Apple Intelligence gets the short standard and keeps the status', () {
      final request = AppleCoachRequest.build(
        [ChatMessage(text: 'Was soll ich heute tun?', isUser: true)],
        [
          '[Context:V4]',
          for (var i = 0; i < 60; i++) '[Filler:$i,${'x' * 40}]',
          '[DataStatus:Activities(None),MissingRecord:Unknown]',
        ].join('\n'),
      );
      expect(request.instructions, contains('Missing records mean unknown'));
      // The status line is kept first and reads as a sentence for the model.
      expect(request.prompt, contains('A missing record means unknown'));
      expect(request.inputBytes, lessThanOrEqualTo(3000));
    });

    Future<String> systemPromptSent(AiProvider provider) async {
      FlutterSecureStorage.setMockInitialValues({
        'ai_coach_api_key_${provider.name}': 'test-key',
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
          AiCoachSettings(
            provider: provider,
            model: 'test-model',
            hasApiKey: true,
            enabled: true,
            consentMode: AiConsentMode.session,
          ),
          [ChatMessage(text: 'Hallo', isUser: true)],
          context,
        );
      } catch (_) {
        // The empty reply is not a valid answer; only the request matters.
      }
      return jsonEncode(jsonDecode(body));
    }

    for (final provider in [
      AiProvider.openai,
      AiProvider.anthropic,
      AiProvider.gemini,
      AiProvider.mistral,
      AiProvider.deepseek,
    ]) {
      test('${provider.name} request carries the answer standard', () async {
        final sent = await systemPromptSent(provider);
        expect(sent, contains('ANSWER STANDARD'));
        expect(sent, contains('A missing record means unknown'));
      });
    }
  });
}
