import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher, Locale;

import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

import '../models/activity_location.dart';
import '../l10n/app_localizations.dart';

/// One native recording session shared by a workout and its ECG segments.
/// Android owns a foreground service/CPU wake lock; iOS uses Core Location and
/// Core Bluetooth background delivery. Screen locking is always allowed.
class ActivityBackground {
  ActivityBackground({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('fjelia/activity_recording') {
    _channel.setMethodCallHandler(_receive);
  }
  final MethodChannel _channel;
  final _owners = <String, ({bool gps, bool bluetooth, String name})>{};
  final _locations = StreamController<ActivityLocation>.broadcast();
  final _actions = StreamController<String>.broadcast();
  final _errors = StreamController<String>.broadcast();
  Stream<ActivityLocation> get locations => _locations.stream;
  Stream<String> get actions => _actions.stream;
  Stream<String> get errors => _errors.stream;
  Future<void> _writes = Future.value();
  bool _disposed = false;

  /// Native continuous time includes device sleep and ignores wall-clock edits.
  Future<int?> monotonicMilliseconds() async {
    try {
      return await _channel.invokeMethod<int>('clock');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> prepare({required bool gps, bool bluetooth = false}) async {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    if (gps) {
      final location = Location();
      if (!await location.serviceEnabled() &&
          !await location.requestService()) {
        throw StateError('Enable location services to record GPS.');
      }
      final permission = await location.requestPermission();
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.grantedLimited) {
        throw StateError('Allow location access, or turn off GPS recording.');
      }
    }
    if (Platform.isAndroid) {
      if (bluetooth) await permissions.Permission.bluetoothConnect.request();
      // A denied notification permission does not prevent a user-started FGS.
      await permissions.Permission.notification.request();
    }
  }

  Future<void> start(
    String owner, {
    required bool gps,
    required bool bluetooth,
    required String name,
  }) => _serial(() async {
    final previous = _owners[owner];
    _owners[owner] = (gps: gps, bluetooth: bluetooth, name: name);
    try {
      await _configure();
    } catch (_) {
      if (previous == null) {
        _owners.remove(owner);
      } else {
        _owners[owner] = previous;
      }
      // A native partial start must not leave GPS or a wake lock behind.
      try {
        await _configure();
      } catch (_) {
        /* Report the original failure. */
      }
      rethrow;
    }
  });

  Future<void> stop(String owner) => _serial(() async {
    _owners.remove(owner);
    await _configure();
  });

  Future<void> _serial(Future<void> Function() operation) {
    final result = _writes.then((_) => operation());
    _writes = result.catchError((Object _) {});
    return result;
  }

  Future<void> _configure() async {
    final locale = PlatformDispatcher.instance.locale;
    final supported = AppLocalizations.supportedLocales.any(
      (v) => v.languageCode == locale.languageCode,
    );
    final l = lookupAppLocalizations(supported ? locale : const Locale('en'));
    try {
      await _channel.invokeMethod<void>('configure', {
        'active': _owners.isNotEmpty,
        'gps': _owners.values.any((v) => v.gps),
        'bluetooth': _owners.values.any((v) => v.bluetooth),
        'name':
            (_owners['activity'] ?? _owners.values.firstOrNull)?.name ??
            'Fjelia',
        'notification': l.manualBackgroundNotification,
        'pause': l.indoorPause,
        'stop': l.indoorFinish,
      });
    } on MissingPluginException {
      if (Platform.isIOS || Platform.isAndroid) rethrow;
    }
  }

  Future<void> _receive(MethodCall call) async {
    if (_disposed) return;
    if (call.method == 'location' && call.arguments is Map) {
      final fix = ActivityLocation.decode(call.arguments as Map);
      if (fix != null) _locations.add(fix);
    } else if (call.method == 'action' && call.arguments is String) {
      _actions.add(call.arguments as String);
    } else if (call.method == 'error') {
      // Native messages are intentionally generic: no coordinates or vitals.
      _errors.add(
        'GPS is unavailable. Recording time and connected sensors continue.',
      );
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _serial(() async {
      _owners.clear();
      await _configure();
    });
    _channel.setMethodCallHandler(null);
    await _locations.close();
    await _actions.close();
    await _errors.close();
  }
}
