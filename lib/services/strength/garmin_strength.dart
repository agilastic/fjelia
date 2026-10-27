import '../../models/strength_workout.dart';

/// Garmin Connect strength workouts and recorded exercise sets.
///
/// Garmin names exercises by FIT category and exercise name. Only the
/// built-in exercises below are mapped; anything else goes up as a plain
/// step named in its description, and comes back as an exercise of its own.
/// The names follow the FIT SDK's exercise lists; Garmin may reject one, in
/// which case the upload is retried without names (see
/// [withoutGarminExerciseNames]).

const garminExercises = <String, (String, String)>{
  'back_squat': ('SQUAT', 'BARBELL_BACK_SQUAT'),
  'front_squat': ('SQUAT', 'BARBELL_FRONT_SQUAT'),
  'goblet_squat': ('SQUAT', 'GOBLET_SQUAT'),
  'leg_press': ('SQUAT', 'LEG_PRESS'),
  'deadlift': ('DEADLIFT', 'BARBELL_DEADLIFT'),
  'romanian_deadlift': ('DEADLIFT', 'ROMANIAN_DEADLIFT'),
  'bench_press': ('BENCH_PRESS', 'BARBELL_BENCH_PRESS'),
  'db_bench_press': ('BENCH_PRESS', 'DUMBBELL_BENCH_PRESS'),
  'overhead_press': ('SHOULDER_PRESS', 'OVERHEAD_BARBELL_PRESS'),
  'barbell_row': ('ROW', 'BARBELL_ROW'),
  'db_row': ('ROW', 'DUMBBELL_ROW'),
  'pull_up': ('PULL_UP', 'PULL_UP'),
  'push_up': ('PUSH_UP', 'PUSH_UP'),
  'walking_lunge': ('LUNGE', 'WALKING_LUNGE'),
  'split_squat': ('LUNGE', 'DUMBBELL_BULGARIAN_SPLIT_SQUAT'),
  'calf_raise': ('CALF_RAISE', 'STANDING_CALF_RAISE'),
  'barbell_curl': ('CURL', 'BARBELL_BICEPS_CURL'),
  'hip_thrust': ('HIP_RAISE', 'BARBELL_HIP_THRUST_WITH_BENCH'),
  'plank': ('PLANK', 'PLANK'),
  'side_plank': ('PLANK', 'SIDE_PLANK'),
  'dead_bug': ('HIP_STABILITY', 'DEAD_BUG'),
};

/// The built-in exercise for a Garmin category and name, if mapped.
String? variantForGarmin(String? category, String? name) {
  for (final e in garminExercises.entries) {
    if (e.value.$1 == category && e.value.$2 == name) return e.key;
  }
  return null;
}

String _humanise(String key) {
  final words = key.toLowerCase().split('_').where((w) => w.isNotEmpty);
  final text = words.join(' ');
  return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}

/// A Garmin strength workout and what it leaves out.
class GarminStrengthPayload {
  const GarminStrengthPayload(this.steps, this.omitted);
  final List<Map<String, dynamic>> steps;

  /// Prescription details Garmin cannot hold; they stay in Fjelia.
  final List<String> omitted;
}

Map<String, dynamic> _rest(int seconds) => {
  'type': 'ExecutableStepDTO',
  'stepType': {'stepTypeId': 5, 'stepTypeKey': 'rest'},
  'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
  'endConditionValue': seconds,
  'targetType': {'workoutTargetTypeId': 1, 'workoutTargetTypeKey': 'no.target'},
};

