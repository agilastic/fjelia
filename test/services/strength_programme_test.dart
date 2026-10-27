import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/strength/strength_templates.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_providers/workout_providers.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

/// Device review: an ultra plan only ever got "Full Body Strength — Base",
/// and one strength session a week whatever the strength days.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late TrainingPlanService service;
  final clock = DateTime(2026, 10, 26, 9);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    service = TrainingPlanService(
      db,
      WorkoutProviders(const []),
      clock: () => clock,
    );
  });
  tearDown(() => db.close());

  Future<List<TrainingSession>> strength(String planId) =>
      (db.select(db.trainingSessions)
            ..where((t) => t.planId.equals(planId) & t.sport.equals('strength'))
            ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)]))
          .get();

  test('focus follows the race; programme templates are valid', () {
    expect(strengthFocusFor('trail_running'), StrengthFocus.trail);
    expect(strengthFocusFor('running', hilly: true), StrengthFocus.trail);
    expect(strengthFocusFor('running'), StrengthFocus.run);
    expect(strengthFocusFor('cycling_gravel'), StrengthFocus.bike);
    expect(strengthFocusFor('swimming'), StrengthFocus.full);
    expect(strengthProgrammeTemplates.length, 4 * 4 * 2);
    for (final t in strengthProgrammeTemplates) {
      final plan = t.build();
      expect(plan.validate(), isEmpty, reason: t.id);
      expect(
        plan.exercises.every((e) => e.sets.every((s) => s.load == null)),
        isTrue,
      );
    }
  });

  test('every programme template has its library entry', () async {
    final rows = await (db.select(
      db.workoutTemplates,
    )..where((t) => t.sport.equals('strength'))).get();
    for (final t in strengthProgrammeTemplates) {
      final row = rows.singleWhere((r) => r.subType == t.id);
      expect(row.description, t.legacyDescription);
      expect(row.targetPhase, t.phase);
      expect(row.name, t.name);
    }
  });

  test('A and B vary; build is heavier than base', () {
    // A and B differ in their exercises; equipment includes machines.
    final a = strengthProgrammeTemplates
        .firstWhere((t) => t.id == 'str-trail-base-a')
        .build();
    final b = strengthProgrammeTemplates
        .firstWhere((t) => t.id == 'str-trail-base-b')
        .build();
    expect(
      a.exercises.map((e) => e.variantId).toSet(),
      isNot(b.exercises.map((e) => e.variantId).toSet()),
    );
    final bike = strengthProgrammeTemplates
        .firstWhere((t) => t.id == 'str-bike-base-a')
        .build();
    expect(bike.exercises.map((e) => e.equipment), contains('Machine'));
    // Build is heavier and fewer reps than base.
    final build = strengthProgrammeTemplates
        .firstWhere((t) => t.id == 'str-trail-build-a')
        .build();
    expect(a.exercises.first.sets.first.repBounds, (10, 12));
    expect(build.exercises.first.sets.first.repBounds, (4, 6));
    expect(build.exercises.first.sets.length, 4);
  });

  test(
    'an ultra trail plan uses every strength day with varied sessions',
    () async {
      final planId = await service.generatePlan(
        athleteId: 'self',
        raceDate: clock.add(const Duration(days: 7 * 30)),
        sport: 'trail_running',
        raceDistanceM: 80000,
        raceElevationM: 4000,
        daysPerWeek: 6,
        restDays: const [1],
        strengthDays: const [2, 5],
        hoursPerWeek: 10,
        gadSports: const ['trail_running'],
      );
      final sessions = await strength(planId);
      expect(sessions, isNotEmpty);
      final templates = {for (final s in sessions) s.subType};
      expect(
        templates.length,
        greaterThan(4),
        reason: 'more than one template',
      );
      expect(
        sessions
            .where((s) => s.subType!.startsWith('str-'))
            .every((s) => s.subType!.startsWith('str-trail-')),
        isTrue,
        reason: 'trail focus for a mountain ultra',
      );
      final byWeek = <int, List<TrainingSession>>{};
      for (final s in sessions) {
        byWeek.putIfAbsent(s.weekNumber, () => []).add(s);
      }
      for (final week in byWeek.values) {
        final phase = week.first.phase;
        final count = week.length;
        switch (phase) {
          case 'base' || 'build':
            // Both strength days are used, with A and B.
            if (count == 2) {
              expect(
                week.map((s) => s.subType).toSet().length,
                2,
                reason: 'A and B',
              );
            }
            expect(count, lessThanOrEqualTo(2));
          case 'taper' || 'recovery':
            expect(count, 1);
          case 'race':
            fail('no strength in race week');
        }
        for (final s in week) {
          expect([
            DateTime.tuesday,
            DateTime.friday,
          ], contains(s.sessionDate.weekday));
        }
      }
      expect(byWeek.values.where((w) => w.length == 2), isNotEmpty);
      // Every session opens as a structured plan.
      for (final s in sessions) {
        expect(
          bundledStrengthPlanFor(
            subType: s.subType,
            sessionNotes: s.sessionNotes,
          ),
          isNotNull,
          reason: s.subType,
        );
      }
    },
  );

  test('no strength days, no strength', () async {
    final planId = await service.generatePlan(
      athleteId: 'self',
      raceDate: clock.add(const Duration(days: 7 * 16)),
      sport: 'running',
      raceDistanceM: 21097,
      strengthDays: const [],
    );
    expect(await strength(planId), isEmpty);
  });
}
