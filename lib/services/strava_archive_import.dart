import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../db/database.dart';
import '../utils/log.dart';
import 'activity_file_import_service.dart';
import 'dfa_alpha1_service.dart';
import 'hr_zone_model.dart';
import 'media_service.dart';
import '../theme/activity_colors.dart';

/// Source of activities imported from a Strava account archive.
const stravaSource = 'strava';

/// One row of `activities.csv` in a Strava account export ("Download your
/// account"). Strava names the columns in the account's language, so they
/// are read by position: the layout is the same in every language, and the
/// second block (from column 15) holds the values in seconds, metres and
/// m/s. Values Strava left empty stay null.
class StravaActivityRow {
  const StravaActivityRow({
    required this.stravaId,
    required this.start,
    required this.name,
    required this.typeName,
    this.description = '',
    this.elapsedSeconds,
    this.movingSeconds,
    this.distanceMeters,
    this.elevationGain,
    this.maxHeartRate,
    this.avgHeartRate,
    this.maxWatts,
    this.avgWatts,
    this.calories,
    this.fileName,
    this.media = const [],
  });

  final String stravaId;

  /// UTC, as Strava writes it; null for a broken date (Strava has 1970).
  final DateTime? start;
  final String name, typeName, description;
  final int? elapsedSeconds, movingSeconds;
  final double? distanceMeters, elevationGain;
  final double? maxHeartRate, avgHeartRate, maxWatts, avgWatts, calories;

  /// Path inside the archive, e.g. `activities/123.fit.gz`.
  final String? fileName;

  /// Photo and video paths inside the archive, e.g. `media/ABC.jpg`.
  final List<String> media;

  /// The original Strava ID stays in the Fjelia ID, for traceability and so
  /// a second import finds what the first one stored.
  String get activityId => 'strava_$stravaId';

  /// Fjelia's sport for Strava's type name, in English or German.
  String get type => stravaType(typeName);
}

/// Fjelia's sport name for a Strava activity type (English or German).
String stravaType(String name) {
  final key = name.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß]'), '');
  return switch (key) {
    'virtualride' || 'virtuelleradfahrt' => 'virtual_ride',
    'virtualrun' || 'virtuellerlauf' => 'treadmill_running',
    'trailrun' || 'traillauf' => 'trail_running',
    'run' || 'lauf' => 'running',
    'ride' || 'radfahrt' => 'cycling',
    'mountainbikeride' || 'mountainbikefahrt' => 'mountain_biking',
    'gravelride' || 'gravelfahrt' => 'cycling_gravel',
    'ebikeride' || 'ebikefahrt' => 'e_biking',
    'hike' || 'wandern' => 'hiking',
    'walk' || 'spaziergang' => 'walking',
    'weighttraining' || 'gewichtstraining' => 'strength_training',
    'swim' || 'schwimmen' => 'swimming',
    'rowing' || 'rudern' => 'rowing',
    'yoga' => 'yoga',
    'workout' || 'training' => 'training',
    'inlineskate' || 'inlineskaten' => 'inline_skating',
    'nordicski' || 'skilanglaufen' => 'cross_country_skiing',
    'alpineski' || 'ski' || 'skifahren' => 'skiing',
    'stairstepper' || 'stufenstepper' => 'stair_stepper',
    'windsurf' || 'windsurfen' => 'windsurfing',
    _ => key.isEmpty ? 'other' : key,
  };
}

/// RFC 4180 CSV: quoted fields may hold commas, quotes and line breaks.
List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      row.add(field.toString());
      field.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      if (row.any((f) => f.isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    if (row.any((f) => f.isNotEmpty)) rows.add(row);
  }
  return rows;
}

