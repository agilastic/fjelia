import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../db/database.dart';
import '../theme/activity_colors.dart';
import 'dfa_alpha1_service.dart';
import 'fit_activity_data.dart';
import 'gpx_parser.dart';
import 'hr_zone_model.dart';
import 'tcx_parser.dart';

/// Source of activities the athlete imported from a FIT, GPX or TCX file.
const activityFileSource = 'file';

/// File extensions Fjelia opens as activities.
const activityFileExtensions = ['fit', 'gpx', 'tcx'];

/// A workout read from a file, before it is stored.
class ActivityFile {
  const ActivityFile({
    required this.format,
    required this.activityId,
    required this.type,
    required this.name,
    required this.start,
    required this.durationSeconds,
    this.distanceMeters,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgWatts,
    this.ascentMeters,
    this.movingSeconds,
    this.samples = const [],
    this.route = const [],
    this.rrIntervals = const [],
  });

  /// 'FIT', 'GPX' or 'TCX'.
  final String format;
  final String activityId, type, name;
  final DateTime start;
  final int durationSeconds;
  final double? distanceMeters, avgHeartRate, maxHeartRate, avgWatts;
  final double? ascentMeters;
  final int? movingSeconds;
  final List<Map<String, num>> samples;
  final List<Map<String, double>> route;

  /// Beat-to-beat intervals (ms) of a FIT file, for DFA alpha1.
  final List<double> rrIntervals;
}

/// What importing [file] would do.
class ActivityFilePreview {
  const ActivityFilePreview({
    required this.fileName,
    this.file,
    this.alreadyImported = false,
    this.duplicateSource,
  });

  final String fileName;

  /// Null when the file is not a readable activity.
  final ActivityFile? file;

  /// The same file was imported before.
  final bool alreadyImported;

  /// A watch platform already holds this workout (e.g. 'garmin_api'). Apple
  /// Health copies don't count: the file replaces them.
  final String? duplicateSource;

  bool get canImport =>
      file != null && !alreadyImported && duplicateSource == null;
}

/// The activity files in a ZIP (Garmin Connect's "Export Original", or
/// several files zipped together). Empty when [bytes] is not a ZIP.
List<({String name, Uint8List bytes})> activityFilesInZip(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) return const [];
  try {
    return [
      for (final entry in ZipDecoder().decodeBytes(bytes))
        if (entry.isFile &&
            activityFileExtensions.contains(
              entry.name.split('.').last.toLowerCase(),
            ))
          (
            name: entry.name.split('/').last,
            bytes: Uint8List.fromList(entry.content as List<int>),
          ),
    ];
  } catch (_) {
    return const [];
  }
}

/// Reads [bytes] as a FIT, GPX or TCX activity; the content decides the
/// format, not the file name. Null when it is none of them or has no time.
ActivityFile? decodeActivityFile(Uint8List bytes) {
  final id = 'file_${sha1.convert(bytes).toString().substring(0, 20)}';
  final fit = parseFitActivity(bytes);
  if (fit != null) return _fromFit(id, fit);
  final String xml;
  try {
    xml = utf8.decode(bytes, allowMalformed: true);
  } catch (_) {
    return null;
  }
  final head = xml.length > 2000 ? xml.substring(0, 2000) : xml;
  if (head.contains('TrainingCenterDatabase')) {
    final tcx = parseTcx(xml, source: activityFileSource);
    return tcx == null ? null : _fromTcx(id, tcx);
  }
  if (head.contains('<gpx')) {
    final gpx = parseGpx(xml);
    return gpx == null ? null : _fromGpx(id, gpx);
  }
  return null;
}

ActivityFile? _fromFit(String id, FitActivityData fit) {
  final samples = fit.samples;
  final start =
      fit.start ??
      (samples.isEmpty
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              samples.first['t']!.toInt(),
              isUtc: true,
            ));
  final span = samples.length < 2
      ? 0.0
      : (samples.last['t']! - samples.first['t']!) / 1000;
  final seconds = (fit.timerSeconds ?? span).round();
  if (start == null || seconds <= 0) return null;
  final type = activityFileType(fit.sport);
  return ActivityFile(
    format: 'FIT',
    activityId: id,
    type: type,
    name: _defaultName(type),
    start: start,
    durationSeconds: seconds,
    distanceMeters: fit.distanceMeters,
    avgHeartRate: fit.avgHeartRate,
    maxHeartRate: fit.maxHeartRate,
    avgWatts: fit.avgPower,
    ascentMeters: fit.ascentMeters,
    movingSeconds:
        fit.movingSeconds != null && fit.movingSeconds! <= seconds + 1
        ? fit.movingSeconds!.round()
        : null,
    samples: samples,
    route: fit.route,
    rrIntervals: fit.rrIntervals,
  );
}

ActivityFile? _fromTcx(String id, TcxSession tcx) {
  if (tcx.durationSeconds <= 0) return null;
  final type = activityFileType(tcx.sport);
  final watts = [
    for (final s in tcx.samples)
      if (s['w'] != null) s['w']!.toDouble(),
  ];
  return ActivityFile(
    format: 'TCX',
    activityId: id,
    type: type,
    name: _defaultName(type),
    start: tcx.start.toUtc(),
    durationSeconds: tcx.durationSeconds,
    distanceMeters: tcx.distanceMeters,
    avgHeartRate: tcx.avgHeartRate,
    maxHeartRate: tcx.maxHeartRate,
    avgWatts: watts.isEmpty
        ? null
        : watts.reduce((a, b) => a + b) / watts.length,
    samples: tcx.samples,
    route: tcx.route,
  );
}

