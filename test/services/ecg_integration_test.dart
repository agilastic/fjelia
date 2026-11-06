import 'dart:convert';
import 'dart:typed_data';

import 'package:fjelia/models/ecg.dart';
import 'package:fjelia/services/ecg_ble_service.dart';
import 'package:fjelia/services/ecg_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PMD decodes full device timestamp and signed 24-bit microvolts', () {
    const time = 599616023171427290;
    final bytes = [
      0,
      for (var i = 0; i < 8; i++) (time >> (i * 8)) & 255,
      0,
      for (final value in [-8388608, -123, 0, 456, 8388607])
        for (var i = 0; i < 3; i++) (value >> (i * 8)) & 255,
    ];
    final frame = EcgFrame.decode(bytes);
    expect(frame.lastSampleNs, time);
    expect(frame.microvolts, [-8388608, -123, 0, 456, 8388607]);
    expect(
      () => EcgFrame.decode(bytes.sublist(0, bytes.length - 1)),
      throwsFormatException,
    );
    expect(
      () => EcgFrame.decode([...bytes.take(9), 128, ...bytes.skip(10)]),
      throwsFormatException,
    );
  });

  test(
    'sample timeline ignores duplicates and preserves rather than closes gaps',
    () {
      final timeline = EcgTimeline(130), now = DateTime.utc(2026);
      final first = timeline.add(
        const EcgFrame(1000000000, [10, 20, 30]),
        now,
      )!;
      expect(first.offsetUs, 0);
      final nextTime = 1000000000 + (3e9 / 130).round();
      final next = timeline.add(EcgFrame(nextTime, [40, 50, 60]), now)!;
      expect(next.offsetUs, closeTo(3e6 / 130, 1));
      expect(timeline.add(EcgFrame(nextTime, [40, 50, 60]), now), isNull);
      expect(timeline.sampleCount, 6);
      final gap = timeline.add(const EcgFrame(2000000000, [70, 80, 90]), now)!;
      expect(gap.offsetUs, greaterThan(900000));
      expect(timeline.gaps, 1);
      final restored = EcgChunk.fromJson(
        jsonDecode(jsonEncode(gap.toJson())) as Map<String, dynamic>,
      );
      expect(restored.deviceLastSampleNs, 2000000000);
      expect(restored.microvolts, [70, 80, 90]);
    },
  );

  test('settings negotiation rejects unsupported rates and malformed TLVs', () {
    expect(parseEcgSettings([0, 1, 130, 0, 1, 1, 14, 0]), (
      sampleRate: 130,
      resolution: 14,
    ));
    expect(
      () => parseEcgSettings([0, 1, 100, 0, 1, 1, 14, 0]),
      throwsFormatException,
    );
    expect(() => parseEcgSettings([0, 2, 130, 0]), throwsFormatException);
  });

  test('waveform display preserves extrema without modifying raw samples', () {
    final raw = List<int>.filled(10000, 0)..[5000] = 9999;
    final points = ecgDisplayPoints(
      [EcgChunk(offsetUs: 0, microvolts: raw)],
      1000,
      startSeconds: 0,
      endSeconds: 10,
      pixels: 100,
    );
    expect(points.any((p) => p.uv == 9999), isTrue);
    expect(points.length, lessThanOrEqualTo(202));
    expect(raw.length, 10000);
    expect(raw[5000], 9999);
  });

  test('CSV import converts explicit mV and millisecond units', () {
    final imported = decodeEcgImport(
      Uint8List.fromList(
        utf8.encode('time_ms,ecg_mv\n0,1.25\n2,-0.5\n4,0\n6,0.001\n'),
      ),
    );
    expect(imported.kind, 'waveform');
    expect(imported.sampleRateHz, closeTo(500, .001));
    expect(imported.sampleCount, 4);
    expect(imported.chunks.single.microvolts, [1250, -500, 0, 1]);
    expect(imported.durationMs, 8);
  });

  test('CSV keeps declared timing gaps and original frame timestamps', () {
    final imported = decodeEcgImport(
      Uint8List.fromList(
        utf8.encode(
          '# fjelia-ecg-v1 {"sample_rate_hz":100,"recorded_at":"2026-11-05T12:00:00Z"}\n'
          'time_seconds,ecg_uv,device_frame_end_ns,frame_sample_index\n'
          '0,12,599616023171427290,0\n0.01,13,599616023171427290,1\n'
          '0.10,22,599616023271427290,0\n0.11,23,599616023271427290,1\n',
        ),
      ),
    );
    expect(imported.chunks, hasLength(2));
    expect(imported.chunks.last.offsetUs, 100000);
    expect(imported.chunks.first.deviceLastSampleNs, 599616023171427290);
    expect(imported.recordedAt, DateTime.utc(2026, 11, 5, 12));
  });

  test('PDF remains a report; unsupported or unordered CSV is rejected', () {
    final pdf = decodeEcgImport(
      Uint8List.fromList(ascii.encode('%PDF-1.7\nreport\n%%EOF')),
    );
    expect(pdf.kind, 'report');
    expect(pdf.chunks, isEmpty);
    expect(pdf.sampleRateHz, isNull);
    for (final csv in [
      'amplitude\n1\n2',
      'time_seconds,ecg_uv\n0,1\n0,2',
      'time_seconds,ecg_uv\n0,NaN\n1,2',
      'time_seconds,ecg_uv\n0,1\n-1,2',
    ]) {
      expect(
        () => decodeEcgImport(Uint8List.fromList(utf8.encode(csv))),
        throwsFormatException,
      );
    }
  });
}
