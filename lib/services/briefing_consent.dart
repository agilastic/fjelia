import 'package:shared_preferences/shared_preferences.dart';

import 'ai_coach_settings.dart';

/// The athlete's one-time yes to sending briefing context to an AI cloud
/// service. It is independent of provider/model selection.
class BriefingConsent {
  const BriefingConsent._();

  static const _key = 'ai_briefing_cloud_consent_v2';
  static const _legacyKey = 'ai_briefing_cloud_consent_v1';

  static Future<bool> given(AiCoachSettings settings) async {
    if (settings.usesOnDeviceBriefing) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_key) == true) return true;

      // Preserve a yes from older versions, which stored provider|model.
      final legacy = prefs.getString(_legacyKey);
      if (legacy != null && legacy.contains('|')) {
        await prefs.setBool(_key, true);
        await prefs.remove(_legacyKey);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> remember(AiCoachSettings settings) async {
    if (settings.usesOnDeviceBriefing) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    await prefs.remove(_legacyKey);
  }
}
