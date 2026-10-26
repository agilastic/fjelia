import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../models/device_connection.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import '../api/garmin_client.dart';
import '../api/polar_flow_web_client.dart';
import '../services/polar_service.dart';
import 'auth_provider.dart';
import 'coros_provider.dart';
import 'suunto_provider.dart';
import 'polar_provider.dart';
import 'health_connect_provider.dart';
export '../models/device_connection.dart';

final connectionActionsProvider = Provider<ConnectionActions>(
  (ref) => ConnectionActions(ref),
);

class ConnectionActions {
  ConnectionActions(this.ref);
  final Ref ref;
  Future<bool> signIn(
    ConnectionType type,
    String email,
    String password, {
    String? region,
  }) async {
    try {
      switch (type) {
        case ConnectionType.garmin:
          await ref.read(authProvider.notifier).loginGarmin(email, password);
        case ConnectionType.bloodPressure:
          await ref.read(authProvider.notifier).loginAktiia(email, password);
        case ConnectionType.bodyScale:
          await ref.read(authProvider.notifier).loginRenpho(email, password);
        case ConnectionType.coros:
          final ok = await ref
              .read(corosServiceProvider)
              .login(email, password, region: region ?? 'EU');
          ref.invalidate(corosConnectedProvider);
          ref.invalidate(corosEmailProvider);
          return ok;
        default:
          throw const ConnectionFailure('Unsupported sign-in method');
      }
      return true;
    } on GarminMfaRequiredException {
      throw const VerificationRequired();
    } on GarminAuthException catch (e) {
      throw ConnectionFailure(e.message);
    } on AktiiaAuthException catch (e) {
      throw ConnectionFailure(e.message);
    }
  }

  Future<void> verifyCode(String email, String code) async {
    try {
      await ref.read(authProvider.notifier).loginGarminMfa(email, code);
    } on GarminAuthException catch (e) {
      throw ConnectionFailure(e.message);
    }
  }

  Future<bool> requestSms(String phone) =>
      ref.read(suuntoServiceProvider).requestSmsPin(phone);
  Future<bool> verifySms(
    String phone,
    String pin, {
    required String email,
  }) async {
    final ok = await ref
        .read(suuntoServiceProvider)
        .verifyPin(phone, pin, email: email);
    ref.invalidate(suuntoConnectedProvider);
    ref.invalidate(suuntoEmailProvider);
    return ok;
  }

  Future<void> authorize() async {
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: PolarService.buildAuthUrl(),
        callbackUrlScheme: 'fjelia',
      );
      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) {
        throw const ConnectionFailure('No authorization code received.');
      }
      if (!await ref.read(polarServiceProvider).handleAuthCallback(code)) {
        throw const ConnectionFailure(
          'Authorization failed. Please try again.',
        );
      }
      ref.invalidate(polarConnectedProvider);
      ref.invalidate(polarEmailProvider);
    } on PlatformException catch (e) {
      throw ConnectionFailure(
        e.code.toLowerCase().contains('cancel')
            ? 'Cancelled.'
            : 'Connection failed. Check your internet connection.',
      );
    }
  }

  /// E-mail of the Flow login used for older history and planned workouts.
  Future<String?> polarFlowEmail() =>
      ref.read(polarServiceProvider).flowLoginEmail;

  /// Checks and stores the Polar Flow login. Throws [ConnectionFailure].
  Future<void> savePolarFlowLogin(String email, String password) async {
    try {
      await ref.read(polarServiceProvider).saveFlowLogin(email, password);
      ref.invalidate(polarFlowConnectedProvider);
    } on PolarFlowException catch (e) {
      throw ConnectionFailure(e.message);
    } catch (_) {
      throw const ConnectionFailure(
        'Could not reach Polar. Check your connection.',
      );
    }
  }

  Future<void> removePolarFlowLogin() async {
    await ref.read(polarServiceProvider).clearFlowLogin();
    ref.invalidate(polarFlowConnectedProvider);
  }

  Future<void> requestHealthAccess() async {
    if (await ref.read(healthConnectServiceProvider).requestPermissions()) {
      await ref.read(healthConnectPermissionProvider.notifier).markGranted();
    }
    ref.invalidate(healthConnectPermissionProvider);
  }

  Future<void> disconnect(ConnectionType type) async {
    switch (type) {
      case ConnectionType.garmin:
        await ref.read(authProvider.notifier).logoutGarmin();
      case ConnectionType.bloodPressure:
        await ref.read(authProvider.notifier).logoutAktiia();
      case ConnectionType.bodyScale:
        await ref.read(authProvider.notifier).logoutRenpho();
      case ConnectionType.coros:
        await ref.read(corosServiceProvider).disconnect();
        ref.invalidate(corosConnectedProvider);
        ref.invalidate(corosEmailProvider);
      case ConnectionType.suunto:
        await ref.read(suuntoServiceProvider).disconnect();
        ref.invalidate(suuntoConnectedProvider);
        ref.invalidate(suuntoEmailProvider);
      case ConnectionType.polar:
        await ref.read(polarServiceProvider).disconnect();
        ref.invalidate(polarFlowConnectedProvider);
        ref.invalidate(polarConnectedProvider);
        ref.invalidate(polarEmailProvider);
      case ConnectionType.health:
        throw const ConnectionFailure(
          'Manage health permissions in system settings.',
        );
    }
  }
}
