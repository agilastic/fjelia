import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fjelia/services/moon_phase.dart';
import 'package:fjelia/widgets/weather_glyph.dart';

void main() {
  group('moon phase', () {
    test('matches real full and new moons of 2026', () {
      // Full moons on 26 Oct and 24 Nov 2026, new moon on 9 Nov 2026.
      expect(moonPhaseOf(DateTime.utc(2026, 10, 26, 4)), MoonPhase.full);
      expect(moonPhaseOf(DateTime.utc(2026, 11, 24, 15)), MoonPhase.full);
      expect(moonPhaseOf(DateTime.utc(2026, 11, 9, 7)), MoonPhase.newMoon);
      expect(
        moonIllumination(DateTime.utc(2026, 11, 24, 15)),
        greaterThan(.97),
      );
      expect(moonIllumination(DateTime.utc(2026, 11, 9, 7)), lessThan(.03));
    });

    test('waxes after new moon and wanes after full moon', () {
      expect(moonWaxing(DateTime.utc(2026, 11, 13)), isTrue);
      expect(moonPhaseOf(DateTime.utc(2026, 11, 13)), MoonPhase.waxingCrescent);
      expect(moonWaxing(DateTime.utc(2026, 10, 30)), isFalse);
      expect(moonPhaseOf(DateTime.utc(2026, 11, 1, 20)), MoonPhase.lastQuarter);
    });
  });

  group('weather symbols', () {
    test('WMO codes map to the symbols', () {
      expect(weatherKindOf(0), WeatherKind.clear);
      expect(weatherKindOf(2), WeatherKind.partly);
      expect(weatherKindOf(45), WeatherKind.fog);
      expect(weatherKindOf(51), WeatherKind.drizzle);
      expect(weatherKindOf(61), WeatherKind.rain);
      expect(weatherKindOf(81), WeatherKind.rain);
      expect(weatherKindOf(73), WeatherKind.snow);
      expect(weatherKindOf(95), WeatherKind.thunder);
      expect(weatherKindOf(null), isNull);
    });

    test('a day shows rain only when it rains for more than an hour', () {
      expect(
        dominantWeather([WeatherKind.clear, WeatherKind.rain]),
        WeatherKind.clear,
      );
      expect(
        dominantWeather([
          WeatherKind.clear,
          WeatherKind.rain,
          WeatherKind.rain,
        ]),
        WeatherKind.rain,
      );
      // Two hours of a chart: one wet hour is enough.
      expect(
        dominantWeather([WeatherKind.cloudy, WeatherKind.drizzle], minWet: 1),
        WeatherKind.drizzle,
      );
      expect(
        dominantWeather([WeatherKind.clear, WeatherKind.thunder]),
        WeatherKind.thunder,
      );
    });

    test('night between sunset and sunrise, else 20:00 to 6:00', () {
      final rise = {'2026-11-02': DateTime(2026, 11, 2, 7, 12)};
      final set = {'2026-11-02': DateTime(2026, 11, 2, 16, 48)};
      expect(isNightAt(DateTime(2026, 11, 2, 7), rise, set), isTrue);
      expect(isNightAt(DateTime(2026, 11, 2, 12), rise, set), isFalse);
      expect(isNightAt(DateTime(2026, 11, 2, 17), rise, set), isTrue);
      expect(isNightAt(DateTime(2026, 11, 3, 5), rise, set), isTrue);
      expect(isNightAt(DateTime(2026, 11, 3, 12), rise, set), isFalse);
    });
  });

  testWidgets('one symbol per two hours by day, one per day in the week', (
    tester,
  ) async {
    final day = DateTime(2026, 11, 3);
    Future<int> glyphs(bool week, int hours) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            child: WeatherGlyphRow(
              week: week,
              points: [
                for (var h = 0; h < hours; h++)
                  (time: day.add(Duration(hours: h)), code: 3),
              ],
            ),
          ),
        ),
      );
      return tester.widgetList(find.byType(WeatherGlyph)).length;
    }

    expect(await glyphs(false, 24), 12);
    expect(await glyphs(true, 7 * 24), 7);
  });
}
