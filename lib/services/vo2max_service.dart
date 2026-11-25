import 'dart:convert';

import 'package:fjelia_core/services/vo2max.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:fjelia_core/services/vo2max.dart' show Vo2MaxResult;

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

  static Vo2MaxResult? calculate(String metricsJson, String activityId) =>
      Max5Test.calculate(metricsJson, activityId);
}
