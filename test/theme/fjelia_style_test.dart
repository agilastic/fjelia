import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/style_provider.dart';
import 'package:fjelia/screens/settings/display_tab.dart';
import 'package:fjelia/theme/app_theme.dart';
import 'package:fjelia/theme/fjelia_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A constant widget that paints the panel colour of the current look.
class _Swatch extends StatelessWidget {
  const _Swatch();
  @override
  Widget build(BuildContext context) =>
      Container(key: const Key('swatch'), color: fjPanel, height: 10);
}

Widget app(ThemeMode mode, {Widget home = const _Swatch()}) => MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: mode,
  themeAnimationDuration: Duration.zero,
  builder: (context, child) => FjeliaStyleScope(child: child!),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: home),
);

Color swatch(WidgetTester tester) =>
    tester.widget<Container>(find.byKey(const Key('swatch'))).color!;

void main() {
  tearDown(() => Fjelia.style = FjeliaStyle.dark);

  test('DarkFjelia is the default and a choice is kept', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(styleChoiceProvider.future), StyleChoice.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    await container.read(styleChoiceProvider.notifier).set(StyleChoice.auto);
    expect(container.read(themeModeProvider), ThemeMode.system);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('fjelia_style'), 'auto');
  });

  test('DarkFjelia keeps the colours the app always had', () {
    Fjelia.style = FjeliaStyle.dark;
    expect(fjPanel, const Color(0xFF202020));
    expect(fjInk70, Colors.white70);
    expect(duo(0xFF2A2A2A, 0xFFEEF1F5), const Color(0xFF2A2A2A));
  });

  testWidgets('switching the look repaints constant widgets too', (
    tester,
  ) async {
    await tester.pumpWidget(app(ThemeMode.dark));
    expect(swatch(tester), const Color(0xFF202020));

    await tester.pumpWidget(app(ThemeMode.light));
    await tester.pump();
    expect(Fjelia.style, FjeliaStyle.light);
    expect(swatch(tester), const Color(0xFFFFFFFF));
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.light,
    );

    await tester.pumpWidget(app(ThemeMode.dark));
    await tester.pump();
    expect(swatch(tester), const Color(0xFF202020));
  });

  testWidgets('the look is chosen in Display: auto, dark or light', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(child: app(ThemeMode.dark, home: const DisplayTab())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Style'), findsWidgets);
    expect(find.text('DarkFjelia'), findsOneWidget);
    expect(find.text('LightFjelia'), findsOneWidget);

    await tester.tap(find.text('LightFjelia'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('fjelia_style'), 'light');

    await tester.tap(find.text('Auto'));
    await tester.pumpAndSettle();
    expect(prefs.getString('fjelia_style'), 'auto');
    expect(find.textContaining('Follows your phone'), findsOneWidget);
  });
}
