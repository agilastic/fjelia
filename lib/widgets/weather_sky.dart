import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'weather_glyph.dart';

typedef _CloudColors = ({Color body, Color shade, Color lit});

/// A painted sky for a weather kind: the sky by day or night, sun or moon
/// with stars, clouds lit from the sun's side, rain as dense as forecast,
/// snow, fog bands, lightning and wind. Nothing moves; every random detail
/// comes from a fixed seed, so a sky looks the same on every paint.
///
/// With [fadeTo] the lower part fades into that colour, so cards below sit
/// on the plain page (`style.md`: no full-screen gradients). [showSunAndMoon]
/// is off where a [WeatherGlyph] already shows them. [lightLook] paints the
/// brighter iOS-like sky of LightFjelia, light enough for dark text on it.
class WeatherSkyPainter extends CustomPainter {
  WeatherSkyPainter(
    this.kind, {
    required this.rainMm,
    required this.windKmh,
    this.night = false,
    this.fadeTo,
    this.showSunAndMoon = true,
    this.strength = 1,
    this.lightLook = false,
  });
  final WeatherKind kind;
  final double rainMm;
  final double windKmh;
  final bool night;
  final Color? fadeTo;
  final bool showSunAndMoon;

  /// 0 to 1 while the sky fades in.
  final double strength;

  final bool lightLook;

  /// The share of the height that is sky before the fade starts.
  static const _skyShare = .62;

  static const _day = {
    WeatherKind.clear: [
      Color(0xFF1656B8),
      Color(0xFF3F8FE0),
      Color(0xFF9CCBF2),
    ],
    WeatherKind.partly: [
      Color(0xFF235FAE),
      Color(0xFF5590CF),
      Color(0xFFA5C6E6),
    ],
    WeatherKind.cloudy: [
      Color(0xFF465260),
      Color(0xFF6D7987),
      Color(0xFF9AA4AF),
    ],
    WeatherKind.fog: [Color(0xFF6E7781), Color(0xFF959DA6), Color(0xFFBCC2C8)],
    WeatherKind.drizzle: [
      Color(0xFF34465B),
      Color(0xFF55687E),
      Color(0xFF7D8DA0),
    ],
    WeatherKind.rain: [Color(0xFF1F2C3C), Color(0xFF384A5F), Color(0xFF5A6C80)],
    WeatherKind.snow: [Color(0xFF6F84A0), Color(0xFF9DB0C6), Color(0xFFD0DAE5)],
    WeatherKind.thunder: [
      Color(0xFF15131F),
      Color(0xFF2B2840),
      Color(0xFF4A4663),
    ],
  };
  static const _nightSky = [
    Color(0xFF040918),
    Color(0xFF0B1735),
    Color(0xFF1B2D55),
  ];

  // LightFjelia: saturated at the top like the iOS sky, light in the middle
  // where text sits on it.
  static const _dayLight = {
    WeatherKind.clear: [
      Color(0xFF1C74DB),
      Color(0xFF63AEF2),
      Color(0xFFC2E1FB),
    ],
    WeatherKind.partly: [
      Color(0xFF2F7DD3),
      Color(0xFF7AB6EE),
      Color(0xFFC9E1F6),
    ],
    WeatherKind.cloudy: [
      Color(0xFF7F8D9E),
      Color(0xFFB5C0CC),
      Color(0xFFDFE5EB),
    ],
    WeatherKind.fog: [Color(0xFF9CA6B1), Color(0xFFC9D0D7), Color(0xFFE6E9ED)],
    WeatherKind.drizzle: [
      Color(0xFF6A7E96),
      Color(0xFFA6B5C6),
      Color(0xFFD7DFE8),
    ],
    WeatherKind.rain: [Color(0xFF51647C), Color(0xFF94A5B9), Color(0xFFCCD5E0)],
    WeatherKind.snow: [Color(0xFF8DA3BE), Color(0xFFC6D4E4), Color(0xFFEDF2F7)],
    WeatherKind.thunder: [
      Color(0xFF47436A),
      Color(0xFF8E8AAE),
      Color(0xFFC9C6DC),
    ],
  };
  static const _nightLight = [
    Color(0xFF14285A),
    Color(0xFF4C6AA3),
    Color(0xFFB3C3DF),
  ];

