import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/workout_destination_provider.dart';
import 'package:fjelia/screens/planner/plan_adjustments_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  // Monday and Tuesday of a week with a ride swapped forward.
  final monday = DateTime(2026, 11, 9), tuesday = DateTime(2026, 11, 10);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          pushProvidersProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: PlanAdjustmentsCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> seed(WidgetTester tester) => tester.runAsync(() async {
    final before = TrainingSession(
      id: 'ride',
      planId: 'p',
      athleteId: 'self',
      sessionDate: tuesday,
      sessionNumber: 1,
      weekNumber: 1,
      sport: 'cycling_road',
      sessionType: 'endurance',
      phase: 'base',
      primaryZone: 2,
      title: 'Endurance ride',
      plannedDurationMin: 60,
      plannedTrimp: 60,
      sessionLevel: 1,
      tspAdjusted: false,
      status: 'planned',
      createdByCoach: false,
      adjustedByCoach: false,
      addedByAthlete: false,
      historical: false,
      indoor: false,
      isMovedFromDifferentWeek: false,
      locked: false,
    );
    await db
        .into(db.trainingSessions)
        .insert(
          before
              .copyWith(sessionDate: monday, status: 'completed')
              .toCompanion(true),
        );
    await db
        .into(db.planAdjustments)
        .insert(
          PlanAdjustmentsCompanion.insert(
            id: 'x',
            groupId: 'g',
            createdAt: DateTime.now(),
            kind: 'swap',
            sessionId: 'ride',
            activityId: const Value('a1'),
            beforeJson: jsonEncode(before.toJson()),
            reasonCode: 'swap',
            paramsJson: Value(
              jsonEncode({
                'session': 'Endurance ride',
                'activity': 'Morning ride',
                'from': tuesday.toIso8601String(),
                'to': monday.toIso8601String(),
              }),
            ),
          ),
        );
  });

  testWidgets('shows the reason and undoes the change', (tester) async {
    await seed(tester);
    await pump(tester);
    expect(find.text('PLAN ADJUSTED AUTOMATICALLY'), findsOneWidget);
    expect(
      find.text('Endurance ride: done on Monday instead of Tuesday.'),
      findsOneWidget,
    );

    await tester.runAsync(() async {
      await tester.tap(find.text('Undo'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    final ride = await tester.runAsync(
      () => db.select(db.trainingSessions).getSingle(),
    );
    expect(ride!.status, 'planned');
    expect(ride.sessionDate, tuesday);
    expect(find.text('PLAN ADJUSTED AUTOMATICALLY'), findsNothing);
    expect(find.text('Change undone.'), findsOneWidget);
  });

  testWidgets('OK puts the note away and keeps the change', (tester) async {
    await seed(tester);
    await pump(tester);
    await tester.runAsync(() async {
      await tester.tap(find.text('OK'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('PLAN ADJUSTED AUTOMATICALLY'), findsNothing);
    final ride = await tester.runAsync(
      () => db.select(db.trainingSessions).getSingle(),
    );
    expect(ride!.status, 'completed');
  });
}
