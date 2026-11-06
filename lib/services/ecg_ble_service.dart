import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/ecg.dart';
import '../models/spot_hrv.dart';
import 'training_ble.dart';

/// PMD wire format and ECG frame layout follow Polar's published online
/// measurement protocol. Uses the app's existing BLE transport on iOS/Android.
class EcgDeviceService {
  static const service = 'fb005c80-02e7-f387-1cad-8acd2d8df0c8';
  static const control = 'fb005c81-02e7-f387-1cad-8acd2d8df0c8';
  static const data = 'fb005c82-02e7-f387-1cad-8acd2d8df0c8';
  final _connection = TrainingBleConnection();
  final _frames = StreamController<EcgFrame>.broadcast();
  Stream<EcgFrame> get frames => _frames.stream;
  final _heartRate = StreamController<H10HeartRatePacket>.broadcast();
  Stream<H10HeartRatePacket> get heartRate => _heartRate.stream;
  BluetoothCharacteristic? _control;
  Completer<List<int>>? _response;
  final _responseBytes = <int>[];
  int? _opcode;
  bool _started = false, _disposed = false;
  double sampleRateHz = 130;
  int resolutionBits = 14;

  Future<void> connect(TrainingDevice device) async {
    if (_disposed) throw StateError('ECG connection closed.');
    try {
      await _connection.connect(device);
      _connection.onDisconnected = () {
        if (_response != null && !_response!.isCompleted) {
          _response!.completeError(StateError('The ECG sensor disconnected.'));
        }
        _response = null;
        _frames.addError(
          StateError(
            'The ECG sensor disconnected. The saved signal is incomplete.',
          ),
        );
      };
      final cp = _connection.characteristic(service, control);
      final stream = _connection.characteristic(service, data);
      if (cp == null ||
          stream == null ||
          !cp.properties.write ||
          !cp.properties.indicate) {
        throw StateError('This device does not provide Polar ECG recording.');
      }
      _control = cp;
      await _connection.subscribe(cp, _receiveResponse);
      final settings = parseEcgSettings(await _command(1));
      sampleRateHz = settings.sampleRate.toDouble();
      resolutionBits = settings.resolution;
      await _connection.subscribe(stream, (bytes) {
        if (bytes.isEmpty || bytes.first != 0) return;
        try {
          _frames.add(EcgFrame.decode(bytes));
        } catch (_) {
          _frames.addError(const FormatException('Invalid ECG signal packet.'));
        }
      }, onError: _frames.addError);
      // H10's normal HR/RR notifications share the ECG connection. No second
      // central connection or ECG-derived beat estimate is needed.
      final hr = _connection.characteristic('180d', '2a37');
      if (hr?.properties.notify ?? false) {
        try {
          await _connection.subscribe(hr!, (bytes) {
            try {
              _heartRate.add(H10HeartRatePacket.decode(bytes));
            } on FormatException {
              // An invalid HR packet cannot become a reading.
            }
          });
        } catch (_) {
          // ECG remains usable if optional HR notifications are unavailable.
        }
      }
    } catch (_) {
      await _connection.close();
      rethrow;
    }
  }

  void _receiveResponse(List<int> bytes) {
    final response = _response;
    if (response == null ||
        response.isCompleted ||
        bytes.length < 4 ||
        bytes[0] != 0xf0 ||
        bytes[1] != _opcode ||
        bytes[2] != 0) {
      return;
    }
    if (bytes[3] != 0) {
      response.completeError(
        StateError('The sensor rejected the ECG request (code ${bytes[3]}).'),
      );
      return;
    }
    if (bytes.length > 5) _responseBytes.addAll(bytes.sublist(5));
    if (bytes.length == 4 || bytes[4] == 0) {
      response.complete(List.of(_responseBytes));
    }
  }

  Future<List<int>> _command(
    int opcode, [
    List<int> parameters = const [],
  ]) async {
    if (_response != null) {
      throw StateError('An ECG request is already in progress.');
    }
    final cp = _control;
    if (cp == null) throw StateError('Connect an ECG sensor first.');
    final response = Completer<List<int>>();
    _opcode = opcode;
    _responseBytes.clear();
    _response = response;
    final reply = response.future.timeout(const Duration(seconds: 8));
    try {
      final results = await Future.wait<Object?>([
        reply,
        cp.write([opcode, 0, ...parameters], withoutResponse: false),
      ], eagerError: true);
      return results.first as List<int>;
    } finally {
      _response = null;
    }
  }

  Future<void> start() async {
    final hz = sampleRateHz.round();
    await _command(2, [
      0,
      1,
      hz & 255,
      hz >> 8,
      1,
      1,
      resolutionBits & 255,
      resolutionBits >> 8,
    ]);
    _started = true;
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    await _command(3);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_response != null && !_response!.isCompleted) {
      _response!.completeError(StateError('ECG connection closed.'));
    }
    try {
      await stop();
    } catch (_) {
      /* Partial recordings remain saved. */
    }
    await _connection.close();
    await _frames.close();
    await _heartRate.close();
  }
}

/// Query settings before starting, rather than silently assuming every
/// Polar device supports the H10's rate/resolution.
({int sampleRate, int resolution}) parseEcgSettings(List<int> bytes) {
  final settings = <int, List<int>>{};
  const sizes = {0: 2, 1: 2, 2: 2, 3: 4, 4: 1, 5: 4};
  var offset = 0;
  while (offset < bytes.length) {
    if (offset + 2 > bytes.length) {
      throw const FormatException('Truncated ECG settings.');
    }
    final type = bytes[offset++], count = bytes[offset++];
    final size = sizes[type];
    if (size == null || count == 0 || offset + size * count > bytes.length) {
      throw const FormatException('Unsupported ECG settings.');
    }
    final values = <int>[];
    for (var i = 0; i < count; i++) {
      var value = 0;
      for (var j = 0; j < size; j++) {
        value |= bytes[offset++] << (8 * j);
      }
      values.add(value);
    }
    settings[type] = values;
  }
  final rates = settings[0] ?? [], resolutions = settings[1] ?? [];
  // This decoder is specifically for H10's raw ECG frames. Other device
  // formats must be added deliberately with a matching decoder.
  if (!rates.contains(130) || !resolutions.contains(14)) {
    throw const FormatException(
      'This sensor does not offer H10 ECG at 130 Hz / 14 bits.',
    );
  }
  return (sampleRate: 130, resolution: 14);
}
