/// A planned session ready to be sent to a watch platform: the steps with
/// concrete targets, the text that goes with it and what a platform needs to
/// convert the targets.
class PreparedWorkout {
  const PreparedWorkout({
    required this.sessionId,
    required this.title,
    required this.date,
    required this.sport,
    required this.steps,
    required this.description,
    this.thresholdHr,
  });

  final String sessionId;
  final String title;
  final DateTime date;

  /// The planner's sport, such as `running` or `cycling_road`.
  final String sport;

  /// Garmin-style steps: `stepType`, `endCondition`, `endConditionValue`,
  /// `zoneNumber`, `targetType` and `targetValueOne`/`targetValueTwo` in bpm
  /// for heart-rate steps, nested repeat groups under `workoutSteps`.
  final List<Map<String, dynamic>> steps;

  /// Notes, targets and totals as text.
  final String description;

  /// Threshold heart rate in bpm, for platforms that express a heart-rate
  /// target as a share of it.
  final int? thresholdHr;
}
