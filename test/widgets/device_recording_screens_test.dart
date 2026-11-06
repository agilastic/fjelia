import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/ecg_provider.dart';
import 'package:fjelia/providers/indoor_recording_provider.dart';
import 'package:fjelia/providers/polar_h10_provider.dart';
import 'package:fjelia/screens/activities/activities_screen.dart';
import 'package:fjelia/screens/ocr/manual_entry_sheet.dart';
import 'package:fjelia/services/ecg_storage_service.dart';
import 'package:fjelia/theme/app_theme.dart';
import 'package:fjelia/widgets/ecg_sheet.dart';
import 'package:fjelia/widgets/manual_activity_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PreviewIndoor extends IndoorRecorder {
  _PreviewIndoor(
    super.ref,
    IndoorCapture capture, {
    IndoorPhase phase = IndoorPhase.paused,
  }) {
    state = IndoorRecorderState(
      phase: phase,
      device: capture.device,
      machine: capture.machine,
      capture: capture,
      connected: false,
      live: const {'spd': 2.68, 'hr': 142, 'incline': 3.5},
    );
  }
  @override
  Future<void> disconnectIdle() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Real fonts only for preview screenshots, as in screen_views_test.
  setUpAll(() async {
    if (Platform.environment['FJELIA_UI_PREVIEW_DIR'] == null) return;
    final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
    if (font.existsSync()) {
      final loader = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
      await loader.load();
    }
    try {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    } catch (_) {}
  });
  late AppDatabase db;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    await db.close();
  });

  Widget app(
    Widget child, {
    List<Override> overrides = const [],
    Locale locale = const Locale('en'),
  }) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      polarH10PairedProvider.overrideWith((ref) async => null),
      indoorPairedProvider.overrideWith((ref) async => null),
      indoorHeartRatePairedProvider.overrideWith((ref) async => null),
      ...overrides,
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RepaintBoundary(
          key: const ValueKey('preview'),
          // The colour of the app's sheets, so previews look as on a phone.
          child: ColoredBox(color: const Color(0xFF111111), child: child),
        ),
      ),
    ),
  );

  Future<void> screenshot(WidgetTester tester, String name) async {
    final output = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
    if (output == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final dir = await Directory(output).create(recursive: true);
      await File('${dir.path}/$name.png')
          .writeAsBytes(png!.buffer.asUint8List());
    });
  }

  testWidgets('plus menu exposes ECG and one place to record any activity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const ManualEntrySheet()));
    await tester.pumpAndSettle();
    await screenshot(tester, 'plus-menu');
    // One live entry on top, then the topics.
    expect(find.text('Start workout'), findsOneWidget);
    expect(find.text('Indoor Training'), findsNothing);
    for (final group in ['TRAINING', 'HEART & CIRCULATION', 'RECOVERY']) {
      await tester.scrollUntilVisible(find.text(group), 200);
      expect(find.text(group), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text('Record ECG'), -200);
    await tester.ensureVisible(find.text('Record ECG'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record ECG'));
    await tester.pumpAndSettle();
    expect(find.byType(EcgSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('logging a workout shows its form in German too', (tester) async {
    await tester.pumpWidget(
      app(const ManualEntrySheet(), locale: const Locale('de')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Training nachtragen'));
    await tester.pumpAndSettle();
    // The form is looked up by its id, not by the translated label.
    expect(find.byType(TextField), findsNWidgets(5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  Finder switchOf(String key) => find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(Switch),
  );
  VoidCallback? startAction(WidgetTester tester) => tester
      .widget<GestureDetector>(
        find
            .descendant(
              of: find.byKey(const ValueKey('record-start')),
              matching: find.byType(GestureDetector),
            )
            .first,
      )
      .onTap;
  Future<void> pickSport(WidgetTester tester, String sport) async {
    await tester.tap(find.byKey(const ValueKey('record-sport')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(sport).last);
    await tester.pumpAndSettle();
  }

  testWidgets('manual run setup exposes ECG and supports time-only recording', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const ManualActivitySheet()));
    await tester.pumpAndSettle();
    await screenshot(tester, 'record-setup');
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('ECG'), findsOneWidget);
    expect(find.text('Heart rate'), findsOneWidget);
    expect(find.text('GPS'), findsNWidgets(2));
    // ECG is on, but no H10 is chosen yet.
    expect(startAction(tester), isNull);
    await tester.tap(switchOf('record-ecg'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(switchOf('record-hr'));
    await tester.tap(switchOf('record-hr'));
    await tester.pumpAndSettle();
    expect(startAction(tester), isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('a live run shows time, pace and distance big', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = IndoorCapture(
      id: 'run-preview',
      startedAt: DateTime.utc(2026, 11, 5),
      device: const TrainingDevice(id: 'phone', name: 'Fjelia'),
      machine: FtmsMachine.treadmill,
      dataProtocol: 'manual',
      activityTypeOverride: 'running',
      name: 'Running',
      gpsEnabled: true,
    );
    c.totals['d'] = 3420;
    c.elapsedMs = 1143000;
    await tester.pumpWidget(
      app(
        const ManualActivitySheet(),
        overrides: [
          indoorRecorderProvider.overrideWith(
            (ref) => _PreviewIndoor(ref, c, phase: IndoorPhase.recording),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await screenshot(tester, 'record-live');
    expect(find.text('00:19:03'), findsOneWidget);
    // 2.68 m/s is 6:13 per kilometre.
    expect(find.text('6:13'), findsOneWidget);
    expect(find.text('3.42'), findsOneWidget);
    expect(find.text('142'), findsOneWidget);
    expect(find.byKey(const ValueKey('record-pause')), findsOneWidget);
    expect(find.byKey(const ValueKey('record-map')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('a treadmill run offers the Bluetooth treadmill', (tester) async {
    await tester.pumpWidget(app(const ManualActivitySheet()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('record-machine')), findsNothing);
    await pickSport(tester, 'Treadmill run');
    expect(find.byKey(const ValueKey('record-machine')), findsOneWidget);
    expect(
      find.text('Connect treadmill (Bluetooth, optional)'),
      findsOneWidget,
    );
    // No GPS indoors.
    final gps = tester.widget<Switch>(switchOf('record-gps'));
    expect(gps.value, isFalse);
    expect(gps.onChanged, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('indoor cycling waits for its machine before it starts', (
    tester,
  ) async {
    await tester.pumpWidget(app(const ManualActivitySheet()));
    await tester.pumpAndSettle();
    await pickSport(tester, 'Indoor cycling');
    expect(find.text('Choose equipment'), findsOneWidget);
    // Without ECG and heart rate only the machine is missing.
    await tester.ensureVisible(switchOf('record-ecg'));
    await tester.tap(switchOf('record-ecg'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(switchOf('record-hr'));
    await tester.tap(switchOf('record-hr'));
    await tester.pumpAndSettle();
    expect(startAction(tester), isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  Future<EcgRecording> ecgRow(WidgetTester tester, {String? activityId}) async {
    late EcgRecording row;
    await tester.runAsync(() async {
      final repo = EcgStorageService(db);
      final id = await repo.begin(
        deviceId: 'h10',
        deviceName: 'Polar H10',
        rate: 130,
        resolution: 14,
        activityId: activityId,
      );
      await repo.append(
        id,
        [
          EcgChunk(
            offsetUs: 0,
            microvolts: [for (var i = 0; i < 1300; i++) i % 130 == 0 ? 900 : 0],
          ),
        ],
        0,
        count: 1300,
        durationMs: 10000,
        gaps: 0,
      );
      await repo.finish(id, interrupted: false);
      row = (await repo.recording(id))!;
    });
    return row;
  }

  testWidgets('an ECG taken during an activity shows in its details', (
    tester,
  ) async {
    await ecgRow(tester, activityId: 'run-1');
    await tester.pumpWidget(
      app(
        const SingleChildScrollView(
          child: ActivityEcgCard(activityId: 'run-1'),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('ECG'), findsOneWidget);
    expect(find.text('Polar H10'), findsOneWidget);
    expect(find.byType(EcgWaveform), findsOneWidget);
    // Another activity has none.
    await tester.pumpWidget(
      app(
        const SingleChildScrollView(
          child: ActivityEcgCard(activityId: 'other'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Polar H10'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('an ECG of its own is an entry of the history', (tester) async {
    await ecgRow(tester);
    await ecgRow(tester, activityId: 'run-1');
    await tester.pumpWidget(
      app(
        const SingleChildScrollView(
          child: ActivityHistory(showHeader: false, monthMode: true),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    // Only the one without an activity.
    expect(find.byType(EcgHistoryTile), findsOneWidget);
    expect(find.text('ECG · Polar H10'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'ECG waveform review supports zoom and horizontal navigation on a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = EcgStorageService(db);
      late EcgRecording row;
      await tester.runAsync(() async {
        final id = await repo.begin(
          deviceId: 'h10',
          deviceName: 'Polar H10',
          rate: 130,
          resolution: 14,
        );
        final raw = [
          for (var i = 0; i < 1560; i++)
            (80 * math.sin(i / 8) +
                    (i % 130 == 25
                        ? 1000
                        : i % 130 == 27
                        ? -350
                        : 0))
                .round(),
        ];
        await repo.append(
          id,
          [EcgChunk(offsetUs: 0, microvolts: raw)],
          0,
          count: raw.length,
          durationMs: 12000,
          gaps: 0,
        );
        await repo.finish(id, interrupted: false);
        row = (await repo.recording(id))!;
      });
      await tester.pumpWidget(app(EcgDetailSheet(recording: row)));
      await tester.pumpAndSettle();
      expect(find.text('Export waveform (CSV)'), findsOneWidget);
      expect(find.text('100% sample coverage'), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<double>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 s').last);
      await tester.pumpAndSettle();
      final slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChanged!(4);
      await tester.pump();
      expect(find.text('4.0–6.0 s · µV'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await screenshot(tester, 'ecg-review');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Matrix screen explains recording-only mode and omits equipment control',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = IndoorCapture(
        id: 'matrix-preview',
        startedAt: DateTime.utc(2026, 11, 5),
        device: const TrainingDevice(
          id: 'matrix',
          name: 'Matrix Performance TouchXL',
        ),
        machine: FtmsMachine.treadmill,
        name: 'Indoor endurance run',
        steps: const [
          IndoorStep(label: 'warmup', seconds: 300, zone: 1),
          IndoorStep(label: 'interval', seconds: 1200, zone: 2),
        ],
      );
      c.totals['d'] = 2350;
      c.elapsedMs = 900000;
      await tester.pumpWidget(
        app(
          const ManualActivitySheet(),
          overrides: [
            indoorRecorderProvider.overrideWith(
              (ref) => _PreviewIndoor(ref, c),
            ),
            indoorPendingProvider.overrideWith((ref) => Stream.value([])),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('remote control has not been verified'),
        findsOneWidget,
      );
      expect(find.text('Allow equipment control'), findsNothing);
      expect(find.text('2.35'), findsOneWidget);
      expect(find.text('00:15:00'), findsOneWidget);
      // Paused: resume and finish as big buttons.
      expect(find.byKey(const ValueKey('record-resume')), findsOneWidget);
      expect(find.byKey(const ValueKey('record-finish')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await screenshot(tester, 'matrix-indoor');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
