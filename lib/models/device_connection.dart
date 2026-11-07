enum DeviceRole { bracelet, cuff, primaryScale, secondaryScale }

enum ConnectionType {
  garmin,
  bloodPressure,
  bodyScale,
  coros,
  suunto,
  myWhoosh,
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

/// The account is open on another device and must be signed out there first.
class SignedInElsewhere implements Exception {
  const SignedInElsewhere();
}

class VerificationRequired implements Exception {
  const VerificationRequired();
}
