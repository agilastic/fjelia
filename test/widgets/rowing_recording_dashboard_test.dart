import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/ecg_provider.dart';
import 'package:fjelia/providers/indoor_recording_provider.dart';
import 'package:fjelia/theme/app_theme.dart';
import 'package:fjelia/theme/fjelia_style.dart';
import 'package:fjelia/widgets/ecg_sheet.dart';
import 'package:fjelia/widgets/manual_activity_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RowingRecorder extends IndoorRecorder {
  _RowingRecorder(super.ref, IndoorCapture capture) {
    final now = DateTime.now().toUtc();
    state = IndoorRecorderState(
      phase: IndoorPhase.recording,
      machine: FtmsMachine.rower,
      device: capture.device,
      capture: capture,
      connected: true,
      live: {'hr': 146, ...capture.live(now)},
      rowing: capture.rowing.live(now),
    );
  }

  @override
  Future<void> disconnectIdle() async {}

  @override
  Future<void> pause() async {
    state = IndoorRecorderState(
      phase: IndoorPhase.paused,
      machine: state.machine,
      device: state.device,
      capture: state.capture,
      connected: true,
    );
  }
}

class _RowingEcg extends EcgRecorder {
  _RowingEcg(super.ref) {
    // Synthetic signal for layout previews; never used as recorded data.
    final signal = [
      for (var i = 0; i < 650; i++)
        (30 * math.sin(i / 18) +
                1150 * math.exp(-math.pow((i % 110 - 25) / 1.7, 2)) +
                160 * math.exp(-math.pow((i % 110 - 52) / 6, 2)))
            .round(),
    ];
    state = EcgRecorderState(
      phase: EcgPhase.recording,
      recordingId: 'rowing-ecg',
      rate: 130,
      durationMs: 5000,
      count: 650,
      preview: [EcgChunk(offsetUs: 0, microvolts: signal)],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() async {
    await db.close();
    Fjelia.style = FjeliaStyle.dark;
  });
  setUpAll(() async {
    if (Platform.environment['FJELIA_UI_PREVIEW_DIR'] == null) return;
    final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
    if (font.existsSync()) {
      await (FontLoader('Roboto')..addFont(
            Future.value(ByteData.sublistView(await font.readAsBytes())),
          ))
          .load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  IndoorCapture capture() {
    final at = DateTime.now().toUtc();
    final result = IndoorCapture(
      id: 'rowing-preview',
      startedAt: at.subtract(const Duration(minutes: 11, seconds: 45)),
      device: const TrainingDevice(id: 'rower', name: 'DFIT-D-R-03245'),
      machine: FtmsMachine.rower,
      name: 'Indoor Rowing',
    );
    for (var i = 0; i < 3; i++) {
      result.ingest(
        {
          'machine_strokes': 40 + i,
          'pace_500m': 180 + 30 * i,
          'cad': 20 + 4 * i,
          'w': 180 + 30 * i,
        },
        at.subtract(Duration(seconds: 4 - i * 2)),
        recording: true,
      );
    }
    result.elapsedMs = 705000;
    result.totals['d'] = 1850;
    result.ecgDevice = const TrainingDevice(
      id: 'h10',
      name: 'Polar H10 1C4BC83B',
    );
    result.ecgRecordingIds.add('rowing-ecg');
    return result;
  }

  Widget app({bool light = false, double textScale = 1}) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      indoorRecorderProvider.overrideWith(
        (ref) => _RowingRecorder(ref, capture()),
      ),
      ecgRecorderProvider.overrideWith(_RowingEcg.new),
    ],
    child: MaterialApp(
      theme: light ? AppTheme.light() : AppTheme.dark(),
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => FjeliaStyleScope(
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
      home: Scaffold(
        body: RepaintBoundary(
          key: const ValueKey('rowing-preview'),
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: .94,
                child: const ManualActivitySheet(),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> screenshot(WidgetTester tester, String name) async {
    final output = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
    if (output == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('rowing-preview')),
    );
    await tester.runAsync(() async {
      final rendered = await boundary.toImage(pixelRatio: 2);
      final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
      rendered.dispose();
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  void size(WidgetTester tester, Size viewport) {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'rower shows three-stroke metrics and switches its large figure',
    (tester) async {
      size(tester, const Size(390, 844));
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('rowing-primary-value')))
            .data,
        '3:30',
      );
      expect(find.text('Ø 3 Schläge'), findsNWidgets(2));
      expect(find.text('146'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('rowing-power'))).data,
        '210',
      );
      final pause = tester.getRect(find.byKey(const ValueKey('record-pause')));
      final ecg = tester.getRect(find.byKey(const ValueKey('rowing-ecg')));
      expect(ecg.bottom, lessThan(pause.top));
      expect(
        tester.getRect(find.byKey(const ValueKey('rowing-heart-rate'))).height,
        greaterThan(40),
      );
      expect(
        tester.widget<EcgWaveform>(find.byType(EcgWaveform)).showControls,
        isFalse,
      );
      await screenshot(tester, 'rowing-dark-pace');

      await tester.tap(find.byKey(const ValueKey('rowing-primary')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('rowing-primary-value')))
            .data,
        '24',
      );
      expect(find.text('3:30 /500 m'), findsOneWidget);
      await screenshot(tester, 'rowing-dark-strokes');
      await tester.tap(find.byKey(const ValueKey('record-pause')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('record-resume')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('rowing-heart-rate')))
            .data,
        '—',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  for (final config in [
    (
      name: 'rowing-light',
      viewport: const Size(390, 844),
      light: true,
      scale: 1.0,
    ),
    (
      name: 'rowing-small',
      viewport: const Size(320, 640),
      light: false,
      scale: 1.0,
    ),
    (
      name: 'rowing-landscape',
      viewport: const Size(844, 390),
      light: false,
      scale: 1.0,
    ),
    (
      name: 'rowing-large-text',
      viewport: const Size(390, 844),
      light: false,
      scale: 1.6,
    ),
  ]) {
    testWidgets('${config.name} remains readable and can reach the full ECG', (
      tester,
    ) async {
      size(tester, config.viewport);
      await tester.pumpWidget(
        app(light: config.light, textScale: config.scale),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('record-pause')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await screenshot(tester, config.name);
      await tester.ensureVisible(find.byType(EcgWaveform));
      await tester.pumpAndSettle();
      expect(find.byType(EcgWaveform).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}
