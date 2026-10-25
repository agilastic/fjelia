import 'package:drift/drift.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/spot_hrv.dart';
import 'package:uuid/uuid.dart';

final base = DateTime.utc(2026, 11, 2, 8);

DateTime atMin(int minutes) => base.add(Duration(minutes: minutes));

Future<void> addActivity(
  AppDatabase db,
  String id,
  int startMin,
  int minutes, {
  String source = 'garmin_api',
  String type = 'cycling',
  int? moving,
}) => db
    .into(db.activityRecords)
    .insert(
      ActivityRecordsCompanion.insert(
        activityId: id,
        name: id,
        type: type,
        startDate: atMin(startMin),
        durationSeconds: minutes * 60,
        source: Value(source),
        movingDurationSeconds: Value(moving == null ? null : moving * 60),
      ),
    );

/// A stored spot reading whose sampling starts [startMin] minutes after
/// [base]. Returns its uid.
Future<String> addReading(
  AppDatabase db,
  int startMin,
  SpotHrvContext context, {
  double rmssd = 50,
  SpotHrvPosture posture = SpotHrvPosture.seated,
  int seconds = 300,
  String quality = 'usable',
  String uid = '',
}) async {
  final id = uid.isEmpty ? const Uuid().v4() : uid;
  final start = atMin(startMin);
  await db
      .into(db.spotHrvMeasurements)
      .insert(
        SpotHrvMeasurementsCompanion.insert(
          startedAt: start,
          context: context.name,
          posture: posture.name,
          durationSeconds: seconds,
          settleSeconds: 60,
          deviceId: 'h10',
          deviceName: 'Polar H10',
          rmssdMs: rmssd,
          sdnnMs: 60,
          meanHr: 60,
          acceptedIntervals: 290,
          totalIntervals: 295,
          coverage: .97,
          rrJson: '[]',
          measurementUid: Value(id),
          samplingEndedAt: Value(start.add(Duration(seconds: seconds))),
          qualityState: Value(quality),
        ),
      );
  return id;
}
