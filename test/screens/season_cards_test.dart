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
      child: const MaterialApp(
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

  testWidgets('MG-T01: both goals are on the plan screen, with priorities', (
    tester,
  ) async {
    await tester.pumpWidget(host([marathon, brevet], null));
    await tester.pumpAndSettle();
    expect(find.text('Marathon · A'), findsOneWidget);
    expect(find.text('Brevet 200 · B'), findsOneWidget);
    expect(find.textContaining('7:30:00'), findsOneWidget);
    expect(find.textContaining('26.7 km/h'), findsOneWidget);
    expect(find.textContaining('1500'), findsOneWidget);
  });

  testWidgets('one goal looks as it always did', (tester) async {
    await tester.pumpWidget(host([marathon], null));
    await tester.pumpAndSettle();
    expect(find.text('Marathon'), findsOneWidget);
    expect(find.textContaining('Season'), findsNothing);
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
