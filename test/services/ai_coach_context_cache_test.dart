import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'new and changed race goals are visible before the one-hour cache expires',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final cache = container.read(toonCacheProvider.notifier);
      final before = await cache.getOrBuild(null, '', null);
      expect(before, isNot(contains('[RaceGoal:')));
      await db
          .into(db.raceGoals)
          .insert(
            RaceGoalsCompanion.insert(
              id: 'marathon',
              athleteId: 'self',
              name: 'Race',
              primarySport: 'running',
              source: 'manual',
              createdAt: DateTime.now(),
              distanceM: 42195,
              raceDate: DateTime.now().add(const Duration(days: 200)),
              priority: 'a',
            ),
          );
      final added = await cache.getOrBuild(null, '', null);
      expect(added, contains('[RaceGoal:'));
      expect(added, contains('Target:none'));
      await (db.update(db.raceGoals)..where((t) => t.id.equals('marathon')))
          .write(const RaceGoalsCompanion(targetFinishSeconds: Value(14400)));
      final updated = await cache.getOrBuild(null, '', null);
      expect(updated, contains('Target:4:00:00'));
      final profile = await cache.getOrBuild(null, 'A new profile goal', null);
      expect(profile, contains('[RaceGoals:A new profile goal]'));
    },
  );
}
