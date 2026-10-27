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
    this.name,
    this.phase,
    this.focus,
    this.cues,
    this.minutes,
  });

  /// Library metadata of a programme template; null for the original three,
  /// whose library entries are written out by hand.
  final String? name, phase, cues;
  final StrengthFocus? focus;
  final int? minutes;

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
  for (final t in [
    ...bundledStrengthTemplates,
    ...strengthProgrammeTemplates,
  ]) {
    if (t.id == subType && t.legacyDescription == sessionNotes?.trim()) {
      return t.build();
    }
  }
  return null;
}

// ── Goal-driven programme ─────────────────────────────────────────────────
//
// Strength for endurance athletes, by what the race asks of the legs and
// body, periodised with the plan: base builds tolerance with moderate loads
// and more repetitions, build lifts heavy for few repetitions, peak keeps
// strength with power and little volume, taper keeps it with a short
// session. Two sessions per focus (A and B) alternate so the exercises vary
// from session to session. Gym equipment: barbells, dumbbells and machines.
// A Fjelia programming policy, not an individual prescription; loads come
// from the athlete's history, never from here.

enum StrengthFocus {
  run('Runner', 'running'),
  trail('Trail', 'trail and mountain running'),
  bike('Cycling', 'cycling'),
  full('Full-Body', 'whole-body sports');

  const StrengthFocus(this.label, this.forWhat);
  final String label, forWhat;
}

/// The focus for a race: trail for mountain and hilly foot races, the
/// sport's own otherwise.
StrengthFocus strengthFocusFor(String sport, {bool hilly = false}) =>
    switch (sport) {
      'trail_running' || 'hiking' || 'walking' => StrengthFocus.trail,
      'running' => hilly ? StrengthFocus.trail : StrengthFocus.run,
      'cycling_road' ||
      'cycling_gravel' ||
      'cycling_mtb' ||
      'inline_skating' => StrengthFocus.bike,
      _ => StrengthFocus.full,
    };

/// Phases with a programme template; recovery weeks get core and stability.
const strengthProgrammePhases = ['base', 'build', 'peak', 'taper'];

/// The template id for a session: [variant] 0 is A, 1 is B.
String strengthProgrammeId(StrengthFocus focus, String phase, int variant) =>
    'str-${focus.name}-$phase-${variant.isEven ? 'a' : 'b'}';

enum _Role { main, accessory, core }

typedef _Move = (String id, _Role role);

const _programme = <StrengthFocus, (List<_Move>, List<_Move>)>{
  StrengthFocus.run: (
    [
      ('back_squat', _Role.main),
      ('romanian_deadlift', _Role.main),
      ('walking_lunge', _Role.accessory),
      ('calf_raise', _Role.accessory),
      ('plank', _Role.core),
    ],
    [
      ('split_squat', _Role.main),
      ('step_up', _Role.main),
      ('leg_curl', _Role.accessory),
      ('calf_raise', _Role.accessory),
      ('dead_bug', _Role.core),
    ],
  ),
  StrengthFocus.trail: (
    [
      ('back_squat', _Role.main),
      ('romanian_deadlift', _Role.main),
      ('step_up', _Role.accessory),
      ('calf_raise', _Role.accessory),
      ('side_plank', _Role.core),
    ],
    [
      ('split_squat', _Role.main),
      ('step_down', _Role.main),
      ('single_leg_rdl', _Role.accessory),
      ('calf_raise', _Role.accessory),
      ('pallof_press', _Role.core),
    ],
  ),
  StrengthFocus.bike: (
    [
      ('back_squat', _Role.main),
      ('romanian_deadlift', _Role.main),
      ('leg_press', _Role.accessory),
      ('hip_thrust', _Role.accessory),
      ('plank', _Role.core),
    ],
    [
      ('deadlift', _Role.main),
      ('split_squat', _Role.main),
      ('leg_curl', _Role.accessory),
      ('leg_press', _Role.accessory),
      ('dead_bug', _Role.core),
    ],
  ),
  StrengthFocus.full: (
    [
      ('back_squat', _Role.main),
      ('bench_press', _Role.main),
      ('lat_pulldown', _Role.accessory),
      ('barbell_row', _Role.accessory),
      ('plank', _Role.core),
    ],
    [
      ('deadlift', _Role.main),
      ('overhead_press', _Role.main),
      ('pull_up', _Role.accessory),
      ('split_squat', _Role.accessory),
      ('dead_bug', _Role.core),
    ],
  ),
};

