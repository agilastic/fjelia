import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/absence_service.dart';
import 'package:fjelia/services/plan_session_actions.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await WorkoutTemplateLibrary(db).seedIfEmpty();
  });
  tearDown(() => db.close());

  TrainingPlanService service() =>
      TrainingPlanService(db, garminProviders(db, FakeWorkoutGarmin()));

  Future<List<TrainingSession>> generate({
    Map<int, int> caps = const {},
    String? existing,
  }) async {
    await service().generatePlan(
      athleteId: 'self',
      raceDate: day(12 * 7),
      sport: 'running',
      raceDistanceM: 21097,
      daysPerWeek: 5,
      restDays: const [1, 5],
      strengthDays: const [],
      hoursPerWeek: 6,
      gadSports: const ['running'],
      dayCapMinutes: caps,
      existingPlanId: existing,
    );
    return (db.select(
      db.trainingSessions,
    )..where((t) => t.status.isIn(const ['planned', 'adapted']))).get();
  }

  bool within(TrainingSession s, DateTime from, DateTime to) =>
      !s.sessionDate.isBefore(from) &&
      s.sessionDate.isBefore(to.add(const Duration(days: 1)));

  test('an illness leaves its days free and the week back is easy', () async {
    await db
        .into(db.absences)
        .insert(
          AbsencesCompanion.insert(
            kind: 'illness',
            startDay: day(7),
            endDay: day(13),
            createdAt: now,
          ),
        );
    final sessions = await generate();
    expect(sessions, isNotEmpty);
    expect(sessions.where((s) => within(s, day(7), day(13))), isEmpty);
    final back = sessions.where((s) => within(s, day(14), day(20))).toList();
    expect(back, isNotEmpty);
    for (final s in back) {
      expect(s.sessionType, isNot('key'), reason: s.title);
      expect(s.plannedDurationMin, lessThanOrEqualTo(50), reason: s.title);
    }
  });

  test('no session is longer than its day training window', () async {
    // Weekdays have an hour; the weekend has room for the long run.
    final sessions = await generate(
      caps: {2: 60, 3: 60, 4: 60, 6: 240, 7: 240},
    );
    final weekdays = sessions.where((s) => s.sessionDate.weekday <= 5);
    expect(weekdays, isNotEmpty);
    for (final s in weekdays) {
      expect(s.plannedDurationMin, lessThanOrEqualTo(65), reason: s.title);
    }
    final longs = sessions.where((s) => s.sessionType == 'long');
    expect(longs, isNotEmpty);
    // A long run of more than an hour only fits the weekend.
    expect(
      longs
          .where((s) => s.plannedDurationMin > 60)
          .every((s) => s.sessionDate.weekday >= 6),
      isTrue,
    );
  });

  test('entering and removing an absence cancels and restores', () async {
    final planId = (await generate()).first.planId;
    final absences = AbsenceService(
      db,
      PlanSessionActions(db, garminProviders(db, FakeWorkoutGarmin())),
    );
    final inRange = (await generate(existing: planId))
        .where((s) => within(s, day(21), day(27)))
        .toList();
    expect(inRange, isNotEmpty);
    final cancelled = await absences.add(
      kind: 'vacation',
      start: day(21),
      end: day(27),
    );
    expect(cancelled, inRange.length);
    final open = await (db.select(
      db.trainingSessions,
    )..where((t) => t.status.isIn(const ['planned', 'adapted']))).get();
    expect(open.where((s) => within(s, day(21), day(27))), isEmpty);
    final reasons = {
      for (final a in await db.select(db.sessionActuals).get())
        a.sessionId: a.skipReason,
    };
    expect(reasons[inRange.first.id], 'Travel');

    await absences.remove((await db.select(db.absences).get()).single);
    final restored = await (db.select(
      db.trainingSessions,
    )..where((t) => t.id.isIn([for (final s in inRange) s.id]))).get();
    expect(restored.every((s) => s.status == 'planned'), isTrue);
  });

  test('an open illness goes on day by day until fit again', () async {
    final planId = (await generate()).first.planId;
    final absences = AbsenceService(
      db,
      PlanSessionActions(db, garminProviders(db, FakeWorkoutGarmin())),
    );
    await generate(existing: planId);
    Future<List<TrainingSession>> openOn(int from, int to) async => [
      for (final s in await (db.select(
        db.trainingSessions,
      )..where((t) => t.status.isIn(const ['planned', 'adapted']))).get())
        if (within(s, day(from), day(to))) s,
    ];
    await absences.add(
      kind: 'illness',
      start: day(0),
      end: day(0),
      openEnd: true,
    );
    var ill = (await db.select(db.absences).get()).single;
    expect(ill.openEnd, isTrue);
    expect(ill.endDay, day(1));
    expect(await openOn(0, 1), isEmpty);

    // Three days later it still goes on: up to the day after.
    final later = day(3);
    expect(await absences.extendOpen(now: later), isTrue);
    ill = (await db.select(db.absences).get()).single;
    expect(ill.endDay, day(4));
    expect(await openOn(0, 4), isEmpty);
    expect(await absences.extendOpen(now: later), isFalse);

    // Fit again on day 3: the illness ended yesterday, today is open again.
    final cancelledAhead = [
      for (final s in await db.select(db.trainingSessions).get())
        if (within(s, day(3), day(4)) && s.status == 'skipped') s.id,
    ];
    await absences.endOpen(ill, now: later);
    ill = (await db.select(db.absences).get()).single;
    expect(ill.openEnd, isFalse);
    expect(ill.endDay, day(2));
    final back = await (db.select(
      db.trainingSessions,
    )..where((t) => t.id.isIn(cancelledAhead))).get();
    expect(back.every((s) => s.status == 'planned'), isTrue);
  });
}
