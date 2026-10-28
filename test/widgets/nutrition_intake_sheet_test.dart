import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/models/workout_nutrition.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/nutrition_provider.dart';
import 'package:fjelia/widgets/nutrition_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<ActivityRecord> activity() async {
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'swim',
            name: 'Schwimmbad',
            type: 'swimming',
            startDate: DateTime.now().subtract(const Duration(hours: 2)),
            durationSeconds: 83 * 60,
            distanceMeters: const Value(1500),
            source: const Value('garmin'),
          ),
        );
    return (db.select(db.activityRecords)).getSingle();
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump(const Duration(milliseconds: 40));
    }
  }

  Future<void> show(WidgetTester tester, ActivityRecord a) async {
    tester.view.physicalSize = const Size(1170, 6000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: NutritionIntakeSheet(activity: a)),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('an empty log is clear: header, choice, hint, add, actions', (
    tester,
  ) async {
    await show(tester, await activity());
    expect(find.text('Schwimmbad'), findsOneWidget);
    expect(find.text('WHAT DID YOU HAVE?'), findsOneWidget);
    expect(find.text('I had something'), findsOneWidget);
    expect(find.text('Nothing'), findsOneWidget);
    expect(find.textContaining('Nothing added yet'), findsOneWidget);
    expect(find.text('Add food or drink'), findsOneWidget);
    expect(find.text('Finish intake log'), findsOneWidget);
    expect(find.text('Save draft'), findsOneWidget);
    // No totals before there is something to add up.
    expect(find.text('TOTAL INTAKE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('entries show their numbers and add up with the hourly rate', (
    tester,
  ) async {
    final a = await activity();
    await ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)])
        .read(nutritionServiceProvider)
        .saveLog(
          a.activityId,
          const NutritionLog(
            status: 'draft',
            gut: 'Comfortable',
            entries: [
              NutritionEntry(name: 'Gel', quantity: 2, carbs: 25),
              NutritionEntry(
                name: 'Sports drink',
                fluid: 500,
                carbs: 30,
                sodium: 250,
              ),
            ],
          ),
        );
    await show(tester, a);
    expect(find.textContaining('Gel'), findsWidgets);
    expect(find.text('50 g carbs'), findsOneWidget);
    expect(find.text('TOTAL INTAKE'), findsOneWidget);
    // 80 g carbs over 83 minutes is about 58 g/h.
    expect(find.text('80'), findsOneWidget);
    expect(find.text('58 g/h'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Nothing" hides the list and the totals', (tester) async {
    await show(tester, await activity());
    await tester.tap(find.text('Nothing'));
    await tester.pump();
    expect(find.text('Add food or drink'), findsNothing);
    expect(find.textContaining('Nothing added yet'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
