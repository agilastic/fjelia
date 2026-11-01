import 'dart:convert';

import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const instructions = 'Reply with JSON only: {"version":1,"changes":[]}';

  test('a cloud planning request carries only its own JSON rules', () async {
    FlutterSecureStorage.setMockInitialValues({});
    Map? sent;
    final client = AiCoachClient(
      store: const AiCoachSettingsStore(freeAiApiKey: 'k'),
      client: MockClient((r) async {
        sent = jsonDecode(r.body) as Map;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': '{"version":1,"changes":[]}'},
              },
            ],
          }),
          200,
        );
      }),
    );
    final reply = await client.sendPlanning(
      const AiCoachSettings(
        provider: AiProvider.freeAi,
        model: 'free',
        hasApiKey: true,
        enabled: true,
      ),
      instructions,
      '{"today":"2026-11-02"}',
      'Context: Today: 2026-11-02',
      AiConsentToken.confirmed(),
    );
    expect(reply, '{"version":1,"changes":[]}');
    final system = (sent!['messages'] as List).first['content'] as String;
    expect(system, startsWith(instructions));
    expect(system, contains('DATE:'));
    // The prose rules of chat and briefings would turn the answer into text.
    expect(system, isNot(contains('BRIEFING RULES')));
    expect(system, isNot(contains('ANSWER STANDARD')));
    expect(system, isNot(contains('\u0000')));
  });

  test('on the device the instructions reach the model unchanged', () async {
    String? got;
    final client = AiCoachClient(
      appleSender: (r) async {
        got = r.instructions;
        return ' {"version":1,"changes":[]} ';
      },
    );
    final reply = await client.sendPlanning(
      const AiCoachSettings(enabled: true),
      instructions,
      '{"today":"2026-11-02"}',
      '',
    );
    expect(reply, '{"version":1,"changes":[]}');
    expect(got, startsWith(instructions));
    expect(got, isNot(contains('briefing')));
  });
}
