import 'dart:convert';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/strength_workout.dart';
import 'package:fjelia/services/morning_revision.dart';
import 'package:fjelia/services/strength/strength_repository.dart';
import 'package:fjelia/services/workout_semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> step(String type, int seconds, int zone) => {
  'type': 'ExecutableStepDTO',
  'stepType': {'stepTypeKey': type},
  'endCondition': {'conditionTypeKey': 'time'},
  'endConditionValue': seconds,
  'zoneNumber': zone,
};

Map<String, dynamic> repeat(int n, List<Map<String, dynamic>> steps) => {
  'type': 'RepeatGroupDTO',
  'stepType': {'stepTypeKey': 'repeat'},
  'numberOfIterations': n,
  'endConditionValue': n,
  'workoutSteps': steps,
};

// Tuesday 10 November 2026; the week runs Monday 9 to Sunday 15.
final tue = DateTime(2026, 11, 10);
DateTime on(int weekday) => DateTime(2026, 11, 9 + weekday - 1);

TrainingSession s(
  String id,
  DateTime day, {
  String sport = 'running',
  String type = 'endurance',
  int zone = 2,
  int minutes = 60,
  String? steps,
}) => TrainingSession(
  id: id,
  planId: 'p',
  athleteId: 'self',
  sessionDate: day,
  sessionNumber: 1,
  weekNumber: 1,
  sport: sport,
  sessionType: type,
  phase: 'base',
  primaryZone: zone,
  title: '$id ($minutes min)',
  tspAdjusted: false,
  plannedDurationMin: minutes,
  plannedTrimp: 60,
  sessionLevel: 5,
  status: 'planned',
  warmUpCompletionPct: 0,
  mainSetCompletionPct: 0,
  createdByCoach: false,
  adjustedByCoach: false,
  addedByAthlete: false,
  historical: false,
  indoor: false,
  locked: false,
  isMovedFromDifferentWeek: false,
  stepsJson: steps,
);

final intervals = jsonEncode([
  step('warmup', 900, 1),
  repeat(5, [step('interval', 240, 4), step('recovery', 180, 1)]),
  step('cooldown', 600, 1),
]);

const squat = StrengthPlannedExercise(
  id: 'squat',
  variantId: 'squat',
  name: 'Leg press',
  equipment: 'Machine',
  sets: [
    StrengthSetTarget(id: 'sq-w', kind: StrengthSetKind.warmup, reps: 10),
    StrengthSetTarget(id: 'sq-1', reps: 8, load: StrengthLoad(100)),
    StrengthSetTarget(id: 'sq-2', reps: 8, load: StrengthLoad(100)),
    StrengthSetTarget(id: 'sq-3', reps: 8, load: StrengthLoad(100)),
  ],
);
const plank = StrengthPlannedExercise(
  id: 'plank',
  variantId: 'plank',
  name: 'Plank',
  equipment: 'Bodyweight',
  convention: StrengthConvention(loadKind: StrengthLoadKind.bodyweight),
  sets: [
    StrengthSetTarget(id: 'pl-1', durationSeconds: 45),
    StrengthSetTarget(id: 'pl-2', durationSeconds: 45),
  ],
);
const strengthPlan = StrengthWorkoutPlan(
  blocks: [
    StrengthBlock(id: 'b1', exercises: [squat]),
    StrengthBlock(id: 'b2', exercises: [plank]),
  ],
);

RevisionContext ctx(
  List<TrainingSession> week, {
  List<int> rest = const [],
  List<int> strengthDays = const [],
  int maxPerDay = 1,
  Map<String, StoredStrengthPlan> plans = const {},
}) => RevisionContext(
  day: tue,
  week: week,
  restWeekdays: rest,
  strengthWeekdays: strengthDays,
  maxPerDay: maxPerDay,
  strengthPlans: plans,
);

MorningRevision rev(List<RevisionChange> changes) => MorningRevision(
  title: 'Easier today',
  body: 'HRV is low.',
  changes: changes,
);

RevisionItem st(String type, double min, int zone) =>
    RevisionItem.step(RevisionStep(type: type, minutes: min, zone: zone));

