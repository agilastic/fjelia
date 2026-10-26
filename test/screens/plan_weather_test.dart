import 'package:fl_chart/fl_chart.dart';
import 'package:fjelia/widgets/weather_forecast_preview.dart';
import 'package:fjelia/widgets/weather_visuals.dart';
import 'package:fjelia/models/weather_comparison.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/providers/heat_acclimation_provider.dart';
import 'package:fjelia/providers/plan_weather_provider.dart';
import 'package:fjelia/screens/planner/plan_overview_cards.dart';
import 'package:fjelia/screens/weather/weather_screen.dart';
import 'package:fjelia/services/open_meteo_client.dart';
import 'package:fjelia/services/weather_radar_service.dart';

OpenMeteoResult fixture({DateTime? at}) {
  final now = at ?? DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  return OpenMeteoResult(
    points: [
      for (
        var h = 0;
        h <
            DateTime(
              start.year,
              start.month,
              start.day + 14,
            ).difference(start).inHours;
        h++
      )
        OpenMeteoPoint(
          time: start.add(Duration(hours: h)),
          temperatureC: 17 + h % 6,
          humidityPct: 89,
          pressureHpa: 1011,
          precipitationMm: h % 5 == 0 ? 2 : 0,
          precipitationProbability: 87,
          windSpeedKmh: 17,
          windDirection: 315,
          cloudCover: 100,
          uvIndex: 2,
          weatherCode: 61,
        ),
    ],
    sunrise: {
      for (var d = 0; d < 14; d++)
        start.add(Duration(days: d)).toIso8601String().substring(0, 10): start
            .add(Duration(days: d, hours: 8)),
    },
    sunset: {
      for (var d = 0; d < 14; d++)
        start.add(Duration(days: d)).toIso8601String().substring(0, 10): start
            .add(Duration(days: d, hours: 19)),
    },
    fetchedAt: now,
    rawJson: '{}',
    source: 'Test forecast',
  );
}

