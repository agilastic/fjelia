import '../../models/workout_presentation.dart';

import 'package:flutter/material.dart';

import '../../models/garmin_data.dart';
import '../../widgets/app_widgets.dart';
import '../ai_coach/ai_coach_screen.dart';

class WorkoutDetailSheet extends StatelessWidget {
  const WorkoutDetailSheet({super.key, required this.workout});
  final ScheduledWorkout workout;
  @override
  Widget build(BuildContext context) => SheetPage(
    title: workout.name,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Garmin Workout',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ),
        SectionCard(
          title: dayText(workout.scheduledDate),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(workout.sportType.replaceAll('_', ' ')),
              Text(
                workoutSummary(workout),
                style: const TextStyle(color: mint),
              ),
            ],
          ),
        ),
        if (workout.description != null)
          SectionCard(title: 'Description', child: Text(workout.description!)),
        for (final step in workout.steps) _Step(step),
        if (workout.userNote != null)
          SectionCard(title: 'Your note', child: Text(workout.userNote!)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: mint,
            side: const BorderSide(color: mint),
            minimumSize: const Size(double.infinity, 44),
          ),
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text('Ask AI Coach'),
          onPressed: () => showCoachSheet(
            context,
            title: 'Workout Coach',
            prompt: [
              'Help me prepare for this planned workout: its purpose, how to pace it, and whether I should adjust it based on my current recovery and training load.',
              '',
              'Workout: ${workout.name}',
              'Date: ${dayText(workout.scheduledDate)}',
              'Sport: ${workout.sportType.replaceAll('_', ' ')}',
              'Planned: ${workoutSummary(workout)}',
              if (workout.steps.isNotEmpty) 'Structure:',
              for (final step in workout.steps) ..._stepLines(step, 0),
            ].join('\n'),
          ),
        ),
      ],
    ),
  );
}

List<String> _stepLines(WorkoutStep step, int depth) {
  final target = workoutStepTarget(step);
  return [
    '${'  ' * depth}- ${step.stepName ?? step.type}: ${workoutStepDuration(step)}'
        '${target == null ? '' : ' @ $target'}',
    for (final child in step.steps) ..._stepLines(child, depth + 1),
  ];
}

class _Step extends StatelessWidget {
  const _Step(this.step);
  final WorkoutStep step;
  @override
  Widget build(BuildContext context) => SectionCard(
    title: step.stepName ?? step.type,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (step.description != null) Text(step.description!),
        Text(
          [
            workoutStepDuration(step),
            if (workoutStepTarget(step) != null) workoutStepTarget(step)!,
          ].join(' · '),
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        for (final child in step.steps) _Step(child),
      ],
    ),
  );
}