  static const Map<WeatherKind, _CloudColors> _clouds = {
    WeatherKind.partly: (
      body: Color(0xFFF3F6FA),
      shade: Color(0xFFAFBDCF),
      lit: Color(0xFFFFFFFF),
    ),
    WeatherKind.cloudy: (
      body: Color(0xFFA7B0BB),
      shade: Color(0xFF66717E),
      lit: Color(0xFFD6DBE1),
    ),
    WeatherKind.fog: (
      body: Color(0xFFC2C8CE),
      shade: Color(0xFF959DA6),
      lit: Color(0xFFE2E6EA),
    ),
    WeatherKind.drizzle: (
      body: Color(0xFF8592A1),
      shade: Color(0xFF4C5866),
      lit: Color(0xFFB0BAC5),
    ),
    WeatherKind.rain: (
      body: Color(0xFF5C6878),
      shade: Color(0xFF2B3542),
      lit: Color(0xFF8994A2),
    ),
    WeatherKind.snow: (
      body: Color(0xFFCDD5DF),
      shade: Color(0xFF8C99AB),
      lit: Color(0xFFF0F3F7),
    ),
    WeatherKind.thunder: (
      body: Color(0xFF45425A),
      shade: Color(0xFF1A1825),
      lit: Color(0xFF6F6B90),
    ),
  };

  static const Map<WeatherKind, _CloudColors> _cloudsLight = {
    WeatherKind.partly: (
      body: Color(0xFFF7F9FC),
      shade: Color(0xFFB4C3D6),
      lit: Color(0xFFFFFFFF),
    ),
    WeatherKind.cloudy: (
      body: Color(0xFFE4E9EE),
      shade: Color(0xFF9AA6B4),
      lit: Color(0xFFFFFFFF),
    ),
    WeatherKind.fog: (
      body: Color(0xFFE8EBEE),
      shade: Color(0xFFB7BFC8),
      lit: Color(0xFFFFFFFF),
    ),
    WeatherKind.drizzle: (
      body: Color(0xFFCDD5DF),
      shade: Color(0xFF8595A8),
      lit: Color(0xFFF2F5F8),
    ),
    WeatherKind.rain: (
      body: Color(0xFFADB9C7),
      shade: Color(0xFF6A7A8E),
      lit: Color(0xFFE2E7ED),
    ),
    WeatherKind.snow: (
      body: Color(0xFFF2F5F9),
      shade: Color(0xFFB3C0D0),
      lit: Color(0xFFFFFFFF),
    ),
    WeatherKind.thunder: (
      body: Color(0xFF8F8BAB),
      shade: Color(0xFF4E4A6C),
      lit: Color(0xFFC6C3DB),
    ),
  };

