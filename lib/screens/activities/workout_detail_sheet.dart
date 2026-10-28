import '../../l10n/l10n_ext.dart';
import '../../l10n/formats.dart';
import '../../models/workout_presentation.dart';

import 'package:flutter/material.dart';

import '../../models/coach_context_card.dart';
import '../../models/garmin_data.dart';
import '../../models/strength_workout.dart';
import '../../services/strength/strength_repository.dart';
import '../../models/workout_profile.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/workout_profile_bar.dart';
import '../../widgets/workout_structure_list.dart';
import '../../widgets/nutrition_widgets.dart';
import '../../models/workout_nutrition.dart';
import '../ai_coach/ai_coach_screen.dart';
import '../strength/strength_sections.dart';
import 'weekly_load_card.dart' show sportName;

class WorkoutDetailSheet extends StatelessWidget {
  const WorkoutDetailSheet({super.key, required this.workout});
  final ScheduledWorkout workout;

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        color: muted,
        fontWeight: FontWeight.w700,
        letterSpacing: .8,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final lines = workoutStepLines(workout.steps);
    final blocks = workoutStepBlocks(workout.steps, sport: workout.sportType);
    final seconds =
        workout.estimatedDuration?.inSeconds.toDouble() ??
        workoutStepsSeconds(workout.steps);
    final distance = workout.estimatedDistanceMeters;
    final strength = isStrengthSport(workout.sportType);
    return SheetPage(
      title: workout.name,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.l10n.garminWorkoutScheduleddate(
              dayText(workout.scheduledDate),
            ),
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          WorkoutStatTiles(
            items: [
              if (seconds != null && seconds > 0)
                (workoutDurationLabel(seconds), context.l10n.duration2),
              if (distance != null && distance > 0)
                ('${(distance / 1000).fixed(1)} km', context.l10n.distance2),
              (sportName(workout.sportType), context.l10n.sport2),
              if (lines.any((l) => l.repeat))
                (
                  '${lines.where((l) => l.repeat).length}',
                  context.l10n.repeatSets,
                ),
            ],
          ),
          if (workout.description?.isNotEmpty ?? false) ...[
            _heading(context.l10n.aboutThisWorkout),
            Text(
              workout.description!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.6,
              ),
            ),
          ],
          if (strength)
            PlannedStrengthSection(
              owner: StrengthPlanOwner.scheduled('garmin', workout.scheduleId),
              sessionDate: workout.scheduledDate,
              ownershipNote: context.l10n.editsAreKeptInFjelia,
            ),
          if (lines.isNotEmpty) ...[
            _heading(
              strength
                  ? context.l10n.asSentByGarmin
                  : context.l10n.workoutStructure,
            ),
            if (blocks.isNotEmpty) ...[
              WorkoutProfileBar(blocks: blocks),
              const SizedBox(height: 14),
            ],
            WorkoutStructureList(steps: lines),
          ],
          if (seconds != null && seconds > 0)
            PlannedNutritionCard(
              workout: NutritionWorkout(
                key:
                    'garmin:${workout.workoutId}:${workout.scheduledDate.toIso8601String().split('T').first}',
                title: workout.name,
                sport: workout.sportType,
                date: workout.scheduledDate,
                minutes: seconds / 60,
                indoor: workout.sportType.contains('indoor'),
              ),
            ),
          if (workout.userNote != null)
            SectionCard(
              title: context.l10n.yourNote,
              child: Text(workout.userNote!),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: mint,
              side: const BorderSide(color: mint),
              minimumSize: const Size(double.infinity, 44),
            ),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: Text(context.l10n.askAiCoach),
            onPressed: () => openCoachTab(
              context,
              prompt: context.l10n.howDoIExecuteThis,
              card: CoachContextCard.scheduled(
                sport: workout.sportType,
                title: workout.name,
                date: workout.scheduledDate,
                summary: workoutSummary(workout),
                structure: [
                  for (final step in workout.steps)
                    ..._stepLines(
                      step,
                      0,
                    ).map((l) => l.trim().replaceFirst('- ', '')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _stepLines(WorkoutStep step, int depth) {
  final target = workoutStepTarget(step);
  return [
    '${'  ' * depth}- ${step.stepName ?? step.type}: ${workoutStepDuration(step)}'
        '${target == null ? '' : ' @ $target'}',
    for (final child in step.steps) ..._stepLines(child, depth + 1),
  ];
}