/// The rows of `activities.csv`; rows without an ID are left out.
List<StravaActivityRow> parseStravaActivities(String csv) {
  final rows = parseCsv(csv.startsWith('﻿') ? csv.substring(1) : csv);
  if (rows.length < 2) return const [];
  final header = rows.first;
  // The media column sits near the end; find it by name, else by position.
  var mediaColumn = header.indexWhere(
    (h) => const {
      'media',
      'medien',
      'médias',
      'medios',
    }.contains(h.trim().toLowerCase()),
  );
  if (mediaColumn < 0 && header.length > 102) mediaColumn = 102;
  String at(List<String> r, int i) => i < r.length ? r[i].trim() : '';
  double? number(List<String> r, int i) {
    final v = at(r, i);
    if (v.isEmpty) return null;
    final n = double.tryParse(v) ?? double.tryParse(v.replaceAll(',', '.'));
    return n == null || !n.isFinite ? null : n;
  }

  double? positive(List<String> r, int i) {
    final n = number(r, i);
    return n == null || n <= 0 ? null : n;
  }

  return [
    for (final r in rows.skip(1))
      if (RegExp(r'^\d+$').hasMatch(at(r, 0)))
        StravaActivityRow(
          stravaId: at(r, 0),
          start: parseStravaDate(at(r, 1)),
          name: at(r, 2),
          typeName: at(r, 3),
          description: at(r, 4),
          // The SI block: seconds, metres, m/s; the display block before it
          // is in the account's units.
          elapsedSeconds: (number(r, 15) ?? number(r, 5))?.round(),
          movingSeconds: number(r, 16)?.round(),
          distanceMeters: number(r, 17),
          elevationGain: positive(r, 20),
          maxHeartRate: positive(r, 30) ?? positive(r, 7),
          avgHeartRate: positive(r, 31),
          maxWatts: positive(r, 32),
          avgWatts: positive(r, 33),
          calories: positive(r, 34),
          fileName: at(r, 12).isEmpty ? null : at(r, 12),
          media: mediaColumn < 0
              ? const []
              : [
                  for (final m in at(r, mediaColumn).split('|'))
                    if (m.trim().isNotEmpty) m.trim(),
                ],
        ),
  ];
}

const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, //
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

/// Strava's activity date, in UTC: `03.11.2026, 17:44:51` (German),
/// `Nov 3, 2026, 5:44:51 PM` (English) or ISO. Null for what it cannot
/// read and for Strava's placeholder 1970.
DateTime? parseStravaDate(String raw) {
  final s = raw.trim();
  DateTime? date;
  final de = RegExp(
    r'^(\d{1,2})\.(\d{1,2})\.(\d{4}),?\s+(\d{1,2}):(\d{2}):(\d{2})$',
  ).firstMatch(s);
  final en = RegExp(
    r'^([A-Za-z]{3})[a-z]*\.? (\d{1,2}), (\d{4}),? (\d{1,2}):(\d{2}):(\d{2})\s*([AP]M)?$',
  ).firstMatch(s);
  if (de != null) {
    final v = [for (var i = 1; i <= 6; i++) int.parse(de[i]!)];
    date = DateTime.utc(v[2], v[1], v[0], v[3], v[4], v[5]);
  } else if (en != null && _months[en[1]!.toLowerCase()] != null) {
    var hour = int.parse(en[4]!);
    if (en[7] == 'PM' && hour < 12) hour += 12;
    if (en[7] == 'AM' && hour == 12) hour = 0;
    date = DateTime.utc(
      int.parse(en[3]!),
      _months[en[1]!.toLowerCase()]!,
      int.parse(en[2]!),
      hour,
      int.parse(en[5]!),
      int.parse(en[6]!),
    );
  } else {
    date = DateTime.tryParse(s)?.toUtc();
  }
  return date == null || date.year < 1990 ? null : date;
}

/// A Strava account ZIP, read from disk entry by entry: the archive (often
/// several hundred MB) is never loaded into memory as a whole.
class StravaArchive {
  StravaArchive._(this._input, this._entries, this._prefix, this.rows);

  final InputFileStream _input;
  final Map<String, ArchiveFile> _entries;

  /// A folder the export was zipped in, e.g. `export_123/`; usually empty.
  final String _prefix;
  final List<StravaActivityRow> rows;

  /// Opens [path]; null when it is not a Strava account export.
  static StravaArchive? open(String path) {
    InputFileStream? input;
    try {
      input = InputFileStream(path);
      final zip = ZipDecoder().decodeStream(input);
      final entries = {
        for (final f in zip.files)
          if (f.isFile) f.name: f,
      };
      final csvName = entries.keys
          .where((n) => n == 'activities.csv' || n.endsWith('/activities.csv'))
          .fold<String?>(
            null,
            (best, n) => best == null || n.length < best.length ? n : best,
          );
      if (csvName == null) {
        input.closeSync();
        return null;
      }
      final prefix = csvName.substring(
        0,
        csvName.length - 'activities.csv'.length,
      );
      final csv = utf8.decode(
        entries[csvName]!.content as List<int>,
        allowMalformed: true,
      );
      return StravaArchive._(
        input,
        entries,
        prefix,
        parseStravaActivities(csv),
      );
    } catch (e) {
      log('[Strava] not a readable archive: $e');
      input?.closeSync();
      return null;
    }
  }

  ArchiveFile? _entry(String path) => _entries['$_prefix$path'];

