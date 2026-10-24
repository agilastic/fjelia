import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Result of a MAX5 field test: best 5-minute effort pace.
class Vo2MaxResult {
  const Vo2MaxResult({
    required this.pace,
    required this.paceSec,
    required this.at,
    required this.activityId,
  });

  final String pace;
  final int paceSec;
  final DateTime at;
  final String activityId;

  Map<String, dynamic> toJson() => {
        'pace': pace,
        'paceSec': paceSec,
        'at': at.toIso8601String(),
        'aid': activityId,
      };

  static Vo2MaxResult fromJson(Map<String, dynamic> json) => Vo2MaxResult(
        pace: json['pace'] as String,
        paceSec: json['paceSec'] as int,
        at: DateTime.parse(json['at'] as String),
        activityId: json['aid'] as String,
      );
}

abstract class Vo2MaxService {
  static const _key = 'max5_test_result_v1';

  static Future<Vo2MaxResult?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return Vo2MaxResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> save(Vo2MaxResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(result.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Fastest 5-minute window in an activity's metric samples
  /// (`[{d: metres, spd: m/s}, …]`).
  static Vo2MaxResult? calculate(String metricsJson, String activityId) {
    final samples = (jsonDecode(metricsJson) as List)
        .cast<Map<String, dynamic>>();
    final times = <double>[];
    final dists = <double>[];
    var t = 0.0;
    var prevD = 0.0;
    for (final s in samples) {
      final d = (s['d'] as num?)?.toDouble();
      final spd = (s['spd'] as num?)?.toDouble();
      if (d == null || spd == null || spd <= 0.1) continue;
      t += (d - prevD).abs() / spd;
      prevD = d;
      times.add(t);
      dists.add(d);
    }
    if (times.isEmpty || times.last < 300) return null;

    var bestDist = 0.0;
    var j = 0;
    for (var i = 0; i < times.length; i++) {
      while (j < times.length && times[j] - times[i] < 300.0) {
        j++;
      }
      if (j >= times.length) break;
      final dist = dists[j] - dists[i];
      if (dist > bestDist) bestDist = dist;
    }
    if (bestDist <= 0) return null;

    final paceSec = (300.0 / (bestDist / 1000.0)).round();
    final pace = '${paceSec ~/ 60}:${(paceSec % 60).toString().padLeft(2, '0')}/km';
    return Vo2MaxResult(
      pace: pace,
      paceSec: paceSec,
      at: DateTime.now(),
      activityId: activityId,
    );
  }
}
