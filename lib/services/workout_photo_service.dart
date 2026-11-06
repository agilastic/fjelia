import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/gym_workout.dart';

class WorkoutTextLine {
  const WorkoutTextLine(
    this.text,
    this.left,
    this.top,
    this.width,
    this.height,
  );
  final String text;
  final double left, top, width, height;
  double get center => left + width / 2;
  factory WorkoutTextLine.fromJson(Map<Object?, Object?> j) => WorkoutTextLine(
    j['text'] as String,
    (j['left'] as num).toDouble(),
    (j['top'] as num).toDouble(),
    (j['width'] as num).toDouble(),
    (j['height'] as num).toDouble(),
  );
}

class WorkoutPhotoDraft {
  const WorkoutPhotoDraft({
    this.seconds,
    this.distance,
    this.unit,
    this.calories,
    this.heartRate,
  });
  final int? seconds;
  final double? distance, calories, heartRate;
  final GymDistanceUnit? unit;
}

/// Label- and position-based extraction. Ambiguous/unreadable fields stay
/// empty for review; a pace or remaining-time value cannot become duration.
WorkoutPhotoDraft parseWorkoutPhoto(List<WorkoutTextLine> lines) {
  final durationLabel = RegExp(
    r'\b(?:total time|elapsed time|duration|workout time|time|gesamtzeit|dauer|zeit|durée|temps)\b',
    caseSensitive: false,
  );
  final distanceLabel = RegExp(
    r'\b(?:distance|distanz|strecke|distancia|distanza)\b',
    caseSensitive: false,
  );
  final calorieLabel = RegExp(
    r'\b(?:calories|calorie|kalorien|kcal|calorías)\b',
    caseSensitive: false,
  );
  final hrLabel = RegExp(
    r'\b(?:average heart rate|avg heart rate|avg hr|heart rate|herzfrequenz|puls|bpm)\b',
    caseSensitive: false,
  );
  final excluded = RegExp(
    r'\b(?:remaining|restzeit|restant|pace|speed|geschwindigkeit|cal(?:ories)?\s*/\s*h(?:our)?|kcal\s*/\s*h|per hour)\b',
    caseSensitive: false,
  );
  final number = RegExp(r'\d+(?:[.,]\d+)?');
  String? value(RegExp label, RegExp expected) {
    final candidates = <String>[];
    for (final line in lines) {
      if (!label.hasMatch(line.text) || excluded.hasMatch(line.text)) continue;
      final after = line.text.replaceFirst(label, '').trim();
      if (expected.hasMatch(after)) {
        candidates.add(after);
        continue;
      }
      final nearby =
          lines
              .where(
                (other) =>
                    other != line &&
                    other.top >= line.top + line.height * .5 &&
                    other.top - line.top < .20 &&
                    (other.center - line.center).abs() < .18 &&
                    !excluded.hasMatch(other.text) &&
                    expected.hasMatch(other.text) &&
                    !durationLabel.hasMatch(other.text) &&
                    !distanceLabel.hasMatch(other.text) &&
                    !calorieLabel.hasMatch(other.text) &&
                    !hrLabel.hasMatch(other.text),
              )
              .toList()
            ..sort(
              (a, b) => (a.top - line.top + (a.center - line.center).abs())
                  .compareTo(b.top - line.top + (b.center - line.center).abs()),
            );
      if (nearby.isNotEmpty) candidates.add(nearby.first.text);
    }
    final unique = candidates.toSet();
    return unique.length == 1 ? unique.single : null;
  }

  final timePattern = RegExp(r'\b\d{1,3}:\d{2}(?::\d{2})?\b');
  final time = value(durationLabel, timePattern);
  final distance = value(distanceLabel, number);
  double? read(String? text) => text == null
      ? null
      : double.tryParse(
          number.firstMatch(text)?.group(0)?.replaceAll(',', '.') ?? '',
        );
  GymDistanceUnit? unit(String? text) {
    if (text == null) return null;
    if (RegExp(
      r'(?:^|[\d\s(])(km|kilometers?|kilometres?)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return GymDistanceUnit.kilometers;
    }
    if (RegExp(
      r'(?:^|[\d\s(])(mi|miles?)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return GymDistanceUnit.miles;
    }
    if (RegExp(
      r'(?:^|[\d\s(])(m|meters?|metres?)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return GymDistanceUnit.meters;
    }
    return null;
  }

  final distanceUnits = lines
      .where((l) => distanceLabel.hasMatch(l.text))
      .map((l) => unit(l.text))
      .whereType<GymDistanceUnit>()
      .toSet();
  return WorkoutPhotoDraft(
    seconds: time == null
        ? null
        : gymDuration(timePattern.firstMatch(time)!.group(0)!),
    distance: read(distance),
    unit:
        unit(distance) ??
        (distanceUnits.length == 1 ? distanceUnits.single : null),
    calories: read(value(calorieLabel, number)),
    heartRate: read(value(hrLabel, number)),
  );
}

class WorkoutPhotoService {
  WorkoutPhotoService({ImagePicker? picker, MethodChannel? channel})
    : _picker = picker ?? ImagePicker(),
      _channel = channel ?? const MethodChannel('fjelia/workout_text');
  final ImagePicker _picker;
  final MethodChannel _channel;
  Future<WorkoutPhotoDraft?> pick({required bool camera}) async {
    final image = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 95,
      requestFullMetadata: false,
    );
    if (image == null) return null;
    final raw =
        await _channel.invokeListMethod<Object?>('recognize', image.path) ?? [];
    return parseWorkoutPhoto([
      for (final line in raw.whereType<Map>())
        WorkoutTextLine.fromJson(line.cast<Object?, Object?>()),
    ]);
  }
}
