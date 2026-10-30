import 'dart:io' show Platform;

import 'package:fjelia_service/fjelia_service.dart' as service;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../config/free_ai.dart';
import 'local_model_catalog.dart';

enum AiProvider {
  mistral,
  openai,
  anthropic,
  gemini,
  deepseek,
  appleIntelligence,
  localQwen,
  freeAi,
}

enum AiConsentMode { everyMessage, session }

/// How the daily briefing is produced. `static_` is the rule-based text.
enum BriefingMode { ai, static_, none }

extension AiProviderLabel on AiProvider {
  bool get isLocal =>
      this == AiProvider.appleIntelligence || this == AiProvider.localQwen;

  bool get requiresUserApiKey => !isLocal && this != AiProvider.freeAi;

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
    AiProvider.localQwen => const [localQwenModelId, localQwen4bModelId],
    AiProvider.freeAi => const ['default'],
  };

  String get defaultModel => switch (this) {
    AiProvider.mistral => 'mistral-medium-latest',
    AiProvider.openai => 'gpt-4o-mini',
    AiProvider.anthropic => 'claude-haiku-5-5',
    AiProvider.gemini => 'gemini-2.0-flash',
    AiProvider.deepseek => 'deepseek-chat',
    AiProvider.appleIntelligence => 'on-device',
    AiProvider.localQwen => localQwenModelId,
    AiProvider.freeAi => 'default',
  };
}

/// Apple devices prefer Apple Intelligence; its runtime availability is checked
/// by the settings notifier. Other platforms start with Free AI.
AiProvider get defaultAiProvider => Platform.isIOS || Platform.isMacOS
    ? AiProvider.appleIntelligence
    : AiProvider.freeAi;

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
    this.localModelAvailable = false,
    this.localModelInstalled = false,
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
  final bool localModelAvailable, localModelInstalled;

  bool get ready =>
      enabled &&
      model.trim().isNotEmpty &&
      switch (provider) {
        AiProvider.appleIntelligence => onDeviceAvailable,
        AiProvider.localQwen =>
          provider.models.contains(model) &&
              localModelAvailable &&
              localModelInstalled,
        _ => hasApiKey,
      };

  bool get usesOnDeviceBriefing =>
      provider.isLocal ||
      (provider.requiresUserApiKey && appleIntelligenceForBriefing);

  bool get readyForBriefing =>
      briefingMode == BriefingMode.ai &&
      (provider == AiProvider.localQwen
          ? ready
          : (usesOnDeviceBriefing || ready));

  AiCoachSettings copyWith({
    bool? appleIntelligenceForBriefing,
    BriefingMode? briefingMode,
    AiConsentMode? consentMode,
    bool? enabled,
    bool? hasApiKey,
    String? model,
    AiProvider? provider,
    bool? onDeviceAvailable,
    bool? localModelAvailable,
    bool? localModelInstalled,
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
      localModelAvailable: localModelAvailable ?? this.localModelAvailable,
      localModelInstalled: localModelInstalled ?? this.localModelInstalled,
    );
  }
}

class AiCoachSettingsStore {
  const AiCoachSettingsStore({this.freeAiApiKey = service.freeAiApiKey});

  final String freeAiApiKey;

  static const _storage = FlutterSecureStorage();
  static const _installationStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );
  static const _uuid = Uuid();
  static final _installationIdPattern = RegExp(
    r'^fjelia-install-[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );
  static Future<String>? _installationIdLoading;

  static String _apiKeyKey(AiProvider p) => 'ai_coach_api_key_${p.name}';

  static AiProvider _providerFromName(String? name) => AiProvider.values
      .firstWhere((p) => p.name == name, orElse: () => defaultAiProvider);

  static BriefingMode _briefingModeFromName(String? name) => BriefingMode.values
      .firstWhere((m) => m.name == name, orElse: () => BriefingMode.ai);

  /// Distinguishes a previous choice from the platform's initial default.
  Future<AiProvider?> readSavedProvider() async {
    final name = await _storage.read(key: 'ai_coach_provider');
    for (final provider in AiProvider.values) {
      if (provider.name == name) return provider;
    }
    return null;
  }

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
    final key = await readApiKey(provider);
    final hasKey = key != null && key.isNotEmpty;
    final enabled = await _storage.read(key: 'ai_coach_enabled') != 'false';
    final savedConsent = await _storage.read(key: 'ai_coach_consent_mode');
    // New preferences ask once per session; retain an explicit per-message
    // choice (and the conservative handling of unrecognised saved values).
    final consent = savedConsent == null || savedConsent == 'session'
        ? AiConsentMode.session
        : AiConsentMode.everyMessage;
    final trimmed = model?.trim();
    return AiCoachSettings(
      provider: provider,
      model:
          trimmed == null ||
              trimmed.isEmpty ||
              ((provider == AiProvider.localQwen ||
                      provider == AiProvider.freeAi) &&
                  !provider.models.contains(trimmed))
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
    final key = provider == AiProvider.freeAi
        ? freeAiApiKey.trim()
        : (await _storage.read(key: _apiKeyKey(provider)))?.trim();
    return key == null || key.isEmpty ? null : key;
  }

  /// A random, device-local identity for Free AI usage attribution. It contains
  /// no account or hardware identifiers and is excluded from Fjelia backups.
  Future<String> readFreeAiInstallationId() =>
      _installationIdLoading ??= _loadFreeAiInstallationId().whenComplete(() {
        _installationIdLoading = null;
      });

  Future<String> _loadFreeAiInstallationId() async {
    final saved = await _installationStorage.read(
      key: freeAiInstallationIdStorageKey,
    );
    if (saved != null && _installationIdPattern.hasMatch(saved)) return saved;
    final id = 'fjelia-install-${_uuid.v4()}';
    await _installationStorage.write(
      key: freeAiInstallationIdStorageKey,
      value: id,
    );
    return id;
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
