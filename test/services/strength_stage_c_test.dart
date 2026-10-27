import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/strength_workout.dart';
import 'package:fjelia/services/post_workout_scorer.dart';
import 'package:fjelia/services/strength/strength_estimates.dart';
import 'package:fjelia/services/strength/strength_focus.dart';
import 'package:fjelia/services/strength/strength_repository.dart';
import 'package:fjelia/services/strength/strength_statistics.dart';
import 'package:fjelia/services/strength/strength_templates.dart';
import 'package:flutter_test/flutter_test.dart';

StrengthSetResult _set(
  int? reps,
  double? kg, {
  StrengthSetStatus status = StrengthSetStatus.completed,
  StrengthSetKind kind = StrengthSetKind.working,
  int? seconds,
}) => StrengthSetResult(
  id: 's${reps}_$kg',
  status: status,
  kind: kind,
  reps: reps,
  durationSeconds: seconds,
  load: kg == null ? null : StrengthLoad(kg),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const barbell = StrengthConvention();

  group('C2 estimated 1RM', () {
    test('named formulas give a range; one rep is the lift itself', () {
      final five = estimateOneRm(_set(5, 100), barbell)!;
      expect(five.lowKg, closeTo(112.5, 1e-9), reason: 'Brzycki');
      expect(five.highKg, closeTo(116.667, 1e-3), reason: 'Epley');
      expect(
        oneRmText(five, MassUnit.kg),
        '≈ 112.5–116.7 kg (Epley–Brzycki, from 5 × 100 kg)',
      );
      final single = estimateOneRm(_set(1, 140), barbell)!;
      expect(single.measured, isTrue);
      expect(single.highKg, 140);
    });

    test('only eligible sets are estimated', () {
      for (final (why, set, c) in [
        ('warm-up', _set(5, 60, kind: StrengthSetKind.warmup), barbell),
        ('technique', _set(5, 60, kind: StrengthSetKind.technique), barbell),
        ('failed', _set(5, 100, status: StrengthSetStatus.failed), barbell),
        ('partial', _set(5, 100, status: StrengthSetStatus.partial), barbell),
        ('over 10 reps', _set(11, 60), barbell),
        ('zero reps', _set(0, 60), barbell),
        ('unknown load', _set(5, null), barbell),
        ('timed', _set(null, 20, seconds: 60), barbell),
        (
          'bodyweight',
          _set(10, null),
          const StrengthConvention(loadKind: StrengthLoadKind.bodyweight),
        ),
        (
          'added load',
          _set(5, 20),
          const StrengthConvention(loadKind: StrengthLoadKind.added),
        ),
        (
          'assisted',
          _set(5, 20),
          const StrengthConvention(loadKind: StrengthLoadKind.assisted),
        ),
      ]) {
        expect(estimateOneRm(set, c), isNull, reason: why);
      }
    });

    test('trend: top load and best estimate per session, oldest first', () {
      final t = strengthTrend([
        StrengthHistoryEntry(
          activityId: 'b',
          date: DateTime(2026, 10, 25),
          source: null,
          stale: false,
          sets: [
            _set(5, 100),
            _set(5, 102.5),
            _set(3, 105, status: StrengthSetStatus.failed),
          ],
        ),
        StrengthHistoryEntry(
          activityId: 'a',
          date: DateTime(2026, 10, 20),
          source: null,
          stale: false,
          sets: [_set(8, 90)],
        ),
      ], barbell);
      expect(t.map((p) => p.activityId), ['a', 'b']);
      expect(t.last.topLoadKg, 102.5, reason: 'failed sets do not count');
      expect(t.last.oneRm!.loadKg, 102.5);
      expect(t.last.completedSets, 2);
    });
  });

  group('C1 gym mode order and recording', () {
    test('straight sets in order, circuits round by round, no final rest', () {
      final plan = bundledStrengthTemplates.last.build(); // core circuit
      final log = StrengthActivityLog(
        activityId: 'x',
        baseline: StrengthPlanBaseline(
          ownerKind: 'session',
          ownerKey: 's',
          revisionId: 'r',
          plan: plan,
        ),
        exercises: logLayoutFromPlan(plan),
      );
      final order = strengthFocusOrder(log);
      expect(order.length, 12);
      expect(order.take(5).map((o) => o.exercise.name), [
        'Plank',
        'Dead bug',
        'Bird dog',
        'Pallof press',
        'Plank',
      ]);
      expect(order.take(4).map((o) => o.restAfter), [15, 15, 15, 60]);
      expect(order.last.restAfter, isNull);
      expect(strengthFocusStart(order), 0);

      final full = bundledStrengthTemplates.first.build();
      final straight = strengthFocusOrder(
        StrengthActivityLog(
          activityId: 'y',
          baseline: StrengthPlanBaseline(
            ownerKind: 'session',
            ownerKey: 's',
            revisionId: 'r',
            plan: full,
          ),
          exercises: logLayoutFromPlan(full),
        ),
      );
      expect(straight.take(4).map((o) => o.exercise.name), [
        'Back squat',
        'Back squat',
        'Back squat',
        'Deadlift',
      ]);
      expect(straight.first.restAfter, 120);
    });

    test('done needs reps; skipped holds nothing', () {
      const open = StrengthSetResult(id: 'a');
      expect(
        () => recordFocusSet(open, StrengthSetStatus.completed),
        throwsA(isA<StrengthValidationException>()),
      );
      final done = recordFocusSet(
        open,
        StrengthSetStatus.completed,
        reps: 8,
        load: const StrengthLoad(70),
      );
      expect(done.reps, 8);
      expect(done.origins['reps'], StrengthOrigin.manual);
      final skipped = recordFocusSet(
        open,
        StrengthSetStatus.skipped,
        reps: 8,
        load: const StrengthLoad(70),
      );
      expect(skipped.reps, isNull);
      expect(skipped.load, isNull);
      final failed = recordFocusSet(open, StrengthSetStatus.failed, reps: 0);
      expect(failed.reps, 0, reason: 'zero achieved reps is a fact');
    });

    test('timed rest is measured rest and counts in the average', () {
      final rested = withTimedRest(
        const StrengthSetResult(
          id: 'a',
          status: StrengthSetStatus.completed,
          reps: 5,
        ),
        const Duration(seconds: 95),
      );
      expect(rested.restSeconds, 95);
      expect(rested.restOrigin, StrengthOrigin.timer);
      final s = summariseLog(
        StrengthActivityLog(
          activityId: 'x',
          exercises: [
            StrengthPerformedExercise(
              id: 'e',
              variantId: 'v',
              name: 'Squat',
              equipment: '',
              sets: [rested],
            ),
          ],
        ),
      );
      expect(s.restSeconds, 95);
      expect(s.restIntervals, 1);
    });
  });

  group('C1 live workouts in storage', () {
    late AppDatabase db;
    late StrengthRepository repo;
    final owner = StrengthPlanOwner.session('s');
    final start = DateTime(2026, 10, 27, 18);

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = StrengthRepository(db);
      await db
          .into(db.trainingPlans)
          .insert(
            TrainingPlansCompanion.insert(
              id: 'p',
              athleteId: 'self',
              startDate: DateTime(2026, 10, 1),
              endDate: DateTime(2027, 1, 1),
              status: 'active',
              generatedAt: DateTime(2026, 10, 1),
            ),
          );
      await db
          .into(db.trainingSessions)
          .insert(
            TrainingSessionsCompanion.insert(
              id: 's',
              planId: 'p',
              athleteId: 'self',
              sessionDate: DateTime(2026, 10, 27),
              sessionNumber: 1,
              weekNumber: 1,
              sport: 'strength',
              sessionType: 'key',
              phase: 'base',
              primaryZone: 3,
              title: 'Strength',
              plannedDurationMin: 55,
              plannedTrimp: 50,
              sessionLevel: 2,
            ),
          );
    });
    tearDown(() => db.close());

    Future<StrengthActivityLog> started() async {
      final stored = await repo.savePlan(
        owner,
        bundledStrengthTemplates.first.build(),
        expectedRevision: 0,
      );
      return repo.startLiveSession(
        stored: stored,
        title: 'Strength',
        now: start,
      );
    }

    Future<StrengthActivityLog> doFirstSet(StrengthActivityLog live) {
      final first = live.exercises.first.sets.first;
      return repo.saveLog(
        live.copyWith(
          exercises: [
            live.exercises.first.copyWith(
              sets: [
                recordFocusSet(
                  first,
                  StrengthSetStatus.completed,
                  reps: 10,
                  load: const StrengthLoad(60),
                ),
                ...live.exercises.first.sets.skip(1),
              ],
            ),
            ...live.exercises.skip(1),
          ],
        ),
      );
    }

    test('start, resume, finish completes the session explicitly', () async {
      final live = await started();
      final a = (await db.getActivityById(live.activityId))!;
      expect(a.source, StrengthRepository.liveSource);
      expect(a.durationSeconds, 0);
      expect(live.baseline?.retrospective, isFalse);
      expect((await repo.openLiveSession(owner))!.activityId, live.activityId);
      // An open workout completes nothing, even when a sync scores.
      expect(await PostWorkoutScorer(db).score(a), isFalse);
      await doFirstSet(live);
      await repo.finishLiveSession(
        live.activityId,
        sessionId: 's',
        now: start.add(const Duration(minutes: 50)),
      );
      expect(
        (await db.getActivityById(live.activityId))!.durationSeconds,
        3000,
      );
      final actual = await (db.select(db.sessionActuals)).getSingle();
      expect(actual.activityId, live.activityId);
      final s = await (db.select(db.trainingSessions)).getSingle();
      expect(s.status, 'completed');
      expect(s.actualDurationMin, 50);
      expect(await repo.openLiveSession(owner), isNull);
    });

    test('finish without completing leaves the session open', () async {
      final live = await started();
      await repo.finishLiveSession(
        live.activityId,
        now: start.add(const Duration(minutes: 30)),
      );
      expect(await db.select(db.sessionActuals).get(), isEmpty);
      expect(
        (await db.select(db.trainingSessions).getSingle()).status,
        'planned',
      );
    });

    test('discard removes the workout and its sets', () async {
      final live = await started();
      await repo.discardLiveSession(live.activityId);
      expect(await db.getActivityById(live.activityId), isNull);
      expect(await db.select(db.strengthPerformedSets).get(), isEmpty);
    });

    Future<void> watch(
      String id,
      DateTime from,
      int minutes, {
      String type = 'strength_training',
    }) => db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: id,
            name: 'Strength',
            type: type,
            startDate: from,
            durationSeconds: minutes * 60,
            source: const Value('garmin_api'),
          ),
        );

    test('the watch copy becomes the one session (STR-A30)', () async {
      final live = await doFirstSet(await started());
      await repo.finishLiveSession(
        live.activityId,
        sessionId: 's',
        now: start.add(const Duration(minutes: 50)),
      );
      await watch('g1', start.add(const Duration(minutes: 2)), 46);
      // Garmin's own sets arrived first; the athlete's live log wins.
      await repo.saveLog(
        StrengthActivityLog(
          activityId: 'g1',
          exercises: [
            StrengthPerformedExercise(
              id: 'garmin:g1:ex:x',
              variantId: 'garmin:unknown',
              name: 'Unidentified exercise',
              equipment: '',
              sets: const [StrengthSetResult(id: 'garmin:g1:set:0:0', reps: 9)],
            ),
          ],
        ),
      );
      expect(await repo.reconcileLiveSessions(), 1);
      expect(await db.getActivityById(live.activityId), isNull);
      final moved = (await repo.loadLog('g1'))!;
      expect(moved.exercises.first.name, 'Back squat');
      expect(moved.sets.first.reps, 10);
      expect(moved.baseline?.ownerKey, 's');
      expect((await db.select(db.sessionActuals).getSingle()).activityId, 'g1');
      expect(await repo.reconcileLiveSessions(), 0, reason: 'once');
      // History counts it once, on the watch's date.
      final h = await repo.recentComparableSessions(
        moved.exercises.first.contextKey,
        before: DateTime(2026, 11, 1),
      );
      expect(h.map((e) => e.activityId), ['g1']);
    });

    test(
      'no merge without overlap, for another sport, or over own log',
      () async {
        final live = await doFirstSet(await started());
        await repo.finishLiveSession(
          live.activityId,
          now: start.add(const Duration(minutes: 50)),
        );
        await watch('later', start.add(const Duration(hours: 3)), 40);
        await watch('run', start, 50, type: 'running');
        await watch('own', start, 50);
        await repo.saveLog(
          StrengthActivityLog(
            activityId: 'own',
            exercises: [
              StrengthPerformedExercise(
                id: 'pe-own',
                variantId: 'bench_press',
                name: 'Bench press',
                equipment: 'Barbell',
                sets: const [StrengthSetResult(id: 'own-1')],
              ),
            ],
          ),
        );
        expect(await repo.reconcileLiveSessions(), 0);
        expect(await db.getActivityById(live.activityId), isNotNull);
        expect(
          (await repo.loadLog('own'))!.exercises.single.name,
          'Bench press',
        );
      },
    );
  });
}
