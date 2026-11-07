import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/planner_providers.dart';
import 'package:fjelia/screens/planner/plan_overview_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

RaceGoal goal(
  String id,
  String name,
  String sport,
  String priority,
  DateTime date, {
  double distanceM = 42195,
  double? elevationM,
  int? target,
}) => RaceGoal(
  id: id,
  athleteId: 'self',
  name: name,
  primarySport: sport,
  distanceM: distanceM,
  targetFinishSeconds: target,
  raceDate: date,
  priority: priority,
  elevationM: elevationM,
  source: 'manual',
  createdAt: DateTime(2026, 10, 25),
  participation: 'committed',
);

Widget host(List<RaceGoal> goals, Map<String, dynamic>? report) =>
    ProviderScope(
      overrides: [
        seasonGoalsProvider.overrideWith((ref) async => goals),
        seasonReportProvider.overrideWith((ref) async => report),
        raceFinishEstimateProvider.overrideWith((ref, goal) async => null),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: RaceCountdownCard())),
      ),
    );

void main() {
  final marathon = goal('m', 'Marathon', 'running', 'a', DateTime(2027, 4, 10));
  final brevet = goal(
    'b',
    'Brevet 200',
    'cycling_road',
    'b',
    DateTime(2027, 3, 20),
    distanceM: 200000,
    elevationM: 1500,
    target: 27000,
  );

  testWidgets('several goals are one slim item: a dot per goal on the season '
      'line and the weeks to the plan\'s goal', (tester) async {
    await tester.pumpWidget(host([marathon, brevet], null));
    await tester.pumpAndSettle();
    expect(find.text('Race goals · 2'), findsOneWidget);
    // The priorities as dots on the line, the details wait behind it.
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.textContaining('weeks'), findsOneWidget);
    expect(find.textContaining('Marathon'), findsNothing);
    expect(find.textContaining('7:30:00'), findsNothing);
    expect(find.textContaining('26.7 km/h'), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('goals-header'))).height,
      lessThanOrEqualTo(60),
    );
  });

  testWidgets('a tap unfolds every goal into its card, a second folds them', (
    tester,
  ) async {
    await tester.pumpWidget(host([marathon, brevet], null));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('goals-header')));
    await tester.pumpAndSettle();
    expect(find.text('Race goals · 2'), findsOneWidget);
    // The full cards, with priorities, target, pace and climbing.
    expect(find.text('Marathon · A'), findsOneWidget);
    expect(find.text('Brevet 200 · B'), findsOneWidget);
    expect(find.textContaining('7:30:00'), findsOneWidget);
    expect(find.textContaining('26.7 km/h'), findsOneWidget);
    expect(find.textContaining('1500'), findsOneWidget);
    expect(find.byIcon(Icons.ios_share), findsOneWidget);
    await tester.tap(find.byKey(const Key('goals-header')));
    await tester.pumpAndSettle();
    expect(find.textContaining('7:30:00'), findsNothing);
    expect(find.textContaining('Marathon'), findsNothing);
  });

  testWidgets('one goal folds the same way, named in the header', (
    tester,
  ) async {
    await tester.pumpWidget(host([marathon], null));
    await tester.pumpAndSettle();
    expect(find.text('Marathon'), findsOneWidget);
    expect(find.textContaining('Race goals'), findsNothing);
    expect(find.textContaining('Season'), findsNothing);
    await tester.tap(find.byKey(const Key('goals-header')));
    await tester.pumpAndSettle();
    // The card without a priority, as before.
    expect(find.text('Marathon'), findsNWidgets(2));
    expect(find.textContaining('Marathon · A'), findsNothing);
  });

  testWidgets('trade-offs and conflicts are told, with what could be done', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        [marathon, brevet],
        {
          'outcome': 'feasibleWithTradeoffs',
          'conflicts': [
            {
              'message': 'Brevet 200 and Marathon are 21 days apart.',
              'alternatives': ['Ride Brevet 200 as a controlled effort'],
            },
          ],
          'summary': ['In 12 of 24 weeks the long sessions are shortened.'],
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Season: with trade-offs'), findsOneWidget);
    expect(find.textContaining('21 days apart'), findsOneWidget);
    await tester.tap(find.text('Season: with trade-offs'));
    await tester.pumpAndSettle();
    expect(find.textContaining('long sessions are shortened'), findsOneWidget);
    expect(find.textContaining('controlled effort'), findsOneWidget);
  });

  testWidgets('a decision that is open is named', (tester) async {
    await tester.pumpWidget(
      host(
        [marathon, brevet],
        {
          'outcome': 'requiresDecision',
          'conflicts': [
            {'message': 'Both are priority A.', 'alternatives': []},
          ],
          'summary': [],
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Season: needs your decision'), findsOneWidget);
  });

  testWidgets('a plainly feasible season shows no extra card', (tester) async {
    await tester.pumpWidget(
      host(
        [marathon, brevet],
        {'outcome': 'feasible', 'conflicts': [], 'summary': []},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Season'), findsNothing);
  });
}
