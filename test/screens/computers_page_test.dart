import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/screens/settings/computers_page.dart';
import 'package:fjelia_core/services/sync/sync_tables.dart';
import 'package:fjelia_sync/fjelia_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
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
          home: const ComputersPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('without a computer it offers pairing', (tester) async {
    await open(tester);
    expect(find.text('No computer paired yet.'), findsOneWidget);
    expect(find.text('Pair with a computer'), findsOneWidget);
  });

  testWidgets('a paired computer is listed and can be unpaired', (
    tester,
  ) async {
    await tester.runAsync(
      () => db.saveSyncPeer(
        SyncPeer(
          deviceId: 'mac',
          name: 'Studio Mac',
          fingerprint: 'f' * 64,
          pairedAt: DateTime(2026, 11, 25),
          categories: {SyncCategory.activities},
        ),
      ),
    );
    await open(tester);
    expect(find.text('Studio Mac'), findsOneWidget);
    expect(find.text('No computer paired yet.'), findsNothing);

    await tester.tap(find.byType(PopupMenuButton<void Function()>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unpair'));
    await tester.pumpAndSettle();
    expect(find.text('Unpair Studio Mac?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Unpair'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Studio Mac'), findsNothing);
    expect(await tester.runAsync(db.syncPeers), isEmpty);
  });
}
