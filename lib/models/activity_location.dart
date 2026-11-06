import 'dart:math' as math;

/// An observed fix, with the device's timestamp and horizontal uncertainty.
class ActivityLocation {
  const ActivityLocation({
    required this.at,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude,
    this.speed,
  });
  final DateTime at;
  final double latitude, longitude, accuracy;
  final double? altitude, speed;

  static ActivityLocation? decode(Map<Object?, Object?> value) {
    double? number(String key) {
      final n = value[key];
      return n is num && n.isFinite ? n.toDouble() : null;
    }

    final t = number('t'), lat = number('lat'), lng = number('lng');
    final accuracy = number('accuracy');
    if (t == null ||
        t <= 0 ||
        t > 8640000000000000 ||
        lat == null ||
        lat.abs() > 90 ||
        lng == null ||
        lng.abs() > 180 ||
        accuracy == null ||
        accuracy < 0) {
      return null;
    }
    final speed = number('speed');
    return ActivityLocation(
      at: DateTime.fromMillisecondsSinceEpoch(t.round(), isUtc: true),
      latitude: lat,
      longitude: lng,
      accuracy: accuracy,
      altitude: number('altitude'),
      speed: speed != null && speed >= 0 ? speed : null,
    );
  }

  double distanceTo(ActivityLocation other) {
    const radians = math.pi / 180;
    final dLat = (other.latitude - latitude) * radians;
    final dLng = (other.longitude - longitude) * radians;
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(latitude * radians) *
            math.cos(other.latitude * radians) *
            math.pow(math.sin(dLng / 2), 2);
    return 6371000 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
  }
}
