import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/screens/settings/system_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('delete all data asks twice and offers a backup', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('de'),
          home: SystemTab(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alle Daten löschen'));
    await tester.pumpAndSettle();
    expect(find.text('Alle Daten löschen?'), findsOneWidget);
    expect(find.text('Backup erstellen'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('wipe-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Wirklich alles löschen?'), findsOneWidget);
    expect(find.byKey(const ValueKey('wipe-confirm')), findsOneWidget);

    // Cancelled: nothing runs.
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.text('Alle Daten werden gelöscht…'), findsNothing);
    expect(find.text('Alle Daten löschen'), findsOneWidget);
  });
}
