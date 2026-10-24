import 'weather_radar_provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/ai_context_toon_builder.dart';
import '../services/health_connect_service.dart' show HealthAccess;
import '../services/sync_service.dart';
import '../services/widget_data_service.dart';
import '../utils/log.dart';
import 'ai_coach_provider.dart';
import 'auth_provider.dart';
import 'coros_provider.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';
import 'health_connect_provider.dart';
import 'heat_acclimation_provider.dart';
import 'hilo_sync_provider.dart';
import 'hr_zone_sync_provider.dart';
import 'hr_zones_provider.dart';
import 'planner_providers.dart';
import 'polar_provider.dart';
import 'readiness_provider.dart';
import 'source_priority_provider.dart';
import 'suunto_provider.dart';
import 'user_profile_provider.dart';
import 'workout_generation_provider.dart';

const _storage = FlutterSecureStorage();

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    ref.watch(aktiiaClientProvider),
    ref.watch(garminClientProvider),
    ref.watch(renphoClientProvider),
    ref.watch(databaseProvider),
    ref.watch(heatAcclimationServiceProvider),
  ),
);

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>(
  (ref) => SyncNotifier(ref, ref.watch(syncServiceProvider)),
);

final historicSyncProvider =
    StateNotifierProvider<HistoricSyncNotifier, HistoricSyncState>(
      (ref) => HistoricSyncNotifier(ref, ref.watch(syncServiceProvider)),
    );

