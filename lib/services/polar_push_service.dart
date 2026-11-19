import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/secrets.dart';
import '../utils/log.dart';
import 'polar_service.dart';

const polarPushChannel = MethodChannel('fjelia/polar_push');

/// "New Polar workout" pushes on iOS. Polar calls push.fjelia.com's webhook
/// when the watch has synced a workout; the server sends an APNs push to the
/// devices registered here for that Polar user. The webhook belongs to
/// Fjelia's own Polar client, so a client of the user's own (Fjelia CE) gets
/// none, and Android has no APNs.
class PolarPushService {
  PolarPushService(
    this._polar, {
    http.Client? client,
    this._channel = polarPushChannel,
    this._storage = const FlutterSecureStorage(),
    this._supported,
  }) : _http = client ?? http.Client();

  final PolarService _polar;
  final http.Client _http;
  final MethodChannel _channel;
  final FlutterSecureStorage _storage;
  final bool? _supported;

  static final devicesUri = Uri.https('push.fjelia.com', '/v1/devices');
  static final deleteUri = Uri.https('push.fjelia.com', '/v1/devices/delete');
  static const _registrationKey = 'polar_push_registration_v1';
  static const _installationKey = 'polar_push_installation_id_v1';
  // The server keeps a device until it is deleted; renewing now and then
  // keeps its record current without asking on every sync.
  static const _renewAfter = Duration(days: 7);
  static const _timeout = Duration(seconds: 20);

  bool get supported =>
      _supported ?? (Platform.isIOS && Secrets.polarViaServer);

  Future<void>? _registering;

  /// Registers this device for the connected Polar user. Cheap to call often:
  /// it only asks the server when the token, user or environment changed, or
  /// after [_renewAfter]; a call while one runs joins it. Never throws.
  Future<void> register({DateTime? now}) =>
      _registering ??= _register(now).whenComplete(() => _registering = null);

  Future<void> _register(DateTime? now) async {
    if (!supported) return;
    try {
      final credentials = await _polar.pushCredentials();
      if (credentials == null) return;
      final apnsToken = await _channel.invokeMethod<String>('register');
      final environment =
          await _channel.invokeMethod<String>('environment') ?? 'production';
      if (apnsToken == null) return;
      final installationId = await _installationId();
      final at = now ?? DateTime.now();
      final saved = await _saved();
      if (saved != null &&
          saved['installation_id'] == installationId &&
          saved['polar_user_id'] == credentials.userId &&
          saved['apns_token'] == apnsToken &&
          saved['environment'] == environment &&
          at.difference(DateTime.parse(saved['at'] as String)) < _renewAfter) {
        return;
      }
      final response = await _http
          .post(
            devicesUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'installation_id': installationId,
              'polar_user_id': credentials.userId,
              'polar_access_token': credentials.accessToken,
              'apns_token': apnsToken,
              'environment': environment,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode != 204) {
        log('[PolarPush] register failed: ${response.statusCode}');
        return;
      }
      await _storage.write(
        key: _registrationKey,
        value: jsonEncode({
          'installation_id': installationId,
          'polar_user_id': credentials.userId,
          'apns_token': apnsToken,
          'environment': environment,
          'at': at.toIso8601String(),
        }),
      );
      log('[PolarPush] registered ($environment)');
    } catch (e) {
      log('[PolarPush] register error: $e');
    }
  }

  /// Removes this device on the server, before Polar is disconnected.
  /// Never throws; a failed delete only means a push the app ignores.
  Future<void> unregister() async {
    final saved = await _saved();
    if (saved == null) return;
    try {
      final response = await _http
          .post(
            deleteUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'installation_id': saved['installation_id'],
              'apns_token': saved['apns_token'],
            }),
          )
          .timeout(_timeout);
      log('[PolarPush] unregistered: ${response.statusCode}');
    } catch (e) {
      log('[PolarPush] unregister error: $e');
    }
    await _storage.delete(key: _registrationKey);
  }

  /// True once when a tapped Polar push launched or reopened the app.
  Future<bool> takeOpened() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('takeOpened') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> _saved() async {
    try {
      final raw = await _storage.read(key: _registrationKey);
      return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<String> _installationId() async {
    final saved = await _storage.read(key: _installationKey);
    if (saved != null) return saved;
    final id = const Uuid().v4();
    await _storage.write(key: _installationKey, value: id);
    return id;
  }
}
