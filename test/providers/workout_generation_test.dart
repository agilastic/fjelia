import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/planner_providers.dart';
import 'package:fjelia/providers/workout_generation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late ProviderContainer container;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'user_profile_v1': jsonEncode({
        'trainingDaysPerWeek': 6,
        'hoursPerWeek': 12.0,
        'restDays': [7],
        'preferredStrengthDays': [2],
        'maxSessionsPerDay': 2,
        'preferredSports': ['running', 'swimming', 'cycling_road'],
      }),
    });
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });
  test('generation requires an A goal before changing plans', () async {
    await expectLater(
      container.read(workoutGenerationProvider.notifier).generate(),
      throwsStateError,
    );
    expect(await db.select(db.trainingPlans).get(), isEmpty);
    expect(container.read(workoutGenerationProvider).hasError, isTrue);
  });
  test(
    'race goal generates named sessions and regeneration replaces future sessions',
    () async {
      final date = DateTime.now().add(const Duration(days: 42));
      await container
          .read(raceGoalServiceProvider)
          .create(
            name: 'Target race',
            primarySport: 'running',
            distanceM: 42195,
            raceDate: date,
            priority: 'a',
          );
      final job = container.read(workoutGenerationProvider.notifier);
      final count = await job.generate();
      expect(count, greaterThan(0));
      final first = await db.select(db.trainingSessions).get();
      expect(first.any((s) => s.stepsJson != null), isTrue);
      expect(first.any((s) => s.title != 'running'), isTrue);
      expect(first.every((s) => s.sessionDate.weekday != 7), isTrue);
      expect(first.every((s) => s.sessionDate.hour == 0), isTrue);
      final done = first.first;
      await (db.update(db.trainingSessions)..where((t) => t.id.equals(done.id)))
          .write(const TrainingSessionsCompanion(status: Value('completed')));
      final secondCount = await job.generate();
      expect(secondCount, count);
      expect((await db.select(db.trainingPlans).get()).length, 1);
      final second = await db.select(db.trainingSessions).get();
      expect(second.length, count! + 1);
      expect(second.singleWhere((s) => s.id == done.id).status, 'completed');
      expect(
        (await container.read(upcomingSessionsProvider.future)).length,
        secondCount,
      );
    },
  );
}
