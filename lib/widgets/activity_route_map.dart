import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'app_widgets.dart';

class ActivityRouteMap extends StatefulWidget {
  const ActivityRouteMap({
    super.key,
    required this.route,
    required this.exportGpx,
    this.fullscreen = false,
    this.tileProvider,
  });
  final List<LatLng> route;
  final Future<void> Function(BuildContext) exportGpx;
  final bool fullscreen;
  final TileProvider? tileProvider;
  @override
  State<ActivityRouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<ActivityRouteMap> {
  final controller = MapController();
  bool ready = false;
  List<LatLng> get points => widget.route
      .where(
        (p) =>
            p.latitude.isFinite &&
            p.longitude.isFinite &&
            p.latitude.abs() <= 90 &&
            p.longitude.abs() <= 180,
      )
      .toList();
  CameraFit get fit => CameraFit.bounds(
    bounds: LatLngBounds.fromPoints(points),
    padding: const EdgeInsets.all(32),
    maxZoom: 17,
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = points;
    if (route.isEmpty) return const EmptyState('No recorded route');
    Widget button(String label, IconData icon, VoidCallback action) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: const Color(0xE6202020),
        borderRadius: BorderRadius.circular(8),
        child: IconButton(
          tooltip: label,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          padding: EdgeInsets.zero,
          onPressed: ready ? action : null,
          icon: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
    final map = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCameraFit: route.length > 1 ? fit : null,
          initialCenter: route.first,
          initialZoom: 13,
          minZoom: 2,
          maxZoom: 19,
          onMapReady: () {
            if (mounted) setState(() => ready = true);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'de.ebeling-hoppe.fjelia',
            tileProvider: widget.tileProvider,
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: route,
                color: const Color(0xFF4FC3F7),
                strokeWidth: 4,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              for (final e in [
                (route.first, mint),
                (route.last, Colors.redAccent),
              ])
                Marker(
                  point: e.$1,
                  width: 16,
                  height: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: e.$2,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Column(
              children: [
                button(
                  'Zoom in',
                  Icons.add,
                  () => controller.move(
                    controller.camera.center,
                    (controller.camera.zoom + 1).clamp(2, 19),
                  ),
                ),
                button(
                  'Zoom out',
                  Icons.remove,
                  () => controller.move(
                    controller.camera.center,
                    (controller.camera.zoom - 1).clamp(2, 19),
                  ),
                ),
                button('Fit route', Icons.fit_screen, () {
                  controller.rotate(0);
                  if (route.length > 1) {
                    controller.fitCamera(fit);
                  } else {
                    controller.move(route.first, 13);
                  }
                }),
                if (!widget.fullscreen)
                  button(
                    'Fullscreen map',
                    Icons.fullscreen,
                    () => showAppSheet(
                      context,
                      SheetPage(
                        title: 'Route',
                        showBack: false,
                        backgroundColor: panel,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: ActivityRouteMap(
                            route: route,
                            exportGpx: widget.exportGpx,
                            fullscreen: true,
                            tileProvider: widget.tileProvider,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
        ],
      ),
    );
    return Column(
      mainAxisSize: widget.fullscreen ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (widget.fullscreen)
          Expanded(child: map)
        else
          SizedBox(height: 240, child: map),
        Row(
          children: [
            const Icon(Icons.circle, size: 10, color: mint),
            const SizedBox(width: 5),
            const Text(
              'Start',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.circle, size: 10, color: Colors.redAccent),
            const SizedBox(width: 5),
            const Expanded(
              child: Text(
                'Finish',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ),
            Builder(
              builder: (buttonContext) => TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  backgroundColor: Colors.white.withValues(alpha: .04),
                ),
                icon: const Icon(Icons.download, size: 15),
                label: const Text('GPX'),
                onPressed: () => runUiAction(
                  buttonContext,
                  () => widget.exportGpx(buttonContext),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
