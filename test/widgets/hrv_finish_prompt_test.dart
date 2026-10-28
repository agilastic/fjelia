import 'package:fjelia/l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/hrv_reminder_provider.dart';
import 'package:fjelia/widgets/hrv_finish_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationGateway gateway;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
  });
  tearDown(() => db.close());

  final now = DateTime.now();

  Future<void> preReading() => db
      .into(db.spotHrvMeasurements)
      .insert(
        SpotHrvMeasurementsCompanion.insert(
          startedAt: now.subtract(const Duration(minutes: 40)),
          context: 'beforeTraining',
          posture: 'seated',
          durationSeconds: 300,
          settleSeconds: 60,
          deviceId: 'h10',
          deviceName: 'Polar H10',
          rmssdMs: 55,
          sdnnMs: 60,
          meanHr: 60,
          acceptedIntervals: 290,
          totalIntervals: 295,
          coverage: .97,
          rrJson: '[]',
          measurementUid: const Value('pre'),
          samplingEndedAt: Value(now.subtract(const Duration(minutes: 35))),
          qualityState: const Value('usable'),
        ),
      );

  Future<void> optIn() => db
      .into(db.hrvReminderPreferences)
      .insert(
        HrvReminderPreferencesCompanion.insert(
          installationEpoch: 'epoch',
          optedIn: const Value(true),
          enabledSinceUtc: Value(
            now.subtract(const Duration(hours: 2)).toUtc(),
          ),
          updatedAtUtc: now.toUtc(),
        ),
      );

  late ProviderContainer container;
  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          localNotificationGatewayProvider.overrideWithValue(gateway),
          hrvSensorReadyProvider.overrideWithValue(() async => true),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                container = ProviderScope.containerOf(context);
                return const SingleChildScrollView(child: HrvFinishPrompt());
              },
            ),
          ),
        ),
      ),
    );
    await wait(tester);
  }

  testWidgets('hidden while the reminder is off', (tester) async {
    await preReading();
    await show(tester);
    expect(find.text('Workout finished'), findsNothing);
    await close(tester);
  });

  testWidgets('hidden without a waiting before-training reading', (
    tester,
  ) async {
    await optIn();
    await show(tester);
    expect(find.text('Workout finished'), findsNothing);
    await close(tester);
  });

  testWidgets('HRV-T011 a waiting pre with the reminder on offers the report', (
    tester,
  ) async {
    await preReading();
    await optIn();
    await show(tester);
    expect(find.text('Workout finished?'.toUpperCase()), findsOneWidget);
    expect(find.text('Workout finished'), findsOneWidget);
    // No timer was started from a guess.
    expect(gateway.scheduleCalls, 0);
    await close(tester);
  });

  testWidgets('HRV-D15 reporting the finish gives the reminder its real end', (
    tester,
  ) async {
    await preReading();
    await optIn();
    await show(tester);
    await container
        .read(hrvReminderActionsProvider)
        .reportFinish(
          start: now.subtract(const Duration(minutes: 30)),
          end: now.subtract(const Duration(minutes: 2)),
        );
    await wait(tester);
    // The reading belongs to the workout now, so nothing is waiting.
    expect(find.text('Workout finished'), findsNothing);
    expect(gateway.scheduled, hasLength(1));
    final due = gateway.scheduled.single.at;
    // Around 30 minutes after the reported end, not after the report.
    expect(
      due.difference(now.subtract(const Duration(minutes: 2))).inMinutes,
      anyOf(29, 30),
    );
    final episode = await db.select(db.hrvTrainingEpisodes).getSingle();
    expect(episode.intervalBasis, 'userReported');
    await close(tester);
  });

  testWidgets('a provider record arriving later joins the reported episode', (
    tester,
  ) async {
    await preReading();
    await optIn();
    await show(tester);
    final end = now.subtract(const Duration(minutes: 2));
    final start = now.subtract(const Duration(minutes: 30));
    await container
        .read(hrvReminderActionsProvider)
        .reportFinish(start: start, end: end);
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'real',
            name: 'Ride',
            type: 'cycling',
            startDate: start,
            durationSeconds: end.difference(start).inSeconds + 60,
            source: const Value('garmin_api'),
          ),
        );
    await container.read(hrvReminderActionsProvider).reconcile();
    expect(await db.select(db.hrvTrainingEpisodes).get(), hasLength(1));
    // One reminder chain throughout.
    expect(await db.select(db.hrvPostReminders).get(), hasLength(1));
    await close(tester);
  });
}

Future<void> wait(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
}
