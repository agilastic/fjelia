import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/weather_radar_service.dart';

final weatherRadarServiceProvider = Provider((ref) {
  final service = WeatherRadarService();
  ref.onDispose(service.dispose);
  return service;
});
final weatherRadarProvider = FutureProvider<List<RadarFrame>>(
  (ref) => ref.watch(weatherRadarServiceProvider).fetch(),
);
