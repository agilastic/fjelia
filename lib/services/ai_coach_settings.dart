import 'dart:io' show Platform;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AiProvider {
  mistral,
  openai,
  anthropic,
  gemini,
  deepseek,
  appleIntelligence,
}

enum AiConsentMode { everyMessage, session }

/// How the daily briefing is produced. `static_` is the rule-based text.
enum BriefingMode { ai, static_, none }

extension AiProviderLabel on AiProvider {
  List<String> get models => switch (this) {
    AiProvider.mistral => const [
      'mistral-small-latest',
      'mistral-medium-latest',
      'mistral-large-latest',
    ],
    AiProvider.openai => const [
      'gpt-4o-mini',
      'gpt-4o',
      'gpt-4.1-mini',
      'gpt-4.1',
      'o4-mini',
      'o3',
    ],
    AiProvider.anthropic => const [
      'claude-haiku-5-5',
      'claude-sonnet-5-5',
      'claude-opus-5-5',
      'claude-fable-5-1',
    ],
    AiProvider.gemini => const [
      'gemini-2.0-flash',
      'gemini-2.0-flash-lite',
      'gemini-2.5-flash-preview-05-20',
      'gemini-2.5-pro-preview-06-05',
    ],
    AiProvider.deepseek => const ['deepseek-chat', 'deepseek-reasoner'],
    AiProvider.appleIntelligence => const ['on-device'],
  };

  String get defaultModel => switch (this) {
    AiProvider.mistral => 'mistral-medium-latest',
    AiProvider.openai => 'gpt-4o-mini',
    AiProvider.anthropic => 'claude-haiku-5-5',
    AiProvider.gemini => 'gemini-2.0-flash',
    AiProvider.deepseek => 'deepseek-chat',
    AiProvider.appleIntelligence => 'on-device',
  };
}

/// Apple Intelligence runs on-device (iOS/macOS 26+), so it is the default
/// where it exists; elsewhere the user brings a key for a cloud provider.
AiProvider get defaultAiProvider => Platform.isIOS || Platform.isMacOS
    ? AiProvider.appleIntelligence
    : AiProvider.mistral;

class AiCoachSettings {
  const AiCoachSettings({
    this.provider = AiProvider.appleIntelligence,
    this.model = 'on-device',
    this.hasApiKey = false,
    this.enabled = false,
    this.consentMode = AiConsentMode.everyMessage,
    this.briefingMode = BriefingMode.ai,
    this.appleIntelligenceForBriefing = false,
    this.onDeviceAvailable = true,
  });

  final AiProvider provider;
  final String model;
  final bool hasApiKey;
  final bool enabled;
  final AiConsentMode consentMode;
  final BriefingMode briefingMode;
  final bool appleIntelligenceForBriefing;

  /// Whether the on-device model can run here (device, OS, Apple
  /// Intelligence switched on, language). Only relevant for Apple
  /// Intelligence.
  final bool onDeviceAvailable;

  bool get ready =>
      enabled &&
      model.trim().isNotEmpty &&
      (provider == AiProvider.appleIntelligence
          ? onDeviceAvailable
          : hasApiKey);

  bool get usesOnDeviceBriefing =>
      provider == AiProvider.appleIntelligence || appleIntelligenceForBriefing;

  bool get readyForBriefing =>
      briefingMode == BriefingMode.ai && (usesOnDeviceBriefing || ready);

  AiCoachSettings copyWith({
    bool? appleIntelligenceForBriefing,
    BriefingMode? briefingMode,
    AiConsentMode? consentMode,
    bool? enabled,
    bool? hasApiKey,
    String? model,
    AiProvider? provider,
    bool? onDeviceAvailable,
  }) {
    return AiCoachSettings(
      provider: provider ?? this.provider,
      model: model ?? this.model,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      enabled: enabled ?? this.enabled,
      consentMode: consentMode ?? this.consentMode,
      briefingMode: briefingMode ?? this.briefingMode,
      appleIntelligenceForBriefing:
          appleIntelligenceForBriefing ?? this.appleIntelligenceForBriefing,
      onDeviceAvailable: onDeviceAvailable ?? this.onDeviceAvailable,
    );
  }
}

