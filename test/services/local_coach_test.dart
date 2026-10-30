import 'dart:convert';
import 'dart:io';

import 'package:fjelia/l10n/l10n_ext.dart';
import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/services/local_model_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

class _LocalModel extends LocalModelService {
  _LocalModel({this.reply = 'Your training summary is ready.'});
  final String reply;
  List<Map<String, String>>? messages;
  String? failure;

  @override
  Future<String> generate(
    List<Map<String, String>> messages, {
    int maxTokens = 512,
  }) async {
    this.messages = messages;
    if (failure != null) throw LocalModelException(failure!);
    return reply;
  }
}

const _ready = AiCoachSettings(
  enabled: true,
  provider: AiProvider.localQwen,
  model: localQwenModelId,
  localModelAvailable: true,
  localModelInstalled: true,
);

void main() {
  tearDown(() => setActiveLocale(const Locale('en')));

  test('local chat keeps comparisons and the full season', () async {
    setActiveLocale(const Locale('de'));
    const context =
        '[Context:V4][Today:2026-10-29,Weekday:Thu,TimeNow:12:31]\n'
        '[Analysis:Stress,Date:2026-10-29,DaysAgo:0,Latest:20,Avg7d:24,Rule:lowerIsBetter,Verdict:better,Text:Stress 20 is below the 7-day average of 24; lower stress is better.]\n'
        '[Analysis:SleepDuration,Latest:7h,Avg7d:8h,Verdict:worse,Text:Sleep duration was 7 h; below the 7-day average of 8 h.]\n'
        '[Analysis:SleepVsNeed,Slept:7h,Need:8h,Verdict:slightlyShort,Text:Slept 7 h against a need of 8 h; shortfall is 1 h.]\n'
        '[Analysis:Form,TSB:-11,Band:tired,Verdict:worse,Text:Current form TSB is -11 points; accumulated training fatigue.]\n'
        '[Analysis:Energy,Latest:34,Avg7d:50,Rule:higherIsBetter,Verdict:clearlyWorse,Text:Energy 34 is below the average of 50; lower energy is worse.]\n'
        '[BP:Latest:2026-10-29,Sys:139,Dia:77,HR:55]\n'
        '[Sleep:Latest:2026-10-29,Dur:7h,Need:8h]\n'
        '[RaceGoal:Sport:running,DistKm:42.2,Date:2027-08-08,Target:4:00:00,Priority:A]\n'
        '[RaceGoal:Sport:cycling_road,DistKm:200,Date:2027-03-20,Target:none,Priority:B]\n'
        '[RaceGoal:Sport:running,DistKm:21.1,Date:2027-10-10,Target:1:50:00,Priority:C]';
    final rawPath = Platform.environment['FJELIA_QWEN_CHAT_REPLY'];
    final local = _LocalModel(
      reply: rawPath == null
          ? 'Der Blutzuckerspiegel ist 34, was unter dem Durchschnitt von 50 liegt.'
          : File(rawPath).readAsStringSync(),
    );
    final reply = await AiCoachClient(localModel: local).send(_ready, [
      ChatMessage(
        text: 'Was sagen meine Werte über meine Erholung und Wettkampfziele?',
        isUser: true,
      ),
    ], context);
    expect(reply, contains(tr.coachDataFallback));
    expect(reply, contains('34 < 50'));
    expect(reply, isNot(contains('Blutzucker')));
    for (final date in ['2027-08-08', '2027-03-20', '2027-10-10']) {
      expect(reply, contains(date));
    }
    final prompt = local.messages!.last['content']!;
    expect(prompt, contains('Stress 20 is below the 7-day average of 24'));
    expect(prompt, contains('shortfall is 1 h'));
    expect(prompt, contains('3 listed goals'));
    for (final date in ['2027-08-08', '2027-03-20', '2027-10-10']) {
      expect(prompt, contains(date));
    }
    final fixture = Platform.environment['FJELIA_QWEN_CHAT_FIXTURE'];
    if (fixture != null) {
      File(fixture).writeAsStringSync(
        jsonEncode({'messages': local.messages, 'maxTokens': 512}),
      );
    }
  });

  test(
    'Qwen needs compatible hardware and downloaded weights, not an API key',
    () {
      expect(_ready.hasApiKey, isFalse);
      expect(_ready.ready, isTrue);
      expect(_ready.readyForBriefing, isTrue);
      expect(_ready.usesOnDeviceBriefing, isTrue);
      expect(_ready.copyWith(localModelInstalled: false).ready, isFalse);
      expect(_ready.copyWith(localModelAvailable: false).ready, isFalse);
      expect(_ready.copyWith(enabled: false).readyForBriefing, isFalse);
    },
  );

  test('chat uses local inference without consent or cloud HTTP', () async {
    final local = _LocalModel();
    final client = AiCoachClient(
      localModel: local,
      client: MockClient(
        (_) async => fail('Local health data must not go to HTTP'),
      ),
    );
    final result = await client.send(
      _ready,
      [ChatMessage(text: 'Review my training.', isUser: true)],
      '[Activity:2026-10-28,Sport:run,Min:40,AvgHR:138]\n[DataStatus:MissingRecord:Unknown]',
    );
    expect(result, 'Your training summary is ready.');
    expect(local.messages!.last['content'], contains('138'));
    expect(local.messages!.last['content'], contains('Review my training.'));
    expect(local.messages!.first['content'], contains('DO NOT invent'));
  });

  test('all app languages are passed to the local model', () async {
    const names = {
      'en': 'British English',
      'de': 'German',
      'fr': 'French',
      'it': 'Italian',
      'es': 'Spanish',
      'ca': 'Catalan',
      'nb': 'Norwegian Bokmål',
      'sk': 'Slovak',
      'fi': 'Finnish',
      'da': 'Danish',
    };
    final local = _LocalModel();
    final client = AiCoachClient(localModel: local);
    for (final entry in names.entries) {
      setActiveLocale(Locale(entry.key));
      await client.send(_ready, [
        ChatMessage(text: 'Training?', isUser: true),
      ], '');
      expect(local.messages!.first['content'], contains(entry.value));
    }
  });

  test(
    'chat and briefings use the chosen 4B backend without a cloud request',
    () async {
      final small = _LocalModel();
      final large = _LocalModel();
      final selected = <String>[];
      final client = AiCoachClient(
        localModelFor: (id) {
          selected.add(id);
          return id == localQwen4bModelId ? large : small;
        },
        client: MockClient(
          (_) async => fail('Local inference must not use HTTP'),
        ),
        appleSender: (_) async => fail('Local inference must not use Apple'),
      );
      final settings = _ready.copyWith(model: localQwen4bModelId);
      await client.send(settings, [
        ChatMessage(text: 'Training?', isUser: true),
      ], '');
      await client.sendBriefing(settings, '');
      expect(selected, [localQwen4bModelId, localQwen4bModelId]);
      expect(large.messages, isNotNull);
      expect(small.messages, isNull);
    },
  );

  test(
    'briefings remain local even with a saved Apple briefing override',
    () async {
      final local = _LocalModel();
      final client = AiCoachClient(
        localModel: local,
        client: MockClient(
          (_) async => fail('No cloud fallback for local briefings'),
        ),
        appleSender: (_) async => fail('Qwen selection must not call Apple'),
      );
      await client.sendBriefing(
        _ready.copyWith(appleIntelligenceForBriefing: true),
        '',
      );
      expect(local.messages, isNotNull);
    },
  );

  test(
    'local errors produce a translated message without cloud fallback',
    () async {
      setActiveLocale(const Locale('de'));
      final local = _LocalModel()..failure = 'generation';
      final client = AiCoachClient(
        localModel: local,
        client: MockClient((_) async => fail('No cloud fallback')),
      );
      await expectLater(
        client.send(_ready, [ChatMessage(text: 'Training?', isUser: true)], ''),
        throwsA(
          isA<AiCoachException>().having(
            (e) => e.message,
            'message',
            tr.localModelCouldNotAnswer,
          ),
        ),
      );
    },
  );
}
