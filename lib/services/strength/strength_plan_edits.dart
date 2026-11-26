import '../../models/strength_workout.dart';

export 'package:fjelia_core/services/strength/strength_plan_edits.dart';

/// A readable exercise list for sharing, from the same domain model.
String strengthPlanText(StrengthWorkoutPlan plan, MassUnit unit) {
  final lines = <String>[];
  var n = 0;
  for (final b in plan.blocks) {
    if (b.grouped) {
      lines.add(
        '${b.kind.label} · ${b.rounds} rounds'
        '${b.restBetweenRoundsSeconds == null ? '' : ' · rest ${formatStrengthSeconds(b.restBetweenRoundsSeconds!)} between rounds'}',
      );
    }
    for (final e in b.exercises) {
      n++;
      lines.add(
        '$n. ${e.name}${e.equipment.isEmpty ? '' : ' (${e.equipment})'}',
      );
      for (var i = 0; i < e.sets.length; i++) {
        final s = e.sets[i];
        final load = s.load == null
            ? s.resistance
            : formatStrengthLoad(s.load!.kg, unit) +
                  (e.convention.basis == StrengthLoadBasis.perImplement
                      ? ' each'
                      : '');
        lines.add(
          '   ${s.kind == StrengthSetKind.warmup ? 'Warm-up' : 'Set ${i + 1}'}: '
          '${s.timed ? formatStrengthSeconds(s.durationSeconds!) : '${s.repsText} reps'}'
          '${load == null ? '' : ' × $load'}'
          '${!b.grouped && s.restSeconds != null ? ' · rest ${formatStrengthSeconds(s.restSeconds!)}' : ''}'
          '${s.effort == null ? '' : ' · ${s.effort!.text}'}',
        );
      }
    }
  }
  return lines.join('\n');
}
