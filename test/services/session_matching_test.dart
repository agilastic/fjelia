import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/post_workout_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late PostWorkoutScorer scorer;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    scorer = PostWorkoutScorer(db);
    await db
        .into(db.trainingPlans)
        .insert(
          TrainingPlansCompanion.insert(
            id: 'p',
            athleteId: 'self',
            startDate: DateTime(2026, 10, 1),
            endDate: DateTime(2027, 4, 1),
            status: 'active',
            generatedAt: DateTime(2026, 10, 1),
          ),
        );
  });
  tearDown(() => db.close());

  Future<void> plan(
    String id,
    DateTime day,
    String sport, {
    int minutes = 40,
    String status = 'planned',
  }) => db
      .into(db.trainingSessions)
      .insert(
        TrainingSessionsCompanion.insert(
          id: id,
          planId: 'p',
          athleteId: 'self',
          sessionDate: day,
          sessionNumber: 1,
          weekNumber: 1,
          sport: sport,
          sessionType: 'recovery',
          phase: 'base',
          primaryZone: 1,
          title: id,
          plannedDurationMin: minutes,
          plannedTrimp: 40,
          sessionLevel: 1,
          status: Value(status),
        ),
      );

  Future<ActivityRecord> activity(
    String id,
    DateTime start,
    String type, {
    int minutes = 40,
  }) async {
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: id,
            name: id,
            type: type,
            startDate: start,
            durationSeconds: minutes * 60,
          ),
        );
    return (db.select(
      db.activityRecords,
    )..where((t) => t.activityId.equals(id))).getSingle();
  }

  Future<String> status(String id) async => (await (db.select(
    db.trainingSessions,
  )..where((t) => t.id.equals(id))).getSingle()).status;

  group('sport families', () {
    test('yoga, hiking and inline are no catch-all', () {
      bool m(String sport, String type) =>
          PostWorkoutScorer.sportFamilyMatches(sport, type);
      expect(m('yoga', 'running'), isFalse);
      expect(m('yoga', 'strength_training'), isFalse);
      expect(m('yoga', 'yoga'), isTrue);
      expect(m('hiking', 'running'), isFalse);
      expect(m('hiking', 'hiking'), isTrue);
      expect(m('hiking', 'walking'), isTrue);
      expect(m('inline_skating', 'road_biking'), isFalse);
      expect(m('inline_skating', 'inline_skating'), isTrue);
      expect(m('climbing', 'running'), isFalse);
      expect(m('climbing', 'rock_climbing'), isTrue);
      expect(m('running', 'treadmill_running'), isTrue);
      expect(m('cycling_road', 'road_biking'), isTrue);
      expect(m('cycling_gravel', 'cyclocross'), isTrue);
      expect(m('strength', 'strength_training'), isTrue);
    });
  });

  group('matching', () {
    test('a run does not complete yoga on the same day', () async {
      await plan('yoga', DateTime(2026, 10, 22), 'yoga');
      final run = await activity('r', DateTime(2026, 10, 22, 14), 'running');
      expect(await scorer.score(run), isFalse);
      expect(await status('yoga'), 'planned');
    });

    test('the next day is not the activity\'s day', () async {
      await plan('tomorrow', DateTime(2026, 10, 21), 'running');
      final run = await activity('r', DateTime(2026, 10, 20, 14), 'running');
      expect(await scorer.score(run), isFalse);
      expect(await status('tomorrow'), 'planned');
    });

    test('one run completes one session, not two on following days', () async {
      await plan('d20', DateTime(2026, 10, 20), 'running');
      await plan('d21', DateTime(2026, 10, 21), 'running');
      final run = await activity('r', DateTime(2026, 10, 20, 14), 'running');
      expect(await scorer.scoreIfUnscored(run), isTrue);
      expect(await scorer.scoreIfUnscored(run), isFalse);
      expect(await status('d20'), 'completed');
      expect(await status('d21'), 'planned');
    });
  });

  group('activity identity', () {
    test(
      'a scored activity is linked and cannot complete a second session',
      () async {
        await plan('first', DateTime(2026, 10, 20), 'running');
        await plan('second', DateTime(2026, 10, 20), 'running');
        final run = await activity('r', DateTime(2026, 10, 20, 9), 'running');
        expect(await scorer.score(run), isTrue);
        final linked = (await db.select(db.sessionActuals).get()).single;
        expect(linked.activityId, 'r');
        // Syncing it again, however often, completes nothing else.
        expect(await scorer.score(run), isFalse);
        expect(await scorer.scoreIfUnscored(run), isFalse);
        expect(await db.select(db.sessionActuals).get(), hasLength(1));
        // A different activity still can.
        final other = await activity(
          'o',
          DateTime(2026, 10, 20, 18),
          'running',
        );
        expect(await scorer.score(other), isTrue);
        expect(await db.select(db.sessionActuals).get(), hasLength(2));
      },
    );

    test('the database refuses one activity on two sessions', () async {
      await plan('a', DateTime(2026, 10, 20), 'running');
      await plan('b', DateTime(2026, 10, 21), 'running');
      Future<void> link(String session) => db
          .into(db.sessionActuals)
          .insert(
            SessionActualsCompanion.insert(
              sessionId: session,
              activityId: const Value('same'),
            ),
          );
      await link('a');
      await expectLater(link('b'), throwsA(isA<Object>()));
      // Skips and old completions carry no link and do not clash.
      await db
          .into(db.sessionActuals)
          .insert(SessionActualsCompanion.insert(sessionId: 'x'));
      await db
          .into(db.sessionActuals)
          .insert(SessionActualsCompanion.insert(sessionId: 'y'));
    });

    test(
      'old completions are linked only when the activity is certain',
      () async {
        final start = DateTime(2026, 10, 20, 9);
        await activity('only', start, 'running');
        await activity('twin-1', DateTime(2026, 10, 21, 9), 'running');
        await activity('twin-2', DateTime(2026, 10, 21, 9), 'running');
        Future<void> actual(String id, DateTime? at) => db
            .into(db.sessionActuals)
            .insert(
              SessionActualsCompanion.insert(
                sessionId: id,
                startedAt: Value(at),
              ),
            );
        await actual('certain', start);
        await actual('ambiguous', DateTime(2026, 10, 21, 9));
        await actual('unknown', null);
        await actual('nothing', DateTime(2026, 10, 22, 9));
        expect(await scorer.linkExistingCompletions(), 1);
        Future<String?> link(String id) async => (await (db.select(
          db.sessionActuals,
        )..where((t) => t.sessionId.equals(id))).getSingle()).activityId;
        expect(await link('certain'), 'only');
        expect(await link('ambiguous'), isNull);
        expect(await link('unknown'), isNull);
        expect(await link('nothing'), isNull);
        expect(await scorer.linkExistingCompletions(), 0);
      },
    );
  });

  group('repair', () {
    test('a completion on the wrong day is undone and closed', () async {
      await plan(
        'wrong',
        DateTime(2026, 10, 21),
        'running',
        status: 'completed',
      );
      await db
          .into(db.sessionActuals)
          .insert(
            SessionActualsCompanion.insert(
              sessionId: 'wrong',
              startedAt: Value(DateTime(2026, 10, 20, 14)),
              completedAt: Value(DateTime(2026, 10, 20, 15)),
              executionScore: const Value(41),
            ),
          );
      await plan(
        'right',
        DateTime(2026, 10, 20),
        'running',
        status: 'completed',
      );
      await db
          .into(db.sessionActuals)
          .insert(
            SessionActualsCompanion.insert(
              sessionId: 'right',
              startedAt: Value(DateTime(2026, 10, 20, 14)),
              completedAt: Value(DateTime(2026, 10, 20, 15)),
            ),
          );
      expect(await scorer.repairMatches(), 1);
      expect(await status('right'), 'completed');
      // Nothing was done on the 21st; by now the session is closed.
      expect(await status('wrong'), 'skipped');
      final actual = await (db.select(
        db.sessionActuals,
      )..where((t) => t.sessionId.equals('wrong'))).getSingle();
      expect(actual.skipReason, 'No matching activity');
      expect(actual.executionScore, isNull);
      // A second run changes nothing.
      expect(await scorer.repairMatches(), 0);
    });

    test('a reset session takes the activity of its own day', () async {
      await plan(
        'wrong',
        DateTime(2026, 10, 21),
        'running',
        status: 'completed',
      );
      await db
          .into(db.sessionActuals)
          .insert(
            SessionActualsCompanion.insert(
              sessionId: 'wrong',
              startedAt: Value(DateTime(2026, 10, 20, 14)),
              completedAt: Value(DateTime(2026, 10, 20, 15)),
            ),
          );
      await activity('own', DateTime(2026, 10, 21, 9), 'running');
      expect(await scorer.repairMatches(), 1);
      expect(await status('wrong'), 'completed');
      final actual = await (db.select(
        db.sessionActuals,
      )..where((t) => t.sessionId.equals('wrong'))).getSingle();
      expect(actual.startedAt, DateTime(2026, 10, 21, 9));
    });

    test('yesterday and later stay open, older sessions close', () async {
      await plan('old', DateTime(2026, 9, 10), 'running');
      await plan('yesterday', DateTime(2026, 10, 23), 'running');
      await plan('today', DateTime(2026, 10, 24), 'running');
      final closed = await scorer.closePastSessions(
        now: DateTime(2026, 10, 24),
      );
      expect(closed, 1);
      expect(await status('old'), 'skipped');
      expect(await status('yesterday'), 'planned');
      expect(await status('today'), 'planned');
    });
  });
}