  bool has(String path) => _entry(path) != null;

  /// The uncompressed size of [path], 0 when it is missing.
  int size(String path) => _entry(path)?.size ?? 0;

  /// The bytes of [path]; null when it is missing or unreadable.
  Uint8List? read(String path) {
    final entry = _entry(path);
    if (entry == null) return null;
    try {
      final bytes = Uint8List.fromList(entry.content as List<int>);
      entry.clear();
      return bytes;
    } catch (e) {
      log('[Strava] $path unreadable: $e');
      return null;
    }
  }

  /// Writes [path] to [target] without holding it in memory.
  bool extractTo(String path, String target) {
    final entry = _entry(path);
    if (entry == null) return false;
    try {
      final out = OutputFileStream(target);
      entry.writeContent(out);
      out.closeSync();
      entry.clear();
      return true;
    } catch (e) {
      log('[Strava] $path not extracted: $e');
      return false;
    }
  }

  void close() => _input.closeSync();
}

/// What an import of the archive would do.
class StravaPreview {
  const StravaPreview({
    required this.activities,
    required this.withFile,
    required this.photos,
    required this.videos,
    required this.alreadyImported,
    required this.duplicates,
    required this.deleted,
    required this.storageBytes,
  });

  final int activities, withFile, photos, videos;
  final int alreadyImported, duplicates, deleted;

  /// Roughly what the photos and videos take on the device.
  final int storageBytes;

  int get toImport => activities - alreadyImported - duplicates - deleted;
}

/// How far an import is, and in the end what it did.
class StravaImportProgress {
  int processed = 0, total = 0;
  int imported = 0, alreadyImported = 0, duplicates = 0, deleted = 0;
  int photos = 0, failed = 0;
  bool done = false, cancelled = false;

  /// One line per activity that failed: its date, name and the reason.
  final errors = <String>[];

  bool get complete => done && !cancelled && failed == 0;
}

/// Where an archive row stands against what Fjelia already holds.
enum _Match { none, imported, duplicate, deleted }

/// Imports a Strava account archive: activities with their files (FIT, GPX
/// or TCX, gzipped or not) and their photos, next to what other sources
/// already brought. Nothing leaves the device.
class StravaArchiveImporter {
  StravaArchiveImporter(
    this._db,
    this._media, {
    this.runningZones = const [],
    this.cyclingZones = const [],
  });

  final AppDatabase _db;
  final MediaService _media;
  final List<int> runningZones, cyclingZones;

  late List<ActivityRecord> _known;
  late Map<String, ActivityRecord> _byId;
  late List<DeletedActivity> _deleted;
  late Set<String> _deletedIds;

  /// Which activity each archive file went to in this run: a second row
  /// with the same file is the same recording.
  final _fileOwner = <String, String>{};

  Future<void> _load() async {
    _known = await (_db.select(
      _db.activityRecords,
    )..orderBy([(t) => OrderingTerm(expression: t.startDate)])).get();
    _byId = {for (final a in _known) a.activityId: a};
    _fileOwner.clear();
    _deleted = await _db.getDeletedActivities();
    _deletedIds = {for (final d in _deleted) d.activityId};
  }

  /// The activity already holding this workout, from Strava or any other
  /// source, matched conservatively by time, duration and sport. An Apple
  /// Health copy does not count: the Strava recording is richer, and the
  /// Health copy goes when duplicates are merged.
  ActivityRecord? _existing(StravaActivityRow r, DateTime start, int seconds) {
    final same = _byId[r.activityId];
    if (same != null) return same;
    for (final a in _near(start)) {
      if (a.source == 'health_connect') continue;
      if (isSameWorkout(
        a.startDate,
        a.durationSeconds,
        a.type,
        start,
        seconds,
        r.type,
      )) {
        return a;
      }
    }
    return null;
  }

  Iterable<ActivityRecord> _near(DateTime start) =>
      _known.where((a) => a.startDate.difference(start).inMinutes.abs() <= 10);

  /// Deleted in Fjelia before: the Strava copy itself, or the same workout
  /// from another source.
  bool _wasDeleted(StravaActivityRow r, DateTime start, int seconds) =>
      _deletedIds.contains(r.activityId) ||
      _deleted.any(
        (d) => isSameWorkout(
          d.startDate,
          d.durationSeconds,
          d.type,
          start,
          seconds,
          r.type,
        ),
      );

