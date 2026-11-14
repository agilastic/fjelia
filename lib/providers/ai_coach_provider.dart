import 'dart:convert';

import 'day_data_provider.dart' show dayScoresProvider, trainingMonitorProvider;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n_ext.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
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
import '../services/briefing_consent.dart';
import 'user_profile_provider.dart';

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
  (ref) => AiContextToonBuilder(
    ref.watch(databaseProvider),
    bodyFrame: () async {
      final p = await ref.read(userProfileProvider.future);
      return (heightCm: p.heightCm, waistCm: p.waistCm);
    },
  ),
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
  CoachRequest({
    required this.prompt,
    this.activity,
    this.card,
    this.autoSend = false,
  }) : id = DateTime.now().microsecondsSinceEpoch;

  /// Tells requests apart, so a new request starts a fresh conversation.
  final int id;
  final String prompt;
  final ActivityRecord? activity;
  final CoachContextCard? card;

  /// Sends [prompt] as soon as the coach tab shows. Cleared once sent, so
  /// coming back to the tab does not ask a second time.
  bool autoSend;
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

final aiBriefingSourceProvider =
    StateProvider.family<String?, AiBriefingPeriod>((ref, period) => null);

final aiBriefingProvider =
    StateNotifierProvider.family<
      AiBriefingNotifier,
      AsyncValue<String?>,
      AiBriefingPeriod
    >((ref, period) {
      final notifier = AiBriefingNotifier(ref, period);
      ref.listen(aiCoachSettingsProvider, (previous, next) {
        final settings = next.valueOrNull;
        if (settings == null || !settings.readyForBriefing) return;
        Future.microtask(() async {
          final cloudConsent = await BriefingConsent.given(settings);
          if (settings.onDeviceAvailable || cloudConsent) {
            final profile = await ref.read(userProfileProvider.future);
            await notifier.load(
              settings,
              raceGoals: profile.raceGoals ?? '',
              cloudConsent: cloudConsent,
            );
          }
        });
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
  // Bump the version when prompts or deterministic readiness rules change.
  return 'ai_briefing_${period.name}_${day}_${activeLocale.languageCode}_v9';
}

String _briefingInputHashKey(AiBriefingPeriod period) =>
    '${_briefingKey(period)}_input_hash';

String _briefingSourceKey(AiBriefingPeriod period) =>
    '${_briefingKey(period)}_source';

/// Values that move with every sync during the day without changing what the
/// briefing should say: the clock, today's running totals (steps, calories,
/// Body Battery…) and the current-hour weather reading. Only inside their
/// own blocks: `Steps:` also names a planned workout's structure, which must
/// keep counting.
const _intradayBriefingFields = {
  '[Today:': ['TimeNow'],
  '[Daily:': [
    'Steps',
    'ActiveCal',
    'TotalCal',
    'Floors',
    'IntensityMin',
    'BBHigh',
    'BBLow',
    'BBCharged',
    'BBDrained',
  ],
  '[Weather:': ['TempNow', 'WindKmh', 'WindChill', 'WetBulb'],
};

/// The hash that decides whether today's briefing is written again. Only
/// substantive changes (sleep, HRV, activities, plan, BP, forecast…) count.
String briefingInputHash(String toon) {
  final stableToon = toon.replaceAllMapped(RegExp(r'\[[A-Za-z]+:[^\]]*\]'), (
    block,
  ) {
    final text = block[0]!;
    final fields = _intradayBriefingFields.entries
        .where((e) => text.startsWith(e.key))
        .firstOrNull
        ?.value;
    if (fields == null) return text;
    return text.replaceAllMapped(
      RegExp('([\\[,:])(${fields.join('|')}):[^,\\]]*'),
      (m) => '${m[1]}${m[2]}:<omitted>',
    );
  });
  return sha256.convert(utf8.encode(stableToon)).toString();
}

/// Today's briefing for one period, cached in secure storage per day.
class AiBriefingNotifier extends StateNotifier<AsyncValue<String?>> {
  AiBriefingNotifier(this._ref, this.period) : super(const AsyncData(null)) {
    _loadFromDisk();
  }

  final Ref _ref;
  final AiBriefingPeriod period;
  bool _checkingInputs = false;

  Future<void> _loadFromDisk() async {
    final cached = await _storage.read(key: _briefingKey(period));
    final source = await _storage.read(key: _briefingSourceKey(period));
    if (mounted && source != null) {
      _ref.read(aiBriefingSourceProvider(period).notifier).state = source;
    }
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

  Future<void> _persist(String text, String inputHash, String? source) async {
    await _storage.write(key: _briefingKey(period), value: text);
    await _storage.write(key: _briefingInputHashKey(period), value: inputHash);
    if (source != null) {
      await _storage.write(key: _briefingSourceKey(period), value: source);
      _ref.read(aiBriefingSourceProvider(period).notifier).state = source;
    }
  }

  /// Refreshes an existing morning briefing after the athlete changes today's
  /// plan. Cloud models are used only when the athlete has given consent for
  /// recorded; the plan interaction never triggers a consent flow.
  Future<void> refreshAfterPlanChange() async {
    if (period != AiBriefingPeriod.morning || !mounted) return;
    try {
      final settings = await _ref.read(aiCoachSettingsProvider.future);
      if (!settings.readyForBriefing) {
        return;
      }
      final cached =
          state.valueOrNull ?? await _storage.read(key: _briefingKey(period));
      final cloudConsent = await BriefingConsent.given(settings);
      if (!settings.onDeviceAvailable && !cloudConsent) return;
      final profile = await _ref.read(userProfileProvider.future);
      await load(
        settings,
        raceGoals: profile.raceGoals ?? '',
        // Compare the full current context so a plan response regenerates only
        // when it actually changed an input to the briefing.
        checkDataChanges: cached != null,
        cloudConsent: cloudConsent,
      );
    } catch (e) {
      log('[AiBriefing] refresh after plan change: $e');
    }
  }

  /// Generates a briefing and reuses today's result while its inputs match.
  /// Cloud-only briefings require confirmation from the initiating UI action.
  Future<void> load(
    AiCoachSettings settings, {
    AiContextTrainingMonitor? monitor,
    String raceGoals = '',
    String? weatherSummary,
    BioAgeResult? bioAge,
    AiContextPlanInfo? planInfo,
    bool checkDataChanges = false,
    bool cloudConsent = false,
  }) async {
    if (!settings.onDeviceAvailable && !cloudConsent) return;
    if (!mounted || state.isLoading || _checkingInputs) {
      return;
    }
    var previousText = state.valueOrNull;
    if (previousText == null) {
      previousText = await _storage.read(key: _briefingKey(period));
      if (!mounted || state.isLoading) return;
      if (previousText != null) state = AsyncData(previousText);
    }
    if (previousText != null && !checkDataChanges) {
      return;
    }
    if (!mounted || state.isLoading) return;
    _checkingInputs = true;
    try {
      // Keep the existing briefing visible while inputs are collected and
      // compared; a routine app refresh should not flash an empty card.
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
      final inputHash = briefingInputHash(toon);
      final savedHash = await _storage.read(key: _briefingInputHashKey(period));
      if (!mounted) return;
      if (previousText != null && checkDataChanges && savedHash == inputHash) {
        state = AsyncData(previousText);
        return;
      }
      state = const AsyncLoading();
      final client = _ref.read(aiCoachClientProvider);
      String? generatedSource;
      void recordSource(String source) => generatedSource = source;
      final future = switch (period) {
        AiBriefingPeriod.morning => client.sendBriefing(
          settings,
          toon,
          cloudFallback: cloudConsent,
          onSource: recordSource,
        ),
        AiBriefingPeriod.lunch => client.sendLunchBriefing(
          settings,
          toon,
          cloudFallback: cloudConsent,
          onSource: recordSource,
        ),
        AiBriefingPeriod.afternoon => client.sendAfternoonBriefing(
          settings,
          toon,
          cloudFallback: cloudConsent,
          onSource: recordSource,
        ),
        AiBriefingPeriod.evening => client.sendEveningBriefing(
          settings,
          toon,
          cloudFallback: cloudConsent,
          onSource: recordSource,
        ),
      };
      final timeout = settings.onDeviceAvailable && !cloudConsent
          ? const Duration(seconds: 30)
          : freeAiGenerationTimeout;
      final text = await future.timeout(timeout);
      if (!mounted) return;
      state = AsyncData(text);
      await _persist(text, inputHash, generatedSource);
    } catch (e, st) {
      log('[AiBriefing] ${period.name} error: $e');
      if (mounted) {
        // If refreshing an existing briefing fails, keep the previous useful
        // result visible and retry at the next refresh.
        state = previousText == null
            ? AsyncError(e, st)
            : AsyncData(previousText);
      }
    } finally {
      _checkingInputs = false;
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
    final available = await _appleAvailable();
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
        onDeviceAvailable: available,
      );
    }
    // With Free AI or an own key the chat goes to the cloud, but briefings
    // are written on the device whenever Apple Intelligence runs here.
    if (settings.provider != AiProvider.appleIntelligence) {
      return settings.copyWith(onDeviceAvailable: available);
    }
    if (available) {
      return settings.copyWith(model: 'on-device', onDeviceAvailable: true);
    }
    return settings.copyWith(
      provider: AiProvider.freeAi,
      model: AiProvider.freeAi.defaultModel,
      hasApiKey: await _store.readApiKey(AiProvider.freeAi) != null,
      onDeviceAvailable: false,
    );
  }

  Future<bool> _appleAvailable() async {
    try {
      return await ref.watch(appleIntelligenceAvailabilityProvider)();
    } catch (e) {
      log('[AiCoach] Apple Intelligence availability check failed: $e');
      return false;
    }
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
