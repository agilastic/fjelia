/// One sport's HR zone setup as configured on a device/platform (Garmin,
/// Polar, …), mapped to a uniform shape: five zone floors plus the
/// thresholds they were derived from.
class DeviceHrZones {
  const DeviceHrZones({
    required this.source,
    required this.sport,
    required this.method,
    required this.floors,
    this.lthr,
    this.maxHr,
    this.restingHr,
  });

  /// Source id as used for activities: garmin_api, polar, coros, …
  final String source;

  /// DEFAULT, RUNNING, CYCLING or SWIMMING.
  final String sport;

  /// How the zones are defined, e.g. LACTATE_THRESHOLD, HR_MAX, HR_RESERVE.
  final String method;

  /// Lower bounds of zones 1–5.
  final List<int> floors;
  final int? lthr, maxHr, restingHr;

  bool get isLthrBased => method.toUpperCase().contains('LACTATE');

  /// Garmin `/biometric-service/heartRateZones` entry.
  static DeviceHrZones? fromGarminJson(Map<String, dynamic> json) {
    final floors = <int>[];
    for (var i = 1; i <= 5; i++) {
      final v = json['zone${i}Floor'];
      if (v is! num) return null;
      floors.add(v.round());
    }
    int? n(String key) => (json[key] as num?)?.round();
    return DeviceHrZones(
      source: 'garmin_api',
      sport: (json['sport'] as String? ?? 'DEFAULT').toUpperCase(),
      method: json['trainingMethod'] as String? ?? 'UNKNOWN',
      floors: floors,
      lthr: n('lactateThresholdHeartRateUsed'),
      maxHr: n('maxHeartRateUsed'),
      restingHr: n('restingHeartRateUsed'),
    );
  }

  Map<String, dynamic> toJson() => {
    'source': source,
    'sport': sport,
    'method': method,
    'floors': floors,
    'lthr': lthr,
    'maxHr': maxHr,
    'restingHr': restingHr,
  };

  static DeviceHrZones fromJson(Map<String, dynamic> json) => DeviceHrZones(
    source: json['source'] as String,
    sport: json['sport'] as String,
    method: json['method'] as String,
    floors: (json['floors'] as List).map((e) => (e as num).toInt()).toList(),
    lthr: (json['lthr'] as num?)?.toInt(),
    maxHr: (json['maxHr'] as num?)?.toInt(),
    restingHr: (json['restingHr'] as num?)?.toInt(),
  );

  /// Sport key for a planner/activity sport.
  static String sportKey(String activityType) {
    final t = activityType.toLowerCase();
    if (t.contains('cycl') || t.contains('bik') || t.contains('ride')) {
      return 'CYCLING';
    }
    if (t.contains('swim')) return 'SWIMMING';
    if (t.contains('run') || t.contains('walk') || t.contains('hik')) {
      return 'RUNNING';
    }
    return 'DEFAULT';
  }
}
