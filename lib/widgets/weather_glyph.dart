import '../theme/fjelia_style.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// What a weather symbol shows.
enum WeatherKind { clear, partly, cloudy, fog, drizzle, rain, snow, thunder }

/// The symbol for a WMO weather code; null without a code.
WeatherKind? weatherKindOf(int? code) => switch (code) {
  null => null,
  0 || 1 => WeatherKind.clear,
  2 => WeatherKind.partly,
  3 => WeatherKind.cloudy,
  45 || 48 => WeatherKind.fog,
  >= 51 && <= 57 => WeatherKind.drizzle,
  >= 61 && <= 67 || >= 80 && <= 82 => WeatherKind.rain,
  >= 71 && <= 77 || 85 || 86 => WeatherKind.snow,
  >= 95 => WeatherKind.thunder,
  _ => WeatherKind.cloudy,
};

/// The most telling weather of several hours: rain over cloud over sun.
WeatherKind? dominantWeather(Iterable<WeatherKind?> kinds, {int minWet = 2}) {
  const order = [
    WeatherKind.thunder,
    WeatherKind.snow,
    WeatherKind.rain,
    WeatherKind.drizzle,
    WeatherKind.fog,
    WeatherKind.cloudy,
    WeatherKind.partly,
    WeatherKind.clear,
  ];
  final present = kinds.whereType<WeatherKind>().toSet();
  // A single wet hour shouldn't paint a dry day as rainy: it takes
  // [minWet] of them.
  final counts = <WeatherKind, int>{};
  for (final k in kinds.whereType<WeatherKind>()) {
    counts[k] = (counts[k] ?? 0) + 1;
  }
  for (final kind in order) {
    if (!present.contains(kind)) continue;
    final wet = kind.index >= WeatherKind.drizzle.index;
    if (wet && counts[kind]! < minWet && kind != WeatherKind.thunder) {
      continue;
    }
    return kind;
  }
  return present.isEmpty ? null : WeatherKind.cloudy;
}

/// A small glossy weather symbol: shaded clouds, a rayed sun or a moon,
/// blue drops, flakes or a bolt. Painted, so it stays sharp at any size.
class WeatherGlyph extends StatelessWidget {
  const WeatherGlyph({
    super.key,
    required this.kind,
    this.night = false,
    this.size = 24,
  });