void main() {
  test('weather preparation sorts hours and selects calendar day/week', () {
    final result = fixture();
    final now = DateTime.now();
    final data = PlanWeatherData(result, now);
    expect(data.current, isNotNull);
    expect(data.upcoming.length, 25);
    expect(data.upcoming.first.time, data.previewStart);
    expect(
      data.upcoming.last.time,
      data.previewStart.add(const Duration(hours: 24)),
    );
    expect(data.pointsFor(now, false).length, 24);
    expect(
      data.pointsFor(now, true).length,
      DateTime(
        now.year,
        now.month,
        now.day + 7,
      ).difference(DateTime(now.year, now.month, now.day)).inHours,
    );
    expect(
      data.pointsFor(now, true, forecastDays: 14).length,
      DateTime(
        now.year,
        now.month,
        now.day + 14,
      ).difference(DateTime(now.year, now.month, now.day)).inHours,
    );
    expect(data.wetBulb, lessThan(data.current!.temperatureC));
  });
  test('the 24-hour Plan preview continues through midnight', () {
    final now = DateTime(2026, 10, 26, 20, 30);
    final data = PlanWeatherData(fixture(at: now), now);
    expect(data.previewStart, DateTime(2026, 10, 26, 20));
    expect(data.upcoming.length, 25);
    expect(data.upcoming.first.time, DateTime(2026, 10, 26, 20));
    expect(data.upcoming.last.time, DateTime(2026, 10, 27, 20));
  });
  testWidgets('a partial preview keeps missing hours on the 24-hour scale', (
    tester,
  ) async {
    final samples = fixture().points;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeatherForecastPreview(
            start: samples.first.time,
            points: [samples[12], samples[0], samples[6]],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final chart = tester.widget<LineChart>(find.byType(LineChart)).data;
    expect(chart.minX, 0);
    expect(chart.maxX, 24);
    expect(chart.lineBarsData.single.spots.map((point) => point.x), [0, 6, 12]);
    for (final label in ['6h', '12h', '18h', '24h']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
  test(
    'current-hour highlight is limited to today and excludes overview ranges',
    () {
      final points = fixture().points;
      final day = DateTime(
        points.first.time.year,
        points.first.time.month,
        points.first.time.day,
      );
      expect(
        currentWeatherHourIndex(
          points.take(24).toList(),
          DateTime(day.year, day.month, day.day, 16, 59),
        ),
        16,
      );
      expect(
        currentWeatherHourIndex(
          points.take(24).toList(),
          DateTime(day.year, day.month, day.day, 17),
        ),
        17,
      );
      expect(
        currentWeatherHourIndex(
          points.skip(24).take(24).toList(),
          DateTime(day.year, day.month, day.day, 16),
        ),
        isNull,
      );
      expect(
        currentWeatherHourIndex(
          points,
          DateTime(day.year, day.month, day.day, 16),
          overview: true,
        ),
        isNull,
      );
    },
  );
  test(
    'provider spread only covers hours with actual overlapping forecasts',
    () {
      final primary = fixture();
      final secondary = OpenMeteoResult(
        points: [
          for (final p in primary.points.take(48))
            OpenMeteoPoint(
              time: p.time,
              temperatureC: p.temperatureC + 3,
              humidityPct: p.humidityPct,
              pressureHpa: p.pressureHpa,
              precipitationMm: p.precipitationMm,
              windSpeedKmh: p.windSpeedKmh,
              windDirection: p.windDirection,
            ),
        ],
        sunrise: {},
        sunset: {},
        fetchedAt: DateTime.now(),
        rawJson: '{}',
        source: 'Second provider',
      );
      final comparison = WeatherComparison(primary.points, primary.source, [
        secondary,
      ]);
      expect(comparison.series.length, 2);
      expect(comparison.series.last.points.length, 48);
      expect(comparison.spread.length, 48);
      expect(
        comparison.spread.every((p) => (p.high - p.low - 3).abs() < .0001),
        isTrue,
      );
      expect(
        WeatherComparison(primary.points, primary.source, []).spread,
        isEmpty,
      );
    },
  );
  test('radar metadata uses returned host and sorts past frames', () {
    final frames = WeatherRadarService.parse({
      'host': 'https://tilecache.rainviewer.com',
      'radar': {
        'past': [
          {'time': 200, 'path': '/v2/radar/200'},
          {'time': 100, 'path': '/v2/radar/100'},
        ],
      },
    });
    expect(
      frames.first.tileUrl,
      'https://tilecache.rainviewer.com/v2/radar/100/256/{z}/{x}/{y}/2/1_1.png',
    );
    expect(frames.first.time.isBefore(frames.last.time), isTrue);
    expect(
      () => WeatherRadarService.parse({
        'host': 'http://invalid.test',
        'radar': {},
      }),
      throwsFormatException,
    );
  });
  testWidgets(
    'weather graph fullscreen preserves data, selection and provider comparison',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = fixture();
      final points = source.points.take(24).toList();
      final secondary = OpenMeteoResult(
        points: points,
        sunrise: {},
        sunset: {},
        fetchedAt: DateTime.now(),
        rawJson: '{}',
        source: 'Second provider',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeatherForecastChart(
                points: points,
                week: false,
                primarySource: source.source,
                comparison: [secondary],
              ),
            ),
          ),
        ),
      );
      final plot = find
          .descendant(
            of: find.byType(WeatherForecastChart),
            matching: find.byType(CustomPaint),
          )
          .last;
      await tester.tapAt(tester.getCenter(plot));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fullscreen'));
      await tester.pumpAndSettle();
      expect(find.byType(WeatherChartFullscreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(WeatherChartFullscreen),
          matching: find.byType(RotatedBox),
        ),
        findsOneWidget,
      );
      final fullscreen = tester.widget<WeatherForecastChart>(
        find.byType(WeatherForecastChart).last,
      );
      expect(fullscreen.fullscreen, isTrue);
      expect(fullscreen.initialSelected, isNotNull);
      expect(fullscreen.points.length, 24);
      expect(fullscreen.comparison.single.source, 'Second provider');
      expect(find.textContaining('°C ·'), findsOneWidget);
      tester.view.physicalSize = const Size(852, 393);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(WeatherChartFullscreen),
          matching: find.byType(RotatedBox),
        ),
        findsNothing,
      );
      final fullscreenChart = find.byType(WeatherForecastChart).last;
      final legend = find.descendant(
        of: fullscreenChart,
        matching: find.byKey(const ValueKey('weather-chart-legend')),
      );
      expect(
        tester.getRect(legend).bottom,
        closeTo(tester.getRect(fullscreenChart).bottom, 1),
      );
      final fullscreenPlot = find
          .descendant(of: fullscreenChart, matching: find.byType(CustomPaint))
          .last;
      expect(
        tester.getSize(fullscreenPlot).height,
        greaterThan(tester.getSize(fullscreenChart).height * .65),
      );
      await tester.tap(find.byTooltip('Close fullscreen weather chart'));
      await tester.pumpAndSettle();
      expect(find.byType(WeatherChartFullscreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Plan weather remains visible without heat acclimation and opens forecast',
    (tester) async {
      tester.view.physicalSize = const Size(320, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heatHourlyWeatherProvider.overrideWith((ref) async => fixture()),
            heatPreferredLocationProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: PlanWeatherStrip()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('89%'), findsOneWidget);
      expect(find.text('WEATHER FORECAST'), findsOneWidget);
      expect(find.text('Next 24 hours'), findsOneWidget);
      expect(find.byType(WeatherForecastPreview), findsOneWidget);
      for (final label in ['6h', '12h', '18h', '24h']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.byType(PlanWeatherStrip));
      await tester.pumpAndSettle();
      expect(find.byType(WeatherScreen), findsOneWidget);
      expect(find.textContaining('Wet-bulb'), findsOneWidget);
      await tester.tap(find.text('WEEK'));
      await tester.pumpAndSettle();
      expect(find.text('7-Day Forecast'), findsOneWidget);
      await tester.tap(find.text('14 DAYS'));
      await tester.pumpAndSettle();
      expect(find.text('14-Day Forecast'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('UV INDEX'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('UV INDEX'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
