import 'dart:convert';

import '../models/workout_profile.dart' show secondsPerMetre;

/// What a structured workout asks for, worked out from its steps in one place.
///
/// Time steps are exact. A step that ends after a distance gets an estimated
/// time from the sport's typical pace, and a step without an end (a lap
/// button) a short default; both are reported as estimates and never mixed
/// into the exact total. Repeats multiply everything inside them, nested
/// repeats multiply each other.
class WorkoutSemantics {
  const WorkoutSemantics({
    this.exactSeconds = 0,
    this.estimatedSeconds = 0,
    this.openSteps = 0,
    this.zoneSeconds = const {},
    this.mainZoneSeconds = const {},
  });

  /// Seconds of steps that end after a time.
  final double exactSeconds;

  /// Seconds estimated for steps that end after a distance or have no end.
  final double estimatedSeconds;

  /// Number of steps without a defined end (counted once per repetition).
  final int openSteps;

  /// Seconds per zone 1 to 5, all steps. Steps without a zone count as zone 1.
  final Map<int, double> zoneSeconds;

  /// The same without warm-up and cool-down.
  final Map<int, double> mainZoneSeconds;

  double get totalSeconds => exactSeconds + estimatedSeconds;
  bool get isExact => estimatedSeconds == 0 && openSteps == 0;
  bool get isEmpty => totalSeconds <= 0;

  /// Minutes, rounded; 0 when there is nothing to add up.
  int get totalMinutes => (totalSeconds / 60).round();

  /// The zone with the most time outside warm-up and cool-down, or null.
  int? get dominantZone {
    if (mainZoneSeconds.isEmpty) return null;
    return mainZoneSeconds.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  static const _openStepSeconds = 300.0;
  static const _maxDepth = 8;
  static const _maxRepeat = 200;

  /// Parses [stepsJson]; an unreadable or empty list gives an empty result.
  static WorkoutSemantics of(String? stepsJson, {String sport = ''}) {
    if (stepsJson == null || stepsJson.isEmpty) return const WorkoutSemantics();
    Object? decoded;
    try {
      decoded = jsonDecode(stepsJson);
    } on FormatException {
      return const WorkoutSemantics();
    }
    final steps = decoded is Map
        ? decoded['workoutSteps'] ?? decoded['steps']
        : decoded;
    if (steps is! List) return const WorkoutSemantics();
    final perMetre = secondsPerMetre(sport);
    var exact = 0.0, estimated = 0.0;
    var open = 0;
    final zones = <int, double>{}, main = <int, double>{};

    void add(Map<int, double> into, int zone, double seconds) =>
        into[zone] = (into[zone] ?? 0) + seconds;

    void walk(List items, double multiplier, int depth) {
      if (depth > _maxDepth) return;
      for (final item in items) {
        if (item is! Map) continue;
        final children = item['workoutSteps'];
        final type = _typeKey(item);
        if (children is List || type == 'repeat') {
          final n = item['numberOfIterations'] ?? item['endConditionValue'];
          final times = n is num && n.isFinite
              ? n.round().clamp(1, _maxRepeat)
              : 1;
          if (children is List) walk(children, multiplier * times, depth + 1);
          continue;
        }
        final condition = item['endCondition'];
        final key = condition is Map
            ? condition['conditionTypeKey']?.toString()
            : condition?.toString();
        final value = item['endConditionValue'];
        final number = value is num && value.isFinite && value > 0
            ? value.toDouble()
            : null;
        double seconds;
        if (number != null && (key == 'time' || key == null)) {
          seconds = number;
          exact += seconds * multiplier;
        } else if (number != null && key == 'distance') {
          seconds = number * perMetre;
          estimated += seconds * multiplier;
        } else {
          seconds = _openStepSeconds;
          estimated += seconds * multiplier;
          open += multiplier.round();
        }
        final zone = item['zoneNumber'];
        final z = zone is num && zone >= 1 && zone <= 5 ? zone.toInt() : 1;
        add(zones, z, seconds * multiplier);
        if (type != 'warmup' && type != 'cooldown') {
          add(main, z, seconds * multiplier);
        }
      }
    }

    walk(steps, 1, 0);
    return WorkoutSemantics(
      exactSeconds: exact,
      estimatedSeconds: estimated,
      openSteps: open,
      zoneSeconds: zones,
      mainZoneSeconds: main,
    );
  }

  static String? _typeKey(Map item) {
    final stepType = item['stepType'];
    return stepType is Map
        ? stepType['stepTypeKey']?.toString()
        : stepType?.toString();
  }

  /// Zone weights of the planner's load estimate (Z1 to Z5).
  static const zoneWeights = [1.0, 1.1, 1.2, 3.1, 8.0];

  /// Load in the planner's legacy zone-weighted units: minutes times the
  /// weight of the zone, nested repeats and estimated durations included.
  double get legacyLoad {
    var total = 0.0;
    zoneSeconds.forEach((zone, seconds) {
      total += seconds / 60 * zoneWeights[(zone - 1).clamp(0, 4)];
    });
    return total;
  }
}

/// A workout whose main part was lengthened or shortened to fit a duration.
class FittedWorkout {
  const FittedWorkout(this.stepsJson, this.scaled);

