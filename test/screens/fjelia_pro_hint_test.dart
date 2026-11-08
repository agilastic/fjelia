import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/fjelia_edition_provider.dart';
import 'package:fjelia/screens/settings/ai_settings_tab.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _Edition implements FjeliaEdition {
  const _Edition({required this.proOffered, this.isPro = false});
  @override
  final bool proOffered, isPro;
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

  testWidgets('a local coach points to FjeliaPro once it is offered', (
    tester,
  ) async {
    await show(
      tester,
      AiProvider.appleIntelligence,
      const _Edition(proOffered: true),
    );
    expect(find.text(hint), findsOneWidget);
  });

  testWidgets('no hint before FjeliaPro is offered', (tester) async {
    await show(
      tester,
      AiProvider.appleIntelligence,
      const _Edition(proOffered: false),
    );
    expect(find.text(hint), findsNothing);
  });

  testWidgets('no hint for someone who has FjeliaPro', (tester) async {
    await show(
      tester,
      AiProvider.appleIntelligence,
      const _Edition(proOffered: true, isPro: true),
    );
    expect(find.text(hint), findsNothing);
  });

  testWidgets('no hint with a cloud coach', (tester) async {
    await show(tester, AiProvider.freeAi, const _Edition(proOffered: true));
    expect(find.text(hint), findsNothing);
  });
}
