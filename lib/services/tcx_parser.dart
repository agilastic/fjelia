import 'package:xml/xml.dart';

import '../models/heart_rate.dart';

/// A training session read from a TCX export (Polar Flow, and others).
class TcxSession {
  const TcxSession({
    required this.sport,
    required this.start,
    required this.durationSeconds,
    this.distanceMeters,
    this.calories,
    this.avgHeartRate,
    this.maxHeartRate,
    this.heartRates = const [],
    this.route = const [],
    this.samples = const [],
  });

  final String sport;
  final DateTime start;
  final int durationSeconds;
  final double? distanceMeters;
  final int? calories;
  final double? avgHeartRate;
  final double? maxHeartRate;
  final List<TimedHeartRate> heartRates;

  /// `{lat, lng}` points of the recorded route.
  final List<Map<String, double>> route;

  /// Observed, timestamped distance, HR, speed (m/s), altitude and power.
  /// Unknown fields are omitted rather than replaced with zero.
  final List<Map<String, num>> samples;
}

XmlElement? _child(XmlElement parent, String name) => parent.childElements
    .where((element) => element.name.local == name)
    .firstOrNull;

String? _text(XmlElement parent, String name) =>
    _child(parent, name)?.innerText.trim();

double? _number(String? text, {bool nonnegative = true}) {
  final value = double.tryParse(text ?? '');
  return value != null && value.isFinite && (!nonnegative || value >= 0)
      ? value
      : null;
}

/// Parses the first Activity, including namespace-prefixed elements and
/// trackpoints with attributes (which Polar uses on almost every point).
/// Missing observations stay null/empty; malformed XML is ignored safely.
TcxSession? parseTcx(String xml, {String source = 'polar'}) {
  final XmlDocument document;
  try {
    document = XmlDocument.parse(xml);
  } on XmlException {
    return null;
  }
  final activity = document.descendants
      .whereType<XmlElement>()
      .where((element) => element.name.local == 'Activity')
      .firstOrNull;
  if (activity == null) return null;
  var start = DateTime.tryParse(_text(activity, 'Id') ?? '');
  var seconds = 0.0, distance = 0.0, hasDistance = false;
  var calories = 0, hasCalories = false;
  var hrWeighted = 0.0, hrWeight = 0.0, maxHr = 0.0;
  final route = <Map<String, double>>[];
  final timed = <int, Map<String, num>>{};

  for (final lap in activity.childElements.where(
    (element) => element.name.local == 'Lap',
  )) {
    start ??= DateTime.tryParse(lap.getAttribute('StartTime') ?? '');
    final duration = _number(_text(lap, 'TotalTimeSeconds')) ?? 0;
    seconds += duration;
    final lapDistance = _number(_text(lap, 'DistanceMeters'));
    if (lapDistance != null) {
      distance += lapDistance;
      hasDistance = true;
    }
    final lapCalories = _number(_text(lap, 'Calories'));
    if (lapCalories != null) {
      calories += lapCalories.round();
      hasCalories = true;
    }
    double? hr(String name, XmlElement parent) {
      final container = _child(parent, name);
      return container == null ? null : _number(_text(container, 'Value'));
    }

    final avg = hr('AverageHeartRateBpm', lap);
    if (avg != null && avg > 0 && duration > 0) {
      hrWeighted += avg * duration;
      hrWeight += duration;
    }
    final max = hr('MaximumHeartRateBpm', lap);
    if (max != null && max > maxHr) maxHr = max;

    for (final tp in lap.descendants.whereType<XmlElement>().where(
      (element) => element.name.local == 'Trackpoint',
    )) {
      final position = _child(tp, 'Position');
      final lat = position == null
          ? null
          : _number(_text(position, 'LatitudeDegrees'), nonnegative: false);
      final lng = position == null
          ? null
          : _number(_text(position, 'LongitudeDegrees'), nonnegative: false);
      if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) {
        route.add({'lat': lat, 'lng': lng});
      }
      final time = DateTime.tryParse(_text(tp, 'Time') ?? '');
      if (time == null) continue;
      final extensions = _child(tp, 'Extensions');
      double? extension(String name) => _number(
        extensions?.descendants
            .whereType<XmlElement>()
            .where((element) => element.name.local == name)
            .firstOrNull
            ?.innerText
            .trim(),
      );
      final bpm = hr('HeartRateBpm', tp);
      final cadence = extension('RunCadence') ?? _number(_text(tp, 'Cadence'));
      final sample = <String, num>{
        't': time.millisecondsSinceEpoch,
        'd': ?_number(_text(tp, 'DistanceMeters')),
        'spd': ?extension('Speed'),
        'ele': ?_number(_text(tp, 'AltitudeMeters'), nonnegative: false),
        if (bpm != null && bpm > 0) 'hr': bpm,
        'w': ?extension('Watts'),
        'cad': ?cadence,
      };
      // Some files repeat a boundary point in adjacent laps. Merge observed
      // fields at that timestamp without losing complementary measurements.
      timed.update(
        time.millisecondsSinceEpoch,
        (previous) => {...previous, ...sample},
        ifAbsent: () => sample,
      );
    }
  }
  final samples = timed.values.toList()
    ..sort((a, b) => a['t']!.compareTo(b['t']!));
  final heartRates = [
    for (final sample in samples)
      if (sample['hr'] != null)
        TimedHeartRate(
          DateTime.fromMillisecondsSinceEpoch(
            sample['t']!.toInt(),
            isUtc: true,
          ),
          sample['hr']!.toDouble(),
          source,
        ),
  ];
  double? avgHr = hrWeight > 0 ? hrWeighted / hrWeight : null;
  if (heartRates.isNotEmpty) {
    avgHr ??=
        heartRates.fold<double>(0, (sum, hr) => sum + hr.bpm) /
        heartRates.length;
    for (final hr in heartRates) {
      if (hr.bpm > maxHr) maxHr = hr.bpm;
    }
  }
  if (samples.isNotEmpty) {
    start ??= DateTime.fromMillisecondsSinceEpoch(
      samples.first['t']!.toInt(),
      isUtc: true,
    );
    if (seconds <= 0 && samples.length > 1) {
      seconds = (samples.last['t']! - samples.first['t']!) / 1000;
    }
  }
  if (start == null) return null;
  return TcxSession(
    sport: activity.getAttribute('Sport') ?? 'Other',
    start: start,
    durationSeconds: seconds.round(),
    distanceMeters: hasDistance ? distance : null,
    calories: hasCalories ? calories : null,
    avgHeartRate: avgHr,
    maxHeartRate: maxHr > 0 ? maxHr : null,
    heartRates: heartRates,
    route: route,
    samples: samples,
  );
}
