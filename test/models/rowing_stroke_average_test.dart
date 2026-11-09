import 'package:fjelia/models/ftms.dart';
import 'package:fjelia/models/indoor_recording.dart';
import 'package:fjelia/models/rowing_stroke_average.dart';
import 'package:fjelia/models/training_device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime.utc(2026, 11, 8, 12);
  DateTime at(int seconds) => start.add(Duration(seconds: seconds));
  Map<String, num> stroke(int count, int pace, int rate, int power) => {
    'machine_strokes': count,
    'pace_500m': pace,
    'cad': rate,
    'w': power,
  };

  test('pace, rate and power average the last three distinct strokes', () {
    final window = RowingStrokeAverage();
    window.ingest(stroke(40, 180, 20, 180), at(0));
    window.ingest(stroke(41, 210, 24, 210), at(2));
    window.ingest(stroke(42, 240, 28, 240), at(4));
    final metrics = window.live(at(4));
    expect(metrics.pace.value, 210);
    expect(metrics.rate.value, 24);
    expect(metrics.power.value, 210);
    expect(metrics.pace.strokes, 3);
    window.ingest(stroke(43, 270, 32, 270), at(6));
    expect(window.live(at(6)).pace.value, 240);
    expect(window.live(at(6)).rate.value, 28);
  });

  test('frequent notifications do not give one stroke extra weight', () {
    final window = RowingStrokeAverage();
    window.ingest(stroke(40, 180, 20, 180), at(0));
    window.ingest(stroke(41, 210, 24, 210), at(2));
    window.ingest(stroke(42, 240, 28, 240), at(4));
    for (var i = 0; i < 20; i++) {
      window.ingest(stroke(42, 270, 30, 270), at(4));
    }
    final metrics = window.live(at(4));
    expect(metrics.pace.value, 220);
    expect(metrics.power.value, 220);
    expect(metrics.rate.value, closeTo(74 / 3, .001));
    expect(metrics.power.strokes, 3);
  });

  test(
    'split packets join their actual stroke without filling absent fields',
    () {
      final window = RowingStrokeAverage();
      window.ingest({'machine_strokes': 1, 'cad': 20}, at(0));
      window.ingest({'pace_500m': 180, 'w': 100}, at(1));
      window.ingest({'machine_strokes': 2, 'cad': 24}, at(2));
      final partial = window.live(at(2));
      expect(partial.pace.value, 180);
      expect(partial.pace.strokes, 1);
      expect(partial.rate.value, 22);
      expect(partial.rate.strokes, 2);
      window.ingest({'pace_500m': 240}, at(3));
      expect(window.live(at(3)).pace.value, 210);
      expect(window.live(at(3)).power.strokes, 1);
    },
  );

  test('a jump in the counter never invents the skipped strokes', () {
    final window = RowingStrokeAverage();
    window.ingest(stroke(40, 180, 20, 180), at(0));
    window.ingest(stroke(43, 240, 28, 240), at(2));
    expect(window.live(at(2)).pace.value, 240);
    expect(window.live(at(2)).pace.strokes, 1);
  });

  test('counter resets and a pause start a new window', () {
    final window = RowingStrokeAverage();
    window.ingest(stroke(40, 180, 20, 180), at(0));
    window.ingest(stroke(41, 210, 24, 210), at(2));
    window.ingest({'machine_strokes': 0, 'cad': 18}, at(4));
    expect(window.live(at(4)).rate.value, 18);
    expect(window.live(at(4)).rate.strokes, 1);
    expect(window.live(at(4)).power.value, isNull);
    window.clear();
    expect(window.live(at(4)).rate.value, isNull);
    window.ingest(stroke(1, 240, 20, 100), at(6));
    expect(window.live(at(6)).power.strokes, 1);
  });

  test('readings expire and a resumed counter does not revive old strokes', () {
    final window = RowingStrokeAverage();
    window.ingest(stroke(40, 180, 20, 180), at(0));
    expect(window.live(at(6)).pace.value, isNull);
    expect(window.live(at(6)).rate.value, isNull);
    expect(window.live(at(6)).power.value, isNull);
    window.ingest(stroke(41, 240, 24, 240), at(7));
    expect(window.live(at(7)).power.value, 240);
    expect(window.live(at(7)).power.strokes, 1);
  });

  test(
    'without a counter real readings stay live and claim no stroke mean',
    () {
      final window = RowingStrokeAverage();
      window.ingest({'spd': 2.5, 'cad': 24, 'w': 180}, at(0));
      expect(window.live(at(0)).pace.value, 200);
      expect(window.live(at(0)).pace.strokes, 0);
      expect(window.live(at(0)).power.value, 180);
      expect(window.live(at(0)).power.strokes, 0);
    },
  );

  test('stopping does not keep an old nonzero stroke average alive', () {
    final window = RowingStrokeAverage();
    window.ingest(stroke(40, 180, 20, 180), at(0));
    window.ingest({'machine_strokes': 40, 'cad': 0, 'w': 0}, at(2));
    expect(window.live(at(2)).pace.value, isNull);
    expect(window.live(at(2)).rate.value, 0);
    expect(window.live(at(2)).power.value, 0);
    expect(window.live(at(2)).power.strokes, 0);
    window.ingest({'w': 0}, at(3));
    expect(window.live(at(3)).power.strokes, 0);
  });

  test('capture smoothing leaves recorded samples and checkpoint data raw', () {
    final capture = IndoorCapture(
      id: 'rower',
      startedAt: start,
      device: const TrainingDevice(id: 'rower', name: 'Rower'),
      machine: FtmsMachine.rower,
      name: 'Row',
    );
    for (var i = 0; i < 3; i++) {
      capture.ingest(
        stroke(40 + i, 180 + 30 * i, 20 + 4 * i, 180 + 30 * i),
        at(i * 2),
        recording: true,
      );
      capture.snapshot(at(i * 2), i * 2000);
    }
    expect(capture.rowing.live(at(4)).power.value, 210);
    expect(capture.samples.map((s) => s['w']), [180, 210, 240]);
    expect(capture.samples.map((s) => s['cad']), [20, 24, 28]);
    final restored = IndoorCapture.fromJson(capture.toJson());
    expect(restored.samples.map((s) => s['w']), [180, 210, 240]);
    expect(restored.rowing.live(at(4)).power.value, isNull);
    capture.clearContinuity();
    expect(capture.rowing.live(at(4)).power.value, isNull);
    capture.ingest(stroke(44, 300, 24, 100), at(5), recording: false);
    expect(capture.rowing.live(at(5)).power.value, isNull);
  });
}
