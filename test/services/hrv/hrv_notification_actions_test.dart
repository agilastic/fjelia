import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/spot_hrv.dart';
import 'package:fjelia/services/hrv/hrv_notification_action_router.dart';
import 'package:fjelia/services/hrv/hrv_post_reminder_coordinator.dart';
import 'package:fjelia/services/notifications/local_notification_adapter.dart';
import 'package:fjelia/services/notifications/local_notification_gateway.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_notification_gateway.dart';
import '../../support/hrv_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('payload', () {
    const p = HrvNotificationPayload(
      epoch: 'e1',
      reminderId: 'r1',
      generation: 3,
      episodeId: 'ep1',
    );

    test('round trips and holds nothing but identity', () {
      final raw = p.encode();
      final back = HrvNotificationPayload.decode(raw)!;
      expect(back.epoch, 'e1');
      expect(back.reminderId, 'r1');
      expect(back.generation, 3);
      expect(back.episodeId, 'ep1');
      // No health value, no note, no time.
      expect(raw, isNot(contains('ms')));
      expect(raw.length, lessThan(120));
    });

    test('malformed, oversized or foreign payloads are refused', () {
      expect(HrvNotificationPayload.decode(null), isNull);
      expect(HrvNotificationPayload.decode(''), isNull);
      expect(HrvNotificationPayload.decode('nope'), isNull);
      expect(HrvNotificationPayload.decode('[]'), isNull);
      expect(
        HrvNotificationPayload.decode('{"v":2,"e":"a","r":"b","g":1,"ep":"c"}'),
        isNull,
      );
      expect(
        HrvNotificationPayload.decode(
          '{"v":1,"e":"a","r":"b","g":"1","ep":"c"}',
        ),
        isNull,
      );
      expect(
        HrvNotificationPayload.decode('{"v":1,"e":"","r":"b","g":1,"ep":"c"}'),
        isNull,
      );
      expect(
        HrvNotificationPayload.decode(
          '{"v":1,"e":"${'x' * 100}","r":"b","g":1,"ep":"c"}',
        ),
        isNull,
      );
      expect(HrvNotificationPayload.decode('x' * 500), isNull);
    });

    test('the wording is generic and promises no exact time', () {
      for (final code in [
        'en', 'de', 'fr', 'it', 'es', 'ca', 'nb', 'sk', 'fi', 'da', //
      ]) {
        final t = HrvReminderTexts.forLanguage(code);
        expect(t.body, isNot(contains('30')));
        expect(t.title, isNot(contains('30')));
      }
      expect(
        HrvReminderTexts.forLanguage('de-DE').title,
        contains('Nachmessung'),
      );
      expect(
        HrvReminderTexts.forLanguage('sw').title,
        contains('post-training'),
      );
    });
  });

  group('background inbox', () {
    test(
      'keeps a valid action for the foreground, bounded and clearable',
      () async {
        final at = DateTime.utc(2026, 11, 2, 10, 35);
        await HrvActionInbox.append(HrvInboxEntry('snooze', 'p1', at));
        final taken = await HrvActionInbox.take();
        expect(taken.single.actionId, 'snooze');
        expect(taken.single.receivedAt, at);
        expect(await HrvActionInbox.take(), isEmpty);

        for (var i = 0; i < 40; i++) {
          await HrvActionInbox.append(HrvInboxEntry('open', 'p$i', at));
        }
        final capped = await HrvActionInbox.take();
        expect(capped, hasLength(20));
        expect(capped.last.payload, 'p39');
      },
    );

    test('a corrupt line is skipped', () async {
      SharedPreferences.setMockInitialValues({
        'hrv_notification_action_inbox_v1': [
          'not json',
          '{"a":"skip","p":null,"t":1}',
        ],
      });
      final taken = await HrvActionInbox.take();
      expect(taken.map((e) => e.actionId), ['skip']);
    });

    test('the background handler stores only well-formed payloads', () async {
      const good = HrvNotificationPayload(
        epoch: 'e',
        reminderId: 'r',
        generation: 1,
        episodeId: 'ep',
      );
      hrvNotificationBackgroundHandler(
        const fln.NotificationResponse(
          notificationResponseType:
              fln.NotificationResponseType.selectedNotificationAction,
          actionId: 'snooze',
          payload: 'garbage',
        ),
      );
      hrvNotificationBackgroundHandler(
        fln.NotificationResponse(
          notificationResponseType:
              fln.NotificationResponseType.selectedNotificationAction,
          actionId: 'snooze',
          payload: good.encode(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final taken = await HrvActionInbox.take();
      expect(taken, hasLength(1));
      expect(taken.single.actionId, 'snooze');
    });
  });

  group('router', () {
    late AppDatabase db;
    late FakeNotificationGateway gateway;
    late HrvPostReminderCoordinator coordinator;
    var clock = atMin(-600);

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      gateway = FakeNotificationGateway();
      clock = atMin(-600);
      coordinator = HrvPostReminderCoordinator(
        db: db,
        gateway: gateway,
        sensorReady: () async => true,
        clock: () => clock,
      );
    });
    tearDown(() => db.close());

    Future<NotificationResponse> due(String action) async {
      await coordinator.setEnabled(true);
      await addActivity(db, 'a1', 0, 120);
      await addReading(db, -20, SpotHrvContext.beforeTraining, uid: 'pre');
      clock = atMin(121);
      await coordinator.reconcile();
      clock = atMin(152);
      final r = await db.select(db.hrvPostReminders).getSingle();
      return NotificationResponse(
        actionId: action,
        payload: HrvNotificationPayload(
          epoch: r.installationEpoch,
          reminderId: r.reminderId,
          generation: r.generation,
          episodeId: r.episodeId,
        ).encode(),
      );
    }

    HrvNotificationActionRouter build(
      List<ActionResult> results, {
      List<HrvInboxEntry> inbox = const [],
    }) {
      final router = HrvNotificationActionRouter(
        coordinator: coordinator,
        gateway: gateway,
        inbox: () async => inbox,
      );
      router.onResult = (r) async {
        results.add(r);
      };
      router.attach();
      return router;
    }

    test(
      'HRV-T069 a response before the app is ready waits, then runs once',
      () async {
        final measure = await due('measure');
        final results = <ActionResult>[];
        final router = build(results);
        addTearDown(router.dispose);
        gateway.respond(measure);
        gateway.respond(measure); // the same callback twice
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(results, isEmpty);
        await router.markReady();
        expect(results.map((r) => r.kind), [ActionKind.startMeasurement]);
      },
    );

    test('a cold-launch response is taken once', () async {
      final measure = await due('measure');
      gateway.launch = measure;
      final results = <ActionResult>[];
      final router = build(results);
      addTearDown(router.dispose);
      await router.markReady();
      await router.markReady();
      expect(results.map((r) => r.kind), [ActionKind.startMeasurement]);
      expect(gateway.launch, isNull);
    });

    test('after it is ready, responses run straight away', () async {
      final skip = await due('skip');
      final results = <ActionResult>[];
      final router = build(results);
      addTearDown(router.dispose);
      await router.markReady();
      gateway.respond(skip);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(results.map((r) => r.kind), [ActionKind.skipped]);
    });

    test('HRV-D12 a snooze taken in the background counts from when it was taken', () async {
      final snooze = await due('snooze');
      final results = <ActionResult>[];
      final taken = atMin(150);
      final router = build(
        results,
        inbox: [HrvInboxEntry('snooze', snooze.payload, taken.toUtc())],
      );
      addTearDown(router.dispose);
      await router.markReady();
      expect(results.single.kind, ActionKind.snoozed);
      final row = await db.select(db.hrvPostReminders).getSingle();
      // Ten minutes from the tap, not from the later moment the app was opened.
      expect(row.nextDueAtUtc.toUtc(), atMin(160));
    });

    test('unknown or stale responses never reach the screen', () async {
      await due('measure');
      final results = <ActionResult>[];
      final router = build(results);
      addTearDown(router.dispose);
      await router.markReady();
      gateway.respond(
        const NotificationResponse(actionId: 'open', payload: 'bad'),
      );
      gateway.respond(const NotificationResponse(actionId: 'open'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(results, isEmpty);
    });

    test(
      'a tap on a finished reminder shows the workout, never a capture',
      () async {
        final tap = await due('open');
        await addReading(db, 151, SpotHrvContext.afterTraining);
        clock = atMin(160);
        final results = <ActionResult>[];
        final router = build(results);
        addTearDown(router.dispose);
        await router.markReady();
        gateway.respond(tap);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(results.single.kind, ActionKind.showEpisode);
      },
    );
  });
}
