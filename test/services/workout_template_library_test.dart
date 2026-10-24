import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

/// Total seconds of a Garmin step list (repeats expanded), or null when a step
/// is not time-based (e.g. swim distances).
int? seconds(List steps, [int mult = 1]) {
  var total = 0;
  for (final s in steps.cast<Map<String, dynamic>>()) {
    if (s['type'] == 'RepeatGroupDTO') {
      final inner = seconds(
        s['workoutSteps'] as List,
        mult * (s['numberOfIterations'] as int),
      );
      if (inner == null) return null;
      total += inner;
    } else if ((s['endCondition'] as Map)['conditionTypeKey'] == 'time') {
      total += (s['endConditionValue'] as int) * mult;
    } else {
      return null;
    }
  }
  return total;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
    'built-in library: unique names, valid steps, matching durations',
    () async {
      await WorkoutTemplateLibrary(db).reseed();
      final rows = await db.select(db.workoutTemplates).get();
      expect(rows.length, greaterThan(190));
      expect(rows.length, 200);
      // Names are unique within a sport (some sports share names).
      expect(
        rows.map((r) => '${r.sport}|${r.name}').toSet().length,
        rows.length,
      );
      expect(rows.every((r) => r.source == 'fjelia_builtin'), isTrue);

      final mismatched = <String>[];
      for (final r in rows) {
        final steps = jsonDecode(r.stepsJson) as List;
        expect(steps, isNotEmpty, reason: r.name);
        final secs = seconds(steps);
        if (secs != null && (secs / 60 - r.estimatedDurationMin).abs() > 1) {
          mismatched.add(
            '${r.sport}|${r.name}: duration ${r.estimatedDurationMin} min, '
            'steps ${(secs / 60).round()} min',
          );
        }
        expect(r.description.trim(), isNotEmpty);
        expect(r.coachingCues, isNotEmpty);
      }
      expect(mismatched, isEmpty);
    },
  );

  test(
    'converted cycling uses power, converted running uses heart-rate zones',
    () async {
      await WorkoutTemplateLibrary(db).reseed();
      final rows = await db.select(db.workoutTemplates).get();
      bool power(String json) => json.contains('"power.zone"');
      final cycling = rows.where(
        (r) => r.sport == 'cycling_road' && power(r.stepsJson),
      );
      expect(cycling.length, greaterThanOrEqualTo(30));
      for (final r in cycling) {
        expect(r.parameterizedFor, 'power', reason: r.name);
        expect(r.stepsJson, contains('zoneNumber'), reason: r.name);
      }
      final running = rows.where((r) => r.sport == 'running');
      expect(running.length, greaterThanOrEqualTo(60));
      expect(running.any((r) => power(r.stepsJson)), isFalse);
      // Every sport the planner schedules keeps a pool for each session type.
      for (final type in ['key', 'long', 'recovery']) {
        expect(
          rows.any((r) => r.sport == 'cycling_road' && r.sessionType == type),
          isTrue,
        );
        expect(
          rows.any((r) => r.sport == 'running' && r.sessionType == type),
          isTrue,
        );
      }
    },
  );

  group('planner resolves power templates', () {
    Future<List<Map<String, dynamic>>> cyclingSteps({int? ftp}) async {
      if (ftp != null) {
        await db
            .into(db.athleteThresholds)
            .insert(
              AthleteThresholdsCompanion.insert(
                athleteId: 'self',
                ftpWatts: Value(ftp),
              ),
            );
      }
      await WorkoutTemplateLibrary(db).seedIfEmpty();
      final service = TrainingPlanService(db, FakeWorkoutGarmin());
      final planId = await service.generatePlan(
        athleteId: 'self',
        raceDate: DateTime.now().add(const Duration(days: 12 * 7)),
        sport: 'cycling_road',
        raceDistanceM: 100000,
        hoursPerWeek: 8,
        athlete: const PlanAthleteProfile(sex: 'm', age: 40),
      );
      final sessions = await (db.select(
        db.trainingSessions,
      )..where((t) => t.planId.equals(planId) & t.stepsJson.isNotNull())).get();
      return [
        for (final s in sessions)
          for (final st in jsonDecode(s.stepsJson!) as List)
            ...(st['type'] == 'RepeatGroupDTO'
                ? (st['workoutSteps'] as List).cast<Map<String, dynamic>>()
                : [(st as Map).cast<String, dynamic>()]),
      ];
    }

    test('with an FTP: watts', () async {
      final steps = await cyclingSteps(ftp: 250);
      final power = steps.where(
        (s) => (s['targetType'] as Map)['workoutTargetTypeKey'] == 'power.zone',
      );
      expect(power, isNotEmpty);
      for (final s in power) {
        expect(s['targetValueOne'] as num, greaterThan(40));
        expect(s.containsKey('ftpFraction'), isFalse);
      }
    });

    test('without an FTP: heart-rate zone targets instead of watts', () async {
      final steps = await cyclingSteps();
      expect(
        steps.where(
          (s) =>
              (s['targetType'] as Map)['workoutTargetTypeKey'] == 'power.zone',
        ),
        isEmpty,
      );
      final hr = steps.where(
        (s) =>
            (s['targetType'] as Map)['workoutTargetTypeKey'] ==
            'heart.rate.zone',
      );
      expect(hr, isNotEmpty);
    });
  });
}
