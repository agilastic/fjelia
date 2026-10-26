import '../models/prepared_workout.dart';

class PolarUnsupportedWorkout implements Exception {
  const PolarUnsupportedWorkout(this.reason);
  final String reason;
  @override
  String toString() => reason;
}

/// The phased target accepted by Polar Flow's workout editor.
/// HR zones refer to the athlete's Polar sport profile; no profile is changed.
Map<String, dynamic> buildPolarWorkout(PreparedWorkout workout) {
  final sportId = switch (workout.sport) {
    'running' || 'trail_running' => workout.indoor ? 17 : 1,
    'cycling' || 'cycling_road' || 'cycling_gravel' || 'cycling_mtb' => 2,
    'swimming' => 23,
    'swimming_pool' => 103,
    'swimming_open_water' => 105,
    'strength' => 15,
    _ => throw PolarUnsupportedWorkout(
      'Polar workout push does not support ${workout.sport.replaceAll('_', ' ')}.',
    ),
  };
  if (workout.steps.isEmpty) {
    throw const PolarUnsupportedWorkout(
      'This workout has no phases to send to Polar.',
    );
  }
  var uniquePhases = 0;
  var expandedPhases = 0;

  List<Map<String, dynamic>> phases(
    List<Map<String, dynamic>> steps, {
    int depth = 0,
    int multiplier = 1,
  }) {
    final result = <Map<String, dynamic>>[];
    for (final step in steps) {
      if (step['type'] == 'RepeatGroupDTO') {
        final count = step['numberOfIterations'] ?? step['endConditionValue'];
        final children = step['workoutSteps'];
        if (depth >= 2 ||
            count is! num ||
            !count.isFinite ||
            count != count.round() ||
            count < 2 ||
            count > 99 ||
            children is! List ||
            children.isEmpty ||
            children.any((s) => s is! Map<String, dynamic>)) {
          throw const PolarUnsupportedWorkout(
            'Polar supports repeat groups of 2–99 repetitions, nested at most twice.',
          );
        }
        result.add({
          'phaseType': 'REPEAT',
          'repeatCount': count.toInt(),
          'phases': phases(
            children.cast<Map<String, dynamic>>(),
            depth: depth + 1,
            multiplier: multiplier * count.toInt(),
          ),
        });
        continue;
      }
      uniquePhases++;
      expandedPhases += multiplier;
      if (uniquePhases > 20 || expandedPhases > 200) {
        throw const PolarUnsupportedWorkout(
          'Polar supports at most 20 different phases and 200 phases including repeats.',
        );
      }
      final condition = (step['endCondition'] as Map?)?['conditionTypeKey'];
      final value = step['endConditionValue'];
      if ((condition != 'time' && condition != 'distance') ||
          value is! num ||
          !value.isFinite ||
          value <= 0 ||
          (condition == 'time' &&
              (value.round() < 1 || value.round() > 359999))) {
        throw const PolarUnsupportedWorkout(
          'Polar phases need a positive time or distance. Open-ended steps can be shared as text.',
        );
      }
      final target = (step['targetType'] as Map?)?['workoutTargetTypeKey'];
      final zone = step['zoneNumber'];
      final hr = target == 'heart.rate.zone';
      if (hr &&
          (zone is! num ||
              !zone.isFinite ||
              zone != zone.round() ||
              zone < 1 ||
              zone > 5)) {
        throw const PolarUnsupportedWorkout(
          'Polar heart-rate targets need a zone from 1 to 5.',
        );
      }
      if (target != null && target != 'no.target' && !hr) {
        throw const PolarUnsupportedWorkout(
          'Polar push supports heart-rate zones and untargeted phases. Use heart rate for this workout or share its other targets as text.',
        );
      }
      final kind = switch ((step['stepType'] as Map?)?['stepTypeKey']) {
        'warmup' => 'Warm-up',
        'cooldown' => 'Cool-down',
        'recovery' => 'Recovery',
        'rest' => 'Rest',
        _ => 'Interval',
      };
      final low = step['targetValueOne'], high = step['targetValueTwo'];
      final name = [
        step['stepName'] as String? ?? kind,
        if (hr) 'Z${(zone as num).toInt()}',
        if (hr && low is num && high is num && low.isFinite && high.isFinite)
          '${low.round()}–${high.round()} bpm',
      ].join(' · ');
      final seconds = value.round();
      String two(int n) => n.toString().padLeft(2, '0');
      result.add({
        'phaseType': 'PHASE',
        'name': _limit(name, 45),
        'phaseChangeType': 'AUTOMATIC',
        'goalType': condition == 'time' ? 'DURATION' : 'DISTANCE',
        'duration': condition == 'time'
            ? '${two(seconds ~/ 3600)}:${two(seconds % 3600 ~/ 60)}:${two(seconds % 60)}'
            : null,
        'distance': condition == 'distance' ? value : null,
        'intensityType': hr ? 'HEART_RATE_ZONES' : 'NONE',
        'lowerZone': hr ? (zone as num).toInt() : null,
        'upperZone': hr ? (zone as num).toInt() : null,
      });
    }
    return result;
  }

  final date = workout.date;
  String two(int n) => n.toString().padLeft(2, '0');
  // Plans store a day rather than a start time. Keep it in local time and use
  // 18:00 for these day-only sessions, preserving an explicitly supplied time.
  final hour = date.hour == 0 && date.minute == 0 ? 18 : date.hour;
  return {
    'type': 'PHASED',
    'name': _limit(
      workout.title.trim().isEmpty ? 'Workout' : workout.title.trim(),
      45,
    ),
    'description': _limit(workout.description, 500),
    'datetime':
        '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}T${two(hour)}:${two(date.minute)}',
    'exerciseTargets': [
      {
        'id': null,
        'sportId': sportId,
        'distance': null,
        'calories': null,
        'duration': null,
        'phases': phases(workout.steps),
      },
    ],
  };
}

String _limit(String value, int length) {
  final runes = value.runes.toList();
  return runes.length <= length
      ? value
      : '${String.fromCharCodes(runes.take(length - 1))}…';
}
