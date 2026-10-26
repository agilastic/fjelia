import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/services/fit_activity_data.dart';
import 'package:fjelia/services/polar_exercise_data.dart';

import '../support/polar_fit_fixture.dart';

Map<String, dynamic> polarExerciseFixture() => {
  'id': 'ABC123',
  'start_time': '2026-10-25T15:28:00',
  'start_time_utc_offset': 60,
  'duration': 'PT1H45S',
  'distance': 9530.4,
  'sport': 'RUNNING',
  'heart_rate': {'average': 132, 'maximum': 152},
  'training_load': 93.8,
  'training_load_pro': {'cardio-load': 84, 'muscle-load': 1051},
  'samples': [
    {'sample-type': '0', 'recording-rate': 5, 'data': '120,null,152'},
    {'sample-type': '1', 'recording-rate': 5, 'data': '9,9,9'},
    {'sample-type': '3', 'recording-rate': 5, 'data': '50,52,51'},
    {'sample-type': '4', 'recording-rate': 5, 'data': '275,289,300'},
    {'sample-type': '10', 'recording-rate': 5, 'data': '0,12.5,25'},
  ],
};

void main() {
  test(
    'FIT decodes source ascent, moving time, power and unit-scaled samples',
    () {
      final data = parseFitActivity(polarFitFixture())!;
      expect(data.ascentMeters, 20);
      expect(data.timerSeconds, 3645); // Not the 3700-second elapsed time.
      expect(data.movingSeconds, 3600);
      expect(data.avgPower, 289);
      expect(data.distanceMeters, 9530);
      expect(data.samples[1]['d'], 12.5);
      expect(data.samples[1]['spd'], 2.5);
      expect(data.samples[1]['ele'], 52);
      expect(data.route.first['lat'], closeTo(52.1, 1e-6));
      expect(data.route.first['lng'], closeTo(9.7, 1e-6));
    },
  );
  test('an absent moving field is not replaced by timer time', () {
    final fit = parseFitActivity(polarFitFixture(movingSeconds: null))!;
    expect(fit.movingSeconds, isNull);
    expect(
      PolarExerciseData.parse(polarExerciseFixture(), fit: fit)!.movingSeconds,
      isNull,
    );
  });
  test('missing or zero ascent remains distinct', () {
    expect(
      parseFitActivity(polarFitFixture(ascent: null))!.ascentMeters,
      isNull,
    );
    expect(parseFitActivity(polarFitFixture(ascent: 0))!.ascentMeters, 0);
  });
  test('corrupt exports are unavailable rather than partially accepted', () {
    final bytes = polarFitFixture();
    bytes.last ^= 1;
    expect(parseFitActivity(bytes), isNull);
    expect(parseFitActivity(bytes.sublist(0, 10)), isNull);
  });
  test(
    'AccessLink CSV uses intervals, preserves gaps and converts km/h to m/s',
    () {
      final data = PolarExerciseData.parse(polarExerciseFixture())!;
      expect(data.start, DateTime.utc(2026, 10, 25, 14, 28));
      expect(data.durationSeconds, 3645);
      expect(data.distanceMeters, 9530.4);
      expect(
        data.trainingLoad,
        84,
      ); // Cardio load, never muscle load or fallback.
      expect(data.samples, hasLength(3));
      expect(data.samples[1].containsKey('hr'), isFalse);
      expect(data.samples[2]['t'], data.start.millisecondsSinceEpoch + 10000);
      expect(data.samples[1]['spd'], 2.5);
      expect(data.samples[1]['d'], 12.5);
    },
  );
  test(
    'FIT enriches summary fields without rounding distance or changing timer duration',
    () {
      final data = PolarExerciseData.parse(
        polarExerciseFixture(),
        fit: parseFitActivity(polarFitFixture()),
      )!;
      expect(data.ascentMeters, 20);
      expect(data.avgPower, 289);
      expect(data.movingSeconds, 3600);
      expect(data.durationSeconds, 3645);
      expect(data.distanceMeters, 9530.4);
      expect(data.samples[1]['hr'], 132);
    },
  );
  test('underscore aliases and explicit time-zone offsets are supported', () {
    final json = polarExerciseFixture()
      ..['start_time'] = '2026-10-25T15:28:00+02:00'
      ..['training_load_pro'] = {'cardio_load': 0, 'muscle_load': 1051}
      ..['samples'] = [
        {'sample_type': 1, 'recording_rate': 5, 'data': '0,18'},
      ];
    final data = PolarExerciseData.parse(json)!;
    expect(data.start, DateTime.utc(2026, 10, 25, 13, 28));
    expect(data.trainingLoad, 0);
    expect(data.samples.last['spd'], 5);
  });
  test('missing Training Load Pro uses the recorded legacy load', () {
    final json = polarExerciseFixture()..remove('training_load_pro');
    expect(PolarExerciseData.parse(json)!.trainingLoad, 93.8);
    json.remove('training_load');
    expect(PolarExerciseData.parse(json)!.trainingLoad, isNull);
  });
  test('malformed core data and samples do not invent values', () {
    expect(PolarExerciseData.parse({'duration': 3645}), isNull);
    final json = polarExerciseFixture()
      ..['samples'] = [
        {'sample-type': '1', 'recording-rate': 0, 'data': '9,9'},
        {'sample-type': '4', 'recording-rate': 1, 'data': 'NaN,-1,null'},
      ];
    expect(PolarExerciseData.parse(json)!.samples, isEmpty);
  });
  test('long and fractional durations are preserved', () {
    expect(parsePolarDuration('P1DT4H30M0.4S'), 102600);
    expect(parsePolarDuration('PT1H0M45.7S'), 3646);
    expect(parsePolarDuration('invalid PT1H'), 0);
  });
}