/// One set as a Garmin step. Exact reps end on the rep count, timed work on
/// time; a rep range ends on the lap button with the range in the
/// description, so no single number is claimed as the target.
Map<String, dynamic> _set(
  StrengthPlannedExercise e,
  StrengthSetTarget s,
  Set<String> omitted,
) {
  final garmin = garminExercises[e.variantId];
  final c = e.convention;
  final notes = <String>[
    e.name,
    if (s.isRange) '${s.repMin}–${s.repMax} reps',
    if (c.side == StrengthSide.unilateral) 'reps per side',
    if (c.basis == StrengthLoadBasis.perImplement) 'load per implement',
    if (c.loadKind == StrengthLoadKind.assisted && s.load != null)
      'assistance ${formatStrengthLoad(s.load!.kg, MassUnit.kg)}',
    if (c.loadKind == StrengthLoadKind.band && s.resistance != null)
      s.resistance!,
    if (s.effort != null) s.effort!.text,
    if (s.tempo != null) 'tempo ${s.tempo}',
  ];
  if (s.isRange) omitted.add('rep ranges (the set ends on the lap button)');
  if (s.effort != null) omitted.add('effort targets');
  if (s.tempo != null) omitted.add('tempo');
  if (c.loadKind == StrengthLoadKind.assisted) omitted.add('assistance loads');
  if (c.loadKind == StrengthLoadKind.band) omitted.add('band resistance');
  if (garmin == null) omitted.add('exercise names Garmin does not know');
  final hasWeight = s.load != null && c.loadKind.countsVolume && s.load!.kg > 0;
  return {
    'type': 'ExecutableStepDTO',
    'stepType': s.kind == StrengthSetKind.warmup
        ? {'stepTypeId': 1, 'stepTypeKey': 'warmup'}
        : {'stepTypeId': 3, 'stepTypeKey': 'interval'},
    'endCondition': s.timed
        ? {'conditionTypeId': 2, 'conditionTypeKey': 'time'}
        : s.reps != null
        ? {'conditionTypeId': 10, 'conditionTypeKey': 'reps'}
        : {'conditionTypeId': 1, 'conditionTypeKey': 'lap.button'},
    if (s.timed) 'endConditionValue': s.durationSeconds,
    if (!s.timed && s.reps != null) 'endConditionValue': s.reps,
    'targetType': {
      'workoutTargetTypeId': 1,
      'workoutTargetTypeKey': 'no.target',
    },
    'category': ?garmin?.$1,
    'exerciseName': ?garmin?.$2,
    if (hasWeight) 'weightValue': (s.load!.kg * 10).round() / 10,
    if (hasWeight)
      'weightUnit': {'unitId': 8, 'unitKey': 'kilogram', 'factor': 1000.0},
    'description': notes.join(' · '),
  };
}

/// The plan as Garmin workout steps: one step per set, so pyramids and
/// variable loads stay exact; rests as their own steps; supersets and
/// circuits interleaved by round. No rest follows the final set.
GarminStrengthPayload garminStrengthPayload(StrengthWorkoutPlan plan) {
  final steps = <Map<String, dynamic>>[];
  final omitted = <String>{};
  final blocks = plan.blocks.where((b) => b.exercises.isNotEmpty).toList();
  for (var bi = 0; bi < blocks.length; bi++) {
    final b = blocks[bi];
    final lastBlock = bi == blocks.length - 1;
    if (!b.grouped) {
      final e = b.exercises.single;
      for (var i = 0; i < e.sets.length; i++) {
        final s = e.sets[i];
        steps.add(_set(e, s, omitted));
        final last = lastBlock && i == e.sets.length - 1;
        if (!last && (s.restSeconds ?? 0) > 0) steps.add(_rest(s.restSeconds!));
      }
      continue;
    }
    for (var r = 0; r < b.rounds; r++) {
      final round = [
        for (final e in b.exercises)
          if (r < e.sets.length) (e, e.sets[r]),
      ];
      for (var i = 0; i < round.length; i++) {
        steps.add(_set(round[i].$1, round[i].$2, omitted));
        final between = b.restBetweenExercisesSeconds ?? 0;
        if (i < round.length - 1 && between > 0) steps.add(_rest(between));
      }
      final last = lastBlock && r == b.rounds - 1;
      final rounds = b.restBetweenRoundsSeconds ?? 0;
      if (!last && rounds > 0) steps.add(_rest(rounds));
    }
  }
  return GarminStrengthPayload([
    for (var i = 0; i < steps.length; i++) {...steps[i], 'stepOrder': i + 1},
  ], omitted.toList()..sort());
}

