import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/providers/metric_history_provider.dart';
import 'package:fjelia/widgets/app_widgets.dart';
import 'package:fjelia/widgets/hrv_combined_card.dart';
import 'package:fjelia/widgets/metric_detail_sheet.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  final start = DateTime(2026, 10, 10);

  Future<void> spot(
    String context,
    int day,
    double rmssd, {
    int hour = 8,
    int minute = 0,
    String posture = 'seated',
  }) => db
      .into(db.spotHrvMeasurements)
      .insert(
        SpotHrvMeasurementsCompanion.insert(
          startedAt: start.add(
            Duration(days: day, hours: hour, minutes: minute),
          ),
          context: context,
          posture: posture,
          durationSeconds: 300,
          settleSeconds: 60,
          deviceId: 'h10',
          deviceName: 'Polar H10',
          rmssdMs: rmssd,
          sdnnMs: rmssd + 5,
          meanHr: 60,
          acceptedIntervals: 280,
          totalIntervals: 290,
          coverage: .97,
          rrJson: '[]',
        ),
      );

  Future<void> show(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 24)),
          metricHistoryProvider.overrideWith(
            (ref, metric) async => [
              for (var d = 0; d < 14; d++)
                ChartPoint(DateTime(2026, 10, 11 + d), 40.0 + d % 5),
            ],
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    // The HRV pairing reads and writes the database in real asynchronous work.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets(
    'shows a tile per series, one chart and the training difference',
    (tester) async {
      // One ride with its own before and after reading.
      await spot('beforeTraining', 2, 60);
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'ride',
              name: 'Ride',
              type: 'cycling',
              startDate: start.add(const Duration(days: 2, hours: 9)),
              durationSeconds: 3600,
              source: const Value('garmin_api'),
            ),
          );
      await spot('afterTraining', 2, 45, hour: 10, minute: 31);
      await show(
        tester,
        HrvCombinedCard(
          start: start,
          end: start.add(const Duration(days: 14)),
          sleepPoints: [
            for (var d = 0; d < 10; d++)
              ChartPoint(start.add(Duration(days: d)), 40.0 + d),
          ],
          average: 44,
          averageLabel: '14D avg',
        ),
      );

      for (final label in [
        'Sleep',
        'Before training',
        'After training',
        'Resting',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      // Chart axes also show numbers, so look inside the tiles.
      Finder inTile(String label, String text) => find.descendant(
        of: find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
        matching: find.text(text),
      );
      expect(inTile('Before training', '60'), findsOneWidget);
      expect(inTile('After training', '45'), findsOneWidget);
      expect(find.text('10 readings'), findsOneWidget);
      expect(find.text('No readings'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      // The change is the pair of one workout, not two averages.
      expect(
        find.textContaining('1 comparable workout pair · median change −15 ms'),
        findsOneWidget,
      );
      expect(find.textContaining('vs before training'), findsNothing);
      expect(find.text('Measure with Polar H10'), findsOneWidget);

      // A tile switches its series off and on again.
      await tester.tap(find.text('Before training'));
      await tester.pump();
      // With a series hidden the comparison goes with it.
      expect(find.textContaining('comparable workout pair'), findsNothing);
      expect(find.byType(LineChart), findsOneWidget);
      await close(tester);
    },
  );

  testWidgets('without readings it says so and still offers a measurement', (
    tester,
  ) async {
    await show(
      tester,
      HrvCombinedCard(
        start: start,
        end: start.add(const Duration(days: 14)),
        sleepPoints: const [],
      ),
    );
    expect(find.text('No HRV readings in this period'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
    expect(find.text('Measure with Polar H10'), findsOneWidget);
    await close(tester);
  });

  testWidgets('seated is the default and lying readings are not averaged in', (
    tester,
  ) async {
    await spot('resting', 1, 50);
    await spot('resting', 3, 80, posture: 'supine');
    await show(
      tester,
      HrvCombinedCard(
        start: start,
        end: start.add(const Duration(days: 14)),
        sleepPoints: const [],
      ),
    );
    Finder inTile(String label, String text) => find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
      matching: find.text(text),
    );
    // Default: seated only, so the average is that of the seated reading.
    expect(inTile('Resting', '50'), findsOneWidget);
    expect(find.text('1 reading'), findsOneWidget);

    await tester.tap(find.text('Both'));
    await tester.pump(const Duration(milliseconds: 300));
    // Both are listed, but two positions are not one average.
    expect(find.text('2 readings · mixed positions'), findsOneWidget);
    expect(inTile('Resting', '—'), findsOneWidget);
    expect(inTile('Resting', '65'), findsNothing);
    await close(tester);
  });

  testWidgets('HRV-T083 the paired summary follows the posture filter', (
    tester,
  ) async {
    await spot('beforeTraining', 2, 60);
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'ride',
            name: 'Ride',
            type: 'cycling',
            startDate: start.add(const Duration(days: 2, hours: 9)),
            durationSeconds: 3600,
            source: const Value('garmin_api'),
          ),
        );
    await spot('afterTraining', 2, 45, hour: 10, minute: 31);
    await show(
      tester,
      HrvCombinedCard(
        start: start,
        end: start.add(const Duration(days: 14)),
        sleepPoints: const [],
      ),
    );
    expect(find.textContaining('1 comparable workout pair'), findsOneWidget);

    // Lying down: this ride has no lying pair, so nothing is claimed for it.
    await tester.tap(find.text('Lying down'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('comparable workout pair'), findsNothing);
    expect(
      find.text(
        'No workout in this period has a comparable before and after pair.',
      ),
      findsOneWidget,
    );
    await close(tester);
  });

  testWidgets('HRV-T034 unpaired readings never make a workout summary', (
    tester,
  ) async {
    // Before and after readings on different days, with no workout at all.
    await spot('beforeTraining', 2, 60);
    await spot('afterTraining', 5, 20);
    await show(
      tester,
      HrvCombinedCard(
        start: start,
        end: start.add(const Duration(days: 14)),
        sleepPoints: const [],
      ),
    );
    expect(find.textContaining('comparable workout pair'), findsNothing);
    expect(find.textContaining('−40'), findsNothing);
    await close(tester);
  });

  testWidgets('the HRV sheet has one chart, other metrics keep theirs', (
    tester,
  ) async {
    await show(
      tester,
      const SizedBox(
        height: 900,
        child: MetricDetailSheet(metric: HealthMetric.hrv),
      ),
    );
    expect(find.byType(HrvCombinedCard), findsOneWidget);
    expect(find.byType(HistoryChart), findsNothing);
    expect(find.byType(LineChart), findsOneWidget);
    await close(tester);

    await show(
      tester,
      const SizedBox(
        height: 900,
        child: MetricDetailSheet(metric: HealthMetric.rhr),
      ),
    );
    expect(find.byType(HrvCombinedCard), findsNothing);
    expect(find.byType(HistoryChart), findsOneWidget);
    await close(tester);
  });
}
