import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/workout_nutrition.dart';
import 'package:fjelia/services/nutrition_service.dart';
import 'package:fjelia/services/nutrition_reminder_service.dart';
import 'package:fjelia/services/notifications/local_notification_gateway.dart';
import 'package:fjelia/services/hrv/hrv_notification_action_router.dart';
import 'package:fjelia/services/hrv/hrv_post_reminder_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late NutritionService store;
  late FakeNotificationGateway gateway;
  late NutritionReminderService reminders;
  var now = DateTime(2026, 10, 28, 12);
  Future<void> add(String id, {DateTime? start, int minutes = 60}) async {
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: id,
            name: 'Ride',
            type: 'cycling',
            startDate: start ?? now.subtract(const Duration(minutes: 80)),
            durationSeconds: minutes * 60,
          ),
        );
  }

  setUp(() {
    now = DateTime(2026, 10, 28, 12);
    db = AppDatabase(NativeDatabase.memory());
    store = NutritionService(db);
    gateway = FakeNotificationGateway();
    reminders = NutritionReminderService(store, gateway, now: () => now);
  });
  tearDown(() => db.close());
  test(
    'one reminder per recent activity, independent of HRV or a sensor',
    () async {
      await add('a');
      await add('b');
      await add('old', start: now.subtract(const Duration(days: 5)));
      await add('short', minutes: 20);
      await add('ongoing', start: now.subtract(const Duration(minutes: 10)));
      await reminders.reconcile();
      await reminders.reconcile();
      expect(gateway.scheduled, hasLength(2));
      expect(gateway.scheduled.map((n) => n.feature).toSet(), {
        NotificationFeature.nutrition,
      });
      expect(gateway.scheduled.map((n) => n.id).toSet(), hasLength(2));
      expect(gateway.permissionRequests, isEmpty);
      final payloads = gateway.scheduled
          .map(
            (n) => NutritionNotificationPayload.decode(n.payload)!.activityId,
          )
          .toSet();
      expect(payloads, {'a', 'b'});
    },
  );
  test(
    'completed/no-intake/declined logs cancel; a draft stays pending',
    () async {
      await add('a');
      await reminders.reconcile();
      await store.saveLog(
        'a',
        const NutritionLog(
          entries: [NutritionEntry(name: 'Water', fluid: 500)],
        ),
      );
      await reminders.reconcile();
      expect(gateway.pending, hasLength(1));
      await store.saveLog(
        'a',
        const NutritionLog(status: 'complete', noIntake: true),
      );
      await reminders.reconcile();
      expect(gateway.pending, isEmpty);
      await add('b');
      await store.saveLog('b', const NutritionLog(status: 'declined'));
      await reminders.reconcile();
      expect(gateway.pending, isEmpty);
    },
  );
  test(
    'permission denial never prompts and enabling later can schedule',
    () async {
      gateway.state = NotificationPermission.denied;
      await add('a');
      await reminders.reconcile();
      expect(gateway.scheduled, isEmpty);
      expect(gateway.permissionRequests, isEmpty);
      gateway.state = NotificationPermission.granted;
      await reminders.reconcile();
      expect(gateway.scheduled, hasLength(1));
    },
  );
  test('quiet hours postpone without changing a daytime schedule', () async {
    now = DateTime(2026, 10, 28, 22, 10);
    await add('a');
    await reminders.reconcile();
    expect(gateway.scheduled.single.at, DateTime(2026, 10, 29, 8));
  });
  test(
    'tap opens the exact activity once, and stale tokens are ignored',
    () async {
      await add('a');
      await reminders.reconcile();
      final payload = gateway.scheduled.single.payload;
      expect(
        await reminders.handle(
          NotificationResponse(actionId: 'log', payload: payload),
        ),
        'a',
      );
      expect(
        await reminders.handle(
          NotificationResponse(actionId: 'log', payload: payload),
        ),
        isNull,
      );
      expect(gateway.pending, isEmpty);
    },
  );
  test(
    'snooze rotates the token; dismiss does not invent zero intake',
    () async {
      await add('a');
      await reminders.reconcile();
      final first = gateway.scheduled.single.payload;
      await reminders.handle(
        NotificationResponse(actionId: 'snooze', payload: first),
      );
      expect(gateway.scheduled.last.payload, isNot(first));
      expect(
        await reminders.handle(
          NotificationResponse(actionId: 'log', payload: first),
        ),
        isNull,
      );
      await reminders.handle(
        NotificationResponse(
          actionId: 'skip',
          payload: gateway.scheduled.last.payload,
        ),
      );
      expect((await store.log('a')).finished, isFalse);
      await reminders.reconcile();
      expect(gateway.pending, isEmpty);
    },
  );
  test(
    'activity deletion/reset cancels owned requests and preserves HRV ids',
    () async {
      await add('a');
      await reminders.reconcile();
      await gateway.schedule(
        ScheduledNotification(
          id: 7000001,
          at: now,
          payload: 'hrv',
          title: '',
          body: '',
        ),
      );
      await db.delete(db.activityRecords).go();
      await reminders.reconcile();
      expect(gateway.pending.keys, [7000001]);
      await db.delete(db.nutritionReminderRecords).go();
      gateway.delivered.addAll([7199998, 7000002]);
      await gateway.schedule(
        ScheduledNotification(
          id: 7199999,
          at: now,
          payload: 'old',
          title: '',
          body: '',
        ),
      );
      await reminders.reconcile();
      expect(gateway.pending.keys, [7000001]);
      expect(gateway.delivered, {7000002});
    },
  );
  test(
    'cold-launch and foreground actions route nutrition without an HRV sensor',
    () async {
      await add('a');
      await reminders.reconcile();
      gateway.launch = NotificationResponse(
        actionId: 'log',
        payload: gateway.scheduled.single.payload,
      );
      final hrv = HrvPostReminderCoordinator(
        db: db,
        gateway: gateway,
        sensorReady: () async => false,
      );
      final opened = <String>[];
      final router = HrvNotificationActionRouter(
        coordinator: hrv,
        gateway: gateway,
        inbox: () async => [],
      );
      addTearDown(router.dispose);
      router.onOtherResponse = (response) async {
        final id = await reminders.handle(response);
        if (id != null) opened.add(id);
      };
      router.attach();
      await router.markReady();
      await router.markReady();
      expect(opened, ['a']);
      await add('b');
      await reminders.reconcile();
      gateway.respond(
        NotificationResponse(
          actionId: 'log',
          payload: gateway.scheduled.last.payload,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(opened, ['a', 'b']);
    },
  );
}
