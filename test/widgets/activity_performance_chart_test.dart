import 'package:fjelia/l10n/app_localizations.dart';

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fjelia/models/garmin_data.dart';
import 'package:fjelia/theme/app_theme.dart';
import 'package:fjelia/widgets/activity_performance_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 7.5 km run at about 5:30 min/km with GPS jitter and four stops at
/// traffic lights, where the watch reports almost no speed.
GarminActivity run() {
  final samples = <ActivitySample>[];
  var distance = 0.0;
  final start = DateTime.utc(2026, 10, 24, 17);
  for (var i = 0; i < 2500; i++) {
    final stopped = [400, 900, 1600, 2200].any((s) => i >= s && i < s + 12);
    // Slow changes of pace, small GPS noise and an occasional jump.
    final jitter =
        math.sin(i / 160) * .35 +
        math.sin(i * 1.7) * .08 +
        (i % 97 == 0 ? -1.2 : 0);
    final speed = stopped ? .3 + (i % 3) * .1 : 3.05 + jitter;
    distance += speed;
    samples.add(
      ActivitySample(
        distanceMeters: distance,
        speed: speed,
        heartRate: 130 + math.sin(i / 50) * 15,
        elevation: 60 + math.sin(i / 300) * 5,
        timestamp: start.add(Duration(seconds: i)),
      ),
    );
  }
  return GarminActivity(
    id: 'run',
    name: 'Run',
    type: 'running',
    startTime: start,
    duration: const Duration(seconds: 2500),
    distanceMeters: distance,
    samples: samples,
  );
}

void main() {
  final output = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    if (output == null) return;
    final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
    if (font.existsSync()) {
      await (FontLoader('Roboto')..addFont(
            Future.value(ByteData.sublistView(await font.readAsBytes())),
          ))
          .load();
    }
  });

  testWidgets('stops do not stretch the pace axis; faster pace sits higher', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.dark(),
          home: Scaffold(
            backgroundColor: const Color(0xFF202020),
            body: SingleChildScrollView(
              child: RepaintBoundary(
                key: key,
                child: Material(
                  color: const Color(0xFF202020),
                  child: ActivityPerformanceChart(
                    activity: run(),
                    fullscreen: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final charts = tester
        .widgetList<LineChart>(find.byType(LineChart))
        .toList();
    expect(find.text('PACE (min/km)'), findsOneWidget);
    // Order: HR, pace, elevation.
    final pace = charts[1].data;
    // The axis is negated pace: -7 is 7:00 min/km. Stops (30+ min/km) do not
    // reach into it, and the running pace fills it.
    expect(pace.minY, greaterThan(-8));
    expect(pace.maxY, lessThan(-4));
    final spots = pace.lineBarsData.single.spots;
    // Each stop breaks the line once.
    expect(spots.where((s) => s.isNull()), hasLength(4));
    final values = [
      for (final s in spots)
        if (!s.isNull()) -s.y,
    ];
    expect(values.reduce(math.max), lessThan(15));
    expect(values.reduce(math.min), greaterThan(4));
    // Axis labels read as pace.
    expect(find.textContaining('′'), findsWidgets);

    if (output != null) {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File('$output/pace-chart.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });

  testWidgets('a ride shows speed without the stops at zero', (tester) async {
    final r = run();
    final ride = GarminActivity(
      id: 'ride',
      name: 'Ride',
      type: 'cycling',
      startTime: r.startTime,
      duration: r.duration,
      distanceMeters: r.distanceMeters,
      samples: r.samples,
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ActivityPerformanceChart(activity: ride),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('SPEED (km/h)'), findsOneWidget);
    final speed = tester
        .widgetList<LineChart>(find.byType(LineChart))
        .elementAt(1)
        .data;
    expect(speed.minY, greaterThan(5));
    expect(
      speed.lineBarsData.single.spots.where((s) => s.isNull()),
      hasLength(4),
    );
  });
}
