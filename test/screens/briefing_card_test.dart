import 'package:fjelia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/widgets/briefing_card.dart';
import 'package:fjelia/screens/settings/ai_settings_tab.dart';

class _Settings extends AiCoachSettingsNotifier {
  @override
  Future<AiCoachSettings> build() async => const AiCoachSettings(
    provider: AiProvider.appleIntelligence,
    enabled: true,
  );
}

class _FailedBriefing extends AiBriefingNotifier {
  _FailedBriefing(super.ref, super.period) {
    state = AsyncError(StateError('Model unavailable'), StackTrace.current);
  }
}

class _ReadyBriefing extends AiBriefingNotifier {
  _ReadyBriefing(super.ref, super.period) {
    state = const AsyncData('Line one. Line two. Line three. Line four.');
  }

  @override
  Future<void> load(
    AiCoachSettings settings, {
    Object? monitor,
    String raceGoals = '',
    String? weatherSummary,
    Object? bioAge,
    Object? planInfo,
    bool force = false,
  }) async {}
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets(
    'failed on-device briefing shows labeled non-AI fallback and retry',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiCoachSettingsProvider.overrideWith(_Settings.new),
            aiBriefingProvider.overrideWith(
              (ref, period) => _FailedBriefing(ref, period),
            ),
            briefingSummaryProvider.overrideWith(
              (ref, date) => 'Recovery 70 / 100.',
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: BriefingCard(openCoach: () {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Recovery 70 / 100.'), findsOneWidget);
      expect(
        find.text(
          'Apple Intelligence is unavailable. Showing a non-AI summary.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry AI briefing'), findsOneWidget);
      expect(find.text('read more'), findsNothing);
    },
  );
  testWidgets(
    'Apple provider does not show redundant briefing override switch',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [aiCoachSettingsProvider.overrideWith(_Settings.new)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AiSettingsTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('AI Briefing'), 200);
      expect(find.text('Use Apple Intelligence for briefings'), findsNothing);
    },
  );
  testWidgets('read more expands the briefing and reveals the chat button', (
    tester,
  ) async {
    var opened = 0;
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiCoachSettingsProvider.overrideWith(_Settings.new),
          aiBriefingProvider.overrideWith(
            (ref, period) => _ReadyBriefing(ref, period),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: BriefingCard(openCoach: () => opened++)),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chat with AI about this briefing'), findsNothing);

    await tester.tap(find.text('read more'));
    await tester.pumpAndSettle();
    expect(find.text('show less'), findsOneWidget);
    final text = tester.widget<Text>(
      find.text('Line one. Line two. Line three. Line four.'),
    );
    expect(text.maxLines, isNull);

    await tester.tap(find.text('Chat with AI about this briefing'));
    expect(opened, 1);
    expect(container.read(pendingCoachPromptProvider), contains('Line four.'));
  });
}
