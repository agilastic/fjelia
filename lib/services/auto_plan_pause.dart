import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Whether the daily sync may build a plan by itself.
///
/// Deleting all workouts is the athlete saying they want none, so the sync
/// must not bring a plan back and send it to the watch. It builds one again
/// only after the athlete generates a plan themselves.
class AutoPlanPause {
  const AutoPlanPause._();

  static const _key = 'auto_plan_paused_v1';
  static const _storage = FlutterSecureStorage();

  static Future<bool> get isPaused async =>
      await _storage.read(key: _key) != null;

  static Future<void> pause() => _storage.write(key: _key, value: '1');

  static Future<void> resume() => _storage.delete(key: _key);
}