  final WeatherKind kind;
  final bool night;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _GlyphPainter(kind, night)),
  );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.kind, this.night);
  final WeatherKind kind;
  final bool night;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    switch (kind) {
      case WeatherKind.clear:
        night
            ? _moon(canvas, Offset(s * .5, s * .5), s * .34)
            : _sun(canvas, Offset(s * .5, s * .5), s * .22, s * .46);
      case WeatherKind.partly:
        if (night) {
          _moon(canvas, Offset(s * .36, s * .36), s * .24);
        } else {
          _sun(canvas, Offset(s * .36, s * .36), s * .15, s * .32);
        }
        _cloud(canvas, Rect.fromLTWH(s * .26, s * .4, s * .7, s * .42));
      case WeatherKind.cloudy:
        _cloud(canvas, Rect.fromLTWH(s * .06, s * .24, s * .88, s * .52));
      case WeatherKind.fog:
        _cloud(canvas, Rect.fromLTWH(s * .1, s * .12, s * .8, s * .46));
        final line = Paint()
          ..color = const Color(0xFFC9D2DC)
          ..strokeWidth = s * .07
          ..strokeCap = StrokeCap.round;
        for (final (y, inset) in [(.7, .16), (.84, .26)]) {
          canvas.drawLine(
            Offset(s * inset, s * y),
            Offset(s * (1 - inset), s * y),
            line,
          );
        }
      case WeatherKind.drizzle:
        _cloud(canvas, Rect.fromLTWH(s * .08, s * .08, s * .84, s * .5));
        _drop(canvas, Offset(s * .54, s * .66), s * .18);
        _drop(canvas, Offset(s * .38, s * .82), s * .12);
      case WeatherKind.rain:
        _cloud(
          canvas,
          Rect.fromLTWH(s * .06, s * .06, s * .88, s * .5),
          dark: true,
        );
        for (final (x, y) in [(.28, .66), (.52, .74), (.76, .66)]) {
          _drop(canvas, Offset(s * x, s * y), s * .2);
        }
      case WeatherKind.snow:
        _cloud(canvas, Rect.fromLTWH(s * .08, s * .06, s * .84, s * .5));
        for (final (x, y) in [(.3, .78), (.54, .86), (.74, .74)]) {
          _flake(canvas, Offset(s * x, s * y), s * .09);
        }
      case WeatherKind.thunder:
        _cloud(
          canvas,
          Rect.fromLTWH(s * .06, s * .04, s * .88, s * .52),
          dark: true,
        );
        _bolt(canvas, Offset(s * .5, s * .5), s);
    }
    canvas.restore();
  }

  /// A cloud of three puffs on a rounded base, lit from above.
  void _cloud(Canvas canvas, Rect r, {bool dark = false}) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            r.left,
            r.top + r.height * .45,
            r.width,
            r.height * .55,
          ),
          Radius.circular(r.height * .28),
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(r.left + r.width * .3, r.top + r.height * .55),
          radius: r.height * .3,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(r.left + r.width * .56, r.top + r.height * .4),
          radius: r.height * .4,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(r.left + r.width * .78, r.top + r.height * .62),
          radius: r.height * .26,
        ),
      );
    canvas
      ..drawShadow(path, Colors.black, r.height * .08, false)
      ..drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? [duo(0xFFE9EDF2, 0xFF1F2937), Color(0xFFA9B4C0)]
                : [fjInk, Color(0xFFD3DBE4)],
          ).createShader(r),
      );
  }

  void _sun(Canvas canvas, Offset c, double radius, double rays) {
    final rayPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFFE066), Color(0xFFFFA000)],
      ).createShader(Rect.fromCircle(center: c, radius: rays));
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final tip = c + Offset(math.cos(a), math.sin(a)) * rays;
      final side = radius * .42;
      final b1 =
          c +
          Offset(math.cos(a + .26), math.sin(a + .26)) * (radius + side * .2);
      final b2 =
          c +
          Offset(math.cos(a - .26), math.sin(a - .26)) * (radius + side * .2);
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(b1.dx, b1.dy)
          ..lineTo(b2.dx, b2.dy)
          ..close(),
        rayPaint,
      );
    }
    canvas
      ..drawCircle(
        c,
        radius * 1.25,
        Paint()
          ..color = const Color(0x55FFD54F)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * .4),
      )
      ..drawCircle(
        c,
        radius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.3, -.3),
            colors: const [Color(0xFFFFF9C4), Color(0xFFFFC107)],
          ).createShader(Rect.fromCircle(center: c, radius: radius)),
      );
  }

  void _moon(Canvas canvas, Offset c, double radius) {
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: radius)),
      Path()..addOval(
        Rect.fromCircle(
          center: c + Offset(radius * .55, -radius * .35),
          radius: radius * .9,
        ),
      ),
    );
    canvas.drawPath(
      moon,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [duo(0xFFF2F4F8, 0xFF1F2937), Color(0xFF9AA3B0)],
        ).createShader(Rect.fromCircle(center: c, radius: radius)),
    );
  }

  /// A drop with its point upwards, top at [top].
  void _drop(Canvas canvas, Offset top, double h) {
    final w = h * .62;
    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo(top.dx + w, top.dy + h * .65, top.dx, top.dy + h)
      ..quadraticBezierTo(top.dx - w, top.dy + h * .65, top.dx, top.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFB3E5FC), Color(0xFF1E88E5)],
        ).createShader(Rect.fromLTWH(top.dx - w, top.dy, w * 2, h)),
    );
  }

  void _flake(Canvas canvas, Offset c, double r) {
    final paint = Paint()
      ..color = fjInk
      ..strokeWidth = r * .32
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final a = i * math.pi / 3;
      final d = Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawLine(c - d, c + d, paint);
    }
  }

  void _bolt(Canvas canvas, Offset top, double s) {
    final path = Path()
      ..moveTo(top.dx + s * .04, top.dy)
      ..lineTo(top.dx - s * .12, top.dy + s * .24)
      ..lineTo(top.dx + s * .01, top.dy + s * .24)
      ..lineTo(top.dx - s * .06, top.dy + s * .46)
      ..lineTo(top.dx + s * .16, top.dy + s * .16)
      ..lineTo(top.dx + s * .03, top.dy + s * .16)
      ..lineTo(top.dx + s * .12, top.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [Color(0xFFFFF176), Color(0xFFFFA000)],
            ).createShader(
              Rect.fromLTWH(top.dx - s * .12, top.dy, s * .3, s * .46),
            ),
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.kind != kind || old.night != night;
}

