import 'dart:math' as math;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/daily_readiness_service.dart';
import 'package:fjelia/services/missed_workout_reminder_service.dart';
import 'package:fjelia/services/notifications/local_notification_gateway.dart';
import 'package:fjelia/services/plan_proposal_notifications.dart';
import 'package:fjelia/services/plan_proposal_store.dart';
import 'package:fjelia/services/post_workout_scorer.dart' show noActivityReason;
import 'package:fjelia/services/session_adaptation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/upcoming_done_test.dart' show session;
import '../support/fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationGateway gateway;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
  });
  tearDown(() => db.close());

  Future<void> plan(DateTime from) => db
      .into(db.trainingPlans)
      .insert(
        TrainingPlansCompanion.insert(
          id: 'p',
          athleteId: 'self',
          startDate: from.subtract(const Duration(days: 14)),
          endDate: from.add(const Duration(days: 30)),
          status: 'active',
          generatedAt: from.subtract(const Duration(days: 14)),
        ),
      );

  group('readiness preview', () {
    test('shows the change without making it', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await plan(today);
      await db
          .into(db.trainingSessions)
          .insert(session('t', today, title: 'Tempo run', minutes: 60));
      const yellow = ReadinessResult(
        level: ReadinessLevel.yellow,
        flagCount: 2,
        hrvLow: true,
      );
      final service = SessionAdaptationService(db);

      final preview = await service.previewDay(yellow);
      expect(preview, hasLength(1));
      expect(preview.single.durationMin, 51);
      expect(preview.single.rest, isFalse);
      final stored = await (db.select(
        db.trainingSessions,
      )..where((t) => t.id.equals('t'))).getSingle();
      expect(stored.status, 'planned');
      expect(stored.plannedDurationMin, 60);

      // Agreeing makes exactly the change that was shown.
      final done = await service.adaptDay(yellow);
      expect(done.single.session.plannedDurationMin, 51);
      expect(done.single.session.status, 'adapted');
    });

    test('a green morning proposes nothing', () async {
      const green = ReadinessResult(level: ReadinessLevel.green, flagCount: 0);
      expect(await SessionAdaptationService(db).previewDay(green), isEmpty);
    });
  });

  group('missed in the last two days', () {
    // Sunday noon.
    final now = DateTime(2026, 11, 8, 12);
    DateTime day(int i) => DateTime(now.year, now.month, now.day + i);
    MissedWorkoutReminderService service() => MissedWorkoutReminderService(
      db,
      gateway,
      now: () => now,
      settings: () async => const MissedWorkoutSettings(),
    );

    setUp(() async {
      await plan(day(0));
      // Yesterday still open; the day before closed as missed by the scorer.
      await db
          .into(db.trainingSessions)
          .insert(session('sat', day(-1), title: 'Long run'));
      await db
          .into(db.trainingSessions)
          .insert(
            session('fri', day(-2), title: 'Intervals', status: 'skipped'),
          );
      await db
          .into(db.sessionActuals)
          .insert(
            SessionActualsCompanion.insert(
              sessionId: 'fri',
              skipReason: const Value(noActivityReason),
            ),
          );
      // Three days back is too old to ask about.
      await db
          .into(db.trainingSessions)
          .insert(session('thu', day(-3), title: 'Easy run'));
    });

    test('yesterday and the day before, latest first', () async {
      final missed = await service().pastMissed();
      expect(missed.map((m) => m.day), [day(-1), day(-2)]);
      expect(missed.first.items.single.plannedTitle, 'Long run');
      expect(missed.last.items.single.plannedTitle, 'Intervals');
    });

    test('a day the athlete left as it is is not asked again', () async {
      await service().acknowledge(day(-1));
      expect((await service().pastMissed()).map((m) => m.day), [day(-2)]);
    });

    test('a skip with a reason is an answer', () async {
      await (db.update(db.sessionActuals)
            ..where((t) => t.sessionId.equals('fri')))
          .write(const SessionActualsCompanion(skipReason: Value('Sick')));
      expect((await service().pastMissed()).map((m) => m.day), [day(-1)]);
    });

    group('notifications', () {
      PlanProposalNotifications notifications(DateTime Function() at) =>
          PlanProposalNotifications(
            gateway,
            service(),
            now: at,
            random: math.Random(1),
          );

      test('come 3 to 6 minutes after leaving the app, once', () async {
        final n = notifications(() => now);
        await n.onBackground(
          readiness: (day: day(0), title: 'A bit easier today?', body: 'x'),
        );
        expect(gateway.scheduled, hasLength(3));
        for (final s in gateway.scheduled) {
          final wait = s.at.difference(now).inSeconds;
          expect(wait, inInclusiveRange(180, 360));
        }
        final readiness = gateway.scheduled.firstWhere(
          (s) => s.feature == NotificationFeature.planProposal,
        );
        expect(readiness.actionLabels.keys, ['open', 'keep']);
        expect(PlanProposalPayload.decode(readiness.payload)?.day, day(0));
        // A past day has no "still today".
        final missed = gateway.scheduled.where(
          (s) => s.feature == NotificationFeature.missedWorkout,
        );
        expect(missed.every((s) => !s.actionLabels.containsKey('today')), true);
        expect(missed.map((s) => MissedWorkoutPayload.decode(s.payload)?.day), [
          day(-1),
          day(-2),
        ]);

        // Leaving the app again does not ring twice.
        await n.onBackground(
          readiness: (day: day(0), title: 'A bit easier today?', body: 'x'),
        );
        expect(gateway.scheduled, hasLength(3));
      });

      test('back in the app before they appear, they are taken back and '
          'can come again', () async {
        await notifications(() => now).onBackground();
        expect(gateway.scheduled, hasLength(2));
        await notifications(
          () => now.add(const Duration(minutes: 1)),
        ).onForeground();
        expect(gateway.cancelled, hasLength(2));
        expect(await PlanProposalStore.notifications(), isEmpty);
        await notifications(() => now).onBackground();
        expect(gateway.scheduled, hasLength(4));
      });

      test('once shown, they stay until answered', () async {
        await notifications(() => now).onBackground();
        await notifications(
          () => now.add(const Duration(minutes: 7)),
        ).onForeground();
        expect(gateway.cancelled, isEmpty);
        await notifications(
          () => now,
        ).resolved(PlanProposalNotifications.missedKey(day(-1)));
        expect(gateway.cancelled, [
          pastMissedNotificationBase +
              DateTime.utc(2026, 11, 7).difference(DateTime.utc(2020)).inDays,
        ]);
      });

      test('without permission nothing is set up', () async {
        gateway.state = NotificationPermission.denied;
        await notifications(() => now).onBackground();
        expect(gateway.scheduled, isEmpty);
      });
    });
  });
}
