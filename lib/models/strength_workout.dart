import 'dart:math' as math;

/// Strength workouts: exercises and their individual sets, kept apart from
/// the endurance step model. A plan holds targets; a log holds what was
/// actually done. Neither is ever derived from the other without the athlete.

const strengthSchemaVersion = 1;

/// Exact conversion; stored loads are kilograms, the entered unit is kept.
const kgPerLb = 0.45359237;

double lbToKg(double lb) => lb * kgPerLb;
double kgToLb(double kg) => kg / kgPerLb;

enum MassUnit {
  kg,
  lb;

  static MassUnit parse(Object? v) => v == 'lb' ? lb : kg;
  double fromKg(double kg) => this == MassUnit.kg ? kg : kgToLb(kg);
  double toKg(double value) => this == MassUnit.kg ? value : lbToKg(value);
}

/// Normalised sport key: lower case, words joined by underscores.
String _sportKey(String sport) => sport
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9äöüß]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

/// Sport names known to mean lifting. Broad words such as `functional`,
/// `crossfit`, `hiit`, `gym` or anything containing `strength` (a
/// `strength_endurance` ride) are deliberately not on this list.
const strengthSportAliases = {
  'strength',
  'strength_training',
  'strengthtraining',
  'traditional_strength_training',
  'weight_training',
  'weighttraining',
  'weightlifting',
  'weight_lifting',
  'krafttraining',
  'kraft_training',
};

/// Whether a planned or recorded sport is a strength workout (STR-F01).
bool isStrengthSport(String? sport) =>
    sport != null && strengthSportAliases.contains(_sportKey(sport));

enum StrengthSetKind {
  warmup('Warm-up'),
  working('Working'),
  backoff('Back-off'),
  technique('Technique');

  const StrengthSetKind(this.label);
  final String label;
  static StrengthSetKind parse(Object? v) =>
      values.firstWhere((k) => k.name == v, orElse: () => working);
}

/// How the load of an exercise is meant.
enum StrengthLoadKind {
  /// A barbell, dumbbell, machine stack: external load in kg.
  external('External load'),

  /// No load; repetitions or time only.
  bodyweight('Bodyweight'),

  /// External load added to bodyweight (a weighted pull-up).
  added('Added load'),

  /// Assistance, a positive magnitude that makes the movement easier.
  assisted('Assistance'),

  /// Bands and uncalibrated resistance: a description, never kg.
  band('Band / resistance');

  const StrengthLoadKind(this.label);
  final String label;
  static StrengthLoadKind parse(Object? v) =>
      values.firstWhere((k) => k.name == v, orElse: () => external);

  /// Loads that count toward external volume.
  bool get countsVolume => this == external || this == added;
  bool get hasKg => this != bodyweight && this != band;
}

/// What one load number refers to.
enum StrengthLoadBasis {
  total('Total load'),
  perImplement('Per implement'),
  single('One implement');

  const StrengthLoadBasis(this.label);
  final String label;
  static StrengthLoadBasis parse(Object? v) =>
      values.firstWhere((k) => k.name == v, orElse: () => total);
}

enum StrengthSide {
  bilateral('Both sides'),
  unilateral('Reps per side'),
  alternating('Alternating, total reps');

  const StrengthSide(this.label);
  final String label;
  static StrengthSide parse(Object? v) =>
      values.firstWhere((k) => k.name == v, orElse: () => bilateral);
}

enum StrengthSetStatus {
  unrecorded('Not recorded'),
  completed('Done'),
  partial('Partial'),
  failed('Failed'),
  skipped('Skipped');

  const StrengthSetStatus(this.label);
  final String label;
  static StrengthSetStatus parse(Object? v) =>
      values.firstWhere((k) => k.name == v, orElse: () => unrecorded);

  /// A set that was attempted: its recorded repetitions count.
  bool get attempted => this == completed || this == partial || this == failed;
}

enum StrengthBlockKind {
  straight('Straight sets'),
  superset('Superset'),
  circuit('Circuit');

  const StrengthBlockKind(this.label);
  final String label;
  static StrengthBlockKind parse(Object? v) =>
      values.firstWhere((k) => k.name == v, orElse: () => straight);
}

enum StrengthEffortScale {
  rir('RIR'),
  rpe('RPE 1–10');

  const StrengthEffortScale(this.label);
  final String label;
  static StrengthEffortScale? parse(Object? v) =>
      values.where((k) => k.name == v).firstOrNull;
}

/// An effort value on an explicit scale. RIR is a non-negative count (10
/// stands for "10 or more"); RPE runs 1–10 in half steps.
class StrengthEffort {
  const StrengthEffort(this.scale, this.value);
  final StrengthEffortScale scale;
  final double value;

  String? get error => switch (scale) {
    _ when !value.isFinite => 'Effort must be a number.',
    StrengthEffortScale.rir when value < 0 || value > 10 =>
      'RIR runs from 0 to 10+.',
    StrengthEffortScale.rpe when value < 1 || value > 10 =>
      'RPE runs from 1 to 10.',
    _ => null,
  };

  String get text => switch (scale) {
    StrengthEffortScale.rir => 'RIR ${value >= 10 ? '10+' : _trim(value)}',
    StrengthEffortScale.rpe => 'RPE ${_trim(value)}',
  };

