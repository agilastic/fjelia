import 'dart:async';
import 'dart:convert';

import 'package:fjelia/config/free_ai.dart';
import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _store = AiCoachSettingsStore(freeAiApiKey: 'test-free-ai-key');
const _settings = AiCoachSettings(
  provider: AiProvider.freeAi,
  model: 'default',
  hasApiKey: true,
  enabled: true,
);

http.Response _reply() => http.Response(
  jsonEncode({
    'choices': [
      {
        'message': {'content': 'Training looks steady.'},
      },
    ],
  }),
  200,
);

Future<String> _send(AiCoachClient client) => client.send(
  _settings,
  [ChatMessage(text: 'Review my training.', isUser: true)],
  '[Context:V4]',
  AiConsentToken.confirmed(),
);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final status in [502, 503, 504]) {
    testWidgets('Free AI retries HTTP $status with the same approved request', (
      tester,
    ) async {
      final sent = <http.Request>[];
      final client = AiCoachClient(
        store: _store,
        client: MockClient((request) async {
          sent.add(request);
          return sent.length == 1
              ? http.Response('<html>Proxy Error</html>', status)
              : _reply();
        }),
      );
      final result = _send(client);
      await tester.pump();
      expect(sent, hasLength(1));
      await tester.pump(const Duration(milliseconds: 999));
      expect(sent, hasLength(1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(await result, 'Training looks steady.');
      expect(sent, hasLength(2));
      expect(sent[1].url, sent[0].url);
      expect(sent[1].body, sent[0].body);
      expect(sent[1].headers, sent[0].headers);
      expect(
        (jsonDecode(sent[1].body) as Map)['user'],
        startsWith('fjelia-install-'),
      );
      expect(
        (jsonDecode(sent[1].body) as Map)['messages'].where(
          (message) => message['role'] == 'user',
        ),
        hasLength(1),
      );
    });
  }

  testWidgets('three failed attempts stop and report the last proxy error', (
    tester,
  ) async {
    var calls = 0;
    final client = AiCoachClient(
      store: _store,
      client: MockClient((_) async {
        calls++;
        return http.Response('<html>Proxy Error $calls</html>', 502);
      }),
    );
    final result = expectLater(
      _send(client),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'last error',
          contains('Proxy Error 3'),
        ),
      ),
    );
    await tester.pump();
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 2);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(calls, 2);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, 3);
    await result;
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 3);
  });

  testWidgets('other HTTP failures are reported without retrying', (
    tester,
  ) async {
    final identities = <String>[];
    for (final status in [400, 401, 403, 429, 500]) {
      var calls = 0;
      final client = AiCoachClient(
        store: _store,
        client: MockClient((request) async {
          calls++;
          identities.add((jsonDecode(request.body) as Map)['user'] as String);
          return http.Response('Request rejected', status);
        }),
      );
      final result = expectLater(_send(client), throwsStateError);
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      await result;
      expect(calls, 1, reason: 'HTTP $status must not be retried');
    }
    expect(identities.toSet(), hasLength(1));
  });

  testWidgets('a dropped connection is retried', (tester) async {
    var calls = 0;
    final client = AiCoachClient(
      store: _store,
      client: MockClient((_) async {
        calls++;
        if (calls == 1) throw http.ClientException('Connection closed');
        return _reply();
      }),
    );
    final result = _send(client);
    await tester.pump();
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(await result, 'Training looks steady.');
    expect(calls, 2);
  });

  testWidgets('a stalled request times out and the next attempt can succeed', (
    tester,
  ) async {
    var calls = 0;
    final pending = Completer<http.Response>();
    final client = AiCoachClient(
      store: _store,
      client: MockClient((_) {
        calls++;
        return calls == 1 ? pending.future : Future.value(_reply());
      }),
    );
    final result = _send(client);
    await tester.pump();
    expect(calls, 1);
    await tester.pump(freeAiRequestTimeout);
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(await result, 'Training looks steady.');
    expect(calls, 2);
  });

  testWidgets('stalled requests also stop after three attempts', (
    tester,
  ) async {
    var calls = 0;
    final client = AiCoachClient(
      store: _store,
      client: MockClient((_) {
        calls++;
        return Completer<http.Response>().future;
      }),
    );
    final result = expectLater(_send(client), throwsA(isA<TimeoutException>()));
    await tester.pump();
    for (var attempt = 1; attempt <= 3; attempt++) {
      expect(calls, attempt);
      await tester.pump(freeAiRequestTimeout);
      if (attempt < 3) {
        await tester.pump(Duration(seconds: attempt));
      }
    }
    await result;
    expect(calls, 3);
  });

  testWidgets('all four Free AI briefings retry transient proxy errors', (
    tester,
  ) async {
    var calls = 0;
    final client = AiCoachClient(
      store: _store,
      client: MockClient((_) async {
        calls++;
        return calls.isOdd ? http.Response('Proxy Error', 502) : _reply();
      }),
    );
    for (final send in [
      client.sendBriefing,
      client.sendLunchBriefing,
      client.sendAfternoonBriefing,
      client.sendEveningBriefing,
    ]) {
      final result = send(_settings, '');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(await result, 'Training looks steady.');
    }
    expect(calls, 8);
  });

  testWidgets(
    'personal cloud providers retain their existing request behavior',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'ai_coach_api_key_openai': 'test-personal-key',
      });
      var calls = 0;
      late Map sentBody;
      final client = AiCoachClient(
        store: _store,
        client: MockClient((request) async {
          calls++;
          sentBody = jsonDecode(request.body) as Map;
          return http.Response('Proxy Error', 502);
        }),
      );
      final result = expectLater(
        client.send(
          _settings.copyWith(provider: AiProvider.openai, model: 'test-model'),
          [ChatMessage(text: 'Training?', isUser: true)],
          '',
          AiConsentToken.confirmed(),
        ),
        throwsStateError,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      await result;
      expect(calls, 1);
      expect(sentBody, isNot(contains('user')));
      expect(
        await const FlutterSecureStorage().read(
          key: freeAiInstallationIdStorageKey,
        ),
        isNull,
      );
    },
  );
}
