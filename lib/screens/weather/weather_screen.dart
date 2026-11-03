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
import '../../widgets/weather_glyph.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});
  @override
  ConsumerState<WeatherScreen> createState() => _WeatherState();
}

class _WeatherState extends ConsumerState<WeatherScreen> {
  int days = 1;
  DateTime day = DateUtils.dateOnly(DateTime.now());
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
                      padding: EdgeInsets.all(20),
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
            final now = DateTime.now();
            final points = data!.pointsFor(day, days > 1, forecastDays: days);
            final todayKey = DateFormat('yyyy-MM-dd').format(now);
            Widget metric(
              String title,
              IconData icon,
              String value,
              String detail,
            ) => Container(
              width: (MediaQuery.sizeOf(context).width - 52) / 2,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF292929),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: muted,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          ref.watch(weatherPlaceNameProvider).valueOrNull ??
                              context.l10n.localWeather,
                          style: const TextStyle(fontSize: 12, color: muted),
                        ),
                      ),
                      IconButton(
                        tooltip: context.l10n.weatherLocation,
                        onPressed: () =>
                            showAppSheet(context, const WeatherLocationTab()),
                        icon: const Icon(Icons.tune, size: 18, color: muted),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(icon, color: muted, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: const TextStyle(fontSize: 10, color: muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    detail,
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            );
            String time(DateTime? value) =>
                value == null ? '—' : DateFormat.Hm().format(value);
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(heatHourlyWeatherProvider);
                await ref.read(heatHourlyWeatherProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.round2(current.temperatureC.round()),
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.roundRhRound2Hpa(
                                current.humidityPct.round(),
                                current.pressureHpa.round(),
                              ),
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              context.l10n.wetBulbTostringasfixedC(
                                data.wetBulb!.fixed(1),
                              ),
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${current.windSpeedKmh.round()} km/h · ${current.cloudCover ?? '—'}% cloud',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          const Icon(
                            Icons.water_drop_outlined,
                            color: Colors.lightBlue,
                          ),
                          Text(
                            '${current.precipitationProbability ?? '—'}%',
                            style: const TextStyle(color: Colors.lightBlue),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  WeatherRangeSwitcher(
                    days: days,
                    onChanged: (value) => setState(() {
                      days = value;
                      day = DateUtils.dateOnly(now);
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (days == 1) ...[
                        IconButton(
                          tooltip: context.l10n.previousForecastDay,
                          onPressed: day.isAfter(DateUtils.dateOnly(now))
                              ? () => setState(
                                  () => day = DateTime(
                                    day.year,
                                    day.month,
                                    day.day - 1,
                                  ),
                                )
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            DateUtils.isSameDay(day, now)
                                ? context.l10n.today
                                : DateFormat.MMMEd().format(day),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.nextForecastDay,
                          onPressed:
                              day.isBefore(
                                DateUtils.dateOnly(now)
                                    .add(const Duration(days: 13)),
                              )
                              ? () => setState(
                                  () => day = DateTime(
                                    day.year,
                                    day.month,
                                    day.day + 1,
                                  ),
                                )
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ] else
                        Expanded(
                          child: Text(
                            context.l10n.daysDayForecast(days),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  WeatherForecastChart(
                    points: points,
                    week: days > 1,
                    comparison:
                        ref.watch(weatherComparisonProvider).valueOrNull ?? [],
                    primarySource: data.result.source,
                    sunrise: data.result.sunrise,
                    sunset: data.result.sunset,
                  ),
                  if (data.availableDays(day, days) < days)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        context.l10n.thisProviderCurrentlySuppliesDays(
                          data.availableDays(day, days),
                          days,
                        ),
                        style: const TextStyle(fontSize: 10, color: muted),
                      ),
                    ),
                  SectionLabel(context.l10n.now),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      metric(
                        context.l10n.wind,
                        Icons.air,
                        '${current.windSpeedKmh.fixed(1)} km/h',
                        '${current.windDirection.round()}° · ${(current.windSpeedKmh / 1.852).fixed(1)} kn',
                      ),
                      metric(
                        context.l10n.uvIndex2,
                        Icons.wb_sunny_outlined,
                        '${current.uvIndex ?? '—'}',
                        current.uvIndex == null
                            ? 'Unavailable'
                            : current.uvIndex! < 3
                            ? context.l10n.low
                            : current.uvIndex! < 6
                            ? context.l10n.moderate
                            : context.l10n.high,
                      ),
                      metric(
                        context.l10n.sun2,
                        Icons.wb_twilight,
                        '${time(data.result.sunrise[todayKey])} ↑',
                        '${time(data.result.sunset[todayKey])} ↓',
                      ),
                      metric(
                        context.l10n.cloud,
                        Icons.cloud_outlined,
                        '${current.cloudCover ?? '—'}%',
                        current.cloudCover == null
                            ? 'Unavailable'
                            : current.cloudCover! >= 80
                            ? context.l10n.overcast
                            : current.cloudCover! > 20
                            ? context.l10n.partlyCloudy
                            : context.l10n.clear,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const WeatherRadar(),
                  SectionLabel(context.l10n.sunAndMoon),
                  // The moon tonight: how it looks, its phase and how much
                  // of it is lit.
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
                              size: 34,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    moonPhaseName(context, moonPhaseOf(night)),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    context.l10n.moonLit((lit * 100).round()),
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 11,
                                    ),
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
                          .where((key) => key.compareTo(todayKey) >= 0)
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
                                      ? context.l10n.today
                                      : DateFormat.MMMEd().format(
                                          DateTime.parse(key),
                                        ),
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
                                context.l10n.keyKey2(time(rise), time(set)),
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (daylight != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  context.l10n.daylightLength(
                                    daylight.inHours,
                                    daylight.inMinutes % 60,
                                  ),
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 10,
                                  ),
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
                    // Every forecast in the chart's range is named, not
                    // only the main one (CC BY / DWD attribution).
                    context.l10n.dataSourceUpdatedFetchedat(
                      {
                        data.result.source,
                        for (final other
                            in ref
                                    .watch(weatherComparisonProvider)
                                    .valueOrNull ??
                                const [])
                          if (other.points.isNotEmpty) other.source,
                      }.join(', '),
                      DateFormat.Hm().format(data.result.fetchedAt),
                    ),
                    style: const TextStyle(fontSize: 10, color: muted),
                  ),
                ],
              ),
            );
          },
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