/// The same steps without Garmin exercise names, for a retry when Garmin
/// rejects a name; the names stay in each step's description.
List<Map<String, dynamic>> withoutGarminExerciseNames(
  List<Map<String, dynamic>> steps,
) => [
  for (final s in steps)
    {
      for (final e in s.entries)
        if (e.key != 'category' && e.key != 'exerciseName') e.key: e.value,
    },
];

/// Whether [steps] carry Garmin exercise names.
bool hasGarminExerciseNames(List<Map<String, dynamic>> steps) =>
    steps.any((s) => s.containsKey('exerciseName'));

// ── Recorded exercise sets ────────────────────────────────────────────────

double? _num(Object? v) => v is num && v.isFinite ? v.toDouble() : null;

/// Exercises from Garmin's `exerciseSets` response of [activityId].
///
/// Ids are derived from the activity and Garmin's set order, so a repeated
/// import finds the same sets. Garmin weights are grams; a zero or missing
/// weight is unknown, not 0 kg. Repetition counts are the watch's and stay
/// marked as imported so a correction wins. A rest set gives the preceding
/// set its measured rest. Dumbbell loads go into a separate "as recorded"
/// context: Garmin does not say whether the weight is per dumbbell.
List<StrengthPerformedExercise> parseGarminExerciseSets(
  String activityId,
  Object? json,
) {
  final raw = json is Map ? json['exerciseSets'] : json;
  if (raw is! List) return const [];
  final order = <String>[];
  final byKey = <String, StrengthPerformedExercise>{};
  final sets = <String, List<StrengthSetResult>>{};
  String? lastKey;
  var unknownRun = 0;
  for (var i = 0; i < raw.length; i++) {
    final row = raw[i];
    if (row is! Map) continue;
    final type = '${row['setType'] ?? ''}'.toUpperCase();
    if (type == 'REST') {
      final seconds = _num(row['duration'])?.round();
      final list = lastKey == null ? null : sets[lastKey];
      if (seconds != null && list != null && list.isNotEmpty) {
        list[list.length - 1] = list.last.copyWith(
          restSeconds: () => seconds,
          restOrigin: () => StrengthOrigin.imported,
          origins: {
            ...list.last.origins,
            'restSeconds': StrengthOrigin.imported,
          },
        );
      }
      continue;
    }
    if (type != 'ACTIVE') continue;
    final exercises = row['exercises'];
    final best =
        exercises is List && exercises.isNotEmpty && exercises.first is Map
        ? exercises.first as Map
        : const {};
    final category = best['category'] as String?;
    final name = best['name'] as String?;
    final known = category != null && category != 'UNKNOWN';
    if (!known && (lastKey == null || !lastKey.startsWith('unknown'))) {
      unknownRun++;
    }
    final key = known ? '$category/${name ?? ''}' : 'unknown$unknownRun';
    lastKey = key;
    if (!byKey.containsKey(key)) {
      final variantId = known ? variantForGarmin(category, name) : null;
      final builtin = variantId == null
          ? null
          : builtInStrengthVariant(variantId);
      var convention = builtin?.convention ?? const StrengthConvention();
      var equipment = builtin?.equipment ?? '';
      if (convention.basis == StrengthLoadBasis.perImplement) {
        convention = convention.copyWith(
          basis: StrengthLoadBasis.single,
          implements: 1,
        );
        equipment = '$equipment (as recorded by Garmin)';
      }
      byKey[key] = StrengthPerformedExercise(
        id: 'garmin:$activityId:ex:$key',
        variantId:
            variantId ??
            (known ? 'garmin:$category:${name ?? ''}' : 'garmin:unknown'),
        name:
            builtin?.name ??
            (known ? _humanise(name ?? category) : 'Unidentified exercise'),
        equipment: equipment,
        convention: convention,
      );
      order.add(key);
      sets[key] = [];
    }
    final e = byKey[key]!;
    final timed = builtInStrengthVariant(e.variantId)?.timed ?? false;
    final reps = _num(row['repetitionCount'])?.round();
    final grams = _num(row['weight']);
    final load = grams == null || grams <= 0 || !e.convention.loadKind.hasKg
        ? null
        : StrengthLoad(grams / 1000);
    final duration = _num(row['duration'])?.round();
    final index = row['messageIndex'] ?? row['wktStepIndex'] ?? i;
    sets[key]!.add(
      StrengthSetResult(
        id: 'garmin:$activityId:set:$index:$i',
        status: StrengthSetStatus.completed,
        reps: timed ? null : reps,
        durationSeconds: timed ? duration : null,
        load: load,
        origins: {
          'status': StrengthOrigin.imported,
          if (!timed && reps != null) 'reps': StrengthOrigin.imported,
          if (timed && duration != null)
            'durationSeconds': StrengthOrigin.imported,
          if (load != null) 'load': StrengthOrigin.imported,
        },
      ),
    );
  }
  return [for (final k in order) byKey[k]!.copyWith(sets: sets[k])];
}

