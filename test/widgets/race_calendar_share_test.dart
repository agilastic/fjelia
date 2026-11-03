import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/widgets/race_calendar_share.dart';

RaceGoal _goal(
  String name,
  DateTime date,
  String priority, {
  double km = 42.195,
  double? up,
  int? target,
}) => RaceGoal(
  id: name,
  athleteId: 'self',
  name: name,
  primarySport: 'running',
  distanceM: km * 1000,
  targetFinishSeconds: target,
  raceDate: date,
  priority: priority,
  elevationM: up,
  source: 'manual',
  createdAt: DateTime(2026),
  participation: 'racing',
);

final _goals = [
  _goal(
    'Zugspitz Ultratrail',
    DateTime(2027, 6, 19),
    'A',
    km: 106,
    up: 5400,
    target: 17 * 3600,
  ),
  _goal('Hannover Marathon', DateTime(2027, 4, 11), 'B', target: 12300),
  // Nine in all: only eight fit the image.
  for (var i = 0; i < 7; i++)
    _goal('Parkrun $i', DateTime(2027, 9, 1 + i * 7), 'C', km: 5),
];

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  for (final style in RaceCalendarStyle.values) {
    testWidgets('${style.name}: soonest first, eight at most, signed', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(RaceCalendarCard(goals: _goals, style: style)),
      );
      expect(tester.takeException(), isNull);
      final names = [
        for (final t in tester.widgetList<Text>(find.byType(Text)))
          if (t.data case final d?
              when d.toLowerCase().contains('marathon') ||
                  d.toLowerCase().contains('zugspitz'))
            d.toLowerCase(),
      ];
      expect(names.first, contains('marathon'));
      expect(find.textContaining('Parkrun 6'), findsNothing);
      expect(find.textContaining('fjelia.com'), findsOneWidget);
      // Target times stay private unless shown.
      expect(find.textContaining('17:00:00'), findsNothing);
    });
  }

  testWidgets('target times appear when switched on', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(RaceCalendarSharePage(goals: _goals)));
    expect(find.textContaining('17:00:00'), findsNothing);
    await tester.tap(find.text('Show target times'));
    await tester.pump();
    expect(find.textContaining('17:00:00'), findsOneWidget);
    await tester.tap(find.text('Tickets'));
    await tester.pump();
    expect(find.textContaining('17:00:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
