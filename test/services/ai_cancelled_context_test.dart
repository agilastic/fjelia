import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/coach_context_card.dart';
import 'package:fjelia/services/ai_coach_rules.dart';
import 'package:fjelia/services/ai_context_toon_builder.dart';
import 'package:fjelia/services/apple_context_facts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.trainingPlans)
        .insert(
          TrainingPlansCompanion.insert(
            id: 'p',
            athleteId: 'self',
            startDate: day(-20),
            endDate: day(100),
            status: 'active',
            generatedAt: day(-20),
          ),
        );
  });
  tearDown(() => db.close());

  Future<void> session(
    String id,
    DateTime date,
    String status, {
    String? reason,
  }) async {
    await db
        .into(db.trainingSessions)
        .insert(
          TrainingSessionsCompanion.insert(
            id: id,
            planId: 'p',
            athleteId: 'self',
            sessionDate: date,
            sessionNumber: 1,
            weekNumber: 1,
            sport: 'running',
            sessionType: 'key',
            phase: 'base',
            primaryZone: 3,
            title: 'Secret title $id',
            plannedDurationMin: 45,
            plannedTrimp: 50,
            sessionLevel: 4,
            status: Value(status),
          ),
        );
    if (reason != null) {
      await db
          .into(db.sessionActuals)
          .insert(
            SessionActualsCompanion.insert(
              sessionId: id,
              skipReason: Value(reason),
            ),
          );
    }
  }

  Future<String> context() => AiContextToonBuilder(db).build(null, '', null);

  test('a cancelled session today is not a plain rest day', () async {
    await session('a', today, 'skipped', reason: 'Illness');
    final text = await context();
    expect(
      text,
      contains('[TodayWorkout:Status:cancelled,Reason:Illness,By:athlete'),
    );
    expect(text, isNot(contains('[TodayWorkout:Status:rest_day')));
    expect(
      text,
      contains('[Cancelled:Sessions:1,Window:±14d,Reasons:Illness]'),
    );
    expect(text, contains('Planned:45m,Reason:Illness,By:athlete]'));
    expect(text, contains('Status:cancelled,Reason:Illness]'));
    // Names stay out of what is sent.
    expect(text, isNot(contains('Secret title')));
  });

  test('a skip the readiness check made says so', () async {
    await session('r', today, 'skipped', reason: 'Rest advised by readiness');
    expect(await context(), contains('By:readiness'));
  });

  test('a past session nothing was recorded for is no decision', () async {
    await session('m', day(-5), 'skipped', reason: 'No matching activity');
    await session('far', day(-40), 'skipped', reason: 'Illness');
    final text = await context();
    expect(text, isNot(contains('[Cancelled:')));
    expect(text, contains('[TodayWorkout:Status:rest_day'));
  });

  test('recent and coming cancellations are listed', () async {
    await session('past', day(-3), 'skipped', reason: 'Travel');
    await session('next', day(4), 'skipped', reason: 'Injury or pain');
    final text = await context();
    expect(text, contains('[Cancelled:Sessions:2'));
    expect(text, contains('Reasons:Travel/Injury or pain]'));
  });

  test('the rules say illness is a restriction, for every provider', () {
    expect(
      coachAnswerStandard,
      contains('Illness or injury is a health restriction'),
    );
    expect(coachAnswerStandardShort, contains('Illness or Injury means rest'));
  });

  test(
    'a session card carries the reason, Apple reads it as a sentence',
    () async {
      await session('s', day(1), 'skipped', reason: 'Illness');
      final row = await (db.select(
        db.trainingSessions,
      )..where((t) => t.id.equals('s'))).getSingle();
      final card = CoachContextCard.planned(row, skipReason: 'Illness');
      expect(card.contextLine, contains('SkipReason:Illness'));
      final text = appleFactLine(card.contextLine);
      expect(text, contains('cancelled because of: Illness'));
      expect(text, contains('Do not suggest making it up'));
      // Without a reason nothing is claimed.
      expect(
        CoachContextCard.planned(row).contextLine,
        isNot(contains('SkipReason')),
      );
    },
  );

  test('Apple gets today as a sentence, not tags', () {
    final text = appleFactLine(
      '[TodayWorkout:Status:cancelled,Reason:Illness,By:athlete,GarminScheduled:0,PlanSessions:0]',
    );
    expect(text, contains('cancelled (Illness)'));
    expect(text, contains('NO training today'));
    expect(
      appleFactLine(
        '[Cancelled:Sessions:2,Window:±14d,Reasons:Travel/Illness]',
      ),
      contains('reasons: Travel, Illness'),
    );
    // Other TodayWorkout lines stay as they are.
    const rest =
        '[TodayWorkout:Status:rest_day,GarminScheduled:0,PlanSessions:0]';
    expect(appleFactLine(rest), rest);
  });

  group('race goal', () {
    Future<void> goal({int? target}) => db
        .into(db.raceGoals)
        .insert(
          RaceGoalsCompanion.insert(
            id: 'g',
            athleteId: 'self',
            name: 'Secret race name',
            primarySport: 'running',
            distanceM: 42200,
            elevationM: const Value(100),
            targetFinishSeconds: Value(target),
            raceDate: day(120),
            priority: 'a',
            source: 'manual',
            createdAt: today,
          ),
        );

    test(
      'the coach gets target, pace and terrain, not the race name',
      () async {
        await goal(target: 12600);
        final text = await context();
        final line = text
            .split('\n')
            .firstWhere((l) => l.startsWith('[RaceGoal:'));
        expect(
          line,
          contains('Sport:running,DistKm:42.2,ElevM:100,ClimbMPerKm:2.4'),
        );
        expect(line, contains('Terrain:flat'));
        expect(line, contains('Target:3:30:00,PaceSecKm:298.6'));
        expect(text, isNot(contains('Secret race name')));
      },
    );

    test(
      'without a target it says none, so the coach can suggest one',
      () async {
        await goal();
        expect(await context(), contains('Target:none'));
      },
    );

    test('Apple reads it as sentences', () {
      final text = appleFactLine(
        '[RaceGoal:Sport:running,DistKm:42.2,ElevM:100,ClimbMPerKm:2.4,Terrain:flat,Date:2027-04-10,Target:3:30:00,PaceSecKm:299,FlatPaceSecKm:296,Estimate:3:33:12,GoalAheadOfEstimate%:2]',
      );
      expect(text, contains('target 3:30:00 (4:59/km)'));
      expect(text, contains('current estimate 3:33:12'));
      expect(text, isNot(contains('a stretch')));
      final stretch = appleFactLine(
        '[RaceGoal:Sport:running,DistKm:42.2,ElevM:100,Terrain:flat,Date:2027-04-10,Target:3:00:00,PaceSecKm:256,Estimate:3:33:12,GoalAheadOfEstimate%:16]',
      );
      expect(stretch, contains('16% faster than the estimate: a stretch'));
      final none = appleFactLine(
        '[RaceGoal:Sport:running,DistKm:42.2,ElevM:na,Terrain:flat,Date:2027-04-10,Target:none,PaceSecKm:na,Estimate:na,GoalAheadOfEstimate%:na]',
      );
      expect(none, contains('no target time set'));
    });

    test('the rules tell the coach how to treat a stretch goal', () {
      expect(
        coachAnswerStandard,
        contains('A goal clearly faster than the estimate is a stretch'),
      );
    });
  });
}
