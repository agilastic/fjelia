import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/screens/activities/activities_screen.dart';
import 'package:fjelia/widgets/swipe_action_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  final now = DateTime.now();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    // The hint was shown before: no wiggle in these tests.
    SharedPreferences.setMockInitialValues({'history_swipe_hint_v1': true});
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.runAsync(
      () => db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'g1',
              name: 'Lunch Run',
              type: 'running',
              startDate: now.subtract(const Duration(hours: 3)),
              durationSeconds: 2700,
              distanceMeters: const Value(8000),
              source: const Value('garmin_api'),
            ),
          ),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: ActivityHistory(showHeader: false, rollingDays: 7),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lunch Run'), findsOneWidget);
  }

  testWidgets('swiping left deletes, with undo', (tester) async {
    await pump(tester);
    await tester.drag(find.byType(SwipeActionTile), const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('DELETE'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(await tester.runAsync(() => db.getActivityById('g1')), isNull);
    expect(find.text('Lunch Run deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(await tester.runAsync(() => db.getActivityById('g1')), isNotNull);
    expect(find.text('Lunch Run'), findsOneWidget);
  });

  testWidgets('swiping right asks the coach, the card springs back', (
    tester,
  ) async {
    await pump(tester);
    await tester.drag(find.byType(SwipeActionTile), const Offset(300, 0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ASK COACH'), findsOneWidget);
    await tester.pumpAndSettle();
    final request = container.read(coachRequestProvider)!;
    expect(request.activity!.activityId, 'g1');
    expect(await tester.runAsync(() => db.getActivityById('g1')), isNotNull);
  });

  testWidgets('a short swipe does nothing', (tester) async {
    await pump(tester);
    await tester.drag(find.byType(SwipeActionTile), const Offset(-40, 0));
    await tester.pumpAndSettle();
    expect(find.text('Lunch Run'), findsOneWidget);
    expect(container.read(coachRequestProvider), isNull);
    expect(await tester.runAsync(() => db.getActivityById('g1')), isNotNull);
  });

  testWidgets('older activities load step by step down to the oldest', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final (id, days) in [('d60', 60), ('d400', 400)]) {
        await db
            .into(db.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: id,
                name: 'Run $days',
                type: 'running',
                startDate: now.subtract(Duration(days: days)),
                durationSeconds: 1800,
                source: const Value('garmin_api'),
              ),
            );
      }
    });
    await pump(tester);
    // The date of the oldest activity loads with the list.
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Run 60'), findsNothing);
    var taps = 0;
    while (find.text('No older activities').evaluate().isEmpty && taps < 20) {
      await tester.tap(find.text('Load older activities'));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      taps++;
      // This list starts with 7 days: 49 after one step, 91 after two.
      if (taps == 1) expect(find.text('Run 60'), findsNothing);
      if (taps == 2) expect(find.text('Run 60'), findsOneWidget);
    }
    // 400 days back: ten steps of six weeks after the first seven days.
    expect(taps, 10);
    expect(find.text('Run 400'), findsOneWidget);
  });
}
