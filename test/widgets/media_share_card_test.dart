import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/widgets/media_share_card.dart';

void main() {
  late Directory dir;
  late File photo;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dir = Directory.systemTemp.createTempSync('fjelia-card-page');
    photo = File('${dir.path}/p.png')
      ..writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4DwQACfsD/eNV8pwAAAAASUVORK5CYII=',
        ),
      );
  });
  tearDown(() => dir.deleteSync(recursive: true));
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

  final info = ActivityShareInfo(
    title: 'Morning run',
    date: DateTime(2026, 11, 2, 8),
    duration: const Duration(minutes: 38),
    distanceMeters: 7420,
    paceSecPerKm: 307,
    route: [for (var i = 0; i <= 50; i++) (lat: 52.0 + i * 0.001, lng: 9.7)],
  );

  final rowing = ActivityShareInfo(
    title: 'Indoor Rowing',
    date: DateTime(2026, 11, 9, 18),
    duration: const Duration(minutes: 32, seconds: 18),
    distanceMeters: 7500,
    watts: 210,
    avgHeartRate: 146,
    sport: 'rowing',
    indoor: true,
  );
  final skiErg = ActivityShareInfo(
    title: 'SkiErg',
    date: DateTime(2026, 11, 9, 18),
    duration: const Duration(minutes: 24, seconds: 15),
    distanceMeters: 5000,
    watts: 198,
    avgHeartRate: 151,
    sport: 'nordic_skiing',
    indoor: true,
  );

  Future<void> waitForImages(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
  }

  Future<void> open(
    WidgetTester tester, {
    List<File> photos = const [],
    ActivityShareInfo? activity,
    int? initialPhoto,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaShareCardPage(
          info: activity ?? info,
          photos: photos,
          initialPhoto: initialPhoto,
        ),
      ),
    );
    await waitForImages(tester);
  }

  Future<void> exportPreview(WidgetTester tester, String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find
          .ancestor(
            of: find.byType(ShareCard),
            matching: find.byType(RepaintBoundary),
          )
          .first,
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      expect(image.width, 1080);
      expect(image.height, 1350);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      expect(png, isNotNull);
      final output = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
      if (output != null) {
        await Directory(output).create(recursive: true);
        await File('$output/$name.png').writeAsBytes(png!.buffer.asUint8List());
      }
    });
  }

  testWidgets('indoor rowing defaults to the gym photo and can remove it', (
    tester,
  ) async {
    await open(tester, activity: rowing, photos: [photo]);
    ShareCard card() => tester.widget<ShareCard>(find.byType(ShareCard));
    expect(card().backgroundImage, rowingGymShareBackground);
    expect(card().photo, isNull);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await exportPreview(tester, 'rowing-share-gym');

    await tester.tap(find.text('Without photo'));
    await waitForImages(tester);
    expect(card().backgroundImage, isNull);
    expect(card().photo, isNull);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Gym photo'));
    await waitForImages(tester);
    expect(card().backgroundImage, rowingGymShareBackground);

    // Personal photos remain available alongside the supplied background.
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is ResizeImage,
      ),
    );
    await waitForImages(tester);
    expect(card().photo, photo);
    expect(card().backgroundImage, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an explicitly chosen activity photo overrides the gym default', (
    tester,
  ) async {
    await open(tester, activity: rowing, photos: [photo], initialPhoto: 0);
    final card = tester.widget<ShareCard>(find.byType(ShareCard));
    expect(card.photo, photo);
    expect(card.backgroundImage, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SkiErg uses its own optional gym photo and exports it', (
    tester,
  ) async {
    await open(tester, activity: skiErg, photos: [photo]);
    ShareCard card() => tester.widget<ShareCard>(find.byType(ShareCard));
    expect(card().backgroundImage, skiErgGymShareBackground);
    expect(card().photo, isNull);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await exportPreview(tester, 'skierg-share-gym');

    await tester.tap(find.text('Without photo'));
    await waitForImages(tester);
    expect(card().backgroundImage, isNull);

    await tester.tap(find.text('Gym photo'));
    await waitForImages(tester);
    expect(card().backgroundImage, skiErgGymShareBackground);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is ResizeImage,
      ),
    );
    await waitForImages(tester);
    expect(card().photo, photo);
    expect(card().backgroundImage, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('outdoor Nordic skiing keeps its route background', (
    tester,
  ) async {
    await open(
      tester,
      activity: ActivityShareInfo(
        title: 'Nordic skiing',
        date: info.date,
        duration: info.duration,
        sport: 'nordic_skiing',
        route: info.route,
      ),
    );
    expect(find.text('Gym photo'), findsNothing);
    expect(
      tester.widget<ShareCard>(find.byType(ShareCard)).backgroundImage,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('SkiErg also exports its photo in full-art Holo style', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'share_card_style': 'holoFull'});
    await open(tester, activity: skiErg);
    expect(
      tester.widget<ShareCard>(find.byType(ShareCard)).backgroundImage,
      skiErgGymShareBackground,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await exportPreview(tester, 'skierg-share-holoFull');
    expect(tester.takeException(), isNull);
  });

  testWidgets('outdoor rowing keeps its route background', (tester) async {
    await open(
      tester,
      activity: ActivityShareInfo(
        title: 'Rowing on the lake',
        date: info.date,
        duration: info.duration,
        sport: 'rowing',
        route: info.route,
      ),
    );
    expect(find.text('Gym photo'), findsNothing);
    expect(
      tester.widget<ShareCard>(find.byType(ShareCard)).backgroundImage,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  for (final style in [ShareCardStyle.holo, ShareCardStyle.holoFull]) {
    testWidgets('${style.name} exports the bundled gym photo', (tester) async {
      SharedPreferences.setMockInitialValues({'share_card_style': style.name});
      await open(tester, activity: rowing);
      expect(tester.widget<ShareCard>(find.byType(ShareCard)).style, style);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await exportPreview(tester, 'rowing-share-${style.name}');
      expect(tester.takeException(), isNull);
    });
  }

  Finder routeTile() => find.byWidgetPredicate(
    (w) =>
        w is CustomPaint &&
        w.painter is RouteOutlinePainter &&
        (w.painter! as RouteOutlinePainter).thickness == 1,
  );

  testWidgets('the panel and the route tile can be dragged', (tester) async {
    await open(tester, photos: [photo]);
    final panelBefore = tester.getCenter(find.text('Fjelia'));
    await tester.drag(find.text('Fjelia'), const Offset(0, -500));
    await tester.pump();
    final panelAfter = tester.getCenter(find.text('Fjelia'));
    expect(panelAfter.dy, lessThan(panelBefore.dy - 100));

    final tileBefore = tester.getCenter(routeTile());
    await tester.drag(routeTile(), const Offset(-400, 0));
    await tester.pump();
    expect(tester.getCenter(routeTile()).dx, lessThan(tileBefore.dx - 100));
    expect(tester.takeException(), isNull);
    // Lets the double-tap detector's timer run out.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('without photos the route is the picture', (tester) async {
    await open(tester);
    // Drawn large, no small tile.
    expect(routeTile(), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter is RouteOutlinePainter &&
            (w.painter! as RouteOutlinePainter).thickness > 1,
      ),
      findsOneWidget,
    );
    expect(find.textContaining('fjelia.com'), findsOneWidget);
  });

  for (final style in ShareCardStyle.values) {
    for (final withPhoto in [true, false]) {
      testWidgets(
        '${style.name} renders ${withPhoto ? 'on a photo' : 'on the route'}',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(400, 500));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Center(
                child: ShareCard(
                  info: info,
                  photo: withPhoto ? photo : null,
                  style: style,
                  panelY: -1,
                  tileAlignment: Alignment.bottomLeft,
                ),
              ),
            ),
          );
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          // Every style carries the address.
          expect(find.textContaining('fjelia.com'), findsOneWidget);
        },
      );
    }
  }

  testWidgets('the style chips switch the look', (tester) async {
    await open(tester, photos: [photo]);
    expect(find.textContaining('FJELIA'), findsNothing);
    // The last chip may lie beyond the screen edge.
    await tester.dragUntilVisible(
      find.text('Receipt'),
      find
          .byWidgetPredicate(
            (w) => w is ListView && w.scrollDirection == Axis.horizontal,
          )
          .first,
      const Offset(-120, 0),
    );
    await tester.ensureVisible(find.text('Receipt'));
    await tester.pump();
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    expect(find.text('FJELIA'), findsOneWidget);
  });

  testWidgets('the photo zooms with two fingers, moves, and resets', (
    tester,
  ) async {
    await open(tester, photos: [photo]);
    ShareCard card() => tester.widget<ShareCard>(find.byType(ShareCard));
    // Pinch on the photo, away from the panel at the bottom.
    final center =
        tester.getTopLeft(find.byType(ShareCard)) + const Offset(150, 80);
    final a = await tester.startGesture(center - const Offset(20, 0));
    final b = await tester.startGesture(
      center + const Offset(20, 0),
      pointer: 2,
    );
    await tester.pump();
    for (var i = 1; i <= 5; i++) {
      await a.moveTo(center - Offset(20.0 + i * 12, 0));
      await b.moveTo(center + Offset(20.0 + i * 12, 0));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pump();
    expect(card().photoZoom, greaterThan(1.5));

    // Zoomed in, a drag on the photo moves it.
    await tester.dragFrom(center, const Offset(60, 0));
    await tester.pump();
    expect(card().photoPan.dx, greaterThan(0));

    // A double tap frames it as it came.
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(card().photoZoom, 1);
    expect(card().photoPan, Offset.zero);
  });
}
