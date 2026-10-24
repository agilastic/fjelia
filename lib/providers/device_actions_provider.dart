import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../db/database.dart';
import '../models/device_connection.dart';
import '../services/renpho_ble_scale_service.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';
import 'hilo_sync_provider.dart';
import 'user_profile_provider.dart';
import 'body_measurements_provider.dart';
export '../models/device_connection.dart';

final deviceActionsProvider = Provider<DeviceActions>(
  (ref) => DeviceActions(ref),
);

/// Whether a RENPHO scale is paired over Bluetooth.
final renphoBleConnectedProvider = FutureProvider<bool>((ref) async {
  final actions = ref.read(deviceActionsProvider);
  return await actions.pairedId(await actions.scaleRole()) != null;
});

class DeviceActions {
  DeviceActions(this.ref);
  final Ref ref;
  final _scale = RenphoBleScaleService();
  bool _second(DeviceRole role) => role == DeviceRole.secondaryScale;

  /// The user sees one RENPHO scale. It is stored under whichever of the two
  /// historical roles it was paired as; a new pairing uses the primary role.
  Future<DeviceRole> scaleRole() async {
    if (await pairedId(DeviceRole.primaryScale) != null) {
      return DeviceRole.primaryScale;
    }
    if (await pairedId(DeviceRole.secondaryScale) != null) {
      return DeviceRole.secondaryScale;
    }
    return DeviceRole.primaryScale;
  }
  List<NearbyDevice> _bracelets(Iterable<NearbyDevice> input) {
    final named = input
        .where((d) => d.name.toUpperCase().startsWith('AKTIIA'))
        .toList();
    final pods = named
        .where((d) => d.name.toUpperCase().startsWith('AKTIIA P'))
        .toList();
    return pods.isNotEmpty ? pods : named;
  }

  List<NearbyDevice> knownBracelets() => _bracelets([
    for (final d
        in ref.read(hiloSyncStateProvider).valueOrNull?.foundDevices ?? [])
      NearbyDevice(
        mac: d.mac,
        name: d.name,
        rssi: d.rssi,
        isBonded: d.isBonded,
      ),
  ]);

