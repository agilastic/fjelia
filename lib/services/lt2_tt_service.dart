import 'dart:convert';

import 'package:fjelia_core/services/lt2_tt.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:fjelia_core/services/lt2_tt.dart' show Lt2TtResult;

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

  static Lt2TtResult? calculate(
    String metricsJson,
    String activityId, {
    int? warmupMinutes,
  }) => Lt2TimeTrial.calculate(
    metricsJson,
    activityId,
    warmupMinutes: warmupMinutes,
  );
}
