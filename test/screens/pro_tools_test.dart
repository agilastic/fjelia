import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/fjelia_edition_provider.dart';
import 'package:fjelia/providers/fjelia_pro_provider.dart';
import 'package:fjelia/providers/planner_providers.dart';
import 'package:fjelia/providers/pro_analysis_provider.dart';
import 'package:fjelia/screens/planner/pro_analysis_sheet.dart';
import 'package:fjelia/screens/settings/fjelia_pro_sheet.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/services/fjelia_pro.dart';
import 'package:fjelia/services/pro_analysis.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter/material.dart';
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
    provider: AiProvider.freeAi,
    model: 'default',
    hasApiKey: true,
  );
}

class _Actions extends ProAnalysisActions {
  _Actions(super.ref, this.db);
  final AppDatabase db;
  final asked = <String>[];
  @override
  Future<ProReport> generate(ProAnalysisRef analysis) async {
    asked.add(analysis.id);
    final report = ProReport(
      id: analysis.id,
      kind: analysis.kind.name,
      refKey: analysis.key,
      body: '## As planned\n- HRV 58 ms vs 55 ms',
      model: 'ProAI-deep',
      createdAt: DateTime(2026, 11, 9, 7, 30),
    );
    await db.saveProReport(report);
    return report;
  }
}

void main() {
  late AppDatabase db;
  _Actions? actions;

  Future<void> show(WidgetTester tester, {required bool pro}) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          fjeliaEditionProvider.overrideWithValue(_Edition(pro)),
          proStoreProvider.overrideWithValue(const NoProStore()),
          upcomingRaceGoalsProvider.overrideWith(
            (ref) async => [
              RaceGoal(
                id: 'g1',
                athleteId: 'self',
                name: 'Frankfurt Half',
                primarySport: 'running',
                distanceM: 21097,
                raceDate: DateTime(2026, 12, 13),
                priority: 'A',
                source: 'manual',
                createdAt: DateTime(2026, 10, 1),
                participation: 'committed',
              ),
            ],
          ),
          aiCoachSettingsProvider.overrideWith(_Settings.new),
          proAnalysisActionsProvider.overrideWith(
            (ref) => actions = _Actions(ref, db),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: ProToolsCard()),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  }

  testWidgets('without Pro every analysis leads to the Pro sheet', (
    tester,
  ) async {
    await show(tester, pro: false);
    await tester.tap(find.byKey(const ValueKey('pro-tools')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("Today's plan check"), findsNothing);
    expect(find.text('Race plan'), findsOneWidget);
    expect(
      find.text('Frankfurt Half: taper, pacing, fuelling'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('pro-tool-weekReview')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(FjeliaProSheet), findsOneWidget);
    await close(tester);
  });

  testWidgets('with Pro an analysis is written after consent and shown', (
    tester,
  ) async {
    await show(tester, pro: true);
    await tester.tap(find.byKey(const ValueKey('pro-tools')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("Today's plan check"), findsNothing);
    await tester.tap(find.byKey(const ValueKey('pro-tool-weekReview')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ProAnalysisSheet), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pro-analysis-create')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // The training context leaves the device only after consent.
    expect(find.textContaining('Fjelia AI Pro'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(actions!.asked.single, startsWith('weekReview:'));
    expect(find.byKey(const ValueKey('pro-report')), findsOneWidget);
    expect(find.text('As planned'), findsOneWidget);
    expect(find.text('Create again'), findsNothing);
    await close(tester);
  });
}
