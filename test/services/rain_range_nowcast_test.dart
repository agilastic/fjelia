import 'package:flutter_test/flutter_test.dart';

import 'package:fjelia/models/weather_comparison.dart';
import 'package:fjelia/providers/plan_weather_provider.dart';
import 'package:fjelia/services/open_meteo_client.dart';
import 'package:fjelia/services/rain_nowcast.dart';

OpenMeteoPoint _point(DateTime time, double mm) => OpenMeteoPoint(
  time: time,
  temperatureC: 8,
  humidityPct: 90,
  pressureHpa: 1012,
  precipitationMm: mm,
  windSpeedKmh: 10,
  windDirection: 200,
);

OpenMeteoResult _result(String source, double Function(int hour) mm) =>
    OpenMeteoResult(
      points: [
        for (var h = 0; h < 48; h++) _point(DateTime(2026, 11, 2, h), mm(h)),
      ],
      sunrise: const {},
      sunset: const {},
      fetchedAt: DateTime(2026, 11, 2),
      rawJson: '',
      source: source,
    );

/// A radar answer like Bright Sky's: 7×7 cells, the place at (2.7, 2.5).
Map<String, dynamic> _radar(List<int> centreValues) => {
  'latlon_position': {'x': 2.732, 'y': 2.526},
  'radar': [
    for (final (i, v) in centreValues.indexed)
      {
        'timestamp': DateTime.utc(
          2026,
          11,
          2,
          20,
        ).add(Duration(minutes: 5 * i)).toIso8601String(),
        'precipitation_5': [
          for (var row = 0; row < 7; row++)
            [for (var col = 0; col < 7; col++) row == 3 && col == 3 ? v : 0],
        ],
      },
  ],
};

void main() {
  group('rain range', () {
    final dwd = _result('Bright Sky (DWD)', (h) => h >= 7 && h <= 18 ? .3 : 0);
    final model = _result('Open-Meteo', (h) => h == 9 || h == 30 ? .1 : 0);
    final other = _result('Pirate Weather', (h) => h >= 24 && h < 30 ? .5 : 0);

    test('past hours count as measured, the rest spans the forecasts', () {
      // At 12:00: 07–11 h are past (5 × 0.3 = 1.5 mm, measured).
      final range = dailyRainRange(DateTime(2026, 11, 2), dwd, [
        model,
      ], DateTime(2026, 11, 2, 12, 20))!;
      // DWD expects 7 more wet hours (2.1 mm), the model none.
      expect(range.low, closeTo(1.5, 1e-9));
      expect(range.high, closeTo(3.6, 1e-9));
    });

    test('tomorrow spans all forecasts that cover the whole day', () {
      final range = dailyRainRange(DateTime(2026, 11, 3), dwd, [
        model,
        other,
      ], DateTime(2026, 11, 2, 12))!;
      expect(range.low, 0);
      expect(range.high, closeTo(3.0, 1e-9));
    });

    test('a single forecast has no range', () {
      expect(
        dailyRainRange(
          DateTime(2026, 11, 3),
          dwd,
          const [],
          DateTime(2026, 11, 2),
        ),
        isNull,
      );
    });

    test('hourly spread leaves out the hours already past', () {
      final comparison = WeatherComparison(dwd.points, dwd.source, [
        model,
      ], now: DateTime(2026, 11, 2, 12, 30));
      expect(comparison.rainSpread.first.time, DateTime(2026, 11, 2, 12));
      final at13 = comparison.rainSpread.firstWhere(
        (s) => s.time == DateTime(2026, 11, 2, 13),
      );
      expect((at13.low, at13.high), (0.0, .3));
      expect(comparison.spread.first.time, DateTime(2026, 11, 2, 12));
    });
  });

  group('radar nowcast', () {
    final now = DateTime.utc(2026, 11, 2, 20, 1).toLocal();

    test('reads the cells around the place as mm per hour', () {
      final nowcast = parseRadar(_radar([0, 1, 2]))!;
      expect(nowcast.frames, hasLength(3));
      expect(nowcast.frames[1].mmPerHour, closeTo(.12, 1e-9));
      expect(nowcast.frames[2].mmPerHour, closeTo(.24, 1e-9));
    });

    test('dry, rain soon, raining with an end, raining on', () {
      expect(
        parseRadar(_radar(List.filled(13, 0)))!.outlook(now),
        isA<NowcastDry>(),
      );
      final soon = parseRadar(_radar([0, 0, 0, 0, 1, 1]))!.outlook(now);
      expect(soon, isA<NowcastRainSoon>());
      expect((soon as NowcastRainSoon).after.inMinutes, 19);
      final stops = parseRadar(_radar([1, 1, 1, 0, 0]))!.outlook(now);
      expect((stops as NowcastRaining).stopsIn!.inMinutes, 14);
      final on = parseRadar(_radar([1, 1, 1, 1]))!.outlook(now);
      expect((on as NowcastRaining).stopsIn, isNull);
    });

    test('only inside Germany', () {
      expect(inDwdRadarArea(52.32, 9.74), isTrue);
      expect(inDwdRadarArea(48.86, 2.35), isFalse);
    });
  });
}
