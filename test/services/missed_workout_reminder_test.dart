import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/missed_workout_reminder_service.dart';
import 'package:fjelia/services/notifications/local_notification_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/upcoming_done_test.dart' show session;
import '../support/fake_notification_gateway.dart';

void main() {
  // Monday noon.
  final now = DateTime(2026, 11, 2, 12);
  DateTime day(int i, [int hour = 0]) =>
      DateTime(now.year, now.month, now.day + i, hour);
  late AppDatabase db;
  late FakeNotificationGateway gateway;
  var settings = const MissedWorkoutSettings();

  MissedWorkoutReminderService service({DateTime? at}) =>
      MissedWorkoutReminderService(
        db,
        gateway,
        now: () => at ?? now,
        settings: () async => settings,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = const MissedWorkoutSettings();
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
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
    await db
        .into(db.trainingSessions)
        .insert(session('mon', day(0), title: 'Easy run', minutes: 45));
    await db
        .into(db.trainingSessions)
        .insert(session('wed', day(2), title: 'Long ride', sport: 'cycling'));
  });
  tearDown(() => db.close());

  test('schedules 21:30 on each day with an open session', () async {
    await service().reconcile();
    final byId = {for (final n in gateway.scheduled) n.id: n};
    final mon = byId[missedWorkoutNotificationId(day(0))]!;
    expect(mon.at, DateTime(2026, 11, 2, 21, 30));
    expect(mon.body, contains('Easy run (45 min)'));
    expect(mon.feature, NotificationFeature.missedWorkout);
    expect(byId, contains(missedWorkoutNotificationId(day(2))));
    expect(byId, isNot(contains(missedWorkoutNotificationId(day(1)))));
    expect(
      MissedWorkoutPayload.decode(mon.payload)?.day,
      DateTime(2026, 11, 2),
    );
  });

  test('a recorded workout takes the reminder back', () async {
    await service().reconcile();
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'run',
            name: 'Easy run',
            type: 'running',
            startDate: day(0, 7),
            durationSeconds: 45 * 60,
          ),
        );
    gateway.cancelled.clear();
    await service().reconcile();
    expect(gateway.cancelled, contains(missedWorkoutNotificationId(day(0))));
  });

  test('a skipped session takes the reminder back', () async {
    await (db.update(db.trainingSessions)..where((t) => t.id.equals('wed')))
        .write(const TrainingSessionsCompanion(status: Value('skipped')));
    await service().reconcile();
    expect(gateway.cancelled, contains(missedWorkoutNotificationId(day(2))));
  });

  test('"still today" ends the reminders for that day', () async {
    final s = service();
    final action = await s.handle(
      NotificationResponse(
        actionId: 'today',
        payload: MissedWorkoutPayload(day(0)).encode(),
      ),
    );
    expect(action, isNull);
    gateway.scheduled.clear();
    await s.reconcile();
    expect(
      gateway.scheduled.map((n) => n.id),
      isNot(contains(missedWorkoutNotificationId(day(0)))),
    );
  });

  test('move and skip open the app on that day', () async {
    final action = await service().handle(
      NotificationResponse(
        actionId: 'move',
        payload: MissedWorkoutPayload(day(0)).encode(),
      ),
    );
    expect(action?.kind, MissedWorkoutActionKind.move);
    expect(action?.day, DateTime(2026, 11, 2));
  });

  test('switched off or after the time, nothing new is scheduled', () async {
    settings = const MissedWorkoutSettings(enabled: false);
    await service().reconcile();
    expect(gateway.scheduled, isEmpty);
    settings = const MissedWorkoutSettings();
    await service(at: day(0, 22)).reconcile();
    expect(
      gateway.scheduled.map((n) => n.id),
      isNot(contains(missedWorkoutNotificationId(day(0)))),
    );
  });

  test('the device test fires in 10 s, apart from the real ones', () async {
    final day0 = await service().scheduleTest();
    final n = gateway.scheduled.single;
    expect(day0, DateTime(2026, 11, 2));
    expect(n.at, now.add(const Duration(seconds: 10)));
    expect(n.id, missedWorkoutNotificationLimit - 1);
    expect(n.body, contains('Easy run (45 min)'));
    gateway.cancelled.clear();
    await service().reconcile();
    expect(gateway.cancelled, isNot(contains(n.id)));
  });

  test('without permission nothing is scheduled', () async {
    gateway.state = NotificationPermission.denied;
    await service().reconcile();
    expect(gateway.scheduled, isEmpty);
  });
}
