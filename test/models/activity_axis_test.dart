import 'package:fjelia/models/activity_axis.dart';
import 'package:fjelia/models/garmin_data.dart';
import 'package:fjelia/providers/hr_zones_provider.dart';
import 'package:fjelia/widgets/activity_performance_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ActivitySample sample(double meters, {int? minute, double? hr}) =>
    ActivitySample(
      distanceMeters: meters,
      heartRate: hr,
      timestamp: minute == null
          ? null
          : DateTime.utc(2026, 10, 24, 7).add(Duration(minutes: minute)),
    );

void main() {
  group('activityAxisFor', () {
    test('samples that move along a distance use the distance axis', () {
      expect(
        activityAxisFor([sample(0), sample(500), sample(2500)]),
        ActivityAxis.distance,
      );
    });

    test('strength, yoga and indoor sessions use time', () {
      expect(
        activityAxisFor([sample(0), sample(0), sample(0)]),
        ActivityAxis.time,
      );
      expect(activityAxisFor([sample(0), sample(30)]), ActivityAxis.time);
      expect(activityAxisFor(const []), ActivityAxis.time);
    });
  });

  group('sampleMinutes', () {
    test('uses the recorded timestamps', () {
      final minutes = sampleMinutes([
        sample(0, minute: 0),
        sample(0, minute: 5),
        sample(0, minute: 12),
      ], const Duration(minutes: 99));
      expect(minutes, [0, 5, 12]);
    });

    test('spreads samples evenly over the duration without timestamps', () {
      final minutes = sampleMinutes([
        sample(0),
        sample(0),
        sample(0),
        sample(0),
        sample(0),
      ], const Duration(minutes: 40));
      expect(minutes, [0, 10, 20, 30, 40]);
    });

    test('a sample without a timestamp keeps the previous position', () {
      final minutes = sampleMinutes([
        sample(0, minute: 0),
        sample(0),
        sample(0, minute: 6),
      ], const Duration(minutes: 10));
      expect(minutes, [0, 0, 6]);
    });

    test('a single sample sits at the start', () {
      expect(sampleMinutes([sample(0)], const Duration(minutes: 30)), [0]);
      expect(sampleMinutes(const [], const Duration(minutes: 30)), isEmpty);
    });
  });

  test('axis labels and tick spacing', () {
    expect(formatAxisMinutes(15, 45), '15 min');
    expect(formatAxisMinutes(90, 150), '1:30');
    expect(formatAxisMinutes(0, 150), '0:00');
    expect(niceMinuteInterval(45), 10);
    expect(niceMinuteInterval(30), 5);
    expect(niceMinuteInterval(150), 30);
    expect(niceMinuteInterval(3), 1);
    expect(niceMinuteInterval(2000), 180);
  });

  group('ActivityPerformanceChart', () {
    GarminActivity activity(List<ActivitySample> samples, {String? type}) =>
        GarminActivity(
          id: 'a',
          name: 'Session',
          type: type ?? 'strength_training',
          startTime: DateTime.utc(2026, 10, 24, 7),
          duration: const Duration(minutes: 45),
          samples: samples,
        );

    Future<void> pump(WidgetTester tester, GarminActivity a) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [hrZonesProvider.overrideWith((ref) => HrZonesNotifier())],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ActivityPerformanceChart(activity: a),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('a session without distance is plotted over time', (
      tester,
    ) async {
      await pump(
        tester,
        activity([
          for (var i = 0; i <= 45; i += 5) sample(0, minute: i, hr: 90.0 + i),
        ]),
      );
      expect(find.text('PERFORMANCE / TIME'), findsOneWidget);
      expect(find.text('PERFORMANCE / DISTANCE'), findsNothing);
      final line = tester.widget<LineChart>(find.byType(LineChart).first);
      expect(line.data.maxX, 45);
      expect(find.textContaining(' km'), findsNothing);
      expect(find.text('10 min'), findsOneWidget);
    });

    testWidgets('a run keeps its distance axis', (tester) async {
      await pump(
        tester,
        activity([
          for (var i = 0; i <= 10; i++)
            sample(i * 500.0, minute: i * 4, hr: 140),
        ], type: 'running'),
      );
      expect(find.text('PERFORMANCE / DISTANCE'), findsOneWidget);
      final line = tester.widget<LineChart>(find.byType(LineChart).first);
      expect(line.data.maxX, 5);
      expect(find.textContaining(' km'), findsWidgets);
    });
  });
}
