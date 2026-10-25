import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/spot_hrv.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/hrv_training_provider.dart';
import 'package:fjelia/services/hrv/hrv_training_service.dart';
import 'package:fjelia/widgets/workout_hrv_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/hrv_db.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> show(
    WidgetTester tester, {
    double width = 390,
    double textScale = 1,
    VoidCallback? onExplain,
  }) async {
    tester.view.physicalSize = Size(width, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          // The fixtures are dated after the real clock.
          hrvTrainingServiceProvider.overrideWithValue(
            HrvTrainingService(db, clock: () => atMin(600)),
          ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 1800),
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: WorkoutHrvCard(activityId: 'ride', onExplain: onExplain),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      if (find.text('HRV AROUND THIS WORKOUT').evaluate().isNotEmpty) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
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

  testWidgets('HRV-T081 without readings: a small optional entry, no score', (
    tester,
  ) async {
    await addActivity(db, 'ride', 0, 120);
    await show(tester);
    expect(find.text('HRV AROUND THIS WORKOUT'), findsOneWidget);
    expect(
      find.text('No HRV measurement recorded around this workout.'),
      findsOneWidget,
    );
    expect(find.text('Measure HRV'), findsOneWidget);
    expect(find.textContaining('Change'), findsNothing);
    await close(tester);
  });

  testWidgets(
    'HRV-T081 a comparable pair shows values, real delay and change',
    (tester) async {
      await addActivity(db, 'ride', 0, 120);
      await addReading(db, -20, SpotHrvContext.beforeTraining, rmssd: 60);
      await addReading(db, 151, SpotHrvContext.afterTraining, rmssd: 45);
      await show(tester);
      expect(find.text('60.0'), findsOneWidget);
      expect(find.text('45.0'), findsOneWidget);
      // The delay is the measured sampling start, not the reminder's 30.
      expect(
        find.textContaining('+31 min after', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('−15 ms'), findsOneWidget);
      expect(find.text('−25 %'), findsOneWidget);
      expect(find.textContaining('not a score'), findsOneWidget);
      expect(
        find.textContaining('Not enough comparable workouts yet (0 of 8)'),
        findsOneWidget,
      );
      await close(tester);
    },
  );

  testWidgets('HRV-T016 a mismatch keeps the values and says why', (
    tester,
  ) async {
    await addActivity(db, 'ride', 0, 120);
    await addReading(db, -20, SpotHrvContext.beforeTraining, rmssd: 60);
    await addReading(
      db,
      151,
      SpotHrvContext.afterTraining,
      rmssd: 45,
      posture: SpotHrvPosture.supine,
    );
    await show(tester);
    expect(find.text('60.0'), findsOneWidget);
    expect(find.text('45.0'), findsOneWidget);
    expect(find.text('Change'), findsNothing);
    expect(find.text('−15 ms'), findsNothing);
    expect(
      find.textContaining('different positions, so the change is not compared'),
      findsOneWidget,
    );
    await close(tester);
  });

  testWidgets('post only: no delta and the missing pre is said', (
    tester,
  ) async {
    await addActivity(db, 'ride', 0, 120);
    await addReading(db, 151, SpotHrvContext.afterTraining, rmssd: 45);
    await show(tester);
    expect(find.text('No pre-training measurement recorded.'), findsOneWidget);
    expect(find.text('Change'), findsNothing);
    await close(tester);
  });

  testWidgets('pre only offers the measurement after training', (tester) async {
    await addActivity(db, 'ride', 0, 120);
    await addReading(db, -20, SpotHrvContext.beforeTraining);
    await show(tester);
    expect(find.text('Measure after training'), findsOneWidget);
    expect(find.text('Measure again'), findsNothing);
    await close(tester);
  });

  testWidgets('HRV-T085 two readings do not draw a recovery curve', (
    tester,
  ) async {
    await addActivity(db, 'ride', 0, 120);
    await addReading(db, -20, SpotHrvContext.beforeTraining);
    await addReading(db, 151, SpotHrvContext.afterTraining);
    await show(tester);
    expect(
      find.byType(CustomPaint).evaluate().where((e) {
        final w = e.widget as CustomPaint;
        return w.painter.runtimeType.toString().contains('Line');
      }),
      isEmpty,
    );
    expect(find.textContaining('recovery'), findsNothing);
    await close(tester);
  });

  testWidgets('HRV-T010 overlapping workouts are shown as unclear', (
    tester,
  ) async {
    await addActivity(db, 'ride', 0, 120);
    await addActivity(db, 'other', 30, 120, source: 'coros');
    await addReading(db, -20, SpotHrvContext.beforeTraining);
    await show(tester);
    expect(
      find.textContaining(
        'Workouts overlap, so the readings cannot be assigned',
      ),
      findsOneWidget,
    );
    await close(tester);
  });

  testWidgets('RPE is recorded as one canonical report and shown', (
    tester,
  ) async {
    await addActivity(db, 'ride', 0, 120);
    await show(tester);
    // No readings yet: the card offers only the measurement. Add one.
    await close(tester);
    await addReading(db, -20, SpotHrvContext.beforeTraining);
    await show(tester);
    expect(find.text('How hard did it feel? (RPE)'), findsOneWidget);
    await tester.tap(find.text('7'));
    await settle(tester);
    expect(find.text('RPE 7'), findsOneWidget);
    expect(await db.select(db.hrvEpisodeFeedback).get(), hasLength(1));
    await close(tester);
  });

  testWidgets('HRV-T091 a plan session RPE is used and labelled', (
    tester,
  ) async {
    await addActivity(db, 'ride', 0, 120);
    await addReading(db, -20, SpotHrvContext.beforeTraining);
    await db
        .into(db.sessionActuals)
        .insert(
          SessionActualsCompanion.insert(
            sessionId: 's1',
            activityId: const Value('ride'),
            rpe: const Value(5),
          ),
        );
    await show(tester);
    expect(find.text('RPE 5 · from your plan session'), findsOneWidget);
    await close(tester);
  });

  testWidgets('the reminder state is explained where it matters', (
    tester,
  ) async {
    await addActivity(db, 'ride', 0, 120);
    await addReading(db, -20, SpotHrvContext.beforeTraining, uid: 'pre');
    final now = DateTime.now().toUtc();
    Future<void> reminder(String state, {String reason = 'none'}) async {
      await db.delete(db.hrvPostReminders).go();
      final episode = await db.select(db.hrvTrainingEpisodes).getSingleOrNull();
      await db
          .into(db.hrvPostReminders)
          .insert(
            HrvPostRemindersCompanion.insert(
              reminderId: 'r',
              episodeId: episode!.episodeId,
              preMeasurementUid: 'pre',
              installationEpoch: 'e',
              nativeNotificationId: 7000001,
              originalDueAtUtc: now,
              nextDueAtUtc: now,
              expiresAtUtc: now,
              targetOffsetSeconds: 1800,
              desiredState: state,
              reason: Value(reason),
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );
    }

    // The episode exists once the card has been built.
    await show(tester);
    await reminder('suppressed', reason: 'permissionBlocked');
    await close(tester);
    await show(tester);
    expect(
      find.text(
        'Notifications are off. You can still measure from your workout.',
      ),
      findsOneWidget,
    );
    await close(tester);

    await reminder('expired');
    await show(tester);
    expect(find.textContaining('no longer current'), findsOneWidget);
    await close(tester);
  });

  testWidgets('HRV-T086 a small screen and large text do not overflow', (
    tester,
  ) async {
    await addActivity(db, 'ride', 0, 120);
    await addReading(db, -20, SpotHrvContext.beforeTraining, rmssd: 60);
    await addReading(db, 151, SpotHrvContext.afterTraining, rmssd: 45);
    await show(tester, width: 320, textScale: 2, onExplain: () {});
    expect(tester.takeException(), isNull);
    expect(find.text('Explain with AI'), findsOneWidget);
    // The figures have a spoken equivalent.
    expect(
      find.bySemanticsLabel(RegExp('Change .*15 milliseconds')),
      findsOneWidget,
    );
    await close(tester);
  });

  testWidgets(
    'details name the association and let a stray reading be assigned',
    (tester) async {
      await addActivity(db, 'ride', 0, 120);
      await addReading(db, -20, SpotHrvContext.beforeTraining, uid: 'pre');
      // Taken 90 minutes after the end: outside the automatic window.
      await addReading(
        db,
        120 + 130,
        SpotHrvContext.afterTraining,
        uid: 'late',
      );
      await show(tester);
      await tester.tap(find.text('Details'));
      // The details open with a short animation.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Association: one side only'), findsOneWidget);
      expect(find.textContaining('not assigned'), findsOneWidget);
      await tester.tap(find.text('Use as after'));
      await settle(tester);
      // Both readings (50.0 ms each) now show on the card.
      expect(find.text('50.0'), findsNWidgets(2));
      final link = await (db.select(
        db.hrvEpisodeMeasurements,
      )..where((t) => t.measurementUid.equals('late'))).getSingle();
      expect(link.associationMethod, 'userCorrection');
      await close(tester);
    },
  );
}
