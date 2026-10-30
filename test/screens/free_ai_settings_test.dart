import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/l10n/l10n_ext.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/screens/ai_coach/ai_coach_screen.dart';
import 'package:fjelia/screens/settings/ai_settings_tab.dart';
import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/widgets/briefing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FreeSettings extends AiCoachSettingsNotifier {
  @override
  Future<AiCoachSettings> build() async => const AiCoachSettings(
    provider: AiProvider.freeAi,
    model: 'default',
    enabled: true,
    hasApiKey: true,
  );
}

class _Briefing extends AiBriefingNotifier {
  _Briefing(super.ref, super.period);

  int calls = 0;
  bool confirmed = false;

  @override
  Future<void> load(
    AiCoachSettings settings, {
    Object? monitor,
    String raceGoals = '',
    String? weatherSummary,
    Object? bioAge,
    Object? planInfo,
    bool force = false,
    bool cloudConsent = false,
  }) async {
    calls++;
    confirmed = cloudConsent;
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    setActiveLocale(const Locale('de'));
  });
  tearDown(() => setActiveLocale(const Locale('en')));

  Future<ProviderContainer> showSettings(
    WidgetTester tester, {
    required bool appleAvailable,
    String apiKey = 'test-free-ai-key',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiCoachSettingsStoreProvider.overrideWithValue(
            AiCoachSettingsStore(freeAiApiKey: apiKey),
          ),
          appleIntelligenceAvailabilityProvider.overrideWithValue(
            () async => appleAvailable,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AiSettingsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(AiSettingsTab)),
    );
  }

  testWidgets('Free AI is first and selectable on an Apple-compatible device', (
    tester,
  ) async {
    final container = await showSettings(tester, appleAvailable: true);
    final chips = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .toList();
    expect((chips.first.label as Text).data, 'Free AI');
    expect(chips.first.selected, isFalse);
    expect(chips[1].selected, isTrue);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Free AI'));
    await tester.pumpAndSettle();
    final settings = await container.read(aiCoachSettingsProvider.future);
    expect(settings.provider, AiProvider.freeAi);
    expect(settings.ready, isTrue);
    expect(settings.consentMode, AiConsentMode.session);
    expect(find.text('API-Schlüssel'), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.textContaining('ai.fjelia.com'), findsOneWidget);
    expect(find.text('Modell herunterladen'), findsNothing);
    final askOnce = find.widgetWithText(
      SwitchListTile,
      'Einmal pro Chat-Sitzung fragen',
    );
    await tester.scrollUntilVisible(
      askOnce,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(askOnce).value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without Apple Intelligence Free AI is selected automatically', (
    tester,
  ) async {
    final container = await showSettings(tester, appleAvailable: false);
    final free = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Free AI'),
    );
    expect(free.selected, isTrue);
    expect(
      (await container.read(aiCoachSettingsProvider.future)).ready,
      isTrue,
    );
    expect(find.text('API-Schlüssel'), findsNothing);
    expect(find.text('API-Schlüssel speichern'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('builds without the shared credential explain unavailability', (
    tester,
  ) async {
    final container = await showSettings(
      tester,
      appleAvailable: false,
      apiKey: '',
    );
    expect(
      (await container.read(aiCoachSettingsProvider.future)).ready,
      isFalse,
    );
    expect(
      find.text(
        'Free AI ist in diesem Build nicht verfügbar. Wähle einen anderen Anbieter.',
      ),
      findsOneWidget,
    );
    expect(find.text('API-Schlüssel'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'automatic Free AI asks before sending and cancellation keeps data local',
    (tester) async {
      var requests = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiCoachSettingsStoreProvider.overrideWithValue(
              const AiCoachSettingsStore(freeAiApiKey: 'test-free-ai-key'),
            ),
            appleIntelligenceAvailabilityProvider.overrideWithValue(
              () async => false,
            ),
            aiCoachClientProvider.overrideWithValue(
              AiCoachClient(
                client: MockClient((_) async {
                  requests++;
                  return http.Response('{}', 200);
                }),
              ),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: AiCoachScreen(
                initialPrompt: 'Wie sieht mein Training aus?',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests, 0);
      await tester.tap(find.byTooltip('Nachricht senden'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining(
          'Damit Free AI für alle zuverlässig verfügbar bleibt, senden wir eine zufällige Installations-ID mit. Sie hilft uns, auffällige Nutzung zu erkennen und missbräuchliche Anfragen zu blockieren. Die ID enthält weder deinen Namen noch Kontodaten.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Free AI (ai.fjelia.com)'),
        findsOneWidget,
      );
      expect(requests, 0);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(requests, 0);
      expect(find.text('Wie sieht mein Training aus?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Free AI briefing needs confirmation for the displayed service', (
    tester,
  ) async {
    late _Briefing briefing;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiCoachSettingsProvider.overrideWith(_FreeSettings.new),
          aiBriefingProvider.overrideWith(
            (ref, period) => briefing = _Briefing(ref, period),
          ),
          briefingSummaryProvider.overrideWith((ref, date) => ''),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: BriefingCard(openCoach: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = tester.element(find.byType(BriefingCard)).l10n;
    expect(briefing.calls, 0);

    await tester.tap(find.text(l10n.generateBriefing));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Free AI (ai.fjelia.com)'),
      findsOneWidget,
    );
    expect(briefing.calls, 0);
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(briefing.calls, 0);

    await tester.tap(find.text(l10n.generateBriefing));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.continueLabel));
    await tester.pumpAndSettle();
    expect(briefing.calls, 1);
    expect(briefing.confirmed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
