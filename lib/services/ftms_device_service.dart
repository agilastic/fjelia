import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/concept2.dart';
import '../models/ftms.dart';
import '../models/spot_hrv.dart';
import '../models/running_speed.dart';
import '../models/training_ble_profile.dart';
import 'training_ble.dart';

class FtmsDeviceService {
  FtmsDeviceService({TrainingBleConnection? connection})
    : _connection = connection ?? TrainingBleConnection();
  final TrainingBleConnection _connection;
  TrainingBleReport? report;
  bool runningSpeedOnly = false;
  final _measurements = StreamController<Map<String, num>>.broadcast();
  final _status = StreamController<String>.broadcast();
  Stream<Map<String, num>> get measurements => _measurements.stream;
  Stream<String> get status => _status.stream;
  FtmsMachine? machine;

  /// Connected to a Concept2 PM5 through its own profile, read-only.
  bool concept2 = false;
  FtmsCompatibility compatibility = FtmsCompatibility.standard;
  int measurementFeatures = 0, targetFeatures = 0;
  final ranges = <FtmsTarget, FtmsRange>{};
  BluetoothCharacteristic? _control;
  Completer<int>? _reply;
  int? _opcode;
  bool authorized = false, _disposed = false;
  int _authorizationEpoch = 0;

  Future<void> connect(TrainingDevice device, {FtmsMachine? preferred}) async {
    if (_disposed) throw StateError('Connection closed.');
    manualOverride();
    compatibility = ftmsCompatibilityForName(device.name);
    ranges.clear();
    _control = null;
    await _connection.close();
    try {
      await _connection.connect(device);
      report = _connection.report(device);
      runningSpeedOnly = false;
      _connection.onDisconnected = () {
        manualOverride();
        final reply = _reply;
        if (reply != null && !reply.isCompleted) {
          reply.completeError(StateError('Machine disconnected.'));
        }
        _status.add('disconnected');
      };
      concept2 = report!.concept2;
      if (concept2) {
        await _connectConcept2();
        _status.add('connected');
        return;
      }
      final available = report!.machines;
      if (available.isEmpty) {
        if (!report!.runningSpeed) throw UnsupportedTrainingDevice(report!);
        machine = FtmsMachine.treadmill;
        runningSpeedOnly = true;
      }
      if (!runningSpeedOnly) {
        machine = preferred != null && available.contains(preferred)
            ? preferred
            : available.first;
      }
      final feature = runningSpeedOnly
          ? null
          : _connection.characteristic('1826', '2acc');
      measurementFeatures = 0;
      targetFeatures = 0;
      if (feature?.properties.read ?? false) {
        try {
          final bytes = await feature!.read().timeout(
            const Duration(seconds: 5),
          );
          if (bytes.length >= 8) {
            final data = ByteData.sublistView(Uint8List.fromList(bytes));
            measurementFeatures = data.getUint32(0, Endian.little);
            targetFeatures = data.getUint32(4, Endian.little);
          }
        } catch (_) {
          /* Unreadable capabilities leave recording read-only. */
        }
      }
      final control = runningSpeedOnly
          ? null
          : _connection.characteristic('1826', '2ad9');
      if (control != null &&
          ftmsControlAllowed(machine!, compatibility) &&
          control.properties.write &&
          control.properties.indicate) {
        _control = control;
        await _connection.subscribe(control, (bytes) {
          if (bytes.length >= 3 &&
              bytes[0] == 0x80 &&
              bytes[1] == _opcode &&
              _reply != null &&
              !_reply!.isCompleted) {
            _reply!.complete(bytes[2]);
          }
        });
        for (final target in FtmsTarget.values) {
          if (targetFeatures & (1 << target.featureBit) == 0) continue;
          final c = _connection.characteristic('1826', target.rangeUuid);
          if (!(c?.properties.read ?? false)) continue;
          try {
            ranges[target] = FtmsRange.decode(
              target,
              await c!.read().timeout(const Duration(seconds: 4)),
            );
          } catch (_) {
            /* Without valid limits, this target is unavailable. */
          }
        }
      }
      final machineStatus = runningSpeedOnly
          ? null
          : _connection.characteristic('1826', '2ada');
      if (machineStatus?.properties.notify ?? false) {
        await _connection.subscribe(machineStatus!, (bytes) {
          if (bytes.isNotEmpty && {0xff, 0x03, 0x02}.contains(bytes[0])) {
            manualOverride();
            _status.add('manual');
          }
        });
      }
      await _connection.subscribe(
        _connection.characteristic(
          runningSpeedOnly ? '1814' : '1826',
          runningSpeedOnly ? '2a53' : machine!.characteristic,
        )!,
        (bytes) {
          try {
            _measurements.add(
              runningSpeedOnly
                  ? decodeRunningSpeed(bytes)
                  : decodeFtms(machine!, bytes, compatibility: compatibility),
            );
          } on FormatException {
            _status.add('invalid_packet');
          }
        },
        onError: (e) => _status.add('invalid_packet'),
      );
      _status.add('connected');
    } catch (_) {
      await _connection.close();
      rethrow;
    }
  }

