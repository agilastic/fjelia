import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/api/garmin_client.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/plan_goal_sync_provider.dart';
import 'package:fjelia/providers/planner_providers.dart';
import 'package:fjelia/services/plan_session_actions.dart';
import 'package:fjelia/services/replan_triggers.dart';
import 'package:fjelia/services/workout_semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fjelia/services/race_goal_service.dart';
import 'package:fjelia/services/season/goal_set.dart';
import 'package:fjelia/services/season/season_goal.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

/// A watch connection that can be taken offline: removals then fail.
class _FlakyGarmin extends FakeWorkoutGarmin {
  bool offline = false;
  final deleted = <String>[];
  @override
  Future<void> deleteWorkout(String workoutId, {String? scheduleId}) async {
    if (offline) throw GarminApiException('offline');
    deleted.add(workoutId);
  }
}

/// A watch connection whose removals wait until they are let go, so a test can
/// end a plan while a rebuild is in the middle of its work.
class _GatedGarmin extends FakeWorkoutGarmin {
  final entered = Completer<void>();
  final gate = Completer<void>();
  @override
  Future<void> deleteWorkout(String workoutId, {String? scheduleId}) async {
    if (!entered.isCompleted) entered.complete();
    await gate.future;
  }
}

/// A season planned on a fixed day: a marathon (A) on 10 April 2027 and a
/// 200 km brevet (B) on 20 March 2027, as a synthetic regression fixture.
final clock = DateTime(2026, 10, 25, 9);
final marathonDay = DateTime(2027, 4, 10);
final brevetDay = DateTime(2027, 3, 20);

DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  Future<void> addGoal(
    AppDatabase target,
    String id, {
    required String sport,
    required DateTime date,
    required double distanceM,
    required String priority,
    double? elevationM,
    int? targetSeconds,
    String participation = 'committed',
  }) => target
      .into(target.raceGoals)
      .insert(
        RaceGoalsCompanion.insert(
          id: id,
          athleteId: 'self',
          name: id == 'marathon' ? 'Hannover Marathon' : 'Brevet 200',
          primarySport: sport,
          distanceM: distanceM,
          raceDate: date,
          priority: priority,
          elevationM: Value(elevationM),
          targetFinishSeconds: Value(targetSeconds),
          participation: Value(participation),
          source: 'manual',
          createdAt: clock,
        ),
      );

  Future<void> addBoth(AppDatabase target, {bool reversed = false}) async {
    Future<void> marathon() => addGoal(
      target,
      'marathon',
      sport: 'running',
      date: marathonDay,
      distanceM: 42195,
      priority: 'a',
    );
    Future<void> brevet() => addGoal(
      target,
      'brevet',
      sport: 'cycling_road',
      date: brevetDay,
      distanceM: 200000,
      elevationM: 1500,
      targetSeconds: 7 * 3600 + 1800,
      priority: 'b',
    );
    if (reversed) {
      await brevet();
      await marathon();
    } else {
      await marathon();
      await brevet();
    }
  }

  Future<void> addHistory(AppDatabase target) async {
    // Twelve weeks: three runs (one of 100 min) and two rides (one of 150).
    var n = 0;
    for (var week = 12; week >= 1; week--) {
      for (final (offset, sport, minutes) in const [
        (6, 'running', 50),
        (5, 'cycling_road', 60),
        (4, 'running', 60),
        (3, 'cycling_road', 45),
        (1, 'running', 100),
        (0, 'cycling_road', 150),
      ]) {
        if (week == 12 && offset > 3) continue;
        final when = clock.subtract(Duration(days: week * 7 - offset));
        await target
            .into(target.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: 'h${n++}',
                name: sport,
                type: sport,
                startDate: when,
                durationSeconds: minutes * 60,
                distanceMeters: Value(
                  sport == 'running' ? minutes * 170.0 : minutes * 450.0,
                ),
                source: const Value('garmin'),
              ),
            );
      }
    }
    await target
        .into(target.athleteThresholds)
        .insert(
          AthleteThresholdsCompanion.insert(
            athleteId: 'self',
            lastUpdatedAt: Value(clock),
            ftpWatts: const Value(264),
            maxHrBpm: const Value(183),
            runHrZonesJson: const Value('[92,110,128,146,165]'),
            bikeHrZonesJson: const Value('[100,118,134,148,162]'),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  TrainingPlanService serviceFor(AppDatabase target) =>
      TrainingPlanService(target, garminProviders(target, FakeWorkoutGarmin()), clock: () => clock);

  Future<String> generate(
    AppDatabase target, {
    List<String> chosen = const ['running', 'cycling_road'],
    double hours = 9,
  }) async {
    final goals = await RaceGoalService(target).resolveGoalSet(today: clock);
    final goal = goals.display!;
    return serviceFor(target).generatePlan(
      athleteId: 'self',
      raceGoalId: goal.id,
      raceDate: goal.date,
      sport: goal.sport,
      raceDistanceM: goal.distanceM,
      daysPerWeek: 6,
      restDays: const [1],
      strengthDays: const [2],
      hoursPerWeek: hours,
      maxSessionsPerDay: 2,
      gadSports: chosen,
      goals: goals,
    );
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    await addHistory(db);
    await addBoth(db);
  });
  tearDown(() => db.close());

  Future<List<TrainingSession>> sessionsOf(AppDatabase target, String planId) =>
      (target.select(target.trainingSessions)
            ..where((t) => t.planId.equals(planId))
            ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)]))
          .get();

  group('one plan for both goals', () {
    test(
      'MG-T01/T02: the plan carries both goals and flags the spacing',
      () async {
        final planId = await generate(db);
        final plan = await (db.select(
          db.trainingPlans,
        )..where((t) => t.id.equals(planId))).getSingle();
        expect(plan.raceGoalId, 'marathon');
        expect(plan.endDate, marathonDay);
        final links = await db.select(db.planGoals).get();
        expect(links.map((l) => l.goalId).toSet(), {'marathon', 'brevet'});
        expect(links.firstWhere((l) => l.goalId == 'brevet').priority, 'b');
        expect(plan.goalSetRevision, isNotNull);
        final season = jsonDecode(plan.seasonJson!) as Map<String, dynamic>;
        expect(season['outcome'], 'feasibleWithTradeoffs');
        final conflicts = season['conflicts'] as List;
        expect(conflicts.single['gapDays'], 21);
      },
    );

    test('MG-T09: cycling is planned on purpose, not by rotation', () async {
      final planId = await generate(
        db,
        chosen: const [
          'running',
          'trail_running',
          'hiking',
          'inline_skating',
          'cycling_road',
          'swimming',
          'cycling_gravel',
          'indoor_rowing',
        ],
      );
      final sessions = await sessionsOf(db, planId);
      final sports = sessions.map((s) => s.sport).toSet();
      // Sports without a goal and without history are not scheduled.
      expect(sports, {'running', 'cycling_road', 'strength'});
      final rides = sessions.where((s) => s.sport == 'cycling_road');
      final runs = sessions.where((s) => s.sport == 'running');
      expect(rides.length, greaterThan(runs.length ~/ 2));
      // Long rides exist and grow towards the brevet.
      final long = rides
          .where((s) => s.sessionType == 'long')
          .map((s) => s.plannedDurationMin)
          .reduce((a, b) => a > b ? a : b);
      expect(long, greaterThanOrEqualTo(150));
      // No 30 minute Z1 filler stands in for a goal's preparation.
      final preparation = sessions.where(
        (s) =>
            s.goalRole == 'primary' &&
            s.sessionType == 'long' &&
            s.subType == 'endurance' &&
            s.phase != 'recovery' &&
            s.phase != 'race',
      );
      expect(preparation, isNotEmpty);
    });

    test('both sports are trained in every ordinary week', () async {
      final planId = await generate(db);
      final sessions = await sessionsOf(db, planId);
      final byWeek = <int, List<TrainingSession>>{};
      for (final s in sessions) {
        byWeek.putIfAbsent(s.weekNumber, () => []).add(s);
      }
      var ordinary = 0;
      // Up to the brevet: after it only the marathon is being prepared.
      final brevetWeek = byWeek.entries
          .where((e) => e.value.any((s) => !s.sessionDate.isAfter(brevetDay)))
          .map((e) => e.key)
          .reduce((a, b) => a > b ? a : b);
      for (final week in [
        for (final e in byWeek.entries)
          if (e.key < brevetWeek) e.value,
      ]) {
        final phases = week.map((s) => s.phase).toSet();
        if (phases.contains('recovery') ||
            phases.contains('race') ||
            week.length < 4) {
          continue;
        }
        ordinary++;
        expect(week.any((s) => s.sport == 'running'), isTrue);
        expect(week.any((s) => s.sport == 'cycling_road'), isTrue);
      }
      expect(ordinary, greaterThan(8));
    });

    test('sessions say which goal they prepare', () async {
      final planId = await generate(db);
      final sessions = await sessionsOf(db, planId);
      for (final s in sessions.where((s) => s.sport == 'cycling_road')) {
        expect(s.goalId, anyOf('brevet', isNull));
        if (s.goalId == 'brevet') {
          expect(s.goalObjective, contains('Brevet 200'));
        }
      }
      for (final s in sessions.where((s) => s.sport == 'running')) {
        expect(s.goalId, 'marathon');
      }
      for (final s in sessions.where((s) => s.sport == 'strength')) {
        expect(s.goalId, isNull);
        expect(s.goalRole, 'support');
      }
    });
  });

  group('events', () {
    test(
      'MG-T30: the event days carry no session, nor the day before',
      () async {
        final planId = await generate(db);
        final dates = (await sessionsOf(
          db,
          planId,
        )).map((s) => day(s.sessionDate));
        for (final event in [brevetDay, marathonDay]) {
          expect(dates, isNot(contains(event)));
          expect(
            dates,
            isNot(contains(event.subtract(const Duration(days: 1)))),
          );
        }
        expect(dates.every((d) => !d.isAfter(marathonDay)), isTrue);
      },
    );

    test('the days after the brevet take easy sessions only', () async {
      final planId = await generate(db);
      final sessions = await sessionsOf(db, planId);
      final goals = await RaceGoalService(db).resolveGoalSet(today: clock);
      final easyDays = goals.byId('brevet')!.demand.easyDaysAfter;
      for (var i = 1; i <= easyDays; i++) {
        final d = brevetDay.add(Duration(days: i));
        for (final s in sessions.where((s) => day(s.sessionDate) == d)) {
          expect(s.sport, isNot('strength'));
          expect(s.plannedDurationMin, lessThanOrEqualTo(70));
          expect(s.sessionType, isNot('key'));
        }
      }
    });

    test('the event is counted: its week is lighter, not stacked', () async {
      final planId = await generate(db);
      final sessions = await sessionsOf(db, planId);
      int minutes(DateTime from, DateTime to) => sessions
          .where(
            (s) => !s.sessionDate.isBefore(from) && s.sessionDate.isBefore(to),
          )
          .fold(0, (a, s) => a + s.plannedDurationMin);
      final eventWeek = minutes(DateTime(2027, 3, 15), DateTime(2027, 3, 22));
      final buildWeek = minutes(DateTime(2027, 2, 15), DateTime(2027, 2, 22));
      expect(eventWeek + 450, lessThan(buildWeek * 1.5));
      expect(eventWeek, lessThan(buildWeek * 0.6));
    });

    test('no day holds two long sessions', () async {
      final planId = await generate(db);
      final sessions = await sessionsOf(db, planId);
      final byDay = <DateTime, List<TrainingSession>>{};
      for (final s in sessions.where((s) => s.sport != 'strength')) {
        byDay.putIfAbsent(day(s.sessionDate), () => []).add(s);
      }
      for (final e in byDay.entries) {
        final heavy = e.value.where((s) => s.plannedDurationMin >= 90);
        expect(
          heavy.length,
          lessThanOrEqualTo(1),
          reason: '${e.key}: ${heavy.map((s) => s.title)}',
        );
      }
    });

    test(
      'a long ride is a weekend ride, and a run is not put on top of it',
      () async {
        final planId = await generate(db);
        final sessions = await sessionsOf(db, planId);
        final rides = sessions.where(
          (s) =>
              s.sport == 'cycling_road' &&
              s.sessionType == 'long' &&
              s.plannedDurationMin >= 150,
        );
        expect(rides, isNotEmpty);
        for (final r in rides) {
          expect(
            r.sessionDate.weekday,
            anyOf(DateTime.saturday, DateTime.sunday),
            reason: '${r.sessionDate} ${r.title}',
          );
        }
      },
    );

    test(
      'the week of the brevet holds nothing hard besides the brevet',
      () async {
        final planId = await generate(db);
        final sessions = await sessionsOf(db, planId);
        final week = sessions.where(
          (s) =>
              !s.sessionDate.isBefore(DateTime(2027, 3, 15)) &&
              s.sessionDate.isBefore(DateTime(2027, 3, 22)),
        );
        expect(
          week.where((s) => s.sessionType == 'key' && s.sport != 'strength'),
          isEmpty,
        );
        // Two days before: easy only.
        for (final s in week.where(
          (s) => day(s.sessionDate) == DateTime(2027, 3, 18),
        )) {
          expect(s.plannedDurationMin, lessThanOrEqualTo(60));
        }
      },
    );

    test('easy sessions are easy: zone 2 or below, named as such', () async {
      final planId = await generate(db);
      final sessions = await sessionsOf(db, planId);
      final easy = sessions.where(
        (s) => s.sessionType == 'recovery' && s.sport != 'strength',
      );
      expect(easy, isNotEmpty);
      for (final s in easy) {
        expect(s.primaryZone, lessThanOrEqualTo(2), reason: s.title);
      }
    });

    test('the first, part week is sized to the days that are left', () async {
      final planId = await generate(db);
      final sessions = await sessionsOf(db, planId);
      final today = sessions.where(
        (s) => day(s.sessionDate) == DateTime(2026, 10, 25),
      );
      final minutes = today.fold<int>(0, (a, s) => a + s.plannedDurationMin);
      expect(minutes, lessThan(200));
    });

    test('no long ride is followed next day by a long or hard run', () async {
      final planId = await generate(db);
      final sessions = await sessionsOf(db, planId);
      var clashes = 0;
      for (final long in sessions.where((s) => s.plannedDurationMin >= 150)) {
        final next = day(long.sessionDate).add(const Duration(days: 1));
        clashes += sessions
            .where(
              (s) =>
                  day(s.sessionDate) == next &&
                  s.sport != 'strength' &&
                  (s.sessionType == 'key' || s.plannedDurationMin >= 90),
            )
            .length;
      }
      expect(clashes, 0);
    });
  });

  group('the time of a week', () {
    test('no week is planned far past the hours in the settings', () async {
      final planId = await generate(db, hours: 9);
      final sessions = await sessionsOf(db, planId);
      final byWeek = <int, int>{};
      for (final s in sessions) {
        byWeek[s.weekNumber] =
            (byWeek[s.weekNumber] ?? 0) + s.plannedDurationMin;
      }
      for (final e in byWeek.entries) {
        expect(
          e.value,
          lessThanOrEqualTo(9 * 60 * 1.1),
          reason: 'week ${e.key}',
        );
      }
    });

    test('the allocation says what it could not hold', () async {
      final planId = await generate(db, hours: 7);
      final plan = await (db.select(
        db.trainingPlans,
      )..where((t) => t.id.equals(planId))).getSingle();
      final season = jsonDecode(plan.seasonJson!) as Map<String, dynamic>;
      expect(season['summary'], isNotEmpty);
      final weeks = season['weeks'] as List;
      expect(weeks, isNotEmpty);
      expect(
        weeks.any(
          (w) => (w['allocation']['tradeoffs'] as List?)?.isNotEmpty ?? false,
        ),
        isTrue,
      );
    });
  });

  group('goal changes', () {
    test('MG-T17: the order the goals were saved in changes nothing', () async {
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await WorkoutTemplateLibrary(other).seedIfEmpty();
      await addHistory(other);
      await addBoth(other, reversed: true);
      final a = await sessionsOf(db, await generate(db));
      final b = await sessionsOf(other, await generate(other));
      List<String> key(List<TrainingSession> s) => [
        for (final x in s)
          '${day(x.sessionDate)}|${x.sport}|${x.sessionType}|${x.plannedDurationMin}|${x.title}',
      ];
      expect(key(a), key(b));
    });

    test('MG-T18: a cancelled B goal leaves no brevet preparation', () async {
      await (db.update(db.raceGoals)..where((t) => t.id.equals('brevet')))
          .write(const RaceGoalsCompanion(participation: Value('cancelled')));
      final planId = await generate(db, chosen: const ['running']);
      final sessions = await sessionsOf(db, planId);
      expect(sessions.where((s) => s.goalId == 'brevet'), isEmpty);
      expect(sessions.where((s) => s.sport == 'cycling_road'), isEmpty);
      final links = await db.select(db.planGoals).get();
      expect(links.map((l) => l.goalId), ['marathon']);
      // The dates it held are free again.
      final dates = sessions.map((s) => day(s.sessionDate));
      expect(
        dates,
        contains(DateTime(2027, 3, 19)).or(contains(DateTime(2027, 3, 20))),
      );
    });

    test('MG-T04: a B goal after the A goal stays in the plan', () async {
      await db.delete(db.raceGoals).go();
      await addGoal(
        db,
        'marathon',
        sport: 'running',
        date: DateTime(2027, 3, 1),
        distanceM: 42195,
        priority: 'a',
      );
      await addGoal(
        db,
        'brevet',
        sport: 'cycling_road',
        date: DateTime(2027, 5, 15),
        distanceM: 200000,
        elevationM: 1500,
        priority: 'b',
      );
      final planId = await generate(db);
      final plan = await (db.select(
        db.trainingPlans,
      )..where((t) => t.id.equals(planId))).getSingle();
      expect(plan.endDate, DateTime(2027, 5, 15));
      final sessions = await sessionsOf(db, planId);
      // After the marathon the ride goal carries on.
      final after = sessions.where(
        (s) => s.sessionDate.isAfter(DateTime(2027, 3, 8)),
      );
      expect(after.where((s) => s.goalId == 'brevet'), isNotEmpty);
    });

    test('MG-T22: a replan keeps both goals and the season anchor', () async {
      final service = serviceFor(db);
      final planId = await generate(db);
      final before = await (db.select(
        db.trainingPlans,
      )..where((t) => t.id.equals(planId))).getSingle();
      await service.replan(
        planId: planId,
        reason: 'test',
        daysPerWeek: 6,
        restDays: const [1],
        strengthDays: const [2],
        hoursPerWeek: 9,
        maxSessionsPerDay: 2,
        preferredSports: const ['running', 'cycling_road'],
      );
      final after = await (db.select(
        db.trainingPlans,
      )..where((t) => t.id.equals(planId))).getSingle();
      expect(after.startDate, before.startDate);
      expect(after.goalSetRevision, before.goalSetRevision);
      final links = await db.select(db.planGoals).get();
      expect(links.map((l) => l.goalId).toSet(), {'marathon', 'brevet'});
      final sessions = await sessionsOf(db, planId);
      expect(sessions.where((s) => s.goalId == 'brevet'), isNotEmpty);
    });

    test(
      'MG-T16: a changed brevet date changes the revision, not the anchor',
      () async {
        final planId = await generate(db);
        final first = await (db.select(
          db.trainingPlans,
        )..where((t) => t.id.equals(planId))).getSingle();
        await (db.update(db.raceGoals)..where((t) => t.id.equals('brevet')))
            .write(RaceGoalsCompanion(raceDate: Value(DateTime(2027, 3, 13))));
        final goals = await RaceGoalService(db).resolveGoalSet(today: clock);
        await serviceFor(db).generatePlan(
          athleteId: 'self',
          raceGoalId: 'marathon',
          raceDate: marathonDay,
          sport: 'running',
          raceDistanceM: 42195,
          daysPerWeek: 6,
          restDays: const [1],
          strengthDays: const [2],
          hoursPerWeek: 9,
          maxSessionsPerDay: 2,
          gadSports: const ['running', 'cycling_road'],
          existingPlanId: planId,
          goals: goals,
        );
        final second = await (db.select(
          db.trainingPlans,
        )..where((t) => t.id.equals(planId))).getSingle();
        expect(second.goalSetRevision, isNot(first.goalSetRevision));
        expect(second.startDate, first.startDate);
      },
    );
  });

  group('what happened since', () {
    test(
      'MG-T21: a session the athlete moved stays where they put it',
      () async {
        final planId = await generate(db);
        final sessions = await sessionsOf(db, planId);
        final ride = sessions.firstWhere(
          (s) =>
              s.sport == 'cycling_road' &&
              s.sessionType == 'long' &&
              s.plannedDurationMin >= 150,
        );
        final target = day(ride.sessionDate).add(const Duration(days: 9));
        await PlanSessionActions(db, garminProviders(db, FakeWorkoutGarmin()),
        ).moveToDate(ride, target);
        await serviceFor(db).replan(
          planId: planId,
          reason: 'test',
          daysPerWeek: 6,
          restDays: const [1],
          strengthDays: const [2],
          hoursPerWeek: 9,
          maxSessionsPerDay: 2,
          preferredSports: const ['running', 'cycling_road'],
        );
        final moved = await (db.select(
          db.trainingSessions,
        )..where((t) => t.id.equals(ride.id))).getSingleOrNull();
        expect(moved, isNotNull);
        expect(day(moved!.sessionDate), target);
        expect(moved.modifiedBy, 'athlete');
        // The week around it was planned with it in, not with a second one.
        final week = (await sessionsOf(db, planId)).where(
          (s) =>
              !s.sessionDate.isBefore(
                target.subtract(Duration(days: target.weekday - 1)),
              ) &&
              s.sessionDate.isBefore(
                target.add(Duration(days: 8 - target.weekday)),
              ) &&
              s.sport == 'cycling_road' &&
              s.plannedDurationMin >= 150,
        );
        expect(week, hasLength(1));
      },
    );

    test(
      'MG-T20: when B is dropped, finished sessions and history stay',
      () async {
        final planId = await generate(db);
        final first = await sessionsOf(db, planId);
        final later = DateTime(2026, 11, 8, 9);
        final past = first.where(
          (s) => s.sessionDate.isBefore(DateTime(2026, 11, 8)),
        );
        expect(past, isNotEmpty);
        await (db.update(db.raceGoals)..where((t) => t.id.equals('brevet')))
            .write(const RaceGoalsCompanion(participation: Value('cancelled')));
        final goals = await RaceGoalService(db).resolveGoalSet(today: later);
        await TrainingPlanService(db, garminProviders(db, FakeWorkoutGarmin()),
          clock: () => later,
        ).generatePlan(
          athleteId: 'self',
          raceGoalId: 'marathon',
          raceDate: marathonDay,
          sport: 'running',
          raceDistanceM: 42195,
          daysPerWeek: 6,
          restDays: const [1],
          strengthDays: const [2],
          hoursPerWeek: 9,
          maxSessionsPerDay: 2,
          gadSports: const ['running', 'cycling_road'],
          existingPlanId: planId,
          goals: goals,
        );
        final after = await sessionsOf(db, planId);
        // What was behind us is untouched; nothing is owed for the dropped goal.
        for (final p in past) {
          expect(after.map((s) => s.id), contains(p.id));
        }
        expect(
          after.where(
            (s) =>
                !s.sessionDate.isBefore(DateTime(2026, 11, 8)) &&
                s.goalId == 'brevet',
          ),
          isEmpty,
        );
      },
    );

    test(
      'MG-T19: the week after the brevet is a recovery week, not a catch-up',
      () async {
        final planId = await generate(db);
        final plan = await sessionsOf(db, planId);
        int minutes(List<TrainingSession> all, DateTime from) => all
            .where(
              (s) =>
                  !s.sessionDate.isBefore(from) &&
                  s.sessionDate.isBefore(from.add(const Duration(days: 7))),
            )
            .fold(0, (a, s) => a + s.plannedDurationMin);
        final build = minutes(plan, DateTime(2027, 3, 1));

        // Planned again on the Monday after, with the brevet in the log.
        final other = AppDatabase(NativeDatabase.memory());
        addTearDown(other.close);
        await WorkoutTemplateLibrary(other).seedIfEmpty();
        await addHistory(other);
        await addBoth(other);
        await other
            .into(other.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: 'brevet-ride',
                name: 'Brevet',
                type: 'cycling_road',
                startDate: DateTime(2027, 3, 20, 6),
                durationSeconds: 7 * 3600 + 1800,
                distanceMeters: const Value(200000),
                source: const Value('garmin'),
              ),
            );
        final monday = DateTime(2027, 3, 22, 8);
        final goals = await RaceGoalService(
          other,
        ).resolveGoalSet(today: monday);
        expect(goals.recent.map((g) => g.id), ['brevet']);
        final planB =
            await TrainingPlanService(other, garminProviders(other, FakeWorkoutGarmin()),
              clock: () => monday,
            ).generatePlan(
              athleteId: 'self',
              raceGoalId: 'marathon',
              raceDate: marathonDay,
              sport: 'running',
              raceDistanceM: 42195,
              daysPerWeek: 6,
              restDays: const [1],
              strengthDays: const [2],
              hoursPerWeek: 9,
              maxSessionsPerDay: 2,
              gadSports: const ['running', 'cycling_road'],
              goals: goals,
            );
        final sessions = await sessionsOf(other, planB);
        final recovery = minutes(sessions, DateTime(2027, 3, 22));
        expect(recovery, lessThan(build * 0.85));
        // No ride is rebuilt for a goal that is behind us.
        expect(
          sessions.where(
            (s) => s.sport == 'cycling_road' && s.plannedDurationMin > 90,
          ),
          isEmpty,
        );
        // The first days are easy.
        for (final s in sessions.where(
          (s) => s.sessionDate.isBefore(DateTime(2027, 3, 25)),
        )) {
          expect(s.sessionType, isNot('key'));
        }
      },
    );
  });

  group('what the watch is told', () {
    test(
      'MG-T23: a brevet ride carries the brevet, not the marathon',
      () async {
        final planId = await generate(db);
        final sessions = await sessionsOf(db, planId);
        final ride = sessions.firstWhere(
          (s) => s.goalId == 'brevet' && s.stepsJson != null,
        );
        final workout = await serviceFor(db).prepareWorkout(ride.id);
        expect(workout.description, contains('Goal B · Brevet 200'));
        expect(workout.description, contains('7:30:00 for 200.0 km'));
        expect(workout.description, contains('1500 m climbing'));
        expect(workout.description, isNot(contains('/km')));
        expect(workout.description, isNot(contains('Hannover')));
      },
    );

    test('a run keeps the marathon pace lines', () async {
      final planId = await generate(db);
      final sessions = await sessionsOf(db, planId);
      final run = sessions.firstWhere(
        (s) => s.goalId == 'marathon' && s.stepsJson != null,
      );
      final workout = await serviceFor(db).prepareWorkout(run.id);
      expect(workout.description, contains('Purpose:'));
    });
  });

  test('MG-T25: a single A goal still plans as a single goal', () async {
    await db.delete(db.raceGoals).go();
    await addGoal(
      db,
      'marathon',
      sport: 'running',
      date: marathonDay,
      distanceM: 42195,
      priority: 'a',
    );
    final planId = await generate(db, chosen: const ['running']);
    final sessions = await sessionsOf(db, planId);
    expect(sessions.where((s) => s.sport == 'cycling_road'), isEmpty);
    final plan = await (db.select(
      db.trainingPlans,
    )..where((t) => t.id.equals(planId))).getSingle();
    final season = jsonDecode(plan.seasonJson!) as Map<String, dynamic>;
    expect(season['conflicts'], isEmpty);
    expect((await db.select(db.planGoals).get()).map((l) => l.goalId), [
      'marathon',
    ]);
  });

  test('MG-T22: two writers at once leave one plan, not two', () async {
    await Future.wait([generate(db), generate(db)]);
    final plans = await db.select(db.trainingPlans).get();
    expect(plans.where((p) => p.status == 'active'), hasLength(1));
    final active = plans.singleWhere((p) => p.status == 'active');
    final sessions = await sessionsOf(db, active.id);
    final keys = [
      for (final s in sessions)
        '${day(s.sessionDate)}|${s.sport}|${s.sessionType}|${s.plannedDurationMin}',
    ];
    expect(keys.toSet().length, keys.length);
  });

  test('the season planner can be switched off and nothing is lost', () async {
    SeasonPolicy.multiGoalPlanning = false;
    addTearDown(() => SeasonPolicy.multiGoalPlanning = true);
    final planId = await generate(db);
    final sessions = await sessionsOf(db, planId);
    expect(sessions.every((s) => s.goalId != 'brevet'), isTrue);
    // The goals are still linked and still stored with the plan.
    final links = await db.select(db.planGoals).get();
    expect(links.map((l) => l.goalId).toSet(), {'marathon', 'brevet'});
    final plan = await (db.select(
      db.trainingPlans,
    )..where((t) => t.id.equals(planId))).getSingle();
    expect(plan.seasonJson, isNotNull);
  });

  group('other combinations', () {
    Future<Map<String, dynamic>> seasonOf(String planId) async {
      final plan = await (db.select(
        db.trainingPlans,
      )..where((t) => t.id.equals(planId))).getSingle();
      return jsonDecode(plan.seasonJson!) as Map<String, dynamic>;
    }

    test(
      'MG-T05: two running goals share the preparation and keep the taper',
      () async {
        await db.delete(db.raceGoals).go();
        await addGoal(
          db,
          'marathon',
          sport: 'running',
          date: marathonDay,
          distanceM: 42195,
          priority: 'a',
        );
        await addGoal(
          db,
          'half',
          sport: 'running',
          date: DateTime(2027, 2, 6),
          distanceM: 21097,
          priority: 'b',
        );
        final planId = await generate(db, chosen: const ['running']);
        final sessions = await sessionsOf(db, planId);
        final dates = sessions.map((s) => day(s.sessionDate));
        expect(dates, isNot(contains(DateTime(2027, 2, 6))));
        expect(dates, isNot(contains(DateTime(2027, 2, 5))));
        // One running programme, not two: no week holds more than one long run
        // more than a single-goal plan would.
        final byWeek = <int, int>{};
        for (final s in sessions.where((s) => s.sport == 'running')) {
          byWeek[s.weekNumber] =
              (byWeek[s.weekNumber] ?? 0) + s.plannedDurationMin;
        }
        expect(byWeek.values.every((m) => m <= 9 * 60 * 1.1), isTrue);
        // The marathon's own taper is still there after the half.
        final taper = sessions.where(
          (s) =>
              s.sessionDate.isAfter(DateTime(2027, 3, 26)) &&
              s.phase == 'taper' &&
              s.goalId == 'marathon',
        );
        expect(taper, isNotEmpty);
        // A recovery follows the half before the marathon block carries on.
        final after = sessions.where(
          (s) =>
              s.sessionDate.isAfter(DateTime(2027, 2, 6)) &&
              s.sessionDate.isBefore(DateTime(2027, 2, 9)),
        );
        expect(after.where((s) => s.sessionType == 'key'), isEmpty);
      },
    );

    test(
      'MG-T06: two A goals that cannot both be prepared need a decision',
      () async {
        await db.delete(db.raceGoals).go();
        await addGoal(
          db,
          'marathon',
          sport: 'running',
          date: marathonDay,
          distanceM: 42195,
          priority: 'a',
        );
        await addGoal(
          db,
          'brevet',
          sport: 'cycling_road',
          date: DateTime(2027, 4, 1),
          distanceM: 200000,
          elevationM: 1500,
          targetSeconds: 27000,
          priority: 'a',
        );
        final planId = await generate(db);
        final season = await seasonOf(planId);
        expect(season['outcome'], 'requiresDecision');
        final conflict = (season['conflicts'] as List).single as Map;
        expect(conflict['kind'], 'closeHighPriority');
        expect(conflict['alternatives'], isNotEmpty);
        // The plan still exists, so the athlete has something to react to.
        expect(await sessionsOf(db, planId), isNotEmpty);
      },
    );

    test(
      'MG-T28: the same rules hold with the sports and priorities reversed',
      () async {
        await db.delete(db.raceGoals).go();
        await addGoal(
          db,
          'brevet',
          sport: 'cycling_road',
          date: marathonDay,
          distanceM: 200000,
          elevationM: 1500,
          targetSeconds: 27000,
          priority: 'a',
        );
        await addGoal(
          db,
          'marathon',
          sport: 'running',
          date: brevetDay,
          distanceM: 42195,
          priority: 'b',
        );
        final planId = await generate(db);
        final sessions = await sessionsOf(db, planId);
        final plan = await (db.select(
          db.trainingPlans,
        )..where((t) => t.id.equals(planId))).getSingle();
        expect(plan.raceGoalId, 'brevet');
        expect(sessions.where((s) => s.goalId == 'brevet'), isNotEmpty);
        expect(sessions.where((s) => s.goalId == 'marathon'), isNotEmpty);
        final dates = sessions.map((s) => day(s.sessionDate));
        expect(dates, isNot(contains(brevetDay)));
        expect(dates, isNot(contains(marathonDay)));
        expect(
          sessions
              .where((s) => s.goalId == 'marathon' && s.sessionType == 'long')
              .map((s) => s.plannedDurationMin)
              .reduce((a, b) => a > b ? a : b),
          greaterThanOrEqualTo(120),
        );
      },
    );

    test('MG-T29: no cycling history is said for cycling alone', () async {
      await db.delete(db.activityRecords).go();
      var n = 0;
      for (var week = 12; week >= 1; week--) {
        for (final offset in const [6, 4, 1]) {
          await db
              .into(db.activityRecords)
              .insert(
                ActivityRecordsCompanion.insert(
                  activityId: 'r${n++}',
                  name: 'run',
                  type: 'running',
                  startDate: clock.subtract(Duration(days: week * 7 - offset)),
                  durationSeconds: 3600,
                  source: const Value('garmin'),
                ),
              );
        }
      }
      final planId = await generate(db);
      final season = await seasonOf(planId);
      expect(season['confidence']['running'], 'high');
      expect(season['confidence']['cycling_road'], 'none');
      expect(season['outcome'], 'insufficientData');
      expect((season['summary'] as List).join(' '), contains('cycling road'));
      // The running side is not touched by the cycling gap.
      final sessions = await sessionsOf(db, planId);
      expect(sessions.where((s) => s.sport == 'running'), isNotEmpty);
    });

    test(
      'MG-T13: without weekend days the long ride is moved and it is said',
      () async {
        final goals = await RaceGoalService(db).resolveGoalSet(today: clock);
        final planId = await serviceFor(db).generatePlan(
          athleteId: 'self',
          raceGoalId: 'marathon',
          raceDate: marathonDay,
          sport: 'running',
          raceDistanceM: 42195,
          daysPerWeek: 4,
          restDays: const [5, 6, 7],
          strengthDays: const [2],
          hoursPerWeek: 9,
          maxSessionsPerDay: 2,
          gadSports: const ['running', 'cycling_road'],
          goals: goals,
        );
        final sessions = await sessionsOf(db, planId);
        final rides = sessions.where(
          (s) => s.sport == 'cycling_road' && s.plannedDurationMin >= 150,
        );
        expect(rides, isNotEmpty);
        for (final r in rides) {
          expect(r.sessionDate.weekday, lessThan(5));
        }
        final season = await seasonOf(planId);
        expect(
          (season['summary'] as List).join(' '),
          contains('away from its usual day'),
        );
      },
    );

    test('MG-T11: too few hours is not hidden by clipping', () async {
      final planId = await generate(db, hours: 4);
      final season = await seasonOf(planId);
      expect(season['outcome'], isNot('feasible'));
      expect(season['summary'], isNotEmpty);
      final sessions = await sessionsOf(db, planId);
      final byWeek = <int, int>{};
      for (final s in sessions) {
        byWeek[s.weekNumber] =
            (byWeek[s.weekNumber] ?? 0) + s.plannedDurationMin;
      }
      // Each week stays near the hours given; the shortfall is reported.
      expect(byWeek.values.every((m) => m <= 4 * 60 * 1.2), isTrue);
    });
  });

  group('review findings', () {
    Future<String> generateWith({
      int perDay = 2,
      double hours = 9,
      List<int> restDays = const [1],
      List<int> strengthDays = const [2],
      int daysPerWeek = 6,
      List<String> chosen = const ['running', 'cycling_road'],
      AppDatabase? on,
    }) async {
      final target = on ?? db;
      final goals = await RaceGoalService(target).resolveGoalSet(today: clock);
      final goal = goals.display!;
      return serviceFor(target).generatePlan(
        athleteId: 'self',
        raceGoalId: goal.id,
        raceDate: goal.date,
        sport: goal.sport,
        raceDistanceM: goal.distanceM,
        daysPerWeek: daysPerWeek,
        restDays: restDays,
        strengthDays: strengthDays,
        hoursPerWeek: hours,
        maxSessionsPerDay: perDay,
        gadSports: chosen,
        goals: goals,
      );
    }

    Future<void> replanWith(
      String planId, {
      int perDay = 2,
      DateTime? now,
      AppDatabase? on,
    }) {
      final target = on ?? db;
      return TrainingPlanService(target, garminProviders(target, FakeWorkoutGarmin()),
        clock: () => now ?? clock,
      ).replan(
        planId: planId,
        reason: 'test',
        daysPerWeek: 6,
        restDays: const [1],
        strengthDays: const [2],
        hoursPerWeek: 9,
        maxSessionsPerDay: perDay,
        preferredSports: const ['running', 'cycling_road'],
      );
    }

    Future<Map<String, dynamic>> seasonJsonOf(String planId) async {
      final plan = await (db.select(
        db.trainingPlans,
      )..where((t) => t.id.equals(planId))).getSingle();
      return jsonDecode(plan.seasonJson!) as Map<String, dynamic>;
    }

    test(
      '1: a finished session today leaves no second one on that day',
      () async {
        final planId = await generateWith(perDay: 1);
        final first = (await sessionsOf(db, planId)).first;
        expect(day(first.sessionDate), DateTime(2026, 10, 25));
        await (db.update(db.trainingSessions)
              ..where((t) => t.id.equals(first.id)))
            .write(const TrainingSessionsCompanion(status: Value('completed')));
        await replanWith(planId, perDay: 1);
        final today = (await sessionsOf(
          db,
          planId,
        )).where((s) => day(s.sessionDate) == DateTime(2026, 10, 25));
        expect(today.map((s) => s.id), [first.id]);
      },
    );

    test(
      '1: training done today that no session stands for takes the day',
      () async {
        await db
            .into(db.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: 'today-run',
                name: 'Morning run',
                type: 'running',
                startDate: DateTime(2026, 10, 25, 7),
                durationSeconds: 90 * 60,
                source: const Value('garmin'),
              ),
            );
        final planId = await generateWith(perDay: 1);
        final today = (await sessionsOf(
          db,
          planId,
        )).where((s) => day(s.sessionDate) == DateTime(2026, 10, 25));
        expect(today, isEmpty);
      },
    );

    test(
      '1: an illness day takes nothing new and nothing is made up',
      () async {
        final planId = await generateWith(perDay: 1);
        final sessions = await sessionsOf(db, planId);
        final sick = sessions.firstWhere(
          (s) =>
              s.sessionType == 'long' &&
              s.sessionDate.isAfter(DateTime(2026, 10, 28)),
        );
        await PlanSessionActions(db, garminProviders(db, FakeWorkoutGarmin()),
        ).markRest(sick, reason: 'Illness');
        await replanWith(planId, perDay: 1);
        final after = await sessionsOf(db, planId);
        final that = after.where(
          (s) => day(s.sessionDate) == day(sick.sessionDate),
        );
        expect(that.map((s) => s.id), [sick.id]);
        expect(that.single.status, 'skipped');
        // The week is not topped up for it either.
        final weekBefore = sessions
            .where((s) => s.weekNumber == sick.weekNumber && s.id != sick.id)
            .fold<int>(0, (a, s) => a + s.plannedDurationMin);
        final weekAfter = after
            .where(
              (s) => s.weekNumber == sick.weekNumber && s.status != 'skipped',
            )
            .fold<int>(0, (a, s) => a + s.plannedDurationMin);
        expect(weekAfter, lessThanOrEqualTo(weekBefore + 20));
      },
    );

    test(
      '2: a goal of the same sport just behind us is still recovered from',
      () async {
        // A marathon two days ago (B), another in April (A).
        await db.delete(db.raceGoals).go();
        await addGoal(
          db,
          'recent',
          sport: 'running',
          date: DateTime(2026, 10, 23),
          distanceM: 42195,
          priority: 'b',
        );
        await addGoal(
          db,
          'marathon',
          sport: 'running',
          date: marathonDay,
          distanceM: 42195,
          priority: 'a',
        );
        final goals = await RaceGoalService(db).resolveGoalSet(today: clock);
        expect(goals.recent.map((g) => g.id), ['recent']);
        final planId = await generateWith(chosen: const ['running']);
        final sessions = await sessionsOf(db, planId);
        // The days that follow are easy and short.
        for (final s in sessions.where(
          (s) => s.sessionDate.isBefore(DateTime(2026, 10, 27)),
        )) {
          expect(s.sessionType, isNot('key'), reason: s.title);
          expect(s.plannedDurationMin, lessThanOrEqualTo(60), reason: s.title);
        }
        // And the week is lighter than the weeks that carry on.
        int week(DateTime from) => sessions
            .where(
              (s) =>
                  !s.sessionDate.isBefore(from) &&
                  s.sessionDate.isBefore(from.add(const Duration(days: 7))),
            )
            .fold(0, (a, s) => a + s.plannedDurationMin);
        expect(
          week(DateTime(2026, 10, 26)),
          lessThan(week(DateTime(2026, 11, 9))),
        );
      },
    );

    test(
      '3: strength and endurance keep to two days and 150 minutes',
      () async {
        await db.delete(db.raceGoals).go();
        await addGoal(
          db,
          'marathon',
          sport: 'running',
          date: marathonDay,
          distanceM: 42195,
          priority: 'a',
        );
        await addGoal(
          db,
          'half',
          sport: 'running',
          date: DateTime(2027, 2, 6),
          distanceM: 21097,
          priority: 'b',
        );
        final planId = await generateWith(
          perDay: 1,
          hours: 2.5,
          daysPerWeek: 2,
          restDays: const [1, 3, 4, 5, 6],
          strengthDays: const [2, 7],
          chosen: const ['running'],
        );
        final sessions = await sessionsOf(db, planId);
        final byWeek = <int, List<TrainingSession>>{};
        for (final s in sessions) {
          byWeek.putIfAbsent(s.weekNumber, () => []).add(s);
        }
        for (final e in byWeek.entries) {
          expect(e.value.length, lessThanOrEqualTo(2), reason: 'week ${e.key}');
          expect(
            e.value.fold<int>(0, (a, s) => a + s.plannedDurationMin),
            lessThanOrEqualTo(150),
            reason: 'week ${e.key}',
          );
        }
        final season = await seasonJsonOf(planId);
        expect(season['outcome'], isNot('feasible'));
      },
    );

    test(
      '4: no session is moved onto an event day, whichever goal is shown',
      () async {
        final planId = await generateWith();
        final ride = (await sessionsOf(db, planId)).firstWhere(
          (s) => s.sport == 'cycling_road' && s.sessionType == 'long',
        );
        final actions = PlanSessionActions(db, garminProviders(db, FakeWorkoutGarmin()));
        // The brevet is the B goal: the marathon is the one the plan shows.
        await expectLater(
          actions.moveToDate(ride, brevetDay),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          actions.moveToDate(ride, brevetDay.subtract(const Duration(days: 1))),
          throwsA(isA<StateError>()),
        );
        final stays = await (db.select(
          db.trainingSessions,
        )..where((t) => t.id.equals(ride.id))).getSingle();
        expect(day(stays.sessionDate), day(ride.sessionDate));
        // An ordinary day still works.
        await actions.moveToDate(
          ride,
          day(ride.sessionDate).add(const Duration(days: 2)),
        );
      },
    );

    test(
      '4: a session already moved onto an event stays and is reported',
      () async {
        final planId = await generateWith();
        final ride = (await sessionsOf(db, planId)).firstWhere(
          (s) => s.sport == 'cycling_road' && s.sessionType == 'long',
        );
        await (db.update(
          db.trainingSessions,
        )..where((t) => t.id.equals(ride.id))).write(
          TrainingSessionsCompanion(
            sessionDate: Value(brevetDay),
            sessionDateOriginal: Value(ride.sessionDate.toIso8601String()),
            modifiedBy: const Value('athlete'),
          ),
        );
        await replanWith(planId);
        final kept = await (db.select(
          db.trainingSessions,
        )..where((t) => t.id.equals(ride.id))).getSingleOrNull();
        expect(kept, isNotNull);
        expect(day(kept!.sessionDate), brevetDay);
        final season = await seasonJsonOf(planId);
        expect((season['summary'] as List).join(' '), contains('you moved'));
        expect(season['outcome'], isNot('feasible'));
      },
    );

    test(
      '5: the season keeps its start when the A race is behind us',
      () async {
        await db.delete(db.raceGoals).go();
        await addGoal(
          db,
          'marathon',
          sport: 'running',
          date: DateTime(2027, 3, 1),
          distanceM: 42195,
          priority: 'a',
        );
        await addGoal(
          db,
          'brevet',
          sport: 'cycling_road',
          date: DateTime(2027, 5, 15),
          distanceM: 200000,
          elevationM: 1500,
          targetSeconds: 27000,
          priority: 'b',
        );
        final planId = await generateWith();
        final first = await (db.select(
          db.trainingPlans,
        )..where((t) => t.id.equals(planId))).getSingle();
        expect(first.raceGoalId, 'marathon');
        final unloadBefore = (await sessionsOf(db, planId))
            .where((s) => s.phase == 'recovery' && s.sport != 'strength')
            .map((s) => s.weekNumber)
            .toSet();
        expect(unloadBefore, isNotEmpty);
        // After the marathon the brevet is the goal the plan shows.
        final later = DateTime(2027, 3, 8, 9);
        await replanWith(planId, now: later);
        final second = await (db.select(
          db.trainingPlans,
        )..where((t) => t.id.equals(planId))).getSingle();
        expect(second.raceGoalId, 'brevet');
        expect(second.startDate, first.startDate);
        // The unloading rhythm carries on: the same weeks stay easy weeks.
        final unload = (await sessionsOf(db, planId))
            .where((s) => s.phase == 'recovery' && s.sport != 'strength')
            .map((s) => s.weekNumber)
            .toSet();
        final cycle = unloadBefore.reduce((a, b) => a < b ? a : b);
        expect(unload, isNotEmpty);
        expect(unload.every((w) => w % cycle == 0), isTrue, reason: '$unload');
      },
    );

    test(
      '6: the last goal gone ends the plan and clears what is planned',
      () async {
        final planId = await generateWith();
        final sessions = await sessionsOf(db, planId);
        final done = sessions.first;
        await (db.update(db.trainingSessions)
              ..where((t) => t.id.equals(done.id)))
            .write(const TrainingSessionsCompanion(status: Value('completed')));
        await (db.update(
          db.raceGoals,
        )).write(const RaceGoalsCompanion(participation: Value('cancelled')));
        final goals = await RaceGoalService(db).resolveGoalSet(today: clock);
        expect(goals.isEmpty, isTrue);
        expect(goalSetChanged(planRevision: 'x', goals: goals), isTrue);
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            trainingPlanServiceProvider.overrideWithValue(serviceFor(db)),
          ],
        );
        addTearDown(container.dispose);
        expect(await container.read(retirePlanWithoutGoalsProvider)(), isTrue);
        final plan = await (db.select(
          db.trainingPlans,
        )..where((t) => t.id.equals(planId))).getSingle();
        expect(plan.status, 'ended');
        final left = await sessionsOf(db, planId);
        expect(left.map((s) => s.id), [done.id]);
        // Ending it twice, or with goals present, does nothing.
        expect(await container.read(retirePlanWithoutGoalsProvider)(), isFalse);
      },
    );

    test('6: with goals left the plan is not ended', () async {
      final planId = await generateWith();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trainingPlanServiceProvider.overrideWithValue(serviceFor(db)),
        ],
      );
      addTearDown(container.dispose);
      expect(await container.read(retirePlanWithoutGoalsProvider)(), isFalse);
      final plan = await (db.select(
        db.trainingPlans,
      )..where((t) => t.id.equals(planId))).getSingle();
      expect(plan.status, 'active');
    });

    test(
      '9: ending a plan and rebuilding it at once cannot revive it',
      () async {
        final planId = await generateWith();
        final service = serviceFor(db);
        // The rebuild is held in the middle of its work, on the watch
        // removal, when the plan is ended.
        final gated = _GatedGarmin();
        final held = TrainingPlanService(db, garminProviders(db, gated), clock: () => clock);
        await held.pushPlanToGarmin('self');
        final rebuild = held.replan(
          planId: planId,
          reason: 'test',
          daysPerWeek: 6,
          restDays: const [1],
          strengthDays: const [2],
          hoursPerWeek: 9,
          maxSessionsPerDay: 2,
          preferredSports: const ['running', 'cycling_road'],
        );
        await gated.entered.future;
        final end = held.endPlan(planId);
        await pumpEventQueue(times: 10);
        gated.gate.complete();
        await Future.wait([rebuild, end]);
        Future<int> planned() async => (await sessionsOf(
          db,
          planId,
        )).where((s) => s.status == 'planned' || s.status == 'adapted').length;
        var plan = await (db.select(
          db.trainingPlans,
        )..where((t) => t.id.equals(planId))).getSingle();
        expect(plan.status, 'ended');
        expect(await planned(), 0);
        // A rebuild that arrives after the end does nothing.
        await service.replan(
          planId: planId,
          reason: 'late',
          daysPerWeek: 6,
          restDays: const [1],
          strengthDays: const [2],
          hoursPerWeek: 9,
          maxSessionsPerDay: 2,
          preferredSports: const ['running', 'cycling_road'],
        );
        plan = await (db.select(
          db.trainingPlans,
        )..where((t) => t.id.equals(planId))).getSingle();
        expect(plan.status, 'ended');
        expect(await planned(), 0);
        // And a generation that names the ended plan makes a new one.
        final fresh = await serviceFor(db).generatePlan(
          athleteId: 'self',
          raceGoalId: 'marathon',
          raceDate: marathonDay,
          sport: 'running',
          raceDistanceM: 42195,
          existingPlanId: planId,
          goals: await RaceGoalService(db).resolveGoalSet(today: clock),
        );
        expect(fresh, isNot(planId));
        expect(await planned(), 0);
      },
    );

    test('9: only the active plan is sent to the watch', () async {
      final garmin = _FlakyGarmin();
      final service = TrainingPlanService(db, garminProviders(db, garmin), clock: () => clock);
      final goals = await RaceGoalService(db).resolveGoalSet(today: clock);
      Future<String> build() => service.generatePlan(
        athleteId: 'self',
        raceGoalId: 'marathon',
        raceDate: marathonDay,
        sport: 'running',
        raceDistanceM: 42195,
        daysPerWeek: 6,
        restDays: const [1],
        strengthDays: const [2],
        hoursPerWeek: 9,
        maxSessionsPerDay: 2,
        gadSports: const ['running', 'cycling_road'],
        goals: goals,
      );
      final old = await build();
      final oldSession = (await sessionsOf(
        db,
        old,
      )).firstWhere((s) => s.stepsJson != null);
      final current = await build();
      // The first plan was replaced: its sessions are not sent.
      await expectLater(
        service.pushToGarmin(oldSession.id),
        throwsA(isA<StateError>()),
      );
      await service.pushPlanToGarmin('self');
      final pushed = await (db.select(
        db.trainingSessions,
      )..where((t) => t.garminWorkoutId.isNotNull())).get();
      expect(pushed, isNotEmpty);
      expect(pushed.every((s) => s.planId == current), isTrue);
      // Once the plan has ended nothing more goes.
      final before = garmin.creates;
      await service.endPlan(current);
      await service.pushPlanToGarmin('self');
      expect(garmin.creates, before);
    });

    test(
      '9: a watch entry that cannot be removed is queued and tried again',
      () async {
        final garmin = _FlakyGarmin();
        final service = TrainingPlanService(db, garminProviders(db, garmin), clock: () => clock);
        final goals = await RaceGoalService(db).resolveGoalSet(today: clock);
        final planId = await service.generatePlan(
          athleteId: 'self',
          raceGoalId: 'marathon',
          raceDate: marathonDay,
          sport: 'running',
          raceDistanceM: 42195,
          daysPerWeek: 6,
          restDays: const [1],
          strengthDays: const [2],
          hoursPerWeek: 9,
          maxSessionsPerDay: 2,
          gadSports: const ['running', 'cycling_road'],
          goals: goals,
        );
        await service.pushPlanToGarmin('self');
        final onWatch = (await sessionsOf(db, planId))
            .where((s) => s.garminWorkoutId != null)
            .map((s) => s.garminWorkoutId!)
            .toSet();
        expect(onWatch, isNotEmpty);
        garmin.offline = true;
        await service.endPlan(planId);
        // The plan ended and its sessions are gone, whatever the connection.
        final plan = await (db.select(
          db.trainingPlans,
        )..where((t) => t.id.equals(planId))).getSingle();
        expect(plan.status, 'ended');
        expect(
          (await sessionsOf(db, planId)).where((s) => s.status == 'planned'),
          isEmpty,
        );
        // The entries are remembered for later.
        var queue = await db.select(db.providerCleanups).get();
        expect(queue.map((q) => q.remoteId).toSet(), onWatch);
        expect(queue.every((q) => q.providerId == 'garmin'), isTrue);
        expect(queue.every((q) => q.attempts == 1), isTrue);
        // Still offline: they stay, with one more try counted.
        expect(await service.retryGarminCleanup(), 0);
        queue = await db.select(db.providerCleanups).get();
        expect(queue, hasLength(onWatch.length));
        expect(queue.every((q) => q.attempts == 2), isTrue);
        // Back online: gone from the watch and from the queue.
        garmin.offline = false;
        expect(await service.retryGarminCleanup(), onWatch.length);
        expect(await db.select(db.providerCleanups).get(), isEmpty);
        expect(garmin.deleted.toSet(), onWatch);
      },
    );

    test(
      '10: the report names a long session that was dropped for time already spent',
      () async {
        // A six hour ride nobody planned, on a Monday that opens the week.
        final monday = DateTime(2026, 10, 26, 18);
        await db
            .into(db.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: 'unplanned-ride',
                name: 'Long ride',
                type: 'cycling_road',
                startDate: DateTime(2026, 10, 26, 6),
                durationSeconds: 6 * 3600,
                source: const Value('garmin'),
              ),
            );
        final goals = await RaceGoalService(db).resolveGoalSet(today: monday);
        final planId =
            await TrainingPlanService(db, garminProviders(db, FakeWorkoutGarmin()),
              clock: () => monday,
            ).generatePlan(
              athleteId: 'self',
              raceGoalId: 'marathon',
              raceDate: marathonDay,
              sport: 'running',
              raceDistanceM: 42195,
              daysPerWeek: 6,
              restDays: const [1],
              strengthDays: const [2],
              hoursPerWeek: 9,
              maxSessionsPerDay: 2,
              gadSports: const ['running', 'cycling_road'],
              goals: goals,
            );
        final season = await seasonJsonOf(planId);
        final first = (season['weeks'] as List).first as Map<String, dynamic>;
        final allocation = first['allocation'] as Map<String, dynamic>;
        final sessions = (await sessionsOf(
          db,
          planId,
        )).where((s) => s.sessionDate.isBefore(DateTime(2026, 11, 2)));
        // What the report calls planned is what is stored.
        expect(
          allocation['plannedMin'],
          sessions.fold<int>(0, (a, s) => a + s.plannedDurationMin),
        );
        final longs = (allocation['longTargets'] as Map?) ?? const {};
        for (final e in longs.entries) {
          expect(
            sessions.any(
              (s) =>
                  s.sport == e.key &&
                  s.sessionType == 'long' &&
                  s.plannedDurationMin == e.value,
            ),
            isTrue,
            reason: '${e.key} ${e.value}',
          );
        }
        for (final sport in ['running', 'cycling_road']) {
          final stored = sessions.any(
            (s) => s.sport == sport && s.sessionType == 'long',
          );
          expect(longs.containsKey(sport), stored, reason: sport);
        }
        // A protected long session that is gone is a conflict, in words.
        final unmet = (allocation['unmet'] as List?) ?? const [];
        final lostLong = ['running', 'cycling_road'].any(
          (sport) =>
              !sessions.any((s) => s.sport == sport && s.sessionType == 'long'),
        );
        if (lostLong) {
          expect(unmet.join(' '), contains('dropped'));
          expect(season['outcome'], anyOf('requiresDecision', 'infeasible'));
        }
        expect(lostLong, isTrue);
      },
    );

    test(
      '7: a run is paced against the running goal, not the ride goal shown',
      () async {
        await db.delete(db.raceGoals).go();
        await addGoal(
          db,
          'brevet',
          sport: 'cycling_road',
          date: marathonDay,
          distanceM: 200000,
          elevationM: 1500,
          targetSeconds: 27000,
          priority: 'a',
        );
        await addGoal(
          db,
          'marathon',
          sport: 'running',
          date: brevetDay,
          distanceM: 42195,
          targetSeconds: 3 * 3600 + 30 * 60,
          priority: 'b',
        );
        final planId = await generateWith();
        final runs = (await sessionsOf(
          db,
          planId,
        )).where((s) => s.sport == 'running' && s.stepsJson != null);
        expect(runs, isNotEmpty);
        for (final r in runs) {
          expect(r.paceRangesJson, isNotNull, reason: r.title);
          final pace = jsonDecode(r.paceRangesJson!) as Map<String, dynamic>;
          expect(pace['basis'], 'goal');
          // 3:30 for a marathon is about 4:58 per km.
          expect(pace['goal_sec_per_km'], inInclusiveRange(290, 305));
        }
      },
    );

    test(
      '8: an athlete who rarely trains hard starts with steady work only',
      () async {
        final easy = AppDatabase(NativeDatabase.memory());
        addTearDown(easy.close);
        await WorkoutTemplateLibrary(easy).seedIfEmpty();
        await addBoth(easy);
        var n = 0;
        for (var week = 12; week >= 1; week--) {
          for (final (offset, sport, minutes) in const [
            (6, 'running', 50),
            (4, 'running', 60),
            (1, 'running', 100),
            (5, 'cycling_road', 60),
            (0, 'cycling_road', 150),
          ]) {
            await easy
                .into(easy.activityRecords)
                .insert(
                  ActivityRecordsCompanion.insert(
                    activityId: 'e${n++}',
                    name: sport,
                    type: sport,
                    startDate: clock.subtract(
                      Duration(days: week * 7 - offset),
                    ),
                    durationSeconds: minutes * 60,
                    hrZonesJson: Value(
                      jsonEncode({
                        'zone1': 10,
                        'zone2': 88,
                        'zone3': 2,
                        'zone4': 0,
                        'zone5': 0,
                      }),
                    ),
                    source: const Value('garmin'),
                  ),
                );
          }
        }
        await easy
            .into(easy.athleteThresholds)
            .insert(
              AthleteThresholdsCompanion.insert(
                athleteId: 'self',
                lastUpdatedAt: Value(clock),
                ftpWatts: const Value(264),
                maxHrBpm: const Value(183),
                runHrZonesJson: const Value('[92,110,128,146,165]'),
                bikeHrZonesJson: const Value('[100,118,134,148,162]'),
              ),
              mode: InsertMode.insertOrReplace,
            );
        final planId = await generateWith(on: easy);
        final sessions = await sessionsOf(easy, planId);
        final first = sessions
            .where((s) => s.sessionDate.isBefore(DateTime(2026, 11, 9)))
            .where((s) => s.sessionType == 'key' && s.sport != 'strength');
        expect(first, isNotEmpty);
        final perWeek = <int, int>{};
        for (final k in first) {
          perWeek[k.weekNumber] = (perWeek[k.weekNumber] ?? 0) + 1;
          final steps = WorkoutSemantics.of(k.stepsJson, sport: k.sport);
          expect(
            steps.mainZoneSeconds.entries
                .where((e) => e.value > 0)
                .every((e) => e.key <= 3),
            isTrue,
            reason: '${k.title}: ${steps.mainZoneSeconds}',
          );
          expect(k.primaryZone, lessThanOrEqualTo(3));
        }
        expect(perWeek.values.every((c) => c <= 1), isTrue);
      },
    );
  });

  test('the goal set outcome is a plain enum', () {
    expect(FeasibilityOutcome.values.first, FeasibilityOutcome.feasible);
  });
}

extension on Matcher {
  Matcher or(Matcher other) => anyOf(this, other);
}
