import 'package:shared_preferences/shared_preferences.dart';

import 'ai_coach_settings.dart';

/// The athlete's yes to sending the briefing context to a cloud service.
/// Given once per provider and model: after a change in the AI settings
/// Fjelia asks again, otherwise the briefing is written without asking.
class BriefingConsent {
  const BriefingConsent._();

  static const _key = 'ai_briefing_cloud_consent_v1';

  static String _of(AiCoachSettings s) => '${s.provider.name}|${s.model}';

  static Future<bool> given(AiCoachSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key) == _of(settings);
    } catch (_) {
      return false;
    }
  }

  static Future<void> remember(AiCoachSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _of(settings));
  }
}
