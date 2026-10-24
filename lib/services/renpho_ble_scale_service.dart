import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/log.dart';

class RenphoFoundScale {
  const RenphoFoundScale(this.mac, this.name, this.rssi);
  final String mac, name;
  final int rssi;
}

/// Body data the scale (or the composition model) needs.
class RenphoUserProfile {
  const RenphoUserProfile({
    required this.heightCm,
    required this.age,
    required this.isMale,
    this.hoursPerWeek = 0,
    this.waistCm,
  });

  final int heightCm;
  final int age;
  final bool isMale;

  /// Training volume; ≥ 5 h/week selects the athlete (MATIAS) model.
  final double hoursPerWeek;
  final double? waistCm;
}

class RenphoBleMeasurement {
  const RenphoBleMeasurement({
    required this.weightKg,
    this.bmi,
    this.heightM,
    this.timestamp,
    this.scaleName,
    this.bodyFatPct,
    this.muscleMassKg,
    this.bmrKcal,
    this.visceralFat,
    this.fatFreeMassKg,
    this.bodyWaterPct,
    this.boneMassKg,
    this.proteinPct,
    this.impedanceOhm,
    this.raw = const {},
  });

  final double weightKg;
  final double? bmi, heightM;
  final DateTime? timestamp;
  final String? scaleName;
  final double? bodyFatPct;
  final double? muscleMassKg;
  final double? bmrKcal;
  final double? visceralFat;
  final double? fatFreeMassKg;
  final double? bodyWaterPct;
  final double? boneMassKg;
  final double? proteinPct;
  final double? impedanceOhm;

  /// Protocol name and every received frame, for debugging.
  final Map<String, dynamic> raw;
}

// Characteristics.
const _sigWeight = '00002a9d-0000-1000-8000-00805f9b34fb';
const _sigBodyComp = '00002a9c-0000-1000-8000-00805f9b34fb';
const _rmsbNotifyA = '00002a10-0000-1000-8000-00805f9b34fb';
const _rmsbWrite = '00002a11-0000-1000-8000-00805f9b34fb';
const _rmsbNotifyB = '00002a12-0000-1000-8000-00805f9b34fb';
const _qnNotify = '0000fff1-0000-1000-8000-00805f9b34fb';
const _qnWrite = '0000fff2-0000-1000-8000-00805f9b34fb';
const _lfWrite = '0000ae01-0000-1000-8000-00805f9b34fb';
const _lfNotify = '0000ae02-0000-1000-8000-00805f9b34fb';

/// Services that identify a scale even without a recognisable name.
const _scaleServices = {
  '0000fff0-0000-1000-8000-00805f9b34fb',
  '0000ae00-0000-1000-8000-00805f9b34fb',
  '00001a10-0000-1000-8000-00805f9b34fb',
  '0000181b-0000-1000-8000-00805f9b34fb',
  '0000181d-0000-1000-8000-00805f9b34fb',
};

/// QN scale clock: seconds since its epoch (Unix − 946667521).
const _qnEpochOffset = 946667521;

/// Reassembles R-MSB multi-part frames (`55 AD/AE/AF <seq> …`).
class _RenphoFrameCarrier {
  final _parts = <List<int>>[];
  int? _expected;

  /// Returns the assembled frame once every part has arrived.
  List<int>? add(List<int> part) {
    if (part.length < 4) return null;
    if (part[1] == 0xAD) _expected = part[2] + 1;
    _parts.add(part);
    final expected = _expected;
    if (expected == null || _parts.length < expected) return null;
    _parts.sort((a, b) => a[2].compareTo(b[2]));
    final out = <int>[];
    for (final p in _parts) {
      out.addAll(p.sublist(3));
    }
    return out;
  }
}

/// Mutable state of one measurement session.
class _Session {
  _Session(this.profile, this.scaleName, this.remoteId) {
    final unix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    qnSessionStart = unix - _qnEpochOffset;
  }

  final RenphoUserProfile? profile;
  final String scaleName;
  final String remoteId;
  final raw = <String, dynamic>{};
  final frames = <Map<String, dynamic>>[];
  final done = Completer<RenphoBleMeasurement>();
  late final int qnSessionStart;

  DateTime? at;
  double? weight, bmi, bodyFat, muscle, bmr, visceral, fatFree, water, bone,
      protein, impedance;
  int qnProtocol = 0;
  double weightDivisor = 100;
  int storedAttempts = 0;
  double? lastWeight;
  int stableCount = 0;
  Timer? fallback;
  bool userInfoSent = false;
  void Function(String)? onStatus;

  String? get protocol => raw['protocol'] as String?;
  void setProtocol(String p) => raw['protocol'] ??= p;
}

/// Renpho / QN / Lefu smart scales over Bluetooth: the QN protocol
/// (fff0 or ae00), the R-MSB protocol (1a10) and the Bluetooth SIG weight
/// and body-composition profiles. Body composition is derived from the
/// impedance when the scale reports only weight and resistance.
class RenphoBleScaleService {
  static const _storage = FlutterSecureStorage();

  String _key(bool second, String field) =>
      'renpho${second ? '2' : ''}_ble_$field';

