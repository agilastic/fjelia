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
    title: 'Weather',
    child: ref
        .watch(planWeatherProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(
            child: TextButton.icon(
              onPressed: () => ref.invalidate(heatHourlyWeatherProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Weather unavailable · Retry'),
            ),
          ),
          data: (data) {
            final current = data?.current;
            if (current == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Choose a fixed location in Weather & Location settings, or allow location access for local weather.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          showAppSheet(context, const WeatherLocationTab()),
                      child: const Text('Location settings'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(heatPreferredLocationProvider);
                        ref.invalidate(heatHourlyWeatherProvider);
                      },
                      child: const Text('Retry location'),
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
                              'Local weather',
                          style: const TextStyle(fontSize: 12, color: muted),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Weather & Location',
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
                value == null ? '—' : DateFormat('HH:mm').format(value);
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
                        '${current.temperatureC.round()}°',
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
                              '${current.humidityPct.round()}% RH · ${current.pressureHpa.round()} hPa',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Wet-bulb ${data.wetBulb!.toStringAsFixed(1)}°C',
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
                          tooltip: 'Previous forecast day',
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
                                ? 'Today'
                                : DateFormat('EEE d MMM').format(day),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Next forecast day',
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
                            '$days-Day Forecast',
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
                  ),
                  if (data.availableDays(day, days) < days)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'This provider currently supplies ${data.availableDays(day, days)} of $days forecast days.',
                        style: const TextStyle(fontSize: 10, color: muted),
                      ),
                    ),
                  const SectionLabel('Now'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      metric(
                        'WIND',
                        Icons.air,
                        '${current.windSpeedKmh.toStringAsFixed(1)} km/h',
                        '${current.windDirection.round()}° · ${(current.windSpeedKmh / 1.852).toStringAsFixed(1)} kn',
                      ),
                      metric(
                        'UV INDEX',
                        Icons.wb_sunny_outlined,
                        '${current.uvIndex ?? '—'}',
                        current.uvIndex == null
                            ? 'Unavailable'
                            : current.uvIndex! < 3
                            ? 'Low'
                            : current.uvIndex! < 6
                            ? 'Moderate'
                            : 'High',
                      ),
                      metric(
                        'SUN',
                        Icons.wb_twilight,
                        '${time(data.result.sunrise[todayKey])} ↑',
                        '${time(data.result.sunset[todayKey])} ↓',
                      ),
                      metric(
                        'CLOUD',
                        Icons.cloud_outlined,
                        '${current.cloudCover ?? '—'}%',
                        current.cloudCover == null
                            ? 'Unavailable'
                            : current.cloudCover! >= 80
                            ? 'Overcast'
                            : current.cloudCover! > 20
                            ? 'Partly cloudy'
                            : 'Clear',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const WeatherRadar(),
                  const SectionLabel('Sunrise / Sunset'),
                  for (final key
                      in data.result.sunrise.keys
                          .where((key) => key.compareTo(todayKey) >= 0)
                          .take(days))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            key == todayKey
                                ? 'Today'
                                : DateFormat('EEE d MMM')
                                      .format(DateTime.parse(key)),
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '☀ ${time(data.result.sunrise[key])}   ☾ ${time(data.result.sunset[key])}',
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Data: ${data.result.source} · Updated ${DateFormat('HH:mm').format(data.result.fetchedAt)}',
                    style: const TextStyle(fontSize: 10, color: muted),
                  ),
                ],
              ),
            );
          },
        ),
  );
}