/// The athlete set this field: typed it, or confirmed the plan's value.
bool _manual(StrengthSetResult s, String field) {
  final o = s.origins[field];
  return o != null && o != StrengthOrigin.imported;
}

/// Merges imported exercises into [existing]. Returns null when nothing
/// changes, so a repeated sync saves nothing.
///
/// A log the athlete wrote without the import is left alone. In an imported
/// log, sets keep every field the athlete corrected; other fields take the
/// newer provider values; sets and exercises the athlete added stay.
StrengthActivityLog? mergeGarminImport(
  StrengthActivityLog? existing,
  String activityId,
  List<StrengthPerformedExercise> imported,
) {
  if (imported.isEmpty) return null;
  if (existing == null || existing.isEmpty) {
    return (existing ?? StrengthActivityLog(activityId: activityId)).copyWith(
      exercises: imported,
    );
  }
  final fromImport = existing.exercises.any(
    (e) => e.id.startsWith('garmin:$activityId:'),
  );
  if (!fromImport) return null;
  final incoming = {for (final e in imported) e.id: e};
  var changed = false;
  final merged = <StrengthPerformedExercise>[];
  for (final e in existing.exercises) {
    final i = incoming.remove(e.id);
    if (i == null) {
      merged.add(e);
      continue;
    }
    final newSets = {for (final s in i.sets) s.id: s};
    final sets = <StrengthSetResult>[];
    for (final s in e.sets) {
      final n = newSets.remove(s.id);
      if (n == null) {
        sets.add(s);
        continue;
      }
      final next = s.copyWith(
        status: _manual(s, 'status') ? null : n.status,
        reps: _manual(s, 'reps') ? null : () => n.reps,
        durationSeconds: _manual(s, 'durationSeconds')
            ? null
            : () => n.durationSeconds,
        load: _manual(s, 'load') ? null : () => n.load,
        restSeconds: _manual(s, 'restSeconds') ? null : () => n.restSeconds,
        restOrigin: _manual(s, 'restSeconds') ? null : () => n.restOrigin,
        origins: {
          ...n.origins,
          for (final o in s.origins.entries)
            if (o.value != StrengthOrigin.imported) o.key: o.value,
        },
      );
      if (_setChanged(s, next)) changed = true;
      sets.add(next);
    }
    if (newSets.isNotEmpty) changed = true;
    merged.add(e.copyWith(sets: [...sets, ...newSets.values]));
  }
  if (incoming.isNotEmpty) changed = true;
  merged.addAll(incoming.values);
  return changed ? existing.copyWith(exercises: merged) : null;
}

bool _setChanged(StrengthSetResult a, StrengthSetResult b) =>
    a.status != b.status ||
    a.reps != b.reps ||
    a.durationSeconds != b.durationSeconds ||
    a.load != b.load ||
    a.restSeconds != b.restSeconds;
