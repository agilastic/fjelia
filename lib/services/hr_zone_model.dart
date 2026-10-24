import 'dart:convert';

/// Heart-rate zones as five lower bounds (floors) of zones 1–5, the format
/// Garmin uses and the app stores everywhere.

/// %LTHR zone floors (Friel). Running: Z2 85 %, Z3 90 %, Z4 95 %, Z5 100 %.
/// Cycling: Z2 81 %, Z3 90 %, Z4 94 %, Z5 100 %.
List<int> lthrZoneFloors(int lthr, {bool cycling = false}) {
  final fractions = cycling
      ? const [0.60, 0.81, 0.90, 0.94, 1.00]
      : const [0.65, 0.85, 0.90, 0.95, 1.00];
  return [for (final f in fractions) (lthr * f).round()];
}

/// Moves an existing zone scheme to a new threshold, keeping its
/// percentages (e.g. the athlete's Garmin %LTHR setup).
List<int> scaleZoneFloors(List<int> floors, {required int from, required int to}) =>
    [for (final f in floors) (f * to / from).round()];

/// Upper bounds of zones 1–4, as the planner's HR targets expect. Accepts
/// five floors or (legacy) four upper bounds.
List<int> zoneUpperBounds(List<int> zones) =>
    zones.length >= 5 ? zones.sublist(1, 5) : zones;

/// Zone index 1–5 for [bpm] given five [floors].
int zoneOf(double bpm, List<int> floors) {
  for (var z = floors.length; z >= 2; z--) {
    if (bpm >= floors[z - 1]) return z;
  }
  return 1;
}

/// Time-in-zone percentages (`zone1`…`zone5`) from an activity's samples
/// (`metricsJson`: `[{hr, t?}, …]`), time-weighted when samples carry
/// timestamps. Null when there are too few HR samples.
Map<String, double>? zonePercentFromSamples(
  String? metricsJson,
  List<int> floors,
) {
  if (metricsJson == null || floors.length < 5) return null;
  List<dynamic> samples;
  try {
    final decoded = jsonDecode(metricsJson);
    if (decoded is! List) return null;
    samples = decoded;
  } catch (_) {
    return null;
  }
  final seconds = List<double>.filled(5, 0);
  int? lastT;
  var counted = 0;
  for (final s in samples) {
    if (s is! Map) continue;
    final hr = (s['hr'] as num?)?.toDouble();
    final t = (s['t'] as num?)?.toInt();
    // Weight by the gap to the previous sample (capped at 30 s for pauses).
    final weight = t != null && lastT != null
        ? ((t - lastT) / 1000).clamp(0, 30).toDouble()
        : 1.0;
    if (t != null) lastT = t;
    if (hr == null || hr <= 0) continue;
    seconds[zoneOf(hr, floors) - 1] += weight;
    counted++;
  }
  final total = seconds.fold<double>(0, (a, b) => a + b);
  if (counted < 10 || total <= 0) return null;
  return {
    for (var i = 0; i < 5; i++) 'zone${i + 1}': seconds[i] / total * 100,
  };
}
