import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/messages_provider.dart';
import 'package:fjelia/screens/messages/messages_screen.dart';
import 'package:fjelia_data/messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    // Messages go nowhere in tests: a closed port refuses at once.
    MessagesNotifier.relayBase = Uri.parse('http://127.0.0.1:9');
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MessagesScreen(),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('before meeting a coach it says how to', (tester) async {
    await open(tester);
    expect(find.textContaining('syncs with the coach'), findsOneWidget);
    // A new phone can come back as someone with their code.
    expect(find.text('I have a recovery code'), findsOneWidget);
    await tester.tap(find.text('I have a recovery code'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).last, 'not a code');
    await tester.tap(find.text('Done'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(
      find.text('This code was not found or does not fit.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an athlete writes to the coach; it waits for the relay', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await db.installMessages();
      await db.savePerson(
        const MessagePerson(
          person: 'p-kim',
          name: 'Kim',
          role: PersonRole.coach,
        ),
      );
    });
    await open(tester);
    await tester.tap(find.text('Write to Kim'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Kim'), findsOneWidget); // the conversation's title
    await tester.enterText(find.byType(TextField).last, 'Knee hurts a bit');
    await tester.tap(find.byIcon(Icons.send));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Knee hurts a bit'), findsOneWidget);
    expect(find.textContaining('waiting to send'), findsOneWidget);
    // Without the server, no recovery code is made, and it says so.
    await tester.pageBack();
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.tap(find.text('Make a new recovery code'));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(
      find.textContaining("No connection to Fjelia's server"),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
