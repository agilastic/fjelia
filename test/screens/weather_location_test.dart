import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fjelia/services/weather_geocoding_service.dart';
import 'package:fjelia/providers/plan_weather_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fjelia/screens/settings/settings_sheet.dart';
import 'package:fjelia/screens/settings/weather_location_tab.dart';
import 'package:fjelia/providers/weather_location_provider.dart';
import 'package:fjelia/providers/heat_acclimation_provider.dart';
import 'package:fjelia/services/heat_acclimation_settings.dart';
import 'package:fjelia/services/location_service.dart';

class _Location extends LocationService {
  @override
  Future<CurrentLocationData?> getCurrentLocation() async =>
      CurrentLocationData(
        latitude: 39.8,
        longitude: 3.1,
        timestamp: DateTime.now(),
      );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'heat_acclimation_enabled': false}));
  testWidgets(
    'Weather & Location is accessible in Settings and saves fixed coordinates',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: SettingsSheet())),
        ),
      );
      await tester.tap(find.text('Weather & Location'));
      await tester.pumpAndSettle();
      expect(find.byType(WeatherLocationTab), findsOneWidget);
      await tester.tap(find.text('Fixed location'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(TextField, 'Latitude'),
        150,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Latitude'),
        '39.8021',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Longitude'),
        '3.1191',
      );
      await tester.drag(find.byType(ListView).last, const Offset(0, -250));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save location'));
      await tester.pumpAndSettle();
      final saved = await const HeatAcclimationSettingsStore().load();
      await tester.pumpAndSettle();
      expect(saved.locationMode, HeatLocationMode.fixed);
      expect(saved.fixedLatitude, 39.8021);
      expect(saved.fixedLongitude, 3.1191);
      expect(saved.enabled, isFalse);
      await tester.scrollUntilVisible(
        find.text('Fixed location saved. Weather will refresh.'),
        120,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        find.text('Fixed location saved. Weather will refresh.'),
        findsOneWidget,
      );
    },
  );
  testWidgets('city selection saves its name and coordinates automatically', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = WeatherGeocodingService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'results': [
              {
                'name': 'Palma',
                'country': 'Spain',
                'latitude': 39.57,
                'longitude': 2.65,
              },
            ],
          }),
          200,
        ),
      ),
    );
    addTearDown(service.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherGeocodingServiceProvider.overrideWithValue(service),
          heatPreferredLocationProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: Scaffold(body: WeatherLocationTab())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fixed location'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'City or town'),
      'Palma',
    );
    await tester.ensureVisible(find.text('Search city'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search city'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Palma, Spain'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Palma, Spain'));
    await tester.pumpAndSettle();
    final saved = await const HeatAcclimationSettingsStore().load();
    expect(saved.fixedLocationName, 'Palma, Spain');
    expect(saved.fixedLatitude, 39.57);
    expect(saved.fixedLongitude, 2.65);
    expect(saved.locationMode, HeatLocationMode.fixed);
  });
  test(
    'none persists, retains saved coordinates and bypasses location access',
    () async {
      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWith(
            (ref) => throw StateError('Location must not be requested'),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(heatAcclimationSettingsProvider.future);
      final actions = container.read(weatherLocationActionsProvider);
      await actions.saveFixed('39.8', '3.1');
      await actions.useNone();
      final settings = await const HeatAcclimationSettingsStore().load();
      expect(settings.locationMode, HeatLocationMode.none);
      expect(settings.fixedLatitude, 39.8);
      expect(
        await container.read(heatPreferredLocationProvider.future),
        isNull,
      );
      expect(await container.read(heatHourlyWeatherProvider.future), isNull);
      expect(container.read(weatherLocationEnabledProvider), isFalse);
    },
  );
  test('current location switches back to automatic rather than saving a fixed fix', () async {
    final container = ProviderContainer(
      overrides: [locationServiceProvider.overrideWithValue(_Location())],
    );
    addTearDown(container.dispose);
    await container.read(heatAcclimationSettingsProvider.future);
    final actions = container.read(weatherLocationActionsProvider);
    await actions.saveFixed('39,8', '3,1');
    await actions.useCurrent();
    final saved = await const HeatAcclimationSettingsStore().load();
    expect(saved.locationMode, HeatLocationMode.current);
    expect(saved.fixedLatitude, 39.8);
    expect(() => actions.saveFixed('91', '3'), throwsArgumentError);
  });
}
