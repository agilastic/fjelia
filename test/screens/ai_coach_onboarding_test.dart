import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:fjelia/config/free_ai.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/l10n/l10n_ext.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/local_model_provider.dart';
import 'package:fjelia/providers/sync_provider.dart';
import 'package:fjelia/screens/onboarding/ai_coach_onboarding_screen.dart';
import 'package:fjelia/screens/onboarding/connect_devices_screen.dart';
import 'package:fjelia/screens/onboarding/training_plan_onboarding_screen.dart';
import 'package:fjelia/screens/settings/ai_settings_tab.dart';
import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/services/local_model_service.dart';
import 'package:fjelia/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Model extends LocalModelService {
  _Model({super.model, this.installed = false});

  final bool installed;
  int downloads = 0;

  @override
  Future<LocalModelStatus> inspect() async => LocalModelStatus(
    supported: true,
    installed: installed,
    totalBytes: totalBytes,
    downloadedBytes: installed ? totalBytes : 0,
  );

  @override
  Future<void> download(void Function(int, int) onProgress) async {
    downloads++;
  }

  @override
  Future<void> unload() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  final previewKey = GlobalKey();
  final previewDir = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
  late AppDatabase db;

  setUpAll(() async {
    if (previewDir == null) return;
    final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
    if (font.existsSync()) {
      final loader = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    setActiveLocale(const Locale('en'));
    await db.close();
  });

  Future<ProviderContainer> show(
    WidgetTester tester, {
    bool appleAvailable = true,
    bool appleCheckThrows = false,
    String freeKey = 'test-free-ai-key',
    Locale locale = const Locale('de'),
    Size size = const Size(393, 852),
    double textScale = 1,
    bool reduceMotion = false,
    bool safeInsets = false,
    Widget screen = const AiCoachOnboardingScreen(),
    _Model? model,
    _Model? model4b,
  }) async {
    setActiveLocale(locale);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    if (safeInsets) {
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    }
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
      tester.view.resetPadding();
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          historyImportStarterProvider.overrideWithValue(() async {}),
          aiCoachSettingsStoreProvider.overrideWithValue(
            AiCoachSettingsStore(freeAiApiKey: freeKey),
          ),
          appleIntelligenceAvailabilityProvider.overrideWithValue(() async {
            if (appleCheckThrows) throw UnsupportedError('Not an Apple device');
            return appleAvailable;
          }),
          aiCoachClientProvider.overrideWithValue(
            AiCoachClient(
              client: MockClient((_) async {
                throw StateError('Onboarding must never send cloud requests');
              }),
            ),
          ),
          localModelServiceProvider(
            localQwenModelId,
          ).overrideWithValue(model ?? _Model()),
          localModelServiceProvider(
            localQwen4bModelId,
          ).overrideWithValue(model4b ?? _Model(model: localQwen4b)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: reduceMotion,
            ),
            child: child!,
          ),
          home: RepaintBoundary(key: previewKey, child: screen),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(screen.runtimeType)),
    );
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (previewDir == null) return;
    await tester.runAsync(() async {
      final boundary =
          previewKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(previewDir).create(recursive: true);
      await File(
        '$previewDir/$name.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpAndSettle();
  }

  Finder getContinue() => find.byKey(const ValueKey('onboarding-ai-continue'));

  testWidgets('fresh setup previews Free AI and commits only on Continue', (
    tester,
  ) async {
    final container = await show(tester);
    expect(find.text('Mit Free AI weiter'), findsOneWidget);
    expect(await storage.read(key: 'ai_coach_provider'), isNull);
    expect(await storage.read(key: 'ai_coach_enabled'), isNull);
    expect(await storage.read(key: freeAiInstallationIdStorageKey), isNull);
    expect(container.read(aiCoachSessionConsentProvider), isFalse);
    await capture(tester, 'onboarding-ai-de');

    await tester.tap(getContinue());
    await tester.pumpAndSettle();
    expect(find.byType(TrainingPlanOnboardingScreen), findsOneWidget);
    final settings = await container.read(aiCoachSettingsProvider.future);
    expect(settings.provider, AiProvider.freeAi);
    expect(settings.ready, isTrue);
    expect(settings.briefingMode, BriefingMode.ai);
    expect(await storage.read(key: 'ai_coach_provider'), 'freeAi');
    expect(await storage.read(key: freeAiInstallationIdStorageKey), isNull);
    expect(container.read(aiCoachSessionConsentProvider), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Apple Intelligence can be selected without changing settings yet',
    (tester) async {
      final container = await show(tester);
      await tester.tap(find.byKey(const ValueKey('onboarding-apple-ai')));
      await tester.pumpAndSettle();
      expect(find.text('Mit Apple Intelligence weiter'), findsOneWidget);
      expect(await storage.read(key: 'ai_coach_provider'), isNull);
      await capture(tester, 'onboarding-ai-apple-de');

      await tester.tap(getContinue());
      await tester.pumpAndSettle();
      final settings = await container.read(aiCoachSettingsProvider.future);
      expect(settings.provider, AiProvider.appleIntelligence);
      expect(settings.ready, isTrue);
      expect(await storage.read(key: 'ai_coach_provider'), 'appleIntelligence');
      expect(find.byType(TrainingPlanOnboardingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'repeating setup preserves a configured provider and custom model',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'ai_coach_provider': 'openai',
        'ai_coach_model': 'custom-model-v2',
        'ai_coach_api_key_openai': 'test-own-key',
        'ai_briefing_mode': 'none',
      });
      final container = await show(tester);
      expect(find.text('Mit OpenAI weiter'), findsOneWidget);
      expect(find.text('custom-model-v2'), findsOneWidget);
      await tester.tap(getContinue());
      await tester.pumpAndSettle();
      final settings = await container.read(aiCoachSettingsProvider.future);
      expect(settings.provider, AiProvider.openai);
      expect(settings.model, 'custom-model-v2');
      expect(settings.briefingMode, BriefingMode.none);
      expect(settings.ready, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('continuing without AI disables chat and local AI briefings', (
    tester,
  ) async {
    final container = await show(tester);
    await tester.tap(find.byKey(const ValueKey('onboarding-without-ai')));
    await tester.pumpAndSettle();
    final settings = await container.read(aiCoachSettingsProvider.future);
    expect(settings.enabled, isFalse);
    expect(settings.briefingMode, BriefingMode.static_);
    expect(settings.readyForBriefing, isFalse);
    expect(await storage.read(key: freeAiInstallationIdStorageKey), isNull);
    expect(find.byType(TrainingPlanOnboardingScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('setup preserves a previous decision to disable AI', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'ai_coach_provider': 'appleIntelligence',
      'ai_coach_enabled': 'false',
      'ai_briefing_mode': 'static_',
    });
    final container = await show(tester);
    expect(find.text('Ohne KI fortfahren'), findsOneWidget);
    expect(find.text('Mit Free AI weiter'), findsNothing);
    await tester.tap(getContinue());
    await tester.pumpAndSettle();
    final settings = await container.read(aiCoachSettingsProvider.future);
    expect(settings.enabled, isFalse);
    expect(settings.readyForBriefing, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a build without Free AI falls back to available Apple AI', (
    tester,
  ) async {
    await show(tester, freeKey: '');
    expect(find.text('Mit Apple Intelligence weiter'), findsOneWidget);
    expect(find.text('Derzeit nicht verfügbar'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-free-ai')));
    await tester.pumpAndSettle();
    expect(find.text('Mit Apple Intelligence weiter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unsupported Apple platforms still offer Free AI', (
    tester,
  ) async {
    await show(tester, appleCheckThrows: true);
    expect(find.text('Mit Free AI weiter'), findsOneWidget);
    expect(find.text('Derzeit nicht verfügbar'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-apple-ai')));
    await tester.pumpAndSettle();
    expect(find.text('Mit Free AI weiter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without either default AI users can still finish this step', (
    tester,
  ) async {
    final container = await show(tester, appleAvailable: false, freeKey: '');
    expect(find.text('Ohne KI fortfahren'), findsOneWidget);
    expect(find.text('Derzeit nicht verfügbar'), findsNWidgets(2));
    await tester.tap(getContinue());
    await tester.pumpAndSettle();
    expect(find.byType(TrainingPlanOnboardingScreen), findsOneWidget);
    expect(
      (await container.read(aiCoachSettingsProvider.future)).enabled,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'uninstalled Qwen opens configuration and never downloads itself',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'ai_coach_provider': 'localQwen',
        'ai_coach_model': localQwenModelId,
      });
      final model = _Model();
      await show(tester, model: model);
      expect(find.text('Modell einrichten'), findsOneWidget);
      expect(model.downloads, 0);
      await tester.tap(getContinue());
      await tester.pumpAndSettle();
      expect(find.byType(AiSettingsTab), findsOneWidget);
      expect(find.byType(TrainingPlanOnboardingScreen), findsNothing);
      expect(model.downloads, 0);
      Navigator.of(tester.element(find.byType(AiSettingsTab))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Modell einrichten'), findsOneWidget);
      expect(model.downloads, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('closing model settings preserves an unsaved onboarding choice', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.byKey(const ValueKey('onboarding-apple-ai')));
    await tester.pumpAndSettle();
    final more = find.byKey(const ValueKey('onboarding-more-ai'));
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(AiSettingsTab))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Mit Apple Intelligence weiter'), findsOneWidget);
    expect(await storage.read(key: 'ai_coach_provider'), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an explicit provider choice in Settings replaces the draft', (
    tester,
  ) async {
    await show(tester);
    final more = find.byKey(const ValueKey('onboarding-more-ai'));
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    // Apple was already the runtime default, but saving it is a new choice.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Apple Intelligence'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(AiSettingsTab))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Mit Apple Intelligence weiter'), findsOneWidget);
    expect(await storage.read(key: 'ai_coach_provider'), 'appleIntelligence');
    expect(tester.takeException(), isNull);
  });

  testWidgets('own-key providers require configuration before continuing', (
    tester,
  ) async {
    final container = await show(tester);
    final more = find.byKey(const ValueKey('onboarding-more-ai'));
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'OpenAI'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(AiSettingsTab))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Modell einrichten'), findsOneWidget);
    expect(find.byType(TrainingPlanOnboardingScreen), findsNothing);

    await tester.tap(getContinue());
    await tester.pumpAndSettle();
    expect(find.byType(AiSettingsTab), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'test-own-api-key');
    final save = find.byIcon(Icons.save_outlined);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(AiSettingsTab))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Mit OpenAI weiter'), findsOneWidget);
    await tester.tap(getContinue());
    await tester.pumpAndSettle();
    final settings = await container.read(aiCoachSettingsProvider.future);
    expect(settings.provider, AiProvider.openai);
    expect(settings.ready, isTrue);
    expect(find.byType(TrainingPlanOnboardingScreen), findsOneWidget);
    expect(await storage.read(key: freeAiInstallationIdStorageKey), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an installed Qwen model and its size survive setup unchanged', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'ai_coach_provider': 'localQwen',
      'ai_coach_model': localQwen4bModelId,
    });
    final model = _Model(model: localQwen4b, installed: true);
    final container = await show(tester, model4b: model);
    expect(find.text('Mit Qwen3.5 · lokal weiter'), findsOneWidget);
    await tester.tap(getContinue());
    await tester.pumpAndSettle();
    final settings = await container.read(aiCoachSettingsProvider.future);
    expect(settings.provider, AiProvider.localQwen);
    expect(settings.model, localQwen4bModelId);
    expect(settings.ready, isTrue);
    expect(model.downloads, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'device connections lead to AI choice, then training preferences',
    (tester) async {
      await show(
        tester,
        screen: const ConnectDevicesScreen(),
        size: const Size(800, 800),
        locale: const Locale('en'),
        appleAvailable: false,
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(AiCoachOnboardingScreen), findsOneWidget);
      expect(find.byType(TrainingPlanOnboardingScreen), findsNothing);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(ConnectDevicesScreen), findsOneWidget);
      expect(await storage.read(key: 'ai_coach_provider'), isNull);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();
      await tester.tap(getContinue());
      await tester.pumpAndSettle();
      expect(find.byType(TrainingPlanOnboardingScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(AiCoachOnboardingScreen), findsOneWidget);
      expect(find.text('Continue with Free AI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the choices remain accessible within iPhone safe areas', (
    tester,
  ) async {
    await show(tester, safeInsets: true);
    await capture(tester, 'onboarding-ai-iphone-de');
    final more = find.byKey(const ValueKey('onboarding-more-ai'));
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.byType(AiSettingsTab), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('small phone and larger text fit in ${locale.languageCode}', (
      tester,
    ) async {
      await show(
        tester,
        locale: locale,
        size: const Size(375, 667),
        textScale: 1.3,
        reduceMotion: true,
      );
      expect(getContinue(), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('onboarding-more-ai')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('English preview and very large text remain usable', (
    tester,
  ) async {
    await show(tester, locale: const Locale('en'));
    await capture(tester, 'onboarding-ai-en');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await show(
      tester,
      locale: const Locale('en'),
      size: const Size(320, 568),
      textScale: 1.8,
      reduceMotion: true,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('onboarding-more-ai')),
    );
    await tester.pumpAndSettle();
    expect(getContinue(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