  Future<String?> getPairedMac({bool second = false}) =>
      _storage.read(key: _key(second, 'mac_address'));
  Future<String?> getPairedName({bool second = false}) =>
      _storage.read(key: _key(second, 'device_name'));

  Future<void> pairScale(String mac, String name, {bool second = false}) async {
    await _storage.write(key: _key(second, 'mac_address'), value: mac);
    await _storage.write(key: _key(second, 'device_name'), value: name);
  }

  Future<void> unpairScale({bool second = false}) async {
    await _storage.delete(key: _key(second, 'mac_address'));
    await _storage.delete(key: _key(second, 'device_name'));
  }

  // ---------------------------------------------------------------------------
  // Discovery
  // ---------------------------------------------------------------------------

  static bool _looksLikeScaleName(String name) {
    final n = name.toLowerCase();
    return n.contains('renpho') ||
        n.contains('r-msb') ||
        n.contains('r_a') ||
        n.contains('r-a') ||
        n.contains('scale');
  }

  static bool _looksLikeScale(ScanResult r) =>
      _looksLikeScaleName(_displayName(r.device, r.advertisementData)) ||
      r.advertisementData.serviceUuids
          .any((g) => _scaleServices.contains(g.str128.toLowerCase()));

  static String _displayName(BluetoothDevice d, [AdvertisementData? adv]) {
    final platform = d.platformName.trim();
    if (platform.isNotEmpty) return platform;
    final advName = (adv?.advName ?? d.advName).trim();
    return advName.isNotEmpty ? advName : d.remoteId.str;
  }

