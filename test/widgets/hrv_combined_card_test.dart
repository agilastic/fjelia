import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/chart_point.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/widgets/hrv_combined_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows sleep and spot readings and the training difference', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final start = DateTime(2026, 10, 10);
    Future<void> spot(String context, int day, double rmssd) => db
        .into(db.spotHrvMeasurements)
        .insert(
          SpotHrvMeasurementsCompanion.insert(
            startedAt: start.add(Duration(days: day, hours: 8)),
            context: context,
            posture: 'seated',
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
    await spot('beforeTraining', 2, 60);
    await spot('afterTraining', 2, 45);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HrvCombinedCard(
                start: start,
                end: start.add(const Duration(days: 14)),
                sleepPoints: [
                  for (var d = 0; d < 10; d++)
                    ChartPoint(start.add(Duration(days: d)), 40.0 + d),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('HRV · sleep and spot readings'), findsOneWidget);
    expect(find.textContaining('Before training: 60 ms (1)'), findsOneWidget);
    expect(find.textContaining('After training: 45 ms (1)'), findsOneWidget);
    expect(find.textContaining('−15 ms vs before training'), findsOneWidget);
    expect(find.text('Measure with Polar H10'), findsOneWidget);

    // Hiding a series keeps the others.
    await tester.tap(find.text('Sleep').first);
    await tester.pump();
    expect(find.textContaining('Before training: 60 ms'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('without readings it says so and still offers a measurement', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final start = DateTime(2026, 10, 10);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HrvCombinedCard(
                start: start,
                end: start.add(const Duration(days: 14)),
                sleepPoints: const [],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No HRV readings in this period'), findsOneWidget);
    expect(find.text('Measure with Polar H10'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