class AiCoachSettingsStore {
  const AiCoachSettingsStore();

  static const _storage = FlutterSecureStorage();

  static String _apiKeyKey(AiProvider p) => 'ai_coach_api_key_${p.name}';

  static AiProvider _providerFromName(String? name) => AiProvider.values
      .firstWhere((p) => p.name == name, orElse: () => defaultAiProvider);

  static BriefingMode _briefingModeFromName(String? name) => BriefingMode.values
      .firstWhere((m) => m.name == name, orElse: () => BriefingMode.ai);

  /// Mistral without a key used to run on a shared demo key. That is gone:
  /// once, move such installs to the default provider.
  Future<void> _migrateFromDemoMode() async {
    if (await _storage.read(key: 'ai_demo_removed_v1') != null) return;
    await _storage.write(key: 'ai_demo_removed_v1', value: '1');
    final saved = await _storage.read(key: 'ai_coach_provider');
    if (saved != AiProvider.mistral.name) return;
    final key = (await _storage.read(
      key: _apiKeyKey(AiProvider.mistral),
    ))?.trim();
    if (key != null && key.isNotEmpty) return;
    final target = defaultAiProvider;
    await _storage.write(key: 'ai_coach_provider', value: target.name);
    await _storage.write(key: 'ai_coach_model', value: target.defaultModel);
  }

  Future<AiCoachSettings> load() async {
    await _migrateFromDemoMode();
    final provider = _providerFromName(
      await _storage.read(key: 'ai_coach_provider'),
    );
    final model = await _storage.read(key: 'ai_coach_model');
    final key = (await _storage.read(key: _apiKeyKey(provider)))?.trim();
    final hasKey = key != null && key.isNotEmpty;
    final enabled = await _storage.read(key: 'ai_coach_enabled') != 'false';
    final consent =
        await _storage.read(key: 'ai_coach_consent_mode') == 'session'
        ? AiConsentMode.session
        : AiConsentMode.everyMessage;
    final trimmed = model?.trim();
    return AiCoachSettings(
      provider: provider,
      model: trimmed == null || trimmed.isEmpty
          ? provider.defaultModel
          : trimmed,
      hasApiKey: hasKey || provider == AiProvider.appleIntelligence,
      enabled: enabled,
      consentMode: consent,
      briefingMode: _briefingModeFromName(
        await _storage.read(key: 'ai_briefing_mode'),
      ),
      appleIntelligenceForBriefing:
          await _storage.read(key: 'ai_apple_briefing') == 'true',
    );
  }

  Future<String?> readApiKey(AiProvider provider) async {
    final key = (await _storage.read(key: _apiKeyKey(provider)))?.trim();
    return key == null || key.isEmpty ? null : key;
  }

  Future<void> saveApiKey(AiProvider provider, String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await _storage.delete(key: _apiKeyKey(provider));
    } else {
      await _storage.write(key: _apiKeyKey(provider), value: trimmed);
    }
  }

  /// Switching provider also resets the model to that provider's default.
  Future<void> saveProvider(AiProvider provider) async {
    await _storage.write(key: 'ai_coach_provider', value: provider.name);
    await _storage.write(key: 'ai_coach_model', value: provider.defaultModel);
  }

  Future<void> saveModel(String model) =>
      _storage.write(key: 'ai_coach_model', value: model.trim());

  Future<void> saveEnabled(bool enabled) => _storage.write(
    key: 'ai_coach_enabled',
    value: enabled ? 'true' : 'false',
  );

  Future<void> saveConsentMode(AiConsentMode mode) =>
      _storage.write(key: 'ai_coach_consent_mode', value: mode.name);

  Future<void> saveBriefingMode(BriefingMode mode) =>
      _storage.write(key: 'ai_briefing_mode', value: mode.name);

  Future<void> saveAppleIntelligenceForBriefing(bool value) =>
      _storage.write(key: 'ai_apple_briefing', value: value ? 'true' : 'false');
}
