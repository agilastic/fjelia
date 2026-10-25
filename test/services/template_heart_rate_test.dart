import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

Iterable<Map<String, dynamic>> leaves(List steps) sync* {
  for (final s in steps.cast<Map<String, dynamic>>()) {
    if (s['workoutSteps'] is List) {
      yield* leaves(s['workoutSteps'] as List);
    } else {
      yield s;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.athleteThresholds)
        .insert(
          AthleteThresholdsCompanion.insert(
            athleteId: 'self',
            lastUpdatedAt: Value(DateTime(2026, 10, 1)),
            ftpWatts: const Value(264),
            maxHrBpm: const Value(183),
            runHrZonesJson: const Value('[92,110,128,146,165]'),
            bikeHrZonesJson: const Value('[100,118,134,148,162]'),
            swimHrZonesJson: const Value('[90,108,126,144,162]'),
          ),
          mode: InsertMode.insertOrReplace,
        );
    await WorkoutTemplateLibrary(db).seedIfEmpty();
  });
  tearDown(() => db.close());

  test(
    'every step of every built-in template names a zone, with its heart rates',
    () async {
      final service = TrainingPlanService(
        db,
        garminProviders(db, FakeWorkoutGarmin()),
      );
      final templates = await db.select(db.workoutTemplates).get();
      expect(templates, isNotEmpty);
      final problems = <String>[];
      for (final t in templates) {
        final resolved = leaves(
          jsonDecode(
                await service.resolveTemplateSteps(t.stepsJson, sport: t.sport),
              )
              as List,
        );
        var i = 0;
        for (final step in resolved) {
          i++;
          final zone = step['zoneNumber'];
          final key = (step['targetType'] as Map?)?['workoutTargetTypeKey'];
          final ok =
              zone is int &&
              zone >= 1 &&
              zone <= 5 &&
              key == 'heart.rate.zone' &&
              step['targetValueOne'] != null &&
              step['targetValueTwo'] != null;
          if (!ok) {
            problems.add('${t.sport} · ${t.name} · step $i: zone $zone, $key');
          }
        }
      }
      expect(problems, isEmpty, reason: problems.take(10).join('\n'));
    },
  );

  test('a swim written by distance carries its zones', () async {
    final t = await (db.select(
      db.workoutTemplates,
    )..where((x) => x.name.equals('CSS Threshold Set 10×100m'))).getSingle();
    final steps = leaves(jsonDecode(t.stepsJson) as List).toList();
    // Warm-up in zone 2, the 100s at CSS in zone 4, the rests and the
    // cool-down in zone 1.
    expect(steps.map((s) => s['zoneNumber']), [2, 4, 1, 1]);
    expect(steps.map((s) => s['endCondition']['conditionTypeKey']), [
      'time',
      'distance',
      'time',
      'time',
    ]);
    final mixed =
        await (db.select(db.workoutTemplates)..where(
              (x) =>
                  x.name.equals('Swim Tempo 500m Z3 + Z2') &
                  x.sport.equals('swimming'),
            ))
            .getSingle();
    final zones = leaves(
      jsonDecode(mixed.stepsJson) as List,
    ).map((s) => s['zoneNumber']).toList();
    // 500 m in zone 3, then 1000 m in zone 2, as the name says.
    expect(zones, [2, 3, 2, 1]);
  });

  test('a stored template that an older version wrote is replaced', () async {
    final stale = await (db.select(
      db.workoutTemplates,
    )..where((x) => x.name.equals('Long Swim 2000m Z2'))).getSingle();
    // As it was stored before the zones were added: same name, steps without.
    final old = (jsonDecode(stale.stepsJson) as List)
        .cast<Map<String, dynamic>>()
        .map(
          (s) => {
            for (final e in s.entries)
              if (e.key != 'zoneNumber') e.key: e.value,
          },
        )
        .toList();
    await (db.update(db.workoutTemplates)..where((x) => x.id.equals(stale.id)))
        .write(WorkoutTemplatesCompanion(stepsJson: Value(jsonEncode(old))));
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    final fresh = await (db.select(
      db.workoutTemplates,
    )..where((x) => x.name.equals('Long Swim 2000m Z2'))).getSingle();
    expect(
      leaves(
        jsonDecode(fresh.stepsJson) as List,
      ).every((s) => s['zoneNumber'] != null),
      isTrue,
    );
    // And an unchanged library is left alone: the same rows stay.
    final ids = (await db.select(db.workoutTemplates).get())
        .map((t) => t.id)
        .toSet();
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    expect(
      (await db.select(db.workoutTemplates).get()).map((t) => t.id).toSet(),
      ids,
    );
  });
}
