import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/screens/planner/plan_overview_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> show(WidgetTester tester, {required bool rest}) =>
      tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: UpcomingWorkoutList(entries: const [], restToday: rest),
          ),
        ),
      );

  testWidgets('a planned rest day today is an item of its own', (tester) async {
    await show(tester, rest: true);
    expect(find.byKey(const Key('rest-day-today')), findsOneWidget);
    expect(find.text('Rest day'), findsOneWidget);
    expect(find.text('Recovery is part of your plan.'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('UPCOMING'), findsOneWidget);
  });

  testWidgets('no rest day, nothing planned: the list stays empty', (
    tester,
  ) async {
    await show(tester, rest: false);
    expect(find.byKey(const Key('rest-day-today')), findsNothing);
    expect(find.text('UPCOMING'), findsNothing);
  });
}
