import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/workout_nutrition.dart';
import 'package:fjelia/services/ai_context_toon_builder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Issue #8: swimming gets what a swimmer can actually use.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  NutritionWorkout swim(
    double minutes, {
    int? zone,
    String sport = 'swimming',
  }) => NutritionWorkout(
    key: 'plan:s',
    title: 'Swim',
    sport: sport,
    date: DateTime(2026, 11, 6),
    minutes: minutes,
    zone: zone,
  );
  const pool = NutritionConditions(surface: 'Pool');
  NutritionStrategy plan(
    NutritionWorkout w, [
    NutritionConditions c = pool,
    NutritionPreferences p = const NutritionPreferences(),
  ]) => planNutrition(w, p, c);
  String notes(NutritionStrategy s) => s.guidance.join(' ');

  test('1 short pool swim: water, no gels, two lines', () {
    final s = plan(swim(45, zone: 4));
    expect(s.carbs, 0);
    expect(s.gels, 0);
    expect(s.gelsPractical, isFalse);
    expect(notes(s), contains('No energy gels needed'));
    expect(s.guidance, hasLength(2));
  });

  test('2 moderate pool swim under 90 min: still no carbohydrate', () {
    final s = plan(swim(80, zone: 4));
    expect(s.carbs, 0);
    expect(s.gels, 0);
    expect(notes(s), contains('Before:'));
  });

  test('3 long intensive pool swim: a drink at set breaks, no gels', () {
    final s = plan(swim(110, zone: 4));
    expect(s.carbLow, 30);
    expect(s.carbHigh, 60);
    expect(s.carbs, 45);
    expect(s.gels, 0);
    expect(notes(s), contains('carbohydrate-containing drink'));
    expect(notes(s), contains('Gels are not needed in the pool'));
  });

  test('4/6 long open-water swim with feeds: fuel at the feeds', () {
    final s = plan(
      swim(180, sport: 'swimming_open_water'),
      const NutritionConditions(surface: 'Open water', feeds: 'Supported'),
    );
    expect(s.carbs, greaterThan(0));
    expect(s.gels, 0);
    expect(notes(s), contains('feeding opportunities'));
    expect(notes(s), isNot(contains('Edit strategy')));
  });

  test('5 unsupported open-water swim: nothing during, fuel before', () {
    final s = plan(
      swim(150, sport: 'swimming_open_water'),
      const NutritionConditions(surface: 'Open water', feeds: 'Unsupported'),
    );
    expect(s.carbs, 0);
    expect(notes(s), contains('No feeds during an unsupported swim'));
  });

  test('feeds not known: the athlete is asked to set them', () {
    final s = plan(
      swim(150, sport: 'swimming_open_water'),
      const NutritionConditions(),
    );
    expect(notes(s), contains('Edit strategy'));
  });

  test('7 without an intensity the length decides', () {
    expect(plan(swim(100)).carbs, 45);
    expect(plan(swim(60)).carbs, 0);
  });

  test('8 without a duration nothing is made up', () {
    final s = plan(swim(0));
    expect(s.carbs, 0);
    expect(s.totalFluid, 0);
    expect(notes(s), contains('No planned duration'));
  });

  test('9 preferences: trained gut limit and drink mix count', () {
    final s = plan(
      swim(120, zone: 3),
      pool,
      const NutritionPreferences(trainedCarbs: 30, drinkCarbs: 30),
    );
    expect(s.carbHigh, 30);
    expect(s.drinkCarbs, greaterThan(0));
    expect(s.gels, 0);
  });

  test('10 environment: air heat does not change a pool swim, open water '
      'says the water temperature is unknown', () {
    final hot = plan(
      swim(100),
      const NutritionConditions(surface: 'Pool', temperature: 34),
    );
    expect(hot.fluid, plan(swim(100)).fluid);
    final open = plan(
      swim(100, sport: 'swimming_open_water'),
      const NutritionConditions(
        surface: 'Open water',
        temperature: 26,
        feeds: 'Supported',
      ),
    );
    expect(notes(open), contains('water temperature'));
  });

  test('12 running and cycling are unchanged', () {
    for (final sport in ['running', 'cycling_road']) {
      final s = planNutrition(
        NutritionWorkout(
          key: 'plan:r',
          title: 'Long',
          sport: sport,
          date: DateTime(2026, 11, 6),
          minutes: 120,
          zone: 2,
        ),
        const NutritionPreferences(),
        const NutritionConditions(temperature: 15),
      );
      expect(s.gelsPractical, isTrue);
      expect((s.carbLow, s.carbHigh), (30, 60));
      expect(s.gels, greaterThan(0));
    }
    // A short hard run keeps its small carbohydrate range.
    final hard = planNutrition(
      NutritionWorkout(
        key: 'plan:h',
        title: 'Intervals',
        sport: 'running',
        date: DateTime(2026, 11, 6),
        minutes: 60,
        zone: 4,
      ),
      const NutritionPreferences(),
      const NutritionConditions(temperature: 15),
    );
    expect((hard.carbLow, hard.carbHigh), (15, 30));
  });

  test('11 the coach gets the same plan as the app', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await db
        .into(db.trainingPlans)
        .insert(
          TrainingPlansCompanion.insert(
            id: 'p',
            athleteId: 'self',
            startDate: today,
            endDate: today.add(const Duration(days: 60)),
            status: 'active',
            generatedAt: today,
          ),
        );
    for (final (id, minutes) in [('short', 45), ('long', 110)]) {
      await db
          .into(db.trainingSessions)
          .insert(
            TrainingSessionsCompanion.insert(
              id: id,
              planId: 'p',
              athleteId: 'self',
              sessionDate: today.add(Duration(days: minutes == 45 ? 1 : 2)),
              sessionNumber: 1,
              weekNumber: 1,
              sport: 'swimming',
              sessionType: 'key',
              phase: 'base',
              primaryZone: 4,
              title: 'Swim $id',
              plannedDurationMin: minutes,
              plannedTrimp: 50,
              sessionLevel: 4,
            ),
          );
    }
    final text = await AiContextToonBuilder(db).build(null, '', null);
    expect(
      text,
      contains(
        'Dur:45m,TRIMP:50,Fuel:CarbsGh:0,FluidMlH:500,Gels:no,Swim:pool',
      ),
    );
    expect(text, contains('Dur:110m,TRIMP:50,Fuel:CarbsGh:45,'));
    expect(RegExp(r'Swim:pool.*Gels:[1-9]').hasMatch(text), isFalse);
  });
}
