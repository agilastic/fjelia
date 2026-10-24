import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/hr_zone_model.dart';

final hrZonesProvider = StateNotifierProvider<HrZonesNotifier, HrZonesState>((
  ref,
) {
  return HrZonesNotifier();
});

/// Lower HR bound of zones 1–5.
class HrZones {
  const HrZones(this.bounds);

  final List<int> bounds;

  static HrZones fromJson(String json) => HrZones(
    (jsonDecode(json) as List).map((e) => (e as num).toInt()).toList(),
  );

  String toJson() => jsonEncode(bounds);

  /// Running zones from max HR (60/76/82/88/93 %).
  static HrZones fromMaxHr(int maxHr) => HrZones([
    (maxHr * 0.60).round(),
    (maxHr * 0.76).round(),
    (maxHr * 0.82).round(),
    (maxHr * 0.88).round(),
    (maxHr * 0.93).round(),
  ]);

  /// Cycling zones sit lower than running (55/72/78/84/88 %).
  static HrZones fromMaxHrCycling(int maxHr) => HrZones([
    (maxHr * 0.55).round(),
    (maxHr * 0.72).round(),
    (maxHr * 0.78).round(),
    (maxHr * 0.84).round(),
    (maxHr * 0.88).round(),
  ]);
}

class HrZonesState {
  const HrZonesState({required this.running, required this.cycling});

  final HrZones running;
  final HrZones cycling;

  HrZonesState copyWith({HrZones? running, HrZones? cycling}) => HrZonesState(
    running: running ?? this.running,
    cycling: cycling ?? this.cycling,
  );
}

const _defaultRunning = HrZones([108, 137, 148, 158, 166]);
const _defaultCycling = HrZones([99, 126, 140, 151, 158]);

class HrZonesNotifier extends StateNotifier<HrZonesState> {
  HrZonesNotifier()
    : super(
        const HrZonesState(running: _defaultRunning, cycling: _defaultCycling),
      ) {
    loaded = _load();
  }

  /// Completes when the stored zones are in [state]. Anything that changes
  /// or reads zones right after startup must wait for it, or the late load
  /// overwrites the change with the stored (or default) zones.
  late final Future<void> loaded;

  static const _storage = FlutterSecureStorage();
  static const _runKey = 'custom_hr_zones_running';
  static const _bikeKey = 'custom_hr_zones_cycling';
  static const _bikeFromDeviceKey = 'hr_zones_cycling_from_device';
  static const _deviceSchemeKey = 'hr_zones_device_lthr_scheme';

  Future<void> _load() async {
    final run = await _storage.read(key: _runKey);
    final bike = await _storage.read(key: _bikeKey);
    state = HrZonesState(
      running: run == null ? _defaultRunning : HrZones.fromJson(run),
      cycling: bike == null ? _defaultCycling : HrZones.fromJson(bike),
    );
  }

  HrZones zonesFor(String activityType) {
    final t = activityType.toLowerCase();
    return t.contains('cycl') || t.contains('bike') || t.contains('bik')
        ? state.cycling
        : state.running;
  }

  /// The device's own %LTHR scheme (floors + LTHR), used to keep its
  /// percentages when the app detects a new threshold.
  Future<void> saveDeviceScheme(List<int> floors, int lthr) => _storage.write(
    key: _deviceSchemeKey,
    value: jsonEncode({'floors': floors, 'lthr': lthr}),
  );

  Future<({List<int> floors, int lthr})?> deviceScheme() async {
    final raw = await _storage.read(key: _deviceSchemeKey);
    if (raw == null) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return (
      floors: (m['floors'] as List).map((e) => (e as num).toInt()).toList(),
      lthr: (m['lthr'] as num).toInt(),
    );
  }

  /// LT1 marks the top of zone 2, i.e. the start of zone 3.
  Future<void> applyLt1Ceiling(int lt1Bpm) async {
    await loaded;
    final bounds = List<int>.from(state.running.bounds);
    if (bounds.length < 5) return;
    bounds[2] = lt1Bpm;
    if (bounds[1] >= lt1Bpm) bounds[1] = lt1Bpm - 1;
    if (bounds[3] <= lt1Bpm) bounds[3] = lt1Bpm + 1;
    await saveRunning(HrZones(bounds));
  }

  /// Zones from an app-detected LT2 (= LTHR). Keeps the athlete's own %LTHR
  /// scheme when one is known (e.g. from Garmin), else Friel %LTHR zones.
  /// Cycling zones follow only when no cycling-specific scheme exists.
  Future<void> applyFromLt2Hr(int lt2Bpm) async {
    final scheme = await deviceScheme();
    final run = scheme != null && scheme.lthr > 0
        ? scaleZoneFloors(scheme.floors, from: scheme.lthr, to: lt2Bpm)
        : lthrZoneFloors(lt2Bpm);
    await saveRunning(HrZones(run));
    if (await _storage.read(key: _bikeFromDeviceKey) == null) {
      await saveCycling(HrZones(lthrZoneFloors(lt2Bpm, cycling: true)));
    }
  }

  /// Zones set on the athlete's device (Garmin), per sport.
  Future<void> applyDeviceZones({
    required List<int> running,
    List<int>? cycling,
  }) async {
    await saveRunning(HrZones(running));
    if (cycling != null) {
      await saveCycling(HrZones(cycling));
      await _storage.write(key: _bikeFromDeviceKey, value: '1');
    }
  }

  Future<void> saveRunning(HrZones zones) async {
    await loaded;
    await _storage.write(key: _runKey, value: zones.toJson());
    state = state.copyWith(running: zones);
  }

  Future<void> saveCycling(HrZones zones) async {
    await loaded;
    await _storage.write(key: _bikeKey, value: zones.toJson());
    state = state.copyWith(cycling: zones);
  }
}
