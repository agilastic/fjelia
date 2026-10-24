import 'package:shared_preferences/shared_preferences.dart';

enum HeatLocationMode { current, fixed, none }

class HeatAcclimationSettings {
  const HeatAcclimationSettings({
    this.enabled = true,
    this.locationMode = HeatLocationMode.current,
    this.fixedLatitude,
    this.fixedLongitude,
    this.fixedLocationName,
  });

  final bool enabled;
  final HeatLocationMode locationMode;
  final double? fixedLatitude;
  final double? fixedLongitude;
  final String? fixedLocationName;

  HeatAcclimationSettings copyWith({
    bool? enabled,
    double? fixedLatitude,
    double? fixedLongitude,
    HeatLocationMode? locationMode,
    String? fixedLocationName,
  }) {
    return HeatAcclimationSettings(
      enabled: enabled ?? this.enabled,
      locationMode: locationMode ?? this.locationMode,
      fixedLocationName: fixedLocationName ?? this.fixedLocationName,
      fixedLatitude: fixedLatitude ?? this.fixedLatitude,
      fixedLongitude: fixedLongitude ?? this.fixedLongitude,
    );
  }
}

class HeatAcclimationSettingsStore {
  const HeatAcclimationSettingsStore();

  static const _kEnabled = 'heat_acclimation_enabled';
  static const _kLocationMode = 'heat_acclimation_location_mode';
  static const _kLat = 'heat_acclimation_fixed_latitude';
  static const _kLng = 'heat_acclimation_fixed_longitude';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? true;
  }

  Future<HeatAcclimationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return HeatAcclimationSettings(
      enabled: prefs.getBool(_kEnabled) ?? true,
      locationMode: HeatLocationMode.values.byName(
        prefs.getString(_kLocationMode) ?? 'current',
      ),
      fixedLatitude: prefs.getDouble(_kLat),
      fixedLongitude: prefs.getDouble(_kLng),
      fixedLocationName: prefs.getString('weather_fixed_location_name'),
    );
  }

  Future<void> saveEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, enabled);
  }

  Future<void> saveLocationMode(HeatLocationMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocationMode, mode.name);
  }

  Future<void> saveFixedLocation(
    double latitude,
    double longitude, {
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLat, latitude);
    await prefs.setDouble(_kLng, longitude);
    if (name == null) {
      await prefs.remove('weather_fixed_location_name');
    } else {
      await prefs.setString('weather_fixed_location_name', name);
    }
  }
}
