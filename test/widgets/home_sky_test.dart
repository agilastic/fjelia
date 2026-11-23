import 'dart:io';
import 'dart:ui' as ui;

import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/providers/heat_acclimation_provider.dart';
import 'package:fjelia/services/open_meteo_client.dart';
import 'package:fjelia/theme/fjelia_style.dart';
import 'package:fjelia/widgets/app_widgets.dart';
import 'package:fjelia/widgets/home_sky.dart';
import 'package:fjelia/widgets/weather_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

OpenMeteoPoint _hour(DateTime t, int code, {double rain = 0}) => OpenMeteoPoint(
  time: t,
  temperatureC: 8,
  humidityPct: 70,
  pressureHpa: 1015,
  precipitationMm: rain,
  windSpeedKmh: 10,
  windDirection: 200,
  weatherCode: code,
);

OpenMeteoResult _weather(List<OpenMeteoPoint> points) => OpenMeteoResult(
  points: points,
  sunrise: {'2026-11-23': DateTime(2026, 11, 23, 7, 50)},
  sunset: {'2026-11-23': DateTime(2026, 11, 23, 16, 20)},
  fetchedAt: DateTime(2026, 11, 23, 9),
  rawJson: '{}',
  source: 'test',
);

void main() {
  final noon = DateTime(2026, 11, 23, 12, 10);

  group('the sky right now', () {
    test('takes the hour nearest to now', () {
      final sky = homeSkyAt(
        _weather([
          _hour(DateTime(2026, 11, 23, 11), 3),
          _hour(DateTime(2026, 11, 23, 12), 61, rain: 1.2),
          _hour(DateTime(2026, 11, 23, 13), 0),
        ]),
        noon,
      );
      expect(sky?.kind, WeatherKind.rain);
      expect(sky?.night, isFalse);
      expect(sky?.rainMm, 1.2);
    });

    test('is night outside sunrise and sunset', () {
      final evening = DateTime(2026, 11, 23, 19);
      expect(homeSkyAt(_weather([_hour(evening, 0)]), evening)?.night, isTrue);
      final early = DateTime(2026, 11, 23, 6);
      expect(homeSkyAt(_weather([_hour(early, 0)]), early)?.night, isTrue);
    });

    test('paints nothing without a usable hour', () {
      expect(homeSkyAt(null, noon), isNull);
      expect(homeSkyAt(_weather([]), noon), isNull);
      // Hours away or without a weather code are not guessed from.
      expect(
        homeSkyAt(_weather([_hour(DateTime(2026, 11, 23, 15), 0)]), noon),
        isNull,
      );
      expect(
        homeSkyAt(
          _weather([
            OpenMeteoPoint(
              time: DateTime(2026, 11, 23, 12),
              temperatureC: 8,
              humidityPct: 70,
              pressureHpa: 1015,
              precipitationMm: 0,
              windSpeedKmh: 10,
              windDirection: 200,
            ),
          ]),
          noon,
        ),
        isNull,
      );
    });
  });

  group('on Home', () {
    setUpAll(() async {
      if (Platform.environment['FJELIA_UI_PREVIEW_DIR'] == null) return;
      final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
      if (font.existsSync()) {
        final bytes = ByteData.sublistView(await font.readAsBytes());
        for (final family in ['Roboto', 'Ahem']) {
          await (FontLoader(family)..addFont(Future.value(bytes))).load();
        }
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    tearDown(() => Fjelia.style = FjeliaStyle.dark);

    Widget app(
      OpenMeteoResult? weather, {
      DateTime? selected,
      DateTime? now,
      bool light = false,
    }) {
      Fjelia.style = light ? FjeliaStyle.light : FjeliaStyle.dark;
      return ProviderScope(
        overrides: [
          heatHourlyWeatherProvider.overrideWith((_) async => weather),
          selectedDateProvider.overrideWith(
            (_) => selected ?? DateTime(2026, 11, 23),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: light ? ThemeData.light() : ThemeData.dark(),
          home: Scaffold(
            backgroundColor: fjBackground,
            body: RepaintBoundary(
              key: const ValueKey('preview'),
              child: ColoredBox(
                color: fjBackground,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 360,
                      child: HomeSkyBand(now: now ?? noon),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 220, 16, 0),
                      child: SectionCard(
                        title: 'Morning briefing',
                        accent: [Color(0xFF9D7BFF), Color(0xFF3EE0FF)],
                        child: Text('The cards sit on the plain page.'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    Future<void> frames(WidgetTester tester) async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> preview(WidgetTester tester, String name) async {
      final output = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
      if (output == null) return;
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('preview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        await Directory(output).create(recursive: true);
        await File('$output/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
      });
    }

    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(393, 420);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    setUp(() => SharedPreferences.setMockInitialValues({}));

    for (final light in [false, true]) {
      for (final (name, code, at) in [
        ('clear', 0, noon),
        ('partly', 2, noon),
        ('rain', 61, noon),
        ('snow', 71, noon),
        ('night', 0, DateTime(2026, 11, 23, 19)),
      ]) {
        final look = light ? 'light' : 'dark';
        testWidgets('paints a $name sky ($look)', (tester) async {
          phone(tester);
          await tester.pumpWidget(
            app(
              _weather([
                _hour(
                  DateTime(2026, 11, 23, 12),
                  code,
                  rain: code == 61 ? 2 : 0,
                ),
                if (at != noon) _hour(at, code),
              ]),
              now: at,
              light: light,
            ),
          );
          await frames(tester);
          expect(find.byKey(const ValueKey('home-sky')), findsOneWidget);
          await preview(tester, 'sky_${name}_$look');
        });
      }
    }

    testWidgets('no sky without weather, on another day or when off', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(app(null));
      await frames(tester);
      expect(find.byKey(const ValueKey('home-sky')), findsNothing);

      final weather = _weather([_hour(DateTime(2026, 11, 23, 12), 0)]);
      await tester.pumpWidget(app(weather, selected: DateTime(2026, 11, 20)));
      await frames(tester);
      expect(find.byKey(const ValueKey('home-sky')), findsNothing);

      SharedPreferences.setMockInitialValues({'home_sky_v1': false});
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(weather));
      await frames(tester);
      expect(find.byKey(const ValueKey('home-sky')), findsNothing);
    });
  });
}
