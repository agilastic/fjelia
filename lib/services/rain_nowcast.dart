import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Rain from the DWD radar around one place, in 5-minute steps: measured
/// for the last hour, then DWD's own extrapolation for the next one or two
/// (RADOLAN RV, through Bright Sky). Germany only.
class RainNowcast {
  const RainNowcast(this.frames);

  /// Rain rate per 5-minute step, mm/h.
  final List<({DateTime time, double mmPerHour})> frames;

  /// From this rate on a step counts as rain: drizzle shows at about 0.1.
  static const wetFrom = 0.1;

  /// What is coming from [now] on.
  NowcastOutlook outlook(DateTime now) {
    final ahead = frames
        .where(
          (f) => !f.time.isBefore(now.subtract(const Duration(minutes: 5))),
        )
        .toList();
    if (ahead.isEmpty) return const NowcastUnknown();
    final horizon = ahead.last.time.difference(now);
    final wetNow = ahead.first.mmPerHour >= wetFrom;
    if (wetNow) {
      final dry = ahead.where((f) => f.mmPerHour < wetFrom).firstOrNull;
      return NowcastRaining(dry?.time.difference(now), horizon);
    }
    final wet = ahead.where((f) => f.mmPerHour >= wetFrom).firstOrNull;
    return wet == null
        ? NowcastDry(horizon)
        : NowcastRainSoon(wet.time.difference(now));
  }
}

sealed class NowcastOutlook {
  const NowcastOutlook();
}

class NowcastUnknown extends NowcastOutlook {
  const NowcastUnknown();
}

/// No rain within [horizon].
class NowcastDry extends NowcastOutlook {
  const NowcastDry(this.horizon);
  final Duration horizon;
}

/// Rain starts in [after].
class NowcastRainSoon extends NowcastOutlook {
  const NowcastRainSoon(this.after);
  final Duration after;
}

/// Raining now; dry again in [stopsIn], or not within [horizon] (null).
class NowcastRaining extends NowcastOutlook {
  const NowcastRaining(this.stopsIn, this.horizon);
  final Duration? stopsIn;
  final Duration horizon;
}

/// The radar cells within about 1 km of the place, the wettest one per step.
/// Bright Sky gives 0.01 mm per 5 minutes; ×0.12 makes mm/h.
RainNowcast? parseRadar(Map<String, dynamic> json) {
  final frames = json['radar'];
  final position = json['latlon_position'];
  if (frames is! List || position is! Map) return null;
  final x = (position['x'] as num?)?.round();
  final y = (position['y'] as num?)?.round();
  if (x == null || y == null) return null;
  final out = <({DateTime time, double mmPerHour})>[];
  for (final frame in frames.whereType<Map>()) {
    final time = DateTime.tryParse('${frame['timestamp']}');
    final grid = frame['precipitation_5'];
    if (time == null || grid is! List) continue;
    var wettest = 0.0;
    for (var row = y - 1; row <= y + 1; row++) {
      if (row < 0 || row >= grid.length || grid[row] is! List) continue;
      final cells = grid[row] as List;
      for (var col = x - 1; col <= x + 1; col++) {
        if (col < 0 || col >= cells.length) continue;
        final v = cells[col];
        if (v is num && v > wettest) wettest = v.toDouble();
      }
    }
    out.add((time: time.toLocal(), mmPerHour: wettest * .12));
  }
  out.sort((a, b) => a.time.compareTo(b.time));
  return out.isEmpty ? null : RainNowcast(out);
}

/// Fetches the radar around [latitude], [longitude] from Bright Sky.
Future<RainNowcast?> fetchRainNowcast(
  double latitude,
  double longitude, {
  http.Client? client,
}) async {
  // A connection timeout instead of a timer around the request: nothing is
  // left running when the screen showing the line goes away.
  final http_ =
      client ??
      IOClient(HttpClient()..connectionTimeout = const Duration(seconds: 10));
  try {
    final response = await http_.get(
      Uri.parse('https://api.brightsky.dev/radar').replace(
        queryParameters: {
          'lat': latitude.toStringAsFixed(4),
          'lon': longitude.toStringAsFixed(4),
          'distance': '3000',
          'format': 'plain',
        },
      ),
      // Bright Sky sends plain radar data only compressed.
      headers: {'Accept-Encoding': 'gzip'},
    );
    if (response.statusCode != 200) return null;
    return parseRadar(jsonDecode(response.body) as Map<String, dynamic>);
  } finally {
    if (client == null) http_.close();
  }
}

/// Inside the area the DWD radar covers.
bool inDwdRadarArea(double lat, double lng) =>
    lat >= 47.3 && lat <= 55.1 && lng >= 5.9 && lng <= 15.1;
