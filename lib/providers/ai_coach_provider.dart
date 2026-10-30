import 'day_data_provider.dart' show dayScoresProvider, trainingMonitorProvider;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n_ext.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foundation_models_framework/foundation_models_framework.dart';

import '../config/free_ai.dart';
import '../db/database.dart';
import '../models/coach_context_card.dart';
import '../services/activity_coach_context.dart';
import '../services/ai_coach_client.dart';
import '../services/ai_coach_settings.dart';
import '../services/ai_context_toon_builder.dart';
import '../services/bio_age_service.dart';
import '../services/race_goal_service.dart';
import '../utils/log.dart';
import 'database_provider.dart';
import 'local_model_provider.dart';
import 'sync_provider.dart' show waitForSyncToSettle;

const _storage = FlutterSecureStorage();

final aiCoachSettingsStoreProvider = Provider<AiCoachSettingsStore>(
  (ref) => const AiCoachSettingsStore(),
);

final appleIntelligenceAvailabilityProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    final availability = await FoundationModelsFramework.instance
        .checkAvailability();
    log(
      '[AiCoach] Apple Intelligence available=${availability.isAvailable} '
      'reason=${availability.reasonCode} os=${availability.osVersion}',
    );
    return availability.isAvailable;
  },
);

final aiCoachClientProvider = Provider<AiCoachClient>(
  (ref) => AiCoachClient(
    store: ref.watch(aiCoachSettingsStoreProvider),
    localModelFor: (modelId) => ref.read(localModelServiceProvider(modelId)),
  ),
);

final aiContextToonBuilderProvider = Provider<AiContextToonBuilder>(
  (ref) => AiContextToonBuilder(ref.watch(databaseProvider)),
);

final aiCoachSettingsProvider =
    AsyncNotifierProvider<AiCoachSettingsNotifier, AiCoachSettings>(
      AiCoachSettingsNotifier.new,
    );

/// Coach context for one activity: the activity, the 30 days before it and
/// the year's progression.
final activityCoachContextProvider = FutureProvider.autoDispose
    .family<String, ActivityRecord>(
      (ref, activity) => ActivityCoachContextBuilder(
        ref.read(databaseProvider),
      ).build(activity),
    );

/// A request to open the coach tab about one session: the draft question,
/// the activity whose context is loaded and the card shown above the chat.
class CoachRequest {
  CoachRequest({required this.prompt, this.activity, this.card})
    : id = DateTime.now().microsecondsSinceEpoch;

  /// Tells requests apart, so a new request starts a fresh conversation.
  final int id;
  final String prompt;
  final ActivityRecord? activity;
  final CoachContextCard? card;
}

/// Set by the places that offer "ask the coach about this session"; the home
/// screen takes it, shows the coach tab and clears it.
final coachRequestProvider = StateProvider<CoachRequest?>((ref) => null);

/// A prompt handed from elsewhere in the app to the coach chat.
final pendingCoachPromptProvider = StateProvider<String?>((ref) => null);

/// Consent given for the current app session (consent mode "session").
final aiCoachSessionConsentProvider = StateProvider<bool>((ref) => false);

final toonCacheProvider = StateNotifierProvider<ToonCacheNotifier, _ToonCache?>(
  (ref) => ToonCacheNotifier(ref),
);

enum AiBriefingPeriod { morning, lunch, afternoon, evening }

final aiBriefingProvider =
    StateNotifierProvider.family<
      AiBriefingNotifier,
      AsyncValue<String?>,
      AiBriefingPeriod
    >((ref, period) {
      final notifier = AiBriefingNotifier(ref, period);
      ref.listen(aiCoachSettingsProvider, (previous, next) {
        final settings = next.valueOrNull;
        if (settings != null &&
            settings.readyForBriefing &&
            settings.usesOnDeviceBriefing) {
          Future.microtask(() => notifier.load(settings));
        }
      }, fireImmediately: true);
      return notifier;
    });

final briefingSummaryProvider = Provider.family<String, DateTime>((ref, date) {
  final scores = ref.watch(dayScoresProvider(date)).valueOrNull;
  String score(num? value) => value == null ? '—' : value.round().toString();
  return tr.briefingSummary(
    score(scores?.recovery?.score),
    score(scores?.sleep?.score),
    score(scores?.strain.score),
  );
});

