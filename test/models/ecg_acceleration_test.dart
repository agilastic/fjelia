import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/ecg.dart';
import 'package:fjelia/services/ecg_ble_service.dart';
import 'package:fjelia/services/ecg_storage_service.dart';

/// A Polar PMD ACC notification: type 2, 64-bit device time, frame type 1,
/// then x/y/z as signed 16-bit little endian per sample.
List<int> accFrame(int lastNs, List<(int, int, int)> samples) {
  int u8(int v, int shift) => (v >> shift) & 255;
  return [
    2,
    for (var i = 0; i < 8; i++) u8(lastNs, 8 * i),
    1,
    for (final (x, y, z) in samples)
      for (final v in [x, y, z]) ...[v & 255, (v >> 8) & 255],
  ];
}

void main() {
  group('AccelerationFrame', () {
    test('decodes signed milli-g samples and the device time', () {
      final frame = AccelerationFrame.decode(
        accFrame(599000000000, [(12, -980, 40), (-3, -1001, 0)]),
      );
      expect(frame.lastSampleNs, 599000000000);
      expect(frame.samplesMilliG, [
        (x: 12, y: -980, z: 40),
        (x: -3, y: -1001, z: 0),
      ]);
    });

    test('refuses other streams, frame types and truncated frames', () {
      final good = accFrame(1, [(1, 2, 3)]);
      expect(
        () => AccelerationFrame.decode([0, ...good.skip(1)]),
        throwsFormatException,
      );
      expect(
        () => AccelerationFrame.decode([...good]..[9] = 0),
        throwsFormatException,
      );
      expect(
        () => AccelerationFrame.decode(good.sublist(0, good.length - 1)),
        throwsFormatException,
      );
      expect(
        () => AccelerationFrame.decode(good.sublist(0, 10)),
        throwsFormatException,
      );
    });
  });

  test('the timeline places frames on the device clock and drops repeats', () {
    final timeline = AccelerationTimeline(25);
    final at = DateTime.utc(2026, 11, 12, 23);
    // Two samples 40 ms apart, then the next two.
    final first = timeline.add(
      AccelerationFrame(1040000000, const [
        (x: 0, y: 0, z: 1000),
        (x: 0, y: 0, z: 1000),
      ]),
      at,
    )!;
    final second = timeline.add(
      AccelerationFrame(1120000000, const [
        (x: 0, y: 1, z: 1000),
        (x: 0, y: 2, z: 1000),
      ]),
      at,
    )!;
    expect(first.offsetUs, 0);
    expect(second.offsetUs, 80000);
    expect(second.deviceLastSampleNs, 1120000000);
    // A frame sent again (or from an older time) is not stored twice.
    expect(
      timeline.add(
        AccelerationFrame(1120000000, const [(x: 0, y: 0, z: 0)]),
        at,
      ),
      isNull,
    );
    expect(timeline.sampleCount, 4);
  });

  test('chunks survive storage as JSON', () {
    final chunk = AccelerationChunk(
      offsetUs: 80000,
      samplesMilliG: const [(x: -5, y: 7, z: 1002)],
      deviceLastSampleNs: 9007199254740993, // above 2^53
      receivedAt: DateTime.utc(2026, 11, 12, 23, 1),
    );
    final back = AccelerationChunk.fromJson(
      jsonDecode(jsonEncode(chunk.toJson())) as Map<String, dynamic>,
    );
    expect(chunk.toJson()['stream'], 'acc');
    expect(back.offsetUs, 80000);
    expect(back.samplesMilliG, chunk.samplesMilliG);
    expect(back.deviceLastSampleNs, 9007199254740993);
    expect(back.receivedAt, DateTime.utc(2026, 11, 12, 23, 1));
  });

  group('accelerometer settings', () {
    test('25 Hz and 16 bit are offered', () {
      expect(
        parseAccelerationSettings([
          0,
          2,
          25,
          0,
          50,
          0,
          1,
          1,
          16,
          0,
          2,
          1,
          8,
          0,
        ]),
        (sampleRate: 25, resolution: 16),
      );
    });

    test('other offers and malformed settings are refused', () {
      expect(
        () => parseAccelerationSettings([0, 1, 50, 0, 1, 1, 16, 0]),
        throwsFormatException,
      );
      expect(
        () => parseAccelerationSettings([0, 1, 25]),
        throwsFormatException,
      );
      expect(
        () => parseAccelerationSettings([9, 1, 25, 0]),
        throwsFormatException,
      );
      expect(() => parseAccelerationSettings([0, 0]), throwsFormatException);
    });
  });

  group('overnight recording storage', () {
    late AppDatabase db;
    late EcgStorageService storage;
    late Directory dir;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      storage = EcgStorageService(db, priorityReader: (_) async => const []);
      dir = await Directory.systemTemp.createTemp('fjelia_sleep_csv');
    });
    tearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    Future<String> record({double? accelerationRate = 25}) async {
      final id = await storage.begin(
        deviceId: 'h10',
        deviceName: 'Polar H10',
        rate: 130,
        resolution: 14,
        accelerationRate: accelerationRate,
        purpose: 'sleep',
      );
      await storage.append(
        id,
        [
          EcgChunk(
            offsetUs: 0,
            microvolts: const [10, -20],
            deviceLastSampleNs: 1000000000,
          ),
        ],
        0,
        acceleration: [
          AccelerationChunk(
            offsetUs: 0,
            samplesMilliG: const [(x: 1, y: 2, z: 3), (x: 4, y: 5, z: 6)],
            deviceLastSampleNs: 2000000000,
          ),
        ],
        count: 2,
        durationMs: 15,
        gaps: 0,
      );
      await storage.finish(id, interrupted: false);
      return id;
    }

    test('ECG and accelerometer chunks are read back separately', () async {
      final id = await record();
      expect((await storage.chunks(id)).single.microvolts, [10, -20]);
      expect((await storage.accelerationChunks(id)).single.samplesMilliG.last, (
        x: 4,
        y: 5,
        z: 6,
      ));
    });

    test('exports both signals on the device clock', () async {
      final id = await record();
      final files = await storage.exportSleepCsvFiles(
        (await storage.recording(id))!,
        directory: dir,
      );
      final ecg = await files[0].readAsLines();
      final acc = await files[1].readAsLines();
      expect(ecg[0], startsWith('# fjelia-sleep-ecg-v1 '));
      // 130 Hz: the first sample lies one period before the last one.
      expect(ecg.sublist(3), ['992307692,10', '1000000000,-20']);
      expect(acc[2], 'time_ns,x_mg,y_mg,z_mg');
      expect(acc.sublist(3), ['1960000000,1,2,3', '2000000000,4,5,6']);
    });

    test('a recording without accelerometer rate cannot be exported', () async {
      final id = await record(accelerationRate: null);
      await expectLater(
        storage.exportSleepCsvFiles(
          (await storage.recording(id))!,
          directory: dir,
        ),
        throwsStateError,
      );
    });

    test('notes are trimmed, cleared when empty and capped', () async {
      final id = await record();
      await storage.updateNote(id, '  slept badly  ');
      expect((await storage.recording(id))!.note, 'slept badly');
      await storage.updateNote(id, '   ');
      expect((await storage.recording(id))!.note, isNull);
      await storage.updateNote(id, 'x' * 13000);
      expect((await storage.recording(id))!.note, hasLength(12000));
    });
  });
}
