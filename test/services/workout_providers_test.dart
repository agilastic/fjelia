import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/plan_session_actions.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_destination.dart';
import 'package:fjelia/services/workout_providers/delivery_ledger.dart';
import 'package:fjelia/services/workout_providers/garmin_workout_provider.dart';
import 'package:fjelia/services/workout_providers/share_only_workout_provider.dart';
import 'package:fjelia/services/workout_providers/workout_providers.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';
import '../support/recording_workout_provider.dart';

/// The watch platforms are plug-ins: everything the planner does with them
/// (send, replace, remove, delete all, retry) is done through
/// [WorkoutProvider]. These tests run it with Garmin and with a made-up third
/// platform that has nothing to do with the code, and with one that only
/// shares.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late FakeWorkoutGarmin garmin;
  late RecordingProvider acme;
  late ShareOnlyWorkoutProvider polar;
  late WorkoutProviders providers;
  late TrainingPlanService service;
  final clock = DateTime(2026, 10, 25, 9);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    garmin = FakeWorkoutGarmin();
    acme = RecordingProvider(db, 'acme');
    polar = ShareOnlyWorkoutProvider(
      id: 'polar',
      label: 'Polar',
      sourceKey: 'polar',
      connected: () async => true,
    );
    providers = WorkoutProviders([
      GarminWorkoutProvider(db, garmin),
      acme,
      polar,
    ]);
    service = TrainingPlanService(db, providers, clock: () => clock);
  });
  tearDown(() => db.close());

  Future<String> plan() => service.generatePlan(
    athleteId: 'self',
    raceDate: clock.add(const Duration(days: 70)),
    sport: 'running',
    raceDistanceM: 21097,
    daysPerWeek: 5,
    restDays: const [1],
    strengthDays: const [],
    hoursPerWeek: 6,
    gadSports: const ['running'],
  );

  Future<List<TrainingSession>> sessions(String planId) =>
      (db.select(db.trainingSessions)
            ..where((t) => t.planId.equals(planId))
            ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)]))
          .get();

  group('the list of platforms', () {
    test(
      'connected ones come in the athlete\'s order, the rest after',
      () async {
        final b = RecordingProvider(db, 'beta', label: 'Beta');
        final off = RecordingProvider(db, 'off', connected: false);
        final all = WorkoutProviders([acme, b, off, polar]);
        // No order given: the order they are listed in.
        expect((await all.connected()).map((p) => p.id), [
          'acme',
          'beta',
          'polar',
        ]);
        // The athlete put Polar first and Beta second; Acme is not named.
        expect(
          (await all.connected(['polar', 'beta_source'])).map((p) => p.id),
          ['polar', 'beta', 'acme'],
        );
      },
    );

    test('only connected platforms that take workouts are pushed to', () async {
      final b = RecordingProvider(db, 'beta', connected: false);
      final text = RecordingProvider(db, 'text', kind: DeliveryMode.share);
      final all = WorkoutProviders([acme, b, text, polar]);
      expect((await all.pushTargets()).map((p) => p.id), ['acme']);
    });

    test('a platform id is used once', () {
      expect(
        () => WorkoutProviders([acme, RecordingProvider(db, 'acme')]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('the known platforms keep their label and source key', () {
      expect(WorkoutDestination.garmin.label, 'Garmin');
      expect(WorkoutDestination.coros.sourceKey, 'coros');
      expect(providers.byId('garmin')!.sourceKey, 'garmin_api');
      expect(providers.byId('nobody'), isNull);
    });

    test('a share-only platform holds nothing and cannot be sent to', () async {
      final planId = await plan();
      final s = (await sessions(planId)).first;
      expect(await polar.mode(), DeliveryMode.share);
      expect(await polar.hasDelivered(s), isFalse);
      expect(await polar.removeAll(titles: {}), 0);
      expect(await polar.retryCleanup(), 0);
      await expectLater(
        service.deliver(s.id, polar),
        throwsA(isA<StateError>()),
      );
      expect(polar.shareNote, contains('Polar'));
    });
  });

  group('sending', () {
    test('the plan goes to every platform that takes workouts, once', () async {
      final planId = await plan();
      await service.deliverPlan('self');
      final all = await sessions(planId);
      expect(garmin.creates, all.length);
      expect(acme.delivered, hasLength(all.length));
      // Nothing more the second time: both have everything.
      await service.deliverPlan('self');
      expect(garmin.creates, all.length);
      expect(acme.delivered, hasLength(all.length));
      // A session knows where it is.
      final one = all.first;
      expect((await providers.deliveredTo(one)).map((p) => p.id), [
        'garmin',
        'acme',
      ]);
    });

    test('a platform that is off or only shares gets nothing', () async {
      await plan();
      acme.connected = false;
      await service.deliverPlan('self');
      expect(acme.delivered, isEmpty);
      expect(garmin.creates, greaterThan(0));
    });

    test('one platform failing does not stop the others', () async {
      await plan();
      acme.offline = true;
      await service.deliverPlan('self');
      expect(acme.delivered, isEmpty);
      expect(garmin.creates, greaterThan(0));
    });

    test(
      'a changed session is sent again, to every platform that had it',
      () async {
        final planId = await plan();
        final first = (await sessions(planId)).first;
        await service.deliver(first.id, providers.byId('garmin')!);
        await service.deliver(first.id, acme);
        expect(garmin.creates, 1);
        // Nothing changed: Garmin only reschedules, the same workout.
        await service.deliver(first.id, providers.byId('garmin')!);
        expect(garmin.creates, 1);
        // The target changed: the content is new for everyone.
        final actions = PlanSessionActions(db, providers);
        final changed = await actions.setTargetMetric(first, 'power');
        await service.deliver(changed.id, providers.byId('garmin')!);
        await service.deliver(changed.id, acme);
        expect(garmin.creates, 2);
        // The old definition came down from the library.
        expect(garmin.deletedWorkouts, ['workout-1']);
        expect(acme.delivered, [first.id, first.id]);
        final record = await acme.ledger.get(first.id);
        expect(record!.fingerprint, sessionContentFingerprint(changed));
      },
    );

    test('a plan that ended is not sent', () async {
      final planId = await plan();
      await service.endPlan(planId);
      await service.deliverPlan('self');
      expect(garmin.creates, 0);
      expect(acme.delivered, isEmpty);
    });
  });

  group('taking workouts off', () {
    test('a rebuilt plan removes what it had put on every platform', () async {
      final planId = await plan();
      await service.deliverPlan('self');
      final before = await sessions(planId);
      await service.replan(
        planId: planId,
        reason: 'test',
        daysPerWeek: 5,
        restDays: const [1],
        strengthDays: const [],
        hoursPerWeek: 6,
        preferredSports: const ['running'],
      );
      expect(garmin.deletedWorkouts.length, before.length);
      expect(acme.removed.toSet(), before.map((s) => s.id).toSet());
      // The old sessions are gone, so are their records.
      expect(await db.select(db.workoutDeliveries).get(), isEmpty);
    });

    test(
      'an ended plan: the platform that is offline is queued, the rest are clean',
      () async {
        final planId = await plan();
        await service.deliverPlan('self');
        final count = (await sessions(planId)).length;
        acme.offline = true;
        await service.endPlan(planId);
        expect(garmin.deletedWorkouts, hasLength(count));
        final queued = await db.select(db.providerCleanups).get();
        expect(queued, hasLength(count));
        expect(queued.every((q) => q.providerId == 'acme'), isTrue);
        // Still offline: the entries stay.
        expect(await service.retryCleanup(), 0);
        expect(await db.select(db.providerCleanups).get(), hasLength(count));
        // Online again: one retry clears every platform's queue.
        acme.offline = false;
        expect(await service.retryCleanup(), count);
        expect(await db.select(db.providerCleanups).get(), isEmpty);
        expect(acme.removed, hasLength(count));
      },
    );

    test('skipping a session takes it off every calendar', () async {
      final planId = await plan();
      await service.deliverPlan('self');
      final s = (await sessions(planId)).first;
      final rest = await PlanSessionActions(db, providers).markRest(s);
      expect(rest.status, 'skipped');
      expect(acme.released, [s.id]);
      expect(garmin.removedSchedules, isNotEmpty);
    });
  });

  group('delete all', () {
    test(
      'every connected platform removes its own, with progress by name',
      () async {
        final planId = await plan();
        await service.deliverPlan('self');
        final count = (await sessions(planId)).length;
        final seen = <String>{};
        final removed = await service.removeFromPlatforms(
          titles: const {},
          providers: [providers.byId('garmin')!, acme, polar],
          onProgress: (done, total, label) => seen.add(label),
        );
        expect(removed['acme'], count);
        expect(removed['polar'], 0);
        expect(removed.keys, containsAll(['garmin', 'acme', 'polar']));
        expect(seen, containsAll(['Acme']));
        expect(await acme.ledger.all(), isEmpty);
      },
    );

    test(
      'a platform that cannot be reached does not stop the others',
      () async {
        final planId = await plan();
        await service.deliverPlan('self');
        final count = (await sessions(planId)).length;
        acme.offline = true;
        final removed = await service.removeFromPlatforms(
          titles: const {},
          providers: [acme, providers.byId('garmin')!],
        );
        expect(removed['acme'], 0);
        expect(removed.containsKey('garmin'), isTrue);
        // Garmin's own sessions were cleared, by its own rules.
        expect(count, greaterThan(0));
      },
    );

    test(
      'a platform that stops answering is given up on, not waited for',
      () async {
        await plan();
        await service.deliverPlan('self');
        final hung = _HungProvider(db);
        final started = DateTime.now();
        final removed = await service.removeFromPlatforms(
          titles: const {},
          providers: [hung, acme],
          providerTimeout: const Duration(milliseconds: 80),
        );
        expect(DateTime.now().difference(started).inSeconds, lessThan(5));
        expect(removed['hung'], 0);
        // The one after it still did its part.
        expect(removed['acme'], greaterThan(0));
      },
    );

    test('only the platforms asked are touched', () async {
      await plan();
      await service.deliverPlan('self');
      final removed = await service.removeFromPlatforms(
        titles: const {},
        providers: [acme],
      );
      expect(removed.keys, ['acme']);
      expect(garmin.deletedWorkouts, isEmpty);
    });
  });

  group('the shared records', () {
    test(
      'a queued removal counts its tries and keeps the last reason',
      () async {
        final queue = acme.queue;
        await queue.add('x', error: 'first');
        await queue.add('x', error: 'second');
        final row = (await db.select(db.providerCleanups).get()).single;
        expect(row.providerId, 'acme');
        expect(row.attempts, 2);
        expect(row.lastError, 'second');
        // The same remote id on another platform is another entry.
        await RecordingProvider(db, 'beta').queue.add('x');
        expect(await db.select(db.providerCleanups).get(), hasLength(2));
      },
    );

    test('entries stop being tried after the limit', () async {
      for (var i = 0; i < 5; i++) {
        await acme.queue.add('gone', error: 'x');
      }
      var tried = 0;
      final n = await acme.queue.retry((_, _) async {
        tried++;
        throw StateError('still there');
      }, maxAttempts: 5);
      expect(n, 0);
      expect(tried, 0);
    });

    test('the ledger keeps one record per session and platform', () async {
      await acme.ledger.put(
        's',
        fingerprint: 'a',
        day: '20261026',
        name: 'Run',
      );
      await acme.ledger.put(
        's',
        fingerprint: 'b',
        day: '20261027',
        name: 'Run',
      );
      await RecordingProvider(db, 'beta').ledger.put('s', fingerprint: 'c');
      final mine = await acme.ledger.all();
      expect(mine.single.fingerprint, 'b');
      expect(mine.single.day, '20261027');
      expect(await db.select(db.workoutDeliveries).get(), hasLength(2));
      await acme.ledger.deleteAll();
      expect(await db.select(db.workoutDeliveries).get(), hasLength(1));
    });
  });
}

/// A platform whose removal never answers.
class _HungProvider extends RecordingProvider {
  _HungProvider(AppDatabase db) : super(db, 'hung', label: 'Hung');

  @override
  Future<int> removeAll({
    required Set<String> titles,
    void Function(int done, int total)? onProgress,
  }) => Completer<int>().future;
}
