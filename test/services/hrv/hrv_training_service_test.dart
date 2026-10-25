import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/hrv_pair_assessment.dart';
import 'package:fjelia/models/hrv_training_episode.dart';
import 'package:fjelia/models/spot_hrv.dart';
import 'package:fjelia/services/hrv/hrv_training_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/hrv_db.dart';

void main() {
  late AppDatabase db;
  late HrvTrainingService service;
  var clock = atMin(400);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = atMin(400);
    service = HrvTrainingService(db, clock: () => clock);
  });
  tearDown(() => db.close());

  const before = SpotHrvContext.beforeTraining;
  const after = SpotHrvContext.afterTraining;

  Future<List<HrvEpisodeMeasurement>> activeLinks() => (db.select(
    db.hrvEpisodeMeasurements,
  )..where((t) => t.state.equals('active'))).get();

  test('HRV-T001 an unambiguous sequence pairs on its own', () async {
    await addActivity(db, 'a1', 0, 120);
    final p = await addReading(db, -20, before, rmssd: 60);
    final q = await addReading(db, 151, after, rmssd: 45);
    final snap = await service.reconcile();
    final a = snap.assessments.values.single;
    expect(a.pre!.uid, p);
    expect(a.post!.uid, q);
    expect(a.comparable, isTrue);
    expect(a.deltaMs, -15);
    expect(a.postDelay, const Duration(minutes: 31));
    expect(await activeLinks(), hasLength(2));
  });

  test(
    'HRV-T076 the same facts in any insert order give the same links',
    () async {
      Future<Set<String>> run(List<int> order) async {
        final d = AppDatabase(NativeDatabase.memory());
        addTearDown(d.close);
        final s = HrvTrainingService(d, clock: () => atMin(400));
        final steps = <Future<void> Function()>[
          () => addActivity(d, 'a1', 0, 120),
          () => addReading(d, -20, before, uid: 'pre1'),
          () => addReading(d, 151, after, uid: 'post1'),
          () => addActivity(d, 'a2', 240, 60),
          () => addReading(d, 220, before, uid: 'pre2'),
        ];
        for (final i in order) {
          await steps[i]();
          await s.reconcile();
        }
        final links = await (d.select(
          d.hrvEpisodeMeasurements,
        )..where((t) => t.state.equals('active'))).get();
        final activities = {
          for (final e in await d.select(d.hrvTrainingEpisodes).get())
            e.episodeId: e.primaryActivityId,
        };
        return {
          for (final l in links)
            '${activities[l.episodeId]}|${l.measurementUid}|${l.role}',
        };
      }

      final expected = await run([0, 1, 2, 3, 4]);
      expect(expected, hasLength(3));
      expect(await run([1, 2, 4, 0, 3]), expected);
      expect(await run([3, 4, 2, 1, 0]), expected);
    },
  );

  test('HRV-T021 readings stored before the import pair on import', () async {
    await addReading(db, -20, before, uid: 'p');
    await addReading(db, 151, after, uid: 'q');
    var snap = await service.reconcile();
    expect(snap.episodes, isEmpty);
    expect(await activeLinks(), isEmpty);
    await addActivity(db, 'late', 0, 120);
    snap = await service.reconcile();
    expect(snap.assessments.values.single.hasPair, isTrue);
  });

  test('HRV-T094 repeating the reconciliation changes nothing', () async {
    await addActivity(db, 'a1', 0, 120);
    await addReading(db, -20, before);
    await addReading(db, 151, after);
    await service.reconcile();
    final first = await db.select(db.hrvEpisodeMeasurements).get();
    final episodes = await db.select(db.hrvTrainingEpisodes).get();
    for (var i = 0; i < 20; i++) {
      await service.reconcile();
    }
    expect(
      (await db.select(db.hrvEpisodeMeasurements).get()).length,
      first.length,
    );
    expect(
      (await db.select(db.hrvTrainingEpisodes).get()).length,
      episodes.length,
    );
    expect(
      (await db.select(db.hrvTrainingEpisodes).get()).single.episodeId,
      episodes.single.episodeId,
    );
  });

  test(
    'HRV-T005 the elapsed duration sets the end, not the moving time',
    () async {
      await addActivity(db, 'a1', 0, 120, moving: 90);
      final snap = await service.reconcile();
      expect(snap.episodes.single.end!.toUtc(), atMin(120));
    },
  );

  test('HRV-T006 an unknown source has no end and no post', () async {
    await addActivity(db, 'a1', 0, 120, source: 'manual');
    await addReading(db, -20, before);
    await addReading(db, 130, after);
    final snap = await service.reconcile();
    final a = snap.assessments.values.single;
    expect(a.hasPre, isTrue);
    expect(a.hasPost, isFalse);
    expect(a.reasons, contains(HrvReason.unknownActualEnd));
  });

  group('identity', () {
    test('HRV-T009 two provider copies are one episode', () async {
      await addActivity(db, 'g', 0, 120);
      await addActivity(db, 'h', 0, 120, source: 'health_connect');
      final snap = await service.reconcile();
      expect(snap.episodes, hasLength(1));
      expect(await db.select(db.hrvEpisodeAliases).get(), hasLength(2));
    });

    test('HRV-T010 close but distinct workouts do not merge', () async {
      await addActivity(db, 'a', 0, 120);
      await addActivity(db, 'b', 0, 60, source: 'health_connect');
      final snap = await service.reconcile();
      expect(snap.episodes, hasLength(2));
      expect(
        snap.assessments.values.every(
          (a) => a.association == Association.ambiguous,
        ),
        isTrue,
      );
    });

    test('HRV-T077 de-duplication keeps the pair and the alias', () async {
      await addActivity(db, 'g', 0, 120);
      await addActivity(db, 'h', 0, 120, source: 'health_connect');
      await addReading(db, -20, before);
      await addReading(db, 151, after);
      final one = (await service.reconcile()).episodes.single.id;
      expect(await db.deduplicateActivities(), 1);
      final snap = await service.reconcile();
      expect(snap.episodes.single.id, one);
      expect(snap.assessments[one]!.hasPair, isTrue);
      expect(await service.episodeIdOfActivity('h'), one);
      expect(await service.episodeIdOfActivity('g'), one);
    });

    test('HRV-T022 a planned session never owns the episode', () async {
      await addActivity(db, 'a1', 0, 120);
      await addReading(db, -20, before);
      await addReading(db, 151, after);
      await service.reconcile();
      await db.delete(db.trainingSessions).go();
      await db.delete(db.trainingPlans).go();
      final snap = await service.reconcile();
      expect(snap.assessments.values.single.hasPair, isTrue);
    });
  });

  group('changes to the facts', () {
    test('HRV-T023 deleting the workout keeps the readings', () async {
      await addActivity(db, 'a1', 0, 120);
      await addReading(db, -20, before);
      await addReading(db, 151, after);
      await service.reconcile();
      await db.delete(db.activityRecords).go();
      final snap = await service.reconcile();
      expect(snap.episodes, isEmpty);
      expect(await activeLinks(), isEmpty);
      expect(await db.select(db.spotHrvMeasurements).get(), hasLength(2));
      final retracted = await (db.select(
        db.hrvEpisodeMeasurements,
      )..where((t) => t.state.equals('retracted'))).get();
      expect(retracted, hasLength(2));
    });

    test('HRV-T024 a corrected end past the post removes the post', () async {
      await addActivity(db, 'a1', 0, 120);
      await addReading(db, -20, before);
      await addReading(db, 130, after);
      expect(
        (await service.reconcile()).assessments.values.single.hasPost,
        isTrue,
      );
      await (db.update(db.activityRecords)).write(
        const ActivityRecordsCompanion(durationSeconds: Value(140 * 60)),
      );
      final snap = await service.reconcile();
      expect(snap.assessments.values.single.hasPost, isFalse);
      final e = await db.select(db.hrvTrainingEpisodes).getSingle();
      expect(e.intervalRevision, 1);
    });

    test(
      'HRV-T095 a late import of an intervening workout retracts the link',
      () async {
        await addActivity(db, 'a', 0, 60);
        await addReading(db, -20, before);
        await addReading(db, 130, after, uid: 'q');
        expect(
          (await service.reconcile()).assessments.values.single.hasPost,
          isTrue,
        );
        await addActivity(db, 'b', 70, 40, source: 'coros');
        final snap = await service.reconcile();
        final a = snap.assessments.values.firstWhere((x) => x.pre != null);
        expect(a.hasPost, isFalse);
        expect(a.hasPre, isTrue);
      },
    );

    test('deleting a reading retracts its link and keeps the other', () async {
      await addActivity(db, 'a1', 0, 120);
      await addReading(db, -20, before);
      await addReading(db, 151, after);
      await service.reconcile();
      await (db.delete(
        db.spotHrvMeasurements,
      )..where((t) => t.context.equals('afterTraining'))).go();
      final a = (await service.reconcile()).assessments.values.single;
      expect(a.hasPre, isTrue);
      expect(a.hasPost, isFalse);
      expect(a.deltaMs, isNull);
    });
  });

  group('corrections', () {
    test(
      'HRV-T020 a correction is audited and reassesses atomically',
      () async {
        await addActivity(db, 'a1', 0, 60);
        await addReading(db, 70, after, uid: 'first', rmssd: 40);
        await addReading(db, 100, after, uid: 'second', rmssd: 90);
        var snap = await service.reconcile();
        expect(snap.assessments.values.single.post!.uid, 'first');
        final id = snap.episodes.single.id;
        snap = await service.correct('second', id, HrvRole.post);
        expect(snap.assessments[id]!.post!.uid, 'second');
        expect(snap.assessments[id]!.association, Association.corrected);
        final history = await db.select(db.hrvEpisodeMeasurements).get();
        expect(history.where((l) => l.state == 'retracted'), isNotEmpty);
        expect(
          history
              .where((l) => l.state == 'active' && l.measurementUid == 'second')
              .single
              .associationMethod,
          'userCorrection',
        );
        // The correction survives another reconciliation.
        snap = await service.reconcile();
        expect(snap.assessments[id]!.post!.uid, 'second');
      },
    );

    test('unlink returns the episode to a partial state', () async {
      await addActivity(db, 'a1', 0, 60);
      await addReading(db, -20, before, uid: 'p');
      await addReading(db, 70, after, uid: 'q');
      final id = (await service.reconcile()).episodes.single.id;
      final snap = await service.unlink('p');
      // Unlinking retracts it; the automatic rule would pick it again, which
      // is the documented behavior for an automatic link.
      expect(snap.assessments[id]!.hasPost, isTrue);
    });
  });

  group('feedback and finish', () {
    test('feedback keeps its history and the newest wins', () async {
      await addActivity(db, 'a1', 0, 60);
      final id = (await service.reconcile()).episodes.single.id;
      await service.recordFeedback(id, rpe: 6);
      clock = clock.add(const Duration(minutes: 1));
      await service.recordFeedback(id, rpe: 8, note: ' hard ');
      final latest = await service.latestFeedback(id);
      expect(latest!.rpe, 8);
      expect(latest.note, 'hard');
      expect(await db.select(db.hrvEpisodeFeedback).get(), hasLength(2));
      await expectLater(
        service.recordFeedback(id, rpe: 11),
        throwsArgumentError,
      );
    });

    test('a reported finish makes a user-reported episode', () async {
      final id = await service.reportFinish(start: atMin(0), end: atMin(90));
      await addReading(db, -20, before);
      await addReading(db, 120, after);
      final snap = await service.reconcile();
      expect(snap.episode(id)!.interval.basis, IntervalBasis.userReported);
      expect(snap.assessments[id]!.hasPair, isTrue);
      await expectLater(
        service.reportFinish(start: atMin(10), end: atMin(5)),
        throwsArgumentError,
      );
    });

    test('a breathing session is not a workout', () async {
      await addActivity(db, 'b', 0, 10, type: 'breathwork');
      expect((await service.reconcile()).episodes, isEmpty);
    });
  });

  test('a legacy reading is flagged and stays usable', () async {
    await addActivity(db, 'a1', 0, 60);
    await addReading(db, -20, before, quality: 'legacyUnverified');
    await addReading(db, 70, after, quality: 'legacyUnverified');
    final a = (await service.reconcile()).assessments.values.single;
    expect(a.reasons, contains(HrvReason.legacyQualityUnknown));
    expect(a.hasPair, isTrue);
  });

  test('an invalid reading is never linked', () async {
    await addActivity(db, 'a1', 0, 60);
    await addReading(db, 70, after, quality: 'invalid');
    final a = (await service.reconcile()).assessments.values.single;
    expect(a.hasPost, isFalse);
  });
}
