import '../theme/fjelia_style.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/day_data_provider.dart';
import '../providers/heat_acclimation_provider.dart';
import '../providers/style_provider.dart';
import '../services/open_meteo_client.dart';
import 'weather_glyph.dart';

/// The sky over the athlete right now: the hour's weather and whether the
/// sun is down.
typedef HomeSkyState = ({WeatherKind kind, bool night, double rainMm});

/// The sky for [now] from the hourly forecast: the hour that holds [now]
/// (or the nearest within an hour), and night outside today's sunrise and
/// sunset. Null without a usable hour: no sky is painted from guesses.
HomeSkyState? homeSkyAt(OpenMeteoResult? weather, DateTime now) {
  if (weather == null) return null;
  OpenMeteoPoint? best;
  var gap = const Duration(minutes: 61);
  for (final p in weather.points) {
    final d = p.time.difference(now).abs();
    if (d < gap && p.weatherCode != null) {
      gap = d;
      best = p;
    }
  }
  final kind = weatherKindOf(best?.weatherCode);
  if (best == null || kind == null) return null;
  final key =
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
  final rise = weather.sunrise[key], set = weather.sunset[key];
  final night =
      rise != null && set != null && (now.isBefore(rise) || !now.isBefore(set));
  return (kind: kind, night: night, rainMm: best.precipitationMm);
}

/// A soft sky behind the top of Home that follows today's weather and the
/// time of day. It fades into the page, comes in once and never moves on
/// its own; it shows only for today and only with real weather data.
class HomeSkyBand extends ConsumerWidget {
  const HomeSkyBand({super.key, this.now});

  /// For tests; the clock otherwise.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(ref.watch(homeSkyProvider).valueOrNull ?? true)) {
      return const SizedBox.shrink();
    }
    final at = now ?? DateTime.now();
    final selected = ref.watch(selectedDateProvider);
    if (!DateUtils.isSameDay(selected, at)) return const SizedBox.shrink();
    final sky = homeSkyAt(ref.watch(heatHourlyWeatherProvider).valueOrNull, at);
    if (sky == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(sky),
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          key: const ValueKey('home-sky'),
          painter: HomeSkyPainter(sky, light: Fjelia.light, strength: t),
        ),
      ),
    );
  }
}

class HomeSkyPainter extends CustomPainter {
  HomeSkyPainter(this.sky, {required this.light, this.strength = 1});
  final HomeSkyState sky;
  final bool light;

  /// 0 to 1 while the sky fades in; colour alpha only, never `Opacity`.
  final double strength;

  static const _day = {
    WeatherKind.clear: Color(0xFF2F7DD6),
    WeatherKind.partly: Color(0xFF4A7DB0),
    WeatherKind.cloudy: Color(0xFF5E6978),
    WeatherKind.fog: Color(0xFF7A828C),
    WeatherKind.drizzle: Color(0xFF465C75),
    WeatherKind.rain: Color(0xFF39506B),
    WeatherKind.snow: Color(0xFF8FA6C2),
    WeatherKind.thunder: Color(0xFF4A3B6B),
  };
  static const _night = Color(0xFF16244A);
  static const _sun = Color(0xFFFFF1CF);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = sky.night
        ? Color.lerp(_night, _day[sky.kind]!, .25)!
        : _day[sky.kind]!;
    // Calm: a tint that is strongest at the very top and gone by the
    // bottom, so the cards below sit on the plain page.
    final top = (light ? .30 : .50) * strength;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            base.withValues(alpha: top),
            base.withValues(alpha: top * .45),
            base.withValues(alpha: 0),
          ],
          stops: const [0, .5, 1],
        ).createShader(rect),
    );
    final clearish =
        sky.kind == WeatherKind.clear || sky.kind == WeatherKind.partly;
    if (clearish && !sky.night) {
      final sun = Offset(size.width * .86, size.height * .08);
      final r = size.width * .55;
      canvas.drawCircle(
        sun,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              // Pale warm light: amber over the blue turned olive.
              _sun.withValues(
                alpha:
                    (sky.kind == WeatherKind.clear ? .26 : .14) *
                    strength *
                    (light ? 1.4 : 1),
              ),
              _sun.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: sun, radius: r)),
      );
    }
    if (clearish && sky.night && !light) {
      // A few fixed stars in the upper part of a clear night.
      final random = math.Random(11);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: .45 * strength);
      for (var i = 0; i < 14; i++) {
        canvas.drawCircle(
          Offset(
            random.nextDouble() * size.width,
            random.nextDouble() * size.height * .45,
          ),
          .6 + random.nextDouble() * .8,
          paint,
        );
      }
    }
    final wet =
        sky.kind == WeatherKind.rain ||
        sky.kind == WeatherKind.drizzle ||
        sky.kind == WeatherKind.thunder;
    if (wet || sky.rainMm >= .2) {
      final streaks = (10 + sky.rainMm * 6).clamp(10, 36).round();
      final paint = Paint()
        ..color = fjAccent(Colors.lightBlueAccent)
            .withValues(alpha: (light ? .30 : .22) * strength)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      final random = math.Random(7);
      for (var i = 0; i < streaks; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height * .55;
        final length = 7 + random.nextDouble() * 7;
        canvas.drawLine(Offset(x, y), Offset(x - 3, y + length), paint);
      }
    }
    if (sky.kind == WeatherKind.snow) {
      final paint = Paint()
        ..color = (light ? const Color(0xFF8FA6C2) : Colors.white).withValues(
          alpha: .45 * strength,
        );
      final random = math.Random(3);
      for (var i = 0; i < 22; i++) {
        canvas.drawCircle(
          Offset(
            random.nextDouble() * size.width,
            random.nextDouble() * size.height * .55,
          ),
          1 + random.nextDouble() * 1.3,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(HomeSkyPainter old) =>
      old.sky != sky || old.light != light || old.strength != strength;
}
