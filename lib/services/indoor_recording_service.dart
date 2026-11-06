import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../models/indoor_recording.dart';
import 'activity_blood_pressure.dart';
import 'hr_zone_model.dart' show zonePercentFromActiveSamples;

class IndoorRecordingService {
  IndoorRecordingService(this.db);
  final AppDatabase db;

  Future<List<BpMeasurement>> bloodPressure(IndoorCapture capture) async {
    if (!capture.includeBloodPressure || capture.samples.isEmpty) return [];
    final end = DateTime.fromMillisecondsSinceEpoch(
      capture.samples.last['t']!.round(),
      isUtc: true,
    );
    final rows =
        await (db.select(db.bpMeasurements)..where(
              (t) => t.measuredAt.isBetweenValues(capture.startedAt, end),
            ))
            .get();
    return rows.where((r) => bloodPressureDuringActivity(capture, r)).toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
  }

  Stream<List<IndoorRecording>> watchPending({bool manual = false}) =>
      (db.select(db.indoorRecordings)
            ..where((t) => t.status.equals('saved').not())
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .watch()
          .map(
            (rows) => rows.where((row) {
              try {
                return (jsonDecode(row.dataJson)['data_protocol'] ==
                        'manual') ==
                    manual;
              } catch (_) {
                return false;
              }
            }).toList(),
          );

  Future<void> checkpoint(IndoorCapture capture, String status) => db
      .into(db.indoorRecordings)
      .insertOnConflictUpdate(
        IndoorRecordingsCompanion.insert(
          recordingId: capture.id,
          startedAt: capture.startedAt,
          updatedAt: DateTime.now().toUtc(),
          status: status,
          dataJson: jsonEncode(capture.toJson()),
        ),
      );

  Future<IndoorCapture?> load(String id) async {
    final row = await (db.select(
      db.indoorRecordings,
    )..where((t) => t.recordingId.equals(id))).getSingleOrNull();
    return row == null
        ? null
        : IndoorCapture.fromJson(
            jsonDecode(row.dataJson) as Map<String, dynamic>,
          );
  }

  Future<String> save(IndoorCapture capture, {required List<int> zones}) =>
      db.transaction(() async {
        if (capture.elapsedMs < 1000 || capture.samples.isEmpty) {
          throw StateError('Record at least one second before saving.');
        }
        final existing = await db.getActivityById(capture.id);
        if (existing != null) return capture.id;
        // A previously deleted activity must not be silently resurrected by a
        // stale checkpoint or a second tap of Save.
        final deleted = await (db.select(
          db.deletedActivities,
        )..where((t) => t.activityId.equals(capture.id))).getSingleOrNull();
        if (deleted != null) {
          throw StateError('This recording was already deleted.');
        }
        final json = jsonEncode(capture.samples);
        final zoneFractions = zonePercentFromActiveSamples(
          json,
          zones,
          capture.elapsedMs / 1000,
        );
        await db
            .into(db.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: capture.id,
                name: capture.name,
                type: capture.activityType,
                startDate: capture.startedAt,
                durationSeconds: (capture.elapsedMs / 1000).round(),
                distanceMeters: Value(capture.totals['d']),
                avgHeartRate: Value(capture.average('hr')),
                maxHeartRate: Value(capture.maximum('hr')),
                avgWatts: Value(capture.average('w')),
                totalElevation: Value(capture.totals['ascent']),
                hrZonesJson: Value(
                  zoneFractions == null ? null : jsonEncode(zoneFractions),
                ),
                metricsJson: Value(json),
                gpxJson: Value(
                  capture.route.isEmpty ? null : jsonEncode(capture.route),
                ),
                source: Value(capture.isManual ? 'manual_recording' : 'ftms'),
                calories: Value(capture.totals['kcal']),
                maxSpeedMps: Value(capture.maximum('spd')),
                movingDurationSeconds: Value(
                  capture.isManual ? null : (capture.movingMs / 1000).round(),
                ),
                plannedWorkoutName: Value(
                  capture.sessionId == null ? null : capture.name,
                ),
                plannedStepsJson: Value(capture.plannedStepsJson),
                plannedDurationSeconds: Value(capture.plannedDurationSeconds),
              ),
            );
        if (capture.ecgRecordingIds.isNotEmpty) {
          await (db.update(db.ecgRecordings)..where(
                (t) =>
                    t.recordingId.isIn(capture.ecgRecordingIds) &
                    (t.activityId.isNull() | t.activityId.equals(capture.id)),
              ))
              .write(EcgRecordingsCompanion(activityId: Value(capture.id)));
        }
        final sessionId = capture.sessionId;
        if (sessionId != null) {
          final session = await (db.select(
            db.trainingSessions,
          )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
          final link = await (db.select(
            db.sessionActuals,
          )..where((t) => t.sessionId.equals(sessionId))).getSingleOrNull();
          if (session != null &&
              session.status != 'skipped' &&
              link?.activityId == null) {
            await db
                .into(db.sessionActuals)
                .insertOnConflictUpdate(
                  SessionActualsCompanion(
                    sessionId: Value(sessionId),
                    activityId: Value(capture.id),
                    startedAt: Value(capture.startedAt),
                    completedAt: Value(
                      DateTime.fromMillisecondsSinceEpoch(
                        capture.samples.last['t']!.toInt(),
                        isUtc: true,
                      ),
                    ),
                    avgHrBpm: Value(capture.average('hr')?.round()),
                    maxHrBpm: Value(capture.maximum('hr')?.round()),
                    avgPowerWatts: Value(capture.average('w')?.round()),
                  ),
                );
            await (db.update(
              db.trainingSessions,
            )..where((t) => t.id.equals(sessionId))).write(
              TrainingSessionsCompanion(
                status: const Value('completed'),
                actualDurationMin: Value((capture.elapsedMs / 60000).round()),
                dateModified: Value(DateTime.now()),
              ),
            );
          }
        }
        await checkpoint(capture, 'saved');
        await db.deduplicateActivities();
        return capture.id;
      });

  Future<void> discard(String id) async {
    final row = await (db.select(
      db.indoorRecordings,
    )..where((t) => t.recordingId.equals(id))).getSingleOrNull();
    if (row?.status == 'saved') {
      throw StateError('Delete saved workouts from activity history.');
    }
    await (db.delete(
      db.indoorRecordings,
    )..where((t) => t.recordingId.equals(id))).go();
  }
}
