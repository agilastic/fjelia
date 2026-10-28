import 'package:fjelia/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:fjelia/screens/ai_coach/ai_coach_screen.dart';
import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/widgets/app_widgets.dart';

class _Settings extends AiCoachSettingsNotifier {
  @override
  Future<AiCoachSettings> build() async => const AiCoachSettings(
    enabled: true,
    provider: AiProvider.appleIntelligence,
    model: 'on-device',
  );
}

class _Profile extends UserProfileNotifier {
  @override
  Future<UserProfile> build() async => const UserProfile();
}

class _Client extends AiCoachClient {
  int calls = 0;
  @override
  Future<String> send(
    AiCoachSettings settings,
    List<ChatMessage> messages,
    String toonContext, [
    AiConsentToken? consent,
  ]) async {
    calls++;
    expect(messages, hasLength(1));
    if (calls == 1) {
      throw StateError('Native PlatformException ${'stack frame ' * 100}');
    }
    return 'Your activity review is ready.';
  }
}

void main() {
  testWidgets(
    'chat error stays scrollable above keyboard and retry keeps one user turn',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final db = AppDatabase(NativeDatabase.memory());
      final client = _Client();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            aiCoachSettingsProvider.overrideWith(_Settings.new),
            userProfileProvider.overrideWith(_Profile.new),
            aiCoachClientProvider.overrideWithValue(client),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.only(bottom: 350),
                child: SheetPage(
                  title: 'Activity Coach',
                  child: AiCoachScreen(initialPrompt: 'Review my run.'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Could not get a reply. Check your AI settings and try again.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Native PlatformException'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(client.calls, 2);
      expect(find.text('Your activity review is ready.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await db.close();
    },
  );
}
