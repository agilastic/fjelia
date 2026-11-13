import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../models/ecg.dart';
import '../models/ecg_sleep_staging.dart';
import 'pdf_text_extractor.dart';
import 'source_priority_service.dart' show SourceGroup, priorityForGroup;

class EcgImport {
  const EcgImport({
    required this.kind,
    required this.chunks,
    this.sampleRateHz,
    this.recordedAt,
    this.source,
    this.deviceName,
  });
  final String kind;
  final List<EcgChunk> chunks;
  final double? sampleRateHz;
  final DateTime? recordedAt;
  final String? source, deviceName;
  int get sampleCount => chunks.fold(0, (n, c) => n + c.microvolts.length);
  int get durationMs => chunks.isEmpty
      ? 0
      : ((chunks.last.offsetUs / 1e6 +
                    chunks.last.microvolts.length / sampleRateHz!) *
                1000)
            .round();
}

/// Only explicit units and a time axis are accepted. PDF reports never become
/// waveforms; CSV values never acquire a medical interpretation.
EcgImport decodeEcgImport(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 20 * 1024 * 1024) {
    throw const FormatException('Choose an ECG CSV or PDF smaller than 20 MB.');
  }
  if (bytes.length >= 5 &&
      ascii.decode(bytes.sublist(0, 5), allowInvalid: true) == '%PDF-') {
    return const EcgImport(kind: 'report', chunks: []);
  }
  final lines = const LineSplitter().convert(
    utf8.decode(bytes).replaceFirst('\ufeff', ''),
  );
  Map<String, dynamic> meta = {};
  var headerIndex = 0;
  while (headerIndex < lines.length &&
      (lines[headerIndex].startsWith('#') ||
          lines[headerIndex].trim().isEmpty)) {
    final line = lines[headerIndex++];
    if (line.startsWith('# fjelia-ecg-v1 ')) {
      meta =
          jsonDecode(line.substring('# fjelia-ecg-v1 '.length))
              as Map<String, dynamic>;
    }
  }
  if (headerIndex >= lines.length) {
    throw const FormatException('The ECG file is empty.');
  }
  final header = lines[headerIndex++].trim().toLowerCase().split(',');
  final timeIndex = header.indexWhere(
    (s) => s == 'time_seconds' || s == 'time_ms',
  );
  final uvIndex = header.indexWhere((s) => s == 'ecg_uv' || s == 'ecg_mv');
  final deviceIndex = header.indexOf('device_frame_end_ns');
  if (timeIndex < 0 || uvIndex < 0) {
    throw const FormatException(
      'CSV requires time_seconds (or time_ms) and ecg_uv (or ecg_mv) columns. Garmin and Apple PDF exports can be kept as reports.',
    );
  }
  final times = <double>[], voltages = <num>[], deviceTimes = <int?>[];
  for (var i = headerIndex; i < lines.length; i++) {
    if (lines[i].trim().isEmpty) continue;
    final row = lines[i].split(',');
    if (row.length != header.length) {
      throw FormatException('Invalid ECG CSV row ${i + 1}.');
    }
    final time = double.tryParse(row[timeIndex]),
        voltage = num.tryParse(row[uvIndex]);
    if (time == null ||
        !time.isFinite ||
        time < 0 ||
        voltage == null ||
        !voltage.isFinite ||
        voltage.abs() > 1e9) {
      throw FormatException('Invalid ECG sample on row ${i + 1}.');
    }
    final seconds = time / (header[timeIndex] == 'time_ms' ? 1000 : 1);
    if (times.isNotEmpty && seconds <= times.last) {
      throw const FormatException('ECG sample times must increase.');
    }
    times.add(seconds);
    voltages.add(header[uvIndex] == 'ecg_mv' ? voltage * 1000 : voltage);
    deviceTimes.add(deviceIndex >= 0 ? int.tryParse(row[deviceIndex]) : null);
    if (times.length > 1000000) {
      throw const FormatException('The ECG file contains too many samples.');
    }
  }
  if (times.length < 2) {
    throw const FormatException('At least two ECG samples are required.');
  }
  final differences = [
    for (var i = 1; i < math.min(times.length, 1001); i++)
      times[i] - times[i - 1],
  ]..sort();
  final reportedRate = meta['sample_rate_hz'];
  final rate = reportedRate is num
      ? reportedRate.toDouble()
      : 1 / differences[differences.length ~/ 2];
  if (!rate.isFinite || rate < 1 || rate > 4000) {
    throw const FormatException('The ECG sampling frequency is unsupported.');
  }
  final chunks = <EcgChunk>[];
  var begin = 0;
  void addChunk(int end) {
    chunks.add(
      EcgChunk(
        offsetUs: ((times[begin] - times.first) * 1e6).round(),
        microvolts: voltages.sublist(begin, end),
        deviceLastSampleNs: deviceTimes[begin],
      ),
    );
    begin = end;
  }

  for (var i = 1; i < times.length; i++) {
    final delta = times[i] - times[i - 1];
    if (delta < .75 / rate) {
      throw const FormatException(
        'ECG timing disagrees with its sampling frequency.',
      );
    }
    if (delta > 1.25 / rate ||
        deviceTimes[i] != deviceTimes[begin] ||
        i - begin >= 1000) {
      addChunk(i);
    }
  }
  addChunk(times.length);
  return EcgImport(
    kind: 'waveform',
    chunks: chunks,
    sampleRateHz: rate,
    recordedAt: DateTime.tryParse('${meta['recorded_at']}'),
    source: meta['source'] as String?,
    deviceName: meta['device_name'] as String?,
  );
}

