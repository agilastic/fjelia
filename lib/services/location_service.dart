import 'package:location/location.dart';

class CurrentLocationData {
  const CurrentLocationData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
}

class LocationService {
  LocationService({Location? location}) : _location = location ?? Location();

  final Location _location;

  /// Current position, or null without permission or a fix within 8 s.
  Future<CurrentLocationData?> getCurrentLocation() async {
    try {
      final permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.grantedLimited) {
        return null;
      }
      final data =
          await _location.getLocation().timeout(const Duration(seconds: 8));
      return CurrentLocationData(
        latitude: data.latitude,
        longitude: data.longitude,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      // The plugin occasionally fails right after the permission prompt.
      await Future.delayed(const Duration(seconds: 2));
      return null;
    }
  }
}