  Map<String, dynamic> toJson() => {'scale': scale.name, 'value': value};
  static StrengthEffort? fromJson(Object? j) {
    if (j is! Map) return null;
    final scale = StrengthEffortScale.parse(j['scale']);
    final value = (j['value'] as num?)?.toDouble();
    return scale == null || value == null ? null : StrengthEffort(scale, value);
  }

  @override
  bool operator ==(Object other) =>
      other is StrengthEffort && other.scale == scale && other.value == value;
  @override
  int get hashCode => Object.hash(scale, value);
}

String _trim(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

/// How load and repetitions of one exercise are to be read. Two exercises
/// with different conventions are never compared.
class StrengthConvention {
  const StrengthConvention({
    this.loadKind = StrengthLoadKind.external,
    this.basis = StrengthLoadBasis.total,
    this.implements = 1,
    this.side = StrengthSide.bilateral,
  });
  final StrengthLoadKind loadKind;
  final StrengthLoadBasis basis;

  /// Implements moved at once; 2 for a pair of dumbbells loaded per implement.
  final int implements;
  final StrengthSide side;

  /// Multiplier from one entered load to the external load moved per rep.
  int get loadFactor =>
      basis == StrengthLoadBasis.perImplement ? implements : 1;

  /// Multiplier from entered reps to reps performed (per side → both sides).
  int get repFactor => side == StrengthSide.unilateral ? 2 : 1;

  String get key => '${loadKind.name}/${basis.name}/$implements/${side.name}';

  String get text => [
    loadKind.label,
    if (loadKind.hasKg) basis.label,
    if (basis == StrengthLoadBasis.perImplement) '× $implements',
    if (side != StrengthSide.bilateral) side.label,
  ].join(' · ');

  StrengthConvention copyWith({
    StrengthLoadKind? loadKind,
    StrengthLoadBasis? basis,
    int? implements,
    StrengthSide? side,
  }) => StrengthConvention(
    loadKind: loadKind ?? this.loadKind,
    basis: basis ?? this.basis,
    implements: implements ?? this.implements,
    side: side ?? this.side,
  );

  Map<String, dynamic> toJson() => {
    'loadKind': loadKind.name,
    'basis': basis.name,
    'implements': implements,
    'side': side.name,
  };
  factory StrengthConvention.fromJson(Object? j) {
    if (j is! Map) return const StrengthConvention();
    return StrengthConvention(
      loadKind: StrengthLoadKind.parse(j['loadKind']),
      basis: StrengthLoadBasis.parse(j['basis']),
      implements: (j['implements'] as num?)?.toInt() ?? 1,
      side: StrengthSide.parse(j['side']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StrengthConvention && other.key == key;
  @override
  int get hashCode => key.hashCode;
}

/// A built-in or custom exercise. The id is the movement's history identity;
/// translating or renaming the label never creates a new history.
class StrengthExerciseVariant {
  const StrengthExerciseVariant({
    required this.id,
    required this.name,
    required this.equipment,
    this.convention = const StrengthConvention(),
    this.timed = false,
    this.instructions,
  });
  final String id, name, equipment;
  final StrengthConvention convention;

  /// Usually done for time (a plank) rather than for repetitions.
  final bool timed;
  final String? instructions;
}

const _bodyweight = StrengthConvention(loadKind: StrengthLoadKind.bodyweight);
const _dumbbells = StrengthConvention(
  basis: StrengthLoadBasis.perImplement,
  implements: 2,
);

/// The small searchable built-in list (section 9.1). Ids never change.
const builtInStrengthVariants = [
  StrengthExerciseVariant(
    id: 'back_squat',
    name: 'Back squat',
    equipment: 'Barbell',
  ),
  StrengthExerciseVariant(
    id: 'front_squat',
    name: 'Front squat',
    equipment: 'Barbell',
  ),
  StrengthExerciseVariant(
    id: 'goblet_squat',
    name: 'Goblet squat',
    equipment: 'Dumbbell',
    convention: StrengthConvention(basis: StrengthLoadBasis.single),
  ),
  StrengthExerciseVariant(
    id: 'deadlift',
    name: 'Deadlift',
    equipment: 'Barbell',
  ),
  StrengthExerciseVariant(
    id: 'romanian_deadlift',
    name: 'Romanian deadlift',
    equipment: 'Barbell',
  ),
  StrengthExerciseVariant(
    id: 'bench_press',
    name: 'Bench press',
    equipment: 'Barbell',
  ),
  StrengthExerciseVariant(
    id: 'db_bench_press',
    name: 'Dumbbell bench press',
    equipment: 'Dumbbells',
    convention: _dumbbells,
  ),
  StrengthExerciseVariant(
    id: 'overhead_press',
    name: 'Overhead press',
    equipment: 'Barbell',
  ),
  StrengthExerciseVariant(
    id: 'barbell_row',
    name: 'Barbell row',
    equipment: 'Barbell',
  ),
  StrengthExerciseVariant(
    id: 'db_row',
    name: 'One-arm dumbbell row',
    equipment: 'Dumbbell',
    convention: StrengthConvention(
      basis: StrengthLoadBasis.single,
      side: StrengthSide.unilateral,
    ),
  ),
  StrengthExerciseVariant(
    id: 'pull_up',
    name: 'Pull-up',
    equipment: 'Bar',
    convention: _bodyweight,
  ),
  StrengthExerciseVariant(
    id: 'push_up',
    name: 'Push-up',
    equipment: 'Bodyweight',
    convention: _bodyweight,
  ),
  StrengthExerciseVariant(
    id: 'walking_lunge',
    name: 'Walking lunge',
    equipment: 'Dumbbells',
    convention: StrengthConvention(
      basis: StrengthLoadBasis.perImplement,
      implements: 2,
      side: StrengthSide.alternating,
    ),
  ),
  StrengthExerciseVariant(
    id: 'split_squat',
    name: 'Bulgarian split squat',
    equipment: 'Dumbbells',
    convention: StrengthConvention(
      basis: StrengthLoadBasis.perImplement,
      implements: 2,
      side: StrengthSide.unilateral,
    ),
  ),
  StrengthExerciseVariant(
    id: 'calf_raise',
    name: 'Calf raise',
    equipment: 'Machine',
  ),
  StrengthExerciseVariant(
    id: 'leg_press',
    name: 'Leg press',
    equipment: 'Machine',
  ),
  StrengthExerciseVariant(
    id: 'barbell_curl',
    name: 'Barbell curl',
    equipment: 'Barbell',
  ),
  StrengthExerciseVariant(
    id: 'hip_thrust',
    name: 'Hip thrust',
    equipment: 'Barbell',
  ),
  StrengthExerciseVariant(
    id: 'step_up',
    name: 'Step-up',
    equipment: 'Dumbbells',
    convention: StrengthConvention(
      basis: StrengthLoadBasis.perImplement,
      implements: 2,
      side: StrengthSide.unilateral,
    ),
  ),
  StrengthExerciseVariant(
    id: 'single_leg_rdl',
    name: 'Single-leg Romanian deadlift',
    equipment: 'Dumbbell',
    convention: StrengthConvention(
      basis: StrengthLoadBasis.single,
      side: StrengthSide.unilateral,
    ),
  ),
  StrengthExerciseVariant(
    id: 'step_down',
    name: 'Eccentric step-down',
    equipment: 'Dumbbells',
    convention: StrengthConvention(
      basis: StrengthLoadBasis.perImplement,
      implements: 2,
      side: StrengthSide.unilateral,
    ),
    instructions: 'Lower the free heel to the floor over four seconds.',
  ),
  StrengthExerciseVariant(
    id: 'leg_curl',
    name: 'Leg curl',
    equipment: 'Machine',
  ),
  StrengthExerciseVariant(
    id: 'lat_pulldown',
    name: 'Lat pulldown',
    equipment: 'Cable machine',
  ),
  StrengthExerciseVariant(
    id: 'jump_squat',
    name: 'Jump squat',
    equipment: 'Bodyweight',
    convention: _bodyweight,
  ),
  StrengthExerciseVariant(
    id: 'plank',
    name: 'Plank',
    equipment: 'Bodyweight',
    convention: _bodyweight,
    timed: true,
  ),
  StrengthExerciseVariant(
    id: 'side_plank',
    name: 'Side plank',
    equipment: 'Bodyweight',
    convention: StrengthConvention(
      loadKind: StrengthLoadKind.bodyweight,
      side: StrengthSide.unilateral,
    ),
    timed: true,
  ),
  StrengthExerciseVariant(
    id: 'dead_bug',
    name: 'Dead bug',
    equipment: 'Bodyweight',
    convention: StrengthConvention(
      loadKind: StrengthLoadKind.bodyweight,
      side: StrengthSide.alternating,
    ),
  ),
  StrengthExerciseVariant(
    id: 'bird_dog',
    name: 'Bird dog',
    equipment: 'Bodyweight',
    convention: StrengthConvention(
      loadKind: StrengthLoadKind.bodyweight,
      side: StrengthSide.unilateral,
    ),
  ),
  StrengthExerciseVariant(
    id: 'pallof_press',
    name: 'Pallof press',
    equipment: 'Band',
    convention: StrengthConvention(
      loadKind: StrengthLoadKind.band,
      side: StrengthSide.unilateral,
    ),
  ),
];

StrengthExerciseVariant? builtInStrengthVariant(String id) =>
    builtInStrengthVariants.where((v) => v.id == id).firstOrNull;

/// Validation failure with a message fit for the athlete.
class StrengthValidationException implements Exception {
  StrengthValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Stable unique ids for sets, exercises and blocks. Ids stay when items are
/// reordered and are newly made when items are duplicated.
String newStrengthId([String prefix = 's']) {
  final r = math.Random.secure();
  final hex = List.generate(
    12,
    (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '$prefix-$hex';
}

/// Loads a load value: a finite kg magnitude plus the unit it was entered in.
/// Converting for display never rewrites the stored kilograms.
class StrengthLoad {
  const StrengthLoad(this.kg, {this.unit = MassUnit.kg});
  factory StrengthLoad.entered(double value, MassUnit unit) =>
      StrengthLoad(unit.toKg(value), unit: unit);
  final double kg;
  final MassUnit unit;

  Map<String, dynamic> toJson() => {'kg': kg, 'unit': unit.name};
  static StrengthLoad? fromJson(Object? j) {
    if (j is num) return StrengthLoad(j.toDouble());
    if (j is! Map) return null;
    final kg = (j['kg'] as num?)?.toDouble();
    return kg == null
        ? null
        : StrengthLoad(kg, unit: MassUnit.parse(j['unit']));
  }

  @override
  bool operator ==(Object other) =>
      other is StrengthLoad && other.kg == kg && other.unit == unit;
  @override
  int get hashCode => Object.hash(kg, unit);
}

/// One planned set: exact reps, a rep range or timed work.
class StrengthSetTarget {
  const StrengthSetTarget({
    required this.id,
    this.kind = StrengthSetKind.working,
    this.reps,
    this.repMin,
    this.repMax,
    this.durationSeconds,
    this.load,
    this.resistance,
    this.restSeconds,
    this.tempo,
    this.effort,
    this.notes,
  });
  final String id;
  final StrengthSetKind kind;
  final int? reps, repMin, repMax, durationSeconds, restSeconds;
  final StrengthLoad? load;

  /// Band colour or machine setting where no kg exist.
  final String? resistance;
  final String? tempo;
  final StrengthEffort? effort;
  final String? notes;

  bool get timed => durationSeconds != null;
  bool get isRange => reps == null && repMin != null && repMax != null;

  /// Lowest and highest repetitions, null for timed work.
  (int, int)? get repBounds => reps != null
      ? (reps!, reps!)
      : repMin != null && repMax != null
      ? (repMin!, repMax!)
      : null;

  String get repsText => timed
      ? formatStrengthSeconds(durationSeconds!)
      : reps != null
      ? '$reps'
      : isRange
      ? '$repMin–$repMax'
      : '—';

  StrengthSetTarget copyWith({
    String? id,
    StrengthSetKind? kind,
    int? Function()? reps,
    int? Function()? repMin,
    int? Function()? repMax,
    int? Function()? durationSeconds,
    StrengthLoad? Function()? load,
    String? Function()? resistance,
    int? Function()? restSeconds,
    String? Function()? tempo,
    StrengthEffort? Function()? effort,
    String? Function()? notes,
  }) => StrengthSetTarget(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    reps: reps == null ? this.reps : reps(),
    repMin: repMin == null ? this.repMin : repMin(),
    repMax: repMax == null ? this.repMax : repMax(),
    durationSeconds: durationSeconds == null
        ? this.durationSeconds
        : durationSeconds(),
    load: load == null ? this.load : load(),
    resistance: resistance == null ? this.resistance : resistance(),
    restSeconds: restSeconds == null ? this.restSeconds : restSeconds(),
    tempo: tempo == null ? this.tempo : tempo(),
    effort: effort == null ? this.effort : effort(),
    notes: notes == null ? this.notes : notes(),
  );

  List<String> validate(StrengthConvention c) => [
    if (reps != null && reps! < 0) 'Repetitions cannot be negative.',
    if ((repMin ?? 0) < 0 || (repMax ?? 0) < 0)
      'Repetitions cannot be negative.',
    if ((repMin == null) != (repMax == null))
      'A rep range needs a lowest and a highest value.',
    if (repMin != null && repMax != null && repMin! > repMax!)
      'The rep range is inverted.',
    if (reps != null && repMin != null)
      'Use either exact repetitions or a range.',
    if (durationSeconds != null && durationSeconds! <= 0)
      'Timed work must be longer than zero seconds.',
    if (durationSeconds != null && (reps != null || repMin != null))
      'Choose repetitions or timed work, not both.',
    if (kind != StrengthSetKind.warmup &&
        durationSeconds == null &&
        reps == null &&
        repMin == null)
      'A working set needs repetitions, a range or a duration.',
    if (restSeconds != null && restSeconds! < 0) 'Rest cannot be negative.',
    if (load != null && (!load!.kg.isFinite || load!.kg < 0))
      'Load must be a finite, non-negative number.',
    if (load != null && !c.loadKind.hasKg)
      '${c.loadKind.label} has no kg load.',
    if (tempo != null && !validTempo(tempo!))
      'Tempo has four phases, such as 3-1-1-0.',
    ?effort?.error,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    if (reps != null) 'reps': reps,
    if (repMin != null) 'repMin': repMin,
    if (repMax != null) 'repMax': repMax,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (load != null) 'load': load!.toJson(),
    if (resistance != null) 'resistance': resistance,
    if (restSeconds != null) 'restSeconds': restSeconds,
    if (tempo != null) 'tempo': tempo,
    if (effort != null) 'effort': effort!.toJson(),
    if (notes != null) 'notes': notes,
  };

  factory StrengthSetTarget.fromJson(Map j) => StrengthSetTarget(
    id: _id(j),
    kind: StrengthSetKind.parse(j['kind']),
    reps: _int(j['reps']),
    repMin: _int(j['repMin']),
    repMax: _int(j['repMax']),
    durationSeconds: _int(j['durationSeconds']),
    load: StrengthLoad.fromJson(j['load']),
    resistance: j['resistance'] as String?,
    restSeconds: _int(j['restSeconds']),
    tempo: j['tempo'] as String?,
    effort: StrengthEffort.fromJson(j['effort']),
    notes: j['notes'] as String?,
  );
}

bool validTempo(String tempo) =>
    RegExp(r'^([0-9]{1,2}|X)-([0-9]{1,2}|X)-([0-9]{1,2}|X)-([0-9]{1,2}|X)$')
        .hasMatch(tempo.trim().toUpperCase());

String _id(Map j) {
  final id = j['id'];
  if (id is! String || id.isEmpty) {
    throw const FormatException('Strength item without an id.');
  }
  return id;
}

int? _int(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num && v.isFinite && v == v.roundToDouble()) return v.toInt();
  throw FormatException('Expected a whole number, got $v.');
}

class StrengthPlannedExercise {
  const StrengthPlannedExercise({
    required this.id,
    required this.variantId,
    required this.name,
    required this.equipment,
    this.convention = const StrengthConvention(),
    this.notes,
    this.sets = const [],
  });
  final String id, variantId, name, equipment;
  final StrengthConvention convention;
  final String? notes;
  final List<StrengthSetTarget> sets;

  /// Comparable history context: movement, equipment and convention.
  String get contextKey => strengthContextKey(variantId, equipment, convention);

  StrengthPlannedExercise copyWith({
    String? id,
    String? variantId,
    String? name,
    String? equipment,
    StrengthConvention? convention,
    String? Function()? notes,
    List<StrengthSetTarget>? sets,
  }) => StrengthPlannedExercise(
    id: id ?? this.id,
    variantId: variantId ?? this.variantId,
    name: name ?? this.name,
    equipment: equipment ?? this.equipment,
    convention: convention ?? this.convention,
    notes: notes == null ? this.notes : notes(),
    sets: sets ?? this.sets,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'variantId': variantId,
    'name': name,
    'equipment': equipment,
    'convention': convention.toJson(),
    if (notes != null) 'notes': notes,
    'sets': [for (final s in sets) s.toJson()],
  };
  factory StrengthPlannedExercise.fromJson(Map j) => StrengthPlannedExercise(
    id: _id(j),
    variantId: j['variantId'] as String,
    name: j['name'] as String,
    equipment: j['equipment'] as String? ?? '',
    convention: StrengthConvention.fromJson(j['convention']),
    notes: j['notes'] as String?,
    sets: [
      for (final s in (j['sets'] as List? ?? const []).cast<Map>())
        StrengthSetTarget.fromJson(s),
    ],
  );
}

String strengthContextKey(
  String variantId,
  String equipment,
  StrengthConvention c,
) => '$variantId|${equipment.trim().toLowerCase()}|${c.key}';

/// Straight sets, or a superset/circuit done in rounds. For a group, set `i`
/// of each exercise belongs to round `i + 1`.
class StrengthBlock {
  const StrengthBlock({
    required this.id,
    this.kind = StrengthBlockKind.straight,
    this.exercises = const [],
    this.restBetweenExercisesSeconds,
    this.restBetweenRoundsSeconds,
  });
  final String id;
  final StrengthBlockKind kind;
  final List<StrengthPlannedExercise> exercises;

  /// Group rests; they replace set rests inside the group.
  final int? restBetweenExercisesSeconds, restBetweenRoundsSeconds;

  bool get grouped => kind != StrengthBlockKind.straight;
  int get rounds =>
      grouped ? exercises.fold(0, (m, e) => math.max(m, e.sets.length)) : 1;

  StrengthBlock copyWith({
    String? id,
    StrengthBlockKind? kind,
    List<StrengthPlannedExercise>? exercises,
    int? Function()? restBetweenExercisesSeconds,
    int? Function()? restBetweenRoundsSeconds,
  }) => StrengthBlock(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    exercises: exercises ?? this.exercises,
    restBetweenExercisesSeconds: restBetweenExercisesSeconds == null
        ? this.restBetweenExercisesSeconds
        : restBetweenExercisesSeconds(),
    restBetweenRoundsSeconds: restBetweenRoundsSeconds == null
        ? this.restBetweenRoundsSeconds
        : restBetweenRoundsSeconds(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    if (restBetweenExercisesSeconds != null)
      'restBetweenExercisesSeconds': restBetweenExercisesSeconds,
    if (restBetweenRoundsSeconds != null)
      'restBetweenRoundsSeconds': restBetweenRoundsSeconds,
    'exercises': [for (final e in exercises) e.toJson()],
  };
  factory StrengthBlock.fromJson(Map j) => StrengthBlock(
    id: _id(j),
    kind: StrengthBlockKind.parse(j['kind']),
    restBetweenExercisesSeconds: _int(j['restBetweenExercisesSeconds']),
    restBetweenRoundsSeconds: _int(j['restBetweenRoundsSeconds']),
    exercises: [
      for (final e in (j['exercises'] as List? ?? const []).cast<Map>())
        StrengthPlannedExercise.fromJson(e),
    ],
  );
}

/// Where a plan came from: a bundled template id and its revision.
class StrengthTemplateRef {
  const StrengthTemplateRef(this.id, this.revision);
  final String id;
  final int revision;
  Map<String, dynamic> toJson() => {'id': id, 'revision': revision};
  static StrengthTemplateRef? fromJson(Object? j) => j is Map
      ? StrengthTemplateRef(j['id'] as String, _int(j['revision']) ?? 1)
      : null;
}

/// A planned strength workout: ordered blocks of exercises and their sets.
/// Saved as immutable revisions; editing makes a new revision.
class StrengthWorkoutPlan {
  const StrengthWorkoutPlan({
    this.schemaVersion = strengthSchemaVersion,
    this.title,
    this.notes,
    this.estimatedMinutes,
    this.blocks = const [],
    this.template,
  });
  final int schemaVersion;
  final String? title, notes;

  /// An explicit duration estimate, used where a calculation is unjustified.
  final int? estimatedMinutes;
  final List<StrengthBlock> blocks;
  final StrengthTemplateRef? template;

  Iterable<StrengthPlannedExercise> get exercises =>
      blocks.expand((b) => b.exercises);
  bool get isEmpty => exercises.isEmpty;

  StrengthPlannedExercise? exercise(String id) =>
      exercises.where((e) => e.id == id).firstOrNull;

  StrengthBlock? blockOf(String exerciseId) => blocks
      .where((b) => b.exercises.any((e) => e.id == exerciseId))
      .firstOrNull;

  StrengthWorkoutPlan copyWith({
    String? Function()? title,
    String? Function()? notes,
    int? Function()? estimatedMinutes,
    List<StrengthBlock>? blocks,
    StrengthTemplateRef? Function()? template,
  }) => StrengthWorkoutPlan(
    schemaVersion: schemaVersion,
    title: title == null ? this.title : title(),
    notes: notes == null ? this.notes : notes(),
    estimatedMinutes: estimatedMinutes == null
        ? this.estimatedMinutes
        : estimatedMinutes(),
    blocks: blocks ?? this.blocks,
    template: template == null ? this.template : template(),
  );

  /// Every problem that keeps the plan from being saved.
  List<String> validate() {
    final errors = <String>[];
    final ids = <String>{};
    void unique(String id) {
      if (!ids.add(id)) errors.add('Duplicate id $id.');
    }

    if (estimatedMinutes != null && estimatedMinutes! <= 0) {
      errors.add('The duration estimate must be positive.');
    }
    for (final b in blocks) {
      unique(b.id);
      if (b.exercises.isEmpty) errors.add('A group has no exercises.');
      if (b.kind == StrengthBlockKind.straight && b.exercises.length > 1) {
        errors.add('Straight sets hold a single exercise.');
      }
      for (final r in [
        b.restBetweenExercisesSeconds,
        b.restBetweenRoundsSeconds,
      ]) {
        if (r != null && r < 0) errors.add('Rest cannot be negative.');
      }
      for (final e in b.exercises) {
        unique(e.id);
        if (e.name.trim().isEmpty) errors.add('An exercise has no name.');
        if (e.sets.isEmpty) errors.add('${e.name} has no sets.');
        if (e.convention.implements < 1) {
          errors.add('${e.name}: at least one implement.');
        }
        for (final s in e.sets) {
          unique(s.id);
          for (final m in s.validate(e.convention)) {
            errors.add('${e.name}: $m');
          }
        }
      }
    }
    return errors;
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    if (title != null) 'title': title,
    if (notes != null) 'notes': notes,
    if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
    if (template != null) 'template': template!.toJson(),
    'blocks': [for (final b in blocks) b.toJson()],
  };

  /// Throws [FormatException] for malformed or future documents; callers keep
  /// the stored data untouched and show the fallback.
  factory StrengthWorkoutPlan.fromJson(Map j) {
    final version = _int(j['schemaVersion']) ?? 1;
    if (version > strengthSchemaVersion) {
      throw FormatException(
        'Strength plan schema $version is newer than this app.',
      );
    }
    try {
      return StrengthWorkoutPlan(
        schemaVersion: version,
        title: j['title'] as String?,
        notes: j['notes'] as String?,
        estimatedMinutes: _int(j['estimatedMinutes']),
        template: StrengthTemplateRef.fromJson(j['template']),
        blocks: [
          for (final b in (j['blocks'] as List? ?? const []).cast<Map>())
            StrengthBlock.fromJson(b),
        ],
      );
    } on TypeError catch (e) {
      throw FormatException('Malformed strength plan: $e');
    }
  }
}

/// Where one recorded value came from.
enum StrengthOrigin {
  manual,

  /// Copied from the plan by an explicit "completed as planned".
  plan,
  imported,
  timer;

  static StrengthOrigin parse(Object? v) =>
      values.firstWhere((k) => k.name == v, orElse: () => manual);
}

/// One performed set. Every value is nullable: unknown is not zero.
class StrengthSetResult {
  const StrengthSetResult({
    required this.id,
    this.plannedSetId,
    this.kind = StrengthSetKind.working,
    this.status = StrengthSetStatus.unrecorded,
    this.reps,
    this.durationSeconds,
    this.load,
    this.resistance,
    this.restSeconds,
    this.restOrigin,
    this.effort,
    this.notes,
    this.origins = const {},
  });
  final String id;
  final String? plannedSetId;
  final StrengthSetKind kind;
  final StrengthSetStatus status;
  final int? reps, durationSeconds, restSeconds;
  final StrengthLoad? load;
  final String? resistance;

  /// How the rest was measured; planned rest is never stored here.
  final StrengthOrigin? restOrigin;
  final StrengthEffort? effort;
  final String? notes;

  /// Field name → origin, for merge and correction.
  final Map<String, StrengthOrigin> origins;

  StrengthSetResult copyWith({
    String? id,
    String? Function()? plannedSetId,
    StrengthSetKind? kind,
    StrengthSetStatus? status,
    int? Function()? reps,
    int? Function()? durationSeconds,
    StrengthLoad? Function()? load,
    String? Function()? resistance,
    int? Function()? restSeconds,
    StrengthOrigin? Function()? restOrigin,
    StrengthEffort? Function()? effort,
    String? Function()? notes,
    Map<String, StrengthOrigin>? origins,
  }) => StrengthSetResult(
    id: id ?? this.id,
    plannedSetId: plannedSetId == null ? this.plannedSetId : plannedSetId(),
    kind: kind ?? this.kind,
    status: status ?? this.status,
    reps: reps == null ? this.reps : reps(),
    durationSeconds: durationSeconds == null
        ? this.durationSeconds
        : durationSeconds(),
    load: load == null ? this.load : load(),
    resistance: resistance == null ? this.resistance : resistance(),
    restSeconds: restSeconds == null ? this.restSeconds : restSeconds(),
    restOrigin: restOrigin == null ? this.restOrigin : restOrigin(),
    effort: effort == null ? this.effort : effort(),
    notes: notes == null ? this.notes : notes(),
    origins: origins ?? this.origins,
  );

  List<String> validate(StrengthConvention c) => [
    if (reps != null && reps! < 0) 'Repetitions cannot be negative.',
    if (durationSeconds != null && durationSeconds! < 0)
      'Duration cannot be negative.',
    if (restSeconds != null && restSeconds! < 0) 'Rest cannot be negative.',
    if (restSeconds != null && restOrigin == null)
      'Recorded rest needs its source.',
    if (load != null && (!load!.kg.isFinite || load!.kg < 0))
      'Load must be a finite, non-negative number.',
    if (load != null && !c.loadKind.hasKg)
      '${c.loadKind.label} has no kg load.',
    ?effort?.error,
    if (status == StrengthSetStatus.skipped &&
        (reps ?? 0) + (durationSeconds ?? 0) > 0)
      'A skipped set has no repetitions or time.',
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    if (plannedSetId != null) 'plannedSetId': plannedSetId,
    'kind': kind.name,
    'status': status.name,
    if (reps != null) 'reps': reps,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (load != null) 'load': load!.toJson(),
    if (resistance != null) 'resistance': resistance,
    if (restSeconds != null) 'restSeconds': restSeconds,
    if (restOrigin != null) 'restOrigin': restOrigin!.name,
    if (effort != null) 'effort': effort!.toJson(),
    if (notes != null) 'notes': notes,
    if (origins.isNotEmpty)
      'origins': {for (final e in origins.entries) e.key: e.value.name},
  };
  factory StrengthSetResult.fromJson(Map j) => StrengthSetResult(
    id: _id(j),
    plannedSetId: j['plannedSetId'] as String?,
    kind: StrengthSetKind.parse(j['kind']),
    status: StrengthSetStatus.parse(j['status']),
    reps: _int(j['reps']),
    durationSeconds: _int(j['durationSeconds']),
    load: StrengthLoad.fromJson(j['load']),
    resistance: j['resistance'] as String?,
    restSeconds: _int(j['restSeconds']),
    restOrigin: j['restOrigin'] == null
        ? null
        : StrengthOrigin.parse(j['restOrigin']),
    effort: StrengthEffort.fromJson(j['effort']),
    notes: j['notes'] as String?,
    origins: {
      for (final e in ((j['origins'] as Map?) ?? const {}).entries)
        e.key as String: StrengthOrigin.parse(e.value),
    },
  );
}

class StrengthPerformedExercise {
  const StrengthPerformedExercise({
    required this.id,
    required this.variantId,
    required this.name,
    required this.equipment,
    this.convention = const StrengthConvention(),
    this.plannedExerciseId,
    this.notes,
    this.sets = const [],
  });
  final String id, variantId, name, equipment;
  final StrengthConvention convention;
  final String? plannedExerciseId, notes;
  final List<StrengthSetResult> sets;

  String get contextKey => strengthContextKey(variantId, equipment, convention);

  StrengthPerformedExercise copyWith({
    String? id,
    String? variantId,
    String? name,
    String? equipment,
    StrengthConvention? convention,
    String? Function()? plannedExerciseId,
    String? Function()? notes,
    List<StrengthSetResult>? sets,
  }) => StrengthPerformedExercise(
    id: id ?? this.id,
    variantId: variantId ?? this.variantId,
    name: name ?? this.name,
    equipment: equipment ?? this.equipment,
    convention: convention ?? this.convention,
    plannedExerciseId: plannedExerciseId == null
        ? this.plannedExerciseId
        : plannedExerciseId(),
    notes: notes == null ? this.notes : notes(),
    sets: sets ?? this.sets,
  );
}

enum StrengthLogStatus {
  draft,
  finished;

  static StrengthLogStatus parse(Object? v) =>
      v == 'finished' ? finished : draft;
}

/// The plan a log is compared with, frozen into the log so later template
/// edits or a retired plan cannot change the comparison.
class StrengthPlanBaseline {
  const StrengthPlanBaseline({
    required this.ownerKind,
    required this.ownerKey,
    required this.revisionId,
    required this.plan,
    this.retrospective = false,
  });
  final String ownerKind, ownerKey, revisionId;
  final StrengthWorkoutPlan plan;

  /// Chosen after the workout, not the prescription seen beforehand.
  final bool retrospective;

  Map<String, dynamic> toJson() => {
    'ownerKind': ownerKind,
    'ownerKey': ownerKey,
    'revisionId': revisionId,
    'retrospective': retrospective,
    'plan': plan.toJson(),
  };
  factory StrengthPlanBaseline.fromJson(Map j) => StrengthPlanBaseline(
    ownerKind: j['ownerKind'] as String,
    ownerKey: j['ownerKey'] as String,
    revisionId: j['revisionId'] as String,
    retrospective: j['retrospective'] == true,
    plan: StrengthWorkoutPlan.fromJson(j['plan'] as Map),
  );
}

/// What was actually done in one recorded activity.
class StrengthActivityLog {
  const StrengthActivityLog({
    required this.activityId,
    this.revision = 0,
    this.status = StrengthLogStatus.draft,
    this.incompleteAcknowledged = false,
    this.baseline,
    this.exercises = const [],
    this.notes,
  });
  final String activityId;

  /// Stored revision; 0 for a log not saved yet.
  final int revision;
  final StrengthLogStatus status;

  /// Finished with fields still unknown, acknowledged by the athlete.
  final bool incompleteAcknowledged;
  final StrengthPlanBaseline? baseline;
  final List<StrengthPerformedExercise> exercises;
  final String? notes;

  bool get isEmpty => exercises.isEmpty;
  Iterable<StrengthSetResult> get sets => exercises.expand((e) => e.sets);

  /// Recorded sets missing a value they need.
  int get unrecordedSets =>
      sets.where((s) => s.status == StrengthSetStatus.unrecorded).length;

  StrengthActivityLog copyWith({
    int? revision,
    StrengthLogStatus? status,
    bool? incompleteAcknowledged,
    StrengthPlanBaseline? Function()? baseline,
    List<StrengthPerformedExercise>? exercises,
    String? Function()? notes,
  }) => StrengthActivityLog(
    activityId: activityId,
    revision: revision ?? this.revision,
    status: status ?? this.status,
    incompleteAcknowledged:
        incompleteAcknowledged ?? this.incompleteAcknowledged,
    baseline: baseline == null ? this.baseline : baseline(),
    exercises: exercises ?? this.exercises,
    notes: notes == null ? this.notes : notes(),
  );

  List<String> validate() {
    final errors = <String>[];
    final ids = <String>{};
    for (final e in exercises) {
      if (!ids.add(e.id)) errors.add('Duplicate id ${e.id}.');
      if (e.name.trim().isEmpty) errors.add('An exercise has no name.');
      for (final s in e.sets) {
        if (!ids.add(s.id)) errors.add('Duplicate id ${s.id}.');
        for (final m in s.validate(e.convention)) {
          errors.add('${e.name}: $m');
        }
      }
    }
    if (status == StrengthLogStatus.finished &&
        unrecordedSets > 0 &&
        !incompleteAcknowledged) {
      errors.add(
        '$unrecordedSets ${unrecordedSets == 1 ? 'set is' : 'sets are'} '
        'not recorded. Confirm to finish with incomplete data.',
      );
    }
    return errors;
  }
}

/// Starts a log layout from a plan. Planned values stay targets: every set
/// is unrecorded and carries no actual value.
List<StrengthPerformedExercise> logLayoutFromPlan(StrengthWorkoutPlan plan) => [
  for (final e in plan.exercises)
    StrengthPerformedExercise(
      id: newStrengthId('pe'),
      variantId: e.variantId,
      name: e.name,
      equipment: e.equipment,
      convention: e.convention,
      plannedExerciseId: e.id,
      sets: [
        for (final s in e.sets)
          StrengthSetResult(
            id: newStrengthId('ps'),
            plannedSetId: s.id,
            kind: s.kind,
          ),
      ],
    ),
];

/// Why a set cannot be completed as planned, or null when it can: exact
/// repetitions or a duration, and a known load where the exercise has one.
String? completeAsPlannedBlocker(
  StrengthSetTarget target,
  StrengthConvention c,
) {
  if (target.isRange) {
    return 'Enter the repetitions done; the plan has a range.';
  }
  if (target.reps == null && target.durationSeconds == null) {
    return 'The plan has no repetitions for this set.';
  }
  if (c.loadKind.hasKg && target.load == null) {
    return 'Enter the load; the plan has none.';
  }
  if (c.loadKind == StrengthLoadKind.band && target.resistance == null) {
    return 'Enter the resistance; the plan has none.';
  }
  return null;
}

/// The set recorded exactly as planned. Planned rest is not copied: it was
/// not measured.
StrengthSetResult completedAsPlanned(
  StrengthSetResult result,
  StrengthSetTarget target,
  StrengthConvention c,
) {
  final blocker = completeAsPlannedBlocker(target, c);
  if (blocker != null) throw StrengthValidationException(blocker);
  return result.copyWith(
    status: StrengthSetStatus.completed,
    reps: () => target.reps,
    durationSeconds: () => target.durationSeconds,
    load: () => target.load,
    resistance: () => target.resistance,
    origins: {
      ...result.origins,
      'status': StrengthOrigin.plan,
      if (target.reps != null) 'reps': StrengthOrigin.plan,
      if (target.durationSeconds != null)
        'durationSeconds': StrengthOrigin.plan,
      if (target.load != null) 'load': StrengthOrigin.plan,
      if (target.resistance != null) 'resistance': StrengthOrigin.plan,
    },
  );
}

String formatStrengthSeconds(int seconds) {
  if (seconds < 60) return '$seconds s';
  final m = seconds ~/ 60, s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// "70 kg", "154.5 lb": rounded for display only.
String formatStrengthLoad(double kg, MassUnit unit) {
  final v = unit.fromKg(kg);
  final rounded = (v * 10).round() / 10;
  return '${_trim(rounded)} ${unit.name}';
}

String formatStrengthNumber(double v) {
  final r = v.round();
  final s = r.abs().toString();
  final grouped = s.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return r < 0 ? '-$grouped' : grouped;
}