ActivityFile? _fromGpx(String id, GpxTrack gpx) {
  final type = activityFileType(gpx.type);
  final hr = [
    for (final s in gpx.samples)
      if (s['hr'] != null) s['hr']!.toDouble(),
  ];
  final watts = [
    for (final s in gpx.samples)
      if (s['w'] != null) s['w']!.toDouble(),
  ];
  return ActivityFile(
    format: 'GPX',
    activityId: id,
    type: type,
    name: gpx.name ?? _defaultName(type),
    start: gpx.start,
    durationSeconds: gpx.durationSeconds,
    distanceMeters: gpx.distanceMeters,
    avgHeartRate: hr.isEmpty ? null : hr.reduce((a, b) => a + b) / hr.length,
    maxHeartRate: hr.isEmpty ? null : hr.reduce((a, b) => a > b ? a : b),
    avgWatts: watts.isEmpty
        ? null
        : watts.reduce((a, b) => a + b) / watts.length,
    ascentMeters: gpx.ascentMeters,
    samples: gpx.samples,
    route: gpx.route,
  );
}

/// The stored activity type for a sport named in a file ("Biking", "Run",
/// "cycling", Strava's "Ride"); unknown sports are 'other'.
String activityFileType(String? sport) {
  if (sport == null || sport.trim().isEmpty) return 'other';
  if (sport.toLowerCase() == 'skiing') return 'skiing';
  if (sport.toLowerCase().contains('ride')) {
    return 'cycling';
  }
  final kind = activityKind(sport);
  return kind == ActivityKind.other ? 'other' : kind.name;
}

/// Stored names stay English like those from the other sources.
String _defaultName(String type) => switch (type) {
  'other' => 'Imported activity',
  _ => '${type[0].toUpperCase()}${type.substring(1)} (file)',
};

/// Imports activities from files the athlete opened in Fjelia.
class ActivityFileImportService {
  ActivityFileImportService(this._db);

  final AppDatabase _db;

  /// Reads the file and checks it against what is stored.
  Future<ActivityFilePreview> preview(String fileName, Uint8List bytes) async {
    final file = decodeActivityFile(bytes);
    if (file == null) return ActivityFilePreview(fileName: fileName);
    if (await _db.getActivityById(file.activityId) != null) {
      return ActivityFilePreview(
        fileName: fileName,
        file: file,
        alreadyImported: true,
      );
    }
    final duplicate = (await _nearby(file)).where(
      (a) =>
          a.source != 'health_connect' &&
          isSameWorkout(
            a.startDate,
            a.durationSeconds,
            a.type,
            file.start,
            file.durationSeconds,
            file.type,
          ),
    );
    return ActivityFilePreview(
      fileName: fileName,
      file: file,
      duplicateSource: duplicate.isEmpty
          ? null
          : duplicate.first.source ?? 'unknown',
    );
  }

  Future<List<ActivityRecord>> _nearby(ActivityFile file) =>
      (_db.select(_db.activityRecords)..where(
            (t) => t.startDate.isBetweenValues(
              file.start.subtract(const Duration(hours: 1)),
              file.start.add(const Duration(hours: 1)),
            ),
          ))
          .get();

  /// Stores the activity of [preview] with time in zone from its heart
  /// rate. An Apple Health copy of the same workout is removed afterwards.
  Future<bool> import(
    ActivityFilePreview preview, {
    required List<int> runningZones,
    required List<int> cyclingZones,
  }) async {
    final file = preview.file;
    if (file == null || !preview.canImport) return false;
    final metrics = file.samples.isEmpty ? null : jsonEncode(file.samples);
    final type = file.type;
    final cyclingLike = activityKind(type) == ActivityKind.cycling;
    final zones = type == 'swimming'
        ? null
        : zonePercentFromSamples(
            metrics,
            cyclingLike ? cyclingZones : runningZones,
          );
    await _db
        .into(_db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: file.activityId,
            name: file.name,
            type: type,
            startDate: file.start,
            durationSeconds: file.durationSeconds,
            distanceMeters: Value(file.distanceMeters),
            avgHeartRate: Value(file.avgHeartRate),
            maxHeartRate: Value(file.maxHeartRate),
            avgWatts: Value(file.avgWatts),
            totalElevation: Value(file.ascentMeters),
            hrZonesJson: Value(zones == null ? null : jsonEncode(zones)),
            gpxJson: Value(file.route.isEmpty ? null : jsonEncode(file.route)),
            metricsJson: Value(metrics),
            source: const Value(activityFileSource),
            movingDurationSeconds: Value(file.movingSeconds),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    if (file.rrIntervals.isNotEmpty) {
      await DfaAlpha1Service(_db).save(
        file.activityId,
        start: file.start,
        rrIntervals: file.rrIntervals,
        samples: file.samples,
      );
    }
    await _db.deduplicateActivities();
    return true;
  }
}
