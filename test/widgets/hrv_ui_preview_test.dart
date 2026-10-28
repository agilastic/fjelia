import 'package:fjelia/l10n/app_localizations.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/spot_hrv.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/hrv_reminder_provider.dart';
import 'package:fjelia/providers/hrv_training_provider.dart';
import 'package:fjelia/services/hrv/hrv_training_service.dart';
import 'package:fjelia/theme/app_theme.dart';
import 'package:fjelia/widgets/hrv_reminder_tile.dart';
import 'package:fjelia/widgets/workout_hrv_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_notification_gateway.dart';
import '../support/hrv_db.dart';

/// Renders the HRV surfaces to PNG files when FJELIA_UI_PREVIEW_DIR is set,
/// for a visual review. Without it, each state is still built once, so a
/// layout overflow fails here.
void main() {
  final output = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
  setUpAll(() async {
    if (output == null) return;
    final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
    if (font.existsSync()) {
      final loader = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
      await loader.load();
    }
    try {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    } catch (_) {}
  });

  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  final key = GlobalKey();

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget child, {
    double width = 393,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = FakeNotificationGateway();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          hrvTrainingServiceProvider.overrideWithValue(
            HrvTrainingService(db, clock: () => atMin(600)),
          ),
          localNotificationGatewayProvider.overrideWithValue(gateway),
          hrvSensorReadyProvider.overrideWithValue(() async => true),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: app!,
          ),
          home: Scaffold(
            backgroundColor: const Color(0xFF111111),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: RepaintBoundary(
                key: key,
                child: Material(color: const Color(0xFF111111), child: child),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(tester.takeException(), isNull);
    if (output != null) {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File('$output/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('pair', (tester) async {
    await addActivity(db, 'ride', 0, 120);
    await addReading(db, -20, SpotHrvContext.beforeTraining, rmssd: 60);
    await addReading(db, 151, SpotHrvContext.afterTraining, rmssd: 45);
    await shoot(tester, 'card-pair', const WorkoutHrvCard(activityId: 'ride'));
  });

  testWidgets('pair with history', (tester) async {
    for (var d = 1; d <= 10; d++) {
      final base = -d * 3 * 24 * 60;
      await addActivity(db, 'h$d', base, 120);
      await addReading(db, base - 20, SpotHrvContext.beforeTraining, rmssd: 58);
      await addReading(
        db,
        base + 151,
        SpotHrvContext.afterTraining,
        rmssd: 44.0 + d,
      );
    }
    await addActivity(db, 'ride', 0, 120);
    await addReading(db, -20, SpotHrvContext.beforeTraining, rmssd: 60);
    await addReading(db, 151, SpotHrvContext.afterTraining, rmssd: 45);
    await shoot(
      tester,
      'card-history',
      const WorkoutHrvCard(activityId: 'ride'),
    );
  });

  testWidgets('large text on a small phone', (tester) async {
    await addActivity(db, 'ride', 0, 120);
    await addReading(db, -20, SpotHrvContext.beforeTraining, rmssd: 60);
    await addReading(db, 151, SpotHrvContext.afterTraining, rmssd: 45);
    await shoot(
      tester,
      'card-large-text',
      const WorkoutHrvCard(activityId: 'ride'),
      width: 320,
      textScale: 1.6,
    );
  });

  testWidgets('pre only', (tester) async {
    await addActivity(db, 'ride', 0, 120);
    await addReading(db, -20, SpotHrvContext.beforeTraining, rmssd: 60);
    await shoot(tester, 'card-pre', const WorkoutHrvCard(activityId: 'ride'));
  });

  testWidgets('mismatch', (tester) async {
    await addActivity(db, 'ride', 0, 120);
    await addReading(db, -20, SpotHrvContext.beforeTraining, rmssd: 60);
    await addReading(
      db,
      151,
      SpotHrvContext.afterTraining,
      rmssd: 45,
      posture: SpotHrvPosture.supine,
    );
    await shoot(
      tester,
      'card-mismatch',
      const WorkoutHrvCard(activityId: 'ride'),
    );
  });

  testWidgets('empty', (tester) async {
    await addActivity(db, 'ride', 0, 120);
    await shoot(tester, 'card-empty', const WorkoutHrvCard(activityId: 'ride'));
  });

  testWidgets('tile', (tester) async {
    await shoot(tester, 'tile', const HrvReminderTile());
  });

  testWidgets('tile on', (tester) async {
    await db
        .into(db.hrvReminderPreferences)
        .insert(
          HrvReminderPreferencesCompanion.insert(
            installationEpoch: 'e',
            optedIn: const Value(true),
            updatedAtUtc: DateTime.utc(2026, 11, 2),
          ),
        );
    await shoot(tester, 'tile-on', const HrvReminderTile());
  });
}
