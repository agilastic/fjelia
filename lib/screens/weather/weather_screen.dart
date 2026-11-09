import '../../theme/fjelia_style.dart';
import '../../l10n/formats.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/weather_location_provider.dart';
import '../../widgets/weather_range_switcher.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/plan_weather_provider.dart';
import '../../providers/heat_acclimation_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/weather_visuals.dart';
import '../settings/weather_location_tab.dart';
import 'weather_radar.dart';
import '../../services/moon_phase.dart';
import '../../services/open_meteo_client.dart';
import '../../widgets/weather_glyph.dart';
import '../../widgets/weather_sky.dart';

/// The neon pairs of the weather tiles.
const _windAccent = [Color(0xFF3EE0FF), Color(0xFF4F6BFF)];
const _uvAccent = [Color(0xFFFFE14F), Color(0xFFFF4F8B)];
const _sunAccent = [Color(0xFFFF9A3C), Color(0xFFFF4FD8)];
const _cloudAccent = [Color(0xFF9D7BFF), Color(0xFF3EE0FF)];
const _rainAccent = [Color(0xFF3EE0FF), Color(0xFF00D4A0)];
const _pickedEdge = [Color(0xFFFF4FD8), Color(0xFF9D7BFF), Color(0xFF3EE0FF)];

/// The full forecast. [initialDay] opens it on that day, as a tap on a day
/// of the plan's weather strip does; without it the forecast starts today.
class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key, this.initialDay});
  final DateTime? initialDay;
  @override
  ConsumerState<WeatherScreen> createState() => _WeatherState();
}

class _WeatherState extends ConsumerState<WeatherScreen> {
  static const _pillWidth = 66.0, _pillGap = 8.0, _lastDay = 13;
  int days = 1;
  late DateTime day = _clamp(widget.initialDay);
  late final pills = ScrollController(initialScrollOffset: _offsetOf(day));

  static DateTime get _today => DateUtils.dateOnly(DateTime.now());

  static DateTime _clamp(DateTime? wanted) {
    final today = _today;
    if (wanted == null) return today;
    final d = DateUtils.dateOnly(wanted);
    final last = DateTime(today.year, today.month, today.day + _lastDay);
    return d.isBefore(today) ? today : (d.isAfter(last) ? last : d);
  }

  /// Puts the chosen day second in the row, so the day before shows too.
  static double _offsetOf(DateTime d) {
    final index = DateUtils.dateOnly(d).difference(_today).inDays;
    return ((index - 1) * (_pillWidth + _pillGap)).clamp(0, double.infinity);
  }

  @override
  void dispose() {
    pills.dispose();
    super.dispose();
  }

  void _pick(DateTime d) => setState(() {
    days = 1;
    day = d;
  });

