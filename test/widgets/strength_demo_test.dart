import 'dart:io';
import 'dart:ui' as ui;

import 'package:fjelia/models/strength_workout.dart';
import 'package:fjelia/widgets/strength_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paints the demonstrations. With FJELIA_UI_PREVIEW_DIR set, also writes
/// contact sheets (each exercise at its key poses and in between) for
/// review.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every built-in exercise has a demonstration', () {
    expect(
      builtInStrengthVariants.map((v) => v.id).toSet(),
      StrengthExerciseDemo.ids.toSet(),
    );
    for (final id in StrengthExerciseDemo.ids) {
      expect(StrengthExerciseDemo.cueOf(id), isNotEmpty, reason: id);
    }
  });

  test('every pose paints, through the whole loop', () async {
    final dir = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
    final ids = StrengthExerciseDemo.ids.toList();
    const cell = Size(230, 190), columns = 4, rows = 6;
    for (var page = 0; page * rows < ids.length; page++) {
      final chunk = ids.skip(page * rows).take(rows).toList();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, cell.width * columns, cell.height * chunk.length),
        Paint()..color = const Color(0xFF202020),
      );
      for (var r = 0; r < chunk.length; r++) {
        final id = chunk[r];
        final keys = strengthDemoKeyTimes(id);
        final times = [
          keys[0],
          (keys[0] + keys[1]) / 2 + .4,
          keys[1],
          keys.length > 2 ? keys[2] : keys[1] + 1.2,
        ];
        for (var c = 0; c < columns; c++) {
          canvas.save();
          canvas.translate(c * cell.width, r * cell.height);
          paintStrengthDemo(canvas, cell, id, times[c]);
          if (c == 0) {
            TextPainter(
                text: TextSpan(
                  text: id,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                textDirection: TextDirection.ltr,
              )
              ..layout()
              ..paint(canvas, const Offset(4, 2));
          }
          canvas.restore();
        }
      }
      final image = await recorder.endRecording().toImage(
        (cell.width * columns).round(),
        (cell.height * chunk.length).round(),
      );
      if (dir != null) {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$dir/strength-demos-$page.png')
            .writeAsBytes(png!.buffer.asUint8List());
      }
    }
  });
}
