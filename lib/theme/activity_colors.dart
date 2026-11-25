import 'package:fjelia_core/services/activity_kind.dart';
import 'package:flutter/material.dart';

export 'package:fjelia_core/services/activity_kind.dart';

const _mint = Color(0xFF00D4A0);

/// Strength identity colour.
const strengthColor = Color(0xFFBD91FF);

Color completedActivityColor(String sport) => switch (activityKind(sport)) {
  ActivityKind.running => _mint,
  ActivityKind.cycling => Colors.lightBlue,
  ActivityKind.swimming => const Color(0xFF64D8FF),
  ActivityKind.strength => strengthColor,
  ActivityKind.rowing => const Color(0xFFFFAA42),
  ActivityKind.hiking => const Color(0xFFA6D76D),
  ActivityKind.walking => const Color(0xFFFFC857),
  ActivityKind.yoga => const Color(0xFFFF8FB1),
  ActivityKind.other => const Color(0xFFB0B8C5),
};

IconData activitySportIcon(String sport) => switch (activityKind(sport)) {
  ActivityKind.running => Icons.directions_run,
  ActivityKind.cycling => Icons.directions_bike,
  ActivityKind.swimming => Icons.pool,
  ActivityKind.strength => Icons.fitness_center,
  ActivityKind.rowing => Icons.rowing,
  ActivityKind.hiking => Icons.hiking,
  ActivityKind.walking => Icons.directions_walk,
  ActivityKind.yoga => Icons.self_improvement,
  ActivityKind.other => Icons.sports,
};

Color plannedActivityColor(String? phase) => switch (phase) {
  'recovery' => const Color(0xFF888888),
  'base' => Colors.lightBlue,
  'build' => _mint,
  'peak' => Colors.orange,
  'taper' => Colors.purpleAccent,
  _ => Colors.orange,
};
