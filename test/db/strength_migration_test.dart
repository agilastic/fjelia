import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/strength_workout.dart';
import 'package:fjelia/services/strength/strength_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schema 51 gains strength storage; existing strength activities get no invented sets (STR-A24)', () async {
    final dir = await Directory.systemTemp.createTemp(
      'fjelia-strength-migration-',
    );
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final before = AppDatabase(NativeDatabase(file));
    for (final (id, type) in [
      ('gym', 'strength_training'),
      ('ride', 'cycling'),
    ]) {
      await before
          .into(before.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: id,
              name: 'Existing',
              type: type,
              startDate: DateTime(2026, 10, 20),
              durationSeconds: 3600,
              avgHeartRate: const Value(120),
            ),
          );
    }
    for (final table in const [
      'strength_exercise_variants',
      'strength_equipment_increments',
      'strength_plan_revisions',
      'strength_plan_heads',
      'strength_activity_logs',
      'strength_performed_exercises',
      'strength_performed_sets',
    ]) {
      await before.customStatement('DROP TABLE $table');
    }
    await before.customStatement('PRAGMA user_version = 51');
    await before.close();

    final after = AppDatabase(NativeDatabase(file));
    addTearDown(after.close);
    final rows = await after.select(after.activityRecords).get();
    expect(rows.map((r) => r.activityId).toSet(), {'gym', 'ride'});
    expect(rows.firstWhere((r) => r.activityId == 'gym').avgHeartRate, 120);
    expect(await StrengthRepository(after).loadLog('gym'), isNull);
    expect(await after.select(after.strengthPerformedSets).get(), isEmpty);
  });

  test('schema 52 gains proposal decisions and keeps strength logs', () async {
    final dir = await Directory.systemTemp.createTemp('fjelia-strength-53-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final before = AppDatabase(NativeDatabase(file));
    await before
        .into(before.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'gym',
            name: 'Gym',
            type: 'strength_training',
            startDate: DateTime(2026, 10, 20),
            durationSeconds: 3600,
          ),
        );
    await StrengthRepository(before).saveLog(
      StrengthActivityLog(
        activityId: 'gym',
        exercises: [
          StrengthPerformedExercise(
            id: 'e',
            variantId: 'bench_press',
            name: 'Bench press',
            equipment: 'Barbell',
            sets: const [
              StrengthSetResult(
                id: 's',
                status: StrengthSetStatus.completed,
                reps: 10,
                load: StrengthLoad(70),
              ),
            ],
          ),
        ],
      ),
    );
    await before.customStatement('DROP TABLE strength_proposal_decisions');
    await before.customStatement('PRAGMA user_version = 52');
    await before.close();
    final after = AppDatabase(NativeDatabase(file));
    addTearDown(after.close);
    expect(
      (await StrengthRepository(after).loadLog('gym'))!.sets.single.reps,
      10,
    );
    expect(await after.select(after.strengthProposalDecisions).get(), isEmpty);
  });
}
