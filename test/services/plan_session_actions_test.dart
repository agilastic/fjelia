import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/planned_workout_presentation.dart';
import 'package:fjelia/services/plan_session_actions.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_template_library.dart';
import '../support/fake_workout_garmin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late FakeWorkoutGarmin garmin;
  late TrainingSession session;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    garmin = FakeWorkoutGarmin();
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    final template = await (db.select(
      db.workoutTemplates,
    )..where((t) => t.name.equals('Aerobic Base Swim 4×500m Z2'))).getSingle();
    await db
        .into(db.trainingPlans)
        .insert(
          TrainingPlansCompanion.insert(
            id: 'plan',
            athleteId: 'self',
            startDate: DateTime(2026, 10, 19),
            endDate: DateTime(2027, 1, 1),
            status: 'active',
            generatedAt: DateTime(2026, 10, 19),
          ),
        );
    await db
        .into(db.trainingSessions)
        .insert(
          TrainingSessionsCompanion.insert(
            id: 'session',
            planId: 'plan',
            athleteId: 'self',
            sessionDate: DateTime(2026, 10, 25),
            sessionNumber: 1,
            weekNumber: 1,
            sport: 'swimming',
            sessionType: 'recovery',
            phase: 'base',
            primaryZone: 1,
            title: template.name,
            stepsJson: Value(template.stepsJson),
            sessionNotes: Value(template.description),
            mainSet: Value(template.coachingCues),
            plannedDurationMin: 40,
            plannedTrimp: 36,
            sessionLevel: 1,
          ),
        );
    session = (await db.select(db.trainingSessions).get()).single;
  });
  tearDown(() => db.close());
  test('distance swim structure renders repeats, meters and time recovery', () {
    final rows = plannedStepLines(session.stepsJson);
    expect(rows.map((r) => r.amount), [
      '250 m',
      '4× repeat',
      '500 m',
      '1 min',
      '250 m',
    ]);
    expect(rows[2].depth, 1);
    expect(rows[2].label, 'Interval');
    expect(rows[2].zone, isNull);
    expect(plannedStepLines('{broken'), isEmpty);
    expect(plannedZoneFractions(null, 1), [.70, .20, .05, .03, .02]);
    expect(plannedZoneFractions(null, 3), [.15, .25, .45, .10, .05]);
    expect(plannedZoneFractions('[20,20,20,20,20]', 1), [.2, .2, .2, .2, .2]);
  });
  test(
    'day shifts preserve calendar midnight and original date through DST',
    () async {
      final actions = PlanSessionActions(db, garmin);
      final next = await actions.moveDay(session, 1);
      expect(next.sessionDate, DateTime(2026, 10, 26));
      expect(next.weekNumber, 2);
      expect(next.sessionDateOriginal, session.sessionDate.toIso8601String());
      final previous = await actions.moveDay(next, -1);
      expect(previous.sessionDate, DateTime(2026, 10, 25));
      expect(previous.weekNumber, 1);
      expect(
        previous.sessionDateOriginal,
        session.sessionDate.toIso8601String(),
      );
    },
  );
  test(
    'repeated push reschedules the same Garmin workout after a move',
    () async {
      final plans = TrainingPlanService(db, garmin);
      await plans.pushToGarmin(session.id);
      session = (await db.select(db.trainingSessions).get()).single;
      await PlanSessionActions(db, garmin).moveDay(session, 1);
      await plans.pushToGarmin(session.id);
      expect(garmin.creates, 1);
      expect(garmin.dates.last, DateTime(2026, 10, 26));
      expect(garmin.removedSchedules, ['schedule-1']);
      final saved = (await db.select(db.trainingSessions).get()).single;
      expect(saved.garminWorkoutId, 'workout-1');
      expect(saved.garminAlternativeId, 'schedule-2');
    },
  );
  test(
    'rest unschedules the calendar entry and records a skipped workout',
    () async {
      await TrainingPlanService(db, garmin).pushToGarmin(session.id);
      session = (await db.select(db.trainingSessions).get()).single;
      final rest = await PlanSessionActions(db, garmin).markRest(session);
      expect(rest.status, 'skipped');
      expect(rest.garminAlternativeId, isNull);
      expect(garmin.removedSchedules, ['schedule-1']);
      expect(
        (await db.select(db.sessionActuals).get()).single.skipReason,
        'Marked as rest',
      );
      await expectLater(
        TrainingPlanService(db, garmin).pushToGarmin(rest.id),
        throwsStateError,
      );
    },
  );
  test('failed Garmin unscheduling leaves planned status unchanged', () async {
    await TrainingPlanService(db, garmin).pushToGarmin(session.id);
    session = (await db.select(db.trainingSessions).get()).single;
    garmin.failUnschedule = true;
    await expectLater(
      PlanSessionActions(db, garmin).markRest(session),
      throwsException,
    );
    expect(
      (await db.select(db.trainingSessions).get()).single.status,
      'planned',
    );
  });
  test('retry after scheduling failure reuses the created workout', () async {
    garmin.failSchedule = true;
    final plans = TrainingPlanService(db, garmin);
    await expectLater(plans.pushToGarmin(session.id), throwsException);
    garmin.failSchedule = false;
    await plans.pushToGarmin(session.id);
    expect(garmin.creates, 1);
    expect(garmin.dates.length, 1);
  });
}
