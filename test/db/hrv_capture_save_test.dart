import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/hrv_training_episode.dart';
import 'package:fjelia/models/spot_hrv.dart';
import 'package:fjelia/providers/spot_hrv_provider.dart';
import 'package:fjelia/services/hrv/hrv_training_service.dart';
import 'package:flutter_test/flutter_test.dart';

SpotHrvCapture capture(DateTime at) {
  final c = SpotHrvCapture(startedAt: at, durationSeconds: 120);
  var end = 60000;
  for (var i = 0; i < 119; i++) {
    final rr = 1000.0 + (i % 2) * 10;
    end += rr.toInt();
    c.add(H10HeartRatePacket(60, [rr], true), Duration(milliseconds: end));
  }
  return c;
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<String> save(
    SpotHrvCapture c, {
    SpotHrvContext context = SpotHrvContext.beforeTraining,
    SpotHrvPosture posture = SpotHrvPosture.seated,
    HrvLaunchContext? launch,
    int? minutes,
  }) => saveSpotHrv(
    db,
    capture: c,
    context: context,
    posture: posture,
    deviceId: 'h10',
    deviceName: 'Polar H10',
    elapsed: const Duration(seconds: 180),
    launch: launch,
    minutesAfterTraining: minutes,
  );

  test('HRV-T041 saving the same capture twice is one measurement', () async {
    final c = capture(DateTime.utc(2026, 11, 2, 7, 40));
    final a = await save(c);
    final b = await save(c);
    expect(b, a);
    final rows = await db.select(db.spotHrvMeasurements).get();
    expect(rows, hasLength(1));
    expect(rows.single.measurementUid, c.captureId);
  });

  test('a save records when the sampling really ran, and how', () async {
    final started = DateTime.utc(2026, 11, 2, 7, 40);
    final c = capture(started);
    await save(c);
    final row = await db.select(db.spotHrvMeasurements).getSingle();
    // The window starts after the settling minute.
    expect(row.startedAt.toUtc(), started.add(const Duration(seconds: 60)));
    expect(
      row.samplingEndedAt!.toUtc(),
      started.add(const Duration(seconds: 180)),
    );
    expect(row.captureStartedAt!.toUtc(), started);
    expect(row.qualityState, 'usable');
    expect(row.metricKind, 'rmssd');
    expect(row.protocolVersion, spotProtocolVersion);
    expect(row.analysisVersion, spotAnalysisVersion);
    expect(row.timezoneOffsetMinutes, isNotNull);
    expect(row.createdAt, isNotNull);
  });

  test(
    'HRV-T004 the recorded start is the sampling start, not the reminder',
    () async {
      // Opened at +30 minutes after a workout that ended at 10:00.
      final opened = DateTime.utc(2026, 11, 2, 10, 30);
      await save(capture(opened), context: SpotHrvContext.afterTraining);
      final row = await db.select(db.spotHrvMeasurements).getSingle();
      expect(row.startedAt.toUtc(), DateTime.utc(2026, 11, 2, 10, 31));
    },
  );

  test('HRV-T050 a jumped wall clock is flagged, the timing kept', () async {
    final started = DateTime.utc(2026, 11, 2, 7, 40);
    final jumped = capture(started)
      ..checkClock(
        started.add(const Duration(seconds: 180 + 90)),
        const Duration(seconds: 180),
      );
    expect(jumped.clockUncertain, isTrue);
    await save(jumped);
    final row = await db.select(db.spotHrvMeasurements).getSingle();
    expect(row.qualityReasons, 'clockUncertain');

    final steady = capture(started)
      ..checkClock(
        started.add(const Duration(seconds: 183)),
        const Duration(seconds: 180),
      );
    expect(steady.clockUncertain, isFalse);
  });

  test('HRV-T049 the typed minutes stay apart from computed timing', () async {
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'a',
            name: 'a',
            type: 'cycling',
            startDate: DateTime.utc(2026, 11, 2, 8),
            durationSeconds: 7200,
            source: const Value('garmin_api'),
          ),
        );
    await save(
      capture(DateTime.utc(2026, 11, 2, 10, 30)),
      context: SpotHrvContext.afterTraining,
      minutes: 99,
    );
    final snapshot = await HrvTrainingService(
      db,
      clock: () => DateTime.utc(2026, 11, 2, 11),
    ).reconcile();
    final a = snapshot.assessments.values.single;
    expect(a.postDelay, const Duration(minutes: 31));
    expect(a.post!.reportedMinutesAfter, 99);
    final row = await db.select(db.spotHrvMeasurements).getSingle();
    expect(row.minutesAfterTraining, 99);
  });

  test('HRV-T047 a launch from a workout links the reading to it', () async {
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'a',
            name: 'a',
            type: 'cycling',
            startDate: DateTime.utc(2026, 11, 2, 8),
            durationSeconds: 7200,
            source: const Value('garmin_api'),
          ),
        );
    final service = HrvTrainingService(
      db,
      clock: () => DateTime.utc(2026, 11, 2, 11),
    );
    final episode = (await service.reconcile()).episodes.single.id;
    final uid = await save(
      capture(DateTime.utc(2026, 11, 2, 10, 30)),
      context: SpotHrvContext.afterTraining,
      launch: HrvLaunchContext(episodeId: episode),
    );
    final link = await db.select(db.hrvEpisodeMeasurements).getSingle();
    expect(link.measurementUid, uid);
    expect(link.associationMethod, 'launchContext');
    final snapshot = await service.reconcile();
    expect(snapshot.assessments[episode]!.post!.uid, uid);
  });

  test(
    'a launched reading that cannot hold its timing is dropped from the pair',
    () async {
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'a',
              name: 'a',
              type: 'cycling',
              startDate: DateTime.utc(2026, 11, 2, 8),
              durationSeconds: 7200,
              source: const Value('garmin_api'),
            ),
          );
      final service = HrvTrainingService(
        db,
        clock: () => DateTime.utc(2026, 11, 2, 11),
      );
      final episode = (await service.reconcile()).episodes.single.id;
      // Made while the workout was still running.
      await save(
        capture(DateTime.utc(2026, 11, 2, 9)),
        context: SpotHrvContext.afterTraining,
        launch: HrvLaunchContext(episodeId: episode),
      );
      final snapshot = await service.reconcile();
      expect(snapshot.assessments[episode]!.hasPost, isFalse);
      expect(snapshot.pairings[episode]!.contradictions, hasLength(1));
    },
  );

  test('a measure-again after a post is an extra observation', () async {
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'a',
            name: 'a',
            type: 'cycling',
            startDate: DateTime.utc(2026, 11, 2, 8),
            durationSeconds: 7200,
            source: const Value('garmin_api'),
          ),
        );
    final service = HrvTrainingService(
      db,
      clock: () => DateTime.utc(2026, 11, 2, 12),
    );
    final episode = (await service.reconcile()).episodes.single.id;
    final first = await save(
      capture(DateTime.utc(2026, 11, 2, 10, 30)),
      context: SpotHrvContext.afterTraining,
      launch: HrvLaunchContext(episodeId: episode),
    );
    await service.reconcile();
    final second = await save(
      capture(DateTime.utc(2026, 11, 2, 11, 0)),
      context: SpotHrvContext.afterTraining,
      launch: HrvLaunchContext(episodeId: episode),
    );
    final a = (await service.reconcile()).assessments[episode]!;
    expect(a.post!.uid, first);
    expect(a.additionalPosts.single.uid, second);
  });

  test('an incomplete or unreliable capture is refused', () async {
    final c = SpotHrvCapture(
      startedAt: DateTime.utc(2026, 11, 2, 7),
      durationSeconds: 120,
    );
    await expectLater(save(c), throwsStateError);
    expect(await db.select(db.spotHrvMeasurements).get(), isEmpty);
  });
}
