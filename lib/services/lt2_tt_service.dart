import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Result of a 30-minute time trial: LT2 HR and pace from its last 20 min.
class Lt2TtResult {
  const Lt2TtResult({
    required this.lt2,
    required this.pace,
    required this.paceSec,
    required this.at,
    required this.activityId,
  });

  final int lt2;
  final String pace;
  final int paceSec;
  final DateTime at;
  final String activityId;

  Map<String, dynamic> toJson() => {
    'lt2': lt2,
    'pace': pace,
    'paceSec': paceSec,
    'at': at.toIso8601String(),
    'aid': activityId,
  };

  static Lt2TtResult fromJson(Map<String, dynamic> json) => Lt2TtResult(
    lt2: json['lt2'] as int,
    pace: json['pace'] as String,
    paceSec: json['paceSec'] as int? ?? _paceStrToSec(json['pace'] as String),
    at: DateTime.parse(json['at'] as String),
    activityId: json['aid'] as String,
  );

  /// `"4:41/km"` → 281.
  static int _paceStrToSec(String pace) {
    final parts = pace.split('/').first.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

abstract class Lt2TtService {
  static const _key = 'tt_test_result_v1';

  static Future<Lt2TtResult?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return Lt2TtResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> save(Lt2TtResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(result.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Finds the fastest 30-min window and averages HR and pace over its final
  /// 20 minutes (Friel's LTHR protocol).
  static Lt2TtResult? calculate(
    String metricsJson,
    String activityId, {
    int? warmupMinutes,
  }) {
    final samples = (jsonDecode(metricsJson) as List)
        .cast<Map<String, dynamic>>();
    final times = <double>[];
    final hrs = <int>[];
    final dists = <double>[];
    var t = 0.0;
    var prevD = 0.0;
    for (final s in samples) {
      final d = (s['d'] as num?)?.toDouble();
      final hr = (s['hr'] as num?)?.toInt();
      final spd = (s['spd'] as num?)?.toDouble();
      if (d == null || spd == null || spd <= 0.1) continue;
      t += (d - prevD).abs() / spd;
      prevD = d;
      times.add(t);
      hrs.add(hr ?? 0);
      dists.add(d);
    }
    if (times.isEmpty || times.last < 1800) return null;

    // Fastest 30-minute window.
    var bestStart = 0, bestEnd = 0;
    var bestDist = 0.0;
    var j = 0;
    for (var i = 0; i < times.length; i++) {
      if (warmupMinutes != null && times[i] < warmupMinutes * 60) continue;
      while (j < times.length && times[j] - times[i] < 1800.0) {
        j++;
      }
      if (j >= times.length) break;
      final dist = dists[j] - dists[i];
      if (dist > bestDist) {
        bestDist = dist;
        bestStart = i;
        bestEnd = j;
      }
      if (warmupMinutes != null) break;
    }
    if (bestDist <= 0) return null;

    // Last 20 minutes of it.
    final splitTime = times[bestEnd] - 1200.0;
    var k = bestStart;
    while (k < bestEnd && times[k] < splitTime) {
      k++;
    }
    final lastHrs = hrs.sublist(k, bestEnd + 1).where((h) => h > 0).toList();
    if (lastHrs.isEmpty) return null;
    final lt2 = (lastHrs.reduce((a, b) => a + b) / lastHrs.length).round();
    final dist20 = dists[bestEnd] - dists[k];
    if (dist20 <= 0) return null;
    final paceSec = (1200.0 / (dist20 / 1000.0)).round();
    final pace =
        '${paceSec ~/ 60}:${(paceSec % 60).toString().padLeft(2, '0')}/km';
    return Lt2TtResult(
      lt2: lt2,
      pace: pace,
      paceSec: paceSec,
      at: DateTime.now(),
      activityId: activityId,
    );
  }
}
