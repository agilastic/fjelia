import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/activity_history_provider.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/providers/week_start_provider.dart';
import 'package:fjelia/screens/activities/weekly_load_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Issue #5: the 12-week history switches between load, time and distance
/// in every language, not only in English.
void main() {
  final day = DateTime(2026, 11, 4);
  ActivityRecord run(int daysAgo) => ActivityRecord(
    id: daysAgo,
    activityId: 'a$daysAgo',
    name: 'Run',
    type: 'running',
    startDate: DateTime(day.year, day.month, day.day - daysAgo, 7),
    durationSeconds: 5400,
    distanceMeters: 15000,
    trainingLoad: 80,
  );

  for (final (locale, time, distance) in [
    (const Locale('de'), 'Zeit', 'Distanz'),
    (const Locale('en'), 'Time', 'Distance'),
  ]) {
    testWidgets('switching metric in ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(420, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loadActivitiesProvider.overrideWith(
              (ref) async => [run(0), run(8)],
            ),
            selectedDateProvider.overrideWith((ref) => day),
            weekStartsOnMondayProvider.overrideWithValue(true),
          ],
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: WeeklyLoadCard()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The last bar is this week: one run.
      String lastBar() =>
          tester.widgetList<Tooltip>(find.byType(Tooltip)).last.message!;
      expect(lastBar(), endsWith('pts (so far)'));
      await tester.tap(find.text(time));
      await tester.pumpAndSettle();
      expect(lastBar(), contains('1.5 h'));
      await tester.tap(find.text(distance));
      await tester.pumpAndSettle();
      expect(lastBar(), contains('15.0 km'));
    });
  }
}
