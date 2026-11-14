import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/ecg_provider.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:fjelia/screens/ai_coach/ai_coach_screen.dart';
import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/services/ecg_analysis.dart';
import 'package:fjelia/services/ecg_coach_context.dart';
import 'package:fjelia/widgets/coach_context_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ecg_coach_context_test.dart' show ecg, hz, regularEcg, run;

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
  final contexts = <String>[];
  @override
  Future<String> send(
    AiCoachSettings settings,
    List<ChatMessage> messages,
    String toonContext, [
    AiConsentToken? consent,
    void Function(String source)? onSource,
  ]) async {
    contexts.add(toonContext);
    return 'Answer ${contexts.length}';
  }
}

void main() {
  final analysis = analyzeEcg(regularEcg(120), hz);
  final activity = run('a1', DateTime(2026, 11, 7, 7));

  Future<_Client> pumpChat(
    WidgetTester tester,
    List<EcgRecording> rows, {
    void Function(String id)? analysed,
    bool freshInstall = true,
  }) async {
    FlutterSecureStorage.setMockInitialValues({});
    if (freshInstall) SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.runAsync(() async {
      for (final r in rows) {
        await db.into(db.ecgRecordings).insert(r);
      }
    });
    final client = _Client();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          aiCoachSettingsProvider.overrideWith(_Settings.new),
          userProfileProvider.overrideWith(_Profile.new),
          aiCoachClientProvider.overrideWithValue(client),
          activityCoachContextProvider.overrideWith(
            (ref, a) async => '[Activity:Run,Id:${a.activityId}]',
          ),
          ecgAnalysisProvider.overrideWith((ref, id) async {
            analysed?.call(id);
            return analysis;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AiCoachScreen(activity: activity)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return client;
  }

  Future<void> ask(WidgetTester tester, String question) async {
    await tester.enterText(find.byType(TextField), question);
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Send message'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
  }

  Future<void> answerWarning(
    WidgetTester tester, {
    required bool accept,
  }) async {
    expect(find.text('I understand'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text(accept ? 'I understand' : 'Cancel'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
  }

  final linked = ecg('e1', DateTime(2026, 11, 7, 7, 10), activityId: 'a1');

  testWidgets('an ordinary question only says that an ECG exists', (
    tester,
  ) async {
    var analyses = 0;
    final client = await pumpChat(tester, [
      linked,
    ], analysed: (_) => analyses++);
    await ask(tester, 'How was my pace?');
    expect(find.text('I understand'), findsNothing);
    expect(client.contexts.single, contains('[ECG:Available,Id:e1,'));
    expect(client.contexts.single, isNot(contains('[ECG:Summary')));
    expect(analyses, 0);
    expect(find.byType(CoachMedicalWarning), findsNothing);
  });

  testWidgets(
    'an ECG question shows the warning, then sends the full ECG context',
    (tester) async {
      var analyses = 0;
      final client = await pumpChat(tester, [
        linked,
      ], analysed: (_) => analyses++);
      await ask(tester, 'Were there any irregularities during my workout?');
      await answerWarning(tester, accept: true);
      final full = ecgAnalysisLines(linked, analysis).join('\n');
      expect(client.contexts.single, contains(full));
      expect(client.contexts.single, contains('[Activity:Run,Id:a1]'));
      expect(find.byType(CoachMedicalWarning), findsOneWidget);

      // A follow-up keeps the recording, without a second warning, and
      // places the minute in it.
      await ask(tester, 'And at minute 11?');
      expect(find.text('I understand'), findsNothing);
      expect(client.contexts.last, contains(full));
      expect(
        client.contexts.last,
        contains('[ECG:Focus,Asked:workout minute 11–12,ECG:60–120s'),
      );
      expect(analyses, lessThanOrEqualTo(2));
    },
  );

  testWidgets('the warning is shown once ever, not in every chat', (
    tester,
  ) async {
    final first = await pumpChat(tester, [linked]);
    await ask(tester, 'Analyse my ECG');
    await answerWarning(tester, accept: true);
    expect(first.contexts.single, contains('[ECG:Summary'));

    final later = await pumpChat(tester, [linked], freshInstall: false);
    await ask(tester, 'Analyse my ECG');
    expect(find.text('I understand'), findsNothing);
    expect(later.contexts.single, contains('[ECG:Summary'));
    expect(find.byType(CoachMedicalWarning), findsOneWidget);
  });

  testWidgets('declining the warning sends no ECG content', (tester) async {
    final client = await pumpChat(tester, [linked]);
    await ask(tester, 'Analyse my ECG');
    await answerWarning(tester, accept: false);
    expect(client.contexts.single, contains(ecgDeclinedLine));
    expect(client.contexts.single, isNot(contains('[ECG:Summary')));
    expect(find.byType(CoachMedicalWarning), findsNothing);
  });

  testWidgets('two recordings: the coach asks, the answer picks one', (
    tester,
  ) async {
    final second = ecg('e2', DateTime(2026, 11, 7, 7, 40), activityId: 'a1');
    final client = await pumpChat(tester, [linked, second]);
    await ask(tester, 'Analyse my ECG');
    expect(find.text('I understand'), findsNothing);
    expect(client.contexts.single, contains('[ECG:Choose,'));
    expect(client.contexts.single, isNot(contains('[ECG:Summary')));

    await ask(tester, 'The one at 7:40');
    await answerWarning(tester, accept: true);
    expect(
      client.contexts.last,
      contains(ecgAnalysisLines(second, analysis).first),
    );
    expect(client.contexts.last, contains('Recorded:2026-11-07 07:40'));
  });

  testWidgets('a question about the ECG of an activity without one', (
    tester,
  ) async {
    final client = await pumpChat(tester, [
      ecg('other', DateTime(2026, 11, 6, 14)),
    ]);
    await ask(tester, 'Does the ECG show anything unusual?');
    expect(find.text('I understand'), findsNothing);
    expect(client.contexts.single, isNot(contains('[ECG:')));
  });
}
