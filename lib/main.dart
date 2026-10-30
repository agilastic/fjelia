import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'l10n/l10n_ext.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/day_data_provider.dart';
import 'providers/health_connect_provider.dart';
import 'providers/hilo_sync_provider.dart';
import 'providers/hrv_reminder_provider.dart';
import 'providers/hrv_training_provider.dart';
import 'providers/nutrition_provider.dart';
import 'widgets/nutrition_widgets.dart';
import 'services/notifications/local_notification_gateway.dart'
    as notifications;
import 'services/hrv/hrv_post_reminder_coordinator.dart'
    show ActionKind, ActionResult;
import 'screens/strain/activity_detail_sheet.dart';
import 'widgets/app_widgets.dart' show showAppSheet;
import 'widgets/polar_h10_hrv_sheet.dart';
import 'providers/sync_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/startup_splash.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'services/debug_log.dart';
import 'services/local_model_licenses.dart';

import 'package:fjelia_service_api/fjelia_service_api.dart';

import 'theme/app_theme.dart';
import 'widgets/health_access_lost_dialog.dart';
import 'widgets/hilo_device_picker.dart';

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
      _triggerSync();
      unawaited(_startHrvReminders());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onResume();
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
      router.onOtherResponse = _onNutritionAction;
      await Future.wait([
        ref
            .read(hrvReminderActionsProvider)
            .bootstrap()
            .catchError((Object _) {}),
        ref
            .read(nutritionReminderProvider)
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
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeAnimationDuration: const Duration(milliseconds: 200),
      themeAnimationCurve: Curves.linear,
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
