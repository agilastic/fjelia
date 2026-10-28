import 'package:fjelia/l10n/app_localizations.dart';

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/screens/activities/training_form_card.dart';
import 'package:fjelia/theme/app_theme.dart';

void main() {
  final selected = DateTime(2026, 11, 5);
  final boundary = GlobalKey();

  setUpAll(() async {
    if (Platform.environment['FJELIA_UI_PREVIEW_DIR'] == null) return;
    final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
    await (FontLoader('Roboto')..addFont(
          Future.value(ByteData.sublistView(await font.readAsBytes())),
        ))
        .load();
  });

  List<FormPoint> longHistory() => buildTrainingFormSeries(
    dailyLoads: {
      for (var i = 0; i <= 220; i++)
        DateTime(selected.year, selected.month, selected.day - 220 + i):
            i % 7 == 0 ? 0 : 80 + (i % 5) * 15.0,
    },
    through: selected,
  );

  Future<void> render(
    WidgetTester tester,
    Future<List<FormPoint>> Function() load, {
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedDateProvider.overrideWith((ref) => selected),
          trainingFormSeriesProvider.overrideWith((ref) => load()),
        ],
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.dark(),
            home: const Scaffold(
              body: SingleChildScrollView(child: TrainingFormCard()),
            ),
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  LineChartData chart(WidgetTester tester) =>
      tester.widget<LineChart>(find.byType(LineChart).first).data;

  Future<void> capture(WidgetTester tester, String name) async {
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

  testWidgets('defaults to 60 days warmed by earlier history', (tester) async {
    final history = longHistory();
    await render(tester, () async => history);
    final data = chart(tester);
    expect(data.minX, 0);
    expect(data.maxX, 59);
    expect(data.lineBarsData.first.spots, hasLength(60));
    expect(
      data.lineBarsData.first.spots.first.y,
      history[history.length - 60].ctl,
    );
    expect(data.lineBarsData.first.spots.last.y, history.last.ctl);
    expect(data.lineBarsData[1].spots.last.y, history.last.atl);
    expect(find.text('05/11'), findsOneWidget);
    expect(find.textContaining('History since'), findsOneWidget);
    expect(find.textContaining('building baseline'), findsNothing);
    expect(tester.takeException(), isNull);
    await capture(tester, 'training-form-60d');
  });

  testWidgets(
    'changing the visible window leaves calculated values unchanged',
    (tester) async {
      final history = longHistory();
      await render(tester, () async => history);
      for (final days in [14, 30, 60]) {
        await tester.tap(find.text('${days}d'));
        await tester.pumpAndSettle();
        final data = chart(tester);
        expect(data.maxX, days - 1);
        expect(data.lineBarsData.first.spots, hasLength(days));
        expect(data.lineBarsData.first.spots.last.y, history.last.ctl);
        expect(data.lineBarsData[1].spots.last.y, history.last.atl);
      }
    },
  );

  testWidgets(
    'short history keeps the full window without earlier fake zeros',
    (tester) async {
      final history = buildTrainingFormSeries(
        dailyLoads: {DateTime(2026, 11, 3): 100},
        through: selected,
      );
      await render(tester, () async => history);
      final data = chart(tester);
      expect(data.maxX, 59);
      expect(data.lineBarsData.first.spots.map((p) => p.x), [57, 58, 59]);
      expect(find.textContaining('building baseline'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'training-form-short');
    },
  );

  testWidgets('a single recorded day is visible as dots', (tester) async {
    await render(
      tester,
      () async => buildTrainingFormSeries(
        dailyLoads: {selected: 100},
        through: selected,
      ),
    );
    for (final line in chart(tester).lineBarsData) {
      expect(line.spots, hasLength(1));
      expect(line.spots.single.x, 59);
      expect(line.dotData.show, isTrue);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty history does not render a synthetic zero series', (
    tester,
  ) async {
    await render(tester, () async => []);
    expect(find.text('No training history'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets(
    'loading, failure and retry stay distinct from an empty history',
    (tester) async {
      final pending = Completer<List<FormPoint>>();
      var attempts = 0;
      await render(
        tester,
        () => ++attempts == 1 ? pending.future : Future.value(longHistory()),
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No training history'), findsNothing);
      pending.completeError(StateError('History unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load data'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.byType(LineChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('expanded graph inherits the selected display window', (
    tester,
  ) async {
    await render(tester, () async => longHistory());
    await tester.tap(find.text('14d'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Expand training form'));
    await tester.pumpAndSettle();
    final expanded = find.byWidgetPredicate(
      (w) => w is TrainingFormCard && w.fullscreen,
    );
    expect(expanded, findsOneWidget);
    expect(tester.widget<TrainingFormCard>(expanded).initialDays, 14);
    final data = tester
        .widget<LineChart>(
          find.descendant(of: expanded, matching: find.byType(LineChart)),
        )
        .data;
    expect(data.maxX, 13);
    expect(tester.takeException(), isNull);
    await capture(tester, 'training-form-expanded');
  });
}