Future<bool> _hasInternet() async {
  try {
    final socket = await Socket.connect(
      '8.8.8.8',
      53,
      timeout: const Duration(seconds: 3),
    );
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

/// Starts the history import (a year of activities from every connected
/// platform). Onboarding calls it once the accounts are connected, so the
/// import runs while the plan questions are answered. A no-op while an
/// import is already running.
final historyImportStarterProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => ref.read(historicSyncProvider.notifier).start(force: true),
);

/// Set when a plan was generated before any history was downloaded; the
/// first historic sync then rebuilds it once.
const _planNeedsHistoryKey = 'plan_needs_history_v1';

/// A full-year import has completed (an older 60-day import does not count,
/// so existing installs get the year of history once).
Future<bool> _historyDownloaded() async =>
    await _storage.read(key: HistoricSyncNotifier._yearKey) != null;

/// The automatic import is attempted at most three times a day, so a failing
/// import (offline, Garmin limits) is not restarted at every sync, while one
/// cut short by iOS (app in the background) resumes at the next launch.
Future<bool> _importAttemptedToday() async {
  final now = DateTime.now();
  final today = '${now.year}-${now.month}-${now.day}';
  final raw = await _storage.read(key: HistoricSyncNotifier._attemptKey) ?? '';
  final parts = raw.split('|');
  final count = parts.length == 2 && parts[0] == today
      ? int.tryParse(parts[1]) ?? 0
      : 0;
  if (count >= 3) return true;
  await _storage.write(
    key: HistoricSyncNotifier._attemptKey,
    value: '$today|${count + 1}',
  );
  return false;
}

/// Builds the plan right away (onboarding "Build My Plan"). Without
/// downloaded history it is marked for recalibration after the first
/// historic sync. Returns the number of planned sessions, or null when
/// there is no priority-A race goal.
final buildPlanNowProvider = Provider<Future<int?> Function()>(
  (ref) => () async {
    final goal = await ref.read(raceGoalServiceProvider).getPrimaryGoal();
    if (goal == null) return null;
    final count = await ref.read(workoutGenerationProvider.notifier).generate();
    if (count != null && !await _historyDownloaded()) {
      await _storage.write(key: _planNeedsHistoryKey, value: '1');
    }
    return count;
  },
);

/// Generates a plan for the primary race goal when none is active yet.
///
/// The daily sync waits for the first historic sync, so the plan is
/// calibrated on past activities. After the historic sync ([afterHistory])
/// a plan built without history (e.g. from onboarding) is rebuilt once.
Future<void> _autoGeneratePlanIfNeeded(
  Ref ref, {
  bool afterHistory = false,
}) async {
  final db = ref.read(databaseProvider);
  final needsHistory = await _storage.read(key: _planNeedsHistoryKey) != null;
  if (!afterHistory && !await _historyDownloaded()) {
    log('[Sync] auto-plan waits for the historic sync');
    return;
  }
  final active =
      await (db.select(db.trainingPlans)
            ..where(
              (t) => t.athleteId.equals('self') & t.status.equals('active'),
            )
            ..limit(1))
          .getSingleOrNull();
  if (active != null && !(afterHistory && needsHistory)) return;
  final goal = await ref.read(raceGoalServiceProvider).getPrimaryGoal();
  if (goal == null) return;
  if (active != null) {
    log('[Sync] recalibrating plan with downloaded history');
  }
  final profile = ref.read(userProfileProvider).valueOrNull;
  final days = profile?.trainingDaysPerWeek ?? 5;
  log('[Sync] auto-generating plan for ${goal.name}, $days days/week');
  final plans = ref.read(trainingPlanServiceProvider);
  final generated = await ref
      .read(workoutGenerationProvider.notifier)
      .generate();
  if (generated == null) return;
  await _storage.delete(key: _planNeedsHistoryKey);
  ref.invalidate(upcomingSessionsProvider);
  log('[Sync] plan generated — pushing to Garmin');
  try {
    await plans.pushPlanToGarmin('self');
    log('[Sync] pushed plan workouts to Garmin');
  } catch (e) {
    log('[Sync] Garmin push failed: $e');
  }
}

// ---------------------------------------------------------------------------
// Daily sync
// ---------------------------------------------------------------------------

enum SyncStatus { idle, syncing, done, error }

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSync,
    this.errorMessage,
    this.progress = 0,
    this.garminAuthError = false,
    this.aktiiaAuthError = false,
    this.renphoAuthError = false,
    this.polarAuthError = false,
    this.suuntoAuthError = false,
    this.corosAuthError = false,
  });

  final SyncStatus status;
  final DateTime? lastSync;
  final String? errorMessage;

  /// 0–100 while syncing.
  final int progress;
  final bool garminAuthError;
  final bool aktiiaAuthError;
  final bool renphoAuthError;
  final bool polarAuthError;
  final bool suuntoAuthError;
  final bool corosAuthError;

  bool get hasAuthError =>
      garminAuthError ||
      aktiiaAuthError ||
      renphoAuthError ||
      polarAuthError ||
      suuntoAuthError ||
      corosAuthError;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSync,
    int? progress,
    String? errorMessage,
    bool clearError = false,
    bool? garminAuthError,
    bool? aktiiaAuthError,
    bool? renphoAuthError,
    bool? polarAuthError,
    bool? suuntoAuthError,
    bool? corosAuthError,
  }) => SyncState(
    status: status ?? this.status,
    lastSync: lastSync ?? this.lastSync,
    progress: progress ?? this.progress,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    garminAuthError: garminAuthError ?? this.garminAuthError,
    aktiiaAuthError: aktiiaAuthError ?? this.aktiiaAuthError,
    renphoAuthError: renphoAuthError ?? this.renphoAuthError,
    polarAuthError: polarAuthError ?? this.polarAuthError,
    suuntoAuthError: suuntoAuthError ?? this.suuntoAuthError,
    corosAuthError: corosAuthError ?? this.corosAuthError,
  );
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier(this._ref, this._service) : super(const SyncState());

  final Ref _ref;
  final SyncService _service;
  bool _aktiiaRefreshing = false;

  void _bump(StateProvider<int> p) =>
      _ref.read(p.notifier).update((v) => v + 1);

  Future<void> sync() async {
    if (state.status == SyncStatus.syncing) {
      log('[Sync] already syncing — skipped');
      return;
    }
    log('[Sync] starting');
    state = state.copyWith(
      status: SyncStatus.syncing,
      progress: 0,
      clearError: true,
    );
    try {
      await _doSync();
    } catch (e) {
      log('[Sync] EXCEPTION — $e');
      _bump(syncStatusListenerProvider);
      final msg = e.toString();
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: msg.length > 60 ? msg.substring(0, 60) : msg,
      );
    }
  }

  void cancelSync() {
    if (state.status == SyncStatus.syncing) {
      state = state.copyWith(status: SyncStatus.idle, progress: 0);
    }
  }

  Future<void> _doSync() async {
    final online = await _hasInternet();
    log('[Sync] internet: $online');
    if (!online) {
      log('[Sync] offline — skipping sync (Garmin API requires internet)');
      _finish(SyncResult());
      return;
    }
    log('[Sync] online — fetching all APIs');
    final today = DateTime.now();
    final result = await _service.syncDay(today);
    log('[Sync] API done — garmin=${result.garmin} renpho=${result.renpho}');
    state = state.copyWith(progress: 40);
    _handleAuthErrors(result);
    _bump(syncStatusListenerProvider);

    final sleepPriority = await priorityForGroup(SourceGroup.sleep);

    Future<void> polar() async {
      final s = _ref.read(polarServiceProvider);
      if (!await s.isConnected) return;
      try {
        await s.sync(days: 7);
      } catch (e) {
        log('[Sync] Polar error: $e');
      }
    }

    Future<void> suunto() async {
      final s = _ref.read(suuntoServiceProvider);
      if (!await s.isConnected) return;
      try {
        await s.sync(days: 7);
      } catch (e) {
        log('[Sync] Suunto error: $e');
      }
    }

    Future<void> coros() async {
      final s = _ref.read(corosServiceProvider);
      if (!await s.isConnected) return;
      try {
        await s.sync(days: 7);
      } catch (e) {
        log('[Sync] Coros error: $e');
      }
    }

    Future<void> health() async {
      try {
        final hc = _ref.read(healthConnectServiceProvider);
        final permission = _ref.read(healthConnectPermissionProvider.notifier);
        // Once access counts as revoked, ask again only after the user
        // reconnected it; every read would otherwise wait for a timeout.
        if (await permission.isRevoked()) {
          log('[Sync] Apple Health disconnected — skipping');
          return;
        }
        var granted =
            _ref.read(healthConnectPermissionProvider).valueOrNull ?? false;
        if (!granted) {
          granted = await hc.requestPermissions();
          if (granted) await permission.markGranted();
        }
        if (!granted) return;
        // Check that Health answers at all before the long reads. If it does
        // not, the connection counts as lost: disconnect it, tell the user
        // once and skip Health until it is connected again.
        if (await hc.probeAccess() != HealthAccess.ok) {
          log('[Sync] Apple Health not responding — disconnecting it');
          await permission.markRevoked();
          _ref.read(healthAccessLostProvider.notifier).state = true;
          return;
        }
        log('[Sync] Health Connect sync starting');
        await hc.sync(7, sleepPriority);
        log('[Sync] Health Connect sync done');
        await hc.writeBack(
          _ref.read(hiloWriteHealthProvider),
          _ref.read(renphoWriteHealthProvider),
        );
      } catch (e) {
        log('[Sync] Health Connect sync error: $e');
      }
    }

    await Future.wait([polar(), suunto(), coros(), health()]);
    state = state.copyWith(progress: 70);

    final hilo = activeHiloBleService;
    if (hilo != null && await hilo.getPairedMac() != null) {
      unawaited(hilo.triggerSync());
    } else {
      await _syncAktiiaDirect();
    }

    try {
      await _service.recalculateEnergie(today);
    } catch (e) {
      log('[Sync] Energie recalc error: $e');
    }
    try {
      await _ref.read(activityListProvider.notifier).refresh();
    } catch (e) {
      log('[Sync] activity list refresh error: $e');
    }
    _bump(syncStatusListenerProvider);
    _bump(fullSyncListenerProvider);
    _ref.invalidate(heatTodayStateProvider);
    _ref.invalidate(heatHourlyWeatherProvider);
    _ref.invalidate(weatherRadarProvider);
    _ref.invalidate(heatForecastProvider);

    try {
      await _ref.read(hrZoneSyncProvider)();
      await _ref.read(zoneRecalculationProvider)();
    } catch (e) {
      log('[Sync] HR zone sync error: $e');
    }
    try {
      await _ref.read(morningAdaptationProvider.notifier).runIfNeeded();
    } catch (e) {
      log('[Sync] readiness adaptation error: $e');
    }
    await _scoreRecentWorkouts();
    try {
      await _autoGeneratePlanIfNeeded(_ref);
    } catch (e) {
      log('[Sync] auto-plan error: $e');
    }
    // First run: download the training history in the background; the plan
    // is generated (or recalibrated) when it completes.
    if (!await _historyDownloaded() && !await _importAttemptedToday()) {
      log('[Sync] no year of history yet — starting historic sync');
      unawaited(_ref.read(historicSyncProvider.notifier).start(force: true));
    }
    _finish(result);
  }

  /// Scores the last week's completed workouts against planned sessions.
  Future<void> _scoreRecentWorkouts() async {
    try {
      final scorer = _ref.read(postWorkoutScorerProvider);
      final db = _ref.read(databaseProvider);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final from = today.subtract(const Duration(days: 7));
      final to = today.add(const Duration(days: 1));
      final activities =
          await (db.select(db.activityRecords)
                ..where((t) => t.startDate.isBetweenValues(from, to))
                ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
              .get();
      final scored = (await db.select(db.sessionActuals).get())
          .map((a) => a.sessionId)
          .toSet();
      for (final a in activities) {
        try {
          await scorer.scoreIfUnscored(a, alreadyScored: scored);
        } catch (e) {
          log('[Sync] scorer error for activity ${a.activityId}: $e');
        }
      }
    } catch (e) {
      log('[Sync] post-workout scorer error: $e');
    }
  }

  Future<void> _syncAktiiaDirect() async {
    try {
      log('[Sync] Aktiia direct fetch (no BLE upload)');
      final result = await _service.syncAktiiaDay(DateTime.now());
      log('[Sync] Aktiia direct done — bp=${result.bp}');
      _handleAuthErrors(result);
      _bump(syncStatusListenerProvider);
    } catch (e) {
      log('[Sync] Aktiia direct fetch error: $e');
    }
  }

  /// Called by the Hilo service once a bracelet upload reached Aktiia.
  /// Returns true when new readings arrived.
  Future<bool> refreshAktiiaAfterBleUpload() async {
    if (_aktiiaRefreshing) {
      log('[Sync] Aktiia BLE refresh already in progress — skipping');
      return false;
    }
    if (!await _hasInternet()) {
      log('[Sync] offline — skipping Aktiia refresh after BLE upload');
      return false;
    }
    _aktiiaRefreshing = true;
    try {
      log('[Sync] Aktiia refresh after BLE upload starting');
      final result = await _service.syncAktiiaDay(DateTime.now());
      if (result.hasErrors) {
        log('[Sync] Aktiia refresh errors — ${result.errors.join(', ')}');
        _handleAuthErrors(result);
      }
      log('[Sync] Aktiia refresh done — bp=${result.bp}');
      _bump(syncStatusListenerProvider);
      return result.bp > 0;
    } finally {
      _aktiiaRefreshing = false;
    }
  }

  void _handleAuthErrors(SyncResult result) {
    final auth = _ref.read(authProvider.notifier);
    if (result.garminAuthError) {
      log('[Sync] Garmin auth error detected — marking disconnected');
      auth.markGarminDisconnected();
    }
    if (result.aktiiaAuthError) {
      log('[Sync] Aktiia auth error detected — marking disconnected');
      auth.markAktiiaDisconnected();
    }
    if (result.renphoAuthError) {
      log('[Sync] Renpho auth error detected — marking disconnected');
      auth.markRenphoDisconnected();
    }
  }

  void _finish(SyncResult result) {
    if (!mounted) return;
    state = state.copyWith(status: SyncStatus.idle, progress: 100);
    unawaited(
      WidgetDataService(_ref.read(databaseProvider)).push().catchError((_) {}),
    );
    if (result.garmin > 0 || result.activities > 0 || result.bp > 0) {
      _ref.invalidate(aiBriefingProvider);
      log('[Sync] new data — briefing invalidated');
      _prewarmBriefing();
    }
    final errors = result.errors.join('\n');
    state = state.copyWith(
      status: result.hasErrors ? SyncStatus.error : SyncStatus.done,
      lastSync: DateTime.now(),
      progress: 100,
      errorMessage: result.hasErrors
          ? (errors.length > 200 ? errors.substring(0, 200) : errors)
          : null,
      clearError: !result.hasErrors,
      garminAuthError: result.garminAuthError,
      aktiiaAuthError: result.aktiiaAuthError,
      renphoAuthError: result.renphoAuthError,
    );
  }

  /// Builds the current period's AI briefing in the background.
  void _prewarmBriefing() {
    final settings = _ref.read(aiCoachSettingsProvider).valueOrNull;
    if (settings == null || !settings.readyForBriefing) return;
    final hour = DateTime.now().hour;
    final period = hour < 11
        ? AiBriefingPeriod.morning
        : hour < 14
        ? AiBriefingPeriod.lunch
        : hour < 18
        ? AiBriefingPeriod.afternoon
        : AiBriefingPeriod.evening;
    final today = DateTime.now();
    final monitor = _ref
        .read(
          trainingMonitorProvider(DateTime(today.year, today.month, today.day)),
        )
        .valueOrNull;
    final weather = AiContextToonBuilder.buildWeatherSummary(
      _ref.read(heatHourlyWeatherProvider).valueOrNull,
    );
    final profile = _ref.read(userProfileProvider).valueOrNull;
    _ref
        .read(aiBriefingProvider(period).notifier)
        .load(
          settings,
          monitor: monitor == null
              ? null
              : AiContextTrainingMonitor(
                  ctl: monitor.ctl,
                  atl: monitor.atl,
                  tsb: monitor.tsb,
                  dailyLoad: monitor.dayLoad,
                  optMin: monitor.optimalLow,
                  optMax: monitor.optimalHigh,
                  curWeekH: monitor.weekHours,
                  prevWeekH: monitor.previousWeekHours,
                  curWeekKm: monitor.weekKm,
                  prevWeekKm: monitor.previousWeekKm,
                  vo2maxRun: monitor.vo2max,
                  vo2maxCycle: monitor.vo2maxCycling,
                ),
          raceGoals: profile?.raceGoals ?? '',
          weatherSummary: weather,
          force: true,
        );
    log('[Sync] AI briefing pre-warm triggered (${period.name})');
  }
}

