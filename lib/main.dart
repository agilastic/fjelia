import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'l10n/l10n_ext.dart';
import 'config/fjelia_pro.dart' show proAiModel;
import 'providers/activity_file_import_provider.dart';
import 'providers/ai_coach_provider.dart' show aiCoachSettingsProvider;
import 'services/ai_coach_settings.dart' show AiProvider;
import 'providers/auth_provider.dart';
import 'providers/fjelia_pro_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/style_provider.dart';
import 'theme/fjelia_style.dart';
import 'providers/day_data_provider.dart';
import 'providers/health_connect_provider.dart';
import 'providers/hilo_sync_provider.dart';
import 'providers/hrv_reminder_provider.dart';
import 'providers/hrv_training_provider.dart';
import 'providers/missed_workout_provider.dart';
import 'providers/plan_proposal_provider.dart';
import 'providers/nutrition_provider.dart';
import 'providers/planner_providers.dart' show upcomingSessionsProvider;
import 'screens/planner/missed_workout_sheet.dart';
import 'screens/planner/plan_proposal_cards.dart';
import 'services/missed_workout_reminder_service.dart';
import 'services/plan_proposal_notifications.dart' show PlanProposalPayload;
import 'widgets/nutrition_widgets.dart';
import 'services/notifications/local_notification_gateway.dart'
    as notifications;
import 'services/hrv/hrv_post_reminder_coordinator.dart'
    show ActionKind, ActionResult, HrvPostReminderCoordinator;
import 'screens/strain/activity_detail_sheet.dart';
import 'widgets/activity_file_import_sheet.dart';
import 'widgets/app_widgets.dart' show confirmAction, showAppSheet;
import 'widgets/polar_h10_hrv_sheet.dart';
import 'providers/sync_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/startup_splash.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'services/debug_log.dart';
import 'services/health_connect_service.dart';
import 'services/hrv/hrv_training_service.dart';
import 'services/hrv/post_hrv_missing.dart';
import 'services/local_model_licenses.dart';
import 'services/notifications/local_notification_adapter.dart';
import 'services/nutrition_reminder_service.dart';
import 'services/nutrition_service.dart';
import 'services/workout_background.dart';
import 'providers/database_provider.dart';
import 'utils/log.dart';

import 'package:fjelia_service_api/fjelia_service_api.dart';

import 'theme/app_theme.dart';
import 'widgets/health_access_lost_dialog.dart';
import 'widgets/hilo_device_picker.dart';
import 'widgets/keyboard_dismiss.dart';

void main() {
  DebugLog.install(() async {
    WidgetsFlutterBinding.ensureInitialized();
    registerLocalModelLicenses();
    await initializeDateFormatting();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    runApp(const ProviderScope(child: FjeliaApp()));
  });
}

/// Started by iOS in a headless engine when Apple Health reports a new
/// workout while the app is not running: imports it and schedules the
/// reminders, then tells the native side it is done.
@pragma('vm:entry-point')
Future<void> healthBackgroundMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    final strings = await currentLocalizations();
    final language = strings.localeName;
    setActiveLocale(Locale(language));
    final db = openAppDatabase();
    try {
      final gateway = FlutterLocalNotificationGateway(language: language);
      final training = HrvTrainingService(db);
      await checkNewWorkouts(
        healthConnected: appleHealthConnected,
        health: HealthConnectService(db),
        reconcileHrv: () => HrvPostReminderCoordinator(
          db: db,
          gateway: gateway,
          sensorReady: hrvStrapRemembered,
          training: training,
          language: language,
        ).reconcile(),
        nutrition: NutritionReminderService(
          NutritionService(db),
          gateway,
          postHrvMissing: (ids) => postHrvMissing(db, training, ids),
        ),
        missedWorkout: MissedWorkoutReminderService(db, gateway),
      ).timeout(healthBackgroundBudget);
    } finally {
      await db.close();
    }
  } catch (e) {
    log('[HealthBackground] check failed: $e');
  } finally {
    try {
      await healthBackgroundChannel.invokeMethod<void>('done');
    } catch (_) {}
  }
}

class FjeliaApp extends ConsumerStatefulWidget {
  const FjeliaApp({super.key});

  @override
  ConsumerState<FjeliaApp> createState() => _FjeliaAppState();
}

