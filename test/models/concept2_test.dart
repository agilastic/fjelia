import 'package:fjelia/models/concept2.dart';
import 'package:fjelia/models/ftms.dart';
import 'package:fjelia/models/training_ble_profile.dart';
import 'package:fjelia/models/training_device.dart';
import 'package:flutter_test/flutter_test.dart';

/// Little-endian bytes of [value], [size] bytes long.
List<int> le(int value, int size) => [
  for (var i = 0; i < size; i++) (value >> (8 * i)) & 0xff,
];

/// Records laid out as in the Concept2 PM CSAFE Communication Definition,
/// rev. 0.31, Smart Bluetooth attribute table.
void main() {
  test('general status: time, distance, states and drag factor', () {
    final bytes = [
      ...le(123456, 3), // 1234.56 s
      ...le(45678, 3), // 4567.8 m
      1, 0, 1, 1, 2, // workout type, interval type, states
      ...le(5000, 3), ...le(200000, 3), 0, // work distance, duration
      118, // drag factor
    ];
    expect(bytes, hasLength(19));
    final v = decodeConcept2(0x31, bytes);
    expect(v['machine_elapsed'], closeTo(1234.56, 1e-9));
    expect(v['machine_distance'], closeTo(4567.8, 1e-9));
    expect(v['c2_workout_state'], 1);
    expect(v['c2_rowing_state'], 1);
    expect(v['c2_drag_factor'], 118);
  });

  test('additional status 1: speed, rate, heart rate and pace', () {
    final bytes = [
      ...le(6000, 3),
      ...le(4237, 2), // 4.237 m/s
      26, // strokes/min
      148, // bpm
      ...le(11800, 2), // 1:58.00 /500 m
      ...le(12050, 2),
      ...le(0, 2), ...le(0, 3),
      0, // RowErg model D
    ];
    expect(bytes, hasLength(17));
    final v = decodeConcept2(0x32, bytes);
    expect(v['spd'], closeTo(4.237, 1e-9));
    expect(v['cad'], 26);
    expect(v['hr'], 148);
    expect(v['pace_500m'], closeTo(118, 1e-9));
    expect(v['avg_pace_500m'], closeTo(120.5, 1e-9));
    expect(v['c2_erg_type'], 0);
  });

  test('old firmware: 16-byte status without erg type, no heart rate', () {
    final bytes = [
      ...le(6000, 3),
      ...le(0, 2),
      0,
      255,
      ...le(0, 2),
      ...le(0, 2),
      ...le(0, 2),
      ...le(0, 3),
    ];
    expect(bytes, hasLength(16));
    final v = decodeConcept2(0x32, bytes);
    expect(v.containsKey('hr'), isFalse);
    expect(v.containsKey('pace_500m'), isFalse);
    expect(v.containsKey('spd'), isFalse);
    expect(v.containsKey('c2_erg_type'), isFalse);
  });

  test('stroke data: drive, force in newtons and the stroke count', () {
    final bytes = [
      ...le(6000, 3), ...le(1234, 3),
      145, // 1.45 m drive
      82, // 0.82 s drive
      ...le(160, 2), // 1.60 s recovery
      ...le(1050, 2), // 10.50 m per stroke
      ...le(2000, 2), // 200.0 lbs peak
      ...le(1100, 2), // 110.0 lbs average
      ...le(4500, 2), // 450.0 J
      ...le(321, 2),
    ];
    expect(bytes, hasLength(20));
    final v = decodeConcept2(0x35, bytes);
    expect(v['c2_drive_length'], closeTo(1.45, 1e-9));
    expect(v['c2_drive_time'], closeTo(.82, 1e-9));
    expect(v['c2_recovery_time'], closeTo(1.6, 1e-9));
    expect(v['c2_peak_force_n'], closeTo(889.64, .01));
    expect(v['c2_work_j'], closeTo(450, 1e-9));
    expect(v['machine_strokes'], 321);
  });

  test('additional stroke data gives the stroke power', () {
    final v = decodeConcept2(0x36, [
      ...le(6000, 3),
      ...le(212, 2),
      ...le(900, 2),
      ...le(321, 2),
      ...le(0, 3),
      ...le(0, 3),
      ...le(0, 3),
    ]);
    expect(v['w'], 212);
    expect(v['machine_strokes'], 321);
  });

  test('additional status 2: average power and calories', () {
    final v = decodeConcept2(0x33, [
      ...le(6000, 3),
      2,
      ...le(185, 2),
      ...le(96, 2),
      ...le(11900, 2),
      ...le(190, 2),
      ...le(900, 2),
      ...le(1200, 3),
      ...le(500, 3),
    ]);
    expect(v['avg_w'], 185);
    expect(v['machine_kcal'], 96);
    expect(v['c2_last_split_time'], closeTo(120, 1e-9));
    expect(v['c2_last_split_distance'], 500);
  });

  test('a multiplexed record decodes like its own characteristic', () {
    final status = [
      ...le(6000, 3),
      ...le(4237, 2),
      26,
      148,
      ...le(11800, 2),
      ...le(12050, 2),
      ...le(0, 2),
      ...le(0, 3),
    ];
    expect(
      decodeConcept2(concept2MultiplexedId, [0x32, ...status]),
      decodeConcept2(0x32, status),
    );
  });

  test('a short record is rejected, an unknown one gives nothing', () {
    expect(() => decodeConcept2(0x31, [1, 2, 3]), throwsFormatException);
    expect(
      () => decodeConcept2(0x35, List.filled(19, 0)),
      throwsFormatException,
    );
    expect(decodeConcept2(0x3b, List.filled(6, 0)), isEmpty);
  });

  test('a BikeErg records as a bike, everything else as a rower', () {
    expect(concept2Machine(null), FtmsMachine.rower);
    expect(concept2Machine(0), FtmsMachine.rower);
    expect(concept2Machine(128), FtmsMachine.rower);
    expect(concept2Machine(192), FtmsMachine.bike);
  });

  TrainingBleReport report({required bool ftms}) => TrainingBleReport(
    device: const TrainingDevice(id: 'pm5', name: 'PM5 430000000', rssi: -60),
    services: [
      if (ftms)
        const TrainingGattService('1826', [
          TrainingGattCharacteristic(uuid: '2ad1', notify: true),
        ]),
      TrainingGattService(concept2RowingService, [
        for (final id in concept2LiveIds)
          TrainingGattCharacteristic(uuid: concept2Uuid(id), notify: true),
      ]),
    ],
  );

  test('a PM5 is recognised with old and new firmware', () {
    for (final ftms in [false, true]) {
      final r = report(ftms: ftms);
      expect(r.concept2, isTrue);
      expect(r.machines, [FtmsMachine.rower]);
      expect(r.canRecord, isTrue);
    }
  });

  test('UUIDs follow the Concept2 base', () {
    expect(concept2Uuid(0x31), 'ce060031-43e5-11e4-916c-0800200c9a66');
    expect(concept2DiscoveryService, 'ce060000-43e5-11e4-916c-0800200c9a66');
  });
}
