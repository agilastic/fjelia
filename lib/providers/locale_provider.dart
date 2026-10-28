import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

const _prefsKey = 'app_language';

/// Language codes the app is translated into. English is the fallback.
const supportedLanguageCodes = [
  'en', 'de', 'fr', 'it', 'es', 'ca', 'nb', 'sk', 'fi', 'da', //
];

/// Each language written in itself, for the picker.
const languageNames = <String, String>{
  'en': 'English (UK)',
  'de': 'Deutsch',
  'fr': 'Français',
  'it': 'Italiano',
  'es': 'Español',
  'ca': 'Català',
  'nb': 'Norsk',
  'sk': 'Slovenčina',
  'fi': 'Suomi',
  'da': 'Dansk',
};

/// The saved language code, or null to follow the phone.
final languageProvider = AsyncNotifierProvider<LanguageNotifier, String?>(
  LanguageNotifier.new,
);

class LanguageNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    return supportedLanguageCodes.contains(saved) ? saved : null;
  }

  /// Pass null to follow the phone language again.
  Future<void> set(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, code);
    }
    state = AsyncData(code);
  }
}

/// The locale the app shows: the saved choice, else the phone's language
/// when translated, else English.
final appLocaleProvider = Provider<Locale>((ref) {
  final saved = ref.watch(languageProvider).valueOrNull;
  return Locale(saved ?? phoneLanguageCode());
});

/// The phone's language if we have a translation for it, otherwise `en`.
/// Norwegian Bokmål and Nynorsk both use the `nb` strings.
String phoneLanguageCode() {
  var code = ui.PlatformDispatcher.instance.locale.languageCode;
  if (code == 'no' || code == 'nn') code = 'nb';
  return supportedLanguageCodes.contains(code) ? code : 'en';
}

/// Strings for code that has no [BuildContext], e.g. notifications.
Future<AppLocalizations> currentLocalizations() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_prefsKey);
  final code = supportedLanguageCodes.contains(saved)
      ? saved!
      : phoneLanguageCode();
  return AppLocalizations.delegate.load(Locale(code));
}
