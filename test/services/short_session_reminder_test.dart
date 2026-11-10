import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/notifications/local_notification_gateway.dart';
import 'package:fjelia/services/post_workout_scorer.dart';
import 'package:fjelia/services/short_session_reminder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationGateway gateway;
  late ShortSessionReminder reminder;
  final now = DateTime(2026, 11, 10, 15);
  final ended = DateTime(2026, 11, 10, 14, 58);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
    reminder = ShortSessionReminder(
      db,
      gateway,
      PostWorkoutScorer(db),
      now: () => now,
    );
    await db
        .into(db.trainingSessions)
        .insert(
          TrainingSessionsCompanion.insert(
            id: 'gym',
            planId: 'p',
            athleteId: 'self',
            sessionDate: DateTime(2026, 11, 10),
            sessionNumber: 1,
            weekNumber: 1,
            sport: 'strength',
            sessionType: 'strength',
            phase: 'base',
            primaryZone: 2,
            title: 'Full Body Strength',
            plannedDurationMin: 45,
            plannedTrimp: 40,
            sessionLevel: 1,
            status: const Value('completed'),
            actualDurationMin: const Value(31),
          ),
        );
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'a1',
            name: 'Strength',
            type: 'strength_training',
            startDate: DateTime(2026, 11, 10, 14, 27),
            durationSeconds: 31 * 60,
          ),
        );
    await db
        .into(db.sessionActuals)
        .insert(
          SessionActualsCompanion.insert(
            sessionId: 'gym',
            durationRatio: const Value(31 / 45),
            outcome: const Value('partial'),
            startedAt: Value(DateTime(2026, 11, 10, 14, 27)),
            completedAt: Value(ended),
            activityId: const Value('a1'),
          ),
        );
  });
  tearDown(() => db.close());

  test('asks once, about 5 minutes after the end, with the reasons', () async {
    expect(await reminder.reconcile(), 1);
    final push = gateway.scheduled.single;
    expect(push.feature, NotificationFeature.shortSession);
    expect(push.at, ended.add(const Duration(minutes: 5)));
    expect(push.body, 'Full Body Strength: 31 of 45 min');
    expect(push.actionLabels.keys, ['time', 'weather', 'fatigue', 'pain']);
    expect(ShortSessionPayload.decode(push.payload)?.sessionId, 'gym');
    // A later sync does not ask again.
    expect(await reminder.reconcile(), 0);
  });

  test(
    'the answer is the session\'s reason and the activity\'s note',
    () async {
      await reminder.answer('gym', 'fatigue', text: 'Bad night');
      final a = await (db.select(
        db.sessionActuals,
      )..where((t) => t.sessionId.equals('gym'))).getSingle();
      expect(a.shortReason, 'fatigue');
      final act = await (db.select(
        db.activityRecords,
      )..where((t) => t.activityId.equals('a1'))).getSingle();
      expect(
        act.athleteNote,
        'Shorter than planned (31 of 45 min): Tired – Bad night',
      );
      // Answered: nothing more to ask.
      expect(await reminder.reconcile(), 0);
    },
  );
}
