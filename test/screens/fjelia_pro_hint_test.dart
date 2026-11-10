import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/coach_memory_provider.dart';
import 'package:fjelia/providers/fjelia_edition_provider.dart';
import 'package:fjelia/screens/settings/ai_settings_tab.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/screens/settings/settings_sheet.dart';

class _Edition implements FjeliaEdition {
  const _Edition({required this.proOffered});
  @override
  final bool proOffered;
  @override
  bool get isPro => false;
}

class _Settings extends AiCoachSettingsNotifier {
  _Settings(this.provider);
  final AiProvider provider;
  @override
  Future<AiCoachSettings> build() async => AiCoachSettings(
    provider: provider,
    model: provider.defaultModel,
    enabled: true,
    hasApiKey: true,
    onDeviceAvailable: true,
  );
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<void> show(
    WidgetTester tester,
    AiProvider provider,
    FjeliaEdition edition,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiCoachSettingsProvider.overrideWith(() => _Settings(provider)),
          fjeliaEditionProvider.overrideWithValue(edition),
          coachMemoriesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AiSettingsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const hint = 'FjeliaPro gives you more detailed information and analyses.';

  testWidgets('AI & more no longer carries FjeliaPro', (tester) async {
    for (final provider in [AiProvider.appleIntelligence, AiProvider.freeAi]) {
      await show(tester, provider, const _Edition(proOffered: true));
      expect(find.text(hint), findsNothing);
      expect(find.byKey(const ValueKey('fjelia-pro-entry')), findsNothing);
    }
  });

  Future<void> settings(WidgetTester tester, FjeliaEdition edition) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fjeliaEditionProvider.overrideWithValue(edition)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SettingsSheet()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('Settings has FjeliaPro as its own row once it is offered', (
    tester,
  ) async {
    await settings(tester, const _Edition(proOffered: true));
    expect(find.byKey(const ValueKey('settings-fjelia-pro')), findsOneWidget);
    expect(find.text('FjeliaPro'), findsOneWidget);
    await settings(tester, const _Edition(proOffered: false));
    expect(find.byKey(const ValueKey('settings-fjelia-pro')), findsNothing);
  });
}
