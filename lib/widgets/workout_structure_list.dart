import 'package:flutter/material.dart';

import '../models/planned_workout_presentation.dart';
import 'app_widgets.dart';
import 'workout_profile_bar.dart';

/// Colour of a step: its intensity zone, the same as in the profile above
/// the list. Repeat groups are faint, steps without a zone grey.
Color workoutStepColor(PlannedStepLine step) {
  if (step.repeat) return Colors.white24;
  final zone = step.colorZone ?? step.zone;
  return zone == null ? Colors.grey : workoutZoneColors[zone.clamp(1, 5) - 1];
}

/// The steps of a workout as a list with a coloured bar per step. Repeat
/// groups are indented over the steps they contain.
class WorkoutStructureList extends StatelessWidget {
  const WorkoutStructureList({super.key, required this.steps});

  final List<PlannedStepLine> steps;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final step in steps)
        Padding(
          padding: EdgeInsets.only(left: step.depth * 14.0, bottom: 8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: workoutStepColor(step),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: step.amount,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (step.label.isNotEmpty)
                              TextSpan(
                                text: '  ${step.label}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            if (step.zone != null && step.target == null)
                              TextSpan(
                                text: ' Z${step.zone}',
                                style: const TextStyle(color: muted),
                              ),
                          ],
                        ),
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                      if (step.target != null)
                        Text(
                          step.target!,
                          style: const TextStyle(fontSize: 11, color: muted),
                        ),
                      if (step.note != null)
                        Text(
                          step.note!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                            height: 1.35,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

/// A row of tiles with a value and a small caption, as at the top of a
/// workout.
class WorkoutStatTiles extends StatelessWidget {
  const WorkoutStatTiles({super.key, required this.items});

  /// (value, caption) pairs.
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final e in items)
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                FittedBox(
                  child: Text(
                    e.$1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  child: Text(
                    e.$2,
                    style: const TextStyle(fontSize: 8, color: muted),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
