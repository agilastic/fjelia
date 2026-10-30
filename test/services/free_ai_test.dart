import 'dart:convert';

import 'package:fjelia/config/free_ai.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia_service/fjelia_service.dart' as service;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _store = AiCoachSettingsStore(freeAiApiKey: 'test-free-ai-key');
const _free = AiCoachSettings(
  provider: AiProvider.freeAi,
  model: 'default',
  hasApiKey: true,
  enabled: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  ProviderContainer settingsContainer({
    Future<bool> Function()? availability,
    AiCoachSettingsStore store = _store,
  }) {
    final container = ProviderContainer(
      overrides: [
        aiCoachSettingsStoreProvider.overrideWithValue(store),
        appleIntelligenceAvailabilityProvider.overrideWithValue(
          availability ?? () async => false,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('provider selection', () {
    test('available Apple Intelligence remains the default', () async {
      final container = settingsContainer(availability: () async => true);
      final settings = await container.read(aiCoachSettingsProvider.future);
      expect(settings.provider, AiProvider.appleIntelligence);
      expect(settings.model, 'on-device');
      expect(settings.ready, isTrue);
    });

    test('unavailable Apple Intelligence selects ready Free AI', () async {
      final container = settingsContainer();
      final settings = await container.read(aiCoachSettingsProvider.future);
      expect(settings.provider, AiProvider.freeAi);
      expect(settings.model, 'default');
      expect(settings.enabled, isTrue);
      expect(settings.ready, isTrue);
      expect(settings.readyForBriefing, isTrue);
      expect(settings.usesOnDeviceBriefing, isFalse);
      expect(settings.provider.isLocal, isFalse);
      expect(settings.provider.requiresUserApiKey, isFalse);
      expect(
        await const FlutterSecureStorage().read(key: 'ai_coach_provider'),
        isNull,
        reason: 'The automatic fallback must not replace the local default',
      );
    });

    test('Apple default returns when it becomes available', () async {
      var available = false;
      final container = settingsContainer(availability: () async => available);
      expect(
        (await container.read(aiCoachSettingsProvider.future)).provider,
        AiProvider.freeAi,
      );
      available = true;
      container.invalidate(aiCoachSettingsProvider);
      expect(
        (await container.read(aiCoachSettingsProvider.future)).provider,
        AiProvider.appleIntelligence,
      );
    });

    test('availability errors also offer Free AI', () async {
      final container = settingsContainer(
        availability: () async => throw StateError('Native API unavailable'),
      );
      expect(
        (await container.read(aiCoachSettingsProvider.future)).provider,
        AiProvider.freeAi,
      );
    });

    test(
      'saved Apple choice falls back without automatic cloud briefings',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'ai_coach_provider': 'appleIntelligence',
          'ai_apple_briefing': 'true',
        });
        final container = settingsContainer();
        final settings = await container.read(aiCoachSettingsProvider.future);
        expect(settings.provider, AiProvider.freeAi);
        expect(settings.appleIntelligenceForBriefing, isFalse);
        expect(settings.usesOnDeviceBriefing, isFalse);
        expect(
          await const FlutterSecureStorage().read(key: 'ai_coach_provider'),
          'appleIntelligence',
        );
      },
    );

    test(
      'an explicit Free AI choice survives Apple availability and reload',
      () async {
        final container = settingsContainer(availability: () async => true);
        await container.read(aiCoachSettingsProvider.future);
        await container
            .read(aiCoachSettingsProvider.notifier)
            .setProvider(AiProvider.freeAi);
        container.invalidate(aiCoachSettingsProvider);
        final settings = await container.read(aiCoachSettingsProvider.future);
        expect(settings.provider, AiProvider.freeAi);
        expect(settings.ready, isTrue);
        expect((await _store.load()).provider, AiProvider.freeAi);
      },
    );

    test('saved personal cloud configuration is preserved', () async {
      FlutterSecureStorage.setMockInitialValues({
        'ai_coach_provider': 'openai',
        'ai_coach_model': 'gpt-4o-mini',
        'ai_coach_api_key_openai': 'personal-key',
      });
      final container = settingsContainer(
        availability: () async => fail('Do not override a saved provider'),
      );
      final settings = await container.read(aiCoachSettingsProvider.future);
      expect(settings.provider, AiProvider.openai);
      expect(settings.model, 'gpt-4o-mini');
      expect(settings.ready, isTrue);
      expect(await _store.readApiKey(AiProvider.openai), 'personal-key');
    });

    test('a disabled coach stays disabled after the fallback', () async {
      FlutterSecureStorage.setMockInitialValues({'ai_coach_enabled': 'false'});
      final container = settingsContainer();
      final settings = await container.read(aiCoachSettingsProvider.future);
      expect(settings.provider, AiProvider.freeAi);
      expect(settings.enabled, isFalse);
      expect(settings.ready, isFalse);
      expect(settings.readyForBriefing, isFalse);
    });

    test('a build without Free AI credentials cannot send', () async {
      final container = settingsContainer(
        store: const AiCoachSettingsStore(freeAiApiKey: ''),
      );
      final settings = await container.read(aiCoachSettingsProvider.future);
      expect(settings.provider, AiProvider.freeAi);
      expect(settings.hasApiKey, isFalse);
      expect(settings.ready, isFalse);
      expect(settings.readyForBriefing, isFalse);
    });

    test('switching providers clears the prior chat session consent', () async {
      final container = settingsContainer(availability: () async => true);
      await container.read(aiCoachSettingsProvider.future);
      container.read(aiCoachSessionConsentProvider.notifier).state = true;
      await container
          .read(aiCoachSettingsProvider.notifier)
          .setProvider(AiProvider.freeAi);
      expect(container.read(aiCoachSessionConsentProvider), isFalse);
    });

    test(
      'background refresh does not gather Free AI health context or send it',
      () async {
        var contextReads = 0;
        final container = ProviderContainer(
          overrides: [
            aiContextToonBuilderProvider.overrideWith((_) {
              contextReads++;
              throw StateError(
                'Background cloud briefing must not read health data',
              );
            }),
            aiCoachClientProvider.overrideWith(
              (_) =>
                  throw StateError('Background cloud briefing must not send'),
            ),
          ],
        );
        addTearDown(container.dispose);
        final notifierProvider =
            StateNotifierProvider<AiBriefingNotifier, AsyncValue<String?>>(
              (ref) => AiBriefingNotifier(ref, AiBriefingPeriod.morning),
            );
        final notifier = container.read(notifierProvider.notifier);
        await notifier.load(
          _free.copyWith(appleIntelligenceForBriefing: true),
          force: true,
        );
        expect(contextReads, 0);
        final state = container.read(notifierProvider);
        expect(state.hasError, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.valueOrNull, isNull);
      },
    );
  });

  group('Free AI requests', () {
    test(
      'default build access comes from the optional service package',
      () async {
        const store = AiCoachSettingsStore();
        final key = await store.readApiKey(AiProvider.freeAi);
        final packagedKey = service.freeAiApiKey.trim();
        // Compare without putting a real credential in test failure output.
        expect(key == (packagedKey.isEmpty ? null : packagedKey), isTrue);
        if (!service.hasServicePackage) expect(key == null, isTrue);
        await store.saveProvider(AiProvider.freeAi);
        expect(
          (await store.load()).ready,
          service.hasServicePackage &&
              const String.fromEnvironment('FREE_AI_API_KEY').trim().isNotEmpty,
        );
      },
    );

    test('uses the build credential without storing a personal key', () async {
      await _store.saveProvider(AiProvider.freeAi);
      await _store.saveModel('stale-model');
      final settings = await _store.load();
      expect(settings.model, 'default');
      expect(settings.ready, isTrue);
      expect(await _store.readApiKey(AiProvider.freeAi), 'test-free-ai-key');
      expect(
        await const FlutterSecureStorage().read(key: 'ai_coach_api_key_freeAi'),
        isNull,
      );
    });

    test('chat sends to the supplied endpoint after consent', () async {
      late http.Request sent;
      final client = AiCoachClient(
        store: _store,
        client: MockClient((request) async {
          sent = request;
          return http.Response(
            jsonEncode({
              'model': 'default',
              'choices': [
                {
                  'message': {
                    'content': 'Your training summary is ready.',
                    'reasoning': 'Internal reasoning is not a chat answer.',
                  },
                },
              ],
            }),
            200,
          );
        }),
        appleSender: (_) async => fail('Free AI must not use Apple'),
        localModelFor: (_) => fail('Free AI must not use Qwen'),
      );
      final reply = await client.send(
        _free,
        [ChatMessage(text: 'Review my training.', isUser: true)],
        '[DataStatus:MissingRecord:Unknown]',
        AiConsentToken.confirmed(),
      );
      expect(reply, 'Your training summary is ready.');
      expect(sent.method, 'POST');
      expect(
        sent.url.toString(),
        'https://ai.fjelia.com/llm/v1/chat/completions',
      );
      expect(sent.headers['Authorization'], 'Bearer test-free-ai-key');
      final body = jsonDecode(sent.body) as Map;
      expect(body['model'], 'default');
      expect(body['user'], await _store.readFreeAiInstallationId());
      expect(sent.body, contains('Review my training.'));
      expect(sent.body, contains('HEALTH_CONTEXT:'));
      expect(sent.body, contains('ANSWER STANDARD'));
    });

    test('chat without cloud consent does not make an HTTP request', () async {
      var requests = 0;
      final client = AiCoachClient(
        store: _store,
        client: MockClient((_) async {
          requests++;
          return http.Response('{}', 200);
        }),
      );
      await expectLater(
        client.send(_free, [ChatMessage(text: 'Training?', isUser: true)], ''),
        throwsStateError,
      );
      expect(requests, 0);
      expect(
        await const FlutterSecureStorage().read(
          key: freeAiInstallationIdStorageKey,
        ),
        isNull,
      );
    });

    test('all four briefings use Free AI without a personal API key', () async {
      final sent = <http.Request>[];
      final client = AiCoachClient(
        store: _store,
        client: MockClient((request) async {
          sent.add(request);
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'Your training summary is ready.'},
                },
              ],
            }),
            200,
          );
        }),
        appleSender: (_) async => fail('Free AI must not use Apple'),
      );
      final settings = _free.copyWith(appleIntelligenceForBriefing: true);
      expect(settings.usesOnDeviceBriefing, isFalse);
      for (final send in [
        client.sendBriefing,
        client.sendLunchBriefing,
        client.sendAfternoonBriefing,
        client.sendEveningBriefing,
      ]) {
        expect(await send(settings, ''), 'Your training summary is ready.');
      }
      expect(sent, hasLength(4));
      final installationId = await _store.readFreeAiInstallationId();
      for (final request in sent) {
        expect(request.url.host, 'ai.fjelia.com');
        expect(request.headers['Authorization'], 'Bearer test-free-ai-key');
        expect((jsonDecode(request.body) as Map)['model'], 'default');
        expect((jsonDecode(request.body) as Map)['user'], installationId);
      }
    });

    test(
      'missing build credentials fail before HTTP even with stale readiness',
      () async {
        var requests = 0;
        final client = AiCoachClient(
          store: const AiCoachSettingsStore(freeAiApiKey: ''),
          client: MockClient((_) async {
            requests++;
            return http.Response('{}', 200);
          }),
        );
        await expectLater(
          client.send(
            _free,
            [ChatMessage(text: 'Training?', isUser: true)],
            '',
            AiConsentToken.confirmed(),
          ),
          throwsStateError,
        );
        expect(requests, 0);
      },
    );
  });
}
