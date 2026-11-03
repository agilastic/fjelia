import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/widgets/media_share_card.dart';

void main() {
  late Directory dir;
  late File photo;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('fjelia-card-page');
    photo = File('${dir.path}/p.png')
      ..writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4DwQACfsD/eNV8pwAAAAASUVORK5CYII=',
        ),
      );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  final info = ActivityShareInfo(
    title: 'Morning run',
    date: DateTime(2026, 11, 2, 8),
    duration: const Duration(minutes: 38),
    distanceMeters: 7420,
    paceSecPerKm: 307,
    route: [for (var i = 0; i <= 50; i++) (lat: 52.0 + i * 0.001, lng: 9.7)],
  );

  Future<void> open(WidgetTester tester, {List<File> photos = const []}) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaShareCardPage(info: info, photos: photos),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
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