  _Match _match(StravaActivityRow r) {
    final start = r.start;
    final seconds = r.elapsedSeconds ?? 0;
    if (_deletedIds.contains(r.activityId)) return _Match.deleted;
    if (start == null || seconds <= 0) {
      return _byId.containsKey(r.activityId) ? _Match.imported : _Match.none;
    }
    if (_wasDeleted(r, start, seconds)) return _Match.deleted;
    final existing = _existing(r, start, seconds);
    if (existing == null) return _Match.none;
    return existing.activityId == r.activityId
        ? _Match.imported
        : _Match.duplicate;
  }

  /// Whether an earlier row of the archive is the same workout.
  static bool _inArchive(StravaActivityRow r, List<StravaActivityRow> earlier) {
    final start = r.start, seconds = r.elapsedSeconds ?? 0;
    for (final e in earlier.reversed.take(400)) {
      if (r.fileName != null && e.fileName == r.fileName) return true;
      final s = e.start, es = e.elapsedSeconds ?? 0;
      if (start == null || s == null || seconds <= 0 || es <= 0) continue;
      if (isSameWorkout(s, es, e.type, start, seconds, r.type)) return true;
    }
    return false;
  }

  Future<StravaPreview> preview(StravaArchive archive) async {
    await _load();
    var withFile = 0, photos = 0, videos = 0, imported = 0, dupes = 0;
    var deleted = 0, bytes = 0;
    final accepted = <StravaActivityRow>[];
    for (final r in archive.rows) {
      if (r.fileName != null && archive.has(r.fileName!)) withFile++;
      for (final m in r.media) {
        if (!archive.has(m)) continue;
        isVideoPath(m) ? videos++ : photos++;
        bytes += archive.size(m);
      }
      var match = _match(r);
      // Strava itself may hold a workout twice (uploaded from two devices):
      // the second copy counts as a duplicate here too, as in the import.
      if (match == _Match.none && _inArchive(r, accepted)) {
        match = _Match.duplicate;
      }
      switch (match) {
        case _Match.imported:
          imported++;
        case _Match.duplicate:
          dupes++;
        case _Match.deleted:
          deleted++;
        case _Match.none:
          accepted.add(r);
      }
    }
    return StravaPreview(
      activities: archive.rows.length,
      withFile: withFile,
      photos: photos,
      videos: videos,
      alreadyImported: imported,
      duplicates: dupes,
      deleted: deleted,
      storageBytes: bytes,
    );
  }