/// Sets, repetitions (exact or range, or seconds for holds), rest and
/// intended reps in reserve for a role in a phase.
({int sets, (int, int)? reps, int? seconds, int rest, int? rir}) _dose(
  String phase,
  _Role role,
  bool timed,
) {
  if (role == _Role.core) {
    final sets = phase == 'taper' || phase == 'peak' ? 2 : 3;
    return timed
        ? (
            sets: sets,
            reps: null,
            seconds: phase == 'taper' ? 30 : 40,
            rest: 45,
            rir: null,
          )
        : (sets: sets, reps: (8, 12), seconds: null, rest: 45, rir: null);
  }
  return switch ((phase, role)) {
    ('base', _Role.main) => (
      sets: 3,
      reps: (10, 12),
      seconds: null,
      rest: 90,
      rir: 3,
    ),
    ('base', _) => (sets: 3, reps: (12, 15), seconds: null, rest: 75, rir: 3),
    ('build', _Role.main) => (
      sets: 4,
      reps: (4, 6),
      seconds: null,
      rest: 180,
      rir: 2,
    ),
    ('build', _) => (sets: 3, reps: (6, 8), seconds: null, rest: 120, rir: 2),
    ('peak', _Role.main) => (
      sets: 3,
      reps: (3, 5),
      seconds: null,
      rest: 180,
      rir: 3,
    ),
    ('peak', _) => (sets: 2, reps: (6, 8), seconds: null, rest: 90, rir: 3),
    (_, _) => (sets: 2, reps: (5, 5), seconds: null, rest: 120, rir: 3),
  };
}

/// The moves of a session: all of A or B in base and build; jump squats,
/// the first main lift, the first accessory and core in peak; the two main
/// lifts and core in taper.
List<_Move> _moves(List<_Move> list, String phase) {
  final mains = list.where((m) => m.$2 == _Role.main).toList();
  final acc = list.where((m) => m.$2 == _Role.accessory).toList();
  final core = list.where((m) => m.$2 == _Role.core).toList();
  return switch (phase) {
    'peak' => [('jump_squat', _Role.main), mains.first, acc.first, ...core],
    'taper' => [...mains, ...core],
    _ => list,
  };
}

const _phaseLabel = {
  'base': 'Base',
  'build': 'Build',
  'peak': 'Peak Power',
  'taper': 'Taper Maintenance',
};

const _phaseMinutes = {'base': 50, 'build': 55, 'peak': 40, 'taper': 25};

const _phaseCue = {
  'base': 'Moderate loads, controlled tempo, about three reps in reserve. Build the habit and the tissue tolerance.',
  'build': 'Heavy and few: about two reps in reserve, full rest between sets. Keep it away from the hardest run or ride.',
  'peak':
      'Jumps fast and crisp, lifts heavy but brief. Stop well before fatigue.',
  'taper': 'Short and sharp to keep strength. Nothing new, nothing to failure.',
};

String _doseText(String phase) => switch (phase) {
  'base' => '3 sets × 10–12 reps, moderate load',
  'build' => '4 sets × 4–6 reps, heavy',
  'peak' => 'Jumps plus 3 sets × 3–5 reps, low volume',
  _ => '2 sets × 5 reps, maintenance',
};

final strengthProgrammeTemplates = [
  for (final focus in StrengthFocus.values)
    for (final phase in strengthProgrammePhases)
      for (final variant in const [0, 1])
        _programmeTemplate(focus, phase, variant),
];

BundledStrengthTemplate _programmeTemplate(
  StrengthFocus focus,
  String phase,
  int variant,
) {
  final id = strengthProgrammeId(focus, phase, variant);
  final lists = _programme[focus]!;
  final moves = _moves(variant.isEven ? lists.$1 : lists.$2, phase);
  final letter = variant.isEven ? 'A' : 'B';
  final names = [for (final m in moves) builtInStrengthVariant(m.$1)!.name];
  return BundledStrengthTemplate(
    id: id,
    revision: 1,
    name: '${focus.label} Strength $letter — ${_phaseLabel[phase]}',
    phase: phase,
    focus: focus,
    minutes: _phaseMinutes[phase],
    cues: _phaseCue[phase],
    legacyDescription:
        '${names.join(', ')}. ${_doseText(phase)}. Strength for ${focus.forWhat}.',
    build: () {
      final t = '${id}1';
      return StrengthWorkoutPlan(
        title: '${focus.label} Strength $letter — ${_phaseLabel[phase]}',
        estimatedMinutes: _phaseMinutes[phase],
        template: StrengthTemplateRef(id, 1),
        notes: _phaseCue[phase],
        blocks: [
          for (final m in moves)
            () {
              final v = builtInStrengthVariant(m.$1)!;
              final d = _dose(phase, m.$2, v.timed);
              final power = m.$1 == 'jump_squat';
              final exact = d.reps != null && d.reps!.$1 == d.reps!.$2;
              return _straight(
                _exercise(
                  t,
                  m.$1,
                  sets: d.sets,
                  reps: power ? 5 : (exact ? d.reps!.$1 : null),
                  range: power || exact ? null : d.reps,
                  seconds: d.seconds,
                  rest: power ? 90 : d.rest,
                  tempo: m.$1 == 'step_down' ? '4-0-1-0' : null,
                  effort: power || d.rir == null
                      ? null
                      : StrengthEffort(
                          StrengthEffortScale.rir,
                          d.rir!.toDouble(),
                        ),
                  notes: v.instructions,
                ),
              );
            }(),
        ],
      );
    },
  );
}
