import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/strength_workout.dart';
import 'package:fjelia/services/strength/strength_repository.dart';
import 'package:fjelia/services/strength/strength_templates.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

StrengthWorkoutPlan _plan({double? kg, String id = 'bench'}) =>
    StrengthWorkoutPlan(
      blocks: [
        StrengthBlock(
          id: '$id-b',
          exercises: [
            StrengthPlannedExercise(
              id: id,
              variantId: 'bench_press',
              name: 'Bench press',
              equipment: 'Barbell',
              sets: [
                for (var i = 0; i < 3; i++)
                  StrengthSetTarget(
                    id: '$id-$i',
                    repMin: 8,
                    repMax: 10,
                    load: kg == null ? null : StrengthLoad(kg),
                    restSeconds: 120,
                  ),
              ],
            ),
          ],
        ),
      ],
    );

StrengthPerformedExercise _bench(
  String id,
  List<int> reps,
  double kg, {
  StrengthSetKind kind = StrengthSetKind.working,
}) => StrengthPerformedExercise(
  id: id,
  variantId: 'bench_press',
  name: 'Bench press',
  equipment: 'Barbell',
  sets: [
    for (var i = 0; i < reps.length; i++)
      StrengthSetResult(
        id: '$id-$i',
        kind: kind,
        status: StrengthSetStatus.completed,
        reps: reps[i],
        load: StrengthLoad(kg),
      ),
  ],
);

