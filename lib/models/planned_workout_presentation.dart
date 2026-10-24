import 'dart:convert';

class PlannedStepLine {
  const PlannedStepLine(
    this.amount,
    this.label,
    this.zone,
    this.depth,
    this.repeat,
  );
  final String amount, label;
  final int? zone;
  final int depth;
  final bool repeat;
}

List<PlannedStepLine> plannedStepLines(String? json) {
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
        output.add(
          PlannedStepLine(
            amount,
            label,
            zone is num && zone >= 1 && zone <= 5 ? zone.toInt() : null,
            depth,
            false,
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
