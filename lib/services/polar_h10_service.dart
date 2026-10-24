import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/spot_hrv.dart';

class H10Device {
  const H10Device(this.id, this.name, this.rssi);
  final String id, name;
  final int rssi;
}

/// The H10 the user paired with this phone, kept in secure storage.
class PolarH10Pairing {
  const PolarH10Pairing._();

  static const _storage = FlutterSecureStorage();
  static const _idKey = 'polar_h10_id';
  static const _nameKey = 'polar_h10_name';

  static Future<H10Device?> read() async {
    final id = await _storage.read(key: _idKey);
    if (id == null || id.isEmpty) return null;
    final name = await _storage.read(key: _nameKey);
    return H10Device(id, name ?? 'Polar H10', 0);
  }

  static Future<void> write(H10Device device) => Future.wait([
    _storage.write(key: _idKey, value: device.id),
    _storage.write(key: _nameKey, value: device.name),
  ]);

  static Future<void> clear() => Future.wait([
    _storage.delete(key: _idKey),
    _storage.delete(key: _nameKey),
  ]);
}

/// One foreground connection, independently of Polar cloud sign-in.
class PolarH10Service {
  final _packets = StreamController<H10HeartRatePacket>.broadcast();
  Stream<H10HeartRatePacket> get packets => _packets.stream;
  BluetoothDevice? _device;
  StreamSubscription<List<int>>? _notifications;
  StreamSubscription<BluetoothConnectionState>? _connection;
  bool _disposed = false, _ownsScan = false;

  Future<List<H10Device>> scan() async {
    if (!await FlutterBluePlus.isSupported) {
      throw StateError('Bluetooth is not supported on this device.');
    }
    final adapter = await FlutterBluePlus.adapterState
        .firstWhere((s) => s != BluetoothAdapterState.unknown)
        .timeout(const Duration(seconds: 5));
    if (adapter != BluetoothAdapterState.on) {
      throw StateError('Enable Bluetooth and allow Fjelia to use it.');
    }
    if (FlutterBluePlus.isScanningNow) {
      throw StateError(
        'Another Bluetooth scan is running. Please try again shortly.',
      );
    }
    final devices = <String, H10Device>{};
    final sub = FlutterBluePlus.onScanResults.listen((rows) {
      for (final row in rows) {
        final name = row.advertisementData.advName.isNotEmpty
            ? row.advertisementData.advName
            : row.device.platformName;
        if (name.toLowerCase().contains('polar h10')) {
          devices[row.device.remoteId.str] = H10Device(
            row.device.remoteId.str,
            name,
            row.rssi,
          );
        }
      }
    });
    try {
      if (_disposed) return [];
      _ownsScan = true;
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      await FlutterBluePlus.isScanning.where((s) => !s).first;
      return devices.values.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));
    } finally {
      await sub.cancel();
      if (_ownsScan) {
        _ownsScan = false;
        await FlutterBluePlus.stopScan();
      }
    }
  }

  Future<void> connect(H10Device found) async {
    if (_disposed) return;
    await disconnect();
    final device = BluetoothDevice.fromId(found.id);
    _device = device;
    try {
      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 15),
      );
      if (_disposed || _device != device) {
        await device.disconnect();
        return;
      }
      final services = await device.discoverServices().timeout(
        const Duration(seconds: 15),
      );
      if (_disposed || _device != device) {
        await device.disconnect();
        return;
      }
      BluetoothCharacteristic? measurement;
      for (final service in services) {
        if (service.uuid != Guid('180d')) continue;
        for (final c in service.characteristics) {
          if (c.uuid == Guid('2a37') && c.properties.notify) measurement = c;
        }
      }
      if (measurement == null) {
        throw StateError(
          'This sensor does not expose heart rate and RR notifications.',
        );
      }
      _notifications = measurement.onValueReceived.listen(
        (bytes) {
          if (_disposed || bytes.isEmpty) return;
          try {
            _packets.add(H10HeartRatePacket.decode(bytes));
          } on FormatException {
            _packets.addError(
              StateError(
                'Invalid sensor data. Reconnect and repeat the measurement.',
              ),
            );
          }
        },
        onError: (Object error) {
          if (!_disposed) _packets.addError(error);
        },
      );
      _connection = device.connectionState.listen((state) {
        if (!_disposed &&
            _device == device &&
            state == BluetoothConnectionState.disconnected) {
          _packets.addError(
            StateError('The Polar H10 disconnected. Repeat the measurement.'),
          );
        }
      });
      await measurement
          .setNotifyValue(true)
          .timeout(const Duration(seconds: 10));
      if (_disposed) {
        await disconnect();
      }
    } catch (_) {
      await disconnect();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    final device = _device;
    _device = null;
    await _notifications?.cancel();
    _notifications = null;
    await _connection?.cancel();
    _connection = null;
    if (device != null) {
      try {
        await device.disconnect();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    if (_ownsScan) {
      _ownsScan = false;
      await FlutterBluePlus.stopScan();
    }
    await disconnect();
    await _packets.close();
  }
}
