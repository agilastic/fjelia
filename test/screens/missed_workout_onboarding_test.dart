import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/hrv_reminder_provider.dart';
import 'package:fjelia/screens/onboarding/missed_workout_onboarding_screen.dart';
import 'package:fjelia/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_notification_gateway.dart';

void main() {
  testWidgets('shows the reminder on by default and hides the time when off', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localNotificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.dark(),
          home: const MissedWorkoutOnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Stay on track'), findsOneWidget);
    expect(find.text('Still on your plan today'), findsOneWidget);
    expect(
      find.text('Easy run (45 min). Still today, move it or skip it?'),
      findsOneWidget,
    );
    expect(find.text('Remind me at'), findsOneWidget);
    expect(find.text('9:30 PM'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('onboarding-missed-switch')));
    await tester.pumpAndSettle();
    expect(find.text('Remind me at'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
