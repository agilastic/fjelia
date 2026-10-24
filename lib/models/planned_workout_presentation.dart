import 'dart:convert';

class PlannedStepLine {
  const PlannedStepLine(
    this.amount,
    this.label,
    this.zone,
    this.depth,
    this.repeat, {
    this.target,
    this.note,
    this.colorZone,
  });
  final String amount, label;
  final int? zone;
  final int depth;
  final bool repeat;

  /// What to aim for in this step, e.g. "Heart rate · 140–150 bpm".
  final String? target;
  final String? note;

  /// The zone that colours the step: the stated zone, or an estimate from
  /// its role. Not shown as text.
  final int? colorZone;
}

/// What a zone means today: its heart-rate range from the zone floors and,
/// for sports with power, its watts from FTP (Coggan: Z1 up to 55 %, Z2 55 to
/// 75 %, Z3 75 to 90 %, Z4 90 to 105 %, Z5 105 to 120 %). Zones and FTP
/// change over time, so this is worked out when shown, never stored.
String zoneTargetText(int zone, {required List<int> hrFloors, int? ftp}) {
  final z = zone.clamp(1, 5);
  final parts = <String>['Z$z'];
  if (hrFloors.length >= 5) {
    parts.add(
      z == 5
          ? '${hrFloors[4]}+ bpm'
          : '${hrFloors[z - 1]}–${hrFloors[z] - 1} bpm',
    );
  }
  if (ftp != null && ftp > 0) {
    const edges = [0.0, 0.55, 0.75, 0.90, 1.05, 1.20];
    final low = (ftp * edges[z - 1]).round(), high = (ftp * edges[z]).round();
    parts.add(z == 1 ? 'up to $high W' : '$low–$high W');
  }
  return parts.join(' · ');
}

List<PlannedStepLine> plannedStepLines(
  String? json, {
  int? primaryZone,
  String Function(int zone)? zoneTarget,
}) {
  if (json == null || json.isEmpty) return const [];
  final output = <PlannedStepLine>[];
  try {
    final decoded = jsonDecode(json);
    void read(Object? items, int depth) {
      if (items is! List || depth > 8) return;
      for (final item in items) {
        if (output.length >= 200) return;
        if (item is! Map) continue;
        final children = item['workoutSteps'];
        final stepType = item['stepType'];
        final type = stepType is Map
            ? stepType['stepTypeKey']?.toString()
            : stepType?.toString();
        if (children is List || type == 'repeat') {
          final n = item['numberOfIterations'] ?? item['endConditionValue'];
          output.add(
            PlannedStepLine(
              '${n is num && n.isFinite ? n.round() : 1}× repeat',
              '',
              null,
              depth,
              true,
            ),
          );
          read(children, depth + 1);
          continue;
        }
        final condition = item['endCondition'];
        final distance =
            condition is Map &&
            (condition['conditionTypeKey'] == 'distance' ||
                condition['conditionTypeId'] == 3);
        final value = item['endConditionValue'];
        String amount = 'Open-ended';
        if (value is num && value.isFinite && value >= 0) {
          final n = value.round();
          amount = distance
              ? '$n m'
              : n % 60 == 0
              ? '${n ~/ 60} min'
              : n < 60
              ? '$n sec'
              : '${n ~/ 60} min ${n % 60} sec';
        }
        final label = switch (type) {
          'warmup' => 'Warm-up',
          'cooldown' => 'Cool-down',
          'recovery' => 'Recovery',
          'rest' => 'Rest',
          'interval' => 'Interval',
          _ => 'Workout',
        };
        final zone = item['zoneNumber'];
        final stated = zone is num && zone >= 1 && zone <= 5
            ? zone.toInt()
            : null;
        final easy = const {
          'Warm-up',
          'Cool-down',
          'Recovery',
          'Rest',
        }.contains(label);
        final shown = stated ?? (easy ? 1 : primaryZone?.clamp(1, 5));
        output.add(
          PlannedStepLine(
            amount,
            label,
            stated,
            depth,
            false,
            colorZone: shown,
            target: shown == null || zoneTarget == null
                ? null
                : zoneTarget(shown),
          ),
        );
      }
    }

    read(
      decoded is Map ? decoded['workoutSteps'] ?? decoded['steps'] : decoded,
      0,
    );
  } on FormatException {
    return const [];
  }
  return output;
}

/// Default target fractions, keyed by primary zone.
const plannedZoneDefaults = {
  1: [.70, .20, .05, .03, .02],
  2: [.25, .55, .12, .05, .03],
  3: [.15, .25, .45, .10, .05],
  4: [.15, .15, .15, .50, .05],
  5: [.20, .15, .10, .15, .40],
};
List<double> plannedZoneFractions(String? json, int primaryZone) {
  if (json != null) {
    try {
      final data = jsonDecode(json);
      final values = List<double>.generate(5, (i) {
        final v = data is List && data.length == 5
            ? data[i]
            : data is Map
            ? data['zone${i + 1}'] ?? data['z${i + 1}']
            : null;
        return v is num && v.isFinite && v >= 0 ? v.toDouble() : -1;
      });
      final sum = values.fold(0.0, (a, b) => a + b);
      if (values.every((v) => v >= 0) && sum > 0) {
        return values.map((v) => v / sum).toList();
      }
    } on FormatException {
      /* Use the defaults for malformed legacy values. */
    }
  }
  return plannedZoneDefaults[primaryZone] ?? plannedZoneDefaults[2]!;
}