/// Night between sunset and sunrise of that day; without them, 20:00–6:00.
bool isNightAt(
  DateTime time,
  Map<String, DateTime> sunrise,
  Map<String, DateTime> sunset,
) {
  final key =
      '${time.year}-${time.month.toString().padLeft(2, '0')}-'
      '${time.day.toString().padLeft(2, '0')}';
  final rise = sunrise[key], set = sunset[key];
  if (rise == null || set == null) return time.hour < 6 || time.hour >= 20;
  return time.isBefore(rise) || !time.isBefore(set);
}

/// A row of weather symbols over a chart whose plot leaves [inset] on both
/// sides: one per [stride] hours, or one per day in the [week] view.
class WeatherGlyphRow extends StatelessWidget {
  const WeatherGlyphRow({
    super.key,
    required this.points,
    required this.week,
    this.sunrise = const {},
    this.sunset = const {},
    this.inset = 32,
  });

  final List<({DateTime time, int? code})> points;
  final bool week;
  final Map<String, DateTime> sunrise, sunset;
  final double inset;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth - 2 * inset;
        final slot = width / points.length;
        final glyphs = <(double, WeatherKind, bool)>[];
        if (week) {
          // One per day: the weather that marks its daylight hours.
          final byDay = <String, List<int>>{};
          for (final (i, p) in points.indexed) {
            final key = '${p.time.year}-${p.time.month}-${p.time.day}';
            byDay.putIfAbsent(key, () => []).add(i);
          }
          for (final indices in byDay.values) {
            final daytime = [
              for (final i in indices)
                if (points[i].time.hour >= 8 && points[i].time.hour < 20) i,
            ];
            final kind = dominantWeather([
              for (final i in daytime.isEmpty ? indices : daytime)
                weatherKindOf(points[i].code),
            ]);
            if (kind == null) continue;
            final middle = (indices.first + indices.last) / 2;
            glyphs.add((inset + (middle + .5) * slot, kind, false));
          }
        } else {
          final stride = points.length > 12 ? 2 : 1;
          for (var i = 0; i < points.length; i += stride) {
            final kind = dominantWeather([
              for (var k = i; k < i + stride && k < points.length; k++)
                weatherKindOf(points[k].code),
            ], minWet: 1);
            if (kind == null) continue;
            final centre = i + (stride - 1) / 2;
            glyphs.add((
              inset + (centre + .5) * slot,
              kind,
              isNightAt(points[i].time, sunrise, sunset),
            ));
          }
        }
        final size =
            (week ? width / 7 : slot * (points.length > 12 ? 2 : 1)).clamp(
              14.0,
              26.0,
            ) *
            .92;
        return SizedBox(
          height: size + 4,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final (x, kind, night) in glyphs)
                Positioned(
                  left: x - size / 2,
                  top: 2,
                  child: WeatherGlyph(kind: kind, night: night, size: size),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The moon as it looks: the lit part on the right while it waxes, on the
/// left while it wanes, with the dark rest faintly visible.
class MoonGlyph extends StatelessWidget {
  const MoonGlyph({
    super.key,
    required this.illumination,
    required this.waxing,
    this.size = 24,
  });

  /// 0 (new) to 1 (full).
  final double illumination;
  final bool waxing;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _MoonPainter(illumination, waxing)),
  );
}

class _MoonPainter extends CustomPainter {
  _MoonPainter(this.illumination, this.waxing);
  final double illumination;
  final bool waxing;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * .9;
    final disc = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF2E3440));
    // Half the disc on the lit side, then the terminator as an ellipse:
    // cut away below half lit, added above.
    final half = Path()
      ..addArc(disc, waxing ? -math.pi / 2 : math.pi / 2, math.pi)
      ..close();
    final width = r * (1 - 2 * illumination).abs();
    final terminator = Path()
      ..addOval(Rect.fromCenter(center: c, width: width * 2, height: r * 2));
    final lit = Path.combine(
      illumination < .5 ? PathOperation.difference : PathOperation.union,
      half,
      terminator,
    );
    canvas
      ..save()
      ..clipPath(Path()..addOval(disc))
      ..drawPath(
        lit,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.3, -.3),
            colors: [Color(0xFFFFFDF2), Color(0xFFD9D4C2)],
          ).createShader(disc),
      )
      ..restore()
      ..drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .06
          ..color = const Color(0x55FFFFFF),
      );
  }

  @override
  bool shouldRepaint(_MoonPainter old) =>
      old.illumination != illumination || old.waxing != waxing;
}
