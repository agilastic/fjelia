import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/activity_history_provider.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/providers/week_start_provider.dart';
import 'package:fjelia/screens/activities/load_history_cards.dart';
import 'package:fjelia/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    if (Platform.environment['FJELIA_UI_PREVIEW_DIR'] == null) return;
    final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
    await (FontLoader('Roboto')..addFont(
          Future.value(ByteData.sublistView(await font.readAsBytes())),
        ))
        .load();
  });
  testWidgets('zone history includes prior weeks and labels unavailable data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ActivityRecord a(String id, DateTime at, String? zones) => ActivityRecord(
      id: 0,
      activityId: id,
      name: id,
      type: 'running',
      startDate: at,
      durationSeconds: 3600,
      hrZonesJson: zones,
    );
    final key = GlobalKey();
    final ready = Completer<List<ActivityRecord>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 25)),
          weekStartsOnMondayProvider.overrideWithValue(true),
          loadActivitiesProvider.overrideWith((ref) => ready.future),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: RepaintBoundary(
                key: key,
                child: const Material(
                  child: LoadHistoryCards(polarization: true),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('No activities synced'), findsNothing);
    ready.complete([
      a('current', DateTime(2026, 10, 25), '{"zone2":90,"zone4":10}'),
      a('last', DateTime(2026, 10, 14), '{"zone2":70,"zone3":10,"zone4":20}'),
      a('missing', DateTime(2026, 10, 7), null),
    ]);
    await tester.pumpAndSettle();
    for (final label in ['W43', 'W42', 'W41', 'W32']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.text('No HR-zone data'), findsOneWidget);
    expect(find.text('No activities synced'), findsNWidgets(9));
    expect(find.text('2 of 3 activities with HR-zone data'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final output = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
    if (output != null) {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File(
          '$output/polarization.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
