import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/ecg_sleep_staging.dart';
import 'package:fjelia/services/ecg_storage_service.dart';
import 'package:fjelia/services/source_priority_service.dart';

void main() {
  late AppDatabase db;
  late EcgStorageService ecg;
  var order = <String>[];
  final night = DateTime(2026, 11, 10);
  // 23:00 to 01:00: the H10 night belongs to the 11th, like Garmin's.
  final start = DateTime(2026, 11, 10, 23);
  final day = DateTime(2026, 11, 11);

  Future<List<String>> reader(SourceGroup _) async => order;

  setUp(() async {
    order = ['garmin_api', 'fjelia_ecg'];
    db = AppDatabase(NativeDatabase.memory(), metricPriorityReader: reader);
    ecg = EcgStorageService(db, priorityReader: reader);
    final estimate = EcgSleepStageEstimate(
      createdAt: night,
      epochs: [
        for (var i = 0; i < 240; i++)
          EcgSleepStageEpoch(
            startOffsetSeconds: i * 30,
            stage: i < 120 ? 3 : 2,
            confidence: .9,
          ),
      ],
    );
    await db
        .into(db.ecgRecordings)
        .insert(
          EcgRecordingsCompanion.insert(
            recordingId: 'h10',
            recordedAt: start,
            source: 'polar_h10',
            deviceName: 'Polar H10',
            kind: 'waveform',
            status: 'complete',
            sampleRateHz: const Value(130),
            metadataJson: Value(
              jsonEncode({
                'capture_purpose': 'sleep',
                'sleep_stage_estimate': estimate.toJson(),
              }),
            ),
          ),
        );
    await db.upsertSleep(
      SleepRecordsCompanion(
        date: Value(day),
        totalSleepSeconds: const Value(7 * 3600),
        deepSleepSeconds: const Value(3600),
        remSleepSeconds: const Value(5400),
        lightSleepSeconds: const Value(5 * 3600 - 1800),
        awakeSleepSeconds: const Value(600),
        sleepScore: const Value(81),
        sleepStart: Value(DateTime(2026, 11, 10, 22, 50)),
        sleepEnd: Value(DateTime(2026, 11, 11, 6, 10)),
        phasesJson: const Value('[{"p":"garmin"}]'),
        source: const Value('garmin_api'),
      ),
    );
  });
  tearDown(() => db.close());

  test('a night replaced by the H10 comes back when Garmin ranks first '
      'again', () async {
    // Below Garmin, the H10 summary leaves Garmin's night alone.
    await ecg.reprocessSavedSleepStageSummaries();
    var stored = (await db.getSleepForDate(day))!;
    expect(stored.totalSleepSeconds, 7 * 3600);
    expect(stored.source, 'garmin_api');

    // Ranked first, it replaces the night's stages.
    order = ['fjelia_ecg', 'garmin_api'];
    await ecg.reprocessSavedSleepStageSummaries();
    stored = (await db.getSleepForDate(day))!;
    expect(stored.totalSleepSeconds, 2 * 3600);
    expect(stored.phasesJson, isNot('[{"p":"garmin"}]'));
    // The score was never the H10's.
    expect(stored.sleepScore, 81);

    // Back down: Garmin's night returns without a Garmin sync.
    order = ['garmin_api', 'fjelia_ecg'];
    await ecg.reprocessSavedSleepStageSummaries();
    stored = (await db.getSleepForDate(day))!;
    expect(stored.totalSleepSeconds, 7 * 3600);
    expect(stored.deepSleepSeconds, 3600);
    expect(stored.phasesJson, '[{"p":"garmin"}]');
    expect(stored.sleepEnd, DateTime(2026, 11, 11, 6, 10));
    expect(stored.source, 'garmin_api');
    final origins = await db.getMetricOrigins('sleep_records', day);
    expect(origins['total_sleep_seconds']!.source, 'garmin_api');
    expect(origins['phases_json']!.source, 'garmin_api');

    // A later Garmin night still replaces it normally.
    await db.upsertSleep(
      SleepRecordsCompanion(
        date: Value(day),
        totalSleepSeconds: const Value(6 * 3600),
        deepSleepSeconds: const Value(1800),
        remSleepSeconds: const Value(3600),
        lightSleepSeconds: const Value(4 * 3600 + 1800),
        awakeSleepSeconds: const Value(300),
        source: const Value('garmin_api'),
      ),
    );
    expect((await db.getSleepForDate(day))!.totalSleepSeconds, 6 * 3600);
  });
}
