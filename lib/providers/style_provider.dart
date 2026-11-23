import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'fjelia_style';

/// The look the user chose: follow the phone, DarkFjelia (the default) or
/// LightFjelia.
enum StyleChoice { auto, dark, light }

final styleChoiceProvider = AsyncNotifierProvider<StyleNotifier, StyleChoice>(
  StyleNotifier.new,
);

class StyleNotifier extends AsyncNotifier<StyleChoice> {
  @override
  Future<StyleChoice> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    return StyleChoice.values.asNameMap()[saved] ?? StyleChoice.dark;
  }

  Future<void> set(StyleChoice choice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, choice.name);
    state = AsyncData(choice);
  }
}

/// The theme mode for the app; dark until the choice is read.
final themeModeProvider = Provider<ThemeMode>(
  (ref) => switch (ref.watch(styleChoiceProvider).valueOrNull) {
    StyleChoice.auto => ThemeMode.system,
    StyleChoice.light => ThemeMode.light,
    _ => ThemeMode.dark,
  },
);

const _skyKey = 'home_sky_v1';

/// The weather sky at the top of Home (on unless turned off).
final homeSkyProvider = AsyncNotifierProvider<HomeSkyNotifier, bool>(
  HomeSkyNotifier.new,
);

class HomeSkyNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async =>
      (await SharedPreferences.getInstance()).getBool(_skyKey) ?? true;

  Future<void> set(bool value) async {
    await (await SharedPreferences.getInstance()).setBool(_skyKey, value);
    state = AsyncData(value);
  }
}
