import 'dart:async';

import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/models/ftms.dart';
import 'package:fjelia/models/indoor_recording.dart';
import 'package:fjelia/models/training_device.dart';
import 'package:fjelia/providers/activity_blood_pressure_provider.dart';
import 'package:fjelia/widgets/activity_blood_pressure_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'later BP updates appear without including paused or unrelated readings',
    (tester) async {
      final readings = StreamController<List<BpMeasurement>>.broadcast();
      addTearDown(readings.close);
      final start = DateTime.utc(2026, 11, 5, 10);
      final capture =
          IndoorCapture(
              id: 'run',
              startedAt: start,
              device: const TrainingDevice(id: 'phone', name: 'Fjelia'),
              machine: FtmsMachine.treadmill,
              name: 'Run',
              dataProtocol: 'manual',
              includeBloodPressure: true,
            )
            ..event('start', start)
            ..event('pause', start.add(const Duration(minutes: 10)))
            ..event('resume', start.add(const Duration(minutes: 20)))
            ..snapshot(start.add(const Duration(minutes: 30)), 1200000);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activityBloodPressureProvider(start)
                .overrideWith((ref) => readings.stream),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: ActivityBloodPressureCard(capture: capture)),
          ),
        ),
      );
      readings.add([]);
      await tester.pumpAndSettle();
      expect(
        find.text('No blood pressure readings during this recording.'),
        findsOneWidget,
      );
      BpMeasurement reading(int minute, int sys, int dia) => BpMeasurement(
        id: minute,
        measuredAt: start.add(Duration(minutes: minute)),
        timezone: 'UTC',
        systolic: sys,
        diastolic: dia,
        heartRate: 62,
        measurementType: 'HILO',
      );
      readings.add([
        reading(5, 122, 75),
        reading(15, 133, 80),
        reading(60, 144, 90),
      ]);
      await tester.pumpAndSettle();
      expect(find.textContaining('122/75 mmHg'), findsOneWidget);
      expect(find.textContaining('133/80 mmHg'), findsNothing);
      expect(find.textContaining('144/90 mmHg'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
