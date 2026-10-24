import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/spot_hrv.dart';
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
}