class EcgStorageService {
  EcgStorageService(this.db);
  final AppDatabase db;

  Future<EcgRecording?> recording(String id) => (db.select(
    db.ecgRecordings,
  )..where((t) => t.recordingId.equals(id))).getSingleOrNull();

  Stream<List<EcgRecording>> watchHistory() => (db.select(
    db.ecgRecordings,
  )..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])).watch();

  /// All recordings, newest first, read once.
  Future<List<EcgRecording>> history() => (db.select(
    db.ecgRecordings,
  )..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])).get();

  Future<void> recoverInterrupted() =>
      (db.update(db.ecgRecordings)..where((t) => t.status.equals('recording')))
          .write(const EcgRecordingsCompanion(status: Value('interrupted')));

  Future<String> begin({
    required String deviceId,
    required String deviceName,
    required double rate,
    required int resolution,
    double? accelerationRate,
    String purpose = 'ecg',
    String? activityId,
  }) async {
    final id = const Uuid().v4();
    await db
        .into(db.ecgRecordings)
        .insert(
          EcgRecordingsCompanion.insert(
            recordingId: id,
            recordedAt: DateTime.now().toUtc(),
            source: 'polar_h10',
            deviceId: Value(deviceId),
            deviceName: deviceName,
            kind: 'waveform',
            status: 'recording',
            sampleRateHz: Value(rate),
            activityId: Value(activityId),
            metadataJson: Value(
              jsonEncode({
                'units': 'uV',
                'resolution_bits': resolution,
                'protocol': 'Polar PMD ECG type 0',
                'time_basis':
                    'device_relative; phone recording start is approximate',
                'device_epoch': '2000-01-01; not assumed synchronized',
                'analysis': 'none',
                'capture_purpose': purpose,
                'accelerometer_sample_rate_hz': ?accelerationRate,
              }),
            ),
          ),
        );
    return id;
  }

  Future<void> append(
    String id,
    List<EcgChunk> chunks,
    int sequence, {
    List<AccelerationChunk> acceleration = const [],
    required int count,
    required int durationMs,
    required int gaps,
  }) => db.transaction(() async {
    await db.batch(
      (batch) => batch.insertAll(db.ecgSampleChunks, [
        for (var i = 0; i < chunks.length; i++)
          EcgSampleChunksCompanion.insert(
            recordingId: id,
            sequence: sequence + i,
            dataJson: jsonEncode(chunks[i].toJson()),
          ),
        for (var i = 0; i < acceleration.length; i++)
          EcgSampleChunksCompanion.insert(
            recordingId: id,
            sequence: sequence + chunks.length + i,
            dataJson: jsonEncode(acceleration[i].toJson()),
          ),
      ]),
    );
    final row = await (db.select(
      db.ecgRecordings,
    )..where((t) => t.recordingId.equals(id))).getSingle();
    final meta = jsonDecode(row.metadataJson) as Map<String, dynamic>;
    meta['gap_count'] = gaps;
    meta['coverage'] = durationMs > 0
        ? math.min(1, count / (durationMs / 1000 * row.sampleRateHz!))
        : 0;
    await (db.update(
      db.ecgRecordings,
    )..where((t) => t.recordingId.equals(id))).write(
      EcgRecordingsCompanion(
        sampleCount: Value(count),
        durationMs: Value(durationMs),
        metadataJson: Value(jsonEncode(meta)),
      ),
    );
  });

  Future<void> finish(String id, {required bool interrupted}) async {
    await (db.update(
      db.ecgRecordings,
    )..where((t) => t.recordingId.equals(id))).write(
      EcgRecordingsCompanion(
        status: Value(interrupted ? 'interrupted' : 'complete'),
      ),
    );
  }

  Future<List<EcgChunk>> chunks(String id) async => [
    for (final c
        in await (db.select(db.ecgSampleChunks)
              ..where((t) => t.recordingId.equals(id))
              ..orderBy([(t) => OrderingTerm(expression: t.sequence)]))
            .get())
      if ((jsonDecode(c.dataJson) as Map<String, dynamic>)['stream'] != 'acc')
        EcgChunk.fromJson(jsonDecode(c.dataJson) as Map<String, dynamic>),
  ];

  Future<List<AccelerationChunk>> accelerationChunks(String id) async => [
    for (final c
        in await (db.select(db.ecgSampleChunks)
              ..where((t) => t.recordingId.equals(id))
              ..orderBy([(t) => OrderingTerm(expression: t.sequence)]))
            .get())
      if ((jsonDecode(c.dataJson) as Map<String, dynamic>)['stream'] == 'acc')
        AccelerationChunk.fromJson(
          jsonDecode(c.dataJson) as Map<String, dynamic>,
        ),
  ];

  Future<String> import(
    String name,
    Uint8List bytes, {
    required DateTime at,
    required String source,
    String? activityId,
  }) async {
    final hash = sha256.convert(bytes).toString();
    final existing = await (db.select(
      db.ecgRecordings,
    )..where((t) => t.contentHash.equals(hash))).getSingleOrNull();
    if (existing != null) return existing.recordingId;
    final parsed = decodeEcgImport(bytes);
    final id = const Uuid().v4();
    return db.transaction(() async {
      await db
          .into(db.ecgRecordings)
          .insert(
            EcgRecordingsCompanion.insert(
              recordingId: id,
              recordedAt: parsed.recordedAt ?? at.toUtc(),
              source: parsed.source ?? source,
              deviceName: parsed.deviceName ?? source,
              kind: parsed.kind,
              status: 'complete',
              sampleRateHz: Value(parsed.sampleRateHz),
              sampleCount: Value(parsed.sampleCount),
              durationMs: Value(parsed.durationMs),
              activityId: Value(activityId),
              contentHash: Value(hash),
              originalFileName: Value(p.basename(name)),
              originalBase64: Value(base64Encode(bytes)),
              metadataJson: Value(
                jsonEncode({
                  'units': parsed.kind == 'waveform' ? 'uV' : null,
                  'analysis': 'none',
                  'imported_at': DateTime.now().toUtc().toIso8601String(),
                  'time_basis':
                      'imported sample offsets; original document preserved',
                }),
              ),
            ),
          );
      await db.batch(
        (b) => b.insertAll(db.ecgSampleChunks, [
          for (var i = 0; i < parsed.chunks.length; i++)
            EcgSampleChunksCompanion.insert(
              recordingId: id,
              sequence: i,
              dataJson: jsonEncode(parsed.chunks[i].toJson()),
            ),
        ]),
      );
      return id;
    });
  }

  Future<void> associate(String id, String? activityId) async {
    if (activityId != null && await db.getActivityById(activityId) == null) {
      throw StateError('This workout no longer exists.');
    }
    await (db.update(db.ecgRecordings)..where((t) => t.recordingId.equals(id)))
        .write(EcgRecordingsCompanion(activityId: Value(activityId)));
  }

  Future<void> updateNote(String id, String? note) async {
    final trimmed = note?.trim();
    await (db.update(
      db.ecgRecordings,
    )..where((t) => t.recordingId.equals(id))).write(
      EcgRecordingsCompanion(
        note: Value(
          trimmed == null || trimmed.isEmpty
              ? null
              : trimmed.length <= 12000
              ? trimmed
              : trimmed.substring(0, 12000),
        ),
      ),
    );
  }

  Future<void> saveSleepStageEstimate(
    String id,
    EcgSleepStageEstimate estimate,
  ) async {
    final row = await recording(id);
    if (row == null || row.kind != 'waveform' || row.sampleRateHz == null) {
      throw StateError('This ECG recording cannot store sleep stages.');
    }
    final metadata = jsonDecode(row.metadataJson) as Map<String, dynamic>;
    if (metadata['capture_purpose'] != 'sleep') {
      throw StateError('Sleep-stage estimation is only for sleep recordings.');
    }
    metadata['sleep_stage_estimate'] = estimate.toJson();
    metadata['sleep_stage_summary_version'] = 1;
    metadata['sleep_stage_summary_step_seconds'] = 300;
    metadata['sleep_stage_summary_priority'] = await priorityForGroup(
      SourceGroup.sleep,
    );
    await (db.update(
      db.ecgRecordings,
    )..where((t) => t.recordingId.equals(id))).write(
      EcgRecordingsCompanion(metadataJson: Value(jsonEncode(metadata))),
    );

    final phases = estimate.fiveMinutePhases(row.recordedAt.toLocal());
    if (phases.isEmpty) return;
    var deep = 0, light = 0, rem = 0, awake = 0;
    for (final phase in phases) {
      final seconds = phase.end.difference(phase.start).inSeconds;
      switch (phase.phase) {
        case 'deep':
          deep += seconds;
        case 'light':
          light += seconds;
        case 'rem':
          rem += seconds;
        default:
          awake += seconds;
      }
    }
    final sleepStart = phases.first.start;
    final sleepEnd = phases.last.end;
    final date = DateTime(sleepEnd.year, sleepEnd.month, sleepEnd.day);
    await db.upsertSleep(
      SleepRecordsCompanion(
        date: Value(date),
        totalSleepSeconds: Value(deep + light + rem),
        deepSleepSeconds: Value(deep),
        remSleepSeconds: Value(rem),
        lightSleepSeconds: Value(light),
        awakeSleepSeconds: Value(awake),
        sleepStart: Value(sleepStart),
        sleepEnd: Value(sleepEnd),
        phasesJson: Value(
          jsonEncode([
            for (final phase in phases)
              {
                's': phase.start.toUtc().toIso8601String(),
                'e': phase.end.toUtc().toIso8601String(),
                'p': phase.phase,
              },
          ]),
        ),
        source: const Value('fjelia_ecg'),
      ),
    );
  }

  /// One-time post-processing for completed sleep recordings that already
  /// contain the raw model output but predate five-minute summary blocks.
  /// No model inference is rerun; the active sleep-source priority still
  /// governs whether each H10 summary may replace the current night.
  Future<int> reprocessSavedSleepStageSummaries() async {
    final rows = await history();
    final currentPriority = await priorityForGroup(SourceGroup.sleep);
    var changed = 0;
    for (final row in rows.reversed) {
      if (row.status != 'complete' ||
          row.kind != 'waveform' ||
          row.sampleRateHz == null) {
        continue;
      }
      final metadata = jsonDecode(row.metadataJson) as Map<String, dynamic>;
      final previousPriority =
          (metadata['sleep_stage_summary_priority'] as List?)?.cast<String>();
      final alreadyCurrent =
          metadata['sleep_stage_summary_version'] == 1 &&
          metadata['sleep_stage_summary_step_seconds'] == 300 &&
          previousPriority != null &&
          previousPriority.length == currentPriority.length &&
          List.generate(
            currentPriority.length,
            (index) => previousPriority[index] == currentPriority[index],
          ).every((matches) => matches);
      if (metadata['capture_purpose'] != 'sleep' || alreadyCurrent) {
        continue;
      }
      final estimate = EcgSleepStageEstimate.fromRecordingMetadata(
        row.metadataJson,
      );
      if (estimate == null || estimate.epochs.isEmpty) continue;
      await saveSleepStageEstimate(row.recordingId, estimate);
      changed++;
    }
    return changed;
  }

  Future<void> delete(String id, {Directory? cacheDirectory}) async {
    await db.transaction(() async {
      await (db.delete(
        db.ecgSampleChunks,
      )..where((t) => t.recordingId.equals(id))).go();
      await (db.delete(
        db.ecgRecordings,
      )..where((t) => t.recordingId.equals(id))).go();
    });
    // Remove app-owned export caches too. Copies explicitly saved/shared by
    // the athlete are outside the app's storage and remain theirs.
    try {
      final dir = cacheDirectory ?? await getTemporaryDirectory();
      final safe = _fileId(id);
      for (final name in [
        'fjelia_ecg_$safe.csv',
        'fjelia_ecg_${safe}_original.csv',
        'fjelia_ecg_${safe}_original.pdf',
        'fjelia_ecg_metadata.csv',
      ]) {
        final file = File('${dir.path}/$name');
        if (await file.exists()) await file.delete();
      }
    } catch (_) {
      /* The OS may already have removed the temporary directory. */
    }
  }

  static String _fileId(String id) =>
      id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  Future<File> exportCsv(EcgRecording row, {Directory? directory}) async {
    if (row.kind != 'waveform' || row.sampleRateHz == null) {
      throw StateError('This is a report without waveform samples.');
    }
    final output = StringBuffer(
      '# fjelia-ecg-v1 ${jsonEncode({'recorded_at': row.recordedAt.toUtc().toIso8601String(), 'sample_rate_hz': row.sampleRateHz, 'source': row.source, 'device_name': row.deviceName, 'units': 'uV'})}\ntime_seconds,ecg_uv,device_frame_end_ns,frame_sample_index\n',
    );
    for (final chunk in await chunks(row.recordingId)) {
      for (var i = 0; i < chunk.microvolts.length; i++) {
        output.writeln(
          '${(chunk.offsetUs / 1e6 + i / row.sampleRateHz!).toStringAsFixed(9)},${chunk.microvolts[i]},${chunk.deviceLastSampleNs ?? ''},$i',
        );
      }
    }
    final dir = directory ?? await getTemporaryDirectory();
    return File(
      '${dir.path}/fjelia_ecg_${_fileId(row.recordingId)}.csv',
    ).writeAsString(output.toString(), flush: true);
  }

  /// Exports overnight raw signals as a pair of CSV files. Timestamps use the
  /// H10 device clock (nanoseconds since 2000), not claimed UTC time.
  Future<List<File>> exportSleepCsvFiles(
    EcgRecording row, {
    Directory? directory,
  }) async {
    final meta = jsonDecode(row.metadataJson) as Map<String, dynamic>;
    if (meta['capture_purpose'] != 'sleep' || row.sampleRateHz == null) {
      throw StateError('This is not an overnight H10 recording.');
    }
    final accelerationRate = (meta['accelerometer_sample_rate_hz'] as num?)
        ?.toDouble();
    if (accelerationRate == null || accelerationRate <= 0) {
      throw StateError('The recording has no accelerometer rate metadata.');
    }
    final folder = directory ?? await getTemporaryDirectory();
    final id = _fileId(row.recordingId);
    final ecgFile = File('${folder.path}/fjelia_sleep_${id}_ecg.csv');
    final accFile = File('${folder.path}/fjelia_sleep_${id}_acc.csv');
    final ecgSink = ecgFile.openWrite();
    final accSink = accFile.openWrite();
    final common = jsonEncode({
      'recorded_at': row.recordedAt.toUtc().toIso8601String(),
      'source': row.source,
      'device_name': row.deviceName,
      'time_basis':
          'Polar device clock, nanoseconds since 2000-01-01; not UTC synchronized',
    });
    ecgSink
      ..writeln('# fjelia-sleep-ecg-v1 $common')
      ..writeln('# ecg_units=uV; sample_rate_hz=${row.sampleRateHz}')
      ..writeln('time,ecg,hr,rr,marker');
    accSink
      ..writeln('# fjelia-sleep-acc-v1 $common')
      ..writeln('# acceleration_units=mG; sample_rate_hz=$accelerationRate')
      ..writeln('time_ns,x_mg,y_mg,z_mg');

    try {
      var after = -1;
      while (true) {
        final batch =
            await (db.select(db.ecgSampleChunks)
                  ..where(
                    (t) =>
                        t.recordingId.equals(row.recordingId) &
                        t.sequence.isBiggerThanValue(after),
                  )
                  ..orderBy([(t) => OrderingTerm(expression: t.sequence)])
                  ..limit(128))
                .get();
        if (batch.isEmpty) break;
        after = batch.last.sequence;
        for (final stored in batch) {
          final data = jsonDecode(stored.dataJson) as Map<String, dynamic>;
          if (data['stream'] == 'acc') {
            final chunk = AccelerationChunk.fromJson(data);
            final lastNs = chunk.deviceLastSampleNs;
            if (lastNs == null) {
              throw StateError('Accelerometer sample has no device timestamp.');
            }
            for (var i = 0; i < chunk.samplesMilliG.length; i++) {
              final sample = chunk.samplesMilliG[i];
              final ns =
                  lastNs -
                  ((chunk.samplesMilliG.length - 1 - i) *
                          1e9 /
                          accelerationRate)
                      .round();
              accSink.writeln('$ns,${sample.x},${sample.y},${sample.z}');
            }
          } else {
            final chunk = EcgChunk.fromJson(data);
            final lastNs = chunk.deviceLastSampleNs;
            if (lastNs == null) {
              throw StateError('ECG sample has no device timestamp.');
            }
            for (var i = 0; i < chunk.microvolts.length; i++) {
              final ns =
                  lastNs -
                  ((chunk.microvolts.length - 1 - i) * 1e9 / row.sampleRateHz!)
                      .round();
              ecgSink.writeln('$ns,${chunk.microvolts[i]}');
            }
          }
        }
      }
    } catch (_) {
      await ecgSink.close();
      await accSink.close();
      await ecgFile.delete().catchError((_) => ecgFile);
      await accFile.delete().catchError((_) => accFile);
      rethrow;
    }
    await ecgSink.close();
    await accSink.close();
    return [ecgFile, accFile];
  }

  Future<File> exportOriginal(EcgRecording row, {Directory? directory}) async {
    if (row.originalBase64 == null) {
      throw StateError('There is no imported original file.');
    }
    final dir = directory ?? await getTemporaryDirectory();
    final extension = row.kind == 'report' ? 'pdf' : 'csv';
    return File(
      '${dir.path}/fjelia_ecg_${_fileId(row.recordingId)}_original.$extension',
    ).writeAsBytes(base64Decode(row.originalBase64!), flush: true);
  }

  Future<File> exportMetadataCsv({Directory? directory}) async {
    String cell(Object? v) => '"${(v ?? '').toString().replaceAll('"', '""')}"';
    final lines = <List<Object?>>[
      [
        'recording_id',
        'recorded_at',
        'source',
        'device',
        'kind',
        'status',
        'duration_ms',
        'sample_rate_hz',
        'sample_count',
        'activity_id',
        'metadata_json',
      ],
      for (final r in await db.select(db.ecgRecordings).get())
        [
          r.recordingId,
          r.recordedAt.toUtc().toIso8601String(),
          r.source,
          r.deviceName,
          r.kind,
          r.status,
          r.durationMs,
          r.sampleRateHz,
          r.sampleCount,
          r.activityId,
          r.metadataJson,
        ],
    ];
    final dir = directory ?? await getTemporaryDirectory();
    return File(
      '${dir.path}/fjelia_ecg_metadata.csv',
    ).writeAsString(lines.map((r) => r.map(cell).join(',')).join('\n'));
  }

  /// Extracts selectable text from an imported ECG PDF for an explicitly
  /// requested Pro coach discussion. The temporary copy is removed promptly.
  Future<String> extractReportText(
    EcgRecording row, {
    PdfTextExtractor extractor = const PdfTextExtractor(),
  }) async {
    if (row.kind != 'report' ||
        row.originalBase64 == null ||
        !extractor.isSupported) {
      return '';
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/fjelia_ecg_${_fileId(row.recordingId)}_coach_${DateTime.now().microsecondsSinceEpoch}.pdf',
    );
    try {
      await file.writeAsBytes(base64Decode(row.originalBase64!), flush: true);
      return (await extractor.pages(file.path))
          .map((page) => page.trim())
          .where((page) => page.isNotEmpty)
          .join('\n\n');
    } finally {
      if (await file.exists()) await file.delete();
    }
  }
}
