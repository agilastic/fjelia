import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/models/week_progress.dart';
import 'package:fjelia/screens/activities/load_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final monday = DateTime(2026, 10, 19);

  group('WeekProgress', () {
    test('a running week knows how far it is', () {
      final p = WeekProgress(
        weekStart: monday,
        now: DateTime(2026, 10, 21, 15),
      );
      expect(p.inProgress, isTrue);
      expect(p.daysElapsed, 3);
      // Wednesday 15:00 of the previous week.
      expect(p.previousCutoff, DateTime(2026, 10, 14, 15));
    });

    test('the first and last day of a week', () {
      expect(
        WeekProgress(
          weekStart: monday,
          now: DateTime(2026, 10, 19, 6),
        ).daysElapsed,
        1,
      );
      expect(
        WeekProgress(
          weekStart: monday,
          now: DateTime(2026, 10, 25, 23),
        ).daysElapsed,
        7,
      );
    });

    test('a finished or future week is not in progress', () {
      final past = WeekProgress(weekStart: monday, now: DateTime(2026, 10, 27));
      expect(past.inProgress, isFalse);
      expect(past.daysElapsed, 7);
      expect(past.previousCutoff, monday);
      expect(
        WeekProgress(weekStart: monday, now: DateTime(2026, 10, 10)).inProgress,
        isFalse,
      );
    });
  });

  group('weeklyLoadHeadline', () {
    final running = WeekProgress(
      weekStart: monday,
      now: DateTime(2026, 10, 21, 15),
    );
    final finished = WeekProgress(
      weekStart: monday,
      now: DateTime(2026, 11, 2),
    );

    test('a running week is compared with the same days last week', () {
      expect(
        weeklyLoadHeadline(
          weekNumber: 43,
          current: 120,
          previousComparable: 100,
          progress: running,
        ),
        'Week 43, day 3 of 7: 120 pts so far, 20% above the same days last week.',
      );
      expect(
        weeklyLoadHeadline(
          weekNumber: 43,
          current: 60,
          previousComparable: 100,
          progress: running,
        ),
        contains('40% below the same days last week'),
      );
    });

    test('a finished week is compared with the week before', () {
      expect(
        weeklyLoadHeadline(
          weekNumber: 42,
          current: 305,
          previousComparable: 300,
          progress: finished,
        ),
        'Week 42: 305 pts, about the same as the week before.',
      );
    });

    test('no activity yet is not a drop', () {
      expect(
        weeklyLoadHeadline(
          weekNumber: 43,
          current: 0,
          previousComparable: 300,
          progress: WeekProgress(
            weekStart: monday,
            now: DateTime(2026, 10, 19, 9),
          ),
        ),
        'Week 43, day 1 of 7: no activity on record yet.',
      );
    });

    test('without a comparison it only states the amount', () {
      expect(
        weeklyLoadHeadline(
          weekNumber: 43,
          current: 50,
          previousComparable: 0,
          progress: running,
        ),
        'Week 43, day 3 of 7: 50 pts so far.',
      );
    });
  });

  testWidgets('the running week is marked in the bar chart', (tester) async {
    Widget chart({required bool running}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: LoadWeekBars(
          dates: [for (var i = 0; i < 4; i++) DateTime(2026, 10, 5 + 7 * i)],
          values: const [100, 120, 90, 40],
          limit: true,
          inProgressLast: running,
        ),
      ),
    );
    String tip(String date) => tester
        .widgetList<Tooltip>(find.byType(Tooltip))
        .map((t) => t.message!)
        .firstWhere((m) => m.startsWith(date));

    await tester.pumpWidget(chart(running: true));
    expect(tip('26 Oct'), endsWith('(so far)'));
    expect(tip('19 Oct'), isNot(contains('so far')));
    await tester.pumpWidget(chart(running: false));
    expect(tip('26 Oct'), isNot(contains('so far')));
  });
}
