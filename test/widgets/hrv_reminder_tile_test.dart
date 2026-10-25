import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/hrv_reminder_provider.dart';
import 'package:fjelia/services/notifications/local_notification_gateway.dart';
import 'package:fjelia/widgets/hrv_reminder_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationGateway gateway;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway(
      state: NotificationPermission.notDetermined,
    );
  });
  tearDown(() => db.close());

  Future<void> load(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump(const Duration(milliseconds: 40));
    }
  }

  Future<void> show(WidgetTester tester, {bool sensor = true}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          localNotificationGatewayProvider.overrideWithValue(gateway),
          hrvSensorReadyProvider.overrideWithValue(() async => sensor),
        ],
        child: const MaterialApp(home: Scaffold(body: HrvReminderTile())),
      ),
    );
    await load(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('off by default, with the honest timing sentence', (
    tester,
  ) async {
    await show(tester);
    expect(
      find.text('Remind me to measure HRV after training'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Around 30 minutes after training, when the workout is available in time.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    // Nothing was asked of the system just by showing the setting.
    expect(gateway.permissionRequests, isEmpty);
    await close(tester);
  });

  testWidgets('without a remembered strap it cannot be switched on', (
    tester,
  ) async {
    await show(tester, sensor: false);
    expect(find.text('Pair a Polar H10 first.'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
      isNull,
    );
    await close(tester);
  });

  testWidgets('switching on asks once and offers quiet hours', (tester) async {
    await show(tester);
    await tester.tap(find.byType(Switch).first);
    await load(tester);
    expect(gateway.permissionRequests, hasLength(1));
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      isTrue,
    );
    expect(find.text('No reminders from 22:00 to 07:00'), findsOneWidget);
    final prefs = await db.select(db.hrvReminderPreferences).getSingle();
    expect(prefs.optedIn, isTrue);
    expect(prefs.enabledSinceUtc, isNotNull);

    await tester.tap(find.byType(Switch).last);
    await load(tester);
    expect(
      (await db.select(db.hrvReminderPreferences).getSingle()).quietEnabled,
      isTrue,
    );
    await close(tester);
  });

  testWidgets('HRV-T067 refused permission says so and the data stays usable', (
    tester,
  ) async {
    gateway.state = NotificationPermission.denied;
    await show(tester);
    await tester.tap(find.byType(Switch).first);
    await load(tester);
    expect(
      find.text(
        'Notifications are off. You can still measure from your workout.',
      ),
      findsWidgets,
    );
    // No second prompt for an answer the system already has.
    expect(gateway.permissionRequests, isEmpty);
    await close(tester);
  });

  testWidgets(
    'switching off cancels what was scheduled and keeps the history',
    (tester) async {
      await show(tester);
      await tester.tap(find.byType(Switch).first);
      await load(tester);
      await tester.tap(find.byType(Switch).first);
      await load(tester);
      expect(
        (await db.select(db.hrvReminderPreferences).getSingle()).optedIn,
        isFalse,
      );
      expect(find.text('No reminders from 22:00 to 07:00'), findsNothing);
      await close(tester);
    },
  );

  testWidgets('a quiet provisional permission is explained', (tester) async {
    gateway.state = NotificationPermission.provisional;
    await show(tester);
    await tester.tap(find.byType(Switch).first);
    await load(tester);
    expect(
      find.text('Reminders arrive quietly in the notification list.'),
      findsOneWidget,
    );
    await close(tester);
  });

  testWidgets('diagnostics show states and counts, never health values', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.byType(Switch).first);
    await load(tester);
    await tester.tap(find.text('Reminder diagnostics'));
    await load(tester);
    final text = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join('\n');
    expect(text, contains('policy hrv-v1, analysis paired-response-v1'));
    expect(text, contains('reminder on, permission granted'));
    expect(text, contains('episodes 0, active links 0'));
    expect(text, contains('owned platform requests 0, pending operations 0'));
    expect(text, isNot(contains('RMSSD')));
    await close(tester);
  });
}
