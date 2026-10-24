import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/weather_radar_provider.dart';
import '../../providers/heat_acclimation_provider.dart';
import '../../widgets/app_widgets.dart';

class WeatherRadar extends ConsumerStatefulWidget {
  const WeatherRadar({super.key, this.fullscreen = false});
  final bool fullscreen;
  @override
  ConsumerState<WeatherRadar> createState() => _RadarState();
}

class _RadarState extends ConsumerState<WeatherRadar> {
  int? index;
  Timer? timer;
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(heatPreferredLocationProvider).valueOrNull;
    if (location == null) return const SizedBox.shrink();
    return ref
        .watch(weatherRadarProvider)
        .when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => TextButton.icon(
            onPressed: () => ref.invalidate(weatherRadarProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Radar unavailable · Retry'),
          ),
          data: (frames) {
            if (frames.isEmpty) {
              return const EmptyState('No radar frames available');
            }
            final selected = (index ?? frames.length - 1).clamp(
              0,
              frames.length - 1,
            );
            final point = LatLng(location.latitude, location.longitude);
            final map = ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 6,
                  minZoom: 2,
                  maxZoom: 7,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'de.ebeling-hoppe.fjelia',
                  ),
                  TileLayer(
                    key: ValueKey(frames[selected].tileUrl),
                    urlTemplate: frames[selected].tileUrl,
                    userAgentPackageName: 'de.ebeling-hoppe.fjelia',
                    maxNativeZoom: 7,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 16,
                        height: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.lightBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: widget.fullscreen
                      ? MediaQuery.sizeOf(context).height * .55
                      : 180,
                  child: Stack(
                    children: [
                      Positioned.fill(child: map),
                      if (!widget.fullscreen)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: FilledButton.icon(
                            onPressed: () => showAppSheet(
                              context,
                              const SheetPage(
                                title: 'Radar',
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: WeatherRadar(fullscreen: true),
                                  ),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.fullscreen),
                            label: const Text('Radar'),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: timer == null ? 'Play radar' : 'Pause radar',
                      onPressed: () {
                        if (timer != null) {
                          timer!.cancel();
                          setState(() => timer = null);
                        } else {
                          timer = Timer.periodic(
                            const Duration(milliseconds: 700),
                            (_) {
                              if (mounted) {
                                setState(
                                  () => index =
                                      ((index ?? frames.length - 1) + 1) %
                                      frames.length,
                                );
                              }
                            },
                          );
                          setState(() {});
                        }
                      },
                      icon: Icon(
                        timer == null ? Icons.play_arrow : Icons.pause,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(frames[selected].time),
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                    Expanded(
                      child: Slider(
                        value: selected.toDouble(),
                        max: (frames.length - 1).toDouble(),
                        divisions: frames.length > 1 ? frames.length - 1 : null,
                        onChanged: frames.length > 1
                            ? (v) => setState(() => index = v.round())
                            : null,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () =>
                          launchUrl(Uri.parse('https://www.rainviewer.com')),
                      child: const Text(
                        'Weather data by RainViewer',
                        style: TextStyle(fontSize: 9),
                      ),
                    ),
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                      ),
                      child: const Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
  }
}
