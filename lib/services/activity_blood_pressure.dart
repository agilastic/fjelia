import '../db/database.dart';
import '../models/indoor_recording.dart';

/// Existing observations only, within the actual active portions of a
/// recording. A paused interval is not reconstructed from its timer total.
bool bloodPressureDuringActivity(IndoorCapture capture, BpMeasurement reading) {
  if (!capture.includeBloodPressure || capture.samples.isEmpty) return false;
  final at = reading.measuredAt.toUtc();
  final end = DateTime.fromMillisecondsSinceEpoch(
    capture.samples.last['t']!.round(),
    isUtc: true,
  );
  if (at.isBefore(capture.startedAt) || at.isAfter(end)) return false;
  var paused = false;
  for (final event in capture.events) {
    if (event['at'] is! String) continue;
    final boundary = DateTime.tryParse(event['at'] as String);
    if (boundary == null || boundary.isAfter(at)) continue;
    if (event['type'] == 'pause') paused = true;
    if (event['type'] == 'resume' || event['type'] == 'start') paused = false;
  }
  return !paused;
}
