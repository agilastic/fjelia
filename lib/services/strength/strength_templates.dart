import '../../models/strength_workout.dart';

/// Structured versions of the bundled strength templates. They prescribe
/// sets, repetitions, rest and tempo; never an athlete's kilograms.
///
/// Ids are stable per template revision, so a plan made from the same
/// revision maps sets the same way. Changing a prescription needs a new
/// revision; existing session plans and logs keep theirs.

class BundledStrengthTemplate {
  const BundledStrengthTemplate({
    required this.id,
    required this.revision,
    required this.legacyDescription,
    required this.build,
  });

  /// The planner's `subType` for sessions made from this template.
  final String id;
  final int revision;

  /// The description the planner copied into `sessionNotes`. Together with
  /// the id it proves a session came from this template; a title is not
  /// enough.
  final String legacyDescription;
  final StrengthWorkoutPlan Function() build;
}

StrengthPlannedExercise _exercise(
  String template,
  String variantId, {
  required int sets,
  int? reps,
  (int, int)? range,
  int? seconds,
  int? rest,
  String? tempo,
  StrengthEffort? effort,
  String? notes,
}) {
  final v = builtInStrengthVariant(variantId)!;
  final prefix = '$template-$variantId';
  return StrengthPlannedExercise(
    id: prefix,
    variantId: v.id,
    name: v.name,
    equipment: v.equipment,
    convention: v.convention,
    notes: notes,
    sets: [
      for (var i = 1; i <= sets; i++)
        StrengthSetTarget(
          id: '$prefix-s$i',
          reps: reps,
          repMin: range?.$1,
          repMax: range?.$2,
          durationSeconds: seconds,
          restSeconds: rest,
          tempo: tempo,
          effort: effort,
        ),
    ],
  );
}

StrengthBlock _straight(StrengthPlannedExercise e) =>
    StrengthBlock(id: '${e.id}-block', exercises: [e]);

const _rir2 = StrengthEffort(StrengthEffortScale.rir, 2);

final bundledStrengthTemplates = [
  BundledStrengthTemplate(
    id: 'strengthFull',
    revision: 1,
    legacyDescription: 'Compound lifts: squat, deadlift, press, row. 3 sets × 8–10 reps. Base phase volume.',
    build: () {
      const t = 'strengthFull1';
      return StrengthWorkoutPlan(
        title: 'Full Body Strength — Base',
        estimatedMinutes: 55,
        template: const StrengthTemplateRef('strengthFull', 1),
        notes: 'Control the lowering (3 seconds down). Leave about two repetitions in reserve.',
        blocks: [
          for (final id in const [
            'back_squat',
            'deadlift',
            'overhead_press',
            'barbell_row',
          ])
            _straight(
              _exercise(
                t,
                id,
                sets: 3,
                range: (8, 10),
                rest: 120,
                tempo: '3-0-1-0',
                effort: _rir2,
              ),
            ),
        ],
      );
    },
  ),
  BundledStrengthTemplate(
    id: 'strengthLower',
    revision: 1,
    legacyDescription: 'Squat, lunge, RDL, calf raise. 4 sets × 5–6 reps heavy. Strength phase.',
    build: () {
      const t = 'strengthLower1';
      return StrengthWorkoutPlan(
        title: 'Lower Body Power — Build',
        estimatedMinutes: 60,
        template: const StrengthTemplateRef('strengthLower', 1),
        notes: 'Explosive on the way up, controlled on the way down.',
        blocks: [
          for (final id in const [
            'back_squat',
            'walking_lunge',
            'romanian_deadlift',
            'calf_raise',
          ])
            _straight(
              _exercise(
                t,
                id,
                sets: 4,
                range: (5, 6),
                rest: 150,
                effort: _rir2,
              ),
            ),
        ],
      );
    },
  ),
  BundledStrengthTemplate(
    id: 'strengthCore',
    revision: 1,
    legacyDescription:
        'Plank, dead bug, bird dog, pallof press. Injury prevention focus.',
    build: () {
      const t = 'strengthCore1';
      return StrengthWorkoutPlan(
        title: 'Core & Stability',
        estimatedMinutes: 30,
        template: const StrengthTemplateRef('strengthCore', 1),
        notes: 'Quality over quantity. Stop a set when form breaks.',
        blocks: [
          StrengthBlock(
            id: '$t-circuit',
            kind: StrengthBlockKind.circuit,
            restBetweenExercisesSeconds: 15,
            restBetweenRoundsSeconds: 60,
            exercises: [
              _exercise(t, 'plank', sets: 3, seconds: 45),
              _exercise(t, 'dead_bug', sets: 3, reps: 10),
              _exercise(t, 'bird_dog', sets: 3, reps: 8),
              _exercise(t, 'pallof_press', sets: 3, reps: 10),
            ],
          ),
        ],
      );
    },
  ),
];

/// The structured plan for a session the planner made from a bundled
/// template, or null when the session cannot be proven to come from one.
StrengthWorkoutPlan? bundledStrengthPlanFor({
  required String? subType,
  required String? sessionNotes,
}) {
  for (final t in bundledStrengthTemplates) {
    if (t.id == subType && t.legacyDescription == sessionNotes?.trim()) {
      return t.build();
    }
  }
  return null;
}
