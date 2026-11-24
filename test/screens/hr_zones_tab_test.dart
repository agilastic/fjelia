import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/hr_zones_provider.dart';
import 'package:fjelia/screens/settings/hr_zones_tab.dart';
import 'package:fjelia/services/hr_zone_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    if (Platform.environment['FJELIA_UI_PREVIEW_DIR'] == null) return;
    final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
    if (font.existsSync()) {
      final bytes = ByteData.sublistView(await font.readAsBytes());
      for (final family in ['Roboto', 'Ahem']) {
        await (FontLoader(family)..addFont(Future.value(bytes))).load();
      }
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> preview(WidgetTester tester, String name) async {
    final output = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
    if (output == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(393, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          hrZonesProvider.overrideWith(
            (ref) => HrZonesNotifier(db, () async => 177),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepaintBoundary(
            key: const ValueKey('preview'),
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
    // The zones load from the database outside the fake clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a disagreement is asked, the choice applies', (tester) async {
    await tester.runAsync(() async {
      await HrZoneHistory(db).record(
        'running',
        [105, 133, 144, 154, 163],
        method: ZoneMethod.device,
        from: DateTime.fromMillisecondsSinceEpoch(0),
      );
      await HrZoneHistory(db).record(
        'cycling',
        [110, 126, 139, 151, 166],
        method: ZoneMethod.initial,
        from: DateTime(2026, 11, 23),
      );
    });
    FlutterSecureStorage.setMockInitialValues({
      'custom_hr_zones_cycling': '[93,122,132,142,149]',
    });
    await pump(tester, const HrZonesTab());
    expect(find.text('Radfahren: zwei verschiedene Zonen'), findsOneWidget);
    expect(find.text('Zonenverlauf'), findsOneWidget);
    expect(find.text('Frühere Einstellungen'), findsOneWidget);
    await preview(tester, 'hr_zones_conflict');

    await tester.tap(find.text('Frühere Einstellungen'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Radfahren: zwei verschiedene Zonen'), findsNothing);
    expect(find.textContaining('deine Wahl · ab '), findsOneWidget);
    await preview(tester, 'hr_zones_resolved');
  });

  testWidgets('every sport shows where its zones came from', (tester) async {
    await tester.runAsync(
      () => HrZoneHistory(db).record(
        'running',
        [110, 130, 145, 155, 165],
        method: ZoneMethod.lt2,
        from: DateTime(2026, 11, 10),
      ),
    );
    await pump(tester, const HrZonesTab());
    expect(find.textContaining('LT2-Test · ab '), findsOneWidget);
    // Cycling and swimming follow the running zones.
    expect(find.textContaining('aus deinen Laufzonen · ab '), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('zone-history-running')));
    await tester.pumpAndSettle();
    expect(find.text('110 · 130 · 145 · 155 · 165'), findsOneWidget);
    await preview(tester, 'hr_zones_history');

    await pump(tester, const HrZonesPreview());
    expect(find.byIcon(Icons.pool), findsOneWidget);
  });

  testWidgets('cycling zones above the running ones are pointed out, not '
      'changed', (tester) async {
    await tester.runAsync(() async {
      final history = HrZoneHistory(db);
      await history.record('running', [
        105,
        133,
        144,
        154,
        163,
      ], method: ZoneMethod.device);
      await history.record('cycling', [
        110,
        138,
        150,
        160,
        168,
      ], method: ZoneMethod.device);
    });
    await pump(tester, const HrZonesTab());
    expect(find.byKey(const ValueKey('zone-check-cycling')), findsOneWidget);
    expect(find.byKey(const ValueKey('zone-check-running')), findsNothing);
    expect(find.text('Schätzung übernehmen'), findsWidgets);
    await preview(tester, 'hr_zones_check');
    await pump(tester, const HrZonesPreview());
    expect(find.text('Bitte prüfe deine Zonen'), findsOneWidget);
  });
}
