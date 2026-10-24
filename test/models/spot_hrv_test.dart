import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/models/spot_hrv.dart';

List<SpotRrSample> samples(List<double> values) {
  var time = 0.0;
  return [for (final rr in values) SpotRrSample(time += rr, rr)];
}

void main() {
  test('8-bit HR decodes all RR intervals and contact flags', () {
    final p = H10HeartRatePacket.decode([0x16, 60, 0, 4, 0, 2]);
    expect(p.bpm, 60);
    expect(p.contact, true);
    expect(p.rrMs, [1000, 500]);
  });
  test('16-bit HR skips optional energy field before RR data', () {
    final p = H10HeartRatePacket.decode([0x19, 44, 1, 20, 0, 0, 4]);
    expect(p.bpm, 300);
    expect(p.contact, isNull);
    expect(p.rrMs, [1000]);
    expect(H10HeartRatePacket.decode([4, 70]).contact, false);
    expect(H10HeartRatePacket.decode([0, 70]).rrMs, isEmpty);
  });
  test('rejects incomplete HR and RR fields', () {
    for (final bytes in <List<int>>[
      [],
      [0],
      [1, 20],
      [16, 60, 1],
      [8, 60, 1],
    ]) {
      expect(() => H10HeartRatePacket.decode(bytes), throwsFormatException);
    }
  });
  test('time-domain metrics match known RR values', () {
    final a = SpotHrvAnalysis.calculate(samples([1000, 1020, 980, 1010]), 4);
    expect(a.rmssdMs, closeTo(math.sqrt(2900 / 3), 1e-9));
    expect(a.sdnnMs, closeTo(math.sqrt(875 / 3), 1e-9));
    expect(a.meanHr, closeTo(60000 / 1002.5, 1e-9));
    expect(a.lnRmssd, closeTo(math.log(math.sqrt(2900 / 3)), 1e-9));
  });
  test('outlier is excluded without joining non-adjacent intervals', () {
    final a = SpotHrvAnalysis.calculate(
      samples([1000, 1020, 5000, 1100, 1110]),
      10,
    );
    expect(a.accepted, 4);
    expect(a.pairs, 2);
    expect(a.rmssdMs, closeTo(math.sqrt(250), 1e-9));
    expect(a.reliable, false);
  });
  test('local median screens plausible spikes and preserves raw RMSSD', () {
    final rr = List<double>.filled(100, 1000);
    rr[40] = 1800;
    final a = SpotHrvAnalysis.calculate(samples(rr), 101);
    expect(a.accepted, 99);
    expect(a.rmssdMs, 0);
    expect(a.rawRmssdMs!, greaterThan(0));
    expect(a.lnRmssd, isNull);
    expect(a.rejections[40], contains('median'));
  });
  test('does not compute successive differences across a missing-data gap', () {
    final a = SpotHrvAnalysis.calculate([
      const SpotRrSample(1000, 1000),
      const SpotRrSample(2000, 1000),
      const SpotRrSample(12000, 1100),
      const SpotRrSample(13100, 1100),
    ], 14);
    expect(a.pairs, 2);
    expect(a.rmssdMs, 0);
    expect(a.coverage, lessThan(.9));
  });
  test('poor contact is excluded and cannot yield a reliable result', () {
    final a = SpotHrvAnalysis.calculate([
      for (var i = 1; i <= 120; i++)
        SpotRrSample((i * 1000).toDouble(), 1000, contact: false),
    ], 120);
    expect(a.accepted, 0);
    expect(a.rmssdMs, isNull);
    expect(a.reliable, false);
  });
  test('settling and out-of-window RR values are not recorded', () {
    final capture = SpotHrvCapture(
      startedAt: DateTime(2026),
      durationSeconds: 5,
    );
    const p = H10HeartRatePacket(60, [1000], true);
    capture.add(p, const Duration(seconds: 60));
    expect(capture.samples, isEmpty);
    capture.add(p, const Duration(seconds: 61));
    capture.add(
      const H10HeartRatePacket(60, [1000, 1000], true),
      const Duration(seconds: 63),
    );
    capture.add(
      const H10HeartRatePacket(60, [1000, 1000], true),
      const Duration(seconds: 65),
    );
    capture.add(p, const Duration(seconds: 66));
    expect(capture.samples.map((s) => s.elapsedMs), [
      1000,
      2000,
      3000,
      4000,
      5000,
    ]);
    expect(capture.complete(const Duration(seconds: 64)), false);
    expect(capture.complete(const Duration(seconds: 65)), true);
  });
}
