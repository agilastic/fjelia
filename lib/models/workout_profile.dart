import 'dart:convert';

import 'garmin_data.dart';
import 'workout_presentation.dart';

/// One block of a planned workout: how long it lasts and in which zone.
class WorkoutBlock {
  const WorkoutBlock({
    required this.seconds,
    required this.zone,
    required this.label,
    this.estimated = false,
  });

  final double seconds;

  /// Intensity zone 1 to 5.
  final int zone;
  final String label;

  /// The length is a guess: the step is defined by distance or is open-ended.
  final bool estimated;

  String get duration => formatBlockDuration(seconds);
}

String formatBlockDuration(double seconds) {
  final n = seconds.round();
  if (n < 60) return '$n sec';
  final m = n ~/ 60, s = n % 60;
  return s == 0 ? '$m min' : '$m min $s sec';
}

/// Rough seconds per metre for steps that are defined by distance.
double secondsPerMetre(String sport) {
  final s = sport.toLowerCase();
  if (s.contains('swim')) return 1.4; // 2:20 per 100 m
  if (s.contains('cycl') || s.contains('bik')) return 0.12; // 30 km/h
  if (s.contains('walk') || s.contains('hik')) return 0.72; // 12 min per km
  return 0.36; // 6:00 per km
}

/// The blocks of a planned workout in order, with repeats expanded. Distance
/// and open-ended steps get an estimated length and are marked as such.
/// Returns an empty list when the steps cannot be read.
List<WorkoutBlock> workoutProfile(
  String? stepsJson, {
  required int primaryZone,
  String sport = '',
}) {
  if (stepsJson == null || stepsJson.isEmpty) return const [];
  const maxBlocks = 200;
  final output = <WorkoutBlock>[];
  final perMetre = secondsPerMetre(sport);
  final fallbackZone = primaryZone.clamp(1, 5);

  void read(Object? items, int depth) {
    if (items is! List || depth > 8) return;
    for (final item in items) {
      if (output.length >= maxBlocks) return;
      if (item is! Map) continue;
      final stepType = item['stepType'];
      final type = stepType is Map
          ? stepType['stepTypeKey']?.toString()
          : stepType?.toString();
      final children = item['workoutSteps'];
      if (children is List || type == 'repeat') {
        final n = item['numberOfIterations'] ?? item['endConditionValue'];
        final times = n is num && n.isFinite ? n.round().clamp(1, 100) : 1;
        for (var i = 0; i < times && output.length < maxBlocks; i++) {
          read(children, depth + 1);
        }
        continue;
      }
      final condition = item['endCondition'];
      final key = condition is Map ? condition['conditionTypeKey'] : null;
      final value = item['endConditionValue'];
      var seconds = 300.0;
      var estimated = true;
      if (value is num && value.isFinite && value > 0) {
        if (key == 'time' || (key == null && condition == null)) {
          seconds = value.toDouble();
          estimated = false;
        } else if (key == 'distance' ||
            condition is Map && condition['conditionTypeId'] == 3) {
          seconds = value * perMetre;
        }
      }
      final easy = {'warmup', 'cooldown', 'recovery', 'rest'}.contains(type);
      final zone = item['zoneNumber'];
      output.add(
        WorkoutBlock(
          seconds: seconds,
          zone: zone is num && zone >= 1 && zone <= 5
              ? zone.toInt()
              : easy
              ? 1
              : fallbackZone,
          label: switch (type) {
            'warmup' => 'Warm-up',
            'cooldown' => 'Cool-down',
            'recovery' => 'Recovery',
            'rest' => 'Rest',
            'interval' => 'Interval',
            _ => 'Workout',
          },
          estimated: estimated,
        ),
      );
    }
  }

  try {
    final decoded = jsonDecode(stepsJson);
    read(
      decoded is Map ? decoded['workoutSteps'] ?? decoded['steps'] : decoded,
      0,
    );
  } on FormatException {
    return const [];
  }
  return output;
}

/// The blocks of a Garmin workout in order, repeats expanded. Steps without a
/// time get an estimated length; without a target zone a step counts as zone 1
/// when easy and zone 3 otherwise.
List<WorkoutBlock> workoutStepBlocks(
  List<WorkoutStep> steps, {
  String sport = '',
}) {
  const maxBlocks = 200;
  final output = <WorkoutBlock>[];
  final perMetre = secondsPerMetre(sport);

  void read(List<WorkoutStep> items, int depth) {
    if (depth > 8) return;
    for (final step in items) {
      if (output.length >= maxBlocks) return;
      if (step.steps.isNotEmpty) {
        final times = (step.repeatCount ?? 1).clamp(1, 100);
        for (var i = 0; i < times && output.length < maxBlocks; i++) {
          read(step.steps, depth + 1);
        }
        continue;
      }
      final value = step.durationValue;
      var seconds = 300.0;
      var estimated = true;
      if (value != null && value > 0) {
        switch (step.durationUnit) {
          case 'time' || 'seconds':
            seconds = value;
            estimated = false;
          case 'distance' || 'meters':
            seconds = value * perMetre;
        }
      }
      final role = workoutStepRole(step);
      final easy = const {
        'Warm-up',
        'Cool-down',
        'Recovery',
        'Rest',
      }.contains(role);
      final zone = step.targetZone;
      output.add(
        WorkoutBlock(
          seconds: seconds,
          zone: zone != null && zone >= 1 && zone <= 5 ? zone : (easy ? 1 : 3),
          label: role,
          estimated: estimated,
        ),
      );
    }
  }

  read(steps, 0);
  return output;
}

/// Share of the time in each zone 1 to 5, from the blocks of a workout. Null
/// when there are no blocks.
List<double>? zoneFractionsOf(List<WorkoutBlock> blocks) {
  final total = blocks.fold<double>(0, (sum, b) => sum + b.seconds);
  if (total <= 0) return null;
  final seconds = List<double>.filled(5, 0);
  for (final b in blocks) {
    seconds[b.zone.clamp(1, 5) - 1] += b.seconds;
  }
  return [for (final v in seconds) v / total];
}

/// Seconds of the blocks that are known, not estimated, and the total.
({double total, bool anyEstimated}) blockTotals(List<WorkoutBlock> blocks) => (
  total: blocks.fold<double>(0, (sum, b) => sum + b.seconds),
  anyEstimated: blocks.any((b) => b.estimated),
);
