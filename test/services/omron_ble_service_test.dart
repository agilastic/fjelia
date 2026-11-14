import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/services/omron_ble_service.dart';

OmronModelProfile profile(String model) =>
    omronModelProfiles.firstWhere((p) => p.model == model);

/// Builds one stored record: each field is `(first bit, last bit) → value`,
/// counted the way the monitor's layout tables count them.
List<int> record(OmronModelProfile p, Map<(int, int), int> fields) {
  final length = p.recordSize;
  var bits = BigInt.zero;
  fields.forEach((range, value) {
    final (first, last) = range;
    expect(value, lessThan(1 << (last - first + 1)), reason: '$range');
    bits |= BigInt.from(value) << (length * 8 - last - 1);
  });
  final bytes = [
    for (var i = length - 1; i >= 0; i--)
      ((bits >> (8 * i)) & BigInt.from(255)).toInt(),
  ];
  final raw = p.endian == 'little' ? bytes.reversed.toList() : bytes;
  if (p.layout == 'modern14') {
    raw[12] = raw.take(12).fold<int>(0, (a, v) => a + v) & 255;
    raw[13] = raw[12] ^ 255;
  }
  return raw;
}

/// 2026-03-14 07:42:31, 132/84, pulse 61, as each layout stores it.
Map<(int, int), int> classic14({int second = 31, int sys = 132}) => {
  (0, 7): 84,
  (8, 15): sys - 25,
  (16, 23): 26,
  (24, 31): 61,
  (32, 32): 1, // movement
  (33, 33): 0,
  (34, 37): 3,
  (38, 42): 14,
  (43, 47): 7,
  (52, 57): 42,
  (58, 63): second,
};

Map<(int, int), int> modern14({int second = 31}) => {
  (104, 111): 132 - 25,
  (96, 103): 84,
  (88, 95): 61,
  (82, 87): 26,
  (75, 79): 7,
  (70, 74): 14,
  (66, 69): 3,
  (65, 65): 1, // irregular heartbeat
  (64, 64): 0,
  (58, 63): second,
  (52, 57): 42,
};

Map<(int, int), int> packed16({
  int year = 26,
  int month = 3,
  int day = 14,
  int minute = 42,
  int sys = 132,
  int dia = 84,
}) => {
  (68, 73): minute,
  (74, 79): 31,
  (80, 80): 0,
  (81, 81): 1, // irregular heartbeat
  (82, 85): month,
  (86, 90): day,
  (91, 95): 7,
  (98, 103): year,
  (104, 111): 61,
  (112, 119): dia,
  (120, 127): sys - 25,
};

void expectReading(OmronBpRecord? r, {int user = 1, int second = 31}) {
  expect(r, isNotNull);
  expect(r!.measuredAt, DateTime(2026, 3, 14, 7, 42, second));
  expect((r.systolic, r.diastolic, r.heartRate), (132, 84, 61));
  expect(r.user, user);
}

/// A monitor's memory behind the Omron command protocol: answers start,
/// end and block-read commands from [memory], and records what was asked.
class FakeOmronMonitor {
  FakeOmronMonitor(this.memory, {this.failAt});
  final Map<int, int> memory;
  final int? failAt;
  final commands = <List<int>>[];
  var started = 0, ended = 0;

  static List<int> packet(List<int> body) {
    final p = [body.length + 3, ...body, 0];
    p.add(p.fold<int>(0, (a, b) => a ^ b));
    return p;
  }

  Future<List<int>> send(List<int> command) async {
    commands.add(command);
    expect(command.fold<int>(0, (a, b) => a ^ b), 0, reason: 'command CRC');
    switch (command[1]) {
      case 0:
        started++;
        return packet([0x80, 0, 0, 0, 0]);
      case 15:
        ended++;
        return packet([0x8f, 0, 0, 0, 0]);
      case 1:
        final address = (command[3] << 8) | command[4];
        final size = command[5];
        if (failAt != null && address >= failAt!) {
          throw StateError('link lost');
        }
        return packet([
          0x81,
          0,
          command[3],
          command[4],
          size,
          for (var i = 0; i < size; i++) memory[address + i] ?? 0xff,
        ]);
    }
    throw StateError('unexpected command $command');
  }
}

