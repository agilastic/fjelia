import 'package:fjelia/services/blood_pressure_chart_data.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/screens/bloodpressure/bp_screen.dart';
import 'package:fjelia/screens/bloodpressure/bp_variation_chart.dart';

BpMeasurement reading(DateTime date, int sys, int dia) => BpMeasurement(
  id: sys,
  measuredAt: date,
  timezone: 'UTC',
  systolic: sys,
  diastolic: dia,
  heartRate: 60,
  measurementType: 'POD',
);

void main() {
  test('BP axis follows readings with rounded padding and a nonzero span', () {
    final normal = BpAxisRange.fromValues([75, 125]);
    expect(normal.minimum, 70);
    expect(normal.maximum, 130);
    final high = BpAxisRange.fromValues([110, 205]);
    expect(high.minimum, 100);
    expect(high.maximum, 220);
    final single = BpAxisRange.fromValues([80, 80]);
    expect(single.minimum, 70);
    expect(single.maximum, 90);
    expect(BpAxisRange.fromValues([]).maximum, 160);
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'hourly bars preserve both pressure ranges and averages; gaps stay empty',
    () {
      final start = DateTime(2026, 10, 19);
      final buckets = bpVariationBuckets(
        [
          reading(DateTime(2026, 10, 19, 8, 10), 110, 60),
          reading(DateTime(2026, 10, 19, 8, 50), 140, 80),
          reading(DateTime(2026, 10, 20), 200, 100),
        ],
        start,
        DateTime(2026, 10, 20),
        BpPeriod.day,
      );
      expect(buckets.length, 24);
      expect(buckets[8].minimum(true), 110);
      expect(buckets[8].maximum(true), 140);
      expect(buckets[8].average(true), 125);
      expect(buckets[8].minimum(false), 60);
      expect(buckets[8].maximum(false), 80);
      expect(buckets[8].average(false), 70);
      expect(buckets[9].readings, isEmpty);
      expect(buckets.fold<int>(0, (sum, b) => sum + b.readings.length), 2);
    },
  );

  test('calendar month includes leap day and excludes next month', () {
    final buckets = bpVariationBuckets(
      [
        reading(DateTime(2024, 2, 29, 23), 120, 70),
        reading(DateTime(2024, 3, 1), 130, 80),
      ],
      DateTime(2024, 2),
      DateTime(2024, 3),
      BpPeriod.month,
    );
    expect(buckets.length, 29);
    expect(buckets.last.readings.length, 1);
  });

  testWidgets('Day, Week and Month use hourly/daily bars and period averages', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    container.read(selectedDateProvider.notifier).state = DateTime(2026, 2, 10);
    await db.insertBpMeasurements([
      BpMeasurementsCompanion.insert(
        measuredAt: DateTime(2026, 2, 10, 8),
        systolic: 120,
        diastolic: 60,
        heartRate: 60,
      ),
      BpMeasurementsCompanion.insert(
        measuredAt: DateTime(2026, 2, 10, 9),
        systolic: 140,
        diastolic: 80,
        heartRate: 60,
      ),
      BpMeasurementsCompanion.insert(
        measuredAt: DateTime(2026, 2, 12, 8),
        systolic: 100,
        diastolic: 70,
        heartRate: 60,
      ),
    ]);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: BpScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('130/70'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('HOURLY VARIATION'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<BpVariationChart>(find.byType(BpVariationChart))
          .buckets
          .length,
      24,
    );
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.text('DAILY VARIATION'), findsOneWidget);
    expect(
      tester
          .widget<BpVariationChart>(find.byType(BpVariationChart))
          .buckets
          .length,
      7,
    );
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BpVariationChart>(find.byType(BpVariationChart))
          .buckets
          .length,
      28,
    );
    await tester.tap(find.byTooltip('Previous blood-pressure period'));
    await tester.pumpAndSettle();
    expect(find.text('January 2026'), findsOneWidget);
    expect(find.text('No measurements in this period'), findsOneWidget);
    await tester.tap(find.byTooltip('Next blood-pressure period'));
    await tester.pumpAndSettle();
    expect(find.text('February 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Fullscreen blood-pressure chart'));
    await tester.pumpAndSettle();
    expect(find.byType(BpChartFullscreen), findsOneWidget);
    final chart = find
        .descendant(
          of: find.byType(BpChartFullscreen),
          matching: find.byType(CustomPaint),
        )
        .last;
    final rect = tester.getRect(chart);
    // The default test viewport is already landscape.
    await tester.tapAt(
      Offset(
        rect.left + 34 + (rect.width - 42) * 9.5 / 28,
        rect.top + 8 + (150 - 130) / 100 * (rect.height - 36),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bp-chart-tooltip')), findsOneWidget);
    expect(find.text('SYS'), findsOneWidget);
    expect(find.text('DIA'), findsOneWidget);
    expect(find.text('120–140 mmHg'), findsOneWidget);
    await tester.tapAt(
      Offset(rect.left + 34 + (rect.width - 42) * 1.5 / 28, rect.top + 20),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bp-chart-tooltip')), findsNothing);
    await tester.tap(find.byTooltip('Close fullscreen blood-pressure chart'));
    await tester.pumpAndSettle();
    expect(find.byType(BpChartFullscreen), findsNothing);
    expect(find.text('February 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await db.close();
  });
}
