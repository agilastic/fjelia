import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

/// A blood pressure record read from a BLE monitor's local memory.
class OmronBpRecord {
  const OmronBpRecord({
    required this.measuredAt,
    required this.systolic,
    required this.diastolic,
    required this.heartRate,
    this.user = 1,
    this.irregularPulse = false,
    this.movement = false,
  });

  final DateTime measuredAt;
  final int systolic, diastolic, heartRate, user;
  final bool irregularPulse, movement;
}

class OmronFoundDevice {
  const OmronFoundDevice(
    this.id,
    this.name,
    this.rssi,
    this.advertisedServices,
  );
  final String id, name;
  final int rssi;
  final List<String> advertisedServices;

  bool get advertisesStandardBp => advertisedServices.contains(_bpService);
  bool get advertisesOmronProtocol => advertisedServices.any(
    (uuid) => uuid == _legacyParent || uuid == _modernParent,
  );

  String get advertisedCompatibility => advertisesStandardBp
      ? 'standard'
      : advertisesOmronProtocol
      ? 'omron'
      : 'unknown';
}

class OmronModelProfile {
  const OmronModelProfile({
    required this.model,
    required this.alias,
    required this.layout,
    required this.endian,
    required this.starts,
    required this.counts,
    required this.recordSize,
    required this.blockSize,
    this.parentService = _legacyParent,
    this.rx = _legacyRx,
    this.tx = _legacyTx,
    this.unlock = true,
  });

  final String model, alias, layout, endian, parentService;
  final List<int> starts, counts;
  final int recordSize, blockSize;
  final List<String> rx, tx;
  final bool unlock;
}

const _legacyParent = 'ecbe3980-c9a2-11e1-b1bd-0002a5d5c51b';
const _modernParent = '0000fe4a-0000-1000-8000-00805f9b34fb';
const _legacyRx = [
  '49123040-aee8-11e1-a74d-0002a5d5c51b',
  '4d0bf320-aee8-11e1-a0d9-0002a5d5c51b',
  '5128ce60-aee8-11e1-b84b-0002a5d5c51b',
  '560f1420-aee8-11e1-8184-0002a5d5c51b',
];
const _legacyTx = [
  'db5b55e0-aee7-11e1-965e-0002a5d5c51b',
  'e0b8a060-aee7-11e1-92f4-0002a5d5c51b',
  '0ae12b00-aee8-11e1-a192-0002a5d5c51b',
  '10e1ba60-aee8-11e1-89e5-0002a5d5c51b',
];
const _modernRx = ['49123040-aee8-11e1-a74d-0002a5d5c51b'];
const _modernTx = ['db5b55e0-aee7-11e1-965e-0002a5d5c51b'];
const _omronUnlockUuid = 'b305b680-aee7-11e1-a730-0002a5d5c51b';
const _bpService = '00001810-0000-1000-8000-00805f9b34fb';
const _bpMeasurement = '00002a35-0000-1000-8000-00805f9b34fb';
const _bpRacp = '00002a52-0000-1000-8000-00805f9b34fb';
const _omronOptionalService = '5df5e817-a945-4f81-89c0-3d4e9759c07c';
const standardBpModel = 'Bluetooth BP (standard)';

