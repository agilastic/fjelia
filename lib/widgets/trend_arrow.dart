import '../l10n/l10n_ext.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

class TrendArrow extends StatelessWidget {
  const TrendArrow({super.key, required this.delta, required this.color});
  final double? delta;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final direction = delta == null || delta!.abs() < .01
        ? 0
        : delta! > 0
        ? 1
        : -1;
    return Semantics(
      label: delta == null
          ? context.l10n.trendUnavailable
          : direction == 0
          ? context.l10n.stable
          : direction > 0
          ? context.l10n.increasing
          : context.l10n.decreasing,
      child: SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(painter: _TrendPainter(direction, color)),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.direction, this.color);
  final int direction;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    if (direction != 0) {
      canvas.rotate(direction > 0 ? -math.pi / 2 : math.pi / 2);
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(-5.5, 0)
        ..lineTo(5.5, 0)
        ..moveTo(1, -4.5)
        ..lineTo(5.5, 0)
        ..lineTo(1, 4.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      direction != old.direction || color != old.color;
}
