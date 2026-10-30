import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/l10n/l10n_ext.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/local_model_provider.dart';
import 'package:fjelia/screens/settings/ai_settings_tab.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/services/local_model_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _Model extends LocalModelService {
  _Model({super.model});

  bool installed = false;
  bool supported = true;
  String? unavailableReason;
  int downloads = 0, removals = 0;

  @override
  Future<LocalModelStatus> inspect() async => LocalModelStatus(
    supported: supported,
    reason: supported ? null : unavailableReason ?? 'gpu',
    installed: installed,
    totalBytes: totalBytes,
    downloadedBytes: installed ? totalBytes : 0,
  );

  @override
  Future<void> download(void Function(int bytes, int total) progress) async {
    downloads++;
    progress(totalBytes, totalBytes);
    installed = true;
  }

  @override
  Future<void> remove() async {
    removals++;
    installed = false;
  }

  @override
  Future<void> unload() async {}
}

void main() {
  tearDown(() => setActiveLocale(const Locale('en')));

  Future<ProviderContainer> showSettings(
    WidgetTester tester,
    _Model model, {
    _Model? model4b,
    String initialModel = localQwenModelId,
  }) async {
    FlutterSecureStorage.setMockInitialValues({
      'ai_coach_provider': 'localQwen',
      'ai_coach_model': initialModel,
      'ai_coach_enabled': 'true',
    });
    setActiveLocale(const Locale('de'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localModelServiceProvider(localQwenModelId).overrideWithValue(model),
          localModelServiceProvider(
            localQwen4bModelId,
          ).overrideWithValue(model4b ?? _Model(model: localQwen4b)),
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

  testWidgets('local model can be downloaded and deleted without an API key', (
    tester,
  ) async {
    final model = _Model();
    final container = await showSettings(tester, model);
    expect(
      (await container.read(aiCoachSettingsProvider.future)).ready,
      isFalse,
    );
    expect(find.text('API-Schlüssel'), findsNothing);
    expect(find.text('Weitergabe von Gesundheitsdaten'), findsNothing);
    final chips = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .toList();
    expect((chips[0].label as Text).data, 'Free AI');
    expect((chips[1].label as Text).data, 'Apple Intelligence');
    expect((chips[2].label as Text).data, 'Qwen3.5 · lokal');
    expect(find.textContaining('1749 MB'), findsOneWidget);
    final download = find.text('Modell herunterladen');
    await tester.ensureVisible(download);
    await tester.pumpAndSettle();
    await tester.tap(download);
    await tester.pumpAndSettle();
    expect(model.downloads, 1);
    expect(
      (await container.read(aiCoachSettingsProvider.future)).ready,
      isTrue,
    );
    expect(find.text('Heruntergeladen · offline verfügbar'), findsOneWidget);
    final remove = find.text('Modell löschen');
    await tester.ensureVisible(remove);
    await tester.pumpAndSettle();
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(model.removals, 1);
    expect(
      (await container.read(aiCoachSettingsProvider.future)).ready,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('unsupported hardware cannot start the large download', (
    tester,
  ) async {
    final model = _Model()..supported = false;
    await showSettings(tester, model);
    expect(find.text('Modell herunterladen'), findsNothing);
    expect(find.textContaining('A14-Chip'), findsOneWidget);
    expect(model.downloads, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('2B and 4B selection, downloads and deletion stay independent', (
    tester,
  ) async {
    final small = _Model()..installed = true;
    final large = _Model(model: localQwen4b);
    final container = await showSettings(tester, small, model4b: large);
    expect(
      (await container.read(aiCoachSettingsProvider.future)).ready,
      isTrue,
    );

    final selector = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(selector);
    await tester.pumpAndSettle();
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qwen3.5-4B · 4-bit · iPhone 18+').last);
    await tester.pumpAndSettle();

    var settings = await container.read(aiCoachSettingsProvider.future);
    expect(settings.model, localQwen4bModelId);
    expect(
      settings.ready,
      isFalse,
      reason: 'Installed 2B cannot activate missing 4B',
    );
    expect(
      (await const AiCoachSettingsStore().load()).model,
      localQwen4bModelId,
    );
    expect(find.textContaining('3061 MB'), findsOneWidget);
    expect(find.textContaining('8 GB Arbeitsspeicher'), findsOneWidget);

    await tester.ensureVisible(find.text('Modell herunterladen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modell herunterladen'));
    await tester.pumpAndSettle();
    expect(large.downloads, 1);
    expect(small.downloads, 0);
    expect(
      (await container.read(aiCoachSettingsProvider.future)).ready,
      isTrue,
    );

    await tester.ensureVisible(find.text('Modell löschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modell löschen'));
    await tester.pumpAndSettle();
    expect(large.removals, 1);
    expect(small.installed, isTrue);
    expect(
      (await container.read(aiCoachSettingsProvider.future)).ready,
      isFalse,
    );

    await tester.ensureVisible(selector);
    await tester.pumpAndSettle();
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qwen3.5-2B · 4-bit').last);
    await tester.pumpAndSettle();
    settings = await container.read(aiCoachSettingsProvider.future);
    expect(settings.model, localQwenModelId);
    expect(settings.ready, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('older iPhones show 4B disabled while 2B stays ready', (
    tester,
  ) async {
    final small = _Model()..installed = true;
    final large = _Model(model: localQwen4b)
      ..supported = false
      ..unavailableReason = 'device';
    final container = await showSettings(tester, small, model4b: large);
    final selector = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    expect(
      selector.items!
          .firstWhere((item) => item.value == localQwen4bModelId)
          .enabled,
      isFalse,
    );
    expect(
      selector.items!
          .firstWhere((item) => item.value == localQwenModelId)
          .enabled,
      isTrue,
    );
    expect(
      (await container.read(aiCoachSettingsProvider.future)).ready,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cached 4B on older iPhones stays blocked and can be deleted', (
    tester,
  ) async {
    final small = _Model()..installed = true;
    final large = _Model(model: localQwen4b)
      ..supported = false
      ..unavailableReason = 'device'
      ..installed = true;
    final container = await showSettings(
      tester,
      small,
      model4b: large,
      initialModel: localQwen4bModelId,
    );
    expect(
      (await container.read(aiCoachSettingsProvider.future)).ready,
      isFalse,
    );
    expect(
      find.text('4B ist auf iPhone 18 und neuer verfügbar.'),
      findsOneWidget,
    );
    expect(find.text('Modell herunterladen'), findsNothing);
    await tester.ensureVisible(find.text('Modell löschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modell löschen'));
    await tester.pumpAndSettle();
    expect(large.removals, 1);
    expect(small.installed, isTrue);
    await container
        .read(aiCoachSettingsProvider.notifier)
        .setModel(localQwenModelId);
    await tester.pumpAndSettle();
    expect(
      (await container.read(aiCoachSettingsProvider.future)).ready,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('4B RAM requirement does not disable installed 2B', (
    tester,
  ) async {
    final small = _Model()..installed = true;
    final large = _Model(model: localQwen4b)
      ..supported = false
      ..unavailableReason = 'memory';
    final container = await showSettings(tester, small, model4b: large);
    await container
        .read(aiCoachSettingsProvider.notifier)
        .setModel(localQwen4bModelId);
    await tester.pumpAndSettle();
    expect(
      (await container.read(aiCoachSettingsProvider.future)).ready,
      isFalse,
    );
    expect(find.textContaining('nicht genug Arbeitsspeicher'), findsOneWidget);
    expect(find.text('Modell herunterladen'), findsNothing);
    expect(large.downloads, 0);
    await container
        .read(aiCoachSettingsProvider.notifier)
        .setModel(localQwenModelId);
    await tester.pumpAndSettle();
    expect(
      (await container.read(aiCoachSettingsProvider.future)).ready,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
