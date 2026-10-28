import 'package:fjelia/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/workout_nutrition.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/hrv_reminder_provider.dart';
import 'package:fjelia/providers/nutrition_provider.dart';
import 'package:fjelia/services/nutrition_service.dart';
import 'package:fjelia/widgets/nutrition_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late ActivityRecord activity;
  final w = NutritionWorkout(
    key: 'plan:one',
    title: 'Long trail run',
    sport: 'trail_running',
    date: DateTime(2026, 10, 28),
    minutes: 180,
    zone: 2,
  );
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    activity = ActivityRecord(
      id: 1,
      activityId: 'a',
      name: 'Trail run',
      type: 'trail_running',
      startDate: DateTime.now().subtract(const Duration(minutes: 100)),
      durationSeconds: 5400,
    );
    await db.into(db.activityRecords).insert(activity);
  });
  tearDown(() => db.close());
  Future<void> show(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          localNotificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          nutritionConditionsProvider(w).overrideWith(
            (ref) async => const NutritionConditions(
              temperature: 30,
              humidity: 80,
              ascent: 800,
              surface: 'Technical',
              forecast: true,
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final list = find.byType(ListView).last;
    await tester.scrollUntilVisible(
      find.text(label),
      180,
      scrollable: find
          .descendant(of: list, matching: find.byType(Scrollable))
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'strategy shows rates, product packing and sport/condition guidance at phone width',
    (tester) async {
      await show(tester, PlannedNutritionCard(workout: w));
      expect(find.textContaining('60 g carbs/h'), findsOneWidget);
      expect(find.textContaining('700 ml/h'), findsOneWidget);
      expect(find.textContaining('Carry about 8'), findsOneWidget);
      await tester.tap(find.text('Conditions and feeding plan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Day forecast'), findsOneWidget);
      expect(find.textContaining('time on feet'), findsOneWidget);
      expect(find.textContaining('aid stations'), findsOneWidget);
      expect(
        (await NutritionService(db).savedPlan(w.key))!.conditions.ascent,
        800,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets(
    'history starts unknown and requires an explicit zero-intake confirmation',
    (tester) async {
      await show(tester, ActivityNutritionCard(activity: activity));
      expect(find.text('Intake not recorded'), findsOneWidget);
      await tester.tap(find.text('Log food and fluids'));
      await tester.pumpAndSettle();
      await tap(tester, 'Finish intake log');
      expect((await NutritionService(db).log('a')).finished, isFalse);
      expect(find.textContaining('Add an item or confirm'), findsOneWidget);
      await tap(tester, 'I had no intake');
      await tap(tester, 'Finish intake log');
      expect((await NutritionService(db).log('a')).noIntake, isTrue);
      expect(find.text('Confirmed: no intake'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets(
    'actual product servings and changed label values are saved, not copied from the plan',
    (tester) async {
      await show(tester, ActivityNutritionCard(activity: activity));
      await tester.tap(find.text('Log food and fluids'));
      await tester.pumpAndSettle();
      await tap(tester, 'Add food or drink');
      await tester.tap(find.widgetWithText(ActionChip, 'Gel'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), '2');
      await tester.enterText(find.byType(TextFormField).at(3), '30');
      await tap(tester, 'Apply');
      await tap(tester, 'Finish intake log');
      final log = await NutritionService(db).log('a');
      expect(log.total((e) => e.carbs, during: true), 60);
      expect(log.status, 'complete');
      expect(log.entries.single.quantity, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets('completed workout details do not invent a retrospective plan', (
    tester,
  ) async {
    await show(tester, PlannedNutritionCard(workout: w, editable: false));
    expect(
      find.text('No pre-workout nutrition strategy was saved.'),
      findsOneWidget,
    );
    expect(find.text('Edit strategy'), findsNothing);
    expect(await NutritionService(db).savedPlan(w.key), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets(
    'new weather prompts review while preserving the saved baseline',
    (tester) async {
      final plan = planNutrition(
        w,
        const NutritionPreferences(),
        const NutritionConditions(temperature: 12, forecast: true),
      );
      await NutritionService(db).savePlan(plan);
      await show(tester, PlannedNutritionCard(workout: w));
      expect(find.textContaining('Forecast updated'), findsOneWidget);
      expect(
        (await NutritionService(db).savedPlan(w.key))!.conditions.temperature,
        12,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