String _briefingKey(AiBriefingPeriod period) {
  final now = DateTime.now();
  final day =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
  // The language is part of the key: a briefing is written in one language.
  // Bump the version when the prompts change so stale briefings regenerate.
  return 'ai_briefing_${period.name}_${day}_${activeLocale.languageCode}_v5';
}

/// Today's briefing for one period, cached in secure storage per day.
class AiBriefingNotifier extends StateNotifier<AsyncValue<String?>> {
  AiBriefingNotifier(this._ref, this.period) : super(const AsyncData(null)) {
    _loadFromDisk();
  }

  final Ref _ref;
  final AiBriefingPeriod period;

  Future<void> _loadFromDisk() async {
    final cached = await _storage.read(key: _briefingKey(period));
    if (mounted &&
        cached != null &&
        !state.isLoading &&
        !state.hasError &&
        state.valueOrNull == null) {
      state = AsyncData(cached);
    }
  }

  /// The training monitor as of today, for callers that did not pass one.
  Future<AiContextTrainingMonitor?> _currentMonitor() async {
    try {
      final now = DateTime.now();
      final m = await _ref
          .read(
            trainingMonitorProvider(
              DateTime(now.year, now.month, now.day),
            ).future,
          )
          .timeout(const Duration(seconds: 5));
      return AiContextTrainingMonitor(
        ctl: m.ctl,
        atl: m.atl,
        tsb: m.tsb,
        dailyLoad: m.dayLoad,
        optMin: m.optimalLow,
        optMax: m.optimalHigh,
        curWeekH: m.weekHours,
        prevWeekH: m.previousWeekHours,
        curWeekKm: m.weekKm,
        prevWeekKm: m.previousWeekKm,
        vo2maxRun: m.vo2max,
        vo2maxCycle: m.vo2maxCycling,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist(String text) =>
      _storage.write(key: _briefingKey(period), value: text);

  /// Generates the briefing unless one exists for today (or [force]).
  /// Cloud-only briefings require confirmation from the initiating UI action.
  Future<void> load(
    AiCoachSettings settings, {
    AiContextTrainingMonitor? monitor,
    String raceGoals = '',
    String? weatherSummary,
    BioAgeResult? bioAge,
    AiContextPlanInfo? planInfo,
    bool force = false,
    bool cloudConsent = false,
  }) async {
    if (!settings.usesOnDeviceBriefing && !cloudConsent) return;
    if (!mounted || state.isLoading || (!force && state.valueOrNull != null)) {
      return;
    }
    state = const AsyncLoading();
    try {
      // Never in the middle of a sync: wait until it is really finished, then
      // read the data, so the briefing is written from complete records.
      await waitForSyncToSettle(_ref, stillWanted: () => mounted);
      if (!mounted) return;
      monitor ??= await _currentMonitor();
      final toon = await _ref
          .read(aiContextToonBuilderProvider)
          .build(
            monitor,
            raceGoals,
            weatherSummary,
            bioAge: bioAge,
            planInfo: planInfo,
          );
      final client = _ref.read(aiCoachClientProvider);
      final future = switch (period) {
        AiBriefingPeriod.morning => client.sendBriefing(settings, toon),
        AiBriefingPeriod.lunch => client.sendLunchBriefing(settings, toon),
        AiBriefingPeriod.afternoon => client.sendAfternoonBriefing(
          settings,
          toon,
        ),
        AiBriefingPeriod.evening => client.sendEveningBriefing(settings, toon),
      };
      final timeout = switch (settings.provider) {
        AiProvider.freeAi => freeAiGenerationTimeout,
        AiProvider.localQwen => const Duration(seconds: 120),
        _ => const Duration(seconds: 30),
      };
      final text = await future.timeout(timeout);
      if (!mounted) return;
      state = AsyncData(text);
      await _persist(text);
    } catch (e, st) {
      log('[AiBriefing] ${period.name} error: $e');
      if (mounted) state = AsyncError(e, st);
    }
  }
}

class _ToonCache {
  const _ToonCache(
    this.toon,
    this.builtAt,
    this.goalRevision,
    this.profileGoals,
  );

  final String toon;
  final DateTime builtAt;
  final String goalRevision, profileGoals;

  bool get isStale =>
      DateTime.now().difference(builtAt) > const Duration(hours: 1);
}

/// The coach chat's context document, rebuilt at most hourly.
class ToonCacheNotifier extends StateNotifier<_ToonCache?> {
  ToonCacheNotifier(this._ref) : super(null);

  final Ref _ref;

  void invalidate() => state = null;

  Future<String> getOrBuild(
    AiContextTrainingMonitor? monitor,
    String raceGoals,
    String? weatherSummary, {
    BioAgeResult? bioAge,
    AiContextPlanInfo? planInfo,
  }) async {
    final cached = state;
    // Goals can change between two chat messages, without a device sync.
    final goals = await RaceGoalService(
      _ref.read(databaseProvider),
    ).resolveGoalSet();
    if (cached != null &&
        !cached.isStale &&
        cached.goalRevision == goals.revision &&
        cached.profileGoals == raceGoals) {
      return cached.toon;
    }
    final toon = await _ref
        .read(aiContextToonBuilderProvider)
        .build(
          monitor,
          raceGoals,
          weatherSummary,
          bioAge: bioAge,
          planInfo: planInfo,
        );
    state = _ToonCache(toon, DateTime.now(), goals.revision, raceGoals);
    return toon;
  }
}

class AiCoachSettingsNotifier extends AsyncNotifier<AiCoachSettings> {
  AiCoachSettingsStore get _store => ref.read(aiCoachSettingsStoreProvider);

  /// Prefer Apple Intelligence where available, otherwise offer Free AI.
  /// Resolve this at runtime so enabling Apple Intelligence restores the local
  /// default without replacing an explicitly selected Qwen or cloud provider.
  @override
  Future<AiCoachSettings> build() async {
    final settings = await _store.load();
    if (settings.provider == AiProvider.localQwen) {
      final local = await ref.watch(
        localModelProvider(settings.model).selectAsync(
          (status) =>
              (status.supported, status.installed && !status.downloading),
        ),
      );
      return settings.copyWith(
        localModelAvailable: local.$1,
        localModelInstalled: local.$2,
      );
    }
    if (settings.provider != AiProvider.appleIntelligence) return settings;
    var available = false;
    try {
      available = await ref.watch(appleIntelligenceAvailabilityProvider)();
    } catch (e) {
      log('[AiCoach] Apple Intelligence availability check failed: $e');
    }
    if (available) {
      return settings.copyWith(model: 'on-device', onDeviceAvailable: true);
    }
    return settings.copyWith(
      provider: AiProvider.freeAi,
      model: AiProvider.freeAi.defaultModel,
      hasApiKey: await _store.readApiKey(AiProvider.freeAi) != null,
      onDeviceAvailable: false,
      appleIntelligenceForBriefing: false,
    );
  }

  AiCoachSettings get _current => state.valueOrNull ?? const AiCoachSettings();

  Future<void> setEnabled(bool enabled) async {
    await _store.saveEnabled(enabled);
    state = AsyncData(_current.copyWith(enabled: enabled));
  }

  Future<void> setProvider(AiProvider provider) async {
    if (_current.provider == AiProvider.localQwen &&
        provider != AiProvider.localQwen) {
      await ref.read(localModelServiceProvider(_current.model)).unload();
    }
    if (_current.provider != provider) {
      ref.read(aiCoachSessionConsentProvider.notifier).state = false;
    }
    await _store.saveProvider(provider);
    state = AsyncData(await build());
  }

  Future<void> setApiKey(String key) async {
    await _store.saveApiKey(_current.provider, key);
    state = AsyncData(await build());
  }

  Future<void> setModel(String model) async {
    final selected = model.trim();
    if (_current.provider == AiProvider.localQwen) {
      if (!_current.provider.models.contains(selected)) {
        throw ArgumentError.value(selected, 'model');
      }
      await ref.read(localModelServiceProvider(_current.model)).unload();
      await _store.saveModel(selected);
      // Read readiness from the selected installation; 2B does not activate 4B.
      state = AsyncData(await build());
    } else {
      await _store.saveModel(selected);
      state = AsyncData(_current.copyWith(model: selected));
    }
  }

  Future<void> setConsentMode(AiConsentMode mode) async {
    await _store.saveConsentMode(mode);
    state = AsyncData(_current.copyWith(consentMode: mode));
  }

  Future<void> setBriefingMode(BriefingMode mode) async {
    await _store.saveBriefingMode(mode);
    state = AsyncData(_current.copyWith(briefingMode: mode));
  }

  Future<void> setAppleIntelligenceForBriefing(bool value) async {
    await _store.saveAppleIntelligenceForBriefing(value);
    state = AsyncData(_current.copyWith(appleIntelligenceForBriefing: value));
  }
}
