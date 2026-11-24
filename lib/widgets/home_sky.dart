import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/day_data_provider.dart';
import '../providers/heat_acclimation_provider.dart';
import '../providers/style_provider.dart';
import '../services/open_meteo_client.dart';
import '../theme/fjelia_style.dart';
import 'weather_glyph.dart';
import 'weather_sky.dart';

/// The sky over the athlete right now: the hour's weather, rain and wind,
/// and whether the sun is down.
typedef HomeSkyState = ({
  WeatherKind kind,
  bool night,
  double rainMm,
  double windKmh,
});

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
  return (
    kind: kind,
    night: night,
    rainMm: best.precipitationMm,
    windKmh: best.windSpeedKmh,
  );
}

/// A painted sky behind the top of the main tabs that follows today's
/// weather and the time of day. It fades into the page, comes in once and
/// never moves on its own; it shows only for today and only with real
/// weather data.
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
    final page = Theme.of(context).scaffoldBackgroundColor;
    // Blurred clouds are costly; the boundary keeps the sky out of every
    // scroll repaint.
    return IgnorePointer(
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(sky),
          tween: Tween(begin: 0, end: 1),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => CustomPaint(
            key: const ValueKey('home-sky'),
            painter: WeatherSkyPainter(
              sky.kind,
              rainMm: sky.rainMm,
              windKmh: sky.windKmh,
              night: sky.night,
              fadeTo: page,
              strength: t,
              lightLook: Fjelia.light,
            ),
          ),
        ),
      ),
    );
  }
}
