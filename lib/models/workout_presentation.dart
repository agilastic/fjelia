import 'garmin_data.dart';

String workoutDurationLabel(double seconds) {
  final duration = Duration(seconds: seconds.round());
  final minutes = duration.inMinutes;
  final remainder = duration.inSeconds % 60;
  return remainder == 0 ? '$minutes min' : '$minutes min $remainder sec';
}

String workoutStepDuration(WorkoutStep step) {
  if (step.steps.isNotEmpty) return '${step.repeatCount ?? 1} repetitions';
  final value = step.durationValue;
  if (value == null) return 'Until lap press';
  return switch (step.durationUnit) {
    'time' || 'seconds' => workoutDurationLabel(value),
    'distance' || 'meters' =>
      value >= 1000
          ? '${(value / 1000).toStringAsFixed(1)} km'
          : '${value.round()} m',
    'lap.button' || 'lap_button' => 'Until lap press',
    _ =>
      '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)} ${step.durationUnit ?? ''}'
          .trim(),
  };
}

String? workoutStepTarget(WorkoutStep step) {
  if (step.targetType == null || step.targetType == 'no.target') return null;
  final label = switch (step.targetType) {
    'heartRate' => 'Heart rate',
    'pace' => 'Pace',
    'speed' => 'Speed',
    'cadence' => 'Cadence',
    'power' || 'power.zone' => 'Power',
    _ => step.targetType!.replaceAll('.', ' '),
  };
  if (step.targetZone != null) return '$label · Zone ${step.targetZone}';
  final from = step.targetFrom, to = step.targetTo;
  if (from == null && to == null) return '$label target unavailable';
  final unit = switch (step.targetType) {
    'heartRate' => ' bpm',
    'cadence' => ' rpm',
    'power' || 'power.zone' => ' W',
    _ => '',
  };
  String number(double value) =>
      value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
  final range = from != null && to != null
      ? from == to
            ? number(from)
            : '${number(from)}–${number(to)}'
      : from != null
      ? '≥ ${number(from)}'
      : '≤ ${number(to!)}';
  return '$label · $range$unit';
}

// A mixed distance/lap workout cannot yield a known total time from its steps.
double? workoutStepsSeconds(List<WorkoutStep> steps) {
  if (steps.isEmpty) return null;
  var total = 0.0;
  for (final step in steps) {
    if (step.steps.isNotEmpty) {
      final nested = workoutStepsSeconds(step.steps);
      if (nested == null || step.repeatCount == null) return null;
      total += nested * step.repeatCount!;
    } else {
      if (!['time', 'seconds'].contains(step.durationUnit) ||
          step.durationValue == null) {
        return null;
      }
      total += step.durationValue!;
    }
  }
  return total;
}

String workoutSummary(ScheduledWorkout workout) {
  final seconds =
      workout.estimatedDuration?.inSeconds.toDouble() ??
      workoutStepsSeconds(workout.steps);
  final distance = workout.estimatedDistanceMeters;
  final parts = <String>[
    if (seconds != null && seconds > 0) workoutDurationLabel(seconds),
    if (distance != null && distance > 0)
      '${(distance / 1000).toStringAsFixed(1)} km',
  ];
  return parts.isEmpty ? 'Structured workout' : parts.join(' · ');
}
