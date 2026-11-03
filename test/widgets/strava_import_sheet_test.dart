import 'dart:io';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/media_provider.dart';
import 'package:fjelia/providers/strava_import_provider.dart';
import 'package:fjelia/services/media_service.dart';
import 'package:fjelia/widgets/strava_import_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/strava_archive_fixture.dart';

void main() {
  testWidgets('choose, preview, import, summary', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final dir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('strava_sheet'),
    ))!;
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        mediaServiceProvider.overrideWithValue(
          MediaService(db, root: Directory('${dir.path}/app')),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
      await dir.delete(recursive: true);
    });
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: StravaImportSheet()),
        ),
      ),
    );
    expect(find.text('Choose ZIP'), findsOneWidget);

    final path = writeStravaArchive(dir);
    await tester.runAsync(
      () => container.read(stravaImportProvider.notifier).open(path),
    );
    await tester.pumpAndSettle();
    expect(find.text('4 activities found'), findsOneWidget);
    expect(find.text('3 photos, 0 videos'), findsOneWidget);

    await tester.runAsync(
      () => container.read(stravaImportProvider.notifier).start(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Strava import complete'), findsOneWidget);
    // Nothing in Fjelia yet: three new, and 444 is 111's recording again.
    expect(find.text('3 activities imported'), findsOneWidget);
    expect(find.text('Duplicates: 1 skipped'), findsOneWidget);
    expect(find.text('Photos: 3 imported'), findsOneWidget);
    // The athlete's own archive is never deleted, only a picker's copy.
    expect(File(path).existsSync(), isTrue);
  });
}
