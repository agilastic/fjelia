import 'dart:async';

enum HiloSyncStatus {
  idle,
  scanning,
  needsPairing,
  connecting,
  authenticating,
  syncing,
  uploading,
  done,
  error,
}

class HiloFoundDevice {
  const HiloFoundDevice({
    required this.mac,
    required this.name,
    required this.rssi,
    this.isBonded = false,
  });
  final String mac;
  final String name;
  final int rssi;
  final bool isBonded;
}

class HiloSyncState {
  const HiloSyncState({
    this.status = HiloSyncStatus.idle,
    this.message = '',
    this.framesRead = 0,
    this.lastSync,
    this.foundDevices = const [],
  });
  final HiloSyncStatus status;
  final String message;
  final int framesRead;
  final DateTime? lastSync;
  final List<HiloFoundDevice> foundDevices;

  HiloSyncState copyWith({
    HiloSyncStatus? status,
    String? message,
    int? framesRead,
    DateTime? lastSync,
  }) => HiloSyncState(
    status: status ?? this.status,
    message: message ?? this.message,
    framesRead: framesRead ?? this.framesRead,
    lastSync: lastSync ?? this.lastSync,
    foundDevices: foundDevices,
  );
}

/// Syncs a Hilo device over BLE. The implementation is supplied by the
/// `fjelia_service` package; public builds get an implementation that reports
/// the feature as unavailable.
abstract class HiloBleService {
  HiloSyncState get state;
  Stream<HiloSyncState> get stateStream;

  Future<String?> getPairedMac();
  Future<String?> getPairedName();
  Future<String?> getCuffMac();
  Future<String?> getCuffName();

  Future<void> pairDevice(String mac, String name);
  Future<void> pairCuff(String mac, String name);
  Future<void> unpairDevice();
  Future<void> unpairCuff();

  Future<List<HiloFoundDevice>> scanForDevices();
  Future<void> triggerSync();
  Future<({int diastolic, int heartRate, int systolic})>
  triggerCuffMeasurement();

  void dispose();
}
