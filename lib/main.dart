import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'providers/day_data_provider.dart';
import 'providers/health_connect_provider.dart';
import 'providers/hilo_sync_provider.dart';
import 'providers/sync_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/startup_splash.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'services/debug_log.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'theme/app_theme.dart';
import 'widgets/health_access_lost_dialog.dart';
import 'widgets/hilo_device_picker.dart';

void main() {
  DebugLog.install(() async {
    WidgetsFlutterBinding.ensureInitialized();
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForPairingRequest();
      _listenForHealthAccessLost();
      _triggerSync();
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
    final sync = ref.read(syncProvider);
    if (sync.status == SyncStatus.syncing) return;
    final last = sync.lastSync;
    if (last == null || now.difference(last).inMinutes >= 15) _triggerSync();
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
    return MaterialApp(
      title: 'Fjelia',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
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
