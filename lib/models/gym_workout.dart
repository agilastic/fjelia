import 'dart:convert';

import 'package:crypto/crypto.dart';

/// A console/account summary. It deliberately has no synthetic time series.
class GymWorkout {
  const GymWorkout({
    required this.id,
    required this.startedAt,
    required this.durationSeconds,
    required this.source,
    this.name = 'Treadmill',
    this.distanceMeters,
    this.calories,
    this.avgHeartRate,
  });
  final String id, source, name;
  final DateTime startedAt;
  final int durationSeconds;
  final double? distanceMeters, calories, avgHeartRate;

  void validate() {
    if (id.isEmpty || !{'matrix_xid', 'gym_summary'}.contains(source)) {
      throw const FormatException('Invalid workout identity.');
    }
    if (durationSeconds <= 0 || durationSeconds > 86400) {
      throw const FormatException(
        'Enter a duration between 1 second and 24 hours.',
      );
    }
    for (final v in [distanceMeters, calories, avgHeartRate]) {
      if (v != null && (!v.isFinite || v < 0)) {
        throw const FormatException(
          'Workout values must be finite and positive.',
        );
      }
    }
    if ((distanceMeters ?? 0) > 1000000 ||
        (calories ?? 0) > 100000 ||
        avgHeartRate != null && (avgHeartRate! < 20 || avgHeartRate! > 260)) {
      throw const FormatException('Check the workout values and units.');
    }
  }

  static String stableId(String namespace, String value) =>
      '${namespace}_${sha256.convert(utf8.encode(value)).toString().substring(0, 32)}';
}

enum GymDistanceUnit {
  kilometers('km', 1000),
  miles('mi', 1609.344),
  meters('m', 1);

  const GymDistanceUnit(this.label, this.metersPerUnit);
  final String label;
  final double metersPerUnit;
}

int? gymDuration(String text) {
  final parts = text.trim().split(':');
  if (parts.length < 2 || parts.length > 3) return null;
  final n = parts.map(int.tryParse).toList();
  if (n.any((v) => v == null || v < 0)) return null;
  if (n.last! > 59 || parts.length == 3 && n[1]! > 59) return null;
  final seconds = parts.length == 3
      ? n[0]! * 3600 + n[1]! * 60 + n[2]!
      : n[0]! * 60 + n[1]!;
  return seconds > 0 && seconds <= 86400 ? seconds : null;
}
