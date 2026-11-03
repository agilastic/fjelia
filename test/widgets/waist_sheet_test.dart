import 'dart:io';

import 'package:drift/drift.dart' show Value;

import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:fjelia/widgets/waist_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  final boundary = GlobalKey();

  setUpAll(() async {
    if (Platform.environment['FJELIA_UI_PREVIEW_DIR'] == null) return;
    final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
    await (FontLoader('Roboto')..addFont(
          Future.value(ByteData.sublistView(await font.readAsBytes())),
        ))
        .load();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<ProviderContainer> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 3400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await tester.runAsync(
      () => container
          .read(userProfileProvider.notifier)
          .save(const UserProfile(heightCm: 180)),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData.dark(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RepaintBoundary(
              key: boundary,
              child: const ColoredBox(color: Colors.black, child: WaistSheet()),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> preview(WidgetTester tester, String name) async {
    final output = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
    if (output == null) return;
    final box =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await box.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('saving a waist shows it with its ratios', (tester) async {
    final container = await pump(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(WaistSheet)));
    expect(find.text(l10n.noWaistYet), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '88');
    await tester.enterText(find.byType(TextField).at(1), '100');
    await tester.tap(find.text(l10n.saveMeasurement));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    final rows = await tester.runAsync(db.getWaistMeasurements);
    expect(rows!.single.waistCm, 88);
    expect(rows.single.hipCm, 100);
    expect(find.text('88'), findsOneWidget);
    expect(find.text('0.49'), findsOneWidget); // WHtR 88 / 180
    expect(find.text('0.88'), findsOneWidget); // WHR 88 / 100
    final profile = await tester.runAsync(
      () => container.read(userProfileProvider.future),
    );
    expect(profile!.waistCm, 88);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wrong value is refused', (tester) async {
    await pump(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(WaistSheet)));
    await tester.enterText(find.byType(TextField).at(0), '8');
    await tester.tap(find.text(l10n.saveMeasurement));
    await tester.pumpAndSettle();
    expect(find.text(l10n.enterValidWaist), findsOneWidget);
    expect(await tester.runAsync(db.getWaistMeasurements), isEmpty);
  });

  testWidgets('history with changes', (tester) async {
    for (final (at, w, h) in [
      (DateTime(2025, 11, 1, 7), 94.0, 102.0),
      (DateTime(2026, 6, 1, 7), 91.0, null),
      (DateTime(2026, 10, 2, 7), 89.5, null),
      (DateTime(2026, 11, 1, 7), 88.0, 100.0),
    ]) {
      await db.insertWaistMeasurement(
        WaistMeasurementsCompanion.insert(
          measuredAt: at,
          waistCm: w,
          hipCm: Value(h),
        ),
      );
    }
    await pump(tester);
    expect(find.textContaining('−6'), findsOneWidget); // 1 year
    expect(find.textContaining('−1.5'), findsOneWidget); // 30 days
    await preview(tester, 'waist_sheet');
  });
}