// ---------------------------------------------------------------------------
// Historic backfill
// ---------------------------------------------------------------------------

class HistoricSyncState {
  const HistoricSyncState({
    this.running = false,
    this.progress,
    this.total,
    this.phase,
    this.completed = const [],
    this.done = false,
    this.failed = false,
  });

  final bool running;
  final int? progress;
  final int? total;

  /// What is being downloaded or computed right now.
  final String? phase;

  /// Finished steps, shown as a checklist.
  final List<String> completed;

  /// The run finished; the summary stays visible until dismissed.
  final bool done;
  final bool failed;

  HistoricSyncState copyWith({
    int? progress,
    int? total,
    String? phase,
    List<String>? completed,
  }) => HistoricSyncState(
    running: running,
    progress: progress ?? this.progress,
    total: total ?? this.total,
    phase: phase ?? this.phase,
    completed: completed ?? this.completed,
  );
}

/// Once a day (or on demand): backfill [days] of history from every source,
/// then seed thresholds, templates and an auto-generated plan.
class HistoricSyncNotifier extends StateNotifier<HistoricSyncState> {
  HistoricSyncNotifier(this._ref, this._service)
    : super(const HistoricSyncState()) {
    _restoreLastSyncDay();
  }

  final Ref _ref;
  final SyncService _service;
  DateTime? _lastSyncDay;
  bool _cancelled = false;
  bool _garminRanThisSession = false;

