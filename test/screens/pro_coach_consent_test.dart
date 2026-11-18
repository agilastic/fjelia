import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/plan_proposal_provider.dart';
import 'package:fjelia/screens/settings/pro_coach_consent.dart';
import 'package:fjelia/services/plan_proposal_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _ask(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => askProCoachOnce(context, ref),
            child: const Text('ask'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ask'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the coach stays off until the athlete answers', () async {
    expect(await PlanProposalStore.proCoach(), isFalse);
    expect(await PlanProposalStore.proCoachAsked(), isFalse);
    await PlanProposalStore.setProCoach(false);
    expect(await PlanProposalStore.proCoachAsked(), isTrue);
  });

  testWidgets('allowing turns the switch on', (tester) async {
    await _ask(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pro-coach-allow')));
    await tester.pumpAndSettle();
    expect(await PlanProposalStore.proCoach(), isTrue);
    expect(await PlanProposalStore.proCoachAsked(), isTrue);
  });

  testWidgets('keeping it on the device is an answer: never asked again', (
    tester,
  ) async {
    await _ask(tester);
    await tester.tap(find.byKey(const ValueKey('pro-coach-deny')));
    await tester.pumpAndSettle();
    expect(await PlanProposalStore.proCoach(), isFalse);

    await tester.tap(find.text('ask'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a choice made with the switch counts as asked', (tester) async {
    await PlanProposalStore.setProCoach(true);
    await _ask(tester);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the dialog cannot be dismissed without an answer', (
    tester,
  ) async {
    await _ask(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  test('the provider reads the stored answer', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(proposalProCoachProvider.future), isFalse);
  });
}
