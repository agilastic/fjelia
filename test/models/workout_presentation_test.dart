import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/models/garmin_data.dart';
import 'package:fjelia/models/workout_presentation.dart';

void main() {
  test('cached steps preserve targets, ordering and repeat counts', () {
    const step = WorkoutStep(
      order: 3,
      type: 'RepeatGroupDTO',
      repeatCount: 4,
      targetType: 'heartRate',
      targetFrom: 120,
      targetTo: 140,
      targetZone: 2,
      steps: [
        WorkoutStep(
          order: 1,
          type: 'ExecutableStepDTO',
          durationUnit: 'time',
          durationValue: 300,
        ),
      ],
    );
    final restored = WorkoutStep.fromJson(step.toJson());
    expect(restored.order, 3);
    expect(restored.repeatCount, 4);
    expect(restored.targetFrom, 120);
    expect(restored.targetTo, 140);
    expect(workoutStepTarget(restored), 'Heart rate · Zone 2');
    expect(workoutStepsSeconds([restored]), 1200);
  });
  test('shakeout shows readable durations and derives total without inventing distance', () {
    final steps = [
      for (final seconds in [300.0, 1200.0, 300.0])
        WorkoutStep(
          order: 1,
          type: 'ExecutableStepDTO',
          durationUnit: 'time',
          durationValue: seconds,
          targetType: 'heartRate',
        ),
    ];
    expect(workoutStepDuration(steps.first), '5 min');
    expect(workoutStepDuration(steps[1]), '20 min');
    expect(workoutStepTarget(steps.first), 'Heart rate target unavailable');
    final workout = ScheduledWorkout(
      workoutId: '1',
      scheduleId: '1',
      name: 'Short Shakeout',
      sportType: 'running',
      scheduledDate: DateTime(2026),
      steps: steps,
    );
    expect(workoutSummary(workout), '30 min');
    expect(
      workoutStepsSeconds([
        const WorkoutStep(
          order: 1,
          type: 'ExecutableStepDTO',
          durationUnit: 'lap.button',
        ),
      ]),
      isNull,
    );
  });
}
