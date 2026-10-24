import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const store = AiCoachSettingsStore();

  test(
    'a fresh install defaults to Apple Intelligence, no key needed',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final s = await store.load();
      expect(s.provider, defaultAiProvider);
      expect(defaultAiProvider, AiProvider.appleIntelligence); // iOS/macOS
      expect(s.model, 'on-device');
      expect(s.ready, isTrue);
    },
  );

  test(
    'Mistral without a key (old demo mode) moves to the default once',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'ai_coach_provider': 'mistral',
        'ai_coach_model': 'mistral-medium-latest',
      });
      final s = await store.load();
      expect(s.provider, AiProvider.appleIntelligence);
      // Choosing Mistral afterwards (before entering a key) sticks.
      await store.saveProvider(AiProvider.mistral);
      final again = await store.load();
      expect(again.provider, AiProvider.mistral);
      expect(again.hasApiKey, isFalse);
      expect(again.ready, isFalse);
    },
  );

  test('Mistral with the user\'s own key stays Mistral', () async {
    FlutterSecureStorage.setMockInitialValues({
      'ai_coach_provider': 'mistral',
      'ai_coach_api_key_mistral': 'my-own-key',
    });
    final s = await store.load();
    expect(s.provider, AiProvider.mistral);
    expect(s.hasApiKey, isTrue);
    expect(s.ready, isTrue);
    expect(await store.readApiKey(AiProvider.mistral), 'my-own-key');
  });

  test('Apple Intelligence is not ready where it cannot run', () {
    const s = AiCoachSettings(enabled: true, onDeviceAvailable: false);
    expect(s.provider, AiProvider.appleIntelligence);
    expect(s.ready, isFalse);
  });
}