  /// Imports every row. Safe to run again: what is stored is found by its
  /// Strava ID or as the same workout, and photos by their path in the
  /// archive. A row that fails is reported and the rest go on.
  Future<StravaImportProgress> run(
    StravaArchive archive, {
    void Function(StravaImportProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    await _load();
    final progress = StravaImportProgress()..total = archive.rows.length;
    final storedPhotos = await _media.sourceRefs('strava:');
    final temp = await Directory.systemTemp.createTemp('strava_import');
    try {
      for (final r in archive.rows) {
        if (isCancelled?.call() ?? false) {
          progress.cancelled = true;
          break;
        }
        try {
          await _importRow(archive, r, progress, storedPhotos, temp);
        } catch (e) {
          progress.failed++;
          progress.errors.add(_errorLine(r, '$e'));
          log('[Strava] ${r.stravaId} failed: $e');
        }
        progress.processed++;
        onProgress?.call(progress);
        // Let the UI draw between activities.
        await Future<void>.delayed(Duration.zero);
      }
      await _db.deduplicateActivities();
    } finally {
      try {
        await temp.delete(recursive: true);
      } catch (_) {}
    }
    progress.done = true;
    onProgress?.call(progress);
    return progress;
  }

  String _errorLine(StravaActivityRow r, String reason) {
    final d = r.start;
    final day = d == null
        ? '?'
        : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '$day · ${r.name.isEmpty ? r.stravaId : r.name} · '
        '${reason.replaceFirst('Exception: ', '')}';
  }

  Future<void> _importRow(
    StravaArchive archive,
    StravaActivityRow r,
    StravaImportProgress progress,
    Set<String> storedPhotos,
    Directory temp,
  ) async {
    var start = r.start;
    var seconds = r.elapsedSeconds ?? 0;
    if (_deletedIds.contains(r.activityId) ||
        (start != null && seconds > 0 && _wasDeleted(r, start, seconds))) {
      progress.deleted++;
      return;
    }
    var existing = start == null || seconds <= 0
        ? _byId[r.activityId]
        : _existing(r, start, seconds);
    if (existing == null && r.fileName != null) {
      final owner = _fileOwner[r.fileName];
      existing = owner == null ? null : _byId[owner];
    }
    if (existing != null) {
      if (r.fileName != null) _fileOwner[r.fileName!] = existing.activityId;
      existing.activityId == r.activityId
          ? progress.alreadyImported++
          : progress.duplicates++;
      // The workout is there already: only its photos may be missing.
      await _addPhotos(
        archive,
        r,
        existing.activityId,
        progress,
        storedPhotos,
        temp,
      );
      return;
    }

    // The recording, gzipped or not, read off the UI isolate.
    ActivityFile? file;
    final name = r.fileName;
    if (name != null) {
      final bytes = archive.read(name);
      if (bytes == null) throw Exception('activity file missing in archive');
      file = await Isolate.run(() {
        final raw = name.toLowerCase().endsWith('.gz')
            ? Uint8List.fromList(const GZipDecoder().decodeBytes(bytes))
            : bytes;
        return decodeActivityFile(raw);
      });
      if (file == null) throw Exception('activity file not readable');
    }
    start ??= file?.start;
    if (seconds <= 0) seconds = file?.durationSeconds ?? 0;
    if (start == null || seconds <= 0) {
      throw Exception('no start time or duration');
    }
    // The broken-date rows only now have a time: check them again.
    if (r.start == null) {
      if (_wasDeleted(r, start, seconds)) {
        progress.deleted++;
        return;
      }
      existing = _existing(r, start, seconds);
      if (existing != null) {
        progress.duplicates++;
        await _addPhotos(
          archive,
          r,
          existing.activityId,
          progress,
          storedPhotos,
          temp,
        );
        return;
      }
    }

    final type = r.type == 'other' && file != null ? file.type : r.type;
    final metrics = file == null || file.samples.isEmpty
        ? null
        : jsonEncode(file.samples);
    final zones = metrics == null || type == 'swimming'
        ? null
        : zonePercentFromSamples(
            metrics,
            activityKind(type) == ActivityKind.cycling
                ? cyclingZones
                : runningZones,
          );
    final moving = r.movingSeconds ?? file?.movingSeconds;
    await _db
        .into(_db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: r.activityId,
            name: r.name.isEmpty ? 'Strava activity' : r.name,
            type: type,
            // The file's own start is to the second; the CSV may be off by
            // the time zone of an old export.
            startDate: file?.start ?? start,
            durationSeconds: seconds,
            distanceMeters: Value(r.distanceMeters ?? file?.distanceMeters),
            avgHeartRate: Value(r.avgHeartRate ?? file?.avgHeartRate),
            maxHeartRate: Value(r.maxHeartRate ?? file?.maxHeartRate),
            avgWatts: Value(r.avgWatts ?? file?.avgWatts),
            totalElevation: Value(r.elevationGain ?? file?.ascentMeters),
            hrZonesJson: Value(zones == null ? null : jsonEncode(zones)),
            gpxJson: Value(
              file == null || file.route.isEmpty
                  ? null
                  : jsonEncode(file.route),
            ),
            metricsJson: Value(metrics),
            movingDurationSeconds: Value(
              moving != null && moving > 0 && moving <= seconds + 1
                  ? moving
                  : null,
            ),
            source: const Value(stravaSource),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final stored = await _db.getActivityById(r.activityId);
    if (stored == null) throw Exception('not stored');
    _known.add(stored);
    _byId[stored.activityId] = stored;
    if (name != null) _fileOwner[name] = stored.activityId;
    progress.imported++;
    if (file != null && file.rrIntervals.isNotEmpty) {
      try {
        await DfaAlpha1Service(_db).save(
          r.activityId,
          start: file.start,
          rrIntervals: file.rrIntervals,
          samples: file.samples,
        );
      } catch (_) {}
    }
    await _addPhotos(archive, r, r.activityId, progress, storedPhotos, temp);
  }

  /// The row's photos and videos for [activityId], each once: the archive
  /// names them in the activity's own row, so none is matched by time.
  Future<void> _addPhotos(
    StravaArchive archive,
    StravaActivityRow r,
    String activityId,
    StravaImportProgress progress,
    Set<String> stored,
    Directory temp,
  ) async {
    for (final m in r.media) {
      final ref = 'strava:$m';
      if (stored.contains(ref) || !archive.has(m)) continue;
      final target = p.join(temp.path, p.basename(m));
      if (!archive.extractTo(m, target)) continue;
      try {
        final added = await _media.add(
          MediaOwner.activity(activityId),
          [target],
          sourceRefs: [ref],
        );
        if (added > 0) {
          stored.add(ref);
          progress.photos++;
        }
      } finally {
        try {
          await File(target).delete();
        } catch (_) {}
      }
    }
  }
}
