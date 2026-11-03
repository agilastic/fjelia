import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/services/media_route.dart';
import 'package:fjelia/widgets/media_share_card.dart';

/// A straight 10 km line northwards, one point every 100 m.
final _route = [
  for (var i = 0; i <= 100; i++) (lat: 52.0 + i * 0.0009, lng: 9.7),
];
final _start = DateTime.utc(2026, 11, 2, 8);

void main() {
  group('mediaRoutePoint', () {
    test('a photo with its own location near the route stays there', () {
      final point = mediaRoutePoint(
        route: _route,
        start: _start,
        durationSeconds: 3600,
        latitude: 52.045,
        longitude: 9.701,
      );
      expect(point, (lat: 52.045, lng: 9.701));
    });

    test('a photo taken somewhere else is not pinned', () {
      expect(
        mediaRoutePoint(
          route: _route,
          start: _start,
          durationSeconds: 3600,
          latitude: 48.1,
          longitude: 11.5,
          // Its time would fit, but its place wins.
          takenAt: _start.add(const Duration(minutes: 30)),
        ),
        isNull,
      );
    });

    test('without a location, the time places it along the route', () {
      final point = mediaRoutePoint(
        route: _route,
        start: _start,
        durationSeconds: 3600,
        takenAt: _start.add(const Duration(minutes: 30)),
      );
      expect(point, _route[50]);
    });

    test('just after the finish counts, the next day does not', () {
      expect(
        mediaRoutePoint(
          route: _route,
          start: _start,
          durationSeconds: 3600,
          takenAt: _start.add(const Duration(minutes: 63)),
        ),
        _route.last,
      );
      expect(
        mediaRoutePoint(
          route: _route,
          start: _start,
          durationSeconds: 3600,
          takenAt: _start.add(const Duration(days: 1)),
        ),
        isNull,
      );
    });

    test('nothing to place without a route or any hint', () {
      expect(
        mediaRoutePoint(route: const [], start: _start, durationSeconds: 60),
        isNull,
      );
      expect(
        mediaRoutePoint(route: _route, start: _start, durationSeconds: 3600),
        isNull,
      );
    });
  });

  testWidgets('the share card shows the facts and draws the route', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('fjelia-card');
    addTearDown(() => dir.deleteSync(recursive: true));
    // A 1×1 PNG stands in for the photo.
    final photo = File('${dir.path}/p.png')
      ..writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4DwQACfsD/eNV8pwAAAAASUVORK5CYII=',
        ),
      );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Center(
          child: ShareCard(
            photo: photo,
            info: ActivityShareInfo(
              title: 'Morning run',
              date: _start,
              duration: const Duration(minutes: 38),
              distanceMeters: 7420,
              paceSecPerKm: 307,
              ascentMeters: 64,
              route: _route,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Morning run'), findsOneWidget);
    expect(find.text('7.42'), findsOneWidget);
    expect(find.text('KM'), findsOneWidget);
    expect(find.text('38:00'), findsOneWidget);
    expect(find.text('5:07'), findsOneWidget);
    expect(find.text('/KM'), findsOneWidget);
    expect(find.text('64 m'), findsOneWidget);
    // The signature: app icon, name and address.
    expect(find.text('Fjelia'), findsOneWidget);
    expect(find.textContaining('fjelia.com'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is RouteOutlinePainter,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
