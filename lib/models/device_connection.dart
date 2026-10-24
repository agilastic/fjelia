enum DeviceRole { bracelet, cuff, primaryScale, secondaryScale }

enum ConnectionType {
  garmin,
  bloodPressure,
  bodyScale,
  coros,
  suunto,
  polar,
  health,
}

class NearbyDevice {
  const NearbyDevice({
    required this.mac,
    required this.name,
    required this.rssi,
    this.isBonded = false,
  });
  final String mac, name;
  final int rssi;
  final bool isBonded;
}

class ConnectionFailure implements Exception {
  const ConnectionFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class VerificationRequired implements Exception {
  const VerificationRequired();
}
