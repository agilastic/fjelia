import 'package:flutter/material.dart';

const _mint = Color(0xFF00D4A0);

enum ActivityKind {
  running,
  cycling,
  swimming,
  strength,
  rowing,
  hiking,
  walking,
  yoga,
  other,
}

ActivityKind activityKind(String sport) {
  final key = sport.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (RegExp('strength|weight|functional|kraft|gym|crossfit').hasMatch(key)) {
    return ActivityKind.strength;
  }
  if (RegExp('row|rudern').hasMatch(key)) return ActivityKind.rowing;
  if (RegExp('cycl|bik|mtb|gravel|radfahr').hasMatch(key)) {
    return ActivityKind.cycling;
  }
  if (RegExp('swim|schwimm|pool').hasMatch(key)) return ActivityKind.swimming;
  if (RegExp('hik|wander').hasMatch(key)) return ActivityKind.hiking;
  if (RegExp('walk|gehen').hasMatch(key)) return ActivityKind.walking;
  if (RegExp('yoga|pilates|mobility').hasMatch(key)) return ActivityKind.yoga;
  if (RegExp('run|jog|lauf|trail|treadmill').hasMatch(key)) {
    return ActivityKind.running;
  }
  return ActivityKind.other;
}

Color completedActivityColor(String sport) => switch (activityKind(sport)) {
  ActivityKind.running => _mint,
  ActivityKind.cycling => Colors.lightBlue,
  ActivityKind.swimming => const Color(0xFF64D8FF),
  ActivityKind.strength => const Color(0xFFBD91FF),
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
