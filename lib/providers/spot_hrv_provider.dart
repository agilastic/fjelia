import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/database.dart';
import '../models/hrv_training_episode.dart';
import '../models/spot_hrv.dart';
import '../services/hrv/hrv_timing_policy.dart';
import 'database_provider.dart';

final spotHrvProvider = StreamProvider<List<SpotHrvMeasurement>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.spotHrvMeasurements)
        ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
        ..limit(200))
      .watch();
});

/// Version of the capture protocol: settling, then the recording window.
const spotProtocolVersion = 'spot-rr-v1';
const spotAnalysisVersion = 'rmssd-v1';

/// Saves a complete, usable recording and returns its stable id.
///
/// Saving the same capture again is the same save: it returns the id of the
/// row that is already there. With a [launch], the reading is linked to that
/// workout in the same transaction (the pairing still checks the timing).
Future<String> saveSpotHrv(
  AppDatabase db, {
  required SpotHrvCapture capture,
  required SpotHrvContext context,
  required SpotHrvPosture posture,
  required String deviceId,
  required String deviceName,
  required Duration elapsed,
  String notes = '',
  int? minutesAfterTraining,
  HrvLaunchContext? launch,
  DateTime? now,
}) async {
  final result = capture.analysis;
  if (!capture.complete(elapsed) || !result.reliable) {
    throw StateError('A complete recording with a usable signal is required.');
  }
  final uid = capture.captureId;
  final stamp = (now ?? DateTime.now()).toUtc();
  final start = capture.measurementStartedAt;
  await db.transaction(() async {
    final existing = await (db.select(
      db.spotHrvMeasurements,
    )..where((t) => t.measurementUid.equals(uid))).getSingleOrNull();
    if (existing != null) return;
    await db
        .into(db.spotHrvMeasurements)
        .insert(
          SpotHrvMeasurementsCompanion.insert(
            startedAt: start,
            context: context.name,
            posture: posture.name,
            durationSeconds: capture.durationSeconds,
            settleSeconds: capture.settleSeconds,
            deviceId: deviceId,
            deviceName: deviceName,
            rmssdMs: result.rmssdMs!,
            rawRmssdMs: Value(result.rawRmssdMs),
            sdnnMs: result.sdnnMs!,
            meanHr: result.meanHr!,
            lnRmssd: Value(result.lnRmssd),
            acceptedIntervals: result.accepted,
            totalIntervals: result.samples.length,
            coverage: result.coverage,
            rrJson: result.rrJson,
            notes: Value(notes.trim().isEmpty ? null : notes.trim()),
            minutesAfterTraining: Value(
              context == SpotHrvContext.afterTraining
                  ? minutesAfterTraining
                  : null,
            ),
            measurementUid: Value(uid),
            samplingEndedAt: Value(
              start.add(Duration(seconds: capture.durationSeconds)),
            ),
            captureStartedAt: Value(capture.startedAt),
            timezoneOffsetMinutes: Value(
              capture.startedAt.timeZoneOffset.inMinutes,
            ),
            protocolVersion: const Value(spotProtocolVersion),
            analysisVersion: const Value(spotAnalysisVersion),
            qualityState: const Value('usable'),
            qualityReasons: Value(
              capture.clockUncertain ? 'clockUncertain' : null,
            ),
            createdAt: Value(stamp),
            modifiedAt: Value(stamp),
          ),
        );
    if (launch != null) {
      // The athlete started this from a workout, so the link is theirs. The
      // pairing drops it again if the timing cannot hold.
      await db
          .into(db.hrvEpisodeMeasurements)
          .insert(
            HrvEpisodeMeasurementsCompanion.insert(
              episodeId: launch.episodeId,
              measurementUid: uid,
              role: launch.role.name,
              selection: 'primary',
              associationMethod: AssociationMethod.launchContext.name,
              reason: const Value('launchContext'),
              policyVersion: HrvTimingPolicy.standard.version,
              createdAtUtc: stamp,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  });
  return uid;
}
