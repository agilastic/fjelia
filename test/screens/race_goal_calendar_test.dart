import 'package:fjelia/l10n/app_localizations.dart';

import 'dart:convert';

import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:fjelia/screens/settings/race_goal_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openCalendar(WidgetTester tester) async {
    final button = find.widgetWithIcon(
      OutlinedButton,
      Icons.calendar_month_outlined,
    );
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  for (final mondayFirst in [true, false]) {
    for (final editing in [false, true]) {
      testWidgets(
        '${editing ? 'editing' : 'adding'} a race goal uses the saved '
        '${mondayFirst ? 'Monday' : 'Sunday'} week start',
        (tester) async {
          FlutterSecureStorage.setMockInitialValues({
            'user_profile_v1': jsonEncode({'weekStartsOnMonday': mondayFirst}),
          });
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(393, 1000);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          final now = DateTime.now();
          final goal = RaceGoal(
            id: 'race',
            athleteId: 'self',
            name: 'Spring race',
            primarySport: 'running',
            distanceM: 10000,
            raceDate: DateTime(now.year + 1, 4, 15),
            priority: 'a',
            source: 'manual',
            createdAt: now,
            participation: 'committed',
          );
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: RaceGoalEditor(goal: editing ? goal : null),
                ),
              ),
            ),
          );
          final editorContext = tester.element(find.byType(RaceGoalEditor));
          final container = ProviderScope.containerOf(editorContext);
          await container.read(userProfileProvider.future);
          await tester.pumpAndSettle();
          await openCalendar(tester);

          final calendar = find.byType(CalendarDatePicker);
          final initial = tester
              .widget<CalendarDatePicker>(calendar)
              .initialDate!;
          final grid = find
              .descendant(of: calendar, matching: find.byType(GridView))
              .first;
          final texts = find.descendant(of: grid, matching: find.byType(Text));
          expect(
            tester.widgetList<Text>(texts).take(7).map((text) => text.data),
            mondayFirst
                ? ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                : ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
          );
          // Check actual dates under the headings across the week boundary.
          final month = DateTime(initial.year, initial.month);
          final sunday = DateTime(
            month.year,
            month.month,
            1 + (DateTime.sunday - month.weekday) % 7,
          );
          final monday = DateTime(sunday.year, sunday.month, sunday.day + 1);
          Finder day(DateTime date) => find.descendant(
            of: grid,
            matching: find.byKey(ValueKey<DateTime>(date)),
          );
          expect(
            tester.getCenter(day(sunday)).dx,
            closeTo(tester.getCenter(texts.at(mondayFirst ? 6 : 0)).dx, .1),
          );
          expect(
            tester.getCenter(day(monday)).dx,
            closeTo(tester.getCenter(texts.at(mondayFirst ? 0 : 1)).dx, .1),
          );
          expect(
            MaterialLocalizations.of(editorContext).firstDayOfWeekIndex,
            0,
          ); // The override belongs only to the race date dialog.

          await tester.tap(day(sunday));
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
          await openCalendar(tester);
          expect(
            tester.widget<CalendarDatePicker>(calendar).initialDate,
            sunday,
          );
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          await tester.pumpWidget(const SizedBox());
          await tester.pump(Duration.zero);
        },
      );
    }
  }
}
