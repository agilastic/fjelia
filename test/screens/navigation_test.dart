import 'package:fjelia/providers/heat_acclimation_provider.dart';

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fjelia/widgets/plan_view_switcher.dart';
import 'package:fjelia/widgets/day_navigator.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/screens/planner/plan_screen.dart';
import 'package:fjelia/screens/activities/activities_screen.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/sync_provider.dart';
import 'package:fjelia/screens/onboarding/connect_devices_screen.dart';
import 'package:fjelia/screens/onboarding/welcome_screen.dart';
import 'package:fjelia/screens/settings/settings_sheet.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:fjelia/screens/home/home_screen.dart';
import 'package:fjelia/widgets/day_summary_card.dart';
import 'package:fjelia/screens/strain/strain_screen.dart';
import 'package:fjelia/screens/onboarding/training_plan_onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'heat_acclimation_enabled': false});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> show(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          heatPreferredLocationProvider.overrideWith((ref) async => null),
          // No network import in widget tests.
          historyImportStarterProvider.overrideWithValue(() async {}),
        ],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dashboard renders with no data and changes day', (tester) async {
    await show(tester, const HomeScreen());
    expect(find.text('HEALTH'), findsOneWidget);
    expect(find.text('HEALTH MONITOR'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Dispose providers before closing their database.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets(
    'Health LOAD gauge selects the Load tab without opening a sheet',
    (tester) async {
      await show(tester, const HomeScreen());
      await tester.tap(
        find.descendant(
          of: find.byType(DaySummaryCard),
          matching: find.text('LOAD'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StrainScreen), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('DAY TRAINING LOAD'), findsOneWidget);
      await tester.tap(find.text('HEALTH'));
      await tester.pumpAndSettle();
      expect(find.byType(DaySummaryCard), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    },
  );

  testWidgets('Plan toolbar view control replaces day navigation', (
    tester,
  ) async {
    await show(tester, const HomeScreen());
    await tester.tap(find.text('PLAN'));
    await tester.pumpAndSettle();
    expect(find.byType(DayNavigator), findsNothing);
    final switcher = find.byType(PlanViewSwitcher);
    expect(switcher, findsOneWidget);
    expect(
      tester.getTopLeft(switcher).dy,
      lessThan(tester.getTopLeft(find.text('ACTIVITY LOG')).dy),
    );
    expect(
      find.descendant(
        of: switcher,
        matching: find.byType(PopupMenuButton<String>),
      ),
      findsNothing,
    );
    for (final option in ['Month', 'Week', 'List']) {
      await tester.tap(find.byTooltip('$option view'));
      await tester.pumpAndSettle();
      final selected = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byTooltip('$option view'),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(selected.properties.selected, isTrue);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.text('HEALTH'));
    await tester.pumpAndSettle();
    expect(find.byType(DayNavigator), findsOneWidget);
    expect(find.byType(PlanViewSwitcher), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets('Month history follows only the selected calendar day', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'plan_default_view': 'month',
      'heat_acclimation_enabled': false,
    });
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, 10);
    for (final i in [9, 10, 11]) {
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'day-$i',
              name: 'Run on day $i',
              type: 'running',
              startDate: DateTime(now.year, now.month, i, 12),
              durationSeconds: 1800,
            ),
          );
    }
    await show(tester, const Scaffold(body: PlanScreen()));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlanScreen)),
    );
    container.read(selectedDateProvider.notifier).state = day;
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Run on day 10'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Run on day 10'), findsOneWidget);
    expect(find.text('Run on day 9'), findsNothing);
    expect(find.text('Run on day 11'), findsNothing);
    container.read(selectedDateProvider.notifier).state = DateTime(
      now.year,
      now.month,
      11,
    );
    await tester.pumpAndSettle();
    expect(find.text('Run on day 11'), findsOneWidget);
    expect(find.text('Run on day 10'), findsNothing);
    expect(
      tester
          .widget<ActivityHistory>(find.byType(ActivityHistory))
          .selectedDayOnly,
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets('training preferences save and finish onboarding', (
    tester,
  ) async {
    await show(tester, const TrainingPlanOnboardingScreen());
    // No race goal yet: the step offers to add one.
    expect(find.text('Add race goal'), findsOneWidget);
    await tester.tap(find.text('advanced'));
    await tester.pumpAndSettle();
    final finish = find.widgetWithText(FilledButton, 'Save & Continue');
    await tester.scrollUntilVisible(
      finish,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finish);
    await tester.pumpAndSettle();
    await tester.tap(finish);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    final raw = await const FlutterSecureStorage().read(key: 'user_profile_v1');
    final saved = UserProfile.fromJson(
      jsonDecode(raw!) as Map<String, dynamic>,
    );
    expect(saved.experienceLevel, 'advanced');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets('skip opens dashboard without overwriting profile', (
    tester,
  ) async {
    await show(tester, const TrainingPlanOnboardingScreen());
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      await const FlutterSecureStorage().read(key: 'user_profile_v1'),
      isNull,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets('experience level is asked only without a connected source', (
    tester,
  ) async {
    await show(tester, const TrainingPlanOnboardingScreen());
    expect(find.text('EXPERIENCE LEVEL'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          heatPreferredLocationProvider.overrideWith((ref) async => null),
          historyImportStarterProvider.overrideWithValue(() async {}),
          hasHistorySourceProvider.overrideWithValue(true),
        ],
        child: const MaterialApp(home: TrainingPlanOnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('EXPERIENCE LEVEL'), findsNothing);
    expect(find.text('advanced'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets('Settings can run the setup again', (tester) async {
    await show(tester, const Scaffold(body: SettingsSheet()));
    await tester.scrollUntilVisible(
      find.text('Run setup again'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Run setup again'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets('onboarding groups Bluetooth devices and accounts', (
    tester,
  ) async {
    await show(tester, const ConnectDevicesScreen());
    expect(find.text('BLUETOOTH DEVICES'), findsOneWidget);
    expect(find.text('Hilo pod'), findsOneWidget);
    expect(find.text('RENPHO scale'), findsOneWidget);
    expect(find.text('Polar H10'), findsOneWidget);
    // The grid of Bluetooth devices is long enough to push the accounts
    // section below the first screen.
    await tester.scrollUntilVisible(
      find.text('ACCOUNTS & SERVICES'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ACCOUNTS & SERVICES'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Garmin'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Garmin'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
