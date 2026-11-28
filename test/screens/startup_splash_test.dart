import 'package:fjelia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/screens/startup_splash.dart';

void main() {
  testWidgets('the lockup shows on black, named for screen readers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: StartupSplash(onMinimumElapsed: () {})),
    );
    expect(find.bySemanticsLabel('Fjelia'), findsOneWidget);
    final box = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(StartupSplash),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(box.color, Colors.black);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the decoded lockup stays visible for two seconds', (tester) async {
    var elapsed = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StartupSplash(onMinimumElapsed: () => elapsed = true),
      ),
    );
    final context = tester.element(find.byType(StartupSplash));
    await tester.runAsync(
      () => precacheImage(const AssetImage(startupLockup), context),
    );
    await tester.pump();
    expect(elapsed, isFalse);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(elapsed, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(elapsed, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