class _FjeliaAppState extends ConsumerState<FjeliaApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _nutritionOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForPairingRequest();
      _listenForHealthAccessLost();
      _listenForHealthWorkouts();
      _listenForPlanChanges();
      _listenForPro();
      _listenForActivityFiles();
      _triggerSync();
      unawaited(_startHrvReminders());
      // FjeliaPro listens to the App Store from the start (renewals,
      // interrupted purchases).
      ref.read(fjeliaProProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(planProposalLifecycleProvider).foreground());
      unawaited(ref.read(fjeliaProProvider.notifier).refresh());
      _onResume();
    } else if (state == AppLifecycleState.paused) {
      // Proposals not answered yet are told a few minutes later.
      unawaited(ref.read(planProposalLifecycleProvider).background());
    }
  }

  /// Jump back to today and resync when the app returns after a while.
  void _onResume() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (ref.read(selectedDateProvider) != today) {
      ref.read(selectedDateProvider.notifier).state = today;
    }
    // Permission, clock or time zone may have changed; an action may have
    // been left by the notification while the app was closed.
    unawaited(_startHrvReminders());
    final sync = ref.read(syncProvider);
    if (sync.status == SyncStatus.syncing) return;
    final last = sync.lastSync;
    if (last == null || now.difference(last).inMinutes >= 15) _triggerSync();
  }

  /// Settles the post-training HRV reminders, then lets queued notification
  /// actions in. Reconciling first means an action is judged on current data.
  Future<void> _startHrvReminders() async {
    try {
      // The reminder wording follows the saved language, so load it first.
      await ref.read(languageProvider.future);
      final router = ref.read(hrvActionRouterProvider);
      router.onResult = _onHrvAction;
      router.onOtherResponse = (r) =>
          MissedWorkoutPayload.decode(r.payload) != null
          ? _onMissedWorkoutAction(r)
          : PlanProposalPayload.decode(r.payload) != null
          ? _onPlanProposalAction(r)
          : _onNutritionAction(r);
      await Future.wait([
        ref
            .read(hrvReminderActionsProvider)
            .bootstrap()
            .catchError((Object _) {}),
        ref
            .read(nutritionReminderProvider)
            .reconcile()
            .catchError((Object _) {}),
        ref
            .read(missedWorkoutReminderProvider)
            .reconcile()
            .catchError((Object _) {}),
      ]);
      await router.markReady();
    } catch (_) {
      // Reminders are optional; the rest of the app does not depend on them.
    }
  }

  /// Waits (briefly) until the home screen is showing, so a sheet from a
  /// notification does not open over the startup artwork.
  Future<BuildContext?> _homeContext() async {
    for (var i = 0; i < 60; i++) {
      final context = _navigatorKey.currentContext;
      if (context != null &&
          ref.read(authProvider).status == LoginStatus.loggedIn) {
        return context;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return null;
  }

  Future<void> _onHrvAction(ActionResult result) async {
    final episodeId = result.episodeId;
    if (episodeId == null) return;
    final context = await _homeContext();
    if (context == null || !context.mounted) return;
    if (result.kind == ActionKind.startMeasurement) {
      if (ref.read(hrvCaptureActiveProvider)) {
        // One capture at a time: the running one stays in front.
        return;
      }
      final launch = await ref.read(hrvPostLaunchProvider(episodeId).future);
      if (!context.mounted) return;
      await showAppSheet(context, PolarH10HrvSheet(launch: launch));
      return;
    }
    final activity = await ref.read(episodeActivityProvider(episodeId).future);
    if (activity == null || !context.mounted) return;
    await showAppSheet(context, ActivityDetailSheet(activity: activity));
  }

  Future<void> _onNutritionAction(
    notifications.NotificationResponse response,
  ) async {
    if (_nutritionOpen) return;
    final id = await ref.read(nutritionReminderProvider).handle(response);
    if (id == null || !mounted) return;
    _nutritionOpen = true;
    try {
      final context = await _homeContext();
      if (context == null || !context.mounted) return;
      final activity = await ref.read(nutritionServiceProvider).activity(id);
      if (activity == null || !context.mounted) return;
      await showAppSheet(context, NutritionIntakeSheet(activity: activity));
    } finally {
      _nutritionOpen = false;
    }
  }

  Future<void> _onMissedWorkoutAction(
    notifications.NotificationResponse response,
  ) async {
    final action = await ref
        .read(missedWorkoutReminderProvider)
        .handle(response);
    if (action == null || !mounted) return;
    final context = await _homeContext();
    if (context == null || !context.mounted) return;
    await showAppSheet(
      context,
      MissedWorkoutSheet(day: action.day, intent: action.kind),
    );
  }

  Future<void> _onPlanProposalAction(
    notifications.NotificationResponse response,
  ) async {
    final p = PlanProposalPayload.decode(response.payload);
    if (p == null || !mounted) return;
    final lifecycle = ref.read(planProposalLifecycleProvider);
    if (response.actionId == 'keep') {
      await lifecycle.keepFromNotification(p.day);
      return;
    }
    final context = await _homeContext();
    if (context == null || !context.mounted) return;
    await showAppSheet(context, ReadinessProposalSheet(day: p.day));
  }

  /// FjeliaPro became active: Free AI turns into ProAI by itself, another
  /// provider is asked first. When it ends, a Pro model falls back to Free
  /// AI's own.
  void _listenForPro() {
    ref.listenManual<bool>(proSubscribedProvider, (was, now) async {
      if (was == null || was == now) return;
      final settings = await ref.read(aiCoachSettingsProvider.future);
      final notifier = ref.read(aiCoachSettingsProvider.notifier);
      if (!now) {
        if (settings.provider == AiProvider.freeAi &&
            settings.model != 'default') {
          await notifier.setModel('default');
        }
        return;
      }
      if (settings.provider == AiProvider.freeAi) {
        await notifier.setModel(proAiModel);
        return;
      }
      final context = await _homeContext();
      if (context == null || !context.mounted) return;
      final l = context.l10n;
      final provider = switch (settings.provider) {
        AiProvider.appleIntelligence => l.appleIntelligence,
        AiProvider.localQwen => l.localQwen,
        AiProvider.openai => l.openai,
        final p => p.name[0].toUpperCase() + p.name.substring(1),
      };
      if (await confirmAction(
        context,
        l.proSwitchTitle,
        l.proSwitchBody(provider),
      )) {
        await notifier.setProvider(AiProvider.freeAi);
        await notifier.setModel(proAiModel);
      }
    });
  }

  /// A moved, skipped or newly planned session changes which evenings need
  /// a reminder.
  void _listenForPlanChanges() {
    void reconcile() => unawaited(
      ref
          .read(missedWorkoutReminderProvider)
          .reconcile()
          .catchError((Object _) {}),
    );
    ref.listenManual(upcomingSessionsProvider, (prev, next) {
      if (next.hasValue) reconcile();
    });
    ref.listenManual(scheduledWorkoutsProvider, (prev, next) {
      if (next.hasValue) reconcile();
    });
  }

  /// FIT, GPX or TCX files opened in Fjelia from the share sheet or Files.
  void _listenForActivityFiles() {
    ActivityFileInbox().listen((files) async {
      final context = await _homeContext();
      if (context == null || !context.mounted) return;
      await showAppSheet(context, ActivityFileImportSheet(files: files));
    });
  }

  void _triggerSync() {
    ref.read(syncServiceProvider).migrateStrainToTrimp();
    ref.read(syncProvider.notifier).sync();
  }

  /// Opens the device picker when the Hilo service needs a bracelet chosen.
  void _listenForPairingRequest() {
    ref.listenManual<AsyncValue<HiloSyncState>>(hiloSyncStateProvider, (
      prev,
      next,
    ) {
      next.whenData((s) {
        if (s.status != HiloSyncStatus.needsPairing) return;
        final context = _navigatorKey.currentContext;
        if (context != null) HiloDevicePicker.show(context);
      });
    });
  }

  /// Apple Health reported a new workout while the app is alive, in front or
  /// suspended: import it and schedule the reminders here.
  void _listenForHealthWorkouts() {
    healthBackgroundChannel.setMethodCallHandler((call) async {
      if (call.method != 'workoutsChanged') return null;
      try {
        final added = await checkNewWorkouts(
          healthConnected: appleHealthConnected,
          health: ref.read(healthConnectServiceProvider),
          reconcileHrv: () => ref.read(hrvReminderActionsProvider).reconcile(),
          nutrition: ref.read(nutritionReminderProvider),
          missedWorkout: ref.read(missedWorkoutReminderProvider),
        ).timeout(healthBackgroundBudget);
        if (added > 0 && mounted) {
          ref.read(hrvActivitiesChangedProvider.notifier).state++;
          unawaited(ref.read(activityListProvider.notifier).refresh());
        }
      } catch (e) {
        log('[HealthBackground] check failed: $e');
      }
      return null;
    });
  }

  /// Shows a message once when Apple Health stopped answering and was
  /// disconnected.
  void _listenForHealthAccessLost() {
    ref.listenManual<bool>(healthAccessLostProvider, (prev, lost) {
      if (!lost) return;
      ref.read(healthAccessLostProvider.notifier).state = false;
      final context = _navigatorKey.currentContext;
      if (context != null) HealthAccessLostDialog.show(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    setActiveLocale(locale);
    return MaterialApp(
      title: 'Fjelia',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // The colours switch at once with the look, so the theme does too.
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => FjeliaStyleScope(
        child: DismissKeyboardOnTapOutside(child: child ?? const SizedBox()),
      ),
      home: const _AppRouter(),
    );
  }
}

/// Show the startup artwork for at least two seconds while checking logins.
class _AppRouter extends ConsumerStatefulWidget {
  const _AppRouter();

  @override
  ConsumerState<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<_AppRouter> {
  bool _timedOut = false;
  bool _splashFinished = false;
  late final Timer _authTimeout;

  @override
  void initState() {
    super.initState();
    _authTimeout = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _authTimeout.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authProvider).status;
    if (!_splashFinished || (status == LoginStatus.loading && !_timedOut)) {
      return StartupSplash(
        onMinimumElapsed: () {
          if (mounted) setState(() => _splashFinished = true);
        },
      );
    }
    return switch (status) {
      LoginStatus.loading => const WelcomeScreen(),
      LoginStatus.loggedIn => const HomeScreen(),
      LoginStatus.needsOnboarding => const WelcomeScreen(),
    };
  }
}
