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
  });

  /// The `Sport` attribute (Running, Biking, Other, …).
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
}

/// Parses the first `<Activity>` of a TCX document. Returns null when there is
/// no usable start time. Pure and tolerant: missing parts stay null/empty.
TcxSession? parseTcx(String xml, {String source = 'polar'}) {
  final activity = RegExp(
    r'<Activity\b([^>]*)>([\s\S]*?)</Activity>',
  ).firstMatch(xml);
  if (activity == null) return null;
  final sport =
      RegExp(r'Sport="([^"]*)"').firstMatch(activity.group(1)!)?.group(1) ??
      'Other';
  final body = activity.group(2)!;

  String? tag(String name, String within) => RegExp(
    '<$name>\\s*([^<]*?)\\s*</$name>',
  ).firstMatch(within)?.group(1);

  var start = DateTime.tryParse(tag('Id', body) ?? '');

  var seconds = 0.0, distance = 0.0, hasDistance = false;
  var calories = 0, hasCalories = false;
  double hrWeighted = 0, hrWeight = 0, maxHr = 0;
  final heartRates = <TimedHeartRate>[];
  final route = <Map<String, double>>[];

  for (final lap in RegExp(
    r'<Lap\b([^>]*)>([\s\S]*?)</Lap>',
  ).allMatches(body)) {
    final text = lap.group(2)!;
    start ??= DateTime.tryParse(
      RegExp(r'StartTime="([^"]*)"').firstMatch(lap.group(1)!)?.group(1) ?? '',
    );
    final t = double.tryParse(tag('TotalTimeSeconds', text) ?? '') ?? 0;
    seconds += t;
    final d = double.tryParse(tag('DistanceMeters', text) ?? '');
    if (d != null) {
      distance += d;
      hasDistance = true;
    }
    final c = int.tryParse(tag('Calories', text) ?? '');
    if (c != null) {
      calories += c;
      hasCalories = true;
    }
    final avg = double.tryParse(
      RegExp(
            r'<AverageHeartRateBpm>\s*<Value>\s*([\d.]+)',
          ).firstMatch(text)?.group(1) ??
          '',
    );
    if (avg != null && avg > 0 && t > 0) {
      hrWeighted += avg * t;
      hrWeight += t;
    }
    final max = double.tryParse(
      RegExp(
            r'<MaximumHeartRateBpm>\s*<Value>\s*([\d.]+)',
          ).firstMatch(text)?.group(1) ??
          '',
    );
    if (max != null && max > maxHr) maxHr = max;

    for (final p in RegExp(
      r'<Trackpoint>([\s\S]*?)</Trackpoint>',
    ).allMatches(text)) {
      final tp = p.group(1)!;
      final time = DateTime.tryParse(tag('Time', tp) ?? '');
      final hr = double.tryParse(
        RegExp(
              r'<HeartRateBpm>\s*<Value>\s*([\d.]+)',
            ).firstMatch(tp)?.group(1) ??
            '',
      );
      if (time != null && hr != null && hr > 0) {
        heartRates.add(TimedHeartRate(time, hr, source));
      }
      final lat = double.tryParse(tag('LatitudeDegrees', tp) ?? '');
      final lng = double.tryParse(tag('LongitudeDegrees', tp) ?? '');
      if (lat != null && lng != null) route.add({'lat': lat, 'lng': lng});
    }
  }
  if (start == null) return null;

  double? avgHr = hrWeight > 0 ? hrWeighted / hrWeight : null;
  if (heartRates.isNotEmpty) {
    avgHr ??=
        heartRates.fold<double>(0, (s, h) => s + h.bpm) / heartRates.length;
    final peak = heartRates.map((h) => h.bpm).reduce((a, b) => a > b ? a : b);
    if (peak > maxHr) maxHr = peak;
  }
  if (seconds <= 0 && heartRates.length > 1) {
    seconds = heartRates.last.timestamp
        .difference(heartRates.first.timestamp)
        .inSeconds
        .toDouble();
  }

  return TcxSession(
    sport: sport,
    start: start,
    durationSeconds: seconds.round(),
    distanceMeters: hasDistance && distance > 0 ? distance : null,
    calories: hasCalories ? calories : null,
    avgHeartRate: avgHr,
    maxHeartRate: maxHr > 0 ? maxHr : null,
    heartRates: heartRates,
    route: route,
  );
}
