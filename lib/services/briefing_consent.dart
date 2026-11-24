import 'package:shared_preferences/shared_preferences.dart';

import 'ai_coach_settings.dart';

/// The athlete's one-time yes to sending briefing context to an AI cloud
/// service. It is independent of provider/model selection.
class BriefingConsent {
  const BriefingConsent._();

  static const _key = 'ai_briefing_cloud_consent_v2';
  static const _legacyKey = 'ai_briefing_cloud_consent_v1';

  static Future<bool> given(AiCoachSettings settings) async {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    await prefs.remove(_legacyKey);
  }
}

/// FjeliaPro: Fjelia AI Pro (the small model) writes the briefings instead of
/// Apple Intelligence. Off until the athlete switches it on in Settings →
/// Training; switching it on is the consent to send the briefing context.
class ProBriefing {
  const ProBriefing._();

  static const _key = 'ai_briefing_pro_v1';

  static Future<bool> enabled() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> set(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_key, value);
}
