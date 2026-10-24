import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/heart_rate.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/widgets/hr_timeline_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('only absolute timestamps establish a timed HR sample', () {
    final samples = parseTimedHeartRates([
      {'hr': 47},
      {'timestamp': '2026-10-20', 'hr': 50},
      {'t': 3600, 'hr': 100},
      {'timestamp': '2026-10-20T08:00:00Z', 'hr': 52},
      [1792483260000, 53],
      [1792483320, 54],
      [1792483320, null],
    ], 'polar');
    expect(samples.map((s) => s.bpm), [52, 53, 54]);
    expect(samples.every((s) => s.source == 'polar'), isTrue);
  });

  test('multi-device HR persists, deduplicates and supplies timeline without Health permission', () async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    final day = DateTime(2026, 10, 20);
    await db.saveHeartRateSamples([
      TimedHeartRate(DateTime(2026, 10, 20, 8), 59, 'garmin_api'),
      TimedHeartRate(DateTime(2026, 10, 20, 9), 55, 'suunto'),
      TimedHeartRate(DateTime(2026, 10, 20, 10), 53, 'polar'),
    ]);
    // Re-syncing an identical source/timestamp updates rather than duplicates it.
    await db.saveHeartRateSamples([
      TimedHeartRate(DateTime(2026, 10, 20, 9), 56, 'suunto'),
    ]);
    await db.insertBpMeasurements([
      BpMeasurementsCompanion.insert(
        measuredAt: DateTime(2026, 10, 20, 7),
        systolic: 122,
        diastolic: 66,
        heartRate: 52,
      ),
    ]);
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'timed',
            name: 'Timed ride',
            type: 'cycling',
            startDate: DateTime(2026, 10, 20, 11),
            durationSeconds: 3600,
            metricsJson: Value(
              jsonEncode([
                {
                  'd': 100,
                  'hr': 140,
                  't': DateTime(2026, 10, 20, 11, 5).millisecondsSinceEpoch,
                },
                {
                  'd': 200,
                  'hr': 150,
                }, // This sample has no recorded time: never interpolate.
              ]),
            ),
          ),
        );
    final points = await container.read(heartTimelineProvider(day).future);
    expect(points.map((p) => p.value), [52, 59, 56, 53, 140]);
    expect(points.last.at, DateTime(2026, 10, 20, 11, 5));
    expect(
      (await db.getHeartRateSamples(day, DateTime(2026, 10, 21))).length,
      3,
    );
    container.dispose();
    await db.close();
  });
}