  @override
  Widget build(BuildContext context) => SheetPage(
    title: context.l10n.weather,
    child: ref
        .watch(planWeatherProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(
            child: TextButton.icon(
              onPressed: () => ref.invalidate(heatHourlyWeatherProvider),
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.weatherUnavailableRetry),
            ),
          ),
          data: (data) {
            final current = data?.current;
            if (current == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        context.l10n.chooseAFixedLocationIn,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          showAppSheet(context, const WeatherLocationTab()),
                      child: Text(context.l10n.locationSettings),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(heatPreferredLocationProvider);
                        ref.invalidate(heatHourlyWeatherProvider);
                      },
                      child: Text(context.l10n.retryLocation),
                    ),
                  ],
                ),
              );
            }
            return _content(context, data!, current);
          },
        ),
  );

  Widget _content(
    BuildContext context,
    PlanWeatherData data,
    OpenMeteoPoint current,
  ) {
    final l = context.l10n;
    final now = DateTime.now();
    final today = _today;
    final isToday = DateUtils.isSameDay(day, now);
    final points = data.pointsFor(day, days > 1, forecastDays: days);
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final dayKey = DateFormat('yyyy-MM-dd').format(day);
    final selected = PlanWeatherDay(day, data.pointsFor(day, false));
    final available = data.availableDays(today, _lastDay + 1);
    final forecastDays = [
      for (var i = 0; i < available; i++)
        PlanWeatherDay(
          DateTime(today.year, today.month, today.day + i),
          data.pointsFor(
            DateTime(today.year, today.month, today.day + i),
            false,
          ),
        ),
    ];
    WeatherKind kindOf(DateTime d) =>
        dominantWeather(
          data
              .pointsFor(d, false)
              .where((p) => p.time.hour >= 7 && p.time.hour < 20)
              .map((p) => weatherKindOf(p.weatherCode)),
        ) ??
        WeatherKind.cloudy;
    String time(DateTime? value) =>
        value == null ? '—' : DateFormat.Hm().format(value);
    final width = MediaQuery.sizeOf(context).width;
    final tileWidth = (width - 44) / 2;

    final uv = isToday ? current.uvIndex : selected.uv;
    final cloud = isToday
        ? current.cloudCover
        : () {
            final values = [
              for (final p in data.pointsFor(day, false))
                if (p.cloudCover != null) p.cloudCover!,
            ];
            return values.isEmpty
                ? null
                : (values.reduce((a, b) => a + b) / values.length).round();
          }();
    final windKmh = isToday ? current.windSpeedKmh : selected.windKmh;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(heatHourlyWeatherProvider);
        await ref.read(heatHourlyWeatherProvider.future);
      },
      child: ListView(
        key: const ValueKey('weather-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // Where: the place and its settings.
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 16,
                color: fjAccent(const Color(0xFFFF4FD8)),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  ref.watch(weatherPlaceNameProvider).valueOrNull ??
                      l.localWeather,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fjInk70,
                  ),
                ),
              ),
              IconButton(
                tooltip: l.weatherLocation,
                onPressed: () =>
                    showAppSheet(context, const WeatherLocationTab()),
                icon: Icon(Icons.tune, size: 18, color: muted),
              ),
            ],
          ),
          // Every forecast day as a small sky; the chosen one glows.
          SizedBox(
            height: 92,
            child: ListView.separated(
              controller: pills,
              scrollDirection: Axis.horizontal,
              itemCount: forecastDays.length,
              separatorBuilder: (_, _) => const SizedBox(width: _pillGap),
              itemBuilder: (context, i) {
                final d = forecastDays[i];
                return _DayPill(
                  key: ValueKey('weather-day-$i'),
                  day: d,
                  kind: kindOf(d.date),
                  label: i == 0 ? l.today : DateFormat.E().format(d.date),
                  date: DateFormat.d().format(d.date),
                  picked: days == 1 && DateUtils.isSameDay(d.date, day),
                  width: _pillWidth,
                  onTap: () => _pick(d.date),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _Hero(
            key: const ValueKey('weather-hero'),
            kind: isToday && days == 1
                ? (weatherKindOf(current.weatherCode) ?? kindOf(day))
                : kindOf(day),
            rainMm: selected.rainMm ?? 0,
            windKmh: windKmh ?? 0,
            title: isToday
                ? l.today.toUpperCase()
                : DateFormat.MMMMEEEEd().format(day).toUpperCase(),
            temperature: isToday
                ? current.temperatureC.round()
                : selected.maxC?.round(),
            lines: [
              if (selected.minC != null)
                l.weatherLowHigh(
                  selected.minC!.round(),
                  selected.maxC!.round(),
                ),
              if (isToday) ...[
                l.roundRhRound2Hpa(
                  current.humidityPct.round(),
                  current.pressureHpa.round(),
                ),
                if (data.wetBulb != null)
                  l.wetBulbTostringasfixedC(data.wetBulb!.fixed(1)),
              ],
            ],
            chips: [
              (
                Icons.water_drop_rounded,
                isToday
                    ? '${current.precipitationProbability ?? '—'}%'
                    : '${(selected.rainMm ?? 0).fixed(1)} mm',
              ),
              (Icons.air_rounded, '${(windKmh ?? 0).round()} km/h'),
              (Icons.wb_sunny_rounded, 'UV ${uv?.round() ?? '—'}'),
            ],
          ),
          const SizedBox(height: 20),
          WeatherRangeSwitcher(
            days: days,
            onChanged: (value) => setState(() {
              days = value;
              if (value > 1) day = today;
            }),
          ),
          if (days > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.daysDayForecast(days),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          WeatherForecastChart(
            points: points,
            week: days > 1,
            comparison: ref.watch(weatherComparisonProvider).valueOrNull ?? [],
            primarySource: data.result.source,
            sunrise: data.result.sunrise,
            sunset: data.result.sunset,
          ),
          if (data.availableDays(day, days) < days)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                l.thisProviderCurrentlySuppliesDays(
                  data.availableDays(day, days),
                  days,
                ),
                style: TextStyle(fontSize: 10, color: muted),
              ),
            ),
          const SizedBox(height: 18),
          GradientTitle(
            isToday ? l.now : DateFormat.MMMEd().format(day),
            colors: _pickedEdge,
            size: 12,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _NeonTile(
                width: tileWidth,
                accent: _windAccent,
                icon: Icons.air_rounded,
                title: l.wind,
                value: '${(windKmh ?? 0).fixed(1)} km/h',
                detail: isToday
                    ? '${current.windDirection.round()}° · '
                          '${(current.windSpeedKmh / 1.852).fixed(1)} kn'
                    : l.weatherDayPeak,
              ),
              _NeonTile(
                width: tileWidth,
                accent: _uvAccent,
                icon: Icons.wb_sunny_rounded,
                title: l.uvIndex2,
                value: '${uv?.round() ?? '—'}',
                detail: uv == null
                    ? l.unavailable
                    : uv < 3
                    ? l.low
                    : uv < 6
                    ? l.moderate
                    : l.high,
              ),
              _NeonTile(
                width: tileWidth,
                accent: _sunAccent,
                icon: Icons.wb_twilight_rounded,
                title: l.sun2,
                value: '${time(data.result.sunrise[dayKey])} ↑',
                detail: '${time(data.result.sunset[dayKey])} ↓',
              ),
              isToday
                  ? _NeonTile(
                      width: tileWidth,
                      accent: _cloudAccent,
                      icon: Icons.cloud_rounded,
                      title: l.cloud,
                      value: '${cloud ?? '—'}%',
                      detail: cloud == null
                          ? l.unavailable
                          : cloud >= 80
                          ? l.overcast
                          : cloud > 20
                          ? l.partlyCloudy
                          : l.clear,
                    )
                  : _NeonTile(
                      width: tileWidth,
                      accent: _rainAccent,
                      icon: Icons.water_drop_rounded,
                      title: l.weatherRain,
                      value: '${(selected.rainMm ?? 0).fixed(1)} mm',
                      detail: l.weatherDayTotal,
                    ),
            ],
          ),
          // The radar shows the rain now; a later day has none.
          if (isToday) ...[const SizedBox(height: 16), const WeatherRadar()],
          const SizedBox(height: 22),
          GradientTitle(l.sunAndMoon, colors: _sunAccent, size: 12),
          const SizedBox(height: 10),
          // The moon on the chosen night: how it looks, its phase and how
          // much of it is lit.
          Builder(
            builder: (context) {
              final night = DateTime(day.year, day.month, day.day, 22);
              final lit = moonIllumination(night);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    MoonGlyph(
                      illumination: lit,
                      waxing: moonWaxing(night),
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            moonPhaseName(context, moonPhaseOf(night)),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            l.moonLit((lit * 100).round()),
                            style: TextStyle(color: muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          for (final key
              in data.result.sunrise.keys
                  .where((key) => key.compareTo(dayKey) >= 0)
                  .take(days))
            Builder(
              builder: (context) {
                final rise = data.result.sunrise[key];
                final set = data.result.sunset[key];
                final daylight = rise != null && set != null
                    ? set.difference(rise)
                    : null;
                final night = DateTime.parse(key)
                    .add(const Duration(hours: 22));
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          key == todayKey
                              ? l.today
                              : DateFormat.MMMEd().format(DateTime.parse(key)),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const Icon(
                        Icons.wb_twilight,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l.keyKey2(time(rise), time(set)),
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (daylight != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          l.daylightLength(
                            daylight.inHours,
                            daylight.inMinutes % 60,
                          ),
                          style: TextStyle(color: muted, fontSize: 10),
                        ),
                      ],
                      const SizedBox(width: 8),
                      MoonGlyph(
                        illumination: moonIllumination(night),
                        waxing: moonWaxing(night),
                        size: 16,
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          Text(
            // Every forecast in the chart's range is named, not only the
            // main one (CC BY / DWD attribution).
            l.dataSourceUpdatedFetchedat(
              {
                data.result.source,
                for (final other
                    in ref.watch(weatherComparisonProvider).valueOrNull ??
                        const [])
                  if (other.points.isNotEmpty) other.source,
              }.join(', '),
              DateFormat.Hm().format(data.result.fetchedAt),
            ),
            style: TextStyle(fontSize: 10, color: muted),
          ),
        ],
      ),
    );
  }
}

/// One forecast day in the row: its sky, the weekday, the date and the
/// high. The chosen day stands out with a glowing gradient edge.
class _DayPill extends StatelessWidget {
  const _DayPill({
    super.key,
    required this.day,
    required this.kind,
    required this.label,
    required this.date,
    required this.picked,
    required this.width,
    required this.onTap,
  });
  final PlanWeatherDay day;
  final WeatherKind kind;
  final String label, date;
  final bool picked;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedScale(
      scale: picked ? 1 : .92,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: width,
        padding: EdgeInsets.all(picked ? 2 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: picked
              ? const LinearGradient(
                  colors: _pickedEdge,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: [
            if (picked)
              BoxShadow(
                color: _pickedEdge[1].withValues(alpha: .45),
                blurRadius: 14,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(picked ? 18 : 20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: WeatherSkyPainter(
                  kind,
                  rainMm: day.rainMm ?? 0,
                  windKmh: day.windKmh ?? 0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        shadows: _shadow,
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        shadows: _shadow,
                      ),
                    ),
                    Expanded(child: WeatherGlyph(kind: kind, size: 30)),
                    Text(
                      day.maxC == null ? '—' : '${day.maxC!.round()}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        shadows: _shadow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

const _shadow = [Shadow(color: Colors.black54, blurRadius: 4)];

/// The chosen day big: its sky full-width, the temperature huge, the facts
/// as glassy chips.
class _Hero extends StatelessWidget {
  const _Hero({
    super.key,
    required this.kind,
    required this.rainMm,
    required this.windKmh,
    required this.title,
    required this.temperature,
    required this.lines,
    required this.chips,
  });
  final WeatherKind kind;
  final double rainMm, windKmh;
  final String title;
  final int? temperature;
  final List<String> lines;
  final List<(IconData, String)> chips;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(title),
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 380),
    curve: Curves.easeOutCubic,
    // Moves and grows in rather than fading: an Opacity layer over the
    // glyph's blurred glow trips Impeller's validation.
    builder: (context, t, child) => Transform.translate(
      offset: Offset(0, (1 - t) * 12),
      child: Transform.scale(scale: .97 + .03 * t, child: child),
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3EE0FF).withValues(alpha: .14),
            blurRadius: 28,
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: WeatherSkyPainter(
                  kind,
                  rainMm: rainMm,
                  windKmh: windKmh,
                ),
              ),
            ),
            Positioned(
              right: -18,
              top: -14,
              child: WeatherGlyph(kind: kind, size: 140),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w900,
                      shadows: _shadow,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: const LinearGradient(
                      colors: [Colors.white, Color(0xFFBFF6FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader,
                    child: Text(
                      temperature == null ? '—' : '$temperature°',
                      style: const TextStyle(
                        fontSize: 84,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final line in lines)
                    Text(
                      line,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: _shadow,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (icon, text) in chips)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 15, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A figure on a panel with a neon gradient edge and its glow.
class _NeonTile extends StatelessWidget {
  const _NeonTile({
    required this.width,
    required this.accent,
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });
  final double width;
  final List<Color> accent;
  final IconData icon;
  final String title, value, detail;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(1.5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        colors: accent,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: accent.last.withValues(alpha: Fjelia.light ? .12 : .2),
          blurRadius: 18,
          spreadRadius: -4,
        ),
      ],
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: fjGlow(
          accent,
          strength: 1.4,
        ).copyWith(borderRadius: BorderRadius.circular(20.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: LinearGradient(
                    colors: [for (final c in accent) fjAccent(c)],
                  ).createShader,
                  child: Icon(icon, size: 18),
                ),
                const SizedBox(width: 6),
                Expanded(child: GradientTitle(title, colors: accent, size: 10)),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: fjInk,
                  letterSpacing: -.5,
                ),
              ),
            ),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}

String moonPhaseName(BuildContext context, MoonPhase phase) {
  final l10n = context.l10n;
  return switch (phase) {
    MoonPhase.newMoon => l10n.moonNew,
    MoonPhase.waxingCrescent => l10n.moonWaxingCrescent,
    MoonPhase.firstQuarter => l10n.moonFirstQuarter,
    MoonPhase.waxingGibbous => l10n.moonWaxingGibbous,
    MoonPhase.full => l10n.moonFull,
    MoonPhase.waningGibbous => l10n.moonWaningGibbous,
    MoonPhase.lastQuarter => l10n.moonLastQuarter,
    MoonPhase.waningCrescent => l10n.moonWaningCrescent,
  };
}
