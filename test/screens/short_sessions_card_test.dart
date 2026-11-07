import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/screens/planner/short_sessions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('asks why a session was shorter and records the answer', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final started = DateTime.now().subtract(const Duration(hours: 5));
    await tester.runAsync(() async {
      await db
          .into(db.trainingSessions)
          .insert(
            TrainingSessionsCompanion.insert(
              id: 'long',
              planId: 'p',
              athleteId: 'self',
              sessionDate: started,
              sessionNumber: 1,
              weekNumber: 1,
              sport: 'cycling_road',
              sessionType: 'long',
              phase: 'build',
              primaryZone: 2,
              title: 'Long ride',
              plannedDurationMin: 240,
              plannedTrimp: 200,
              sessionLevel: 1,
              status: const Value('completed'),
              actualDurationMin: const Value(120),
            ),
          );
      await db
          .into(db.sessionActuals)
          .insert(
            SessionActualsCompanion.insert(
              sessionId: 'long',
              durationRatio: const Value(.5),
              outcome: const Value('partial'),
              startedAt: Value(started),
            ),
          );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ShortSessionsCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Shorter than planned – why?'), findsOneWidget);
    expect(find.text('Long ride: 120 of 240 min'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Tired'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    final a = await tester.runAsync(
      () => db.select(db.sessionActuals).getSingle(),
    );
    expect(a!.shortReason, 'fatigue');
    expect(a.outcome, 'stoppedFatigue');
    expect(find.text('Shorter than planned – why?'), findsNothing);
  });
}
