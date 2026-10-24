import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/device_hr_zones.dart';

/// Latest HR zone setup reported by each connected platform, so zones from
/// Garmin, Polar, … are available side by side in one shape.
class DeviceZoneStore {
  const DeviceZoneStore();

  static const _storage = FlutterSecureStorage();
  static const _key = 'device_hr_zones_v1';

  Future<Map<String, List<DeviceHrZones>>> all() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final e in map.entries)
        e.key: [
          for (final z in e.value as List)
            DeviceHrZones.fromJson(z as Map<String, dynamic>),
        ],
    };
  }

  /// Replaces [source]'s zones, or merges per sport when [merge] is set
  /// (sources that report zones one sport at a time, e.g. per exercise).
  Future<void> save(
    String source,
    List<DeviceHrZones> zones, {
    bool merge = false,
  }) async {
    if (zones.isEmpty) return;
    final current = await all();
    final list = merge ? [...?current[source]] : <DeviceHrZones>[];
    for (final z in zones) {
      list.removeWhere((o) => o.sport == z.sport);
      list.add(z);
    }
    current[source] = list;
    await _storage.write(
      key: _key,
      value: jsonEncode({
        for (final e in current.entries)
          e.key: [for (final z in e.value) z.toJson()],
      }),
    );
  }
}