  /// A PM5 is read through its own rowing service on every firmware, also
  /// when it offers FTMS: the records carry more (strokes, force, drag
  /// factor) and an old PM5 has nothing else. Fjelia does not control it.
  Future<void> _connectConcept2() async {
    int? ergType;
    final type = _connection.characteristic(
      concept2InfoService,
      concept2MachineTypeCharacteristic,
    );
    if (type?.properties.read ?? false) {
      try {
        final bytes = await type!.read().timeout(const Duration(seconds: 4));
        if (bytes.isNotEmpty) ergType = bytes.first;
      } catch (_) {
        /* Firmware before V150: the status records name the erg later. */
      }
    }
    machine = concept2Machine(ergType);
    _control = null;
    ranges.clear();
    measurementFeatures = 0;
    targetFeatures = 0;
    // Status twice a second is the PM5's default; four times keeps the
    // display as fresh as an FTMS rower's.
    final rate = _connection.characteristic(
      concept2RowingService,
      concept2SampleRateCharacteristic,
    );
    if (rate?.properties.write ?? false) {
      try {
        await rate!.write([2]).timeout(const Duration(seconds: 4));
      } catch (_) {
        /* The default rate still records. */
      }
    }
    void receive(int id, List<int> bytes) {
      try {
        final values = decodeConcept2(id, bytes);
        if (values.isNotEmpty) _measurements.add(values);
      } on FormatException {
        _status.add('invalid_packet');
      }
    }

    var subscribed = 0;
    for (final id in concept2LiveIds) {
      final c = _connection.characteristic(
        concept2RowingService,
        concept2Uuid(id),
      );
      if (c == null || !(c.properties.notify || c.properties.indicate)) {
        continue;
      }
      await _connection.subscribe(
        c,
        (bytes) => receive(id, bytes),
        onError: (e) => _status.add('invalid_packet'),
      );
      subscribed++;
    }
    // Everything not subscribed on its own arrives here.
    final multiplexed = _connection.characteristic(
      concept2RowingService,
      concept2Uuid(concept2MultiplexedId),
    );
    if (multiplexed?.properties.notify ?? false) {
      await _connection.subscribe(
        multiplexed!,
        (bytes) => receive(concept2MultiplexedId, bytes),
        onError: (e) => _status.add('invalid_packet'),
      );
      subscribed++;
    }
    if (subscribed == 0) throw UnsupportedTrainingDevice(report!);
  }

  Future<void> _command(List<int> command) async {
    final control = _control;
    if (control == null || _disposed) {
      throw StateError('Equipment control is unavailable.');
    }
    if (_reply != null) {
      throw StateError('Wait for the previous equipment command.');
    }
    final reply = Completer<int>();
    _reply = reply;
    _opcode = command.first;
    final response = reply.future.timeout(const Duration(seconds: 5));
    try {
      final results = await Future.wait<Object?>([
        response,
        control.write(command, withoutResponse: false),
      ], eagerError: true);
      final result = results.first as int;
      if (result != 1) {
        authorized = false;
        throw StateError('The machine rejected the command (code $result).');
      }
    } finally {
      _reply = null;
    }
  }

  Future<void> authorize() async {
    if (ranges.isEmpty) {
      throw StateError('The machine offers no supported control targets.');
    }
    final epoch = _authorizationEpoch;
    await _command([0]);
    if (epoch != _authorizationEpoch) {
      throw StateError('Equipment control was cancelled.');
    }
    authorized = true;
  }

  void manualOverride() {
    authorized = false;
    _authorizationEpoch++;
  }

  Future<void> setTarget(FtmsTarget target, double value) async {
    if (!authorized) {
      throw StateError('Authorize equipment control for this session first.');
    }
    final range = ranges[target];
    if (range == null) {
      throw StateError('The machine does not support this control target.');
    }
    await _command(ftmsTargetCommand(target, range, value));
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    manualOverride();
    if (_reply != null && !_reply!.isCompleted) {
      _reply!.completeError(StateError('Machine connection closed.'));
    }
    await _connection.close();
    await _measurements.close();
    await _status.close();
  }
}

/// Any standard BLE Heart Rate Service, including H10 and watches that
/// explicitly broadcast it. No assumed Apple Watch companion connection.
class IndoorHeartRateService {
  final _connection = TrainingBleConnection();
  final _packets = StreamController<H10HeartRatePacket>.broadcast();
  Stream<H10HeartRatePacket> get packets => _packets.stream;
  Future<void> connect(TrainingDevice device) async {
    try {
      await _connection.connect(device);
      _connection.onDisconnected = () =>
          _packets.addError(StateError('Heart-rate sensor disconnected.'));
      final c = _connection.characteristic('180d', '2a37');
      if (c == null) {
        throw StateError('This device does not broadcast live heart rate.');
      }
      await _connection.subscribe(c, (bytes) {
        try {
          _packets.add(H10HeartRatePacket.decode(bytes));
        } on FormatException {
          /* An invalid packet cannot become a reading. */
        }
      }, onError: _packets.addError);
    } catch (_) {
      await _connection.close();
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _connection.close();
    await _packets.close();
  }
}