  Future<List<NearbyDevice>> scan(DeviceRole role) async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    if (role == DeviceRole.primaryScale || role == DeviceRole.secondaryScale) {
      return [
        for (final d in await _scale.scanForScales())
          NearbyDevice(mac: d.mac, name: d.name, rssi: d.rssi),
      ];
    }
    final devices = [
      for (final d in await ref.read(hiloBleServiceProvider).scanForDevices())
        NearbyDevice(
          mac: d.mac,
          name: d.name,
          rssi: d.rssi,
          isBonded: d.isBonded,
        ),
    ];
    if (role == DeviceRole.bracelet) return _bracelets(devices);
    return devices
        .where(
          (d) =>
              d.name.toUpperCase().startsWith('AKTIIA C') ||
              d.name.toLowerCase().contains('cuff'),
        )
        .toList();
  }

  Future<String?> pairedName(DeviceRole role) => switch (role) {
    DeviceRole.bracelet => ref.read(hiloBleServiceProvider).getPairedName(),
    DeviceRole.cuff => ref.read(hiloBleServiceProvider).getCuffName(),
    _ => _scale.getPairedName(second: _second(role)),
  };
  Future<String?> pairedId(DeviceRole role) => switch (role) {
    DeviceRole.bracelet => ref.read(hiloBleServiceProvider).getPairedMac(),
    DeviceRole.cuff => throw UnsupportedError('Use paired cuff name'),
    _ => _scale.getPairedMac(second: _second(role)),
  };
  Future<void> pair(DeviceRole role, NearbyDevice device) async {
    switch (role) {
      case DeviceRole.bracelet:
        await ref
            .read(hiloBleServiceProvider)
            .pairDevice(device.mac, device.name);
        ref.invalidate(hiloBleConnectedProvider);
      case DeviceRole.cuff:
        await ref
            .read(hiloBleServiceProvider)
            .pairCuff(device.mac, device.name);
      case DeviceRole.primaryScale:
      case DeviceRole.secondaryScale:
        await _scale.pairScale(device.mac, device.name, second: _second(role));
    }
  }

  Future<void> synchronizeBracelet() =>
      ref.read(hiloBleServiceProvider).triggerSync();
  /// Takes a measurement with the cuff or a RENPHO scale and stores it. A scale
  /// measurement returns its headline values; [onStatus] reports progress.
  Future<ScaleSummary?> measureAndSave(
    DeviceRole role, {
    void Function(String status)? onStatus,
  }) async {
    ScaleSummary? summary;
    final db = ref.read(databaseProvider);
    if (role == DeviceRole.cuff) {
      final m = await ref.read(hiloBleServiceProvider).triggerCuffMeasurement();
      await db.insertBpMeasurements([
        BpMeasurementsCompanion.insert(
          measuredAt: DateTime.now(),
          systolic: m.systolic,
          diastolic: m.diastolic,
          heartRate: m.heartRate,
          measurementType: const Value('CUFF'),
        ),
      ]);
    } else {
      final profile = ref.read(userProfileProvider).valueOrNull;
      final heightCm = profile?.heightCm;
      final age = profile?.age;
      final scaleProfile = heightCm == null || age == null
          ? null
          : RenphoUserProfile(
              heightCm: heightCm.round(),
              age: age.floor(),
              isMale: profile!.sex == 'm',
              hoursPerWeek: profile.hoursPerWeek,
              waistCm: profile.waistCm,
            );
      final m = await _scale.measure(
        second: _second(role),
        profile: scaleProfile,
        onStatus: onStatus,
      );
      summary = ScaleSummary(
        weightKg: m.weightKg,
        bodyFatPct: m.bodyFatPct,
        muscleMassKg: m.muscleMassKg,
        visceralFat: m.visceralFat,
      );
      await db.upsertRenphoMeasurements([
        RenphoRecordsCompanion.insert(
          measuredAt: m.timestamp ?? DateTime.now(),
          weight: Value(m.weightKg),
          bmi: Value(m.bmi),
          bodyFat: Value(m.bodyFatPct),
          bodyWater: Value(m.bodyWaterPct),
          muscleMass: Value(m.muscleMassKg),
          boneMass: Value(m.boneMassKg),
          bmr: Value(m.bmrKcal),
          visceralFat: Value(m.visceralFat),
          protein: Value(m.proteinPct),
          fatFreeWeight: Value(m.fatFreeMassKg),
          waistCm: Value(profile?.waistCm),
          scaleName: Value(m.scaleName ?? await pairedName(role)),
          rawJson: jsonEncode(m.raw),
        ),
      ]);
      ref.invalidate(bodyMeasurementsProvider);
    }
    ref.read(syncStatusListenerProvider.notifier).state++;
    return summary;
  }
}

/// Headline values of a stored scale measurement.
class ScaleSummary {
  const ScaleSummary({
    this.weightKg,
    this.bodyFatPct,
    this.muscleMassKg,
    this.visceralFat,
  });
  final double? weightKg, bodyFatPct, muscleMassKg, visceralFat;

  /// The scale delivered body composition, not just the weight.
  bool get hasBodyComposition => bodyFatPct != null;

  /// `89.2 kg · 16.6% fat · 55.8 kg muscle · visceral 4`
  String get text {
    String one(double v) => v.toStringAsFixed(1);
    final parts = [
      if (weightKg != null) '${one(weightKg!)} kg',
      if (bodyFatPct != null) '${one(bodyFatPct!)}% fat',
      if (muscleMassKg != null) '${one(muscleMassKg!)} kg muscle',
      if (visceralFat != null) 'visceral ${visceralFat!.round()}',
    ];
    return parts.isEmpty ? 'Measurement stored' : parts.join(' · ');
  }
}
