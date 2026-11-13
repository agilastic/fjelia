import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/ecg_respiration_review.dart';
import '../theme/fjelia_style.dart';

class EcgRespirationChart extends StatelessWidget {
  const EcgRespirationChart({super.key, required this.review});
  final EcgRespirationReview review;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 190,
    width: double.infinity,
    child: CustomPaint(painter: _Painter(review)),
  );
}

class _Painter extends CustomPainter {
  _Painter(this.review);
  final EcgRespirationReview review;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 35.0, right = 8.0, top = 8.0, bottom = 24.0;
    final chartWidth = math.max(1.0, size.width - left - right).toDouble();
    final chartHeight = size.height - top - bottom;
    final duration = math.max(1.0, review.durationSeconds).toDouble();
    final rowHeight = chartHeight / 2;
    final grid = Paint()
      ..color = fjMuted.withValues(alpha: .2)
      ..strokeWidth = 1;
    final ecgPaint = Paint()
      ..color = const Color(0xFF35C6FF)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final motionPaint = Paint()
      ..color = fjAccent(const Color(0xFF00D4A0))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i <= 4; i++) {
      final x = left + chartWidth * i / 4;
      canvas.drawLine(Offset(x, top), Offset(x, top + chartHeight), grid);
      final minutes = (duration * i / 4 / 60).round();
      _label(canvas, '$minutes m', Offset(x, size.height - 17), 10);
    }
    canvas.drawLine(
      Offset(left, top + rowHeight),
      Offset(size.width - right, top + rowHeight),
      grid,
    );
    _label(canvas, 'ECG', Offset(0, top + rowHeight / 2), 9);
    _label(canvas, 'ACC', Offset(0, top + rowHeight + rowHeight / 2), 9);
    final ecgPath = Path();
    var started = false;
    double? previousEcgSeconds;
    for (final point in review.ecgAmplitude) {
      final x = left + point.seconds / duration * chartWidth;
      final y =
          top +
          rowHeight -
          point.value.clamp(0, 2).toDouble() / 2 * (rowHeight - 8);
      if (!started ||
          previousEcgSeconds != null &&
              point.seconds - previousEcgSeconds > 2.5) {
        ecgPath.moveTo(x, y);
        started = true;
      } else {
        ecgPath.lineTo(x, y);
      }
      previousEcgSeconds = point.seconds;
    }
    canvas.drawPath(ecgPath, ecgPaint);
    final motionPath = Path();
    started = false;
    double? previousMotionSeconds;
    for (final point in review.movement) {
      final x = left + point.seconds / duration * chartWidth;
      final y =
          top +
          rowHeight +
          rowHeight -
          point.value.clamp(0, 1.5).toDouble() / 1.5 * (rowHeight - 8);
      if (!started ||
          previousMotionSeconds != null &&
              point.seconds - previousMotionSeconds > 60) {
        motionPath.moveTo(x, y);
        started = true;
      } else {
        motionPath.lineTo(x, y);
      }
      previousMotionSeconds = point.seconds;
    }
    canvas.drawPath(motionPath, motionPaint);
  }

  void _label(Canvas canvas, String text, Offset at, double size) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: fjMuted, fontSize: size),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at - Offset(painter.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant _Painter oldDelegate) =>
      oldDelegate.review != review;
}
