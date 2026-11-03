import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/widgets/recently_deleted_sheet.dart';
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

  testWidgets('a deleted activity is listed and restored', (tester) async {
    await tester.runAsync(() async {
      // An imported file: no source to ask, it comes back from its summary.
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'file_1',
              name: 'Evening Ride',
              type: 'cycling',
              startDate: DateTime(2026, 11, 1, 18),
              durationSeconds: 5400,
              distanceMeters: const Value(42000),
              source: const Value('file'),
            ),
          );
      await db.deleteActivityByUser('file_1');
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: RecentlyDeletedSheet()),
        ),
      ),
    );
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Evening Ride'), findsOneWidget);
    expect(find.textContaining('42.0 km'), findsOneWidget);

    await tester.tap(find.byTooltip('Restore'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Evening Ride'), findsNothing);
    expect(find.text('No deleted activities.'), findsOneWidget);
    expect(find.textContaining('restored with its totals'), findsOneWidget);
    final back = await tester.runAsync(() => db.getActivityById('file_1'));
    expect(back!.distanceMeters, 42000);
  });
}
