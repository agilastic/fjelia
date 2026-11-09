import 'package:fjelia/models/concept2.dart';
import 'package:fjelia/models/ftms.dart';
import 'package:fjelia/models/indoor_recording.dart';
import 'package:fjelia/services/training_ble.dart';
import 'package:fjelia/services/indoor_fit_export.dart';
import 'package:fjelia/services/fit_activity_data.dart';
import 'package:fjelia/services/fit_decode.dart';
import 'package:fjelia/services/hr_zone_model.dart';

import 'dart:convert';

import 'package:fit_sdk/fit_sdk.dart' as fit;
import 'package:flutter_test/flutter_test.dart';

List<int> le(int value, [int size = 2]) => [
  for (var i = 0; i < size; i++) (value >> (8 * i)) & 255,
];
const device = TrainingDevice(id: 'indoor-machine', name: 'Test bike');

IndoorCapture capture({List<IndoorStep> steps = const []}) => IndoorCapture(
  id: 'ftms_test',
  startedAt: DateTime.utc(2026, 11, 5, 12),
  device: device,
  machine: FtmsMachine.bike,
  name: 'Test workout',
  steps: steps,
);

void main() {
  test('indoor zones use active time and leave HR gaps unallocated', () {
    final zones = zonePercentFromActiveSamples(
      jsonEncode([
        {'t': 1000, 'timer': 1, 'hr': 180},
        {'t': 2000, 'timer': 2},
        {'t': 103000, 'timer': 3, 'hr': 120},
      ]),
      [90, 110, 130, 150, 170],
      3,
    )!;
    expect(zones['zone5'], closeTo(100 / 3, .001));
    expect(zones['zone2'], closeTo(100 / 3, .001));
    expect(zones.values.reduce((a, b) => a + b), closeTo(200 / 3, .001));
  });
  test(
    'Matrix legacy short packets keep known fields and no phantom readings',
    () {
      for (final flag in [0x1b9e, 0x1f9e]) {
        final bytes = [
          ...le(flag),
          198,
          3,
          148,
          2,
          62,
          1,
          0,
          90,
          0,
          255,
          127,
          50,
          0,
          255,
          255,
          37,
          0,
          244,
        ];
        final m = decodeFtms(
          FtmsMachine.treadmill,
          bytes,
          compatibility: FtmsCompatibility.matrix,
        );
        expect(m['spd'], closeTo(9.66 / 3.6, .0001));
        expect(m['machine_distance'], 318);
        expect(m['machine_kcal'], 37);
        expect(m['incline'], 9);
        expect(m['machine_ascent'], 5);
        expect(m.containsKey('hr'), isFalse);
        expect(m.containsKey('w'), isFalse);
        expect(m.containsKey('machine_elapsed'), isFalse);
        expect(m.containsKey('kcal_hour'), isFalse);
        expect(m.containsKey('machine_descent'), isFalse);
        expect(m['matrix_tail_raw'], 244);
        expect(
          () => decodeFtms(FtmsMachine.treadmill, bytes),
          throwsFormatException,
        );
        expect(
          () => decodeFtms(
            FtmsMachine.treadmill,
            bytes.sublist(0, 19),
            compatibility: FtmsCompatibility.matrix,
          ),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'Matrix TouchXL standard split notifications keep their individual flags',
    () {
      final first = decodeFtms(FtmsMachine.treadmill, [
        159,
        0,
        97,
        0,
        54,
        0,
        0,
        0,
        0,
        255,
        127,
        0,
        0,
        255,
        255,
        5,
        0,
        110,
        0,
        2,
      ], compatibility: FtmsCompatibility.matrix);
      final second = decodeFtms(FtmsMachine.treadmill, [
        0,
        31,
        113,
        0,
        0,
        2,
        204,
        0,
        60,
        6,
        255,
        127,
        26,
        0,
      ], compatibility: FtmsCompatibility.matrix);
      expect(first.containsKey('spd'), isFalse);
      expect(first['machine_distance'], 54);
      expect(first['machine_kcal'], 5);
      expect(first['kcal_hour'], 110);
      expect(second['spd'], closeTo(1.13 / 3.6, .0001));
      expect(second['machine_elapsed'], 204);
      expect(second['w'], 26);
      expect(second.containsKey('hr'), isFalse);
      final c = IndoorCapture(
        id: 'matrix',
        startedAt: DateTime.utc(2026),
        device: const TrainingDevice(
          id: 'matrix',
          name: 'Matrix Performance TouchXL',
        ),
        machine: FtmsMachine.treadmill,
        name: 'Run',
      );
      final at = DateTime.utc(2026);
      c.ingest(first, at, recording: true);
      c.ingest(
        second,
        at.add(const Duration(milliseconds: 100)),
        recording: true,
      );
      expect(
        c.live(at.add(const Duration(milliseconds: 200)))['spd'],
        second['spd'],
      );
      expect(
        c.live(at.add(const Duration(milliseconds: 200)))['machine_distance'],
        54,
      );
      expect(
        c.live(at.add(const Duration(milliseconds: 200)))['machine_kcal'],
        5,
      );
    },
  );

  test('Matrix bike has its own short layout; Johnson/BowFlex are not misidentified', () {
    final m = decodeFtms(FtmsMachine.bike, [
      254,
      29,
      131,
      12,
      51,
      12,
      134,
      0,
      128,
      0,
      193,
      9,
      0,
      13,
      0,
      162,
      0,
      157,
      0,
      54,
    ], compatibility: FtmsCompatibility.matrix);
    expect(m['cad'], 67);
    expect(m['w'], 162);
    expect(m['machine_distance'], 2497);
    expect(m.containsKey('machine_kcal'), isFalse);
    expect(m.containsKey('hr'), isFalse);
    expect(ftmsCompatibilityForName('Matrix TF50'), FtmsCompatibility.matrix);
    expect(ftmsCompatibilityForName('CTM123456'), FtmsCompatibility.matrix);
    expect(ftmsCompatibilityForName('MatrixT7xi'), FtmsCompatibility.matrix);
    expect(ftmsCompatibilityForName('T7xi'), FtmsCompatibility.matrix);
    expect(ftmsCompatibilityForName('T5x'), FtmsCompatibility.matrix);
    expect(ftmsCompatibilityForName('BFX_T6_8516'), FtmsCompatibility.standard);
    expect(
      ftmsCompatibilityForName('Johnson Health Tech NA'),
      FtmsCompatibility.standard,
    );
    expect(
      ftmsControlAllowed(FtmsMachine.treadmill, FtmsCompatibility.matrix),
      isFalse,
    );
  });

  test(
    'bike flags, signed resistance/power, fractional cadence and energy',
    () {
      final m = decodeFtms(FtmsMachine.bike, [
        ...le(0x1fff & ~1),
        ...le(2500),
        ...le(2000),
        ...le(181),
        ...le(160),
        ...le(123456, 3),
        ...le(-2),
        ...le(250),
        ...le(240),
        ...le(123),
        ...le(600),
        12,
        151,
        80,
        ...le(600),
        ...le(120),
      ]);
      expect(m['spd'], closeTo(25 / 3.6, .001));
      expect(m['cad'], 90.5);
      expect(m['machine_distance'], 123456);
      expect(m['resistance'], -2);
      expect(m['w'], 250);
      expect(m['hr'], 151);
      expect(m['machine_kcal'], 123);
      expect(m['machine_elapsed'], 600);
      expect(m['remaining'], 120);
    },
  );

  test(
    'More Data omits mandatory speed; no-data markers never become zero',
    () {
      expect(decodeFtms(FtmsMachine.bike, [...le(1 | (1 << 6)), ...le(0)]), {
        'w': 0,
      });
      expect(
        decodeFtms(FtmsMachine.bike, [
          ...le((1 << 2) | (1 << 6) | (1 << 9)),
          ...le(0xffff),
          ...le(0xffff),
          ...le(0x7fff),
          255,
        ]),
        isEmpty,
      );
      expect(
        () => decodeFtms(FtmsMachine.bike, [...le(1 << 4), ...le(2000), 1]),
        throwsFormatException,
      );
    },
  );

  test('treadmill decodes negative incline, elevation and belt power', () {
    final m = decodeFtms(FtmsMachine.treadmill, [
      ...le((1 << 2) | (1 << 3) | (1 << 4) | (1 << 12)),
      ...le(1000),
      ...le(500, 3),
      ...le(-15),
      ...le(-8),
      ...le(123),
      ...le(45),
      ...le(20),
      ...le(180),
    ]);
    expect(m['incline'], -1.5);
    expect(m['ramp_angle'], -.8);
    expect(m['machine_ascent'], 12.3);
    expect(m['machine_descent'], 4.5);
    expect(m['force_n'], 20);
    expect(m['w'], 180);
  });

  test('rower stroke data and 500m pace produce m/s', () {
    final m = decodeFtms(FtmsMachine.rower, [
      ...le((1 << 2) | (1 << 3) | (1 << 5)),
      55,
      ...le(400),
      ...le(2000, 3),
      ...le(125),
      ...le(220),
    ]);
    expect(m['cad'], 27.5);
    expect(m['machine_strokes'], 400);
    expect(m['spd'], 4);
    expect(m['w'], 220);
    expect(m['pace_500m'], 125);
  });

  test('cross trainer uses a 24-bit flag field and consumes paired fields', () {
    final m = decodeFtms(FtmsMachine.crossTrainer, [
      ...le(
        (1 << 3) | (1 << 6) | (1 << 7) | (1 << 8) | (1 << 11) | (1 << 13),
        3,
      ),
      ...le(700),
      ...le(65),
      ...le(60),
      ...le(35),
      ...le(20),
      ...le(125),
      ...le(170),
      140,
      ...le(321),
    ]);
    expect(m['cad'], 65);
    expect(m['incline'], 3.5);
    expect(m['resistance'], 12.5);
    expect(m['w'], 170);
    expect(m['hr'], 140);
    expect(m['machine_elapsed'], 321);
  });

  test(
    'step and stair climber layouts preserve steps, floors and elevation',
    () {
      final step = decodeFtms(FtmsMachine.stepClimber, [
        ...le((1 << 1) | (1 << 3) | (1 << 7)),
        ...le(12),
        ...le(300),
        ...le(60),
        ...le(42),
        ...le(120),
      ]);
      expect(step['machine_steps'], 300);
      expect(step['machine_floors'], 12);
      expect(step['machine_ascent'], 42);
      expect(step['machine_elapsed'], 120);
      final stair = decodeFtms(FtmsMachine.stairClimber, [
        ...le((1 << 1) | (1 << 4) | (1 << 6) | (1 << 8)),
        ...le(8),
        ...le(50),
        ...le(220),
        125,
        ...le(100),
      ]);
      expect(stair['machine_floors'], 8);
      expect(stair['machine_strides'], 220);
      expect(stair['hr'], 125);
      expect(stair['machine_elapsed'], 100);
    },
  );

  test('control ranges enforce increments, signed values and wire units', () {
    final range = FtmsRange.decode(FtmsTarget.resistance, [
      ...le(-20),
      ...le(100),
      ...le(5),
    ]);
    expect(range.min, -2);
    expect(range.increment, .5);
    expect(ftmsTargetCommand(FtmsTarget.resistance, range, 2.5), [4, 25, 0]);
    expect(
      () => ftmsTargetCommand(FtmsTarget.resistance, range, 2.2),
      throwsArgumentError,
    );
    expect(
      () => ftmsTargetCommand(FtmsTarget.resistance, range, 20),
      throwsArgumentError,
    );
    expect(
      () =>
          FtmsRange.decode(FtmsTarget.power, [...le(0), ...le(500), ...le(0)]),
      throwsFormatException,
    );
  });

  test(
    'counter baselines, resets and pauses do not add pre-session distance',
    () {
      final c = capture(), at = DateTime.utc(2026);
      c.ingest(
        {'machine_distance': 1000, 'machine_kcal': 30},
        at,
        recording: true,
      );
      c.ingest(
        {'machine_distance': 1010, 'machine_kcal': 32},
        at.add(const Duration(seconds: 1)),
        recording: true,
      );
      expect(c.distanceMeters, 10);
      expect(c.totals['kcal'], 2);
      c.ingest(
        {'machine_distance': 0},
        at.add(const Duration(seconds: 2)),
        recording: true,
      );
      c.ingest(
        {'machine_distance': 5},
        at.add(const Duration(seconds: 3)),
        recording: true,
      );
      expect(c.distanceMeters, 15);
      c.ingest(
        {'machine_distance': 200},
        at.add(const Duration(seconds: 4)),
        recording: false,
      );
      c.ingest(
        {'machine_distance': 250},
        at.add(const Duration(seconds: 5)),
        recording: true,
      );
      expect(c.distanceMeters, 15);
      c.ingest(
        {'machine_distance': 260},
        at.add(const Duration(seconds: 6)),
        recording: true,
      );
      expect(c.distanceMeters, 25);
    },
  );

  test('preferred external HR has no implicit fallback or stale values', () {
    final c = capture(), at = DateTime.utc(2026);
    c.ingest({'hr': 110}, at, recording: true);
    c.externalHeartRate(150, at, contact: true);
    expect(c.live(at)['hr'], 110);
    c.preferExternalHeartRate = true;
    expect(c.live(at)['hr'], 150);
    expect(c.live(at)['hr_source'], 1);
    c.externalHeartRate(180, at, contact: false);
    expect(c.live(at).containsKey('hr'), isFalse);
    c.externalHeartRate(140, at);
    expect(
      c.live(at.add(const Duration(seconds: 6))).containsKey('hr'),
      isFalse,
    );
    c.preferExternalHeartRate = false;
    expect(
      c.live(at.add(const Duration(seconds: 6))).containsKey('hr'),
      isFalse,
    );
  });

  test(
    'structured intervals use actual time/distance and recover exact progress',
    () {
      final steps = indoorSteps([
        {
          'stepType': {'stepTypeKey': 'warmup'},
          'endCondition': {'conditionTypeKey': 'time'},
          'endConditionValue': 5,
        },
        {
          'stepType': 'repeat',
          'numberOfIterations': 2,
          'workoutSteps': [
            {
              'stepType': 'interval',
              'endCondition': {'conditionTypeKey': 'distance'},
              'endConditionValue': 100,
            },
          ],
        },
      ]);
      final c = capture(steps: steps), at = DateTime.utc(2026);
      c.snapshot(at, 6200);
      expect(c.stepIndex, 1);
      expect(c.stepStartedMs, 5000);
      expect(c.remainingSeconds, isNull);
      expect(c.remainingMeters, 100);
      c.ingest({'machine_distance': 1000}, at, recording: true);
      c.ingest({'machine_distance': 1105}, at, recording: true);
      c.snapshot(at.add(const Duration(seconds: 10)), 16200);
      expect(c.stepIndex, 2);
      expect(c.remainingMeters, 95);
      final restored = IndoorCapture.fromJson(c.toJson());
      expect(restored.stepIndex, 2);
      expect(restored.remainingMeters, 95);
      expect(restored.samples, c.samples);
      expect(restored.elapsedMs, 16200);
    },
  );

  test('a PM5 on a SkiErg exports as indoor Nordic skiing', () {
    final at = DateTime.utc(2026, 11, 9, 12);
    final c = IndoorCapture(
      id: 'concept2_ski',
      startedAt: at,
      device: const TrainingDevice(id: 'pm5', name: 'PM5 430000000'),
      machine: FtmsMachine.rower,
      dataProtocol: 'concept2',
      activityTypeOverride: concept2ActivityType(128),
      name: 'SkiErg (Fjelia)',
    );
    expect(c.activityType, 'nordic_skiing');
    c.ingest(
      {'pace_500m': 130, 'cad': 40, 'machine_distance': 100},
      at,
      recording: true,
    );
    c.snapshot(at.add(const Duration(seconds: 1)), 1000);
    final messages = <fit.Mesg>[];
    FitDecode()
      ..onMesg = messages.add
      ..read(indoorFit(c));
    final session = fit.SessionMesg.fromMesg(
      messages.singleWhere((m) => m.num == fit.MesgNum.session),
    );
    expect(session.getSport(), fit.Sport.crossCountrySkiing);
    expect(session.getSubSport(), fit.SubSport.indoorSkiing);
    final restored = IndoorCapture.fromJson(
      jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>,
    );
    expect(restored.activityType, 'nordic_skiing');
    expect(restored.dataProtocol, 'concept2');
  });

  test(
    'FIT preserves wall/timer time, zero power, device and all raw metrics',
    () {
      final c = capture(), at = capture().startedAt;
      c.ingest(
        {
          'spd': 5,
          'w': 0,
          'cad': 85.5,
          'hr': 120,
          'machine_distance': 1000,
          'incline': 1.5,
          'resistance': 7,
        },
        at,
        recording: true,
      );
      c.snapshot(at.add(const Duration(seconds: 1)), 1000);
      c.ingest(
        {'spd': 6, 'w': 200, 'machine_distance': 1010},
        at.add(const Duration(seconds: 2)),
        recording: true,
      );
      c.snapshot(at.add(const Duration(seconds: 2)), 2000);
      c.event('pause', at.add(const Duration(seconds: 2)));
      c.event('resume', at.add(const Duration(seconds: 102)));
      c.clearContinuity();
      c.snapshot(at.add(const Duration(seconds: 103)), 3000);
      final bytes = indoorFit(c);
      // CRC checked independently of the encoder/decoder library.
      var crc = 0;
      for (final byte in bytes.take(bytes.length - 2)) {
        crc ^= byte;
        for (var b = 0; b < 8; b++) {
          crc = crc & 1 != 0 ? (crc >> 1) ^ 0xa001 : crc >> 1;
        }
      }
      expect(bytes[bytes.length - 2] | bytes.last << 8, crc);
      final decoded = parseFitActivity(bytes)!;
      expect(decoded.timerSeconds, 3);
      expect(decoded.distanceMeters, 10);
      expect(decoded.samples.first['w'], 0);
      expect(decoded.samples[1]['w'], 200);
      expect(decoded.samples.last.containsKey('hr'), isFalse);
      final messages = <fit.Mesg>[];
      FitDecode()
        ..onMesg = messages.add
        ..read(bytes);
      final session = fit.SessionMesg.fromMesg(
        messages.singleWhere((m) => m.num == fit.MesgNum.session),
      );
      expect(session.getTotalElapsedTime(), 103);
      expect(session.getSubSport(), fit.SubSport.indoorCycling);
      expect(messages.any((m) => m.num == fit.MesgNum.deviceInfo), isTrue);
      expect(messages.any((m) => m.num == fit.MesgNum.lap), isTrue);
      final records = messages
          .where((m) => m.num == fit.MesgNum.record)
          .toList();
      expect(
        records.first
            .getField(fit.RecordMesg.fieldEnhancedSpeed)!
            .values
            .single,
        5000,
      );
      expect(
        records.first.developerFields.any(
          (f) => f.name == 'ftms_resistance' && f.value == 7,
        ),
        isTrue,
      );
      expect(
        records.first.developerFields.any(
          (f) => f.name == 'ftms_cad' && f.value == 85.5,
        ),
        isTrue,
      );
    },
  );
}
