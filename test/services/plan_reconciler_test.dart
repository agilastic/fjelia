import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/control/plan_reconciler.dart';
import 'package:fjelia/services/plan_session_actions.dart';
import 'package:fjelia/services/post_workout_scorer.dart';
import 'package:fjelia/services/session_adaptation_service.dart';
import 'package:fjelia/services/workout_providers/workout_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late PlanReconciler reconciler;
  // A Monday; the plan runs around it.
  final today = DateTime(2026, 11, 9);
  final tomorrow = DateTime(2026, 11, 10);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final scorer = PostWorkoutScorer(db);
    reconciler = PlanReconciler(
      db,
      scorer,
      PlanSessionActions(db, WorkoutProviders(const [])),
      SessionAdaptationService(db),
    );
    await db
        .into(db.trainingPlans)
        .insert(
          TrainingPlansCompanion.insert(
            id: 'p',
            athleteId: 'self',
            startDate: DateTime(2026, 11, 2),
            endDate: DateTime(2027, 4, 1),
            status: 'active',
            generatedAt: DateTime(2026, 11, 2),
          ),
        );
  });
  tearDown(() => db.close());

  Future<void> plan(
    String id,
    DateTime day,
    String sport, {
    int minutes = 60,
    int zone = 2,
    String type = 'endurance',
    String? subType,
    String? zones,
    bool locked = false,
  }) => db
      .into(db.trainingSessions)
      .insert(
        TrainingSessionsCompanion.insert(
          id: id,
          planId: 'p',
          athleteId: 'self',
          sessionDate: day,
          sessionNumber: 1,
          weekNumber: 2,
          sport: sport,
          sessionType: type,
          subType: Value(subType),
          phase: 'build',
          primaryZone: zone,
          title: id,
          plannedDurationMin: minutes,
          plannedTrimp: minutes,
          sessionLevel: 1,
          plannedZonesJson: Value(zones),
          locked: Value(locked),
        ),
      );

  Future<ActivityRecord> did(
    String id,
    String type, {
    int minutes = 60,
    int hour = 9,
    Map<String, num>? zones,
    double? km,
    double? climb,
  }) async {
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: id,
            name: id,
            type: type,
            startDate: today.add(Duration(hours: hour)),
            durationSeconds: minutes * 60,
            hrZonesJson: Value(zones == null ? null : jsonEncode(zones)),
            distanceMeters: Value(km == null ? null : km * 1000),
            totalElevation: Value(climb),
          ),
        );
    return (db.select(
      db.activityRecords,
    )..where((t) => t.activityId.equals(id))).getSingle();
  }

  Future<TrainingSession> session(String id) => (db.select(
    db.trainingSessions,
  )..where((t) => t.id.equals(id))).getSingle();

  Future<SessionActual?> actual(String id) => (db.select(
    db.sessionActuals,
  )..where((t) => t.sessionId.equals(id))).getSingleOrNull();

  DateTime dayOf(TrainingSession s) =>
      DateTime(s.sessionDate.year, s.sessionDate.month, s.sessionDate.day);

  Future<PlanChanges> reconcile({int maxPerDay = 1}) => reconciler.reconcile(
    now: today.add(const Duration(hours: 20)),
    maxPerDay: maxPerDay,
  );

  // A hard hilly ride: a third of three hours at threshold or harder.
  const hard = {
    'zone1': 10,
    'zone2': 30,
    'zone3': 25,
    'zone4': 25,
    'zone5': 10,
  };

  test('tomorrow\'s ride and swim done today: the days swap', () async {
    await plan('strength', today, 'strength', subType: 'strengthFull');
    await plan('run', today, 'running', minutes: 45);
    await plan('ride', tomorrow, 'cycling_road');
    await plan('swim', tomorrow, 'swimming', minutes: 45);
    await did('Ride', 'cycling', hour: 9);
    await did('Swim', 'swimming', minutes: 45, hour: 17);

    final changes = await reconcile(maxPerDay: 2);

    for (final id in ['ride', 'swim']) {
      final s = await session(id);
      expect(s.status, 'completed', reason: id);
      expect(dayOf(s), today, reason: id);
      expect((await actual(id))!.matchKind, 'swap', reason: id);
    }
    // The run takes the free day; strength stays for the missed flow.
    expect(dayOf(await session('run')), tomorrow);
    expect((await session('run')).status, 'planned');
    expect(dayOf(await session('strength')), today);
    expect(changes.release, containsAll(['ride', 'swim']));
    expect(changes.deliver, contains('run'));
    final log = await db.select(db.planAdjustments).get();
    expect(log.map((x) => x.kind), containsAll(['swap', 'move']));
  });

  test('a hard 3 h hill ride counts as tomorrow\'s ride and as leg strength; '
      'the run moves to tomorrow, shorter', () async {
    await plan(
      'legs',
      today,
      'strength',
      subType: 'strengthLower',
      type: 'key',
    );
    await plan('run', today, 'running', minutes: 80, type: 'long');
    await plan('ride', tomorrow, 'cycling_road', minutes: 90);
    await did(
      'Hill ride',
      'cycling',
      minutes: 180,
      zones: hard,
      km: 80,
      climb: 1600,
    );

    await reconcile();

    final ride = await session('ride');
    expect(ride.status, 'completed');
    expect(dayOf(ride), today);
    expect((await actual('ride'))!.matchKind, 'substitute');

    final legs = await actual('legs');
    expect(legs!.matchKind, 'credit');
    expect(legs.creditedByActivityId, 'Hill ride');
    expect(legs.activityId, isNull);
    expect((await session('legs')).status, 'completed');

    final run = await session('run');
    expect(dayOf(run), tomorrow);
    expect(run.plannedDurationMin, lessThanOrEqualTo(60));
    final reasons = (await db.select(db.planAdjustments).get()).map(
      (x) => x.reasonCode,
    );
    expect(reasons, containsAll(['substitute', 'strengthCredit', 'movedEasy']));
  });

  test(
    'a long easy ride does not stand in for tomorrow\'s threshold ride',
    () async {
      await plan(
        'threshold',
        tomorrow,
        'cycling_road',
        minutes: 90,
        zone: 4,
        type: 'key',
        zones: jsonEncode({'z1': 20, 'z2': 30, 'z3': 0, 'z4': 50}),
      );
      await did(
        'Long ride',
        'cycling',
        minutes: 180,
        zones: {'zone1': 30, 'zone2': 70},
      );

      final changes = await reconcile();

      expect(changes.isEmpty, isTrue);
      expect((await session('threshold')).status, 'planned');
      expect(dayOf(await session('threshold')), tomorrow);
    },
  );

  test('two rides it could be: nothing moves', () async {
    await plan('a', tomorrow, 'cycling_road', minutes: 90);
    await plan('b', DateTime(2026, 11, 11), 'cycling_road', minutes: 100);
    await did('Ride', 'cycling', minutes: 180, zones: hard);

    expect((await reconcile()).isEmpty, isTrue);
    expect(await db.select(db.planAdjustments).get(), isEmpty);
  });

  test('a locked session stays where it is', () async {
    await plan('ride', tomorrow, 'cycling_road', locked: true);
    await did('Ride', 'cycling');
    expect((await reconcile()).isEmpty, isTrue);
    expect(dayOf(await session('ride')), tomorrow);
  });

  test('undo puts every session back and is not redone', () async {
    await plan('run', today, 'running', minutes: 45);
    await plan('ride', tomorrow, 'cycling_road');
    await did('Ride', 'cycling');
    await reconcile();
    final group = (await db.select(db.planAdjustments).get()).first.groupId;

    final changes = await reconciler.undo(group);

    final ride = await session('ride');
    expect(ride.status, 'planned');
    expect(dayOf(ride), tomorrow);
    expect(await actual('ride'), isNull);
    expect(dayOf(await session('run')), today);
    expect(changes.deliver, containsAll(['ride', 'run']));
    expect(
      (await db.select(db.planAdjustments).get()).every(
        (x) => x.undoneAt != null,
      ),
      isTrue,
    );
    // The next sync leaves it as the athlete wanted.
    expect((await reconcile()).isEmpty, isTrue);
    expect(dayOf(await session('ride')), tomorrow);
  });

  test(
    'deleting the workout undoes its moves and reopens its session',
    () async {
      await plan('run', today, 'running', minutes: 45);
      await plan('ride', tomorrow, 'cycling_road');
      final a = await did('Ride', 'cycling');
      await reconcile();
      await db.deleteActivityByUser(a.activityId);

      await reconciler.forgetActivity(a.activityId);

      expect((await session('ride')).status, 'planned');
      expect(dayOf(await session('ride')), tomorrow);
      expect(await actual('ride'), isNull);
      expect(dayOf(await session('run')), today);
    },
  );

  test('deleting a workout of its own day reopens that session', () async {
    await plan('run', today, 'running', minutes: 45);
    final a = await did('Run', 'running', minutes: 45);
    await PostWorkoutScorer(db).score(a);
    expect((await session('run')).status, 'completed');

    await reconciler.forgetActivity(a.activityId);

    expect((await session('run')).status, 'planned');
    expect(await actual('run'), isNull);
  });
}
