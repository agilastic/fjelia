import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:fjelia/widgets/activity_route_map.dart';

class _TestTiles extends TileProvider {
  @override
  ImageProvider getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) => MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGPYcunOfwAIAgNiJBgw5wAAAABJRU5ErkJggg==',
    ),
  );
}

void main() {
  testWidgets('map zoom, fit, fullscreen, attribution and GPX controls work', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    var exports = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: ActivityRouteMap(
              route: const [
                LatLng(39.74, 3.15),
                LatLng(39.78, 3.10),
                LatLng(39.77, 3.18),
              ],
              tileProvider: _TestTiles(),
              exportGpx: (_) async {
                exports++;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final controller = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!;
    final originalZoom = controller.camera.zoom;
    final center = controller.camera.center;
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    expect(controller.camera.zoom, closeTo(originalZoom + 1, .001));
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pumpAndSettle();
    expect(controller.camera.zoom, closeTo(originalZoom, .001));
    controller.move(const LatLng(39.0, 2.0), originalZoom + 2);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Fit route'));
    await tester.pumpAndSettle();
    expect(controller.camera.center.latitude, closeTo(center.latitude, .001));
    expect(controller.camera.center.longitude, closeTo(center.longitude, .001));
    expect(controller.camera.zoom, closeTo(originalZoom, .001));
    await tester.tap(find.text('GPX'));
    await tester.pumpAndSettle();
    expect(exports, 1);
    await tester.tap(find.byTooltip('Attributions'));
    await tester.pumpAndSettle();
    expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.cancel_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Fullscreen map'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((w) => w is ActivityRouteMap && w.fullscreen),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Zoom in').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((w) => w is ActivityRouteMap && w.fullscreen),
      findsNothing,
    );
    expect(find.byType(ActivityRouteMap), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('empty route has no enabled map or export controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityRouteMap(
            route: const [],
            tileProvider: _TestTiles(),
            exportGpx: (_) async {
              fail('An empty route cannot export');
            },
          ),
        ),
      ),
    );
    expect(find.text('No recorded route'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
  });
}
