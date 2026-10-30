import 'package:fjelia/config/free_ai.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  const store = AiCoachSettingsStore();

  test('creates a random ID and reuses it after reopening settings', () async {
    final id = await store.readFreeAiInstallationId();
    expect(
      id,
      matches(
        r'^fjelia-install-[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ),
    );
    final reopened = AiCoachSettingsStore();
    expect(await reopened.readFreeAiInstallationId(), id);
    expect(
      await const FlutterSecureStorage().read(
        key: freeAiInstallationIdStorageKey,
      ),
      id,
    );
  });

  test(
    'concurrent first requests from different clients share one ID',
    () async {
      final ids = await Future.wait([
        for (var i = 0; i < 20; i++)
          AiCoachSettingsStore().readFreeAiInstallationId(),
      ]);
      expect(ids.toSet(), hasLength(1));
      expect(await store.readFreeAiInstallationId(), ids.first);
    },
  );

  test('fresh local storage gets a different ID', () async {
    final first = await store.readFreeAiInstallationId();
    FlutterSecureStorage.setMockInitialValues({});
    final second = await store.readFreeAiInstallationId();
    expect(second, isNot(first));
  });

  test(
    'invalid stored data is replaced instead of sent as an identity',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        freeAiInstallationIdStorageKey: 'invalid-account-value',
      });
      final id = await store.readFreeAiInstallationId();
      expect(id, startsWith('fjelia-install-'));
      expect(id, isNot(contains('invalid-account-value')));
      expect(await store.readFreeAiInstallationId(), id);
    },
  );

  test(
    'switching providers or API keys preserves the installation ID',
    () async {
      final id = await store.readFreeAiInstallationId();
      await store.saveProvider(AiProvider.openai);
      await store.saveApiKey(AiProvider.openai, 'test-personal-key');
      await store.saveProvider(AiProvider.freeAi);
      expect(await store.readFreeAiInstallationId(), id);
    },
  );
}