  final String stepsJson;

  /// The steps were changed.
  final bool scaled;
}

/// Fits a steady workout to [targetSeconds] by changing its easy main step.
///
/// Only the single longest top-level time step in zone 1 or 2 is scaled, and
/// only within half to one and a half times its length. Warm-up, cool-down,
/// intervals, repeat groups and every harder step stay as they are, because
/// they carry the purpose of the session. Workouts without such a step come
/// back unchanged.
FittedWorkout fitSteadyWorkout(String stepsJson, double targetSeconds) {
  Object? decoded;
  try {
    decoded = jsonDecode(stepsJson);
  } on FormatException {
    return FittedWorkout(stepsJson, false);
  }
  if (decoded is! List) return FittedWorkout(stepsJson, false);
  final current = WorkoutSemantics.of(stepsJson);
  if (!current.isExact || current.isEmpty) {
    return FittedWorkout(stepsJson, false);
  }
  int? index;
  var longest = 0.0;
  for (var i = 0; i < decoded.length; i++) {
    final item = decoded[i];
    if (item is! Map || item['workoutSteps'] is List) continue;
    final type = WorkoutSemantics._typeKey(item);
    if (type == 'warmup' || type == 'cooldown' || type == 'repeat') continue;
    final zone = item['zoneNumber'];
    final condition = item['endCondition'];
    final timed = condition is Map && condition['conditionTypeKey'] == 'time';
    final seconds = item['endConditionValue'];
    if (!timed || seconds is! num || zone is! num || zone > 2) continue;
    if (seconds > longest) {
      longest = seconds.toDouble();
      index = i;
    }
  }
  if (index == null) return FittedWorkout(stepsJson, false);
  final wanted = longest + (targetSeconds - current.totalSeconds);
  final bounded = wanted.clamp(longest * 0.5, longest * 1.5);
  // Whole minutes read better on the watch.
  final rounded = (bounded / 60).round() * 60.0;
  if ((rounded - longest).abs() < 60) return FittedWorkout(stepsJson, false);
  final out = [
    for (var i = 0; i < decoded.length; i++)
      if (i == index)
        {
          ...Map<String, dynamic>.from(decoded[i] as Map),
          'endConditionValue': rounded.round(),
        }
      else
        decoded[i],
  ];
  return FittedWorkout(jsonEncode(out), true);
}

/// Replaces a total duration written in a workout title, "(115 min)" or a
/// leading "30m", with [minutes]. Titles without one stay as they are.
String retimeTitle(String title, int minutes) {
  var out = title.replaceFirstMapped(
    RegExp(r'\((\d+)\s*min\)'),
    (m) => '($minutes min)',
  );
  out = out.replaceFirstMapped(RegExp(r'^(\d+)m\b'), (m) => '${minutes}m');
  return out;
}
