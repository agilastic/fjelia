import 'package:fjelia/l10n/app_localizations.dart';

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/providers/fjelia_edition_provider.dart';
import 'package:fjelia/providers/hr_zone_trends_provider.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/providers/week_start_provider.dart';
import 'package:fjelia/screens/activities/load_history_cards.dart';
import 'package:fjelia/theme/app_theme.dart';

class _Free implements FjeliaEdition {
  @override
  final bool isPro = false, proOffered = false;
}

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
    // Minutes in Z1–Z5 from the kept summaries; none: no heart rate.
    HrZoneWorkout a(String id, DateTime at, List<double> minutes) =>
        HrZoneWorkout(
          activityId: id,
          sport: 'running',
          start: at,
          elapsedSeconds: 3600,
          coveredSeconds: minutes.fold(0.0, (x, y) => x + y) * 60,
          zoneSeconds: [for (final m in minutes) m * 60],
          definitionId: 1,
        );
    final key = GlobalKey();
    final ready = Completer<List<HrZoneWorkout>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 25)),
          weekStartsOnMondayProvider.overrideWithValue(true),
          hrZoneWorkoutsProvider.overrideWith((ref) => ready.future),
          fjeliaEditionProvider.overrideWithValue(_Free()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
      a('current', DateTime(2026, 10, 25), [0, 54, 0, 6, 0]),
      a('last', DateTime(2026, 10, 14), [0, 42, 6, 12, 0]),
      a('missing', DateTime(2026, 10, 7), [0, 0, 0, 0, 0]),
      a('older', DateTime(2026, 8, 26), [0, 60, 0, 0, 0]),
    ]);
    await tester.pumpAndSettle();
    for (final label in ['W43', 'W42', 'W41', 'W40', 'W39']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('5-WEEK HISTORY'), findsOneWidget);
    expect(find.text('W38'), findsNothing);
    expect(find.text('W32'), findsNothing);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.text('No HR-zone data'), findsOneWidget);
    expect(find.text('No activities synced'), findsNWidgets(2));
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