  Future<List<RenphoFoundScale>> scanForScales() async {
    final found = <String, RenphoFoundScale>{};
    final seen = <String>{};
    log('[RENPHO] scanForScales: scanning 10 s');
    final sub = FlutterBluePlus.scanResults.listen((rows) {
      for (final r in rows) {
        final n = _displayName(r.device, r.advertisementData);
        if (seen.add(r.device.remoteId.str)) {
          log(
            '[RENPHO] seen ${r.device.remoteId.str} "$n" rssi=${r.rssi} '
            'services=${r.advertisementData.serviceUuids.map((g) => g.str128).toList()} '
            'scale=${_looksLikeScale(r)}',
          );
        }
        if (!_looksLikeScale(r)) continue;
        found[r.device.remoteId.str] = RenphoFoundScale(
          r.device.remoteId.str,
          _displayName(r.device, r.advertisementData),
          r.rssi,
        );
      }
    });
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      await FlutterBluePlus.isScanning
          .firstWhere((v) => !v)
          .timeout(const Duration(seconds: 12));
      return found.values.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));
    } finally {
      await sub.cancel();
      await FlutterBluePlus.stopScan();
    }
  }

  /// The paired scale by MAC (no scan needed), else the first scale seen
  /// within [timeout].
  Future<BluetoothDevice?> _findScale(
      String? pairedMac, Duration timeout) async {
    if (pairedMac != null) {
      log('[RENPHO] direct connect by MAC: $pairedMac');
      return BluetoothDevice.fromId(pairedMac);
    }
    log('[RENPHO] scanning for ${timeout.inSeconds}s...');
    final completer = Completer<BluetoothDevice?>();
    final sub = FlutterBluePlus.scanResults.listen((rows) {
      for (final r in rows) {
        if (_looksLikeScale(r) && !completer.isCompleted) {
          completer.complete(r.device);
        }
      }
    });
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      return await completer.future
          .timeout(timeout + const Duration(seconds: 2), onTimeout: () => null);
    } finally {
      await sub.cancel();
      await FlutterBluePlus.stopScan();
    }
  }

  // ---------------------------------------------------------------------------
  // Measurement
  // ---------------------------------------------------------------------------

  /// Connects to the paired scale and waits for a stable reading.
  Future<RenphoBleMeasurement> measure({
    bool second = false,
    RenphoUserProfile? profile,
    String? macOverride,
    void Function(String status)? onStatus,
  }) async {
    onStatus?.call('Scanning… step on the scale when ready.');
    final adapter = await FlutterBluePlus.adapterState
        .firstWhere((s) => s == BluetoothAdapterState.on,
            orElse: () => BluetoothAdapterState.off)
        .timeout(const Duration(seconds: 3),
            onTimeout: () => BluetoothAdapterState.unknown);
    if (adapter != BluetoothAdapterState.on) throw Exception('Bluetooth is off.');

    final mac = macOverride ?? await getPairedMac(second: second);
    log('[RENPHO] measure: second=$second paired=$mac profile=${profile != null}');
    final device = await _findScale(mac, const Duration(seconds: 35));
    if (device == null) throw Exception('No RENPHO scale found nearby.');
    final name = _displayName(device);
    log('[RENPHO] found: $name');
    onStatus?.call('Connecting to $name…');
    log('[RENPHO] connecting to $name...');

    final subs = <StreamSubscription<List<int>>>[];
    final notifying = <BluetoothCharacteristic>[];
    try {
      await device
          .connect(autoConnect: false)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        log('[RENPHO] connect timeout');
        throw Exception(
            'Scale connection timed out. Make sure the scale is on and nearby.');
      });
      log('[RENPHO] connected, discovering services...');
      onStatus?.call('Connected — stay on the scale until the reading appears.');
      final services = await device.discoverServices();
      log('[RENPHO] services: ${services.map((s) => s.uuid.str).toList()}');
      final chars = _indexCharacteristics(services);

      final s = _Session(profile, name, device.remoteId.str)
        ..onStatus = onStatus;
      s.raw.addAll({
        'source': 'renpho_ble',
        'scaleName': name,
        'remoteId': device.remoteId.str,
        'frames': s.frames,
      });

      Future<void> subscribe(
          String uuid, void Function(List<int>) handler) async {
        final c = chars[uuid];
        if (c == null) return;
        subs.add(c.onValueReceived.listen(handler));
        await c.setNotifyValue(true);
        notifying.add(c);
      }

      // R-MSB.
      final rmsbWrite = chars[_rmsbWrite];
      final carrier = <int, _RenphoFrameCarrier>{};
      void rmsb(List<int> bytes) =>
          _handleRmsb(s, bytes, carrier, rmsbWrite);
      await subscribe(_rmsbNotifyA, rmsb);
      await subscribe(_rmsbNotifyB, rmsb);

      // QN on fff0, or the same framing on the LF service (ae00).
      final qnWrite = chars[_qnWrite];
      final lfWrite = chars[_lfWrite];
      await subscribe(_qnNotify, (b) => _handleQn(s, b, qnWrite));
      await subscribe(_lfNotify, (b) {
        s.setProtocol('renpho_lf');
        _handleQn(s, b, lfWrite);
      });
      log('[RENPHO] subscribed=${notifying.length} lfWrite=${lfWrite?.uuid.str}');
      if (lfWrite != null && profile != null) {
        await _syncLfUserInfo(lfWrite, profile);
        await Future<void>.delayed(const Duration(seconds: 2));
      }

      // Bluetooth SIG profiles.
      await subscribe(_sigWeight, (b) {
        final m = parseWeight(b);
        if (m == null) return;
        s.setProtocol('bluetooth_sig');
        s.frames.add({'weightMeasurement': _hex(b)});
        s.bmi = m.bmi ?? s.bmi;
        _onStableWeight(s, m.weightKg, rmsbWrite);
      });
      await subscribe(_sigBodyComp, (b) {
        s.setProtocol('bluetooth_sig');
        final v = _parseBodyCompositionMeasurement(b);
        s.frames.add({'bodyCompositionMeasurement': v});
        s.bodyFat = (v['bodyfat'] as double?) ?? s.bodyFat;
        s.bmr = (v['bmrKcal'] as double?) ?? s.bmr;
        s.muscle = (v['muscleMassKg'] as double?) ?? s.muscle;
        s.fatFree = (v['fatFreeMassKg'] as double?) ?? s.fatFree;
        s.impedance = (v['impedanceOhm'] as double?) ?? s.impedance;
        final w = v['weightKg'] as double?;
        if (w != null) _onStableWeight(s, w, rmsbWrite);
        _completeIfReady(s, force: true);
      });

      if (notifying.isEmpty) {
        // Unknown protocol: list what the scale offers and log its raw data
        // so a new protocol can be worked out from a real measurement.
        for (final svc in services) {
          for (final c in svc.characteristics) {
            final p = c.properties;
            log(
              '[RENPHO] unknown-protocol ${svc.uuid.str128} / ${c.uuid.str128}'
              ' read=${p.read} write=${p.write} writeNoResp=${p.writeWithoutResponse}'
              ' notify=${p.notify} indicate=${p.indicate}',
            );
          }
        }
        onStatus?.call('Unknown scale protocol — logging data for analysis…');
        for (final svc in services) {
          if (svc.uuid.str128.startsWith('00001800') ||
              svc.uuid.str128.startsWith('00001801')) {
            continue;
          }
          for (final c in svc.characteristics) {
            if (!(c.properties.notify || c.properties.indicate)) continue;
            try {
              subs.add(
                c.onValueReceived.listen(
                  (b) => log('[RENPHO] raw ${c.uuid.str128}: ${_hex(b)}'),
                ),
              );
              await c.setNotifyValue(true);
              notifying.add(c);
            } catch (e) {
              log('[RENPHO] notify ${c.uuid.str128} failed: $e');
            }
          }
        }
        await Future<void>.delayed(const Duration(seconds: 40));
        throw Exception(
          'This scale uses a protocol Fjelia does not know yet. Its data was '
          'logged for analysis.',
        );
      }

      final timeout = Timer(const Duration(seconds: 45), () {
        if (s.weight != null) {
          _completeIfReady(s, force: true);
        } else if (!s.done.isCompleted) {
          s.done.completeError(Exception(
              'No measurement received. Step on the RENPHO scale and wait '
              'until it stabilizes.'));
        }
      });
      try {
        return await s.done.future;
      } finally {
        timeout.cancel();
        s.fallback?.cancel();
      }
    } finally {
      for (final sub in subs) {
        await sub.cancel();
      }
      for (final c in notifying) {
        try {
          await c.setNotifyValue(false);
        } catch (_) {}
      }
      await device.disconnect();
    }
  }

  static Map<String, BluetoothCharacteristic> _indexCharacteristics(
      List<BluetoothService> services) {
    final map = <String, BluetoothCharacteristic>{};
    for (final svc in services) {
      for (final c in svc.characteristics) {
        map[c.uuid.str128.toLowerCase()] = c;
      }
    }
    return map;
  }

  // ---------------------------------------------------------------------------
  // QN protocol: [cmd, length, protocolType, …, checksum]
  // ---------------------------------------------------------------------------

  static int _sum(List<int> b, [int from = 0, int? to]) {
    var s = 0;
    for (var i = from; i < (to ?? b.length); i++) {
      s = (s + b[i]) & 0xff;
    }
    return s;
  }

  static List<int> _withChecksum(List<int> frame) => [...frame, _sum(frame)];

  Future<void> _write(BluetoothCharacteristic? c, List<int> bytes) async {
    if (c == null) return;
    try {
      await c.write(bytes, withoutResponse: true);
    } catch (_) {
      try {
        await c.write(bytes);
      } catch (_) {}
    }
  }

  void _handleQn(_Session s, List<int> b, BluetoothCharacteristic? write) {
    log('[RENPHO LF] rx: ${_hex(b)}');
    if (b.length < 3) return;
    final cmd = b[0];
    if (b[1] != b.length) return;
    s.qnProtocol = b[2];

    switch (cmd) {
      case 0x10:
        _qnWeightFrame(s, b, write);
      case 0x11:
      case 0x12:
        if (cmd == 0x12) {
          if (b.length > 10) s.weightDivisor = b[10] == 2 ? 100 : 10;
          _write(write, _withChecksum([0x13, 0x09, s.qnProtocol, 0x01, 0x10, 0, 0, 0, 0]));
        }
      case 0x13:
      case 0x14:
        if (cmd == 0x14) _sendQnTimeSync(s, write);
      case 0x21:
        _qnProfileOrQuery(s, b, write);
      case 0x23:
        _qnStoredRecord(s, b, write);
      case 0xA1:
        log('[RENPHO 0xA1] profile ack: ${_hex(b)}');
      default:
        break;
    }
  }

  void _qnWeightFrame(_Session s, List<int> b, BluetoothCharacteristic? write) {
    if (b.length < 10) return;
    double weight;
    var stable = false;
    var r1 = 0;

    if (b.length == 14) {
      // Extended frame: status at [4], weight at [5..6], scale-side fat.
      weight = _u16be(b, 5) / 100;
      if (weight <= 5 || weight >= 300) return;
      s.setProtocol('renpho_qn_ext');
      s.at = DateTime.now();
      s.weight = weight;
      final status = b[4];
      double? scaleFat;
      if (status == 2) {
        final fat = _u16be(b, 11);
        if (fat > 0) scaleFat = fat / 10;
        r1 = _u16be(b, 7);
      }
      _applyBodyComp(s, weight, r1.toDouble());
      if (scaleFat != null) {
        // The scale's own figure ran far too high on a real measurement (28 %
        // against 17 % calculated from the impedance, and 16.6 % in an earlier
        // reading). Keep it for reference and use it only when there is no
        // calculation (no profile, so no height/age/sex to calculate with).
        s.raw['scaleReportedFatPct'] = scaleFat;
        s.bodyFat ??= scaleFat;
      }
      s.frames.add({'hex': _hex(b), 'cmd': 0x10, 'status': status});
      _write(write, _withChecksum([0x1F, 0x05, s.qnProtocol, 0x10]));
      if (status == 2) {
        // Final frame: weight plus the body-composition values.
        s.fallback?.cancel();
        _completeIfReady(s, force: true);
      } else {
        // Weight locked, body composition still being measured (about 10 s
        // barefoot on the electrodes). Keep listening; give up after 25 s and
        // keep the weight alone.
        s.onStatus?.call(
          '${weight.toStringAsFixed(1)} kg — keep standing barefoot, '
          'measuring body composition…',
        );
        s.fallback ??= Timer(
          const Duration(seconds: 25),
          () => _completeIfReady(s, force: true),
        );
      }
      return;
    } else if (b[4] <= 2 && s.weightDivisor == 10) {
      // Newer layout: status at [4], weight at [5..6], r1 at [7..8].
      stable = b[4] == 1 || b[4] == 2;
      weight = _u16be(b, 5) / s.weightDivisor;
      r1 = b.length >= 9 ? _u16be(b, 7) : 0;
    } else {
      // Classic layout: weight at [3..4], stable flag at [5], r1 at [6..7].
      stable = b[5] == 1;
      weight = _u16be(b, 3) / s.weightDivisor;
      r1 = b.length >= 8 ? _u16be(b, 6) : 0;
    }
    if (weight <= 5 || weight >= 300) return;
    s.setProtocol('renpho_qn');
    s.at = DateTime.now();
    s.frames.add({'hex': _hex(b), 'cmd': 0x10, 'stable': stable, 'r1': r1});
    if (!stable) return;

    if (r1 > 0 && s.bodyFat == null) _applyBodyComp(s, weight, r1.toDouble());
    _write(write, _withChecksum([0x1F, 0x05, s.qnProtocol, 0x10]));
    _onStableWeight(s, weight, null);
  }

  void _sendQnTimeSync(_Session s, BluetoothCharacteristic? write) {
    final t = DateTime.now().millisecondsSinceEpoch ~/ 1000 - _qnEpochOffset;
    _write(write, _withChecksum([
      0x20, 0x08, s.qnProtocol,
      t & 0xff, (t >> 8) & 0xff, (t >> 16) & 0xff, (t >> 24) & 0xff,
    ]));
  }

  Future<void> _sendStoredDataQuery(
      _Session s, BluetoothCharacteristic? write) async {
    if (s.done.isCompleted || s.storedAttempts >= 10) return;
    s.storedAttempts++;
    await _write(write, _withChecksum([0x22, 0x06, s.qnProtocol, 0x00, 0x03, 0x00]));
  }

  /// 0x21: extended scales (proto 0xFF) get the user profile, basic ones
  /// are asked for their stored measurement.
  void _qnProfileOrQuery(
      _Session s, List<int> b, BluetoothCharacteristic? write) {
    final p = s.profile;
    if (b.length >= 2 && b[1] == 5 && s.qnProtocol == 0xFF && p != null) {
      final h = p.heightCm * 10;
      final frame = [
        0xA0, 0x0D, 0x02, 0xFE, 0xFF, 0xEE,
        p.isMale ? 1 : 0, p.age & 0xff, (h >> 8) & 0xff, h & 0xff,
        0x04, 0x02,
      ];
      final out = _withChecksum(frame);
      log('[RENPHO 0x21] extended → sending profile: ${_hex(out)}');
      _write(write, out);
    } else {
      log('[RENPHO 0x21] basic flavor → querying stored data');
      _sendStoredDataQuery(s, write);
    }
  }

  /// 0x23: a stored measurement, rejected when empty or older than this
  /// session (records the scale kept from earlier weigh-ins).
  void _qnStoredRecord(_Session s, List<int> b, BluetoothCharacteristic? write) {
    if (b.length < 17) {
      _sendStoredDataQuery(s, write);
      return;
    }
    final weight = _u16be(b, 10) / 100;
    final recTs = b[6] | (b[7] << 8) | (b[8] << 16) | (b[9] << 24);
    final stale = recTs + 90 < s.qnSessionStart;
    log('[RENPHO 0x23] wKg=$weight recTs=$recTs '
        'sessionStart=${s.qnSessionStart} stale=$stale');
    if (weight <= 10 || weight > 300 || stale) {
      log('[RENPHO 0x23] rejected (${weight <= 10 || weight > 300 ? 'empty' : 'stale'}'
          ') — retry in 5s attempt=${s.storedAttempts}');
      Future<void>.delayed(const Duration(seconds: 5),
          () => _sendStoredDataQuery(s, write));
      return;
    }
    final r1 = _u16le(b, 13);
    log('[RENPHO 0x23] completing: wKg=$weight r1=$r1');
    s.setProtocol('renpho_qn');
    s.at = DateTime.now();
    s.weight = weight;
    if (r1 > 50) _applyBodyComp(s, weight, r1.toDouble());
    s.frames.add({'hex': _hex(b), 'cmd': 0x23, 'r1': r1});
    _completeIfReady(s, force: true);
  }

  // ---------------------------------------------------------------------------
  // R-MSB protocol: 55 AA <cmd> <lenHi> <lenLo> <payload> <sum>
  // ---------------------------------------------------------------------------

  static List<int> _buildRenphoCommand(int cmd, List<int> payload) {
    final frame = [
      0x55, 0xAA, cmd & 0xff,
      (payload.length >> 8) & 0xff, payload.length & 0xff,
      ...payload.map((v) => v & 0xff),
    ];
    return _withChecksum(frame);
  }

  static List<int> _buildRenphoDataCommand(List<int> payload) {
    final len = payload.length + 1;
    return _withChecksum([
      0x55, 0xAA, 0xC2, (len >> 8) & 0xff, len & 0xff, 0x01,
      ...payload.map((v) => v & 0xff),
    ]);
  }

  static bool _crcOk(List<int> frame) =>
      frame.length >= 2 &&
      _sum(frame, 0, frame.length - 1) == frame[frame.length - 1];

  /// Multi-part frames (`55 AD/AE/AF`) are buffered until complete.
  static List<int>? _normalizeFrame(
      List<int> bytes, Map<int, _RenphoFrameCarrier> carrier) {
    if (bytes.isEmpty) return null;
    if (bytes[0] == 0x55 &&
        bytes.length >= 4 &&
        (bytes[1] == 0xAD || bytes[1] == 0xAE || bytes[1] == 0xAF)) {
      final key = bytes[2];
      final c = carrier.putIfAbsent(key, _RenphoFrameCarrier.new);
      final assembled = c.add(bytes);
      if (assembled != null) carrier.remove(key);
      return assembled;
    }
    return bytes;
  }

  void _handleRmsb(_Session s, List<int> bytes,
      Map<int, _RenphoFrameCarrier> carrier, BluetoothCharacteristic? write) {
    final frame = _normalizeFrame(bytes, carrier);
    if (frame == null || frame.length <= 6) return;
    if (frame[0] != 0x55 || frame[1] != 0xAA) return;
    final cmd = frame[2];

    if (cmd == 0x30 || cmd == 0x37) {
      // Handshake: answer and send the user profile once.
      _write(write,
          _buildRenphoCommand(cmd == 0x30 ? 0xC0 : 0xC7, [frame[5], 1]));
      if (!s.userInfoSent && s.profile != null) {
        s.userInfoSent = true;
        _syncUserInfo(write, s.profile!);
      }
      return;
    }
    _handleRenphoPreassembled(s, frame);
    _ackAssembledFrame(frame, write);
  }

  void _handleRenphoPreassembled(_Session s, List<int> f) {
    final ok = _crcOk(f);
    s.frames.add({'hex': _hex(f), 'crcOk': ok});
    if (!ok || f.length < 7) return;
    if (f[0] != 0x55 || f[1] != 0xAA || f[2] != 0x35 || f.length < 23) return;
    final model = f[6] & 0x7f;
    if (model != 0x11 && model != 0x12) return;

    final weight = _u32be(f, 9) / 100;
    s.raw['rmsb'] = {
      'dataStatus': (f[6] & 0x80) == 0 ? 1 : 0,
      'dataModel': model,
      'pitPosition': f[7],
      'resistance': _u16be(f, 13),
      'deviceNumber': f[8],
    };
    s.setProtocol('renpho_rmsb');
    s.at = DateTime.now();
    s.weight = weight;
    s.bmi = _u16be(f, 17) / 10;
    s.bodyFat = _u16be(f, 15) / 10;
    s.muscle = _u16be(f, 19) / 10;
    s.visceral = _u16be(f, 21) / 10;
    final r = _u16be(f, 13);
    if (r > 0 && s.profile != null) {
      // Fill the values the scale doesn't report (water, bone, protein…).
      final fat = s.bodyFat;
      _applyBodyComp(s, weight, r.toDouble());
      s.bodyFat = fat;
    }
    _completeIfReady(s, force: true);
  }

  Future<void> _ackAssembledFrame(
      List<int> f, BluetoothCharacteristic? write) async {
    if (write == null || f.length < 7) return;
    final reply = switch (f[2]) {
      0x35 => 0xC5,
      0x36 => 0xC6,
      _ => null,
    };
    if (reply == null) return;
    await _write(write, _buildRenphoCommand(reply, [f[5], 1]));
  }

  Future<void> _syncUserInfo(
      BluetoothCharacteristic? write, RenphoUserProfile p) async {
    if (write == null) return;
    final sexCode = p.isMale ? 1 : 2;
    final flag = ((sexCode << 4) & 0x30) | 0x09;
    final birthYear = DateTime.now().year - p.age;
    final h = p.heightCm.clamp(40, 240) * 10;
    await _write(write, _buildRenphoDataCommand([
      flag, (birthYear >> 8) & 0xff, birthYear & 0xff, 1, 1,
      (h >> 8) & 0xff, h & 0xff, 0, 0, 0, 0, 0, 0xFF, 0,
    ]));
  }

  /// LF variant of the profile (command 0x96).
  Future<void> _syncLfUserInfo(
      BluetoothCharacteristic write, RenphoUserProfile p) async {
    final sexBits = p.isMale ? '01' : '10';
    final user = _intTo8Bit(1).substring(4);
    final first = _bitToByte('00$sexBits$user');
    final birthYear = DateTime.now().year - p.age;
    final h = p.heightCm.clamp(30, 300) * 10;
    await _write(write, _buildRenphoCommand(0x96, [
      first, (birthYear >> 8) & 0xff, birthYear & 0xff, 1, 1,
      (h >> 8) & 0xff, h & 0xff, 0, 0, 0, 0,
      _bitToByte('00000000'), 0xFF, _bitToByte('00000000'),
    ]));
  }

  static String _intTo8Bit(int v) => v.toRadixString(2).padLeft(8, '0');
  static int _bitToByte(String bits) => int.parse(bits, radix: 2) & 0xff;

  // ---------------------------------------------------------------------------
  // Completion
  // ---------------------------------------------------------------------------

  /// A weight counts once two readings agree within 50 g; body data may
  /// still follow, so completion waits up to 3 s.
  void _onStableWeight(
      _Session s, double weight, BluetoothCharacteristic? _) {
    if (s.done.isCompleted) return;
    s.weight = weight;
    s.at ??= DateTime.now();
    final last = s.lastWeight;
    if (last != null && (weight - last).abs() < 0.05) {
      s.stableCount++;
      if (s.stableCount >= 2 && s.bodyFat != null) {
        _completeIfReady(s, force: true);
        return;
      }
    } else {
      s.stableCount = 1;
    }
    s.lastWeight = weight;
    _scheduleWeightFallback(s);
  }

  void _scheduleWeightFallback(_Session s) {
    if (s.weight == null || s.done.isCompleted) return;
    s.fallback?.cancel();
    s.fallback = Timer(const Duration(seconds: 3),
        () => _completeIfReady(s, force: true));
  }

  void _completeIfReady(_Session s, {bool force = false}) {
    if (s.done.isCompleted || s.weight == null) return;
    final complete = force ||
        s.bodyFat != null ||
        s.protocol == 'renpho_rmsb' ||
        s.protocol == 'renpho_lf';
    if (!complete) return;
    s.done.complete(_current(s));
  }

  RenphoBleMeasurement _current(_Session s) {
    final w = s.weight!;
    final fatFree = s.fatFree ??
        (s.bodyFat == null ? null : w * (1 - s.bodyFat! / 100));
    final heightM = s.profile == null ? null : s.profile!.heightCm / 100;
    return RenphoBleMeasurement(
      timestamp: s.at ?? DateTime.now(),
      scaleName: s.scaleName,
      weightKg: w,
      bmi: s.bmi ??
          (heightM == null || heightM <= 0 ? null : w / (heightM * heightM)),
      heightM: heightM,
      bodyFatPct: s.bodyFat,
      muscleMassKg: s.muscle,
      bmrKcal: s.bmr,
      visceralFat: s.visceral,
      fatFreeMassKg: fatFree,
      bodyWaterPct: s.water,
      boneMassKg: s.bone,
      proteinPct: s.protein,
      impedanceOhm: s.impedance,
      raw: s.raw,
    );
  }

  // ---------------------------------------------------------------------------
  // Body composition from impedance
  // ---------------------------------------------------------------------------

  /// Derives fat, muscle, water, bone, protein, BMR and visceral fat from
  /// the raw resistance [r1] (QN units) and the user profile.
  void _applyBodyComp(_Session s, double weight, double r1) {
    final p = s.profile;
    if (p == null || r1 <= 0) return;
    final h = p.heightCm / 100;
    final age = p.age.toDouble();
    final male = p.isMale;
    final bmi = weight / (h * h);
    s.bmi = bmi;
    final imp = r1 < 410 ? 3.0 : 0.3 * (r1 - 400);
    s.impedance = imp;
    log('[RENPHO BODYCOMP] r1=$r1 → imp=$imp wKg=$weight age=$age '
        'male=$male hrs=${p.hoursPerWeek}');

    final waterPct = male
        ? bmi * -1.162 - imp * 0.00813 + age * 0.07594 + 87.51
        : bmi * -1.148 - imp * 0.00573 + age * 0.06448 + 77.721;
    final boneKg = male
        ? bmi * -0.0855 - imp * 0.000592 - age * 0.0389 + 7.829
        : bmi * -0.08 - imp * 0.000484 - age * 0.033 + 6.8;

    if (p.hoursPerWeek >= 5) {
      // Athletes: MATIAS fat-free mass from the impedance index.
      final impedanceIndex = p.heightCm * p.heightCm / r1;
      final ffm = impedanceIndex * 0.327 - 2.261 + weight * 0.525 +
          (male ? 1 : 0) * 5.462;
      final fat = ((weight - ffm) / weight * 100).clamp(1.0, 60.0);
      log('[RENPHO MATIAS] h=${p.heightCm}cm r1=$r1 '
          'impedanceIndex=$impedanceIndex wKg=$weight sex=${male ? 1 : 0} '
          '→ ffm=$ffm fat=$fat%');
      s.bodyFat = fat;
      s.fatFree = ffm.clamp(10.0, weight * 0.99);
      s.muscle = (s.fatFree! * 0.75).clamp(1.0, weight * 0.95);
    } else {
      final fat = (male
              ? bmi * (0.00044 * imp + 1.479) + age * 0.1 - 21.764
              : bmi * (0.000391 * imp + 1.506) + age * 0.1 - 12.834)
          .clamp(1.0, 60.0);
      s.bodyFat = fat;
      s.fatFree = weight * (1 - fat / 100);
      final musclePct = male
          ? bmi * -0.811 - imp * 0.00565 - age * 0.367 + 74.627
          : bmi * -0.694 - imp * 0.00344 - age * 0.255 + 57;
      s.muscle = (musclePct / 100 * weight).clamp(1.0, weight * 0.95);
    }

    // Visceral fat: conicity index from waist when known, else a proxy.
    final waist = p.waistCm;
    if (waist != null && waist > 50) {
      final ci = (waist / 100) / (0.109 * math.sqrt(weight / h));
      final ciFrac = ((ci - 1.15) / 0.3).clamp(0.0, 1.0);
      s.visceral = (ciFrac * 29 + 1).roundToDouble();
      log('[RENPHO VF] waist=${waist}cm ci=$ci ciFrac=$ciFrac '
          '→ vfLevel=${s.visceral} (waist-based)');
    } else {
      var v = bmi * 0.6 + age * 0.08 + (s.bodyFat ?? 20) * 0.25;
      if (!male) v *= 0.9;
      s.visceral = (v - 8).clamp(1.0, 30.0).roundToDouble();
      log('[RENPHO VF] no waist → vfLevel=${s.visceral} (BMI/age/BF proxy)');
    }

    s.water = waterPct.clamp(20.0, 80.0);
    s.bone = boneKg.clamp(0.5, 8.0);
    if (s.fatFree != null) s.bmr = s.fatFree! * 21.6 + 370;
    final fat = s.bodyFat ?? 20;
    s.protein = (male ? 22.787 - fat * 0.22735 : 25.34 - fat * 0.30245)
        .clamp(5.0, 24.0);
  }

  // ---------------------------------------------------------------------------
  // Bluetooth SIG parsers
  // ---------------------------------------------------------------------------

  /// Weight Measurement (0x2A9D).
  static RenphoBleMeasurement? parseWeight(List<int> bytes) {
    if (bytes.length < 3) return null;
    final flags = bytes[0];
    final imperial = (flags & 1) != 0;
    int u16(int at) => bytes[at] | bytes[at + 1] << 8;
    final weight = u16(1) * (imperial ? 0.01 * 0.45359237 : 0.005);
    var at = 3;
    if ((flags & 2) != 0) at += 7;
    if ((flags & 4) != 0) at++;
    double? bmi, height;
    if ((flags & 8) != 0 && bytes.length >= at + 4) {
      bmi = u16(at) / 10;
      height = u16(at + 2) * (imperial ? 0.00254 : 0.001);
    }
    if (weight <= 0 || weight > 500) return null;
    return RenphoBleMeasurement(weightKg: weight, bmi: bmi, heightM: height);
  }

  /// Body Composition Measurement (0x2A9C).
  static Map<String, dynamic> _parseBodyCompositionMeasurement(List<int> b) {
    final out = <String, dynamic>{'hex': _hex(b)};
    if (b.length < 4) return out;
    final flags = b[0] | b[1] << 8;
    out['flags'] = flags;
    final imperial = (flags & 1) != 0;
    final massUnit = imperial ? 0.01 * 0.45359237 : 0.005;
    var at = 2;
    int? u16() {
      if (at + 2 > b.length) return null;
      final v = b[at] | b[at + 1] << 8;
      at += 2;
      return v;
    }

    out['bodyfat'] = (u16() ?? 0) / 10;
    if ((flags & 0x02) != 0) at += 7; // time stamp
    if ((flags & 0x04) != 0) at += 1; // user id
    if ((flags & 0x08) != 0) {
      final kj = u16();
      if (kj != null) out['bmrKcal'] = kj / 4.184;
    }
    if ((flags & 0x10) != 0) {
      final v = u16();
      if (v != null) out['musclePercentage'] = v / 10;
    }
    if ((flags & 0x20) != 0) {
      final v = u16();
      if (v != null) out['muscleMassKg'] = v * massUnit;
    }
    if ((flags & 0x40) != 0) {
      final v = u16();
      if (v != null) out['fatFreeMassKg'] = v * massUnit;
    }
    if ((flags & 0x80) != 0) {
      final v = u16();
      if (v != null) out['softLeanMassKg'] = v * massUnit;
    }
    if ((flags & 0x100) != 0) {
      final v = u16();
      if (v != null) out['bodyWaterMassKg'] = v * massUnit;
    }
    if ((flags & 0x200) != 0) {
      final v = u16();
      if (v != null) out['impedanceOhm'] = v / 10;
    }
    if ((flags & 0x400) != 0) {
      final v = u16();
      if (v != null) out['weightKg'] = v * massUnit;
    }
    if ((flags & 0x800) != 0) {
      final v = u16();
      if (v != null) out['heightM'] = v * (imperial ? 0.0254 : 0.001);
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Test hooks
  // ---------------------------------------------------------------------------

  /// Runs QN ([rmsb] false) or R-MSB notification frames through the parser
  /// without a device and returns the resulting measurement, if any.
  @visibleForTesting
  RenphoBleMeasurement? debugParseFrames(
    List<List<int>> frames, {
    RenphoUserProfile? profile,
    bool rmsb = false,
  }) {
    final s = _Session(profile, 'test', 'test');
    final carrier = <int, _RenphoFrameCarrier>{};
    for (final f in frames) {
      rmsb ? _handleRmsb(s, f, carrier, null) : _handleQn(s, f, null);
    }
    s.fallback?.cancel();
    return s.weight == null ? null : _current(s);
  }

  /// Whether the QN frames finish a measurement (true) or the scale is still
  /// measuring (false).
  @visibleForTesting
  bool debugCompletes(
    List<List<int>> frames, {
    RenphoUserProfile? profile,
  }) {
    final s = _Session(profile, 'test', 'test');
    for (final f in frames) {
      _handleQn(s, f, null);
    }
    s.fallback?.cancel();
    return s.done.isCompleted;
  }

  // ---------------------------------------------------------------------------
  // Byte helpers
  // ---------------------------------------------------------------------------

  static int _u16be(List<int> b, int i) => (b[i] << 8) | b[i + 1];
  static int _u16le(List<int> b, int i) => b[i] | (b[i + 1] << 8);
  static int _u32be(List<int> b, int i) =>
      (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
  static String _hex(List<int> b) =>
      b.map((v) => v.toRadixString(16).padLeft(2, '0')).join(' ');
}