  static const _lastKey = 'historic_sync_last_date_v1';
  static const _yearKey = 'historic_sync_year_done_v1';
  static const _attemptKey = 'historic_sync_attempt_day_v1';
  static const _hcBackfillKey = 'hc_backfill_done_v1';

  Future<void> _restoreLastSyncDay() async {
    final raw = await _storage.read(key: _lastKey);
    final ms = raw == null ? null : int.tryParse(raw);
    if (ms == null) return;
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    _lastSyncDay = DateTime(d.year, d.month, d.day);
  }

  void cancel() {
    log('[HistoricSync] cancelled by user');
    _cancelled = true;
    state = const HistoricSyncState();
  }

  /// Hides the finished summary.
  void dismiss() {
    if (!state.running) state = const HistoricSyncState();
  }

  void _phase(String phase, {int? progress, int? total}) {
    if (!mounted || _cancelled) return;
    state = HistoricSyncState(
      running: true,
      phase: phase,
      progress: progress,
      total: total,
      completed: state.completed,
    );
  }

  void _completed(String step) {
    if (!mounted || _cancelled) return;
    state = state.copyWith(completed: [...state.completed, step]);
  }

  /// Downloads history: a year of activities by default (365), with
  /// details and wellness for the last 90 days.
  Future<void> start({int days = 365, bool force = false}) async {
    if (state.running) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!force && _lastSyncDay == today) {
      final hrv = await _ref.read(databaseProvider).getHrvRange(30);
      if (hrv.isNotEmpty) {
        log('[HistoricSync] already ran today — skipped');
        return;
      }
      log('[HistoricSync] DB appears empty after reinstall — forcing re-run');
    } else if (force) {
      log('[HistoricSync] manual force — bypassing date guard');
    }
    if (!await _hasInternet()) {
      log('[HistoricSync] offline — skipped');
      return;
    }

