import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/models/chart_point.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/providers/metric_history_provider.dart';
import 'package:fjelia/screens/strain/activity_detail_sheet.dart';
import 'package:fjelia/theme/fjelia_style.dart';
import 'package:fjelia/widgets/metric_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> frames(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

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
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    Fjelia.style = FjeliaStyle.dark;
    await db.close();
  });

  Widget app(
    Widget child, {
    bool light = false,
    List<Override> overrides = const [],
  }) {
    Fjelia.style = light ? FjeliaStyle.light : FjeliaStyle.dark;
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db), ...overrides],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: light ? ThemeData.light() : ThemeData.dark(),
        home: Scaffold(
          backgroundColor: fjBackground,
          body: RepaintBoundary(
            key: const ValueKey('preview'),
            child: ColoredBox(color: fjBackground, child: child),
          ),
        ),
      ),
    );
  }

  Future<void> preview(WidgetTester tester, String name) async {
    final output = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
    if (output == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  /// Drift closes a query stream on a zero timer; let it run.
  Future<void> closeStreams(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final light in [false, true]) {
    final look = light ? 'light' : 'dark';
    testWidgets('an empty reflection offers chips; one tap saves it ($look)', (
      tester,
    ) async {
      phone(tester);
      await tester.runAsync(
        () => db
            .into(db.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: 'a',
                name: 'Pool Swim',
                type: 'lap_swimming',
                startDate: DateTime(2026, 11, 11, 17),
                durationSeconds: 1860,
              ),
            ),
      );
      await tester.pumpWidget(
        app(
          const Padding(
            padding: EdgeInsets.all(16),
            child: ActivityNoteCard(activityId: 'a'),
          ),
          light: light,
        ),
      );
      await frames(tester);
      expect(find.text('REFLECTION'), findsOneWidget);
      expect(
        find.text('How did it go? A few words help the coach.'),
        findsOneWidget,
      );
      await preview(tester, 'reflection_empty_$look');
      await tester.tap(find.text('Heavy legs'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await frames(tester);
      final saved = await tester.runAsync(() => db.getActivityById('a'));
      expect(saved!.athleteNote, 'Heavy legs');
      expect(find.text('Heavy legs'), findsOneWidget);
      expect(find.text('Too hot'), findsNothing);
      await closeStreams(tester);
    });

    testWidgets('a night without HRV says so and names the last reading '
        '($look)', (tester) async {
      phone(tester);
      await tester.pumpWidget(
        app(
          const MetricDetailSheet(metric: HealthMetric.hrv),
          light: light,
          overrides: [
            selectedDateProvider.overrideWith((_) => DateTime(2026, 11, 11)),
            metricHistoryProvider(HealthMetric.hrv).overrideWith(
              (_) async => [
                ChartPoint(DateTime(2026, 11, 8), 55),
                ChartPoint(DateTime(2026, 11, 9), 52),
              ],
            ),
          ],
        ),
      );
      await frames(tester);
      expect(find.byKey(const ValueKey('data-gap')), findsOneWidget);
      expect(find.text('No reading for 11 Nov 2026'), findsOneWidget);
      expect(find.text('Last reading: 52 ms on 9 Nov 2026.'), findsOneWidget);
      // The headline is the selected night's, not the older reading.
      expect(find.text('— ms'), findsOneWidget);
      await preview(tester, 'hrv_gap_$look');
      await closeStreams(tester);
    });
  }

  testWidgets('a night with HRV shows it and no gap', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      app(
        const MetricDetailSheet(metric: HealthMetric.hrv),
        overrides: [
          selectedDateProvider.overrideWith((_) => DateTime(2026, 11, 9)),
          metricHistoryProvider(HealthMetric.hrv).overrideWith(
            (_) async => [ChartPoint(DateTime(2026, 11, 9), 52)],
          ),
        ],
      ),
    );
    await frames(tester);
    expect(find.byKey(const ValueKey('data-gap')), findsNothing);
    expect(find.text('52 ms'), findsOneWidget);
    await closeStreams(tester);
  });

  testWidgets('an older weight is no gap: weigh-ins are occasional', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      app(
        const MetricDetailSheet(metric: HealthMetric.weight),
        overrides: [
          selectedDateProvider.overrideWith((_) => DateTime(2026, 11, 11)),
          metricHistoryProvider(HealthMetric.weight).overrideWith(
            (_) async => [ChartPoint(DateTime(2026, 11, 2), 72.4)],
          ),
        ],
      ),
    );
    await frames(tester);
    expect(find.byKey(const ValueKey('data-gap')), findsNothing);
    expect(find.textContaining('72.4'), findsWidgets);
    await closeStreams(tester);
  });
}
