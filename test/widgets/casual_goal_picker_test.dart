import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/widgets/casual_goal_picker.dart';

void main() {
  testWidgets('the aim without a race is chosen and explained', (tester) async {
    String? value;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => CasualGoalPicker(
              value: value,
              hasRaceGoal: true,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('easy 25-minute session'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('casual-goal-fitness')));
    await tester.pump();
    expect(value, 'fitness');
    expect(
      find.text('Build up gently, with one harder session a week.'),
      findsOneWidget,
    );
    // A race goal comes first.
    expect(find.text('Applies once no race goal is set.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('casual-goal-none')));
    await tester.pump();
    expect(value, isNull);
  });
}
