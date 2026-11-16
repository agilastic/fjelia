import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A Bluetooth blood-pressure monitor the athlete saved in the settings.
///
/// Two kinds measure differently: a Hilo cuff takes a measurement when Fjelia
/// asks for one; an Omron or standard Bluetooth monitor measures on its own
/// and Fjelia reads the readings stored in it.
class BpMonitor {
  const BpMonitor({
    required this.kind,
    required this.id,
    required this.name,
    this.model,
  });

  /// `hilo` or `memory` (Omron profiles and the standard BLE service).
  final String kind;

  /// The BLE id; `hilo` for the paired Hilo cuff.
  final String id;
  final String name;

  /// For a `memory` monitor: an Omron model number, or the standard service.
  final String? model;

  bool get live => kind == 'hilo';

  Map<String, String> toJson() => {
    'kind': kind,
    'id': id,
    'name': name,
    'model': ?model,
  };

  static BpMonitor? fromJson(Object? json) {
    if (json is! Map) return null;
    final kind = json['kind'], id = json['id'], name = json['name'];
    if (kind is! String || id is! String || name is! String) return null;
    return BpMonitor(
      kind: kind,
      id: id,
      name: name,
      model: json['model'] as String?,
    );
  }
}

/// The Omron and standard monitors, kept on the device. The Hilo cuff keeps
/// its own pairing and joins the list from there.
class BpMonitorStore {
  const BpMonitorStore();

  static const _key = 'bp_monitors_v1';

  Future<List<BpMonitor>> list() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return const [];
      return [
        for (final j in jsonDecode(raw) as List) ?BpMonitor.fromJson(j),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Saves [monitor]; a monitor with the same id is replaced.
  Future<void> save(BpMonitor monitor) async {
    final all = [
      for (final m in await list())
        if (m.id != monitor.id) m,
      monitor,
    ];
    await _write(all);
  }

  Future<void> remove(String id) async =>
      _write([for (final m in await list()) if (m.id != id) m]);

  Future<void> _write(List<BpMonitor> all) async =>
      (await SharedPreferences.getInstance()).setString(
        _key,
        jsonEncode([for (final m in all) m.toJson()]),
      );
}
