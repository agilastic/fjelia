import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/fjelia_edition_provider.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:fjelia/screens/ai_coach/ai_coach_screen.dart';
import 'package:fjelia/screens/ai_coach/coach_memories_screen.dart';
import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/services/apple_coach_request.dart';
import 'package:fjelia/services/coach_memory_context.dart';
import 'package:fjelia/widgets/app_widgets.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _Edition implements FjeliaEdition {
  const _Edition(this.isPro);
  @override
  bool get proOffered => true;
  @override
  final bool isPro;
}

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
  String? context;
  @override
  Future<String> send(
    AiCoachSettings settings,
    List<ChatMessage> messages,
    String toonContext, [
    AiConsentToken? consent,
    void Function(String source)? onSource,
  ]) async {
    context = toonContext;
    return 'Keep the long run flat this week.';
  }
}

CoachMemory _card(String title, String body) => CoachMemory(
  id: title,
  title: title,
  body: body,
  createdAt: DateTime(2026, 11, 9),
  updatedAt: DateTime(2026, 11, 9),
);

void main() {
  group('context lines', () {
    test('one line per card, line breaks flattened, empty cards left out', () {
      expect(
        coachMemoryLines([
          _card('Left knee', 'Downhill hurts.\n\nClimbs are fine.'),
          _card('', '  '),
        ]),
        ['[Memory:Left knee] Downhill hurts. Climbs are fine.'],
      );
    });

    test('the on-device prompt reads a card as additional information', () {
      final request = AppleCoachRequest.build([
        ChatMessage(text: 'Plan my long run.', isUser: true),
      ], coachMemoryLines([_card('Left knee', 'Downhill hurts.')]).single);
      expect(
        request.prompt,
        contains(
          'Additional information from the athlete, use it if useful '
          '(Left knee): Downhill hurts.',
        ),
      );
    });
  });

  Future<(AppDatabase, _Client)> chat(WidgetTester tester, bool pro) async {
    FlutterSecureStorage.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    await db.saveCoachMemory(_card('Left knee', 'Downhill hurts.'));
    final client = _Client();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          aiCoachSettingsProvider.overrideWith(_Settings.new),
          userProfileProvider.overrideWith(_Profile.new),
          aiCoachClientProvider.overrideWithValue(client),
          fjeliaEditionProvider.overrideWithValue(_Edition(pro)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SheetPage(
              title: 'Coach',
              child: AiCoachScreen(initialPrompt: 'Plan my long run.'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    return (db, client);
  }

  testWidgets('FjeliaPro sends the cards along and can copy the answer', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    final (db, client) = await chat(tester, true);
    expect(client.context, contains('[Memory:Left knee] Downhill hurts.'));
    await tester.tap(find.text('Copy answer'));
    await tester.pump();
    expect(copied, 'Keep the long run flat this week.');
    expect(find.text('Copied ✨'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byTooltip('Memory Cards'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('the free edition sends no cards and has no copy button', (
    tester,
  ) async {
    final (db, client) = await chat(tester, false);
    expect(client.context, isNot(contains('[Memory:')));
    expect(find.text('Copy answer'), findsNothing);
    expect(find.byTooltip('Memory Cards'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('a card is created, shown and deleted', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CoachMemoriesScreen(),
        ),
      ),
    );
    Future<void> settle() async {
      // Drift's query streams need real time to deliver.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    await settle();
    expect(find.text('No cards yet. Drop your first one 🔥'), findsOneWidget);
    await tester.tap(find.text('New card'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.enterText(find.byType(TextField).first, 'Left knee');
    await tester.enterText(find.byType(TextField).last, 'Downhill hurts.');
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    for (var i = 0; i < 4; i++) {
      await settle();
    }
    expect(find.text('Left knee'), findsOneWidget);
    expect(find.text("1 card in your coach's head"), findsOneWidget);
    expect(
      (await tester.runAsync(db.coachMemoryList))!.single.body,
      'Downhill hurts.',
    );

    await tester.tap(find.byTooltip('Delete'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continue'));
    for (var i = 0; i < 4; i++) {
      await settle();
    }
    expect(await tester.runAsync(db.coachMemoryList), isEmpty);
    await tester.pumpWidget(const SizedBox());
    // Lets drift cancel its query stream before the database closes.
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  });
}
