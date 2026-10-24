import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/health_connect_service.dart';
import 'database_provider.dart';

/// Raised when Apple Health stopped answering and was disconnected, so the app
/// can tell the user once.
final healthAccessLostProvider = StateProvider<bool>((ref) => false);

final healthConnectServiceProvider = Provider<HealthConnectService>(
  (ref) => HealthConnectService(ref.read(databaseProvider)),
);

final healthConnectPermissionProvider =
    StateNotifierProvider<_HealthPermNotifier, AsyncValue<bool>>(
      _HealthPermNotifier.new,
    );

/// Write Hilo HRV/sleep/BP readings back to Apple Health.
final hiloWriteHealthProvider = StateNotifierProvider<BoolToggleNotifier, bool>(
  (ref) => BoolToggleNotifier('hilo_write_health_enabled', true),
);

/// Write Renpho weight back to Apple Health.
final renphoWriteHealthProvider =
    StateNotifierProvider<BoolToggleNotifier, bool>(
      (ref) => BoolToggleNotifier('renpho_write_health_enabled', true),
    );

/// A persisted on/off switch.
class BoolToggleNotifier extends StateNotifier<bool> {
  BoolToggleNotifier(this._key, bool initial) : super(initial) {
    _load();
  }

  final String _key;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? state;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

class _HealthPermNotifier extends StateNotifier<AsyncValue<bool>> {
  // ignore: avoid_unused_constructor_parameters
  _HealthPermNotifier(Ref ref) : super(const AsyncLoading()) {
    _load();
  }

  static const _key = 'health_permissions_granted';
  static const _revokedKey = 'health_access_revoked';

  /// Whether the last checks found Apple Health unreachable.
  Future<bool> isRevoked() async =>
      (await SharedPreferences.getInstance()).getBool(_revokedKey) ?? false;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = AsyncData(prefs.getBool(_key) ?? false);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    await prefs.remove(_revokedKey);
    state = const AsyncData(true);
  }

  Future<void> markRevoked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
    await prefs.setBool(_revokedKey, true);
    state = const AsyncData(false);
  }
}
