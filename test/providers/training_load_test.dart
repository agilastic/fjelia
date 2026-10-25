import 'dart:math' as math;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/providers/training_load_provider.dart';
import 'package:fjelia/providers/activity_history_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late ProviderContainer container;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  DateTime day(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + offset);
  }

  Future<void> addLoad(String id, DateTime date, double load) => db
      .into(db.activityRecords)
      .insert(
        ActivityRecordsCompanion.insert(
          activityId: id,
          name: 'Run',
          type: 'running',
          startDate: date,
          durationSeconds: 3600,
          trainingLoad: Value(load),
        ),
      )
      .then((_) {});

  test('chart and summary use all history and the same daily source', () async {
    await db.upsertScore(
      DayScoreRecordsCompanion(
        date: Value(day(-220)),
        strainScore: const Value(900),
      ),
    );
    await db.upsertScore(
      DayScoreRecordsCompanion(
        date: Value(day(-219)),
        strainScore: const Value(70),
      ),
    );
    await addLoad('old-am', day(-220), 20);
    await addLoad('old-pm', day(-220), 30);
    await addLoad('today', day(0), 80);
    final points = await container.read(trainingFormSeriesProvider.future);
    final metrics = await container.read(trainingLoadProvider.future);
    expect(points, hasLength(221));
    expect(points.first.date, day(-220));
    expect(points.first.load, 50); // Actual activities replace the stale cache.
    expect(points[1].load, 70); // Cache-only loads remain available.
    expect(points[2].load, 0); // A rest day is processed, not skipped.
    expect(points.last.load, 80);
    expect(metrics.ctl, points.last.ctl);
    expect(metrics.atl, points.last.atl);
    expect(metrics.tsb, points.last.tsb);
  });

  test('the first available activity is not cut off at ten years', () async {
    await addLoad('oldest', day(-4000), 100);
    final points = await container.read(trainingFormSeriesProvider.future);
    expect(points, hasLength(4001));
    expect(points.first.date, day(-4000));
    expect(points.last.date, day(0));
    expect(points.last.historyDays, 4001);
  });

  test(
    'summary projection retains zone, HR and elevation fallback inputs',
    () async {
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'zones',
              name: 'Zone-based run',
              type: 'running',
              startDate: day(0),
              durationSeconds: 3600,
              hrZonesJson: const Value('{"zone2":100}'),
              totalElevation: const Value(100),
            ),
          );
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'hr',
              name: 'HR-based run',
              type: 'running',
              startDate: day(0),
              durationSeconds: 3600,
              avgHeartRate: const Value(190),
            ),
          );
      final points = await container.read(trainingFormSeriesProvider.future);
      final expected = 60 * 1.1 + 100 / 10 + 60 * math.exp(1.92);
      expect(points.single.load, closeTo(expected, 1e-9));
      expect(points.single.atl, closeTo(expected / 4, 1e-9));
      expect(
        (await container.read(trainingLoadProvider.future)).atl,
        points.single.atl,
      );
    },
  );

  test('a recovery-only cache record does not create load history', () async {
    await db.upsertScore(
      DayScoreRecordsCompanion(
        date: Value(day(-300)),
        recoveryScore: const Value(60),
      ),
    );
    expect(await container.read(trainingFormSeriesProvider.future), isEmpty);
    expect((await container.read(trainingLoadProvider.future)).ctl, 0);
  });

  test(
    'future activities and cached loads do not affect current form',
    () async {
      await addLoad('today', day(0), 40);
      await addLoad('future', day(5), 3000);
      await db.upsertScore(
        DayScoreRecordsCompanion(
          date: Value(day(5)),
          strainScore: const Value(2000),
        ),
      );
      final points = await container.read(trainingFormSeriesProvider.future);
      final metrics = await container.read(trainingLoadProvider.future);
      expect(points, hasLength(1));
      expect(points.single.load, 40);
      expect(metrics.atl, 10);
      expect(metrics.peak, closeTo(44, 1e-10));
    },
  );

  test(
    'a full historical import rebuilds the baseline in both views',
    () async {
      await addLoad('today', day(0), 100);
      expect(
        await container.read(trainingFormSeriesProvider.future),
        hasLength(1),
      );
      await container.read(trainingLoadProvider.future);
      await addLoad('new-history', day(-200), 1000);
      container.read(fullSyncListenerProvider.notifier).state++;
      final points = await container.read(trainingFormSeriesProvider.future);
      final metrics = await container.read(trainingLoadProvider.future);
      expect(points.first.date, day(-200));
      expect(points, hasLength(201));
      expect(metrics.ctl, points.last.ctl);
      expect(metrics.atl, points.last.atl);
    },
  );

  test(
    'deleting the last activity clears its stale load cache and refreshes both views',
    () async {
      await addLoad('remove', day(-10), 1000);
      await addLoad('keep', day(0), 40);
      await db.upsertScore(
        DayScoreRecordsCompanion(
          date: Value(day(-10)),
          strainScore: const Value(900),
          recoveryScore: const Value(80),
          sleepScore: const Value(70),
        ),
      );
      await container.read(trainingFormSeriesProvider.future);
      await container.read(trainingLoadProvider.future);
      await container.read(deleteActivityProvider)('remove');
      final points = await container.read(trainingFormSeriesProvider.future);
      final metrics = await container.read(trainingLoadProvider.future);
      expect(points, hasLength(1));
      expect(points.single.historyStart, day(0));
      expect(metrics.atl, 10);
      expect(metrics.ctl, points.single.ctl);
      final cached = await db.getScoreForDate(day(-10));
      expect(cached?.strainScore, isNull);
      expect(cached?.recoveryScore, 80);
      expect(cached?.sleepScore, 70);
    },
  );

  test(
    'deleting one activity retains other activities in the daily cache',
    () async {
      await addLoad('remove', day(0), 1000);
      await addLoad('keep', day(0), 40);
      await db.upsertScore(
        DayScoreRecordsCompanion(
          date: Value(day(0)),
          strainScore: const Value(1040),
        ),
      );
      await container.read(deleteActivityProvider)('remove');
      expect((await db.getScoreForDate(day(0)))?.strainScore, 40);
      final points = await container.read(trainingFormSeriesProvider.future);
      expect(points.single.load, 40);
      expect((await container.read(trainingLoadProvider.future)).atl, 10);
    },
  );

  test(
    'activity history supplies baseline even when score cache contains zeros',
    () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (var i = 0; i < 42; i++) {
        final date = DateTime(today.year, today.month, today.day - i);
        await db
            .into(db.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: 'run-$i',
                name: 'Run',
                type: 'running',
                startDate: date,
                durationSeconds: 3600,
                trainingLoad: const Value(100),
                avgHeartRate: const Value(180),
              ),
            );
        await db.upsertScore(
          DayScoreRecordsCompanion(
            date: Value(date),
            strainScore: const Value(0),
          ),
        );
      }
      final metrics = await container.read(trainingLoadProvider.future);
      expect(metrics.ctl, greaterThan(80));
      expect(metrics.optimalHigh, greaterThan(metrics.optimalLow));
      final scores = await container.read(dayScoresProvider(today).future);
      // The recorded 100 must not become an inflated HR recalculation.
      expect(scores.strain.score, 100);
    },
  );

  test('empty history has no invented target', () async {
    final metrics = await container.read(trainingLoadProvider.future);
    expect(metrics.optimalLow, 0);
    expect(metrics.optimalHigh, 0);
  });

  test(
    'gauge scale accommodates loads above 250 without clamping the reading',
    () {
      expect(trainingLoadScale(796), 800);
      expect(trainingLoadScale(41, 300), 300);
      expect(trainingLoadScale(0), 250);
    },
  );
}