    final auth = _ref.read(authProvider);
    _cancelled = false;
    state = const HistoricSyncState(
      running: true,
      phase: 'Connecting to your accounts…',
    );
    log(
      '[HistoricSync] starting — aktiia=${auth.aktiiaConnected} '
      'garmin=${auth.garminConnected} days=$days',
    );

    try {
      void progress(int done, int total) => _phase(
        'Garmin: daily health data — day $done of $total',
        progress: done,
        total: total,
      );

      bool isCancelled() => _cancelled;

      final futures = <Future<SyncResult>>[];
      if (auth.aktiiaConnected) {
        futures.add(
          _service.syncAktiiaHistoric(
            math.min(days, 90),
            onProgress: auth.garminConnected
                ? null
                : (d, t) => _phase(
                    'Aktiia: blood pressure — day $d of $t',
                    progress: d,
                    total: t,
                  ),
            isCancelled: isCancelled,
          ),
        );
      }
      if (auth.garminConnected) {
        _garminRanThisSession = true;
        futures.add(
          _service.syncGarminHistoric(
            days,
            onProgress: progress,
            onStatus: (s) => _phase('Garmin: $s'),
            isCancelled: isCancelled,
          ),
        );
      }
      final results = await Future.wait(futures);
      final garmin = results.fold<int>(0, (s, r) => s + r.garmin);
      final bp = results.fold<int>(0, (s, r) => s + r.bp);
      final activities = results.fold<int>(0, (s, r) => s + r.activities);
      if (auth.garminConnected) {
        _completed('Garmin: $activities activities, health data');
      }
      if (auth.aktiiaConnected) {
        _completed('Aktiia: $bp blood pressure readings');
      }

      _phase('Apple Health…');
      final sleepPriority = await priorityForGroup(SourceGroup.sleep);
      await _syncHealth(sleepPriority);

      Future<void> integration(
        String name,
        Future<bool> connected,
        Future<void> Function() run,
      ) async {
        if (!await connected) return;
        log('[HistoricSync] $name ${days}d sync');
        _phase('$name: activities and health data…');
        try {
          await run();
          _completed('$name: activities and health data');
        } catch (e) {
          log('[HistoricSync] $name error: $e');
          _completed('$name: failed — $e');
        }
      }

      final polar = _ref.read(polarServiceProvider);
      final suunto = _ref.read(suuntoServiceProvider);
      final coros = _ref.read(corosServiceProvider);
      await Future.wait([
        integration('Polar', polar.isConnected, () async {
          await polar.sync(days: days);
          // AccessLink only reaches back 30 days; an optional Flow login reads
          // the older sessions during this one-time history import.
          if (!await polar.hasFlowLogin) return;
          _phase('Polar: older sessions from Flow…');
          try {
            final n = await polar.importFlowHistory(
              days: days,
              onProgress: _phase,
            );
            _completed('Polar Flow: $n older sessions');
          } catch (e) {
            log('[HistoricSync] Polar Flow error: $e');
            _completed('Polar Flow: older sessions failed — $e');
          }
        }),
        integration(
          'Suunto',
          suunto.isConnected,
          () => suunto.sync(days: days),
        ),
        integration('Coros', coros.isConnected, () => coros.sync(days: days)),
      ]);
      log('[HistoricSync] done — garmin=$garmin bp=$bp');

      _lastSyncDay = today;
      await _storage.write(
        key: _lastKey,
        value: today.millisecondsSinceEpoch.toString(),
      );
      await Future<void>.delayed(Duration.zero);

      _phase('Heart-rate zones and time in zone…');
      try {
        await _ref.read(hrZoneSyncProvider)();
        await _ref.read(zoneRecalculationProvider)();
        _completed('Heart-rate zones applied');
      } catch (e) {
        log('[HistoricSync] HR zone sync error: $e');
      }
      try {
        final zones = _ref.read(hrZonesProvider);
        await _ref
            .read(athleteThresholdsServiceProvider)
            .seedFromExistingData(runZoneFloors: zones.running.bounds);
      } catch (e) {
        log('[HistoricSync] threshold seed error: $e');
      }
      try {
        await _ref.read(workoutTemplateLibraryProvider).seedIfEmpty();
      } catch (e) {
        log('[HistoricSync] template seed error: $e');
      }
      _phase('Calibrating your training plan…');
      try {
        await _autoGeneratePlanIfNeeded(_ref, afterHistory: true);
        _completed('Training plan calibrated on your history');
      } catch (e) {
        log('[HistoricSync] auto-plan error: $e');
      }
      if (days >= 365) await _storage.write(key: _yearKey, value: '1');

      _ref.read(syncStatusListenerProvider.notifier).update((v) => v + 1);
      _ref.read(fullSyncListenerProvider.notifier).update((v) => v + 1);
      _ref.invalidate(heatTodayStateProvider);
      _ref.invalidate(heatForecastProvider);
    } catch (e) {
      log('[HistoricSync] ERROR — $e');
      if (mounted) {
        state = HistoricSyncState(
          done: true,
          failed: true,
          phase: 'History import stopped: $e',
          completed: state.completed,
        );
      }
      rethrow;
    }
    if (mounted && !_cancelled) {
      state = HistoricSyncState(done: true, completed: state.completed);
    }
  }

  /// 60-day Health backfill once, then 14-day top-ups. Deferred while a
  /// Garmin backfill ran this session to keep the first launch responsive.
  Future<void> _syncHealth(List<String> sleepPriority) async {
    try {
      final hc = _ref.read(healthConnectServiceProvider);
      var granted =
          _ref.read(healthConnectPermissionProvider).valueOrNull ?? false;
      if (!granted) {
        granted = await hc.requestPermissions();
        if (granted) {
          await _ref
              .read(healthConnectPermissionProvider.notifier)
              .markGranted();
        }
      }
      if (!granted) {
        await _storage.delete(key: _hcBackfillKey);
        return;
      }
      final backfillDone = await _storage.read(key: _hcBackfillKey) != null;
      if (!backfillDone && _garminRanThisSession) {
        log(
          '[HistoricSync] Health Connect 60d backfill deferred '
          '(Garmin ran this session)',
        );
      }
      final backfill = !backfillDone && !_garminRanThisSession;
      final days = backfill ? 60 : 14;
      log('[HistoricSync] Health Connect ${days}d sync (backfill=$backfill)');
      await hc.sync(days, sleepPriority);
      if (backfill) await _storage.write(key: _hcBackfillKey, value: '1');
      await hc.writeBack(
        _ref.read(hiloWriteHealthProvider),
        _ref.read(renphoWriteHealthProvider),
      );
    } catch (e) {
      log('[HistoricSync] Health Connect error: $e');
    }
  }
}

/// Whether any account or Apple Health is connected, i.e. there is (or soon
/// will be) real training history for the plan to learn from.
final hasHistorySourceProvider = Provider<bool>((ref) {
  bool on(AsyncValue<bool> v) => v.valueOrNull ?? false;
  return ref.watch(authProvider).garminConnected ||
      on(ref.watch(corosConnectedProvider)) ||
      on(ref.watch(suuntoConnectedProvider)) ||
      on(ref.watch(polarConnectedProvider)) ||
      on(ref.watch(healthConnectPermissionProvider));
});
