import 'dart:convert';

import 'package:fjelia_core/services/lt1_drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:fjelia_core/services/lt1_drift.dart' show Lt1DriftResult;

abstract class Lt1DriftService {
  static const _key = 'lt1_drift_result_v1';

  static Future<Lt1DriftResult?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return Lt1DriftResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> save(Lt1DriftResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(result.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Lt1DriftResult? calculate(String metricsJson, String activityId) =>
      Lt1DriftTest.calculate(metricsJson, activityId);
}
