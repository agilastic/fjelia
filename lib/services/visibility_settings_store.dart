import 'package:shared_preferences/shared_preferences.dart';

/// Per-page show/hide toggles for dashboard cards.
class VisibilitySettingsStore {
  const VisibilitySettingsStore();

  static String _key(String page, String item) => 'visible_${page}_$item';

  Future<Map<String, bool>> loadPage(
      String page, Map<String, bool> defaults) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final key in defaults.keys)
        key: prefs.getBool('visible_${page}_$key') ?? defaults[key]!,
    };
  }

  Future<void> setVisible(String page, String item, bool visible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(page, item), visible);
  }
}
