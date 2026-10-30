import 'dart:io';
import 'dart:ui' as ui;

import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/l10n/l10n_ext.dart';
import 'package:fjelia/providers/bio_age_provider.dart';
import 'package:fjelia/services/bio_age_activity.dart';
import 'package:fjelia/services/bio_age_service.dart';
import 'package:fjelia/theme/app_theme.dart';
import 'package:fjelia/widgets/app_widgets.dart';
import 'package:fjelia/widgets/bio_age_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _previewDir = String.fromEnvironment('FJELIA_UI_PREVIEW_DIR');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previewKey = GlobalKey();
  final today = DateTime(2026, 10, 30);

  setUpAll(() async {
    if (_previewDir.isEmpty) return;
    final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
    if (font.existsSync()) {
      final loader = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  tearDown(() => setActiveLocale(const Locale('en')));

  BioAgeResult fixture({bool estimated = true, bool complete = true}) {
    final activity = BioAgeActivity.fromDays([
      for (var i = 0; i < (complete ? 7 : 6); i++)
        BioAgeActivityDay(
          date: DateTime(today.year, today.month, today.day - i),
          reportedMinutes: i == 0
              ? 72
              : estimated
              ? null
              : 0,
          steps: 6000,
        ),
    ], today: today);
    return estimateBioAge(
      BioAgePerson(
        sex: 'm',
        age: 45,
        vo2max: 52,
        gripKg: 60,
        restingHr: 47,
        systolic: 126,
        visceralFat: 8,
        alcoholGramsPerWeek: 0,
        weeklyActivityMinutes: activity.reportedMinutes,
        activity: activity,
      ),
    );
  }

  Future<void> show(
    WidgetTester tester,
    BioAgeResult result, {
    Locale locale = const Locale('de'),
    bool expanded = true,
    double textScale = 1,
    Size size = const Size(393, 852),
  }) async {
    setActiveLocale(locale);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bioAgeProvider.overrideWith((ref) async => result)],
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: previewKey,
            child: Scaffold(
              body: SafeArea(
                child: Builder(
                  builder: (context) => SheetPage(
                    title: context.l10n.biologicalAge,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: BioAgeCard(expanded: expanded),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (_previewDir.isEmpty) return;
    await tester.runAsync(() async {
      final boundary =
          previewKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(_previewDir).create(recursive: true);
      await File(
        '$_previewDir/$name.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpAndSettle();
  }

  Finder approximateYears() => find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        (widget.data?.startsWith('≈ ') ?? false) &&
        (widget.data?.endsWith(' y') ?? false),
  );

  testWidgets('walking estimates are marked in the summary and factor', (
    tester,
  ) async {
    await show(tester, fixture());
    expect(find.text('Aktivität enthält geschätzte Gehzeit.'), findsOneWidget);
    expect(find.text('Bewegung'), findsOneWidget);
    expect(approximateYears(), findsOneWidget);
    await tester.ensureVisible(find.text('Bewegungsdaten · letzte 7 Tage'));
    await tester.pumpAndSettle();
    expect(find.text('72 gemeldete moderate Minuten'), findsOneWidget);
    expect(
      find.text('≈ 360 Gehminuten aus Schritten geschätzt'),
      findsOneWidget,
    );
    expect(find.text('Daten für 7 von 7 Tagen'), findsOneWidget);
    expect(
      find.textContaining(
        'die Schritte dieses Tages werden nicht zusätzlich gezählt',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await capture(tester, 'bio-age-activity-de');
  });

  testWidgets('a collapsed card still discloses estimated walking input', (
    tester,
  ) async {
    await show(tester, fixture(), expanded: false);
    expect(find.text('Aktivität enthält geschätzte Gehzeit.'), findsOneWidget);
    expect(find.text('Bewegungsdaten · letzte 7 Tage'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reported-only data is not presented as a step estimate', (
    tester,
  ) async {
    await show(tester, fixture(estimated: false));
    expect(find.text('Aktivität enthält geschätzte Gehzeit.'), findsNothing);
    expect(approximateYears(), findsNothing);
    expect(find.text('72 gemeldete moderate Minuten'), findsOneWidget);
    expect(
      find.textContaining('Gehminuten aus Schritten geschätzt'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'incomplete coverage explains why there is no activity contribution',
    (tester) async {
      await show(tester, fixture(complete: false));
      expect(find.text('Bewegungsdaten unvollständig'), findsOneWidget);
      expect(find.text('Bewegung'), findsNothing);
      expect(approximateYears(), findsNothing);
      await tester.ensureVisible(find.text('Daten für 6 von 7 Tagen'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('erst mit Daten für alle 7 Tage'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await capture(tester, 'bio-age-incomplete-de');
    },
  );

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('activity details fit larger text in ${locale.languageCode}', (
      tester,
    ) async {
      await show(
        tester,
        fixture(),
        locale: locale,
        textScale: 1.3,
        size: const Size(375, 667),
      );
      final l10n = lookupAppLocalizations(locale);
      await tester.ensureVisible(find.text(l10n.bioAgeActivityEstimateNotice));
      await tester.pumpAndSettle();
      expect(find.text(l10n.bioAgeActivityCoverage(7)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