void main() {
  group('decodeOmronRecord', () {
    test('classic14 (big endian, 112 bits)', () {
      final p = profile('HEM-7322T');
      final r = decodeOmronRecord(p, record(p, classic14()), 2);
      expectReading(r, user: 2);
      expect(r!.movement, isTrue);
      expect(r.irregularPulse, isFalse);
    });

    test('classic14 caps seconds the monitor counts past 59', () {
      final p = profile('HEM-7322T');
      expectReading(
        decodeOmronRecord(p, record(p, classic14(second: 62)), 1),
        second: 59,
      );
    });

    test('modern14 (little endian) checks its checksum', () {
      final p = profile('HEM-7143T');
      final raw = record(p, modern14());
      final r = decodeOmronRecord(p, raw, 1);
      expectReading(r);
      expect(r!.irregularPulse, isTrue);

      final corrupted = [...raw]..[3] ^= 0x10;
      expect(decodeOmronRecord(p, corrupted, 1), isNull);
      // Second 63 marks an unfinished slot.
      expect(decodeOmronRecord(p, record(p, modern14(second: 63)), 1), isNull);
    });

    test('packed16 (little endian, 128 bits)', () {
      final p = profile('HEM-7155T');
      final r = decodeOmronRecord(p, record(p, packed16()), 1);
      expectReading(r);
      expect(r!.irregularPulse, isTrue);
    });

    test('modern16 rejects years before 2020 as unset', () {
      final p = profile('HEM-7380T');
      expectReading(decodeOmronRecord(p, record(p, packed16()), 1));
      expect(decodeOmronRecord(p, record(p, packed16(year: 19)), 1), isNull);
    });

    test('impossible values and dates give no reading', () {
      final p = profile('HEM-7155T');
      expect(
        decodeOmronRecord(p, record(p, packed16(sys: 80, dia: 90)), 1),
        isNull,
      );
      expect(
        decodeOmronRecord(p, record(p, packed16(month: 2, day: 30)), 1),
        isNull,
      );
      expect(decodeOmronRecord(p, record(p, packed16(month: 0)), 1), isNull);
      expect(decodeOmronRecord(p, record(p, packed16(minute: 60)), 1), isNull);
    });
  });

  group('OmronMemoryReader', () {
    Map<int, int> memoryWith(Map<int, List<int>> records) => {
      for (final e in records.entries)
        for (var i = 0; i < e.value.length; i++) e.key + i: e.value[i],
    };

    test('reads every user, skips empty slots and removes copies', () async {
      final p = profile('HEM-7155T');
      final first = record(p, packed16());
      final later = record(p, packed16(day: 15, sys: 141, dia: 88));
      final monitor = FakeOmronMonitor(
        memoryWith({
          p.starts[0]: later,
          p.starts[0] + 16: first,
          // The same reading again in the next slot.
          p.starts[0] + 32: first,
          p.starts[1] + 16: record(p, packed16(minute: 5)),
        }),
      );
      final status = <String>[];
      final records = await OmronMemoryReader(
        p,
        monitor.send,
        onStatus: status.add,
      ).readRecords();

      expect(
        [for (final r in records) (r.user, r.measuredAt, r.systolic)],
        [
          (2, DateTime(2026, 3, 14, 7, 5, 31), 132),
          (1, DateTime(2026, 3, 14, 7, 42, 31), 132),
          (1, DateTime(2026, 3, 15, 7, 42, 31), 141),
        ],
      );
      expect(status, ['Reading user 1…', 'Reading user 2…']);
      expect((monitor.started, monitor.ended), (1, 1));

      // Each user's area is read in contiguous blocks of at most blockSize.
      final reads = monitor.commands.where((c) => c[1] == 1).toList();
      expect(reads.every((c) => c[5] <= p.blockSize), isTrue);
      expect(
        reads.fold<int>(0, (n, c) => n + c[5]),
        (p.counts[0] + p.counts[1]) * p.recordSize,
      );
      expect((reads.first[3] << 8) | reads.first[4], p.starts[0]);
    });

    test('ends the transfer even when a block read fails', () async {
      final p = profile('HEM-7322T');
      final monitor = FakeOmronMonitor({}, failAt: p.starts[0] + 0x38);
      await expectLater(
        OmronMemoryReader(p, monitor.send).readRecords(),
        throwsStateError,
      );
      expect(monitor.ended, 1);
    });

    test('rejects a block for another address', () async {
      final p = profile('HEM-7155T');
      Future<List<int>> send(List<int> c) async => c[1] == 1
          ? FakeOmronMonitor.packet([
              0x81,
              0,
              0,
              0,
              c[5],
              ...List.filled(c[5], 0),
            ])
          : FakeOmronMonitor({}).send(c);
      await expectLater(
        OmronMemoryReader(p, send).readRecords(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('invalid memory block'),
          ),
        ),
      );
    });

    test('rejects a monitor that refuses the transfer', () async {
      final p = profile('HEM-7155T');
      Future<List<int>> send(List<int> c) async =>
          FakeOmronMonitor.packet([0x80, 1, 0, 0, 0]);
      await expectLater(
        OmronMemoryReader(p, send).readRecords(),
        throwsStateError,
      );
    });
  });

  group('packets', () {
    test('a single channel passes checked packets through', () {
      final a = OmronPacketAssembler(1);
      final good = FakeOmronMonitor.packet([0x80, 0, 0, 0, 0]);
      expect(a.add(0, good), good);
      expect(a.add(0, [...good]..[2] ^= 1), isNull, reason: 'bad checksum');
      expect(a.add(0, FakeOmronMonitor.packet([0x80, 0])), isNull);
    });

    test('several channels are joined in order and trimmed', () {
      final a = OmronPacketAssembler(4);
      final packet = FakeOmronMonitor.packet([
        0x81,
        0,
        0,
        0x98,
        16,
        ...List.generate(16, (i) => i),
      ]);
      expect(packet.length, 24);
      final second = [...packet.sublist(16), ...List.filled(8, 0xee)];
      expect(a.add(1, second), isNull, reason: 'channel 0 still missing');
      expect(a.add(0, packet.sublist(0, 16)), packet);
      // The buffers are clear for the next packet.
      expect(a.add(1, second), isNull);
    });

    test('commands are split for the command channels', () {
      final command = List.generate(20, (i) => i);
      expect(omronCommandParts(command, 1), [command]);
      expect(omronCommandParts(command, 4), [
        command.sublist(0, 16),
        command.sublist(16),
      ]);
    });
  });

  group('standard Bluetooth blood pressure', () {
    List<int> sfloat(int mantissa, int exponent) {
      final raw = ((exponent & 0x0f) << 12) | (mantissa & 0x0fff);
      return [raw & 255, raw >> 8];
    }

    List<int> measurement({
      int flags = 0x1e,
      List<int>? sys,
      List<int>? dia,
      List<int> time = const [0xea, 0x07, 3, 14, 7, 42, 31],
      int user = 2,
      int status = 0x05,
    }) => [
      flags,
      ...sys ?? sfloat(132, 0),
      ...dia ?? sfloat(84, 0),
      ...sfloat(100, 0),
      if (flags & 0x02 != 0) ...time,
      if (flags & 0x04 != 0) ...sfloat(610, -1),
      if (flags & 0x08 != 0) user,
      if (flags & 0x10 != 0) ...[status, 0],
    ];

    test('reads values, time, pulse, user and status', () {
      final r = parseStandardBpMeasurement(measurement());
      expectReading(r, user: 2);
      expect(r!.irregularPulse, isTrue);
      expect(r.movement, isTrue);
    });

    test('converts kPa', () {
      final r = parseStandardBpMeasurement(
        measurement(flags: 0x07, sys: sfloat(176, -1), dia: sfloat(112, -1)),
      );
      expect((r!.systolic, r.diastolic), (132, 84));
      expect(r.user, 1);
    });

    test('a reading without its time is not imported', () {
      expect(parseStandardBpMeasurement(measurement(flags: 0x04)), isNull);
    });

    test('invalid dates, values and short packets give no reading', () {
      expect(
        parseStandardBpMeasurement(
          measurement(time: const [0xea, 0x07, 2, 30, 7, 42, 31]),
        ),
        isNull,
      );
      expect(
        parseStandardBpMeasurement(measurement(sys: sfloat(80, 0))),
        isNull,
      );
      expect(parseStandardBpMeasurement([0x1e, 1, 2, 3]), isNull);
      // A user flag without the user byte.
      final truncated = measurement(flags: 0x0e)..removeLast();
      expect(parseStandardBpMeasurement(truncated), isNull);
    });

    test('user 0 counts as the first user', () {
      expect(parseStandardBpMeasurement(measurement(user: 0))!.user, 1);
    });

    test('record access notifications', () {
      expect(
        (parseRacpNotification([0x05, 0, 0x2c, 0x01]) as RacpStoredCount).count,
        300,
      );
      final response = parseRacpNotification([0x06, 0, 0x01, 0x06]);
      expect(
        (response as RacpResponse).request == 0x01 && response.code == 0x06,
        isTrue,
      );
      expect(parseRacpNotification([0x05, 1, 0, 0]), isNull);
      expect(parseRacpNotification([0x06, 0, 1]), isNull);
      expect(parseRacpNotification([0x07, 0, 0, 0]), isNull);
    });
  });

  test('uniqueOmronRecords keeps one reading per user and second', () {
    OmronBpRecord r(int user, int minute, int sys) => OmronBpRecord(
      measuredAt: DateTime(2026, 3, 14, 7, minute),
      systolic: sys,
      diastolic: 80,
      heartRate: 60,
      user: user,
    );
    final unique = uniqueOmronRecords([
      r(1, 30, 130),
      r(1, 10, 120),
      r(2, 10, 140),
      r(1, 30, 131),
    ]);
    expect(
      [for (final x in unique) (x.user, x.systolic)],
      [(1, 120), (2, 140), (1, 131)],
    );
  });

  group('pairing', () {
    final service = OmronBleService();
    const key = 'omron_ble_pairing_keys_v1';

    test('a first pairing needs the athlete\'s confirmation', () async {
      FlutterSecureStorage.setMockInitialValues({});
      expect(await service.needsPairing('dev', 'HEM-7322T'), isTrue);
      // Models paired by the operating system and standard monitors never.
      expect(await service.needsPairing('dev', 'HEM-7143T'), isFalse);
      expect(await service.needsPairing('dev', standardBpModel), isFalse);
      await expectLater(
        service.readRecords(
          deviceId: 'dev',
          model: 'HEM-7322T',
          authorizeFirstPairing: false,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('explicit user confirmation'),
          ),
        ),
      );
    });

    test('a paired monitor keeps its model', () async {
      FlutterSecureStorage.setMockInitialValues({
        key: jsonEncode({
          'dev': {
            'key': '00112233445566778899aabbccddeeff',
            'model': 'HEM-7322T',
          },
        }),
      });
      expect(await service.pairedModel('dev'), 'HEM-7322T');
      expect(await service.needsPairing('dev', 'HEM-7322T'), isFalse);
      await expectLater(
        service.readRecords(
          deviceId: 'dev',
          model: 'HEM-7155T',
          authorizeFirstPairing: true,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('paired as HEM-7322T'),
          ),
        ),
      );
    });

    test('older pairings stored only the key', () async {
      FlutterSecureStorage.setMockInitialValues({
        key: jsonEncode({'dev': '00112233445566778899aabbccddeeff'}),
      });
      expect(await service.pairedModel('dev'), isNull);
      expect(await service.needsPairing('dev', 'HEM-7322T'), isFalse);
    });

    test('unreadable pairing data counts as unpaired', () async {
      FlutterSecureStorage.setMockInitialValues({key: 'not json'});
      expect(await service.needsPairing('dev', 'HEM-7322T'), isTrue);
    });

    test('an unknown model is refused', () async {
      FlutterSecureStorage.setMockInitialValues({});
      await expectLater(
        service.readRecords(
          deviceId: 'dev',
          model: 'HEM-0000',
          authorizeFirstPairing: true,
        ),
        throwsArgumentError,
      );
    });
  });

  test('found devices are ranked by what they advertise', () {
    const standard = OmronFoundDevice('a', 'BP', -70, [
      '00001810-0000-1000-8000-00805f9b34fb',
    ]);
    const omron = OmronFoundDevice('b', 'HEM', -40, [
      '0000fe4a-0000-1000-8000-00805f9b34fb',
    ]);
    const other = OmronFoundDevice('c', '', -30, []);
    expect(standard.advertisedCompatibility, 'standard');
    expect(omron.advertisedCompatibility, 'omron');
    expect(other.advertisedCompatibility, 'unknown');
  });

  test('every model profile describes a readable memory layout', () {
    for (final p in omronModelProfiles) {
      expect(p.starts.length, p.counts.length, reason: p.model);
      expect(p.recordSize, p.layout.endsWith('16') ? 16 : 14, reason: p.model);
      expect(p.blockSize, inInclusiveRange(1, 56), reason: p.model);
      expect(p.rx, isNotEmpty, reason: p.model);
      expect(p.tx, isNotEmpty, reason: p.model);
    }
    expect(
      omronModelProfiles.map((p) => p.model).toSet().length,
      omronModelProfiles.length,
    );
  });
}
