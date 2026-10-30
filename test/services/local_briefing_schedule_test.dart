import 'dart:convert';
import 'dart:io';

import 'package:fjelia/l10n/l10n_ext.dart';
import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/services/briefing_brief.dart';
import 'package:fjelia/services/local_model_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

class _Reply extends LocalModelService {
  _Reply(this.reply);
  final String reply;
  List<Map<String, String>>? messages;

  @override
  Future<String> generate(
    List<Map<String, String>> messages, {
    int maxTokens = 512,
  }) async {
    this.messages = messages;
    return reply;
  }
}

const _settings = AiCoachSettings(
  provider: AiProvider.localQwen,
  model: localQwenModelId,
  enabled: true,
  localModelAvailable: true,
  localModelInstalled: true,
);
const _brief = BriefingBrief(
  readiness: 'yellow',
  findings: ['sleepShort'],
  done: ['walking/20'],
  today: ['running/45', 'strength/30'],
  tomorrow: ['cycling_road/60'],
);

String _context() {
  final today = DateTime.now().toIso8601String().split('T').first;
  return '[Context:V4][Today:$today,Weekday:Thu,TimeNow:10:00]\n'
      '${_brief.toLine()}\n'
      '[TodayWorkout:Status:planned,Source:plan,SessionCount:2,GarminScheduled:0,PlanSessions:2]';
}

AiCoachClient _client(_Reply model) => AiCoachClient(
  localModel: model,
  client: MockClient((_) async => fail('A local briefing must not use HTTP')),
);

void main() {
  tearDown(() => setActiveLocale(const Locale('en')));

  test(
    'a local daily briefing cannot omit two still planned sessions',
    () async {
      setActiveLocale(const Locale('de'));
      final rawPath = Platform.environment['FJELIA_QWEN_SCHEDULE_REPLY'];
      final raw = rawPath == null
          ? 'Heute hast du keine Trainingsabsicht. Nutze den Tag zur Erholung.'
          : File(rawPath).readAsStringSync();
      final model = _Reply(raw);
      final reply = await _client(model).sendBriefing(_settings, _context());
      expect(reply, contains('Für heute sind 2 Einheiten geplant.'));
      expect(reply, isNot(contains('keine Trainingsabsicht')));
      expect(
        model.messages!.first['content'],
        contains('Für heute sind 2 Einheiten geplant.'),
      );
      expect(model.messages!.last['content'], contains('2 scheduled sessions'));
      expect(
        model.messages!.last['content'],
        contains('running 45 min and strength 30 min'),
      );
      expect(
        model.messages!.last['content'],
        contains('Done today: walking 20 min'),
      );
      final fixture = Platform.environment['FJELIA_QWEN_SCHEDULE_FIXTURE'];
      if (fixture != null) {
        File(fixture).writeAsStringSync(
          jsonEncode({
            'messages': model.messages,
            'expectedSentence': tr.briefPlannedTodayCount(2),
          }),
        );
      }
    },
  );

  test('a model reply that preserves the plan can be displayed', () async {
    setActiveLocale(const Locale('de'));
    const text =
        'Dein Schlaf war kurz. Für heute sind 2 Einheiten geplant. '
        'Halte beide locker und füge keine zusätzliche Intensität hinzu.';
    expect(
      await _client(_Reply(text)).sendBriefing(_settings, _context()),
      text,
    );
  });

  test(
    'the plan remains correct in every app language when Qwen omits it',
    () async {
      for (final locale in [
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
      ]) {
        setActiveLocale(Locale(locale));
        final reply = await _client(
          _Reply('Rest today.'),
        ).sendBriefing(_settings, _context());
        expect(reply, contains(tr.briefPlannedTodayCount(2)), reason: locale);
      }
    },
  );
}
