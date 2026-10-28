import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/hrv_reminder_provider.dart';
import 'package:fjelia/providers/nutrition_provider.dart';
import 'package:fjelia/services/notifications/local_notification_gateway.dart';
import 'package:fjelia/widgets/nutrition_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_notification_gateway.dart';

/// A gateway where the system has already refused: no prompt is possible.
class _Refusing extends FakeNotificationGateway {
  _Refusing() : super(state: NotificationPermission.denied);
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump(const Duration(milliseconds: 40));
    }
  }

  Future<ProviderContainer> show(
    WidgetTester tester,
    FakeNotificationGateway gateway,
  ) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          localNotificationGatewayProvider.overrideWithValue(gateway),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: NutritionPreferencesTile()),
            );
          },
        ),
      ),
    );
    await settle(tester);
    return container;
  }

  Switch theSwitch(WidgetTester tester) =>
      tester.widget<Switch>(find.byType(Switch));

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('an enabled reminder checks and asks for permission', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway(
      state: NotificationPermission.notDetermined,
    );
    final container = await show(tester, gateway);
    // On by default: the system is asked as soon as the setting is shown.
    expect(gateway.permissionRequests, [NotificationPermission.notDetermined]);
    expect(theSwitch(tester).value, isTrue);
    expect(
      (await container.read(nutritionPreferencesProvider.future)).reminders,
      isTrue,
    );
    // The old extra link is gone.
    expect(find.text('Enable workout notifications'), findsNothing);
    await close(tester);
  });

  testWidgets('switching it on again asks again and switches on', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway();
    final container = await show(tester, gateway);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(theSwitch(tester).value, isFalse);
    expect(
      (await container.read(nutritionPreferencesProvider.future)).reminders,
      isFalse,
    );
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(theSwitch(tester).value, isTrue);
    expect(gateway.permissionRequests, isNotEmpty);
    await close(tester);
  });

  testWidgets('a refused permission keeps it off and says why', (tester) async {
    final gateway = _Refusing();
    final container = await show(tester, gateway);
    // Enabled in the saved settings, but the system blocks it: shown as off.
    expect(theSwitch(tester).value, isFalse);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(theSwitch(tester).value, isFalse);
    expect(find.textContaining('needs notifications'), findsOneWidget);
    expect(find.text('Enable workout notifications'), findsNothing);
    expect(
      (await container.read(nutritionPreferencesProvider.future)).reminders,
      isTrue,
    );
    await close(tester);
  });
}