void main() {
  late AppDatabase db;
  late StrengthRepository repo;
  Future<void> activity(
    String id,
    DateTime start, {
    String type = 'strength_training',
  }) => db
      .into(db.activityRecords)
      .insert(
        ActivityRecordsCompanion.insert(
          activityId: id,
          name: 'Gym',
          type: type,
          startDate: start,
          durationSeconds: 3600,
        ),
      );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StrengthRepository(db);
  });
  tearDown(() => db.close());

  group('plans', () {
    final owner = StrengthPlanOwner.session('s1');
    test(
      'save makes revisions; a stale editor is refused (STR-A14, A15)',
      () async {
        expect(await repo.loadPlan(owner), isNull);
        final first = await repo.savePlan(owner, _plan(), expectedRevision: 0);
        expect(first.revision, 1);
        final second = await repo.savePlan(
          owner,
          _plan(kg: 70),
          expectedRevision: 1,
        );
        expect(second.revision, 2);
        await expectLater(
          repo.savePlan(owner, _plan(kg: 75), expectedRevision: 1),
          throwsA(isA<StrengthConflictException>()),
        );
        final loaded = (await repo.loadPlan(owner))!;
        expect(loaded.revisionId, second.revisionId);
        expect(loaded.plan.exercises.single.sets.first.load?.kg, 70);
        // The earlier revision stays readable for comparisons.
        expect(
          (await repo.revision(first.revisionId))!
              .plan
              .exercises
              .single
              .sets
              .first
              .load,
          isNull,
        );
      },
    );

    test('invalid and empty plans are not saved', () async {
      await expectLater(
        repo.savePlan(owner, const StrengthWorkoutPlan(), expectedRevision: 0),
        throwsA(isA<StrengthValidationException>()),
      );
      expect(await repo.loadPlan(owner), isNull);
    });

    test('a malformed stored plan is reported, not replaced (STR-F14)', () async {
      final saved = await repo.savePlan(owner, _plan(), expectedRevision: 0);
      await db.customStatement(
        "UPDATE strength_plan_revisions SET plan_json = '{\"blocks\": 7}' WHERE revision_id = '${saved.revisionId}'",
      );
      await expectLater(
        repo.loadPlan(owner),
        throwsA(isA<StrengthUnreadableException>()),
      );
    });
  });

  group('logs', () {
    test('save, reload and stable ids (STR-A14)', () async {
      await activity('a1', DateTime(2026, 10, 20));
      final log = StrengthActivityLog(
        activityId: 'a1',
        exercises: [
          _bench('e1', [10, 9, 8], 70),
        ],
        notes: 'Felt good',
      );
      final saved = await repo.saveLog(log);
      expect(saved.revision, 1);
      final back = (await repo.loadLog('a1'))!;
      expect(back.exercises.single.sets.map((s) => s.id), [
        'e1-0',
        'e1-1',
        'e1-2',
      ]);
      expect(back.exercises.single.sets.map((s) => s.reps), [10, 9, 8]);
      expect(back.notes, 'Felt good');
      await expectLater(
        repo.saveLog(log),
        throwsA(isA<StrengthConflictException>()),
        reason: 'revision 0 is outdated now',
      );
    });

    test('unknown stays unknown; zero stays zero (STR-A11)', () async {
      await activity('a1', DateTime(2026, 10, 20));
      await repo.saveLog(
        StrengthActivityLog(
          activityId: 'a1',
          exercises: [
            StrengthPerformedExercise(
              id: 'e',
              variantId: 'bench_press',
              name: 'Bench',
              equipment: 'Barbell',
              sets: const [
                StrengthSetResult(
                  id: 's1',
                  status: StrengthSetStatus.failed,
                  reps: 0,
                ),
                StrengthSetResult(id: 's2'),
              ],
            ),
          ],
        ),
      );
      final sets = (await repo.loadLog('a1'))!.sets.toList();
      expect(sets[0].reps, 0);
      expect(sets[0].load, isNull);
      expect(sets[1].reps, isNull);
      expect(sets[1].status, StrengthSetStatus.unrecorded);
    });

    test(
      'baseline survives plan edits and retirement (STR-A27, A33)',
      () async {
        await activity('a1', DateTime(2026, 10, 20));
        final owner = StrengthPlanOwner.session('s1');
        await repo.savePlan(owner, _plan(kg: 70), expectedRevision: 0);
        final baseline = (await repo.baselineFor(owner))!;
        await repo.saveLog(
          StrengthActivityLog(
            activityId: 'a1',
            baseline: baseline,
            exercises: logLayoutFromPlan(baseline.plan),
          ),
        );
        await repo.savePlan(owner, _plan(kg: 90), expectedRevision: 1);
        await db.delete(db.strengthPlanHeads).go();
        await db.delete(db.strengthPlanRevisions).go();
        final log = (await repo.loadLog('a1'))!;
        expect(log.baseline!.plan.exercises.single.sets.first.load?.kg, 70);
        expect(log.baseline!.revisionId, baseline.revisionId);
      },
    );

    test('deleting the activity erases its results (STR-A33)', () async {
      await activity('a1', DateTime(2026, 10, 20));
      await repo.saveLog(
        StrengthActivityLog(
          activityId: 'a1',
          exercises: [
            _bench('e', [10], 70),
          ],
        ),
      );
      await db.deleteActivityById('a1');
      expect(await repo.loadLog('a1'), isNull);
      expect(await db.select(db.strengthPerformedSets).get(), isEmpty);
      expect(await db.select(db.strengthPerformedExercises).get(), isEmpty);
    });

    test('a missing activity cannot get a log', () async {
      await expectLater(
        repo.saveLog(const StrengthActivityLog(activityId: 'gone')),
        throwsStateError,
      );
    });
  });

  group('history (STR-A21, A22)', () {
    test('no history: unknown first load', () async {
      expect(
        await repo.recentComparableHistory(
          _plan().exercises.single.contextKey,
          before: DateTime(2026, 10, 27),
        ),
        isNull,
      );
    });

    test('latest earlier session of the same context only', () async {
      await activity('old', DateTime(2026, 10, 10));
      await activity('last', DateTime(2026, 10, 20));
      await activity('later', DateTime(2026, 10, 30));
      await activity('db', DateTime(2026, 10, 25));
      await repo.saveLog(
        StrengthActivityLog(
          activityId: 'old',
          exercises: [
            _bench('o', [10, 10, 10], 60),
          ],
        ),
      );
      await repo.saveLog(
        StrengthActivityLog(
          activityId: 'last',
          exercises: [
            _bench('w', [5], 40, kind: StrengthSetKind.warmup),
            _bench('l', [10, 9, 8], 70),
          ],
        ),
      );
      await repo.saveLog(
        StrengthActivityLog(
          activityId: 'later',
          exercises: [
            _bench('x', [10], 99),
          ],
        ),
      );
      // Same movement with dumbbells is another context.
      await repo.saveLog(
        StrengthActivityLog(
          activityId: 'db',
          exercises: [
            StrengthPerformedExercise(
              id: 'd',
              variantId: 'bench_press',
              name: 'Bench press',
              equipment: 'Dumbbells',
              sets: const [
                StrengthSetResult(
                  id: 'd0',
                  status: StrengthSetStatus.completed,
                  reps: 10,
                  load: StrengthLoad(30),
                ),
              ],
            ),
          ],
        ),
      );
      final h = (await repo.recentComparableHistory(
        _plan().exercises.single.contextKey,
        before: DateTime(2026, 10, 27),
        now: DateTime(2026, 10, 27),
      ))!;
      expect(h.activityId, 'last');
      expect(h.sets.map((s) => s.reps), [10, 9, 8], reason: 'warm-up excluded');
      expect(h.commonLoad?.kg, 70);
      expect(h.stale, isFalse);
      final stale = (await repo.recentComparableHistory(
        _plan().exercises.single.contextKey,
        before: DateTime(2026, 10, 27),
        now: DateTime(2027, 1, 1),
      ))!;
      expect(stale.stale, isTrue);
    });

    test('skipped and unrecorded sets are not history', () async {
      await activity('a', DateTime(2026, 10, 20));
      await repo.saveLog(
        StrengthActivityLog(
          activityId: 'a',
          exercises: [
            StrengthPerformedExercise(
              id: 'e',
              variantId: 'bench_press',
              name: 'Bench press',
              equipment: 'Barbell',
              sets: const [
                StrengthSetResult(id: 's1', status: StrengthSetStatus.skipped),
                StrengthSetResult(id: 's2'),
              ],
            ),
          ],
        ),
      );
      expect(
        await repo.recentComparableHistory(
          _plan().exercises.single.contextKey,
          before: DateTime(2026, 10, 27),
        ),
        isNull,
      );
    });
  });

  test(
    'increments are stored in kg and survive unit display (STR-A29)',
    () async {
      const key = 'bench_press|barbell|external/total/1/bilateral';
      await repo.rememberIncrement(key, StrengthLoad.entered(5, MassUnit.lb));
      final step = (await repo.increment(key))!;
      expect(step.kg, closeTo(2.26796185, 1e-9));
      expect(step.unit, MassUnit.lb);
      await expectLater(
        repo.rememberIncrement(key, const StrengthLoad(0)),
        throwsA(isA<StrengthValidationException>()),
      );
    },
  );

  test('custom exercises get fresh ids and archive without loss', () async {
    final a = await repo.addCustomVariant(name: 'Sled push', equipment: 'Sled');
    final b = await repo.addCustomVariant(name: 'Sled push', equipment: 'Sled');
    expect(a.id, isNot(b.id));
    await repo.archiveCustomVariant(a.id);
    expect((await repo.customVariants()).map((v) => v.id), [b.id]);
  });

  group('bundled templates (STR-A25)', () {
    test('every structured template matches its library entry', () async {
      await WorkoutTemplateLibrary(db).seedIfEmpty();
      final library = await (db.select(
        db.workoutTemplates,
      )..where((t) => t.sport.equals('strength'))).get();
      for (final t in bundledStrengthTemplates) {
        final entry = library.singleWhere((l) => l.subType == t.id);
        expect(entry.description, t.legacyDescription);
        final plan = t.build();
        expect(plan.validate(), isEmpty, reason: t.id);
        expect(plan.isEmpty, isFalse);
        expect(
          plan.exercises.expand((e) => e.sets).every((s) => s.load == null),
          isTrue,
          reason: 'no invented athlete kilograms',
        );
      }
    });

    test('a title or subtype alone does not upgrade a session', () {
      expect(
        bundledStrengthPlanFor(
          subType: 'strengthFull',
          sessionNotes: 'Custom notes',
        ),
        isNull,
      );
      expect(
        bundledStrengthPlanFor(
          subType: 'strengthFull',
          sessionNotes: bundledStrengthTemplates.first.legacyDescription,
        ),
        isNotNull,
      );
    });
  });
}
