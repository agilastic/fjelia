import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/database.dart';
import '../models/spot_hrv.dart';
import 'database_provider.dart';

final spotHrvProvider = StreamProvider<List<SpotHrvMeasurement>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.spotHrvMeasurements)
        ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
        ..limit(200))
      .watch();
});

Future<void> saveSpotHrv(
  AppDatabase db, {
  required SpotHrvCapture capture,
  required SpotHrvContext context,
  required SpotHrvPosture posture,
  required String deviceId,
  required String deviceName,
  required Duration elapsed,
  String notes = '',
  int? minutesAfterTraining,
}) async {
  final result = capture.analysis;
  if (!capture.complete(elapsed) || !result.reliable) {
    throw StateError('A complete recording with a usable signal is required.');
  }
  await db
      .into(db.spotHrvMeasurements)
      .insert(
        SpotHrvMeasurementsCompanion.insert(
          startedAt: capture.measurementStartedAt,
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
        ),
      );
}