/// Models with a tested-readable EEPROM profile in the adopted omblepy
/// reference. Models with encrypted traffic are intentionally not guessed.
const omronModelProfiles = <OmronModelProfile>[
  OmronModelProfile(
    model: 'HEM-6232T',
    alias: 'RS7 Intelli IT',
    layout: 'classic14',
    endian: 'big',
    starts: [0x2e8, 0x860],
    counts: [100, 100],
    recordSize: 14,
    blockSize: 0x38,
  ),
  OmronModelProfile(
    model: 'HEM-7143T',
    alias: 'X2 Smart',
    layout: 'modern14',
    endian: 'little',
    starts: [0x2e8],
    counts: [30],
    recordSize: 14,
    blockSize: 0x2c,
    parentService: _modernParent,
    rx: _modernRx,
    tx: _modernTx,
    unlock: false,
  ),
  OmronModelProfile(
    model: 'HEM-7150T',
    alias: 'BP7250',
    layout: 'packed16',
    endian: 'little',
    starts: [0x0098],
    counts: [60],
    recordSize: 16,
    blockSize: 0x10,
  ),
  OmronModelProfile(
    model: 'HEM-7155T',
    alias: 'M4 Intelli IT',
    layout: 'packed16',
    endian: 'little',
    starts: [0x0098, 0x0458],
    counts: [60, 60],
    recordSize: 16,
    blockSize: 0x10,
  ),
  OmronModelProfile(
    model: 'HEM-7156T',
    alias: 'BP7250 family',
    layout: 'packed16',
    endian: 'little',
    starts: [0x0098, 0x0458],
    counts: [60, 60],
    recordSize: 16,
    blockSize: 0x10,
  ),
  OmronModelProfile(
    model: 'HEM-7280T',
    alias: 'MIT5s Connect',
    layout: 'classic14',
    endian: 'big',
    starts: [0x02ac, 0x0824],
    counts: [100, 100],
    recordSize: 14,
    blockSize: 0x38,
  ),
  OmronModelProfile(
    model: 'HEM-7322T',
    alias: 'M700 Intelli IT',
    layout: 'classic14',
    endian: 'big',
    starts: [0x02ac, 0x0824],
    counts: [100, 100],
    recordSize: 14,
    blockSize: 0x38,
  ),
  OmronModelProfile(
    model: 'HEM-7342T',
    alias: 'BP7450',
    layout: 'packed16',
    endian: 'little',
    starts: [0x0098, 0x06d8],
    counts: [100, 100],
    recordSize: 16,
    blockSize: 0x10,
  ),
  OmronModelProfile(
    model: 'HEM-7361T',
    alias: 'X7 Smart · HEM-7361T-ESL',
    layout: 'packed16',
    endian: 'little',
    starts: [0x0098, 0x06d8],
    counts: [100, 100],
    recordSize: 16,
    blockSize: 0x10,
  ),
  OmronModelProfile(
    model: 'HEM-7377T',
    alias: 'BP5360',
    layout: 'modern16',
    endian: 'little',
    starts: [0x01cc, 0x080c],
    counts: [100, 100],
    recordSize: 16,
    blockSize: 0x38,
    parentService: _modernParent,
    rx: _modernRx,
    tx: _modernTx,
    unlock: false,
  ),
  OmronModelProfile(
    model: 'HEM-7380T',
    alias: 'X7 Smart AFib / M7 AFib',
    layout: 'modern16',
    endian: 'little',
    starts: [0x01c4, 0x0804],
    counts: [100, 100],
    recordSize: 16,
    blockSize: 0x10,
    parentService: _modernParent,
    rx: _modernRx,
    tx: _modernTx,
    unlock: false,
  ),
  OmronModelProfile(
    model: 'HEM-7381T',
    alias: 'BP7465 / 10 Series',
    layout: 'modern16',
    endian: 'little',
    starts: [0x080c, 0x0e4c],
    counts: [100, 100],
    recordSize: 16,
    blockSize: 0x10,
    parentService: _modernParent,
    rx: _modernRx,
    tx: _modernTx,
    unlock: false,
  ),
  OmronModelProfile(
    model: 'HEM-7530T',
    alias: 'Omron Complete (no ECG)',
    layout: 'classic14',
    endian: 'big',
    starts: [0x02e8],
    counts: [90],
    recordSize: 14,
    blockSize: 0x10,
  ),
  OmronModelProfile(
    model: 'HEM-7600T',
    alias: 'EVOLV',
    layout: 'classic14',
    endian: 'big',
    starts: [0x02ac],
    counts: [100],
    recordSize: 14,
    blockSize: 0x38,
  ),
];

/// BLE EEPROM reader for Omron profiles. It only reads measurement memory:
/// clock synchronization and unread-counter reset are deliberately omitted.
class OmronBleService {
  static const _pairingKeyName = 'omron_ble_pairing_keys_v1';
  static const _storage = FlutterSecureStorage();

