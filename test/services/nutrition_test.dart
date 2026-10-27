import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/workout_nutrition.dart';
import 'package:fjelia/services/nutrition_service.dart';
import 'package:flutter_test/flutter_test.dart';

NutritionWorkout workout({
  String sport = 'running',
  double minutes = 180,
  int zone = 2,
}) => NutritionWorkout(
  key: 'plan:session',
  title: 'Long session',
  sport: sport,
  date: DateTime(2026, 10, 28),
  minutes: minutes,
  zone: zone,
);

void main() {
  test('drink carbohydrate is subtracted before calculating extra gels', () {
    final plan = planNutrition(
      workout(minutes: 120),
      const NutritionPreferences(drinkCarbs: 30),
      const NutritionConditions(),
      carbs: 60,
      fluid: 500,
    );
    expect(plan.totalCarbs, 120);
    expect(plan.drinkCarbs, 60);
    expect(plan.gels, 3); // 60 g remaining, three 25 g gels to carry.
    expect(plan.bottles, 2);
  });
  test('short easy training does not become a mandatory gel schedule', () {
    final plan = planNutrition(
      workout(minutes: 40),
      const NutritionPreferences(),
      const NutritionConditions(),
    );
    expect(plan.carbs, 0);
    expect(plan.gels, 0);
    expect(plan.sodium, 0);
  });
  test(
    'trained tolerance caps recommendations and measured sweat wins over heat',
    () {
      final plan = planNutrition(
        workout(),
        const NutritionPreferences(
          trainedCarbs: 40,
          sweatMl: 600,
          sweatSodium: 900,
        ),
        const NutritionConditions(temperature: 32, humidity: 85),
      );
      expect(plan.carbs, 40);
      expect(plan.fluid, 480);
      expect(plan.sodium, closeTo(432, .01));
    },
  );
  test(
    'warm conditions change fluids, not an invented carbohydrate multiplier',
    () {
      final cool = planNutrition(
        workout(),
        const NutritionPreferences(),
        const NutritionConditions(temperature: 12),
      );
      final hot = planNutrition(
        workout(),
        const NutritionPreferences(),
        const NutritionConditions(temperature: 30),
      );
      expect(hot.carbs, cool.carbs);
      expect(hot.fluid, greaterThan(cool.fluid));
    },
  );
  test(
    'sport logistics distinguish pool, supported swimming, MTB and skiing',
    () {
      for (final pair in [
        ('swimming_pool', 'pool deck'),
        ('swimming_open_water', 'supported feeds'),
        ('cycling_mtb', 'technical descents'),
        ('nordic_skiing', 'insulated'),
        ('skate_skiing', 'gloves'),
        ('trail_running', 'aid stations'),
        ('cycling_road', 'refill'),
      ]) {
        final plan = planNutrition(
          workout(sport: pair.$1),
          const NutritionPreferences(),
          const NutritionConditions(),
        );
        expect(plan.guidance.join(' '), contains(pair.$2));
      }
      final pool = planNutrition(
        workout(sport: 'swimming_pool'),
        const NutritionPreferences(),
        const NutritionConditions(temperature: 35, surface: 'Pool'),
      );
      expect(pool.fluid, 500);
      final openWater = planNutrition(
        workout(sport: 'swimming_open_water'),
        const NutritionPreferences(),
        const NutritionConditions(temperature: 35, humidity: 80),
      );
      expect(openWater.fluid, 500);
      expect(openWater.guidance.join(' '), contains('water temperature'));
    },
  );
  test('technical terrain, climbing, altitude, UV and cold remain explicit guidance', () {
    final plan = planNutrition(
      workout(sport: 'trail_running'),
      const NutritionPreferences(),
      const NutritionConditions(
        temperature: -4,
        wind: 35,
        ascent: 900,
        altitude: 2400,
        uv: 7,
        surface: 'Technical',
      ),
    );
    expect(plan.guidance.join(' '), contains('time on feet'));
    expect(plan.guidance.join(' '), contains('altitude'));
    expect(plan.guidance.join(' '), contains('freezing'));
    expect(plan.guidance.join(' '), contains('Strong sun'));
  });
  group('storage', () {
    late AppDatabase db;
    late NutritionService service;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      service = NutritionService(db);
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'a',
              name: 'Run',
              type: 'running',
              startDate: DateTime(2026, 10, 28),
              durationSeconds: 7200,
            ),
          );
    });
    tearDown(() => db.close());
    test(
      'missing, explicit zero, drafts and completed intake survive reloads',
      () async {
        expect((await service.log('a')).finished, isFalse);
        await expectLater(
          service.saveLog('a', const NutritionLog(status: 'complete')),
          throwsArgumentError,
        );
        await service.saveLog(
          'a',
          const NutritionLog(status: 'complete', noIntake: true),
        );
        expect((await NutritionService(db).log('a')).noIntake, isTrue);
        const log = NutritionLog(
          status: 'complete',
          gut: 'Mild symptoms',
          elapsedMinutes: 150,
          entries: [
            NutritionEntry(
              name: 'Gel',
              quantity: 2,
              carbs: 30,
              unknown: ['sodium'],
            ),
            NutritionEntry(
              name: 'Drink',
              quantity: 1.5,
              carbs: 20,
              fluid: 500,
              sodium: 250,
            ),
            NutritionEntry(
              name: 'Recovery meal',
              phase: 'after',
              protein: 30,
              carbs: 80,
            ),
          ],
        );
        await service.saveLog('a', log);
        final saved = await NutritionService(db).log('a');
        expect(saved.total((e) => e.carbs, during: true), 90);
        expect(saved.total((e) => e.fluid, during: true), 750);
        expect(saved.total((e) => e.protein), 30);
        expect(saved.entries.first.unknown, ['sodium']);
        expect(saved.elapsedMinutes, 150);
        expect(saved.gut, 'Mild symptoms');
        expect(saved.finished, isTrue);
      },
    );
    test(
      'bad quantities and nonexistent activities cannot become records',
      () async {
        for (final quantity in [-1.0, double.nan, double.infinity, 0.0]) {
          await expectLater(
            service.saveLog(
              'a',
              NutritionLog(
                entries: [NutritionEntry(name: 'Gel', quantity: quantity)],
              ),
            ),
            throwsArgumentError,
          );
        }
        await expectLater(
          service.saveLog(
            'missing',
            const NutritionLog(noIntake: true, status: 'complete'),
          ),
          throwsStateError,
        );
      },
    );
    test('a stored strategy is a snapshot, not rewritten by preferences or weather', () async {
      final plan = planNutrition(
        workout(),
        const NutritionPreferences(),
        const NutritionConditions(temperature: 12),
      );
      await service.savePlan(plan);
      await service.savePreferences(
        const NutritionPreferences(trainedCarbs: 90),
      );
      final saved = (await service.savedPlan(workout().key))!;
      expect(saved.carbs, plan.carbs);
      expect(saved.preferences.trainedCarbs, 60);
      expect(saved.conditions.temperature, 12);
      expect(
        await service.planForActivity('a'),
        isNull,
      ); // No date-based guess.
    });
    test('sample timestamps include paused time, not just moving duration', () {
      final start = DateTime(2026, 10, 28, 10);
      final activity = ActivityRecord(
        id: 1,
        activityId: 'paused',
        name: 'Run',
        type: 'running',
        startDate: start,
        durationSeconds: 3600,
        movingDurationSeconds: 3000,
        metricsJson: jsonEncode([
          {'t': start.toIso8601String()},
          {'t': start.add(const Duration(minutes: 90)).toIso8601String()},
        ]),
      );
      expect(nutritionElapsedSeconds(activity), 5400);
    });
    test(
      'trusted session links survive retirement without a same-day guess',
      () async {
        await service.savePlan(
          planNutrition(
            workout(),
            const NutritionPreferences(),
            const NutritionConditions(),
          ),
        );
        await db
            .into(db.sessionActuals)
            .insert(
              SessionActualsCompanion.insert(
                sessionId: 'session',
                activityId: const Value('a'),
              ),
            );
        expect(
          (await service.planForActivity('a'))!.workout.key,
          workout().key,
        );
        await service.saveLog(
          'a',
          const NutritionLog(status: 'complete', noIntake: true),
        );
        await db.delete(db.sessionActuals).go();
        expect(
          (await service.planForActivity('a'))!.workout.key,
          workout().key,
        );
      },
    );
    test(
      'two same-day strategies require an explicit user choice when unlinked',
      () async {
        for (final id in ['one', 'two']) {
          final w = NutritionWorkout(
            key: 'garmin:$id',
            title: id,
            sport: 'cycling',
            date: DateTime(2026, 10, 28),
            minutes: 120,
          );
          await service.savePlan(
            planNutrition(
              w,
              const NutritionPreferences(),
              const NutritionConditions(),
            ),
          );
        }
        expect(
          await service.candidatePlans(DateTime(2026, 10, 28)),
          hasLength(2),
        );
        expect(await service.planForActivity('a'), isNull);
        await service.saveLog(
          'a',
          const NutritionLog(
            status: 'complete',
            noIntake: true,
            planKey: 'garmin:two',
          ),
        );
        expect((await service.planForActivity('a'))!.workout.key, 'garmin:two');
        await service.saveLog(
          'a',
          const NutritionLog(status: 'complete', noIntake: true, planKey: ''),
        );
        expect(await service.planForActivity('a'), isNull);
      },
    );
  });
}