void main() {
  test('the coach answer is read, anything else is refused', () {
    final r = parseMorningRevision('''
Here you go:
{"version":1,"title":"Shorter intervals today","body":"HRV is below your usual level.",
 "changes":[{"op":"revise","session":"t","steps":[
   {"type":"warmup","min":15,"zone":1},
   {"repeat":3,"steps":[{"type":"interval","min":4,"zone":4},{"type":"recovery","min":3,"zone":1}]},
   {"type":"cooldown","min":10,"zone":1}]},
  {"op":"swap","session":"x","with":"y"}]}''');
    expect(r?.title, 'Shorter intervals today');
    expect(r?.changes.first.steps, hasLength(3));
    expect(r?.changes.first.steps![1].repeat, 3);
    expect(r?.changes.last.op, RevisionOp.swap);
    expect(parseMorningRevision('no json'), isNull);
    expect(
      parseMorningRevision(
        '{"version":1,"title":"t","body":"b","changes":[{"op":"move"}]}',
      ),
      isNull,
    );
  });

  group('endurance', () {
    final today = s(
      't',
      tue,
      type: 'key',
      zone: 4,
      minutes: 60,
      steps: intervals,
    );
    final week = [today, s('thu', on(4), minutes: 45)];

    test('fewer repetitions pass and are written as steps', () {
      final r = rev([
        RevisionChange(
          op: RevisionOp.revise,
          sessionId: 't',
          steps: [
            st('warmup', 15, 1),
            RevisionItem.repeat(3, const [
              RevisionStep(type: 'interval', minutes: 4, zone: 4),
              RevisionStep(type: 'recovery', minutes: 3, zone: 1),
            ]),
            st('cooldown', 10, 1),
          ],
        ),
      ]);
      expect(revisionProblem(r, ctx(week)), isNull);
      final w = WorkoutSemantics.of(revisionStepsJson(r.changes.first.steps!));
      expect(w.totalMinutes, 46);
    });

    test('longer or harder is refused', () {
      RevisionChange steps(List<RevisionItem> items) =>
          RevisionChange(op: RevisionOp.revise, sessionId: 't', steps: items);
      expect(
        revisionProblem(
          rev([
            steps([st('interval', 80, 2)]),
          ]),
          ctx(week),
        ),
        'longer',
      );
      expect(
        revisionProblem(
          rev([
            steps([st('interval', 40, 5)]),
          ]),
          ctx(week),
        ),
        'harder zone',
      );
      // Only today's sessions may change.
      expect(
        revisionProblem(
          rev([
            RevisionChange(
              op: RevisionOp.revise,
              sessionId: 'thu',
              steps: [st('interval', 30, 1)],
            ),
          ]),
          ctx(week),
        ),
        'not the day or the next thu',
      );
    });
  });

  group('swaps follow Settings → Training', () {
    final hard = s('t', tue, type: 'key', zone: 4);
    final easyThu = s('thu', on(4), minutes: 40);
    MorningRevision swapToday() => rev([
      const RevisionChange(op: RevisionOp.swap, sessionId: 't', withId: 'thu'),
    ]);

    test('an easier session of a later day may come today', () {
      expect(revisionProblem(swapToday(), ctx([hard, easyThu])), isNull);
    });

    test('not onto a rest weekday', () {
      expect(
        revisionProblem(swapToday(), ctx([hard, easyThu], rest: [4])),
        'onto a rest day',
      );
    });

    test('never a harder session today', () {
      final r = rev([
        const RevisionChange(op: RevisionOp.swap, sessionId: 'e', withId: 'k'),
      ]);
      expect(
        revisionProblem(
          r,
          ctx([s('e', tue), s('k', on(5), type: 'key', zone: 4)]),
        ),
        'swap brings a harder session earlier',
      );
    });

    test('no new pair of hard days in a row', () {
      // The hard session moves to Thursday, next to Friday's.
      expect(
        revisionProblem(
          swapToday(),
          ctx([hard, easyThu, s('fri', on(5), type: 'key', zone: 4)]),
        ),
        'hard back to back',
      );
    });

    test('strength only onto strength days', () {
      final r = rev([
        const RevisionChange(op: RevisionOp.swap, sessionId: 'g', withId: 'e'),
      ]);
      expect(
        revisionProblem(
          r,
          ctx(
            [s('g', tue, sport: 'strength'), s('e', on(4), minutes: 30)],
            strengthDays: [2, 5],
          ),
        ),
        'strength off its days',
      );
    });
  });

  group('strength, with and without machines', () {
    late AppDatabase db;
    late StrengthRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = StrengthRepository(db);
    });
    tearDown(() => db.close());

    test('fewer sets and a lighter load, equipment as planned', () async {
      final g = s('g', tue, sport: 'strength', minutes: 45);
      await db.into(db.trainingSessions).insert(g.toCompanion(false));
      final stored = await repo.savePlan(
        StrengthPlanOwner.session('g'),
        strengthPlan,
        expectedRevision: 0,
      );
      final c = ctx([g], plans: {'g': stored});
      final r = rev([
        const RevisionChange(
          op: RevisionOp.revise,
          sessionId: 'g',
          exercises: [
            RevisionExercise(id: 'squat', sets: 2, loadPercent: 80),
            RevisionExercise(id: 'plank', sets: 1),
          ],
        ),
      ]);
      expect(revisionProblem(r, c), isNull);
      final input = jsonDecode(revisionInputJson(c)) as Map;
      final exercises = (input['day_sessions'] as List).single['exercises'];
      expect(exercises.first['equipment'], 'Machine');
      expect(exercises.first['working_sets'], 3);

      await applyMorningRevision(db, repo, r, c);
      final after = (await repo.loadPlan(StrengthPlanOwner.session('g')))!;
      expect(after.revision, 2);
      final press = after.plan.blocks.first.exercises.single;
      expect(press.equipment, 'Machine');
      // The warm-up stays, two of three working sets at 80 %.
      expect(press.sets.map((x) => x.kind), [
        StrengthSetKind.warmup,
        StrengthSetKind.working,
        StrengthSetKind.working,
      ]);
      expect(press.sets.last.load?.kg, 80);
      expect(after.plan.blocks.last.exercises.single.sets, hasLength(1));
      final row = await (db.select(
        db.trainingSessions,
      )..where((t) => t.id.equals('g'))).getSingle();
      expect(row.status, 'adapted');
    });

    test('more sets or reps than planned are refused', () async {
      final g = s('g', tue, sport: 'strength');
      final stored = StoredStrengthPlan(
        owner: StrengthPlanOwner.session('g'),
        revisionId: 'r1',
        revision: 1,
        plan: strengthPlan,
      );
      final c = ctx([g], plans: {'g': stored});
      expect(
        revisionProblem(
          rev([
            const RevisionChange(
              op: RevisionOp.revise,
              sessionId: 'g',
              exercises: [RevisionExercise(id: 'squat', sets: 4)],
            ),
          ]),
          c,
        ),
        'more sets',
      );
      expect(
        revisionProblem(
          rev([
            const RevisionChange(
              op: RevisionOp.revise,
              sessionId: 'g',
              exercises: [RevisionExercise(id: 'squat', reps: 12)],
            ),
          ]),
          c,
        ),
        'more reps',
      );
    });
  });

  test('a swap exchanges the days', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final hard = s('t', tue, type: 'key', zone: 4);
    final easy = s('thu', on(4), minutes: 40);
    for (final x in [hard, easy]) {
      await db.into(db.trainingSessions).insert(x.toCompanion(false));
    }
    await applyMorningRevision(
      db,
      StrengthRepository(db),
      rev([
        const RevisionChange(
          op: RevisionOp.swap,
          sessionId: 't',
          withId: 'thu',
        ),
      ]),
      ctx([hard, easy]),
    );
    final rows = {
      for (final r in await db.select(db.trainingSessions).get())
        r.id: r.sessionDate,
    };
    expect(rows['t'], on(4));
    expect(rows['thu'], tue);
  });

  test('every session of the day with a reason, and a swap as alternative', () {
    final hard = s('t', tue, type: 'key', zone: 4, steps: intervals);
    final gym = s('g', tue, sport: 'strength', minutes: 45);
    final easy = s('thu', on(4), minutes: 40);
    final c = ctx([hard, gym, easy], maxPerDay: 2);
    final raw = jsonEncode({
      'version': 1,
      'title': 'Shorter run tomorrow',
      'body': 'HRV is low.',
      'changes': [
        {
          'op': 'revise',
          'session': 't',
          'steps': [
            {'type': 'warmup', 'min': 15, 'zone': 1},
            {'type': 'interval', 'min': 20, 'zone': 2},
            {'type': 'cooldown', 'min': 10, 'zone': 1},
          ],
          'why': 'Easy instead of intervals.',
        },
        {'op': 'keep', 'session': 'g', 'why': 'Strength is light enough.'},
      ],
      'alternative': {
        'title': 'Swap with Thursday',
        'body': 'Easy run tomorrow, intervals on Thursday.',
        'changes': [
          {'op': 'swap', 'session': 't', 'with': 'thu', 'why': 'x'},
          {'op': 'keep', 'session': 'g', 'why': 'y'},
        ],
      },
    });
    final r = parseMorningRevision(raw)!;
    expect(r.changes.last.op, RevisionOp.keep);
    expect(r.changes.last.why, 'Strength is light enough.');
    final checked = checkedRevision(r, c)!;
    expect(checked.alternative?.changes.first.op, RevisionOp.swap);
    // Thursday a rest day: the alternative goes, the main proposal stays.
    final restThu = ctx([hard, gym, easy], maxPerDay: 2, rest: [4]);
    final noAlt = checkedRevision(r, restThu)!;
    expect(noAlt.alternative, isNull);
    expect(noAlt.changes, hasLength(2));
    // Keeping everything is no proposal.
    expect(
      revisionProblem(
        rev([const RevisionChange(op: RevisionOp.keep, sessionId: 't')]),
        c,
      ),
      'change count',
    );
  });

  test('the question names the day and the calendar\'s today', () {
    final c = RevisionContext(
      day: tue,
      week: [s('t', tue)],
      restWeekdays: const [],
      strengthWeekdays: const [],
      maxPerDay: 1,
      today: DateTime(2026, 11, 9),
    );
    final q = jsonDecode(revisionInputJson(c)) as Map;
    expect(q['day'], '2026-11-10');
    expect(q['today'], '2026-11-09');
    expect(q['day_is_today'], isFalse);
  });

  test('a "keep" about a session that is not the day\'s is left out', () {
    final run = s('t', tue, type: 'key', zone: 4, steps: intervals);
    final done = s('mon', on(1)).copyWith(status: 'completed');
    final r = rev([
      RevisionChange(
        op: RevisionOp.revise,
        sessionId: 't',
        steps: [
          st('warmup', 10, 1),
          st('interval', 30, 2),
          st('cooldown', 10, 1),
        ],
      ),
      const RevisionChange(op: RevisionOp.keep, sessionId: 'mon'),
      const RevisionChange(op: RevisionOp.keep, sessionId: 'nowhere'),
    ]);
    final checked = checkedRevision(r, ctx([done, run]));
    expect(checked, isNotNull);
    expect(checked!.changes.map((x) => x.sessionId), ['t']);
  });

  test('the next day may be reworked too; a locked session never', () {
    final run = s('t', tue, type: 'key', zone: 4, steps: intervals);
    final long = s('w', on(3), type: 'long', minutes: 120);
    final c = ctx([run, long]);
    final shorter = rev([
      RevisionChange(
        op: RevisionOp.revise,
        sessionId: 'w',
        steps: [
          st('warmup', 10, 1),
          st('interval', 70, 2),
          st('cooldown', 10, 1),
        ],
      ),
    ]);
    expect(revisionProblem(shorter, c), isNull);
    final q = jsonDecode(revisionInputJson(c)) as Map;
    expect((q['next_day_sessions'] as List).single['id'], 'w');
    expect(q['week'], isEmpty);
    final locked = ctx([run, long.copyWith(locked: true)]);
    expect(revisionProblem(shorter, locked), 'locked w');
  });
}
