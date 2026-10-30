import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

/// A workout must be on Garmin's calendar once: pushing again, adopting an
/// entry already there or finding copies from earlier pushes never leaves the
/// same session on the same day more than once.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late FakeWorkoutGarmin garmin;
  late TrainingPlanService service;
  final clock = DateTime(2026, 10, 25, 9);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    garmin = FakeWorkoutGarmin();
    service = TrainingPlanService(
      db,
      garminProviders(db, garmin),
      clock: () => clock,
    );
    await service.generatePlan(
      athleteId: 'self',
      raceDate: clock.add(const Duration(days: 70)),
      sport: 'running',
      raceDistanceM: 21097,
      daysPerWeek: 5,
      restDays: const [1],
      strengthDays: const [],
      hoursPerWeek: 6,
      gadSports: const ['running'],
    );
  });
  tearDown(() => db.close());

  Future<TrainingSession> first() async =>
      (await (db.select(db.trainingSessions)
                ..where((t) => t.stepsJson.isNotNull())
                ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)]))
              .get())
          .first;

  String day(TrainingSession s) =>
      s.sessionDate.toIso8601String().substring(0, 10);

  Future<TrainingSession> reload(String id) => (db.select(
    db.trainingSessions,
  )..where((t) => t.id.equals(id))).getSingle();

  test('a pushed session pushed again stays on the calendar once', () async {
    final s = await first();
    await service.pushToGarmin(s.id);
    final pushed = await reload(s.id);
    // The calendar now shows the entry the push made.
    garmin.calendar = [
      (
        title: s.title,
        date: day(s),
        workoutId: pushed.garminWorkoutId!,
        scheduleId: pushed.garminAlternativeId!,
      ),
    ];
    await service.pushToGarmin(s.id);
    expect(garmin.dates, hasLength(1));
    expect(garmin.removedSchedules, isEmpty);
    expect(
      (await reload(s.id)).garminAlternativeId,
      pushed.garminAlternativeId,
    );
  });

  test(
    'an adopted entry keeps its calendar id and is not added again',
    () async {
      final s = await first();
      garmin.existingCalendar = {'${s.title}|${day(s)}': 'w-old'};
      await service.pushPlanToGarmin('self');
      final adopted = await reload(s.id);
      expect(adopted.garminWorkoutId, 'w-old');
      expect(adopted.garminAlternativeId, 'existing-w-old');
      final before = garmin.dates.length;
      await service.pushToGarmin(s.id);
      expect(garmin.dates.length, before);
    },
  );

  test('copies left by earlier pushes come off; other sessions stay', () async {
    final s = await first();
    garmin.calendar = [
      (title: s.title, date: day(s), workoutId: 'w-a', scheduleId: 'copy-1'),
      (title: s.title, date: day(s), workoutId: 'w-b', scheduleId: 'copy-2'),
      (title: 'My own ride', date: day(s), workoutId: 'w-x', scheduleId: 'own'),
    ];
    await service.pushToGarmin(s.id);
    // Adopted nothing (a single push), sent once, and the two copies are gone.
    expect(garmin.dates, hasLength(1));
    expect(garmin.removedSchedules, containsAll(['copy-1', 'copy-2']));
    expect(garmin.removedSchedules, isNot(contains('own')));
  });

  test(
    'a calendar entry of another session with the same title stays',
    () async {
      final s = await first();
      final other = (await (db.select(
        db.trainingSessions,
      )..where((t) => t.id.equals(s.id).not())).get()).first;
      await (db.update(
        db.trainingSessions,
      )..where((t) => t.id.equals(other.id))).write(
        const TrainingSessionsCompanion(garminAlternativeId: Value('theirs')),
      );
      garmin.calendar = [
        (title: s.title, date: day(s), workoutId: 'w-o', scheduleId: 'theirs'),
      ];
      await service.pushToGarmin(s.id);
      expect(garmin.removedSchedules, isNot(contains('theirs')));
    },
  );

  test('adopting with two copies on the calendar keeps one', () async {
    final s = await first();
    garmin.calendar = [
      (title: s.title, date: day(s), workoutId: 'w-1', scheduleId: 'c-1'),
      (title: s.title, date: day(s), workoutId: 'w-2', scheduleId: 'c-2'),
    ];
    await service.pushPlanToGarmin('self');
    final adopted = await reload(s.id);
    expect(adopted.garminAlternativeId, 'c-1');
    expect(garmin.removedSchedules, contains('c-2'));
    expect(garmin.removedSchedules, isNot(contains('c-1')));
  });
}
