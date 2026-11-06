import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/training_device.dart';
import '../models/training_ble_profile.dart';
export '../models/training_device.dart';

/// Shared scan ownership prevents these recording flows from stopping a scan
/// belonging to another Fjelia device. Discovery never opens a connection.
Future<List<TrainingDevice>> scanTrainingDevices({
  String? serviceUuid,
  List<String> serviceUuids = const [],
  String? nameContains,
}) async {
  await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
  if (!await FlutterBluePlus.isSupported) {
    throw StateError('Bluetooth is unavailable.');
  }
  final adapter = await FlutterBluePlus.adapterState
      .firstWhere((s) => s != BluetoothAdapterState.unknown)
      .timeout(const Duration(seconds: 8));
  if (adapter != BluetoothAdapterState.on) {
    throw StateError('Enable Bluetooth and allow Fjelia to use it.');
  }
  if (FlutterBluePlus.isScanningNow) {
    throw StateError('Another device scan is running. Try again shortly.');
  }
  final found = <String, TrainingDevice>{};
  final subscription = FlutterBluePlus.onScanResults.listen((results) {
    for (final r in results) {
      final name = r.advertisementData.advName.isEmpty
          ? r.device.platformName
          : r.advertisementData.advName;
      if (nameContains != null &&
          !name.toLowerCase().contains(nameContains.toLowerCase())) {
        continue;
      }
      found[r.device.remoteId.str] = TrainingDevice(
        id: r.device.remoteId.str,
        name: name.isEmpty ? 'Bluetooth fitness machine' : name,
        rssi: r.rssi,
      );
    }
  });
  var ownsScan = false;
  try {
    await FlutterBluePlus.startScan(
      withServices: [
        if (serviceUuid != null) Guid(serviceUuid),
        for (final uuid in serviceUuids) Guid(uuid),
      ],
      timeout: const Duration(seconds: 8),
    );
    ownsScan = true;
    await FlutterBluePlus.isScanning.firstWhere((s) => !s);
    return found.values.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));
  } finally {
    await subscription.cancel();
    if (ownsScan) await FlutterBluePlus.stopScan();
  }
}

class TrainingBleConnection {
  TrainingBleConnection({this.mtu = 512});
  final int? mtu;
  BluetoothDevice? _device;
  List<BluetoothService> services = [];
  StreamSubscription<BluetoothConnectionState>? _connection;
  final List<StreamSubscription<List<int>>> _subscriptions = [];
  bool _closing = false;
  void Function()? onDisconnected;

  TrainingBleReport report(TrainingDevice device) => TrainingBleReport(
    device: device,
    services: [
      for (final s in services)
        TrainingGattService(s.uuid.str, [
          for (final c in s.characteristics)
            TrainingGattCharacteristic(
              uuid: c.uuid.str,
              read: c.properties.read,
              write: c.properties.write || c.properties.writeWithoutResponse,
              notify: c.properties.notify,
              indicate: c.properties.indicate,
            ),
        ]),
    ],
  );

  BluetoothCharacteristic? characteristic(String service, String uuid) {
    for (final s in services) {
      if (s.uuid != Guid(service)) continue;
      for (final c in s.characteristics) {
        if (c.uuid == Guid(uuid)) return c;
      }
    }
    return null;
  }

  Future<void> connect(TrainingDevice found) async {
    await [Permission.bluetoothConnect].request();
    _closing = false;
    final device = BluetoothDevice.fromId(found.id);
    _device = device;
    try {
      await device.connect(
        autoConnect: false,
        mtu: mtu,
        timeout: const Duration(seconds: 15),
      );
      if (_closing || _device != device) {
        throw StateError('Connection cancelled.');
      }
      // PMD packets exceed the default ATT payload on Android.
      // flutter_blue_plus requests an MTU during Android connect by default.
      services = await device.discoverServices().timeout(
        const Duration(seconds: 15),
      );
      if (_closing || _device != device) {
        throw StateError('Connection cancelled.');
      }
      _connection = device.connectionState.listen((state) {
        if (!_closing && state == BluetoothConnectionState.disconnected) {
          onDisconnected?.call();
        }
      });
    } catch (_) {
      await close();
      rethrow;
    }
  }

  Future<void> subscribe(
    BluetoothCharacteristic c,
    void Function(List<int>) receive, {
    void Function(Object)? onError,
  }) async {
    if (!c.properties.notify && !c.properties.indicate) {
      throw StateError('The device does not provide notifications.');
    }
    _subscriptions.add(c.onValueReceived.listen(receive, onError: onError));
    await c.setNotifyValue(true).timeout(const Duration(seconds: 8));
  }

  Future<void> close() async {
    _closing = true;
    final device = _device;
    _device = null;
    await _connection?.cancel();
    _connection = null;
    final subscriptions = List.of(_subscriptions);
    _subscriptions.clear();
    for (final sub in subscriptions) {
      await sub.cancel();
    }
    services = [];
    try {
      await device?.disconnect();
    } catch (_) {
      /* Already disconnected. */
    }
  }
}
