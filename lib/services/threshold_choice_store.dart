import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/threshold_candidate.dart';

/// What the athlete decided about threshold proposals: the candidates they
/// applied (per kind) and the ones they kept the current value against.
class ThresholdChoiceStore {
  const ThresholdChoiceStore();

  static const _storage = FlutterSecureStorage();
  static const _appliedKey = 'threshold_applied_v1';
  static const _keptKey = 'threshold_kept_v1';

  /// Source of the applied value per kind, e.g. `{lt2: coros}`.
  Future<Map<ThresholdKind, String>> applied() async {
    final raw = await _storage.read(key: _appliedKey);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final kind in ThresholdKind.values)
          if (map[kind.name] case final String source) kind: source,
      };
    } on FormatException {
      return {};
    }
  }

  Future<void> markApplied(ThresholdCandidate candidate) async {
    final current = await applied();
    current[candidate.kind] = candidate.source;
    await _storage.write(
      key: _appliedKey,
      value: jsonEncode({for (final e in current.entries) e.key.name: e.value}),
    );
  }

  Future<Set<String>> kept() async {
    final raw = await _storage.read(key: _keptKey);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as List).whereType<String>().toSet();
    } on FormatException {
      return {};
    }
  }

  Future<void> keep(ThresholdCandidate candidate) async {
    final current = await kept()
      ..add(candidate.fingerprint);
    await _storage.write(key: _keptKey, value: jsonEncode(current.toList()));
  }
}

/// Whether running zones may still follow the device: not after the
/// athlete applied a running threshold from another source.
bool runZonesFollowDevice(Map<ThresholdKind, String> applied) => ![
  ThresholdKind.lt1,
  ThresholdKind.lt2,
].any((k) => applied[k] != null && applied[k] != 'garmin_api');

/// Same for cycling zones.
bool bikeZonesFollowDevice(Map<ThresholdKind, String> applied) =>
    applied[ThresholdKind.lt2Bike] == null ||
    applied[ThresholdKind.lt2Bike] == 'garmin_api';
