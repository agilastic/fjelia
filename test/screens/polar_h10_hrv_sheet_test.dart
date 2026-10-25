import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/hrv_training_episode.dart';
import 'package:fjelia/models/spot_hrv.dart';
import 'package:fjelia/providers/hrv_reminder_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/services/polar_h10_service.dart';
import 'package:fjelia/widgets/polar_h10_hrv_sheet.dart';

class _Sensor extends PolarH10Service {
  final controller = StreamController<H10HeartRatePacket>.broadcast();
  int disconnected = 0;
  @override
  Stream<H10HeartRatePacket> get packets => controller.stream;
  @override
  Future<List<H10Device>> scan() async => [
    const H10Device('sensor', 'Polar H10 test', -40),
  ];
  @override
  Future<void> connect(H10Device device) async {}
  @override
  Future<void> disconnect() async {
    disconnected++;
  }

  @override
  Future<void> dispose() async {
    await controller.close();
    await super.dispose();
  }
}

void main() {
  testWidgets(
    'waits for RR before starting and cancels a background measurement',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final sensor = _Sensor();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(body: PolarH10HrvSheet(sensor: sensor)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Find Polar H10'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Find Polar H10'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Polar H10 test'));
      await tester.tap(find.text('Polar H10 test'));
      await tester.pumpAndSettle();
      FilledButton start() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Start measurement'),
      );
      expect(start().onPressed, isNull);
      sensor.controller.add(const H10HeartRatePacket(60, [], true));
      await tester.pump();
      expect(start().onPressed, isNull);
      sensor.controller.add(const H10HeartRatePacket(60, [1000], true));
      await tester.pump();
      expect(start().onPressed, isNotNull);
      await tester.ensureVisible(find.text('Start measurement'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start measurement'));
      await tester.pump();
      expect(find.text('Settling · stay still'), findsOneWidget);
      // The real lifecycle goes resumed → inactive → hidden → paused, and
      // back through hidden and inactive; Flutter rejects shortcuts.
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(find.textContaining('Measurement interrupted'), findsOneWidget);
      expect(find.text('Save measurement'), findsNothing);
      expect(sensor.disconnected, greaterThan(0));
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      // Drift closes its query streams with a zero-length timer.
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.takeException(), isNull);
    },
  );

  group('opened from a workout', () {
    testWidgets(
      'HRV-T047 the role, position and length follow the pre measurement, '
      'the delay is computed and one capture is marked as running',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final end = DateTime.now().subtract(const Duration(minutes: 29));
        late ProviderContainer container;
        final open = ValueNotifier(true);
        addTearDown(open.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    container = ProviderScope.containerOf(context);
                    return ValueListenableBuilder<bool>(
                      valueListenable: open,
                      builder: (_, isOpen, _) => isOpen
                          ? PolarH10HrvSheet(
                              sensor: _Sensor(),
                              launch: HrvLaunchContext(
                                episodeId: 'ep',
                                posture: 'supine',
                                durationSeconds: 120,
                                workoutEnd: end,
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DropdownButtonFormField<SpotHrvContext>>(
                find.byType(DropdownButtonFormField<SpotHrvContext>),
              )
              .initialValue,
          SpotHrvContext.afterTraining,
        );
        expect(
          tester
              .widget<DropdownButtonFormField<SpotHrvPosture>>(
                find.byType(DropdownButtonFormField<SpotHrvPosture>),
              )
              .initialValue,
          SpotHrvPosture.supine,
        );
        expect(
          tester
              .widget<DropdownButtonFormField<int>>(
                find.byType(DropdownButtonFormField<int>),
              )
              .initialValue,
          120,
        );
        // The role is fixed, and nothing is typed for the delay.
        expect(
          tester
              .widget<DropdownButtonFormField<SpotHrvContext>>(
                find.byType(DropdownButtonFormField<SpotHrvContext>),
              )
              .onChanged,
          isNull,
        );
        expect(
          find.text('Minutes since training ended (optional)'),
          findsNothing,
        );
        expect(
          find.textContaining(
            'Sampling would start about 30 min after your workout ended',
          ),
          findsOneWidget,
        );
        expect(container.read(hrvCaptureActiveProvider), isTrue);
        open.value = false;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 5));
        expect(container.read(hrvCaptureActiveProvider), isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 5));
      },
    );

    testWidgets('a plain launch keeps the typed minutes and free choice', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(body: PolarH10HrvSheet(sensor: _Sensor())),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<SpotHrvContext>>(
              find.byType(DropdownButtonFormField<SpotHrvContext>),
            )
            .onChanged,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 5));
    });
  });
}
