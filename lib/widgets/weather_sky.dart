import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/fjelia_style.dart';
import 'weather_glyph.dart';

/// The sky of a day: a gradient for its weather, a warm glow when the sun
/// shows, rain streaks as dense as the forecast amount, and wind lines on a
/// windy day.
class WeatherSkyPainter extends CustomPainter {
  WeatherSkyPainter(this.kind, {required this.rainMm, required this.windKmh});
  final WeatherKind kind;
  final double rainMm;
  final double windKmh;

  static const _skies = {
    WeatherKind.clear: [Color(0xFF1D5FB4), Color(0xFF4A9BE8)],
    WeatherKind.partly: [Color(0xFF2B5C8E), Color(0xFF6A8DB3)],
    WeatherKind.cloudy: [Color(0xFF36404D), Color(0xFF5E6978)],
    WeatherKind.fog: [Color(0xFF474E57), Color(0xFF7A828C)],
    WeatherKind.drizzle: [Color(0xFF283A4E), Color(0xFF465C75)],
    WeatherKind.rain: [Color(0xFF1C2B3D), Color(0xFF39506B)],
    WeatherKind.snow: [Color(0xFF51647C), Color(0xFF9BB0C8)],
    WeatherKind.thunder: [Color(0xFF211C36), Color(0xFF4A3B6B)],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _skies[kind]!,
        ).createShader(rect),
    );
    if (kind == WeatherKind.clear || kind == WeatherKind.partly) {
      final glow = Offset(size.width * .85, size.height * .2);
      canvas.drawCircle(
        glow,
        size.height,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.amber.withValues(
                alpha: kind == WeatherKind.clear ? .55 : .3,
              ),
              Colors.amber.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: glow, radius: size.height)),
      );
    }
    // Rain: a streak per fixed spot, more of them the more is forecast.
    final wet =
        kind == WeatherKind.rain ||
        kind == WeatherKind.drizzle ||
        kind == WeatherKind.thunder;
    if (wet || rainMm >= .2) {
      final streaks = (6 + rainMm * 4).clamp(6, 40).round();
      final paint = Paint()
        ..color = Colors.lightBlueAccent.withValues(alpha: .45)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      final random = math.Random(7);
      for (var i = 0; i < streaks; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final length = 6 + random.nextDouble() * 6;
        canvas.drawLine(Offset(x, y), Offset(x - 2.5, y + length), paint);
      }
    }
    if (kind == WeatherKind.snow) {
      final paint = Paint()..color = fjInk.withValues(alpha: .7);
      final random = math.Random(3);
      for (var i = 0; i < 18; i++) {
        canvas.drawCircle(
          Offset(
            random.nextDouble() * size.width,
            random.nextDouble() * size.height,
          ),
          1 + random.nextDouble() * 1.2,
          paint,
        );
      }
    }
    // Wind from 25 km/h: soft curved lines across the sky.
    if (windKmh >= 25) {
      final lines = windKmh >= 45 ? 3 : 2;
      final paint = Paint()
        ..color = fjInk.withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < lines; i++) {
        final y = size.height * (.45 + i * .16);
        final x = size.width * (.3 + i * .1);
        canvas.drawPath(
          Path()
            ..moveTo(x, y)
            ..quadraticBezierTo(
              x + size.width * .25,
              y - 6,
              x + size.width * .5,
              y,
            ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(WeatherSkyPainter old) =>
      old.kind != kind || old.rainMm != rainMm || old.windKmh != windKmh;
}
