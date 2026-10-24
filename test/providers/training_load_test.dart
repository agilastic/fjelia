import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/providers/training_load_provider.dart';

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