  Future<List<OmronFoundDevice>> scan() async {
    await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
    if (!await FlutterBluePlus.isSupported) {
      throw StateError('Bluetooth is not available on this device.');
    }
    final found = <String, OmronFoundDevice>{};
    final sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final name = r.advertisementData.advName.isNotEmpty
            ? r.advertisementData.advName
            : r.device.platformName;
        // Omron cuffs often advertise a generic or empty name rather than
        // "Omron"/"HEM". Keep every nearby BLE advertisement so the user can
        // identify it by its label/RSSI; connect() verifies the Omron service
        // UUID before any pairing or memory read is attempted.
        final hasOmronService = r.advertisementData.serviceUuids.any(
          (service) =>
              service.str128.toLowerCase() == _legacyParent ||
              service.str128.toLowerCase() == _modernParent,
        );
        final hasStandardBpService = r.advertisementData.serviceUuids.any(
          (service) => service.str128.toLowerCase() == _bpService,
        );
        final recognized =
            name.toLowerCase().contains('omron') ||
            RegExp(r'HEM[-_ ]?\d', caseSensitive: false).hasMatch(name) ||
            hasOmronService ||
            hasStandardBpService;
        final advertisedServices = r.advertisementData.serviceUuids
            .map((service) => service.str128.toLowerCase())
            .toList(growable: false);
        found[r.device.remoteId.str] = OmronFoundDevice(
          r.device.remoteId.str,
          name.isEmpty
              ? hasStandardBpService
                    ? 'Bluetooth blood-pressure monitor'
                    : recognized
                    ? 'Omron monitor'
                    : 'Unknown BLE device'
              : name,
          r.rssi,
          advertisedServices,
        );
      }
    });
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      await FlutterBluePlus.isScanning.firstWhere((scanning) => !scanning);
      return found.values.toList()..sort((a, b) {
        final byCompatibility = _compatibilityRank(
          a,
        ).compareTo(_compatibilityRank(b));
        return byCompatibility != 0
            ? byCompatibility
            : b.rssi.compareTo(a.rssi);
      });
    } finally {
      await sub.cancel();
      await FlutterBluePlus.stopScan();
    }
  }

  Future<List<OmronBpRecord>> readRecords({
    required String deviceId,
    String? model,
    required bool authorizeFirstPairing,
    void Function(String status)? onStatus,
  }) async {
    if (model == null || model == standardBpModel) {
      return _readStandardBp(deviceId, onStatus: onStatus);
    }
    final profile = omronModelProfiles.firstWhere(
      (p) => p.model == model,
      orElse: () => throw ArgumentError.value(model, 'model', 'Unsupported'),
    );
    final device = BluetoothDevice.fromId(deviceId);
    final pairings = await _readPairings();
    final rememberedModel = pairings[deviceId]?['model'];
    if (rememberedModel != null && rememberedModel != model) {
      throw StateError(
        'This monitor was paired as $rememberedModel. Select that exact model.',
      );
    }
    var key = pairings[deviceId]?['key'];
    if (profile.unlock && key == null) {
      if (!authorizeFirstPairing) {
        throw StateError('First pairing requires explicit user confirmation.');
      }
      key = _newKey();
    }
    final connection = _OmronConnection(device, profile, onStatus);
    try {
      onStatus?.call('Connecting to ${profile.model}…');
      await connection.connect();
      if (!profile.unlock) {
        // For these models the operating system must already have bonded the
        // cuff, or will display its native pairing prompt on protected access.
      } else if (pairings[deviceId]?['key'] == null) {
        await connection.programPairingKey(key!);
        pairings[deviceId] = {'key': key, 'model': model};
        await _storage.write(key: _pairingKeyName, value: jsonEncode(pairings));
      }
      onStatus?.call('Reading stored measurements…');
      final records = await connection.readRecords(key: key);
      pairings[deviceId] = {'key': ?key, 'model': model};
      await _storage.write(key: _pairingKeyName, value: jsonEncode(pairings));
      onStatus?.call('Saving ${records.length} readings…');
      return records;
    } finally {
      await connection.close();
    }
  }

  Future<List<OmronBpRecord>> _readStandardBp(
    String deviceId, {
    void Function(String status)? onStatus,
  }) async {
    final device = BluetoothDevice.fromId(deviceId);
    onStatus?.call('Connecting to Bluetooth blood-pressure monitor…');
    await device.connect(
      autoConnect: false,
      timeout: const Duration(seconds: 15),
    );
    StreamSubscription<List<int>>? measurementSub;
    StreamSubscription<List<int>>? racpSub;
    StreamSubscription<BluetoothConnectionState>? connectionSub;
    Timer? quietTimer;
    BluetoothCharacteristic? measurement;
    BluetoothCharacteristic? racp;
    BluetoothCharacteristic? omronRacp;
    BluetoothCharacteristic? standardRacp;
    BluetoothCharacteristic? otherRacp;
    try {
      final services = await device.discoverServices();
      final service = services.where((s) => s.uuid == Guid(_bpService));
      if (service.isEmpty) {
        throw StateError(
          'The device does not expose the standard Bluetooth blood-pressure service. Select its exact Omron model profile and try again.',
        );
      }
      for (final characteristic in service.first.characteristics) {
        if (characteristic.uuid == Guid(_bpMeasurement)) {
          measurement = characteristic;
        }
      }
      // OMRON places the standard RACP characteristic in its optional service
      // on some models; generic cuffs usually expose it under 0x1810.
      for (final gattService in services) {
        for (final characteristic in gattService.characteristics) {
          if (characteristic.uuid != Guid(_bpRacp)) continue;
          if (gattService.uuid == Guid(_omronOptionalService)) {
            omronRacp = characteristic;
          } else if (gattService.uuid == Guid(_bpService)) {
            standardRacp = characteristic;
          } else {
            otherRacp = characteristic;
          }
        }
      }
      // Keep a generic RACP characteristic for devices that use that path.
      racp = omronRacp ?? standardRacp ?? otherRacp;
      final bpMeasurement = measurement;
      final recordAccess = racp;
      final deviceName = '${device.platformName} ${device.advName}'
          .toLowerCase();
      final identifiedAsOmron =
          deviceName.contains('omron') ||
          RegExp(r'hem[-_ ]?\d', caseSensitive: false).hasMatch(deviceName);
      final omronPushTransfer =
          identifiedAsOmron ||
          services.any(
            (gattService) => gattService.uuid == Guid(_omronOptionalService),
          );
      if (bpMeasurement == null ||
          !(bpMeasurement.properties.notify ||
              bpMeasurement.properties.indicate)) {
        throw StateError(
          'The standard blood-pressure service has no readable measurement characteristic.',
        );
      }
      if (!omronPushTransfer &&
          (recordAccess == null ||
              !(recordAccess.properties.write ||
                  recordAccess.properties.writeWithoutResponse) ||
              !(recordAccess.properties.notify ||
                  recordAccess.properties.indicate))) {
        throw StateError(
          'The standard measurement service is present, but this monitor exposes no stored readings through RACP. Fjelia cannot import its history yet.',
        );
      }

      final records = <OmronBpRecord>[];
      final pushFinished = Completer<void>();
      var receivedPushRecord = false;
      final storedRecordCount = Completer<int>();
      final reportDone = Completer<void>();
      measurementSub = bpMeasurement.onValueReceived.listen((bytes) {
        final record = _parseStandardMeasurement(bytes);
        if (record != null) {
          records.add(record);
          if (omronPushTransfer) {
            receivedPushRecord = true;
            quietTimer?.cancel();
            quietTimer = Timer(const Duration(seconds: 15), () {
              if (!pushFinished.isCompleted) pushFinished.complete();
            });
          }
        }
      });
      if (omronPushTransfer) {
        // The OMRON Telehealth client enables 2A35 notifications and lets the
        // monitor push its saved measurements. It does not write RACP here.
        connectionSub = device.connectionState.listen((state) {
          if (state == BluetoothConnectionState.disconnected &&
              !pushFinished.isCompleted) {
            pushFinished.complete();
          }
        });
      } else {
        racpSub = recordAccess!.onValueReceived.listen((bytes) {
          if (bytes.length < 4 || bytes[1] != 0x00) return;
          if (bytes[0] == 0x05 && !storedRecordCount.isCompleted) {
            // Number Of Stored Records Response: opcode, operator, uint16 LE.
            storedRecordCount.complete(bytes[2] | (bytes[3] << 8));
          } else if (bytes[0] == 0x06) {
            // Response Code: opcode, operator, request opcode, response value.
            final requestOpcode = bytes[2];
            final response = bytes[3];
            if (requestOpcode == 0x04 && !storedRecordCount.isCompleted) {
              storedRecordCount.completeError(
                StateError(
                  'The monitor rejected the record-count request (RACP $response).',
                ),
              );
            } else if (requestOpcode == 0x01 && !reportDone.isCompleted) {
              if (response == 0x01) {
                reportDone.complete();
              } else {
                reportDone.completeError(
                  StateError(
                    'The monitor rejected the stored-reading request (RACP $response).',
                  ),
                );
              }
            }
          }
        });
      }
      await bpMeasurement.setNotifyValue(true);
      if (omronPushTransfer) {
        onStatus?.call(
          'Waiting for the Omron monitor to send saved measurements…',
        );
        try {
          await pushFinished.future.timeout(const Duration(seconds: 45));
        } on TimeoutException {
          if (!receivedPushRecord) {
            throw StateError(
              'The Omron monitor did not send any saved readings. Start its data transfer again and keep the screen open.',
            );
          }
        }
        final unique = <String, OmronBpRecord>{};
        for (final record in records) {
          unique['${record.user}/${record.measuredAt.millisecondsSinceEpoch}'] =
              record;
        }
        return unique.values.toList()
          ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
      }
      await recordAccess!.setNotifyValue(true);
      onStatus?.call('Requesting stored-measurement count (RACP 04 01)…');
      // Generic Bluetooth BP monitors expose stored records through RACP.
      try {
        await recordAccess.write([0x04, 0x01], withoutResponse: false);
      } catch (error) {
        throw StateError(
          'RACP count request failed on ${recordAccess.serviceUuid.str128} '
          '(connected=${device.isConnected}): $error',
        );
      }
      final count = await storedRecordCount.future.timeout(
        const Duration(seconds: 15),
      );
      if (count == 0) return const [];
      onStatus?.call('Reading $count stored measurements…');
      if (!device.isConnected) {
        throw StateError(
          'The monitor disconnected after reporting $count stored measurements.',
        );
      }
      try {
        await recordAccess.write([0x01, 0x01], withoutResponse: false);
      } catch (error) {
        throw StateError(
          'RACP record request failed on ${recordAccess.serviceUuid.str128} '
          'after count=$count (connected=${device.isConnected}): $error',
        );
      }
      await reportDone.future.timeout(const Duration(seconds: 45));
      final unique = <String, OmronBpRecord>{};
      for (final record in records) {
        unique['${record.user}/${record.measuredAt.millisecondsSinceEpoch}'] =
            record;
      }
      return unique.values.toList()
        ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    } finally {
      await measurementSub?.cancel();
      await racpSub?.cancel();
      await connectionSub?.cancel();
      quietTimer?.cancel();
      if (measurement != null) {
        try {
          await measurement.setNotifyValue(false);
        } catch (_) {}
      }
      if (racp != null) {
        try {
          await racp.setNotifyValue(false);
        } catch (_) {}
      }
      if (device.isConnected) await device.disconnect();
    }
  }

  OmronBpRecord? _parseStandardMeasurement(List<int> bytes) {
    if (bytes.length < 7) return null;
    var offset = 0;
    final flags = bytes[offset++];
    final pressureIsKpa = (flags & 0x01) != 0;
    double sfloat() {
      if (offset + 1 >= bytes.length) throw const FormatException();
      final raw = bytes[offset] | (bytes[offset + 1] << 8);
      offset += 2;
      var mantissa = raw & 0x0fff;
      if ((mantissa & 0x0800) != 0) mantissa -= 0x1000;
      var exponent = (raw >> 12) & 0x0f;
      if ((exponent & 0x08) != 0) exponent -= 0x10;
      return mantissa * pow(10, exponent).toDouble();
    }

    try {
      double pressure() {
        final value = sfloat();
        return pressureIsKpa ? value * 7.50062 : value;
      }

      final sys = pressure();
      final dia = pressure();
      pressure(); // Mean arterial pressure, not persisted by this app.
      // This importer reads historical records. Never assign the current time
      // to a record whose device omitted its timestamp.
      if ((flags & 0x02) == 0 || offset + 6 >= bytes.length) return null;
      final year = bytes[offset] | (bytes[offset + 1] << 8);
      final month = bytes[offset + 2];
      final day = bytes[offset + 3];
      final hour = bytes[offset + 4];
      final minute = bytes[offset + 5];
      final second = bytes[offset + 6];
      offset += 7;
      if (year < 1900 ||
          month < 1 ||
          month > 12 ||
          day < 1 ||
          day > 31 ||
          hour > 23 ||
          minute > 59 ||
          second > 59) {
        return null;
      }
      final measuredAt = DateTime(year, month, day, hour, minute, second);
      if (measuredAt.year != year ||
          measuredAt.month != month ||
          measuredAt.day != day) {
        return null;
      }
      var pulse = 0.0;
      if ((flags & 0x04) != 0) pulse = sfloat();
      var user = 1;
      if ((flags & 0x08) != 0) {
        if (offset >= bytes.length) return null;
        user = max(1, bytes[offset++]);
      }
      var irregular = false;
      var movement = false;
      if ((flags & 0x10) != 0) {
        if (offset >= bytes.length) return null;
        irregular = (bytes[offset] & 0x04) != 0;
        movement = (bytes[offset] & 0x01) != 0;
      }
      final systolic = sys.round();
      final diastolic = dia.round();
      final heartRate = pulse.round();
      if (systolic < 50 ||
          systolic > 300 ||
          diastolic < 20 ||
          diastolic > 200 ||
          systolic <= diastolic ||
          heartRate < 0 ||
          heartRate > 240) {
        return null;
      }
      return OmronBpRecord(
        measuredAt: measuredAt,
        systolic: systolic,
        diastolic: diastolic,
        heartRate: heartRate,
        user: user,
        irregularPulse: irregular,
        movement: movement,
      );
    } on FormatException {
      return null;
    }
  }

  Future<bool> needsPairing(String deviceId, String model) async {
    if (model == standardBpModel) return false;
    final profile = omronModelProfiles.firstWhere((p) => p.model == model);
    return profile.unlock && (await _readPairings())[deviceId]?['key'] == null;
  }

  int _compatibilityRank(OmronFoundDevice device) =>
      switch (device.advertisedCompatibility) {
        'standard' => 0,
        'omron' => 1,
        _ => 2,
      };

  Future<String?> pairedModel(String deviceId) async =>
      (await _readPairings())[deviceId]?['model'];

  Future<Map<String, Map<String, String>>> _readPairings() async {
    final raw = await _storage.read(key: _pairingKeyName);
    if (raw == null) return {};
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      return parsed.map((id, value) {
        if (value is String) return MapEntry(id, {'key': value});
        return MapEntry(
          id,
          (value as Map<String, dynamic>).map(
            (key, item) => MapEntry(key, item as String),
          ),
        );
      });
    } catch (_) {
      return {};
    }
  }

  String _newKey() => List<int>.generate(
    16,
    (_) => Random.secure().nextInt(256),
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

class _OmronConnection {
  _OmronConnection(this.device, this.profile, this.onStatus);
  final BluetoothDevice device;
  final OmronModelProfile profile;
  final void Function(String)? onStatus;
  final _rx = <BluetoothCharacteristic>[];
  final _tx = <BluetoothCharacteristic>[];
  final _rxSubscriptions = <StreamSubscription<List<int>>>[];
  BluetoothCharacteristic? _unlock;
  final _buffers = <int, List<int>>{};
  StreamSubscription<List<int>>? _unlockSub;
  Completer<List<int>>? _response;
  Completer<List<int>>? _unlockResponse;

  Future<void> connect() async {
    await device.connect(
      autoConnect: false,
      timeout: const Duration(seconds: 15),
    );
    final services = await device.discoverServices();
    if (!services.any((s) => s.uuid == Guid(profile.parentService))) {
      throw StateError('Selected Omron profile does not match this device.');
    }
    for (final uuid in profile.rx) {
      final c = _characteristic(services, uuid);
      if (c == null) throw StateError('Omron response channel is missing.');
      _rx.add(c);
      await c.setNotifyValue(true);
      _rxSubscriptions.add(
        c.onValueReceived.listen((data) => _onRx(_rx.indexOf(c), data)),
      );
    }
    for (final uuid in profile.tx) {
      final c = _characteristic(services, uuid);
      if (c == null) throw StateError('Omron command channel is missing.');
      _tx.add(c);
    }
    if (profile.unlock) {
      _unlock = _characteristic(services, _omronUnlockUuid);
      if (_unlock == null) throw StateError('Omron unlock channel is missing.');
    }
  }

  BluetoothCharacteristic? _characteristic(
    List<BluetoothService> services,
    String uuid,
  ) {
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == Guid(uuid)) return characteristic;
      }
    }
    return null;
  }

  void _onRx(int channel, List<int> chunk) {
    _buffers[channel] = chunk;
    if (_buffers[0] == null) return;
    List<int> packet;
    if (_rx.length == 1) {
      packet = _buffers[0]!;
      _buffers.clear();
    } else {
      final expectedBytes = _buffers[0]![0];
      final channels = (expectedBytes + 15) ~/ 16;
      if (List.generate(channels, (i) => _buffers[i]).any((v) => v == null)) {
        return;
      }
      packet = [
        for (var i = 0; i < channels; i++) ..._buffers[i]!,
      ].take(expectedBytes).toList();
      _buffers.clear();
    }
    if (packet.fold<int>(0, (sum, b) => sum ^ b) != 0 || packet.length < 8) {
      return;
    }
    final completer = _response;
    if (completer != null && !completer.isCompleted) completer.complete(packet);
  }

  Future<List<int>> _command(List<int> command) async {
    Object? lastError;
    for (var attempt = 0; attempt < 5; attempt++) {
      _response = Completer<List<int>>();
      var rest = command;
      var index = 0;
      final width = _tx.length == 1 ? max(16, command.length) : 16;
      while (rest.isNotEmpty) {
        final part = rest.take(width).toList();
        rest = rest.skip(part.length).toList();
        await _tx[index++].write(part, withoutResponse: _tx.length == 1);
      }
      try {
        return await _response!.future.timeout(const Duration(seconds: 2));
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError('No response from Omron monitor: $lastError');
  }

  Future<void> _unlockWithKey(String key) async {
    final characteristic = _unlock!;
    _unlockSub = characteristic.onValueReceived.listen((value) {
      final response = _unlockResponse;
      if (response != null && !response.isCompleted) response.complete(value);
    });
    await characteristic.setNotifyValue(true);
    final response = _unlockResponse = Completer<List<int>>();
    await characteristic.write([1, ..._hex(key)], withoutResponse: false);
    final value = await response.future.timeout(const Duration(seconds: 8));
    if (value.length < 2 || value[0] != 0x81 || value[1] != 0x00) {
      throw StateError('Omron pairing key was rejected. Pair it again.');
    }
    await characteristic.setNotifyValue(false);
    await _unlockSub?.cancel();
    _unlockSub = null;
  }

  Future<void> programPairingKey(String key) async {
    final unlock = _unlock!;
    _unlockSub = unlock.onValueReceived.listen((value) {
      final response = _unlockResponse;
      if (response != null && !response.isCompleted) response.complete(value);
    });
    // Trigger the device's native BLE security prompt, then enter key mode.
    await _rx.first.setNotifyValue(true);
    await unlock.setNotifyValue(true);
    List<int>? response;
    for (var attempt = 0; attempt < 10; attempt++) {
      final next = _unlockResponse = Completer<List<int>>();
      await unlock.write([
        2,
        ...List<int>.filled(16, 0),
      ], withoutResponse: false);
      try {
        response = await next.future.timeout(const Duration(seconds: 2));
      } catch (_) {
        response = null;
      }
      if (response != null && response.length >= 2 && response[0] == 0x82) {
        break;
      }
      response = null;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    if (response == null) {
      throw StateError(
        'Put the Omron monitor into Bluetooth pairing mode and try again.',
      );
    }
    final programmed = Completer<List<int>>();
    _unlockResponse = programmed;
    await _unlockSub?.cancel();
    _unlockSub = unlock.onValueReceived.listen((value) {
      if (!programmed.isCompleted) programmed.complete(value);
    });
    await unlock.write([0, ..._hex(key)], withoutResponse: false);
    final result = await programmed.future.timeout(const Duration(seconds: 8));
    if (result.length < 2 || result[0] != 0x80 || result[1] != 0) {
      throw StateError('Omron pairing could not be completed.');
    }
    await unlock.setNotifyValue(false);
    await _unlockSub?.cancel();
    _unlockSub = null;
    await startTransmission();
    await endTransmission();
  }

  Future<List<OmronBpRecord>> readRecords({String? key}) async {
    if (profile.unlock) await _unlockWithKey(key!);
    await startTransmission();
    final records = <OmronBpRecord>[];
    try {
      for (var user = 0; user < profile.starts.length; user++) {
        onStatus?.call('Reading user ${user + 1}…');
        final length = profile.counts[user] * profile.recordSize;
        final bytes = await _readContinuous(
          profile.starts[user],
          length,
          profile.blockSize,
        );
        for (
          var offset = 0;
          offset + profile.recordSize <= bytes.length;
          offset += profile.recordSize
        ) {
          final raw = bytes.sublist(offset, offset + profile.recordSize);
          if (raw.every((b) => b == 0xff)) continue;
          final record = _parse(raw, user + 1);
          if (record != null) records.add(record);
        }
      }
    } finally {
      await endTransmission();
    }
    final unique = <String, OmronBpRecord>{};
    for (final record in records) {
      unique['${record.user}/${record.measuredAt.millisecondsSinceEpoch}'] =
          record;
    }
    return unique.values.toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
  }

  Future<void> startTransmission() async {
    final packet = await _command([8, 0, 0, 0, 0, 16, 0, 24]);
    if (packet[1] != 0x80 || packet[2] != 0) {
      throw StateError('Omron data transfer could not start.');
    }
  }

  Future<void> endTransmission() async {
    final packet = await _command([8, 15, 0, 0, 0, 0, 0, 7]);
    if (packet[1] != 0x8f || packet[2] != 0 || packet[6] != 0) {
      throw StateError('Omron data transfer did not finish cleanly.');
    }
  }

  Future<List<int>> _readContinuous(
    int address,
    int count,
    int blockSize,
  ) async {
    final out = <int>[];
    while (count > 0) {
      final size = min(count, min(blockSize, 56));
      final command = [8, 1, 0, (address >> 8) & 255, address & 255, size];
      var crc = 0;
      for (final byte in command) {
        crc ^= byte;
      }
      command.addAll([0, crc]);
      final packet = await _command(command);
      if (packet[1] != 0x81 ||
          packet[2] != 0 ||
          packet[3] != ((address >> 8) & 255) ||
          packet[4] != (address & 255)) {
        throw StateError('Omron returned an invalid memory block.');
      }
      final received = packet[5];
      if (received != size || packet.length < 8 + size) {
        throw StateError('Omron returned an incomplete memory block.');
      }
      out.addAll(packet.sublist(6, 6 + size));
      count -= size;
      address += size;
    }
    return out;
  }

  OmronBpRecord? _parse(List<int> raw, int user) {
    final bits = _bits(raw);
    int b(int first, int last) =>
        bits >> (raw.length * 8 - last - 1) & ((1 << (last - first + 1)) - 1);
    int dia, sys, hr, year, month, day, hour, minute, second, mov = 0, ihb = 0;
    switch (profile.layout) {
      case 'classic14':
        dia = b(0, 7);
        sys = b(8, 15) + 25;
        year = b(16, 23) + 2000;
        hr = b(24, 31);
        mov = b(32, 32);
        ihb = b(33, 33);
        month = b(34, 37);
        day = b(38, 42);
        hour = b(43, 47);
        minute = b(52, 57);
        second = min(b(58, 63), 59);
      case 'modern14':
        if ((raw.take(12).fold<int>(0, (a, v) => a + v) & 255) != raw[12] ||
            raw[13] != (raw[12] ^ 255)) {
          return null;
        }
        sys = b(104, 111) + 25;
        dia = b(96, 103);
        hr = b(88, 95);
        year = b(82, 87) + 2000;
        hour = b(75, 79);
        day = b(70, 74);
        month = b(66, 69);
        ihb = b(65, 65);
        mov = b(64, 64);
        second = b(58, 63);
        if (second == 63) {
          return null;
        }
        minute = b(52, 57);
      case 'packed16':
      case 'modern16':
        minute = b(68, 73);
        second = min(b(74, 79), 59);
        mov = b(80, 80);
        ihb = b(81, 81);
        month = b(82, 85);
        day = b(86, 90);
        hour = b(91, 95);
        year = b(98, 103) + 2000;
        hr = b(104, 111);
        dia = b(112, 119);
        sys = b(120, 127) + 25;
      default:
        return null;
    }
    if (year < 2000 ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31 ||
        hour > 23 ||
        minute > 59) {
      return null;
    }
    if (profile.layout == 'modern16' && year < 2020) return null;
    if (sys < 50 ||
        sys > 300 ||
        dia < 20 ||
        dia > 200 ||
        sys <= dia ||
        hr < 25 ||
        hr > 240) {
      return null;
    }
    try {
      final timestamp = DateTime(year, month, day, hour, minute, second);
      if (timestamp.year != year ||
          timestamp.month != month ||
          timestamp.day != day) {
        return null;
      }
      return OmronBpRecord(
        measuredAt: timestamp,
        systolic: sys,
        diastolic: dia,
        heartRate: hr,
        user: user,
        irregularPulse: ihb != 0,
        movement: mov != 0,
      );
    } on ArgumentError {
      return null;
    }
  }

  int _bits(List<int> bytes) =>
      (profile.endian == 'little' ? bytes.reversed : bytes).fold<int>(
        0,
        (value, byte) => (value << 8) | byte,
      );

  List<int> _hex(String hex) => [
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ];

  Future<void> close() async {
    await _unlockSub?.cancel();
    if (_unlock != null) {
      try {
        await _unlock!.setNotifyValue(false);
      } catch (_) {}
    }
    for (final subscription in _rxSubscriptions) {
      await subscription.cancel();
    }
    for (final rx in _rx) {
      try {
        await rx.setNotifyValue(false);
      } catch (_) {}
    }
    if (device.isConnected) await device.disconnect();
  }
}
