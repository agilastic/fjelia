import 'dart:math' as math;

import 'package:xml/xml.dart';

/// A recorded track read from a GPX file (Strava, Komoot, bike computers).
class GpxTrack {
  const GpxTrack({
    required this.start,
    required this.durationSeconds,
    this.name,
    this.type,
    this.distanceMeters,
    this.ascentMeters,
    this.samples = const [],
    this.route = const [],
  });

  final String? name, type;
  final DateTime start;
  final int durationSeconds;
  final double? distanceMeters, ascentMeters;

  /// Timestamped distance, altitude, HR, cadence and power, as in TCX/FIT.
  final List<Map<String, num>> samples;
  final List<Map<String, double>> route;
}

/// Parses the first track with timestamps. A planned route without times is
/// not a workout and returns null, as does malformed XML.
GpxTrack? parseGpx(String xml) {
  final XmlDocument document;
  try {
    document = XmlDocument.parse(xml);
  } on XmlException {
    return null;
  }
  Iterable<XmlElement> named(XmlNode node, String name) => node.descendants
      .whereType<XmlElement>()
      .where((e) => e.name.local == name);
  String? text(XmlElement parent, String name) => parent.childElements
      .where((e) => e.name.local == name)
      .firstOrNull
      ?.innerText
      .trim();

  final track = named(document, 'trk').firstOrNull;
  if (track == null) return null;
  final metadata = named(document, 'metadata').firstOrNull;
  final name =
      text(track, 'name') ?? (metadata == null ? null : text(metadata, 'name'));
  final samples = <Map<String, num>>[];
  final route = <Map<String, double>>[];
  var distance = 0.0, ascent = 0.0;
  double? lastLat, lastLng, lastEle;
  for (final point in named(track, 'trkpt')) {
    final lat = double.tryParse(point.getAttribute('lat') ?? '');
    final lng = double.tryParse(point.getAttribute('lon') ?? '');
    final time = DateTime.tryParse(text(point, 'time') ?? '');
    if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) {
      continue;
    }
    route.add({'lat': lat, 'lng': lng});
    if (lastLat != null && lastLng != null) {
      distance += _haversine(lastLat, lastLng, lat, lng);
    }
    lastLat = lat;
    lastLng = lng;
    final ele = double.tryParse(text(point, 'ele') ?? '');
    // GPS altitude jitters by a few metres; count a climb only once it
    // has risen 3 m above the last turning point.
    if (ele != null && ele.isFinite) {
      if (lastEle == null || lastEle - ele >= 3) {
        lastEle = ele;
      } else if (ele - lastEle >= 3) {
        ascent += ele - lastEle;
        lastEle = ele;
      }
    }
    if (time == null) continue;
    double? extension(List<String> names) {
      for (final e in named(
        point,
        'extensions',
      ).expand((x) => x.descendants.whereType<XmlElement>())) {
        if (!names.contains(e.name.local.toLowerCase())) continue;
        final value = double.tryParse(e.innerText.trim());
        if (value != null && value.isFinite && value >= 0) return value;
      }
      return null;
    }

    final hr = extension(['hr', 'heartrate']);
    samples.add({
      't': time.millisecondsSinceEpoch,
      'd': distance,
      if (ele != null && ele.isFinite) 'ele': ele,
      if (hr != null && hr > 0) 'hr': hr,
      'cad': ?extension(['cad', 'cadence']),
      'w': ?extension(['power', 'watts']),
    });
  }
  if (samples.length < 2) return null;
  samples.sort((a, b) => a['t']!.compareTo(b['t']!));
  final start = DateTime.fromMillisecondsSinceEpoch(
    samples.first['t']!.toInt(),
    isUtc: true,
  );
  final seconds = ((samples.last['t']! - samples.first['t']!) / 1000).round();
  if (seconds <= 0) return null;
  return GpxTrack(
    name: name == null || name.isEmpty ? null : name,
    type: text(track, 'type'),
    start: start,
    durationSeconds: seconds,
    distanceMeters: distance > 0 ? distance : null,
    ascentMeters: lastEle != null ? ascent : null,
    samples: samples,
    route: route,
  );
}

double _haversine(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}
