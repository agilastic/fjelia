import 'dart:convert';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/plan_rebalance.dart';
import 'package:fjelia/services/plan_rebalance_applier.dart';
import 'package:fjelia/services/plan_session_actions.dart';
import 'package:fjelia/services/season/goal_set.dart' show DayLoad;
import 'package:fjelia/services/session_adaptation_service.dart';
import 'package:fjelia/services/workout_providers/workout_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../providers/upcoming_done_test.dart' show session;

void main() {
  // Monday.
  final today = DateTime(2026, 11, 2);
  DateTime day(int i) => DateTime(today.year, today.month, today.day + i);
  final missed = session('missed', today, minutes: 90); // long, hard
  final tueKey = session(
    'tue',
    day(1),
    minutes: 60,
  ).copyWith(sessionType: 'key', primaryZone: 4);
  final thuEasy = session(
    'thu',
    day(3),
    minutes: 40,
  ).copyWith(sessionType: 'recovery', primaryZone: 1);

  RebalanceContext ctx({
    List<TrainingSession>? upcoming,
    DayLoad Function(DateTime)? load,
    bool Function(DateTime)? rain,
  }) => RebalanceContext(
    missed: missed,
    upcoming: upcoming ?? [tueKey, thuEasy],
    today: today,
    dayLoad: load,
    rainyOn: rain,
  );

  String iso(DateTime d) => d.toIso8601String().substring(0, 10);
  RebalanceProposal p(List<Map<String, Object?>> changes) => parseRebalance(
    jsonEncode({'version': 1, 'summary': 'ok', 'changes': changes}),
  )!;

  group('parse', () {
    test('reads the contract, also wrapped in text', () {
      final r = parseRebalance(
        'Here: {"version":1,"summary":"Wed it is.","changes":['
        '{"op":"move","session":"missed","to":"${iso(day(2))}",'
        '"indoor":true,"duration_min":75,"intensity":"easier"}]} done',
      )!;
      final x = r.changes.single;
      expect(x.op, RebalanceOp.move);
      expect(x.to, day(2));
      expect(x.indoor, isTrue);
      expect(x.durationMin, 75);
      expect(x.intensity, RebalanceIntensity.easier);
      expect(r.summary, 'Wed it is.');
      expect(r.fromCoach, isTrue);
    });

    test('anything else is refused', () {
      expect(parseRebalance('Move it to Wednesday.'), isNull);
      expect(parseRebalance('{"version":2,"changes":[]}'), isNull);
      expect(
        parseRebalance(
          '{"version":1,"changes":[{"op":"swap","session":"missed"}]}',
        ),
        isNull,
      );
      expect(
        parseRebalance(
          '{"version":1,"changes":[{"op":"move","session":"missed"}]}',
        ),
        isNull,
      );
      expect(
        parseRebalance(
          '{"version":1,"changes":[{"op":"adjust","session":"tue",'
          '"intensity":"harder"}]}',
        ),
        isNull,
      );
    });
  });

  group('guardrails', () {
    test('a sound rebalance passes', () {
      // Wednesday follows the hard Tuesday, so Tuesday gets easier.
      final r = p([
        {'op': 'move', 'session': 'missed', 'to': iso(day(2))},
        {'op': 'adjust', 'session': 'tue', 'intensity': 'easier'},
        {'op': 'adjust', 'session': 'thu', 'duration_min': 30},
      ]);
      expect(rebalanceProblem(r, ctx()), isNull);
    });

    test('the missed session must be moved or dropped', () {
      expect(
        rebalanceProblem(
          p([
            {'op': 'drop', 'session': 'tue'},
          ]),
          ctx(),
        ),
        'missed not handled',
      );
    });

    test('unknown ids, dates outside the window and longer are refused', () {
      expect(
        rebalanceProblem(
          p([
            {'op': 'drop', 'session': 'ghost'},
          ]),
          ctx(),
        ),
        startsWith('unknown session'),
      );
      expect(
        rebalanceProblem(
          p([
            {'op': 'move', 'session': 'missed', 'to': iso(day(6))},
          ]),
          ctx(),
        ),
        'date outside window',
      );
      expect(
        rebalanceProblem(
          p([
            {'op': 'move', 'session': 'missed', 'to': iso(day(2))},
            {'op': 'adjust', 'session': 'thu', 'duration_min': 90},
          ]),
          ctx(),
        ),
        'duration out of range',
      );
    });

    test('two hard sessions on one day or back to back are refused', () {
      expect(
        rebalanceProblem(
          p([
            {'op': 'move', 'session': 'missed', 'to': iso(day(1))},
          ]),
          ctx(),
        ),
        anyOf('too many on ${iso(day(1))}', 'two hard on ${iso(day(1))}'),
      );
      // Wednesday after the hard Tuesday: new back-to-back pair.
      final noTue = ctx(upcoming: [tueKey]);
      expect(
        rebalanceProblem(
          p([
            {'op': 'move', 'session': 'missed', 'to': iso(day(2))},
          ]),
          noTue,
        ),
        'hard back to back',
      );
      // Easing Tuesday makes the same move fine.
      expect(
        rebalanceProblem(
          p([
            {'op': 'move', 'session': 'missed', 'to': iso(day(2))},
            {'op': 'adjust', 'session': 'tue', 'intensity': 'easier'},
          ]),
          noTue,
        ),
        isNull,
      );
    });

    test('a day that is already overloaded does not block a drop', () {
      // Tuesday already holds two hard sessions in the plan itself.
      final c = ctx(
        upcoming: [
          tueKey,
          tueKey.copyWith(id: 'tue2', sessionType: 'long', primaryZone: 2),
        ],
      );
      expect(
        rebalanceProblem(
          p([
            {'op': 'drop', 'session': 'missed'},
          ]),
          c,
        ),
        isNull,
      );
      // Adding to it is still refused.
      expect(
        rebalanceProblem(
          p([
            {'op': 'move', 'session': 'missed', 'to': iso(day(1))},
          ]),
          ctx(
            upcoming: [
              tueKey,
              tueKey.copyWith(id: 'tue2', sessionType: 'long', primaryZone: 2),
            ],
          ),
        ),
        isNotNull,
      );
    });

    test('race and taper days are respected', () {
      final c = ctx(load: (d) => d == day(2) ? DayLoad.easyOnly : DayLoad.free);
      expect(
        rebalanceProblem(
          p([
            {'op': 'move', 'session': 'missed', 'to': iso(day(2))},
          ]),
          c,
        ),
        'hard on easy-only day',
      );
    });

    test('indoor only for sports that have an indoor form', () {
      final swim = RebalanceContext(
        missed: missed.copyWith(sport: 'swimming'),
        upcoming: const [],
        today: today,
      );
      expect(
        rebalanceProblem(
          p([
            {
              'op': 'move',
              'session': 'missed',
              'to': iso(day(2)),
              'indoor': true,
            },
          ]),
          swim,
        ),
        'no indoor form',
      );
    });
  });

  test('the rules move a hard session indoors on a rainy free day', () {
    final c = ctx(upcoming: const [], rain: (d) => d == day(1));
    final r = rulesRebalance(c);
    final x = r.changes.single;
    expect(x.op, RebalanceOp.move);
    expect(x.to, day(1));
    expect(x.indoor, isTrue);
    expect(rebalanceProblem(r, c), isNull);
  });

  test('next to a hard day the rules move it a bit easier', () {
    // Tuesday is hard, Thursday full: only Wednesday is left, after Tuesday.
    final c = ctx();
    final r = rulesRebalance(c);
    final x = r.changes.single;
    expect(x.op, RebalanceOp.move);
    expect(x.to, day(2));
    expect(x.intensity, RebalanceIntensity.easier);
    expect(rebalanceProblem(r, c), isNull);
  });

  test('an easy missed session is dropped by the rules', () {
    final c = RebalanceContext(
      missed: thuEasy.copyWith(id: 'missed', sessionDate: today),
      upcoming: const [],
      today: today,
    );
    expect(rulesRebalance(c).changes.single.op, RebalanceOp.drop);
  });

  test('the preview shows what moves in and what gets shorter', () {
    final days = previewRebalance(
      p([
        {'op': 'move', 'session': 'missed', 'to': iso(day(2))},
        {'op': 'adjust', 'session': 'thu', 'duration_min': 30},
      ]),
      ctx(),
    );
    expect(days, hasLength(4));
    expect(days[0].items.single.kind, PreviewKind.missed);
    expect(days[2].items.single.kind, PreviewKind.movedIn);
    final thu = days[3].items.single;
    expect(thu.kind, PreviewKind.adjusted);
    expect(thu.minutesBefore, 40);
    expect(thu.minutes, 30);
  });

  test('the input lists the window and the limits', () {
    final j = jsonDecode(rebalanceInputJson(ctx())) as Map;
    expect(j['missed']['id'], 'missed');
    expect((j['days'] as List).length, 3);
    expect(j['rules']['never_longer_or_harder'], isTrue);
  });

  group('apply and undo', () {
    late AppDatabase db;
    late PlanRebalanceApplier applier;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      applier = PlanRebalanceApplier(
        db,
        PlanSessionActions(db, WorkoutProviders(const [])),
        SessionAdaptationService(db),
      );
      await db
          .into(db.trainingPlans)
          .insert(
            TrainingPlansCompanion.insert(
              id: 'p',
              athleteId: 'self',
              startDate: day(-7),
              endDate: day(30),
              status: 'active',
              generatedAt: day(-7),
            ),
          );
      for (final s in [missed, tueKey, thuEasy]) {
        await db.into(db.trainingSessions).insert(s);
      }
    });
    tearDown(() => db.close());

    Future<TrainingSession> read(String id) => (db.select(
      db.trainingSessions,
    )..where((t) => t.id.equals(id))).getSingle();

    test('moves, shortens and drops, then puts everything back', () async {
      final undo = await applier.apply(
        p([
          {'op': 'move', 'session': 'missed', 'to': iso(day(2))},
          {'op': 'adjust', 'session': 'thu', 'duration_min': 30},
          {'op': 'drop', 'session': 'tue'},
        ]),
        missedId: 'missed',
      );
      expect((await read('missed')).sessionDate, day(2));
      expect((await read('thu')).plannedDurationMin, 30);
      expect((await read('thu')).status, 'adapted');
      expect((await read('tue')).status, 'skipped');

      await applier.undo(undo);
      expect((await read('missed')).sessionDate, today);
      expect((await read('thu')).plannedDurationMin, 40);
      expect((await read('thu')).status, 'planned');
      expect((await read('tue')).status, 'planned');
    });
  });
}