  bool get _wet =>
      kind == WeatherKind.rain ||
      kind == WeatherKind.drizzle ||
      kind == WeatherKind.thunder;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final skyH = fadeTo == null ? h : h * _skyShare;
    // The fade-in multiplies the whole sky at once, not each layer.
    final fading = strength < 1;
    if (fading) {
      canvas.saveLayer(
        rect,
        Paint()..color = Colors.white.withValues(alpha: strength),
      );
    }
    final day = (lightLook ? _dayLight : _day)[kind]!;
    final colors = night
        ? [
            for (var i = 0; i < 3; i++)
              Color.lerp(
                (lightLook ? _nightLight : _nightSky)[i],
                day[i],
                kind == WeatherKind.clear ? .05 : .22,
              )!,
          ]
        : day;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: const [0, .55, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, skyH * 1.15)),
    );
    final scale = math.min(w, skyH) / 240;
    final clearish = kind == WeatherKind.clear || kind == WeatherKind.partly;
    final light = Offset(w * .76, skyH * .22);

    if (night && (clearish || kind == WeatherKind.snow)) {
      _stars(canvas, w, skyH, clearish ? 1 : .25);
    }
    if (clearish && showSunAndMoon) {
      night
          ? _moon(canvas, light, 13 * scale)
          : _sun(canvas, light, 15 * scale, kind == WeatherKind.clear ? 1 : .8);
    }
    if (kind == WeatherKind.fog) _fog(canvas, w, skyH, scale);
    if (kind != WeatherKind.clear) _cloudCover(canvas, w, skyH, light);
    if (kind == WeatherKind.thunder) _lightning(canvas, w, skyH, scale);
    if (_wet || rainMm >= .2) _rain(canvas, w, h, skyH, scale);
    if (kind == WeatherKind.snow) _snow(canvas, w, h, scale);
    if (windKmh >= 25) _wind(canvas, w, skyH, scale);

    final fade = fadeTo;
    if (fade != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              // A long, eased fade: the sky thins out instead of ending.
              fade.withValues(alpha: 0),
              fade.withValues(alpha: .3),
              fade.withValues(alpha: .7),
              fade.withValues(alpha: .92),
              fade,
            ],
            stops: const [.18, .42, .66, .85, 1],
          ).createShader(rect),
      );
    }
    if (fading) canvas.restore();
  }

  void _sun(Canvas canvas, Offset at, double r, double amount) {
    final halo = Rect.fromCircle(center: at, radius: r * 9);
    canvas.drawCircle(
      at,
      r * 9,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF4D6).withValues(alpha: .55 * amount),
            const Color(0xFFFFD98A).withValues(alpha: .18 * amount),
            const Color(0xFFFFD98A).withValues(alpha: 0),
          ],
          stops: const [0, .35, 1],
        ).createShader(halo),
    );
    canvas.drawCircle(
      at,
      r * 2.2,
      Paint()
        ..color = const Color(0xFFFFFBEA).withValues(alpha: .5 * amount)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .9),
    );
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..color = const Color(0xFFFFFDF2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .15),
    );
  }

  void _moon(Canvas canvas, Offset at, double r) {
    final halo = Rect.fromCircle(center: at, radius: r * 6);
    canvas.drawCircle(
      at,
      r * 6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFCFDCFF).withValues(alpha: .22),
            const Color(0xFFCFDCFF).withValues(alpha: 0),
          ],
        ).createShader(halo),
    );
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: at, radius: r)),
      Path()..addOval(
        Rect.fromCircle(center: at + Offset(r * .55, -r * .3), radius: r * .92),
      ),
    );
    canvas.drawPath(
      crescent,
      Paint()
        ..color = const Color(0xFFF4F1E4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .06),
    );
  }

  void _stars(Canvas canvas, double w, double skyH, double amount) {
    final random = math.Random(11);
    final count = (w * skyH / 900 * amount).round();
    for (var i = 0; i < count; i++) {
      final p = Offset(
        random.nextDouble() * w,
        math.pow(random.nextDouble(), 1.4) * skyH * .95,
      );
      final r = .35 + math.pow(random.nextDouble(), 3) * 1.4;
      // Fainter towards the horizon.
      final alpha = (.35 + random.nextDouble() * .6) * (1 - p.dy / skyH * .7);
      if (r > 1.1) {
        canvas.drawCircle(
          p,
          r * 3,
          Paint()
            ..color = Colors.white.withValues(alpha: alpha * .25)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.5),
        );
      }
      canvas.drawCircle(
        p,
        r,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  _CloudColors get _cloudColors {
    final c = (lightLook ? _cloudsLight : _clouds)[kind]!;
    if (!night) return c;
    final dark = lightLook ? const Color(0xFF3A4F7A) : const Color(0xFF0A1224);
    return (
      body: Color.lerp(c.body, dark, lightLook ? .45 : .68)!,
      shade: Color.lerp(c.shade, dark, lightLook ? .6 : .8)!,
      lit: Color.lerp(
        c.lit,
        const Color(0xFF8FA3C8),
        .55,
      )!.withValues(alpha: .9),
    );
  }

  void _cloudCover(Canvas canvas, double w, double skyH, Offset light) {
    final colors = _cloudColors;
    final random = math.Random(kind.index * 31 + 5);
    if (kind == WeatherKind.partly) {
      _cloud(
        canvas,
        Offset(w * .22, skyH * .42),
        w * .42,
        colors,
        light,
        .75,
        random,
      );
      _cloud(
        canvas,
        Offset(w * .66, skyH * .36),
        w * .5,
        colors,
        light,
        .97,
        random,
      );
      return;
    }
    if (kind == WeatherKind.fog) {
      _cloud(
        canvas,
        Offset(w * .3, skyH * .2),
        w * .7,
        colors,
        light,
        .45,
        random,
        soft: 4,
      );
      _cloud(
        canvas,
        Offset(w * .8, skyH * .3),
        w * .6,
        colors,
        light,
        .4,
        random,
        soft: 4,
      );
      return;
    }
    // A deck: the far rows small and faint, the near rows large and solid.
    final heavy = kind == WeatherKind.rain || kind == WeatherKind.thunder;
    final rows = heavy ? 3 : 2;
    for (var row = 0; row < rows; row++) {
      final depth = row / math.max(rows - 1, 1);
      final count = 3 + (1 - depth).round();
      for (var i = 0; i < count; i++) {
        final x = (i + .5 + (random.nextDouble() - .5) * .5) / count * w;
        final y =
            skyH *
            (.08 + depth * (heavy ? .32 : .28) + random.nextDouble() * .05);
        final width = w * (.42 + depth * .28 + random.nextDouble() * .1);
        _cloud(
          canvas,
          Offset(x, y),
          width,
          colors,
          light,
          .6 + depth * .4,
          random,
          soft: lightLook ? 1.4 : 2.2,
        );
      }
    }
  }

  /// One cloud: a silhouette of puffs, then light from the top and the sun's
  /// side and shade at its base painted onto it as a whole.
  void _cloud(
    Canvas canvas,
    Offset center,
    double width,
    _CloudColors colors,
    Offset light,
    double alpha,
    math.Random random, {
    double soft = 1,
  }) {
    final height = width * .36;
    final bounds = Rect.fromCenter(
      center: center,
      width: width * 1.7,
      height: height * 3.4,
    );
    canvas.saveLayer(
      bounds,
      Paint()..color = Colors.white.withValues(alpha: alpha),
    );
    final toLight = light - center;
    final dir = toLight / math.max(toLight.distance, 1);
    final puffs = <(Offset, double)>[];
    // Back to front: the crown, the upper row, then the base row.
    final crown = 1 + random.nextInt(2);
    for (var i = 0; i < crown; i++) {
      puffs.add((
        Offset(
          center.dx + (random.nextDouble() - .5) * width * .35,
          center.dy - height * .42,
        ),
        height * (.38 + random.nextDouble() * .16),
      ));
    }
    final upper = 3 + random.nextInt(2);
    for (var i = 0; i < upper; i++) {
      final t = (i + .5) / upper;
      puffs.add((
        Offset(
          center.dx - width * .36 + t * width * .72,
          center.dy - height * .12 + (random.nextDouble() - .5) * height * .1,
        ),
        height * (.32 + random.nextDouble() * .16),
      ));
    }
    final base = 5 + random.nextInt(3);
    for (var i = 0; i < base; i++) {
      final t = i / (base - 1);
      final r =
          height *
          (.24 + math.sin(t * math.pi) * .1 + random.nextDouble() * .08);
      puffs.add((
        Offset(
          center.dx - width * .5 + t * width,
          center.dy + height * .2 - r * .2,
        ),
        r,
      ));
    }
    final solid = Paint()
      ..color = colors.body
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, height * .05 * soft);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          center.dx - width * .5,
          center.dy + height * .02,
          center.dx + width * .5,
          center.dy + height * .34,
        ),
        Radius.circular(height * .16),
      ),
      solid,
    );
    for (final (p, r) in puffs) {
      canvas.drawCircle(p, r, solid);
    }
    canvas.drawRect(
      bounds,
      Paint()
        ..blendMode = BlendMode.srcATop
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.lit, colors.body, colors.shade],
              stops: const [.1, .55, 1],
            ).createShader(
              Rect.fromLTRB(
                bounds.left,
                center.dy - height,
                bounds.right,
                center.dy + height * .36,
              ),
            ),
    );
    // Light on the sunny side of the upper puffs, a little shade between
    // the lower ones.
    for (final (p, r) in puffs.take(crown + upper)) {
      canvas.drawCircle(
        p + dir * r * .35 + Offset(0, -r * .25),
        r * .55,
        Paint()
          ..blendMode = BlendMode.srcATop
          ..color = colors.lit.withValues(alpha: colors.lit.a * .55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .45),
      );
    }
    for (final (p, r) in puffs.skip(crown + upper)) {
      canvas.drawCircle(
        p + Offset(-dir.dx * r * .3, r * .45),
        r * .6,
        Paint()
          ..blendMode = BlendMode.srcATop
          ..color = colors.shade.withValues(alpha: .35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .5),
      );
    }
    canvas.restore();
  }

  void _fog(Canvas canvas, double w, double skyH, double scale) {
    final random = math.Random(4);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: night ? .07 : .2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * scale);
    for (var i = 0; i < 6; i++) {
      final y = skyH * (.15 + i * .15) + random.nextDouble() * 8 * scale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            -w * .2 + random.nextDouble() * w * .2,
            y,
            w * 1.2,
            skyH * .07,
          ),
          const Radius.circular(40),
        ),
        paint,
      );
    }
  }

  void _lightning(Canvas canvas, double w, double skyH, double scale) {
    final start = Offset(w * .42, skyH * .5);
    final flash = Rect.fromCircle(center: start, radius: w * .45);
    canvas.drawCircle(
      start,
      w * .45,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFD9D4FF).withValues(alpha: .3),
            const Color(0xFFD9D4FF).withValues(alpha: 0),
          ],
        ).createShader(flash),
    );
    final random = math.Random(9);
    Path bolt(Offset from, int steps, double step) {
      final path = Path()..moveTo(from.dx, from.dy);
      var at = from;
      for (var i = 0; i < steps; i++) {
        at += Offset(
          (random.nextDouble() - .45) * step * .9,
          step * (.7 + random.nextDouble() * .5),
        );
        path.lineTo(at.dx, at.dy);
      }
      return path;
    }

    final step = skyH * .055;
    final main = bolt(start, 9, step);
    final branch = bolt(start + Offset(step * .8, step * 3.2), 4, step * .8);
    for (final (path, width) in [(main, 1.0), (branch, .6)]) {
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFB9B0FF).withValues(alpha: .7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7 * width * scale
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * scale),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 2.4 * width * scale,
      );
    }
  }

  /// Rain in two depths, denser the more is forecast and slanting with the
  /// wind; drizzle in short strokes.
  void _rain(Canvas canvas, double w, double h, double skyH, double scale) {
    final random = math.Random(7);
    final mm = math.max(rainMm, kind == WeatherKind.drizzle ? .5 : 1.5);
    final density = (w * h / 1400) * (.4 + math.min(mm, 8) * .25);
    final slant = -.18 - math.min(windKmh, 60) / 120;
    final size = scale.clamp(.6, 1.3);
    for (final (far, alpha, width, length) in [
      (true, .22, .8, 9.0),
      (false, .42, 1.3, 16.0),
    ]) {
      final paint = Paint()
        ..color =
            (lightLook ? const Color(0xFF3D5574) : const Color(0xFFD5E6F7))
                .withValues(alpha: lightLook ? alpha * .9 : alpha)
        ..strokeWidth = width * scale.clamp(.7, 1.4)
        ..strokeCap = StrokeCap.round;
      final count = (density * (far ? .6 : .4)).round();
      for (var i = 0; i < count; i++) {
        final x = random.nextDouble() * w * 1.1;
        final y = skyH * .3 + random.nextDouble() * (h - skyH * .3);
        final l =
            length *
            size *
            (.7 + random.nextDouble() * .6) *
            (kind == WeatherKind.drizzle ? .55 : 1);
        canvas.drawLine(Offset(x, y), Offset(x + slant * l, y + l), paint);
      }
    }
  }

  void _snow(Canvas canvas, double w, double h, double scale) {
    final random = math.Random(3);
    final count = (w * h / 700).round();
    for (var i = 0; i < count; i++) {
      final near = random.nextDouble() < .3;
      final p = Offset(
        random.nextDouble() * w,
        h * .2 + random.nextDouble() * h * .8,
      );
      final r =
          (near
              ? 1.8 + random.nextDouble() * 1.6
              : .7 + random.nextDouble() * .9) *
          scale.clamp(.7, 1.3);
      // A soft shadow keeps white flakes visible on a light sky.
      if (lightLook) {
        canvas.drawCircle(
          p + Offset(0, r * .3),
          r * 1.2,
          Paint()
            ..color = const Color(0xFF4A5A70).withValues(alpha: .28)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .6),
        );
      }
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: near ? .9 : .6)
          ..maskFilter = near
              ? MaskFilter.blur(BlurStyle.normal, r * .35)
              : null,
      );
    }
  }

  /// Wind from 25 km/h: a few soft gusts that fade in and out.
  void _wind(Canvas canvas, double w, double skyH, double scale) {
    final random = math.Random(5);
    for (var i = 0; i < 5; i++) {
      final y = skyH * (.3 + random.nextDouble() * .5);
      final x = w * random.nextDouble() * .5;
      final length = w * (.25 + random.nextDouble() * .3);
      canvas.drawPath(
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + length * .5, y - 5 * scale, x + length, y),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: .35),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(x, y - 2, length, 4))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * scale.clamp(.7, 1.3)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(WeatherSkyPainter old) =>
      old.kind != kind ||
      old.rainMm != rainMm ||
      old.windKmh != windKmh ||
      old.night != night ||
      old.fadeTo != fadeTo ||
      old.showSunAndMoon != showSunAndMoon ||
      old.strength != strength ||
      old.lightLook != lightLook;
}
